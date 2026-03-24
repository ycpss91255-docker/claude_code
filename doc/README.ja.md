**[English](../README.md)** | **[繁體中文](README.zh-TW.md)** | **[简体中文](README.zh-CN.md)** | **日本語**

# Claude Code Docker 環境

Claude Code 用の Docker-in-Docker (DinD) 開発コンテナ。Anthropic の Claude Code CLI がプリインストールされています。CPU と NVIDIA GPU の2つのバリアントを提供し、非 root ユーザーで実行され、ホストの UID/GID を自動的にマッチングします。

## 目次

- [TL;DR](#tldr)
- [概要](#概要)
- [前提条件](#前提条件)
- [クイックスタート](#クイックスタート)
- [会話の永続化](#会話の永続化)
- [複数インスタンスの実行](#複数インスタンスの実行)
- [認証](#認証)
  - [OAuth（対話式ログイン）](#oauth対話式ログイン)
  - [API キー（暗号化）](#api-キー暗号化)
- [設定](#設定)
- [スモークテスト](#スモークテスト)
- [アーキテクチャ](#アーキテクチャ)
  - [Dockerfile ステージ](#dockerfile-ステージ)
  - [Compose サービス](#compose-サービス)
  - [エントリポイントフロー](#エントリポイントフロー)
  - [プリインストール済みツール](#プリインストール済みツール)
  - [コンテナ能力](#コンテナ能力)

## TL;DR

```bash
./build.sh && ./run.sh    # Build and run (CPU, default)
```

- Claude Code がプリインストールされた隔離 Docker-in-Docker コンテナ
- 非 root ユーザー、ホストの UID/GID を自動検出
- 初回実行時に OAuth 認証情報を自動コピー、会話履歴はローカルに永続化
- 暗号化 API キー（GPG AES-256）をオプションで使用可能
- デフォルトは CPU バリアント、GPU バリアントは `./run.sh devel-gpu` を使用

## 概要

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

## 前提条件

- Docker（Compose V2 対応）
- GPU バリアントには [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) が必要
- ホスト側で Claude Code の OAuth ログインを完了していること（`claude`）

## クイックスタート

```bash
# Build (auto-generates .env on every run)
./build.sh              # CPU variant (default)
./build.sh devel-gpu    # GPU variant
./build.sh --no-env test  # ビルドのみ、.env 更新なし

# Run
./run.sh                          # CPU variant (default)
./run.sh devel-gpu                # GPU variant
./run.sh --data-dir ../agent_foo  # Specify data directory
./run.sh --no-env -d              # バックグラウンド起動、.env 更新をスキップ

# Exec into running container
./exec.sh
```

## 会話の永続化

会話履歴とセッションデータは bind mount により永続化され、コンテナ再起動後も保持されます。

`run.sh` はプロジェクトディレクトリから上方向に `agent_*` ディレクトリを自動スキャンします。見つかった場合はそのディレクトリにデータを保存し、見つからない場合は `./data/` にフォールバックします。

```
# Example: if ../agent_myproject/ exists
../agent_myproject/
└── .claude/    # Claude Code conversations, settings, session

# Fallback: no agent_* directory found
./data/
└── .claude/
```

- 初回起動：OAuth 認証情報をホストからデータディレクトリにコピー
- 以降の起動：データディレクトリに既存データがあれば、そのまま使用（上書きしない）
- データディレクトリは自由にコピー、バックアップ、移動が可能
- 手動指定：`./run.sh --data-dir /path/to/dir`

## 複数インスタンスの実行

`--project-name`（`-p`）を使用して完全に隔離されたインスタンスを作成し、各インスタンスは独立した名前付き volume を持ちます：

```bash
# Instance 1
docker compose -p cc1 --env-file .env run --rm devel

# Instance 2 (in another terminal)
docker compose -p cc2 --env-file .env run --rm devel

# Instance 3
docker compose -p cc3 --env-file .env run --rm devel
```

複数インスタンスを実行する場合は、それぞれ独立した `agent_*` ディレクトリを作成してください：

```bash
mkdir ../agent_proj1 ../agent_proj2

./run.sh --data-dir ../agent_proj1
./run.sh --data-dir ../agent_proj2
```

認証情報、会話履歴、セッションデータは完全に隔離されます。クリーンアップ時は対応するディレクトリを削除するだけです：

```bash
rm -rf ../agent_proj1
```

## 認証

2つの方式をサポートしており、併用可能です。

### OAuth（対話式ログイン）

対話式 CLI 使用に適しています。まずホスト側でログインしてください：

```bash
claude   # Log in to Claude Code
```

認証情報（`~/.claude`）は読み取り専用でコンテナにマウントされ、初回起動時にデータディレクトリにコピーされます。以降の起動では既存データをそのまま使用します。

### API キー（暗号化）

プログラムによる API アクセスに適しています。キーは GPG（AES-256）で暗号化して保存され、平文では保存されません。

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

コンテナ起動時にワークスペースで `.env.gpg` が検出されると、パスフレーズの入力を求められます。復号されたキーは環境変数としてメモリ上にのみ保持されます。

> **注意：** `.env` と `.env.gpg` は `.gitignore` に登録されています。

## 設定

`build.sh` / `run.sh` の実行時に `.env` が自動生成されます（`--no-env` でスキップ可能）。詳細は [.env.example](.env.example) を参照してください。

| 変数 | 説明 |
|------|------|
| `USER_NAME` / `USER_UID` / `USER_GID` | ホストに対応するコンテナユーザー（自動検出） |
| `GPU_ENABLED` | 自動検出、`BASE_IMAGE` と `GPU_VARIANT` を決定 |
| `BASE_IMAGE` | `node:20-slim`（CPU）または `nvidia/cuda:13.1.1-cudnn-devel-ubuntu24.04`（GPU） |
| `WS_PATH` | コンテナ内の `~/work` にマウントされるホストパス |
| `IMAGE_NAME` | Docker イメージ名（デフォルト：`claude_code`） |

## スモークテスト

test ターゲットをビルドして環境を検証：

```bash
./build.sh test
```

`smoke_test/agent_env.bats` に配置、全 **29** 項目。

<details>
<summary>クリックしてテスト詳細を表示</summary>

#### AI ツール (3)

| テスト項目 | 説明 |
|------------|------|
| `claude` | 利用可能 |
| `gemini` | 利用可能 |
| `codex` | 利用可能 |

#### 開発ツール (14)

| テスト項目 | 説明 |
|------------|------|
| `node` | 利用可能 |
| `npm` | 利用可能 |
| `git` | 利用可能 |
| `python3` | 利用可能 |
| `make` | 利用可能 |
| `cmake` | 利用可能 |
| `g++` | 利用可能 |
| `curl` | 利用可能 |
| `wget` | 利用可能 |
| `jq` | 利用可能 |
| `rg` (ripgrep) | 利用可能 |
| `tree` | 利用可能 |
| `docker` | 利用可能 |
| `gpg` | 利用可能 |

#### システム (7)

| テスト項目 | 説明 |
|------------|------|
| ユーザー | 非 root |
| `sudo` | パスワードなしで実行可能 |
| タイムゾーン | `Asia/Taipei` |
| `LANG` | `en_US.UTF-8` |
| work ディレクトリ | 存在する |
| work ディレクトリ | 書き込み可能 |
| `entrypoint.sh` | 存在する |

#### 除外ツール (4)

| テスト項目 | 説明 |
|------------|------|
| `tmux` | 未インストール（最小化イメージ） |
| `vim` | 未インストール |
| `fzf` | 未インストール |
| `terminator` | 未インストール |

#### セキュリティ (1)

| テスト項目 | 説明 |
|------------|------|
| `encrypt_env.sh` | PATH に存在 |

</details>

## アーキテクチャ

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
└── README.zh-TW.md
```

### Dockerfile ステージ

| ステージ | 用途 |
|----------|------|
| `sys` | ユーザー/グループ作成、ロケール、タイムゾーン、Node.js（GPU のみ） |
| `base` | 開発ツール、Python、ビルドツール、Docker、jq、ripgrep |
| `devel` | Claude Code、エントリポイント、非 root ユーザー |
| `test` | Bats スモークテスト（一時的、検証後に破棄） |

### Compose サービス

| サービス | 説明 |
|----------|------|
| `devel` | CPU バリアント（デフォルト） |
| `devel-gpu` | GPU バリアント、NVIDIA デバイス予約付き |
| `test` | スモークテスト（profile で制御） |

### エントリポイントフロー

1. sudo で `dockerd`（DinD）を起動し、準備完了まで待機（最大 30 秒）
2. OAuth 認証情報を読み取り専用マウントから `data/` ディレクトリにコピー（初回実行時のみ）
3. `.env.gpg` を復号し、API キーを環境変数としてエクスポート（存在する場合）
4. CMD（`bash`）を実行

### プリインストール済みツール

| ツール | 用途 |
|--------|------|
| Claude Code | Anthropic AI CLI |
| Docker (DinD) | コンテナ内の隔離された Docker daemon |
| Node.js 20 | CLI ツールのランタイム |
| Python 3 | スクリプト作成と開発 |
| git, curl, wget | バージョン管理とダウンロード |
| jq, ripgrep | JSON 処理とコード検索 |
| make, g++, cmake | ビルドツールチェーン |
| tree | ディレクトリ構造の可視化 |

GPU バリアントには追加で CUDA 13.1.1、cuDNN、OpenCL、Vulkan が含まれます。

### コンテナ能力

両サービスとも DinD の正常動作のために `SYS_ADMIN`、`NET_ADMIN`、`MKNOD` 能力と `seccomp:unconfined` が必要です。内部 Docker daemon はホストから完全に隔離されています。
