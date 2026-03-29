**[English](../README.md)** | **繁體中文** | **[简体中文](README.zh-CN.md)** | **[日本語](README.ja.md)**

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
- [作為 Subtree 使用](#作為-subtree-使用)
- [設定](#設定)
- [smoke test](#smoke test)
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
        H_OAuth["~/.claude<br/>(OAuth 憑證)"]
        H_WS["工作區<br/>(WS_PATH)"]
        H_Data["資料目錄<br/>(agent_* or ./data/)"]
    end

    subgraph "Container (DinD)"
        EP["entrypoint.sh"]
        DinD["dockerd<br/>(隔離)"]
        Claude["Claude Code"]
        Tools["git, python3, jq,<br/>ripgrep, make, cmake..."]

        EP -->|"1. 啟動"| DinD
        EP -->|"2. 複製憑證<br/>（首次執行）"| Claude
        EP -->|"3. 解密 API 金鑰<br/>（如有 .env.gpg）"| Tools
    end

    H_OAuth -->|"唯讀掛載"| EP
    H_WS -->|"掛載<br/>~/work"| Tools
    H_Data -->|"掛載<br/>~/.claude"| Claude

    style DinD fill:#f0f0f0,stroke:#666
    style Claude fill:#d4a574,stroke:#333
```

```mermaid
graph LR
    subgraph "Dockerfile 階段"
        sys["sys<br/>使用者, 語系, 時區"]
        base["base<br/>開發工具, Docker"]
        devel["devel<br/>claude code"]
        test["test<br/>Bats smoke test"]
    end

    sys --> base --> devel --> test

    subgraph "Compose Services"
        S_CPU["devel<br/>(CPU, default)"]
        S_GPU["devel-gpu<br/>(NVIDIA GPU)"]
        S_Test["test<br/>（暫時性）"]
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
        A["Generate .env<br/>(template)"] --> B["Derive BASE_IMAGE<br/>(post_setup.sh)"]
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
# Build (auto-generates .env on every run)
./build.sh              # CPU variant (default)
./build.sh devel-gpu    # GPU variant
./build.sh --no-env test  # 建置但不更新 .env

# Run
./run.sh                          # CPU variant (default)
./run.sh devel-gpu                # GPU variant
./run.sh --data-dir ../agent_foo  # Specify data directory
./run.sh --no-env -d              # 背景啟動，跳過 .env 更新

# Exec into running container
./exec.sh
```

## 對話持久化

對話記錄與工作階段資料透過 掛載 持久化儲存，容器重啟後仍可保留。

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

## 作為 Subtree 使用

此 repo 可透過 `git subtree` 嵌入至其他專案，讓專案自帶 Docker 開發環境。

### 加入你的專案

```bash
git subtree add --prefix=docker/claude_code \
    https://github.com/ycpss91255-docker/claude_code.git main --squash
```

加入後的目錄結構範例：

```text
my_project/
├── src/                         # 專案原始碼
├── docker/claude_code/          # Subtree
│   ├── build.sh
│   ├── run.sh
│   ├── compose.yaml
│   ├── Dockerfile
│   └── template/
└── ...
```

### 建置與執行

```bash
cd docker/claude_code
./build.sh && ./run.sh
```

`build.sh` 內部使用 `--base-path`，因此無論從何處執行，路徑偵測都能正確運作。

### 工作區偵測行為

<details>
<summary>展開查看作為 subtree 使用時的偵測行為</summary>

當 subtree 位於 `my_project/docker/claude_code/` 時：

- **IMAGE_NAME**：目錄名稱為 `claude_code`（非 `docker_*`），因此偵測會退回至 `.env.example`，其中設定了 `IMAGE_NAME=claude_code` — 可正常運作。
- **WS_PATH**：策略 1（同層掃描）與策略 2（向上遍歷）可能無法匹配，因此策略 3（退回）會解析至上層目錄（`my_project/docker/`）。

**建議**：首次建置後，請編輯 `.env` 中的 `WS_PATH` 指向實際工作區。此值在後續建置中會被保留。

</details>

### 同步上游更新

```bash
git subtree pull --prefix=docker/claude_code \
    https://github.com/ycpss91255-docker/claude_code.git main --squash
```

> **注意事項**：
> - 本地修改會由 git 正常追蹤。
> - 若上游修改了與你本地相同的檔案，`subtree pull` 可能會產生合併衝突。
> - **不要**修改 subtree 內的 `template/` — 它由 env repo 自身的 subtree 管理。

## 設定

每次執行 `build.sh` / `run.sh` 時會自動產生 `.env`（可傳入 `--no-env` 跳過）。詳情請參閱 [.env.example](.env.example)。

| 變數 | 說明 |
|------|------|
| `USER_NAME` / `USER_UID` / `USER_GID` | 對應主機的容器用戶（自動偵測） |
| `GPU_ENABLED` | 自動偵測，決定 `BASE_IMAGE` 與 `GPU_VARIANT` |
| `BASE_IMAGE` | `node:20-slim`（CPU）或 `nvidia/cuda:13.1.1-cudnn-devel-ubuntu24.04`（GPU） |
| `WS_PATH` | 主機路徑，掛載至容器內的 `~/work` |
| `IMAGE_NAME` | Docker 映像名稱（預設：`claude_code`） |

## smoke test

建置 test target 驗證環境：

```bash
./build.sh test
```

位於 `test/smoke/claude_env.bats`，共 **29** 項。

<details>
<summary>展開查看測試細項</summary>

#### AI 工具 (3)

| 測試項目 | 說明 |
|----------|------|
| `claude` | 可用 |
| `gemini` | 可用 |
| `codex` | 可用 |

#### 開發工具 (14)

| 測試項目 | 說明 |
|----------|------|
| `node` | 可用 |
| `npm` | 可用 |
| `git` | 可用 |
| `python3` | 可用 |
| `make` | 可用 |
| `cmake` | 可用 |
| `g++` | 可用 |
| `curl` | 可用 |
| `wget` | 可用 |
| `jq` | 可用 |
| `rg` (ripgrep) | 可用 |
| `tree` | 可用 |
| `docker` | 可用 |
| `gpg` | 可用 |

#### 系統 (7)

| 測試項目 | 說明 |
|----------|------|
| 用戶 | 非 root |
| `sudo` | 免密碼執行 |
| 時區 | `Asia/Taipei` |
| `LANG` | `en_US.UTF-8` |
| work 目錄 | 存在 |
| work 目錄 | 可寫入 |
| `entrypoint.sh` | 存在 |

#### 排除工具 (4)

| 測試項目 | 說明 |
|----------|------|
| `tmux` | 未安裝（最小化映像） |
| `vim` | 未安裝 |
| `fzf` | 未安裝 |
| `terminator` | 未安裝 |

#### 安全性 (1)

| 測試項目 | 說明 |
|----------|------|
| `encrypt_env.sh` | 在 PATH 中 |

</details>

## 架構

```
.
├── Dockerfile                        # 多階段建置 (sys -> base -> devel -> test)
├── compose.yaml                      # 服務：devel (CPU)、devel-gpu、test
├── build.sh -> template/build.sh     # 建置並自動產生 .env（symlink）
├── run.sh -> template/run.sh         # 執行並自動產生 .env（symlink）
├── exec.sh -> template/exec.sh       # 進入執行中的容器（symlink）
├── stop.sh -> template/stop.sh       # 停止並移除容器（symlink）
├── Makefile -> template/Makefile     # 建置目標（symlink）
├── .hadolint.yaml                    # Hadolint 設定
├── encrypt_env.sh                    # API 金鑰加密工具
├── post_setup.sh                     # 根據 GPU_ENABLED 決定 BASE_IMAGE
├── .env.example                      # .env 範本
├── .template_version                 # subtree 版本追蹤
├── script/
│   └── entrypoint.sh                 # DinD 啟動、OAuth 複製、API 金鑰解密
├── test/
│   └── smoke/
│       └── claude_env.bats           # Bats smoke test（repo 專屬）
├── doc/                              # 翻譯文件
│   ├── README.zh-TW.md
│   ├── README.zh-CN.md
│   └── README.ja.md
├── .github/
│   └── workflows/
│       └── main.yaml                 # CI/CD（呼叫 template 的 reusable workflows）
├── template/                         # 共用腳本與設定（git subtree）
└── README.md
```

### Dockerfile 階段

| 階段 | 用途 |
|------|------|
| `sys` | 用戶/群組建立、語系、時區、Node.js（僅 GPU） |
| `base` | 開發工具、Python、建置工具、Docker、jq、ripgrep |
| `devel` | Claude Code、進入點、非 root 用戶 |
| `test` | Bats smoke test（暫時性，驗證後丟棄） |

### Compose 服務

| 服務 | 說明 |
|------|------|
| `devel` | CPU 版本（預設） |
| `devel-gpu` | GPU 版本，具備 NVIDIA 裝置保留 |
| `test` | smoke test（profile 限定） |

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

GPU 版本額外包含：CUDA 13.1.1、cuDNN、OpenCL、Vulkan。

### 容器能力

兩種服務皆需要 `SYS_ADMIN`、`NET_ADMIN`、`MKNOD` 能力以及 `seccomp:unconfined`，以確保 DinD 正常運作。內部 Docker daemon 與主機完全隔離。
