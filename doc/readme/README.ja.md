# template

[![Self Test](https://github.com/ycpss91255-docker/template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/template/actions/workflows/self-test.yaml)
[![codecov](https://codecov.io/gh/ycpss91255-docker/template/branch/main/graph/badge.svg)](https://codecov.io/gh/ycpss91255-docker/template)

![Language](https://img.shields.io/badge/Language-Bash-blue?style=flat-square)
![Testing](https://img.shields.io/badge/Testing-Bats-orange?style=flat-square)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Compliant-brightgreen?style=flat-square)
![Coverage](https://img.shields.io/badge/Coverage-Kcov-blueviolet?style=flat-square)
[![License](https://img.shields.io/badge/License-GPL--3.0-yellow?style=flat-square)](./LICENSE)

[ycpss91255-docker](https://github.com/ycpss91255-docker) 組織のすべての Docker コンテナ repo 用共有テンプレート。

**[English](../../README.md)** | **[繁體中文](README.zh-TW.md)** | **[简体中文](README.zh-CN.md)** | **[日本語](README.ja.md)**

---

## 目次

- [TL;DR](#tldr)
- [概要](#概要)
- [クイックスタート](#クイックスタート)
- [CI Reusable Workflows](#ci-reusable-workflows)
- [ローカルテスト実行](#ローカルテスト実行)
- [テスト](#テスト)
- [ディレクトリ構造](#ディレクトリ構造)

---

## TL;DR

```bash
# 新規 repo：subtree 追加 + 初期化
git subtree add --prefix=template \
    git@github.com:ycpss91255-docker/template.git main --squash
./template/init.sh

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
    subgraph template["template（共有 repo）"]
        scripts[".hadolint.yaml / Makefile.ci / compose.yaml"]
        smoke["test/smoke/<br/>script_help.bats<br/>display_env.bats"]
        config["config/<br/>bashrc / tmux / terminator / pip"]
        mgmt["script/docker/<br/>build.sh / run.sh / exec.sh / stop.sh / setup.sh"]
        workflows["再利用可能な Workflows<br/>build-worker.yaml<br/>release-worker.yaml"]
    end

    subgraph consumer["Docker Repo（例: ros_noetic）"]
        symlinks["build.sh → template/script/docker/build.sh<br/>run.sh → template/script/docker/run.sh<br/>exec.sh / stop.sh / .hadolint.yaml"]
        dockerfile["Dockerfile<br/>compose.yaml<br/>.env.example<br/>script/entrypoint.sh"]
        repo_test["test/smoke/<br/>ros_env.bats（repo 固有）"]
        main_yaml["main.yaml<br/>→ 再利用可能な workflows を呼び出し"]
    end

    template -- "git subtree" --> consumer
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
        build_worker["build-worker.yaml<br/>（template より）"]
        release_worker["release-worker.yaml<br/>（template より）"]
    end

    build_test --> ci_container
    make_test -->|"script/ci/ci.sh"| ci_container
    shellcheck --> hadolint --> bats

    push["git push / PR"] --> build_worker
    build_worker -->|"docker build test"| ci_container
    tag["git tag v*"] --> release_worker
    release_worker -->|"tar.gz + zip"| release["GitHub Release"]
```

### 含まれるもの

| ファイル | 説明 |
|----------|------|
| `build.sh` | コンテナビルド（`script/docker/setup.sh` を呼び出して `.env` を生成） |
| `run.sh` | コンテナ実行（X11/Wayland 対応） |
| `exec.sh` | 実行中のコンテナに入る |
| `stop.sh` | コンテナの停止・削除 |
| `script/docker/setup.sh` | システムパラメータの自動検出と `.env` 生成 |
| `script/docker/_lib.sh` | 共有 helper（`_load_env`、`_compose`、`_compose_project` など） |
| `script/docker/i18n.sh` | 共有言語検出（`_detect_lang`、`_LANG`） |
| `config/` | シェル設定ファイル（bashrc、tmux、terminator、pip）+ IMAGE_NAME ルール |
| `test/smoke/` | 共有 smoke テスト + runtime assertion helpers（下記参照） |
| `test/unit/` | Template 自身のテスト（bats + kcov） |
| `test/integration/` | Level-1 `init.sh` 統合テスト |
| `.hadolint.yaml` | 共有 Hadolint ルール |
| `Makefile` | Repo コマンドエントリ（`make build`、`make run`、`make stop` 等） |
| `Makefile.ci` | Template CI コマンドエントリ（`make test`、`make lint` 等） |
| `init.sh` | 初回 symlink セットアップ + 新 repo スケルトン生成 |
| `upgrade.sh` | Subtree バージョンアップグレード |
| `script/ci/ci.sh` | CI パイプライン（ローカル + リモート） |
| `dockerfile/Dockerfile.example` | 新 repo のマルチステージ Dockerfile テンプレート |
| `dockerfile/Dockerfile.test-tools` | プリビルド lint/test ツール image（shellcheck、hadolint、bats、bats-mock） |
| `.github/workflows/` | 再利用可能な CI workflows（build + release） |

### Dockerfile ステージ（規約）

ダウンストリーム repo は `dockerfile/Dockerfile.example` で定義される標準のマルチステージ構成に従います。
すべてのステージは `ARG BASE_IMAGE` で指定されるベース image を共有します。

| ステージ | 親ステージ | 用途 | 出荷 |
|----------|------------|------|------|
| `sys` | `${BASE_IMAGE}` | ユーザー/グループ、sudo、タイムゾーン、ロケール、APT mirror | 中間 |
| `base` | `sys` | 開発ツールと言語パッケージ | 中間 |
| `devel` | `base` | アプリ固有ツール + `entrypoint.sh` + PlotJuggler（env repos） | **はい**（主成果物） |
| `test` | `devel` | 一時的：ShellCheck + Hadolint + Bats smoke（いずれも `test-tools:local` から） | いいえ（build 後破棄） |
| `runtime-base`（任意） | `sys` | 最小 runtime 依存（sudo、tini） | 中間 |
| `runtime`（任意） | `runtime-base` | 軽量 runtime image（application repos で使用） | 有効時に出荷 |

補足：
- developer image のみを出荷する repo（`env/*`）は `runtime-base` /
  `runtime` をスキップし、該当セクションは `Dockerfile.example` 内で
  コメントアウトしたままにします。
- `test` は常に `devel` を継承するため、`test/smoke/<repo>_env.bats` の
  runtime assertion が確認するバイナリやファイルは、ユーザーが
  `docker run ... <repo>:devel` で目にするものと一致します。
- `Dockerfile.test-tools` は別途 `test-tools:local` image をビルドし
  （上記ステージ連鎖には含まれません）、`test` ステージが
  `COPY --from=test-tools:local` で bats / shellcheck / hadolint
  バイナリを取り込みます。

### Smoke test ヘルパー（ダウンストリーム repo 用）

`test/smoke/test_helper.bash`（各 smoke spec が
`load "${BATS_TEST_DIRNAME}/test_helper"` で読み込み）が runtime
assertion helpers のセットを提供します。ダウンストリーム repo は
素の `[ -f ... ]` / `command -v` より優先してこれらの helper を使用
すべきです。失敗時は欠落している成果物を直接指し示す decorated な
診断メッセージを出力します。

| Helper | 用法 |
|--------|------|
| `assert_cmd_installed <cmd>` | `<cmd>` が `PATH` 上にない場合に失敗 |
| `assert_cmd_runs <cmd> [flag]` | `<cmd> <flag>` が 0 以外で終了した場合に失敗（flag のデフォルトは `--version`） |
| `assert_file_exists <path>` | `<path>` が通常ファイルでない場合に失敗 |
| `assert_dir_exists <path>` | `<path>` がディレクトリでない場合に失敗 |
| `assert_file_owned_by <user> <path>` | `<path>` の所有者が `<user>` でない場合に失敗 |
| `assert_pip_pkg <pkg>` | `pip show <pkg>` が 0 以外で終了した場合に失敗 |

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
git subtree add --prefix=template \
    git@github.com:ycpss91255-docker/template.git main --squash

# 2. symlink 初期化（ワンコマンド）
./template/init.sh
```

### アップグレード

```bash
# 新バージョンの確認
make upgrade-check

# 最新にアップグレード（subtree pull + バージョンファイル + workflow tag）
make upgrade

# バージョン指定
./template/upgrade.sh v0.3.0
```

## CI Reusable Workflows

各 repo のローカル `build-worker.yaml` / `release-worker.yaml` を、本 repo の reusable workflows 呼び出しに置き換えます：

```yaml
# .github/workflows/main.yaml
jobs:
  call-docker-build:
    uses: ycpss91255-docker/template/.github/workflows/build-worker.yaml@v1
    with:
      image_name: ros_noetic
      build_args: |
        ROS_DISTRO=noetic
        ROS_TAG=ros-base
        UBUNTU_CODENAME=focal

  call-release:
    needs: call-docker-build
    if: startsWith(github.ref, 'refs/tags/')
    uses: ycpss91255-docker/template/.github/workflows/release-worker.yaml@v1
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

`Makefile.ci`（template ルートから）を使用：
```bash
make -f Makefile.ci test        # フル CI（ShellCheck + Bats + Kcov）docker compose 経由
make -f Makefile.ci lint        # ShellCheck のみ
make -f Makefile.ci clean       # カバレッジレポート削除
make help        # repo ターゲット表示
make -f Makefile.ci help  # CI ターゲット表示
```

直接実行：
```bash
./script/ci/ci.sh          # フル CI（docker compose 経由）
./script/ci/ci.sh --ci     # コンテナ内で実行（compose から呼び出し）
```

## テスト

詳細は [TEST.md](../test/TEST.md) を参照。

## ディレクトリ構造

```
template/
├── init.sh                           # repo 初期化（新規または既存）
├── upgrade.sh                        # template subtree バージョンアップグレード
├── script/
│   ├── docker/                       # Docker 操作スクリプト（各 repo symlink）
│   │   ├── build.sh
│   │   ├── run.sh
│   │   ├── exec.sh
│   │   ├── stop.sh
│   │   ├── setup.sh                  # .env ジェネレータ
│   │   ├── _lib.sh                   # 共有 helper（_load_env、_compose、_compose_project）
│   │   ├── i18n.sh                   # 共有言語検出（_detect_lang、_LANG）
│   │   └── Makefile
│   └── ci/
│       └── ci.sh                     # CI パイプライン（ローカル + リモート）
├── dockerfile/
│   ├── Dockerfile.test-tools         # プリビルド lint/test ツール image
│   └── Dockerfile.example            # 新 repo の Dockerfile テンプレート（sys → base → devel → test → [runtime]）
├── config/                           # シェル/ツール設定 + IMAGE_NAME ルール
│   ├── image_name.conf               # デフォルト IMAGE_NAME 検出ルール
│   ├── pip/
│   │   ├── setup.sh
│   │   └── requirements.txt
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       │   ├── setup.sh
│       │   └── config
│       └── tmux/
│           ├── setup.sh
│           └── tmux.conf
├── test/
│   ├── smoke/                        # 共有 smoke テスト + runtime assertion helpers
│   │   ├── test_helper.bash          #  → assert_cmd_installed / _runs / file / dir / owned_by / pip_pkg
│   │   ├── script_help.bats
│   │   └── display_env.bats
│   ├── unit/                         # テンプレート自身のテスト（bats + kcov）
│   │   ├── test_helper.bash
│   │   ├── bashrc_spec.bats
│   │   ├── ci_spec.bats              # ci.sh _install_deps
│   │   ├── lib_spec.bats             # _lib.sh
│   │   ├── pip_setup_spec.bats
│   │   ├── setup_spec.bats
│   │   ├── smoke_helper_spec.bats    # Runtime assertion helpers
│   │   ├── template_spec.bats
│   │   ├── terminator_config_spec.bats
│   │   ├── terminator_setup_spec.bats
│   │   ├── tmux_conf_spec.bats
│   │   └── tmux_setup_spec.bats
│   └── integration/
│       └── init_new_repo_spec.bats   # Level-1 init.sh 統合テスト
├── Makefile.ci                       # テンプレート CI エントリ（make test/lint/...）
├── compose.yaml                      # Docker CI ランナー
├── .hadolint.yaml                    # 共有 Hadolint ルール
├── codecov.yml
├── .github/workflows/
│   ├── self-test.yaml                # テンプレート CI
│   ├── build-worker.yaml             # 再利用可能なビルド workflow
│   └── release-worker.yaml           # 再利用可能なリリース workflow
├── doc/
│   ├── readme/                       # README 翻訳（zh-TW / zh-CN / ja）
│   ├── test/TEST.md                  # テスト一覧
│   └── changelog/CHANGELOG.md        # リリース記録
├── .gitignore
├── LICENSE
└── README.md
```
