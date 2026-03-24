**English** | **[繁體中文](README.zh-TW.md)** | **[简体中文](README.zh-CN.md)** | **[日本語](README.ja.md)**

# Claude Code Docker Environment

Docker-in-Docker (DinD) development container for Claude Code, with Anthropic's Claude Code CLI pre-installed. Available in CPU and NVIDIA GPU variants. Runs as non-root user with host UID/GID matching.

## Table of Contents

- [TL;DR](#tldr)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Conversation Persistence](#conversation-persistence)
- [Running Multiple Instances](#running-multiple-instances)
- [Authentication](#authentication)
  - [OAuth (Interactive Login)](#oauth-interactive-login)
  - [API Key (Encrypted)](#api-key-encrypted)
- [Configuration](#configuration)
- [Smoke Tests](#smoke-tests)
- [Architecture](#architecture)
  - [Dockerfile Stages](#dockerfile-stages)
  - [Compose Services](#compose-services)
  - [Entrypoint Flow](#entrypoint-flow)
  - [Pre-installed Tools](#pre-installed-tools)
  - [Container Capabilities](#container-capabilities)

## TL;DR

```bash
./build.sh && ./run.sh    # Build and run (CPU, default)
```

- Isolated Docker-in-Docker container with Claude Code pre-installed
- Non-root user, auto-detected UID/GID from host
- OAuth credentials auto-copied on first run, conversations persisted locally
- Optionally encrypted API keys (GPG AES-256)
- CPU default, GPU via `./run.sh devel-gpu`

## Overview

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

## Prerequisites

- Docker with Compose V2
- GPU variant requires [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Host-side OAuth login for Claude Code (`claude`)

## Quick Start

```bash
# Build (auto-generates .env on every run)
./build.sh              # CPU variant (default)
./build.sh devel-gpu    # GPU variant
./build.sh --no-env test  # Build without refreshing .env

# Run
./run.sh                          # CPU variant (default)
./run.sh devel-gpu                # GPU variant
./run.sh --data-dir ../agent_foo  # Specify data directory
./run.sh --no-env -d              # Background start, skip .env refresh

# Exec into running container
./exec.sh
```

## Conversation Persistence

Conversation history and session data are persisted via bind mount, surviving container restarts.

`run.sh` automatically scans upward from the project directory for an `agent_*` directory. If found, data is stored there; otherwise it falls back to `./data/`.

```
# Example: if ../agent_myproject/ exists
../agent_myproject/
└── .claude/    # Claude Code conversations, settings, session

# Fallback: no agent_* directory found
./data/
└── .claude/
```

- First startup: OAuth credentials are copied from the host into the data directory
- Subsequent startups: data directory already has data and is used directly (no overwrite)
- You can freely copy, backup, or move the data directory
- Override manually: `./run.sh --data-dir /path/to/dir`

## Running Multiple Instances

Use `--project-name` (`-p`) to create fully isolated instances, each with its own named volumes:

```bash
# Instance 1
docker compose -p cc1 --env-file .env run --rm devel

# Instance 2 (in another terminal)
docker compose -p cc2 --env-file .env run --rm devel

# Instance 3
docker compose -p cc3 --env-file .env run --rm devel
```

For multiple instances, create separate `agent_*` directories:

```bash
mkdir ../agent_proj1 ../agent_proj2

./run.sh --data-dir ../agent_proj1
./run.sh --data-dir ../agent_proj2
```

Credentials, conversations, and session data are fully isolated. To clean up, simply delete the directory:

```bash
rm -rf ../agent_proj1
```

## Authentication

Two methods are supported. Both can be used at the same time.

### OAuth (Interactive Login)

For interactive CLI usage. Log in on the host first:

```bash
claude   # Log in to Claude Code
```

Credentials (`~/.claude`) are mounted read-only into the container and copied into the data directory on first startup. Subsequent startups reuse the existing data.

### API Key (Encrypted)

For programmatic API access. Keys are stored encrypted with GPG (AES-256), never in plaintext.

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

On container startup, if `.env.gpg` is detected in the workspace, you will be prompted for the passphrase. Decrypted keys are only held in memory as environment variables.

> **Note:** `.env` and `.env.gpg` are already in `.gitignore`.

## Configuration

`.env` is auto-generated on every `build.sh` / `run.sh` invocation (pass `--no-env` to skip). See [.env.example](.env.example) for details.

| Variable | Description |
|----------|-------------|
| `USER_NAME` / `USER_UID` / `USER_GID` | Container user matching host (auto-detected) |
| `GPU_ENABLED` | Auto-detected, drives `BASE_IMAGE` and `GPU_VARIANT` |
| `BASE_IMAGE` | `node:20-slim` (CPU) or `nvidia/cuda:13.1.1-cudnn-devel-ubuntu24.04` (GPU) |
| `WS_PATH` | Host path mounted to `~/work` inside container |
| `IMAGE_NAME` | Docker image name (default: `claude_code`) |

## Smoke Tests

Build the test target to verify the environment:

```bash
./build.sh test
```

Located in `smoke_test/agent_env.bats` — **29 tests** total.

<details>
<summary>Click to expand test details</summary>

#### AI tools (3)

| Test | Description |
|------|-------------|
| `claude` | Available |
| `gemini` | Available |
| `codex` | Available |

#### Dev tools (14)

| Test | Description |
|------|-------------|
| `node` | Available |
| `npm` | Available |
| `git` | Available |
| `python3` | Available |
| `make` | Available |
| `cmake` | Available |
| `g++` | Available |
| `curl` | Available |
| `wget` | Available |
| `jq` | Available |
| `rg` (ripgrep) | Available |
| `tree` | Available |
| `docker` | Available |
| `gpg` | Available |

#### System (7)

| Test | Description |
|------|-------------|
| User | Not root |
| `sudo` | Passwordless works |
| Timezone | `Asia/Taipei` |
| `LANG` | `en_US.UTF-8` |
| Work directory | Exists |
| Work directory | Writable |
| `entrypoint.sh` | Exists |

#### Excluded tools (4)

| Test | Description |
|------|-------------|
| `tmux` | NOT installed (minimal image) |
| `vim` | NOT installed |
| `fzf` | NOT installed |
| `terminator` | NOT installed |

#### Security (1)

| Test | Description |
|------|-------------|
| `encrypt_env.sh` | In PATH |

</details>

## Architecture

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

### Dockerfile Stages

| Stage | Purpose |
|-------|---------|
| `sys` | User/group creation, locale, timezone, Node.js (GPU only) |
| `base` | Dev tools, Python, build tools, Docker, jq, ripgrep |
| `devel` | Claude Code, entrypoint, non-root user |
| `test` | Bats smoke tests (ephemeral, discarded after verification) |

### Compose Services

| Service | Description |
|---------|-------------|
| `devel` | CPU variant (default) |
| `devel-gpu` | GPU variant with NVIDIA device reservation |
| `test` | Smoke test (profile-gated) |

### Entrypoint Flow

1. Start `dockerd` (DinD) via sudo, wait until ready (up to 30s)
2. Copy OAuth credentials from read-only mount into `data/` directory (first run only)
3. Decrypt `.env.gpg` and export API keys as environment variables (if present)
4. Execute CMD (`bash`)

### Pre-installed Tools

| Tool | Purpose |
|------|---------|
| Claude Code | Anthropic AI CLI |
| Docker (DinD) | Isolated Docker daemon inside container |
| Node.js 20 | Runtime for CLI tools |
| Python 3 | Scripting and development |
| git, curl, wget | Version control and downloads |
| jq, ripgrep | JSON processing and code search |
| make, g++, cmake | Build toolchain |
| tree | Directory visualization |

GPU variant additionally includes: CUDA 13.1.1, cuDNN, OpenCL, Vulkan.

### Container Capabilities

Both services require `SYS_ADMIN`, `NET_ADMIN`, `MKNOD` capabilities with `seccomp:unconfined` for DinD to function. The inner Docker daemon is fully isolated from the host.
