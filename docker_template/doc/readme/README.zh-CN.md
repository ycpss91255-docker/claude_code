# docker_template

[![Self Test](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml)
[![codecov](https://codecov.io/gh/ycpss91255-docker/docker_template/branch/main/graph/badge.svg)](https://codecov.io/gh/ycpss91255-docker/docker_template)

![Language](https://img.shields.io/badge/Language-Bash-blue?style=flat-square)
![Testing](https://img.shields.io/badge/Testing-Bats-orange?style=flat-square)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Compliant-brightgreen?style=flat-square)
![Coverage](https://img.shields.io/badge/Coverage-Kcov-blueviolet?style=flat-square)
[![License](https://img.shields.io/badge/License-GPL--3.0-yellow?style=flat-square)](./LICENSE)

[ycpss91255-docker](https://github.com/ycpss91255-docker) 组织下所有 Docker 容器 repo 的共用模板。

[English](../../README.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md)

## TL;DR

```bash
# 新 repo：添加 subtree + 初始化
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash
./docker_template/scripts/init.sh

# 升级到最新版
make upgrade-check   # 检查
make upgrade         # pull + 更新版本文件 + workflow tag

# 运行 CI
make test            # ShellCheck + Bats + Kcov
make help            # 显示所有命令
```

## 概述

此 repo 集中管理所有 Docker 容器 repo 共用的脚本、测试和 CI workflow。各 repo 通过 **git subtree** 拉入此模板，并使用 symlink 引用共用文件。

### 架构

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
        repo_test["test/smoke_test/<br/>ros_env.bats（repo 专属）"]
        main_yaml["main.yaml<br/>→ 调用可重用 workflows"]
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
        build_worker["build-worker.yaml<br/>（来自 docker_template）"]
        release_worker["release-worker.yaml<br/>（来自 docker_template）"]
    end

    build_test --> ci_container
    make_test -->|"scripts/ci.sh"| ci_container
    shellcheck --> hadolint --> bats

    push["git push / PR"] --> build_worker
    build_worker -->|"docker build test"| ci_container
    tag["git tag v*"] --> release_worker
    release_worker -->|"tar.gz + zip"| release["GitHub Release"]
```

### 包含内容

| 文件 | 说明 |
|------|------|
| `build.sh` | 构建容器（调用 `setup.sh` 生成 `.env`） |
| `run.sh` | 运行容器（支持 X11/Wayland） |
| `exec.sh` | 进入运行中的容器 |
| `stop.sh` | 停止并移除容器 |
| `setup.sh` | 自动检测系统参数并生成 `.env` |
| `config/` | Shell 配置文件（bashrc、tmux、terminator、pip） |
| `test/smoke_test/` | 给各 consumer repo 使用的共用测试 |
| `.hadolint.yaml` | 共用 Hadolint 规则 |
| `Makefile` | 统一命令入口（`make test`、`make upgrade` 等） |
| `scripts/init.sh` | Consumer repo 首次初始化 symlinks |
| `scripts/upgrade.sh` | Subtree 版本升级 |
| `scripts/ci.sh` | CI pipeline（本地 + 远端） |
| `.github/workflows/` | 可重用 CI workflows（build + release） |

### 各 repo 自行维护的文件（不共用）

- `Dockerfile`
- `compose.yaml`
- `.env.example`
- `script/entrypoint.sh`
- `doc/` 和 `README.md`
- Repo 专属的 smoke test

## 快速开始

### 添加到新 repo

```bash
# 1. 添加 subtree
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash

# 2. 初始化 symlinks（一个命令搞定）
./docker_template/scripts/init.sh
```

### 升级

```bash
# 检查是否有新版
make upgrade-check

# 升级到最新（subtree pull + 版本文件 + workflow tag）
make upgrade

# 或指定版本
./docker_template/scripts/upgrade.sh v0.3.0
```

## CI Reusable Workflows

各 repo 将本地的 `build-worker.yaml` / `release-worker.yaml` 替换为调用此 repo 的 reusable workflows：

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

### build-worker.yaml 参数

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `image_name` | string | 是 | - | 容器镜像名称 |
| `build_args` | string | 否 | `""` | 多行 KEY=VALUE 构建参数 |
| `build_runtime` | boolean | 否 | `true` | 是否构建 runtime stage |

### release-worker.yaml 参数

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `archive_name_prefix` | string | 是 | - | Archive 名称前缀 |
| `extra_files` | string | 否 | `""` | 额外文件（空格分隔） |

## 本地运行测试

```bash
make test        # 完整 CI（ShellCheck + Bats + Kcov）
make lint        # 只运行 ShellCheck
make clean       # 清除覆盖率报告
make help        # 显示所有可用命令
```

或直接运行：
```bash
./scripts/ci.sh          # 完整 CI（通过 docker compose）
./scripts/ci.sh --ci     # 在容器内运行（由 compose 调用）
```

## 测试

- **124** 个 template 自身测试（`test/unit/`）
- **22** 个共用 smoke tests（`test/smoke_test/`）

详见 [TEST.md](../test/TEST.md)。

## 变更记录

详见 [CHANGELOG.md](../changelog/CHANGELOG.md)。

## 目录结构

```
docker_template/
├── build.sh                          # 共用构建脚本
├── run.sh                            # 共用运行脚本（X11/Wayland）
├── exec.sh                           # 共用 exec 脚本
├── stop.sh                           # 共用停止脚本
├── setup.sh                          # .env 生成器
├── config/                           # Shell/工具配置
│   ├── pip/
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       └── tmux/
├── test/
│   ├── smoke_test/                   # 给各 repo 使用的共用测试
│   │   ├── test_helper.bash
│   │   ├── script_help.bats
│   │   └── display_env.bats
│   └── unit/                         # 模板自身测试（124 个）
├── Makefile                          # 统一命令入口（make test/lint/...）
├── compose.yaml                      # Docker CI 运行器
├── .hadolint.yaml                    # 共用 Hadolint 规则
├── scripts/                          # 模板管理工具
│   ├── init.sh                       # Consumer repo symlink 设置
│   ├── upgrade.sh                    # Subtree 版本升级
│   ├── ci.sh                         # CI pipeline（本地 + 远端）
│   └── migrate.sh                    # 批量 repo 迁移
├── .github/workflows/
│   ├── self-test.yaml                # 模板 CI（调用 scripts/ci.sh）
│   ├── build-worker.yaml             # 可重用构建 workflow
│   └── release-worker.yaml           # 可重用发布 workflow
├── doc/
│   ├── readme/                       # README 翻译
│   ├── test/                         # TEST.md + 翻译
│   └── changelog/                    # CHANGELOG.md + 翻译
├── .codecov.yaml
├── .gitignore
├── LICENSE
└── README.md
```
