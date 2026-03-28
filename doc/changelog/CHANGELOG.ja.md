# 変更履歴

本ファイルにはすべての重要な変更を記録します。

フォーマットは [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) に基づき、
バージョン番号は [セマンティックバージョニング](https://semver.org/spec/v2.0.0.html) に準拠しています。

## [未リリース]

### 追加
- `scripts/init.sh`：consumer repo のワンコマンド symlink セットアップ
- `Makefile`：統一コマンドエントリ（`make test`、`make lint`、`make migrate` 等）

### 変更
- 管理スクリプトを `scripts/` に移動（ci.sh、migrate.sh、init.sh）— ユーザー向けスクリプトと分離
- `Makefile` と `compose.yaml` はルートに残置（ユーザー操作用）
- `test/` の再構成：`test/unit/`（自体テスト）+ `test/smoke_test/`（consumer 共有テスト）
- `doc/` の再構成：`doc/readme/`、`doc/test/`、`doc/changelog/`（ファイルタイプ別、i18n 対応）
- README：テスト/変更履歴セクションを簡素化、詳細ドキュメントへのリンクに変更
- 124 テスト（旧 114）

## [v0.2.0] - 2026-03-28

### 追加
- `scripts/ci.sh`：CI パイプラインスクリプト（ローカル + リモート）
- `Makefile`：統一コマンドエントリ
- `test/unit/` と `test/smoke_test/` の再構成
- `doc/` の再構成（i18n 対応：readme/、test/、changelog/）
- coverage 権限修正（HOST_UID/HOST_GID による chown）

### 変更
- `smoke_test/` を `test/smoke_test/` に移動（**破壊的変更**：consumer Dockerfile COPY パス変更）
- `compose.yaml` が `scripts/ci.sh --ci` を呼び出すよう変更（inline bash を置換）
- `self-test.yaml` が `scripts/ci.sh` を呼び出すよう変更（docker compose 直接呼び出しを置換）

## [v0.1.0] - 2026-03-28

### 追加
- **共有シェルスクリプト**：`build.sh`、`run.sh`（X11/Wayland サポート付き）、`exec.sh`、`stop.sh`
- **setup.sh**：`.env` ジェネレータ、`docker_setup_helper` から統合（UID/GID、GPU、ワークスペースパス、イメージ名の自動検出）
- **設定ファイル**：bashrc、tmux、terminator、pip 設定（`docker_setup_helper` より）
- **共有 Smoke Tests**（`smoke_test/`）：
  - `script_help.bats` — 16 件のスクリプト help/usage テスト
  - `display_env.bats` — 10 件の X11/Wayland 環境テスト（GUI repos）
  - `test_helper.bash` — 統一 bats ローダー
- **テンプレート自体のテスト**（`test/`）：114 件のテスト（ShellCheck + Bats + Kcov カバレッジ）
- **CI 再利用可能な Workflows**：
  - `build-worker.yaml` — パラメータ化された Docker build + smoke test
  - `release-worker.yaml` — パラメータ化された GitHub Release
  - `self-test.yaml` — テンプレート自体の CI
- **`migrate.sh`**：バッチ移行スクリプト（`docker_setup_helper` から `docker_template` への変換）
- `.hadolint.yaml`：共有 Hadolint ルール
- `.codecov.yaml`：カバレッジ設定
- ドキュメント：README（英語）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 変更
- `setup.sh` デフォルト `_base_path` が 1 レベル上（`/..`）に変更、旧 2 レベル（`/../..`）を置換、新しい `docker_template/setup.sh` の配置に対応

### 移行に関する注意事項
- Consumer repos は `docker_setup_helper/` subtree を `docker_template/` subtree に置換
- ルートのシェルスクリプトは `docker_template/` への symlinks に変更
- ローカル `build-worker.yaml` / `release-worker.yaml` は `main.yaml` 内の再利用可能な workflow 呼び出しに置換
- Dockerfile `CONFIG_SRC` パス変更：`docker_setup_helper/src/config` → `docker_template/config`
- 共有 smoke tests は Dockerfile `COPY docker_template/test/smoke_test/` で読み込み（symlinks ではない — Docker COPY は symlinks を追跡しない）

[未リリース]: https://github.com/ycpss91255-docker/docker_template/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/ycpss91255-docker/docker_template/releases/tag/v0.1.0
