# docker_template

[![Self Test](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml)
[![codecov](https://codecov.io/gh/ycpss91255-docker/docker_template/branch/main/graph/badge.svg)](https://codecov.io/gh/ycpss91255-docker/docker_template)

![Language](https://img.shields.io/badge/Language-Bash-blue?style=flat-square)
![Testing](https://img.shields.io/badge/Testing-Bats-orange?style=flat-square)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Compliant-brightgreen?style=flat-square)
![Coverage](https://img.shields.io/badge/Coverage-Kcov-blueviolet?style=flat-square)
[![License](https://img.shields.io/badge/License-GPL--3.0-yellow?style=flat-square)](./LICENSE)

[ycpss91255-docker](https://github.com/ycpss91255-docker) 組織のすべての Docker コンテナ repo 用共有テンプレート。

[English](../../README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

## TL;DR

```bash
# 新規 repo：subtree 追加 + 初期化
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash
./docker_template/scripts/init.sh

# 最新版にアップグレード
make upgrade-check   # 確認
make upgrade         # pull + バージョンファイル + workflow tag 更新

# CI 実行
make test            # ShellCheck + Bats + Kcov
make help            # 全コマンド表示
```

## 概要

本 repo は、すべての Docker コンテナ repo で共有されるスクリプト、テスト、CI workflow を一元管理しています。15 以上の repo で同一ファイルを個別管理する代わりに、各 repo が **git subtree** としてこのテンプレートを取り込み、symlink で参照します。

### アーキテクチャ

```mermaid
graph TB
    subgraph docker_template["docker_template（共有 repo）"]
        scripts["build.sh / run.sh / exec.sh / stop.sh<br/>setup.sh / .hadolint.yaml"]
        smoke["test/smoke_test/<br/>script_help.bats<br/>display_env.bats"]
        config["config/<br/>bashrc / tmux / terminator / pip"]
        mgmt["scripts/<br/>init.sh / upgrade.sh / ci.sh / migrate.sh"]
        workflows["再利用可能な Workflows<br/>build-worker.yaml<br/>release-worker.yaml"]
    end

    subgraph consumer["Consumer Repo（例: ros_noetic）"]
        symlinks["build.sh → docker_template/build.sh<br/>run.sh → docker_template/run.sh<br/>exec.sh / stop.sh / .hadolint.yaml"]
        dockerfile["Dockerfile<br/>compose.yaml<br/>.env.example<br/>script/entrypoint.sh"]
        repo_test["test/smoke_test/<br/>ros_env.bats（repo 固有）"]
        main_yaml["main.yaml<br/>→ 再利用可能な workflows を呼び出し"]
    end

    docker_template -- "git subtree" --> consumer
    scripts -. "symlink" .-> symlinks
    smoke -. "Dockerfile COPY" .-> repo_test
    workflows -. "@tag 参照" .-> main_yaml
```

### CI/CD フロー

```mermaid
flowchart LR
    subgraph local["ローカル"]
        build_test["./build.sh test"]
        make_test["make test"]
    end

    subgraph ci_container["CI コンテナ（kcov/kcov）"]
        shellcheck["ShellCheck"]
        hadolint["Hadolint"]
        bats["Bats smoke tests"]
    end

    subgraph github["GitHub Actions"]
        build_worker["build-worker.yaml<br/>（docker_template より）"]
        release_worker["release-worker.yaml<br/>（docker_template より）"]
    end

    build_test --> ci_container
    make_test -->|"scripts/ci.sh"| ci_container
    shellcheck --> hadolint --> bats

    push["git push / PR"] --> build_worker
    build_worker -->|"docker build test"| ci_container
    tag["git tag v*"] --> release_worker
    release_worker -->|"tar.gz + zip"| release["GitHub Release"]
```

### 含まれるもの

| ファイル | 説明 |
|----------|------|
| `build.sh` | コンテナビルド（`setup.sh` を呼び出して `.env` を生成） |
| `run.sh` | コンテナ実行（X11/Wayland 対応） |
| `exec.sh` | 実行中のコンテナに入る |
| `stop.sh` | コンテナの停止・削除 |
| `setup.sh` | システムパラメータの自動検出と `.env` 生成 |
| `config/` | シェル設定ファイル（bashrc、tmux、terminator、pip） |
| `test/smoke_test/` | 各 consumer repo 用の共有テスト |
| `.hadolint.yaml` | 共有 Hadolint ルール |
| `Makefile` | 統一コマンドエントリ（`make test`、`make upgrade` 等） |
| `scripts/init.sh` | Consumer repo の初回 symlink セットアップ |
| `scripts/upgrade.sh` | Subtree バージョンアップグレード |
| `scripts/ci.sh` | CI パイプライン（ローカル + リモート） |
| `.github/workflows/` | 再利用可能な CI workflows（build + release） |

### 各 repo で個別管理するファイル（共有しない）

- `Dockerfile`
- `compose.yaml`
- `.env.example`
- `script/entrypoint.sh`
- `doc/` と `README.md`
- Repo 固有の smoke test

## クイックスタート

### 新規 repo への追加

```bash
# 1. subtree 追加
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash

# 2. symlink 初期化（ワンコマンド）
./docker_template/scripts/init.sh
```

### アップグレード

```bash
# 新バージョンの確認
make upgrade-check

# 最新にアップグレード（subtree pull + バージョンファイル + workflow tag）
make upgrade

# バージョン指定
./docker_template/scripts/upgrade.sh v0.3.0
```

## CI Reusable Workflows

各 repo のローカル `build-worker.yaml` / `release-worker.yaml` を、本 repo の reusable workflows 呼び出しに置き換えます：

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

### build-worker.yaml パラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|------------|------|------|------------|------|
| `image_name` | string | はい | - | コンテナイメージ名 |
| `build_args` | string | いいえ | `""` | 複数行 KEY=VALUE ビルド引数 |
| `build_runtime` | boolean | いいえ | `true` | runtime stage をビルドするか |

### release-worker.yaml パラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|------------|------|------|------------|------|
| `archive_name_prefix` | string | はい | - | アーカイブ名プレフィックス |
| `extra_files` | string | いいえ | `""` | 追加ファイル（スペース区切り） |

## ローカルテスト実行

```bash
make test        # フル CI（ShellCheck + Bats + Kcov）
make lint        # ShellCheck のみ
make clean       # カバレッジレポート削除
make help        # 全ターゲット表示
```

直接実行：
```bash
./scripts/ci.sh          # フル CI（docker compose 経由）
./scripts/ci.sh --ci     # コンテナ内で実行（compose から呼び出し）
```

## テスト

- **124** テンプレート自身のテスト（`test/unit/`）
- **22** 共有 smoke tests（`test/smoke_test/`）

詳細は [TEST.md](../test/TEST.md) を参照。

## 変更履歴

[CHANGELOG.md](../changelog/CHANGELOG.md) を参照。

## ディレクトリ構造

```
docker_template/
├── build.sh                          # 共有ビルドスクリプト
├── run.sh                            # 共有実行スクリプト（X11/Wayland）
├── exec.sh                           # 共有 exec スクリプト
├── stop.sh                           # 共有停止スクリプト
├── setup.sh                          # .env ジェネレータ
├── config/                           # シェル/ツール設定
│   ├── pip/
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       └── tmux/
├── test/
│   ├── smoke_test/                   # 各 repo 用の共有テスト
│   │   ├── test_helper.bash
│   │   ├── script_help.bats
│   │   └── display_env.bats
│   └── unit/                         # テンプレート自身のテスト（124 件）
├── Makefile                          # 統一コマンドエントリ（make test/lint/...）
├── compose.yaml                      # Docker CI ランナー
├── .hadolint.yaml                    # 共有 Hadolint ルール
├── scripts/                          # テンプレート管理ツール
│   ├── init.sh                       # Consumer repo symlink セットアップ
│   ├── upgrade.sh                    # Subtree バージョンアップグレード
│   ├── ci.sh                         # CI パイプライン（ローカル + リモート）
│   └── migrate.sh                    # バッチ repo 移行
├── .github/workflows/
│   ├── self-test.yaml                # テンプレート CI（scripts/ci.sh を呼び出し）
│   ├── build-worker.yaml             # 再利用可能なビルド workflow
│   └── release-worker.yaml           # 再利用可能なリリース workflow
├── doc/
│   ├── readme/                       # README 翻訳
│   ├── test/                         # TEST.md + 翻訳
│   └── changelog/                    # CHANGELOG.md + 翻訳
├── .codecov.yaml
├── .gitignore
├── LICENSE
└── README.md
```
