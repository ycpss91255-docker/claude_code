# docker_template

[![Self Test](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml)
[![codecov](https://codecov.io/gh/ycpss91255-docker/docker_template/branch/main/graph/badge.svg)](https://codecov.io/gh/ycpss91255-docker/docker_template)

![Language](https://img.shields.io/badge/Language-Bash-blue?style=flat-square)
![Testing](https://img.shields.io/badge/Testing-Bats-orange?style=flat-square)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Compliant-brightgreen?style=flat-square)
![Coverage](https://img.shields.io/badge/Coverage-Kcov-blueviolet?style=flat-square)
[![License](https://img.shields.io/badge/License-GPL--3.0-yellow?style=flat-square)](./LICENSE)

[ycpss91255-docker](https://github.com/ycpss91255-docker) 組織下所有 Docker 容器 repo 的共用模板。

[English](../../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

## TL;DR

```bash
# 新 repo：加入 subtree + 初始化
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash
./docker_template/scripts/init.sh

# 升級到最新版
make upgrade-check   # 檢查
make upgrade         # pull + 更新版本檔 + workflow tag

# 執行 CI
make test            # ShellCheck + Bats + Kcov
make help            # 顯示所有指令
```

## 概述

此 repo 集中管理所有 Docker 容器 repo 共用的腳本、測試和 CI workflow。各 repo 透過 **git subtree** 拉入此模板，並使用 symlink 引用共用檔案。

### 架構

```mermaid
graph TB
    subgraph docker_template["docker_template（共用 repo）"]
        scripts["build.sh / run.sh / exec.sh / stop.sh<br/>setup.sh / .hadolint.yaml"]
        smoke["test/smoke_test/<br/>script_help.bats<br/>display_env.bats"]
        config["config/<br/>bashrc / tmux / terminator / pip"]
        mgmt["scripts/<br/>init.sh / upgrade.sh / ci.sh / migrate.sh"]
        workflows["可重用 Workflows<br/>build-worker.yaml<br/>release-worker.yaml"]
    end

    subgraph consumer["Consumer Repo（如 ros_noetic）"]
        symlinks["build.sh → docker_template/build.sh<br/>run.sh → docker_template/run.sh<br/>exec.sh / stop.sh / .hadolint.yaml"]
        dockerfile["Dockerfile<br/>compose.yaml<br/>.env.example<br/>script/entrypoint.sh"]
        repo_test["test/smoke_test/<br/>ros_env.bats（repo 專屬）"]
        main_yaml["main.yaml<br/>→ 呼叫可重用 workflows"]
    end

    docker_template -- "git subtree" --> consumer
    scripts -. "symlink" .-> symlinks
    smoke -. "Dockerfile COPY" .-> repo_test
    workflows -. "@tag 引用" .-> main_yaml
```

### CI/CD 流程

```mermaid
flowchart LR
    subgraph local["本地"]
        build_test["./build.sh test"]
        make_test["make test"]
    end

    subgraph ci_container["CI 容器（kcov/kcov）"]
        shellcheck["ShellCheck"]
        hadolint["Hadolint"]
        bats["Bats smoke tests"]
    end

    subgraph github["GitHub Actions"]
        build_worker["build-worker.yaml<br/>（來自 docker_template）"]
        release_worker["release-worker.yaml<br/>（來自 docker_template）"]
    end

    build_test --> ci_container
    make_test -->|"scripts/ci.sh"| ci_container
    shellcheck --> hadolint --> bats

    push["git push / PR"] --> build_worker
    build_worker -->|"docker build test"| ci_container
    tag["git tag v*"] --> release_worker
    release_worker -->|"tar.gz + zip"| release["GitHub Release"]
```

### 包含內容

| 檔案 | 說明 |
|------|------|
| `build.sh` | 建置容器（呼叫 `setup.sh` 產生 `.env`） |
| `run.sh` | 執行容器（支援 X11/Wayland） |
| `exec.sh` | 進入執行中的容器 |
| `stop.sh` | 停止並移除容器 |
| `setup.sh` | 自動偵測系統參數並產生 `.env` |
| `config/` | Shell 設定檔（bashrc、tmux、terminator、pip） |
| `test/smoke_test/` | 給各 consumer repo 使用的共用測試 |
| `.hadolint.yaml` | 共用 Hadolint 規則 |
| `Makefile` | 統一指令入口（`make test`、`make upgrade` 等） |
| `scripts/init.sh` | Consumer repo 首次初始化 symlinks |
| `scripts/upgrade.sh` | Subtree 版本升級 |
| `scripts/ci.sh` | CI pipeline（本地 + 遠端） |
| `.github/workflows/` | 可重用 CI workflows（build + release） |

### 各 repo 自行維護的檔案（不共用）

- `Dockerfile`
- `compose.yaml`
- `.env.example`
- `script/entrypoint.sh`
- `doc/` 和 `README.md`
- Repo 專屬的 smoke test

## 快速開始

### 加入新 repo

```bash
# 1. 加入 subtree
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash

# 2. 初始化 symlinks（一個指令搞定）
./docker_template/scripts/init.sh
```

### 升級

```bash
# 檢查是否有新版
make upgrade-check

# 升級到最新（subtree pull + 版本檔 + workflow tag）
make upgrade

# 或指定版本
./docker_template/scripts/upgrade.sh v0.3.0
```

## CI Reusable Workflows

各 repo 將本地的 `build-worker.yaml` / `release-worker.yaml` 替換為呼叫此 repo 的 reusable workflows：

```yaml
# .github/workflows/main.yaml
jobs:
  call-docker-build:
    uses: ycpss91255-docker/docker_template/.github/workflows/build-worker.yaml@v1
    with:
      image_name: ros_noetic
      build_args: |
        ROS_DISTRO=noetic
        ROS_TAG=ros-base
        UBUNTU_CODENAME=focal

  call-release:
    needs: call-docker-build
    if: startsWith(github.ref, 'refs/tags/')
    uses: ycpss91255-docker/docker_template/.github/workflows/release-worker.yaml@v1
    with:
      archive_name_prefix: ros_noetic
```

### build-worker.yaml 參數

| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| `image_name` | string | 是 | - | 容器映像名稱 |
| `build_args` | string | 否 | `""` | 多行 KEY=VALUE 建置參數 |
| `build_runtime` | boolean | 否 | `true` | 是否建置 runtime stage |

### release-worker.yaml 參數

| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| `archive_name_prefix` | string | 是 | - | Archive 名稱前綴 |
| `extra_files` | string | 否 | `""` | 額外檔案（空格分隔） |

## 本地執行測試

```bash
make test        # 完整 CI（ShellCheck + Bats + Kcov）
make lint        # 只跑 ShellCheck
make clean       # 清除覆蓋率報表
make help        # 顯示所有可用指令
```

或直接執行：
```bash
./scripts/ci.sh          # 完整 CI（透過 docker compose）
./scripts/ci.sh --ci     # 在容器內執行（由 compose 呼叫）
```

## 測試

- **124** 個 template 自身測試（`test/unit/`）
- **22** 個共用 smoke tests（`test/smoke_test/`）

詳見 [TEST.md](../test/TEST.md)。

## 變更記錄

詳見 [CHANGELOG.md](../changelog/CHANGELOG.md)。

## 目錄結構

```
docker_template/
├── build.sh                          # 共用建置腳本
├── run.sh                            # 共用執行腳本（X11/Wayland）
├── exec.sh                           # 共用 exec 腳本
├── stop.sh                           # 共用停止腳本
├── setup.sh                          # .env 產生器
├── config/                           # Shell/工具設定
│   ├── pip/
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       └── tmux/
├── test/
│   ├── smoke_test/                   # 給各 repo 使用的共用測試
│   │   ├── test_helper.bash
│   │   ├── script_help.bats
│   │   └── display_env.bats
│   └── unit/                         # 模板自身測試（124 個）
├── Makefile                          # 統一指令入口（make test/lint/...）
├── compose.yaml                      # Docker CI 執行器
├── .hadolint.yaml                    # 共用 Hadolint 規則
├── scripts/                          # 模板管理工具
│   ├── init.sh                       # Consumer repo symlink 設定
│   ├── upgrade.sh                    # Subtree 版本升級
│   ├── ci.sh                         # CI pipeline（本地 + 遠端）
│   └── migrate.sh                    # 批次 repo 遷移
├── .github/workflows/
│   ├── self-test.yaml                # 模板 CI（呼叫 scripts/ci.sh）
│   ├── build-worker.yaml             # 可重用建置 workflow
│   └── release-worker.yaml           # 可重用發布 workflow
├── doc/
│   ├── readme/                       # README 翻譯
│   ├── test/                         # TEST.md + 翻譯
│   └── changelog/                    # CHANGELOG.md + 翻譯
├── .codecov.yaml
├── .gitignore
├── LICENSE
└── README.md
```
