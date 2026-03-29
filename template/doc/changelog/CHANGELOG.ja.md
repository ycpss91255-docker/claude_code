# 変更履歴

本ファイルはすべての重要な変更を記録します。

フォーマットは [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) に基づき、
バージョン番号は [セマンティックバージョニング](https://semver.org/spec/v2.0.0.html) に従います。

## [v0.4.0] - 2026-03-29

### 変更
- `config/` を `script/config/` からルートに戻す（v0.3.0 で移動、設定ファイルは script/ に置くべきではない）
- `self-test.yaml` release archive 修正：存在しないルート `setup.sh` 参照を削除
- mermaid アーキテクチャ図修正：`setup.sh` を正しい `script/` ボックスに表示
- zh-TW / zh-CN README に目次（Table of Contents）を追加
- 翻訳同期：「含まれるもの」テーブルに `Makefile.ci` エントリを追加
- 翻訳同期：「ローカルテスト実行」を正しい `make -f Makefile.ci` コマンドに修正
- `test/smoke_test/` → `test/smoke/` にリネーム

## [v0.3.0] - 2026-03-29

### 変更
- **破壊的変更**: Repo リネーム `docker_template` → `template`
- **破壊的変更**: `setup.sh` → `script/setup.sh` に移動
- **破壊的変更**: `config/` → `script/config/` に移動（v0.4.0 で戻す）
- すべてのシェルスクリプトに Google Shell Style Guide を適用
- `Makefile` を `Makefile`（repo 用）+ `Makefile.ci`（CI 用）に分割
- ドキュメントのディレクトリ構造、テスト数、bashrc スタイルを修正
- 132 テスト（旧 124）

### 移行注意事項
- Other repos: subtree prefix を `docker_template/` から `template/` に変更
- Dockerfile `CONFIG_SRC` パス: `docker_template/config` → `template/config`
- Symlinks: `docker_template/*.sh` → `template/*.sh`

## [v0.2.0] - 2026-03-28

### 追加
- `script/ci.sh`: CI パイプラインスクリプト（ローカル + リモート）
- `Makefile`: 統一コマンドエントリ
- `test/unit/` と `test/smoke_test/` を再構成
- `doc/` を再構成（i18n 対応: readme/、test/、changelog/）
- カバレッジ権限の修正（HOST_UID/HOST_GID で chown）

### 変更
- `smoke_test/` を `test/smoke_test/` に移動（**破壊的変更**: Dockerfile COPY パス変更）
- `compose.yaml` が `script/ci.sh --ci` を呼び出すように変更（inline bash の代替）
- `self-test.yaml` が `script/ci.sh` を呼び出すように変更（docker compose 直接呼び出しの代替）

## [v0.1.0] - 2026-03-28

### 追加
- **共有シェルスクリプト**: `build.sh`、`run.sh`（X11/Wayland 対応）、`exec.sh`、`stop.sh`
- **setup.sh**: `.env` ジェネレータ（`docker_setup_helper` から統合、UID/GID・GPU・ワークスペースパス・イメージ名の自動検出）
- **設定ファイル**: bashrc、tmux、terminator、pip 設定（`docker_setup_helper` から）
- **共有 Smoke Tests**（`smoke_test/`）:
  - `script_help.bats` — 16 スクリプト help/usage テスト
  - `display_env.bats` — 10 X11/Wayland 環境テスト（GUI repos）
  - `test_helper.bash` — 統一 bats ローダー
- **テンプレート自身のテスト**（`test/`）: 114 テスト（ShellCheck + Bats + Kcov カバレッジ）
- **CI 再利用可能 Workflows**:
  - `build-worker.yaml` — パラメータ化 Docker build + smoke test
  - `release-worker.yaml` — パラメータ化 GitHub Release
  - `self-test.yaml` — テンプレート自身の CI
- **`migrate.sh`**: バッチ移行スクリプト（`docker_setup_helper` から `template` への変換）
- `.hadolint.yaml`: 共有 Hadolint ルール
- `.codecov.yaml`: カバレッジ設定
- ドキュメント: README（英語）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 変更
- `setup.sh` デフォルト `_base_path` を 1 レベル上（`/..`）に変更（新しい `template/setup.sh` の位置に合わせる）

### 移行注意事項
- `docker_setup_helper/` subtree を `template/` subtree に置換
- ルートのシェルスクリプトを `template/` への symlinks に変更
- ローカル `build-worker.yaml` / `release-worker.yaml` を `main.yaml` の再利用可能 workflow 呼び出しに置換
- Dockerfile `CONFIG_SRC` パス: `docker_setup_helper/src/config` → `template/config`
- 共有 smoke tests は Dockerfile `COPY template/test/smoke_test/` で読み込み（symlinks ではない）

[v0.4.0]: https://github.com/ycpss91255-docker/template/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/ycpss91255-docker/template/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/ycpss91255-docker/template/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/ycpss91255-docker/template/releases/tag/v0.1.0
