**繁體中文** | [English](README.md)

# Claude Code Docker 環境

Claude Code 的 Docker-in-Docker (DinD) 開發容器，預先安裝 Anthropic 的 Claude Code CLI。提供 CPU 與 NVIDIA GPU 兩種版本，以非 root 用戶執行並自動對應主機的 UID/GID。

## 目錄

- [TL;DR](#tldr)
- [概述](#概述)
- [前置需求](#前置需求)
- [快速開始](#快速開始)
- [對話持久化](#對話持久化)
- [執行多個實例](#執行多個實例)
- [身份驗證](#身份驗證)
  - [OAuth（互動式登入）](#oauth互動式登入)
  - [API 金鑰（加密）](#api-金鑰加密)
- [設定](#設定)
- [冒煙測試](#冒煙測試)
- [架構](#架構)
  - [Dockerfile 階段](#dockerfile-階段)
  - [Compose 服務](#compose-服務)
  - [進入點流程](#進入點流程)
  - [預安裝工具](#預安裝工具)
  - [容器能力](#容器能力)

## TL;DR

```bash
./build.sh && ./run.sh    # Build and run (CPU, default)
```

- 隔離的 Docker-in-Docker 容器，預先安裝 Claude Code
- 非 root 用戶，自動偵測主機 UID/GID
- 首次執行時自動複製 OAuth 憑證，對話記錄持久化儲存於本機
- 選用加密 API 金鑰（GPG AES-256）
- 預設 CPU 版本，GPU 版本使用 `./run.sh devel-gpu`

## 概述

```mermaid
graph TB
    subgraph Host
        H_OAuth["~/.claude<br/>(OAuth credentials)"]
        H_WS["Workspace<br/>(WS_PATH)"]
        H_Data["Data Directory<br/>(agent_* or ./data/)"]
    end

    subgraph "Container (DinD)"
        EP["entrypoint.sh"]
        DinD["dockerd<br/>(isolated)"]
        Claude["Claude Code"]
        Tools["git, python3, jq,<br/>ripgrep, make, cmake..."]

        EP -->|"1. start"| DinD
        EP -->|"2. copy credentials<br/>(first run)"| Claude
        EP -->|"3. decrypt API keys<br/>(if .env.gpg)"| Tools
    end

    H_OAuth -->|"read-only mount"| EP
    H_WS -->|"bind mount<br/>~/work"| Tools
    H_Data -->|"bind mount<br/>~/.claude"| Claude

    style DinD fill:#f0f0f0,stroke:#666
    style Claude fill:#d4a574,stroke:#333
```

```mermaid
graph LR
    subgraph "Dockerfile Stages"
        sys["sys<br/>user, locale, tz"]
        base["base<br/>dev tools, docker"]
        devel["devel<br/>claude code"]
        test["test<br/>bats smoke test"]
    end

    sys --> base --> devel --> test

    subgraph "Compose Services"
        S_CPU["devel<br/>(CPU, default)"]
        S_GPU["devel-gpu<br/>(NVIDIA GPU)"]
        S_Test["test<br/>(ephemeral)"]
    end

    devel -.-> S_CPU
    devel -.-> S_GPU
    test -.-> S_Test

    style sys fill:#e8e8e8,stroke:#333
    style base fill:#d0d0d0,stroke:#333
    style devel fill:#b8d4b8,stroke:#333
    style test fill:#d4b8b8,stroke:#333
```

```mermaid
flowchart LR
    subgraph "run.sh"
        A["Generate .env<br/>(docker_setup_helper)"] --> B["Derive BASE_IMAGE<br/>(post_setup.sh)"]
        B --> C{"--data-dir?"}
        C -->|yes| D["Use specified dir"]
        C -->|no| E{"agent_* found?"}
        E -->|yes| F["Use agent_* dir"]
        E -->|no| G["Use ./data/"]
        D --> H["docker compose run"]
        F --> H
        G --> H
    end
```

## 前置需求

- Docker with Compose V2
- GPU 版本需要 [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- 在主機上完成 Claude Code 的 OAuth 登入（`claude`）

## 快速開始

```bash
# Build (auto-generates .env on first run)
./build.sh              # CPU variant (default)
./build.sh devel-gpu    # GPU variant

# Run
./run.sh                          # CPU variant (default)
./run.sh devel-gpu                # GPU variant
./run.sh --data-dir ../agent_foo  # Specify data directory

# Exec into running container
./exec.sh
```

## 對話持久化

對話記錄與工作階段資料透過 bind mount 持久化儲存，容器重啟後仍可保留。

`run.sh` 會自動從專案目錄向上掃描 `agent_*` 目錄。若找到，資料將儲存於該目錄；否則退回使用 `./data/`。

```
# Example: if ../agent_myproject/ exists
../agent_myproject/
└── .claude/    # Claude Code conversations, settings, session

# Fallback: no agent_* directory found
./data/
└── .claude/
```

- 首次啟動：OAuth 憑證從主機複製至資料目錄
- 後續啟動：資料目錄已有資料，直接使用（不覆寫）
- 可自由複製、備份或移動資料目錄
- 手動指定路徑：`./run.sh --data-dir /path/to/dir`

## 執行多個實例

使用 `--project-name`（`-p`）建立完全隔離的實例，每個實例擁有獨立的具名 volume：

```bash
# Instance 1
docker compose -p cc1 --env-file .env run --rm devel

# Instance 2 (in another terminal)
docker compose -p cc2 --env-file .env run --rm devel

# Instance 3
docker compose -p cc3 --env-file .env run --rm devel
```

若需執行多個實例，請分別建立獨立的 `agent_*` 目錄：

```bash
mkdir ../agent_proj1 ../agent_proj2

./run.sh --data-dir ../agent_proj1
./run.sh --data-dir ../agent_proj2
```

憑證、對話記錄與工作階段資料皆完全隔離。清除時，直接刪除對應目錄即可：

```bash
rm -rf ../agent_proj1
```

## 身份驗證

支援兩種方式，可同時使用。

### OAuth（互動式登入）

適用於互動式 CLI 使用。請先在主機上登入：

```bash
claude   # Log in to Claude Code
```

憑證（`~/.claude`）以唯讀方式掛載至容器內，並於首次啟動時複製至資料目錄。後續啟動將直接使用現有資料。

### API 金鑰（加密）

適用於程式化的 API 存取。金鑰以 GPG（AES-256）加密儲存，不以明文保存。

```bash
# 1. Create plaintext .env
cat <<EOF > .env.keys
ANTHROPIC_API_KEY=sk-ant-xxxxx
EOF

# 2. Encrypt (you will be prompted to set a passphrase)
encrypt_env.sh    # available inside container, or ./encrypt_env.sh on host

# 3. Remove plaintext
rm .env.keys
```

容器啟動時，若偵測到工作區中有 `.env.gpg`，將提示輸入通行短語。解密後的金鑰僅以環境變數形式保存於記憶體中。

> **注意：** `.env` 與 `.env.gpg` 已加入 `.gitignore`。

## 設定

自動產生的 `.env` 檔案控制所有建置與執行時參數。詳情請參閱 [.env.example](.env.example)。

| 變數 | 說明 |
|------|------|
| `USER_NAME` / `USER_UID` / `USER_GID` | 對應主機的容器用戶（自動偵測） |
| `GPU_ENABLED` | 自動偵測，決定 `BASE_IMAGE` 與 `GPU_VARIANT` |
| `BASE_IMAGE` | `node:20-slim`（CPU）或 `nvidia/cuda:12.3.2-cudnn9-devel-ubuntu22.04`（GPU） |
| `WS_PATH` | 主機路徑，掛載至容器內的 `~/work` |
| `IMAGE_NAME` | Docker 映像名稱（預設：`claude_code`） |

## 冒煙測試

建置測試目標以驗證環境：

```bash
./build.sh test
```

測試項目涵蓋：Claude Code 可用性、開發工具、系統設定（非 root 用戶、時區、語系）、確認無 Gemini/Codex，以及確認無不必要的工具（tmux、vim、fzf、terminator）。

## 架構

```
.
├── Dockerfile             # Multi-stage build (sys -> base -> devel -> test)
├── compose.yaml           # Services: devel (CPU), devel-gpu, test
├── build.sh               # Build with auto .env generation
├── run.sh                 # Run with auto .env generation
├── exec.sh                # Exec into running container
├── entrypoint.sh          # DinD startup, OAuth copy, API key decryption
├── encrypt_env.sh         # Helper to encrypt API keys
├── post_setup.sh          # Derives BASE_IMAGE from GPU_ENABLED
├── .env.example           # Template for .env
├── smoke_test/            # Bats smoke tests
│   ├── claude_env.bats
│   └── test_helper.bash
├── docker_setup_helper/   # Auto .env generator (git subtree)
├── README.md
└── README_zh-TW.md
```

### Dockerfile 階段

| 階段 | 用途 |
|------|------|
| `sys` | 用戶/群組建立、語系、時區、Node.js（僅 GPU） |
| `base` | 開發工具、Python、建置工具、Docker、jq、ripgrep |
| `devel` | Claude Code、進入點、非 root 用戶 |
| `test` | Bats 冒煙測試（暫時性，驗證後丟棄） |

### Compose 服務

| 服務 | 說明 |
|------|------|
| `devel` | CPU 版本（預設） |
| `devel-gpu` | GPU 版本，具備 NVIDIA 裝置保留 |
| `test` | 冒煙測試（profile 限定） |

### 進入點流程

1. 透過 sudo 啟動 `dockerd`（DinD），等待就緒（最多 30 秒）
2. 將 OAuth 憑證從唯讀掛載點複製至 `data/` 目錄（僅首次執行）
3. 解密 `.env.gpg` 並將 API 金鑰匯出為環境變數（若存在）
4. 執行 CMD（`bash`）

### 預安裝工具

| 工具 | 用途 |
|------|------|
| Claude Code | Anthropic AI CLI |
| Docker (DinD) | 容器內的隔離 Docker daemon |
| Node.js 20 | CLI 工具的執行環境 |
| Python 3 | 腳本撰寫與開發 |
| git, curl, wget | 版本控制與下載 |
| jq, ripgrep | JSON 處理與程式碼搜尋 |
| make, g++, cmake | 建置工具鏈 |
| tree | 目錄結構視覺化 |

GPU 版本額外包含：CUDA 12.3.2、cuDNN 9、OpenCL、Vulkan。

### 容器能力

兩種服務皆需要 `SYS_ADMIN`、`NET_ADMIN`、`MKNOD` 能力以及 `seccomp:unconfined`，以確保 DinD 正常運作。內部 Docker daemon 與主機完全隔離。
