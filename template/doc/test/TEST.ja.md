# テストドキュメント

テンプレート自体のテスト：合計 **132 件**。

## テストファイル

### test/setup_spec.bats (42)

| テスト項目 | 説明 |
|------------|------|
| `detect_user_info uses USER env when set` | USER 環境変数を使用 |
| `detect_user_info falls back to id -un when USER unset` | USER 未設定時に id コマンドへフォールバック |
| `detect_user_info sets group uid gid correctly` | 全フィールド正しく設定 |
| `detect_hardware returns uname -m output` | ハードウェアアーキテクチャを返却 |
| `detect_docker_hub_user uses docker info username when logged in` | Docker Hub 検出 |
| `detect_docker_hub_user falls back to USER when docker returns empty` | USER フォールバック |
| `detect_docker_hub_user falls back to id -un when USER also unset` | id フォールバック |
| `detect_gpu returns true when nvidia-container-toolkit is installed` | GPU 検出済み |
| `detect_gpu returns false when nvidia-container-toolkit is not installed` | GPU なし |
| `detect_image_name finds *_ws in path` | ワークスペース命名 |
| `detect_image_name finds *_ws at end of path` | パス末尾のワークスペース |
| `detect_image_name prefers docker_* over *_ws in path` | 優先順位チェック |
| `detect_image_name strips docker_ prefix from last dir` | プレフィックス除去 |
| `detect_image_name strips docker_ from absolute root` | ルートパス |
| `detect_image_name returns unknown for plain directory` | unknown フォールバック |
| `detect_image_name returns unknown for generic path` | 一般パス |
| `detect_image_name lowercases the result` | 小文字変換 |
| `detect_ws_path strategy 1: docker_* finds sibling *_ws` | 兄弟ディレクトリスキャン |
| `detect_ws_path strategy 1: docker_* without sibling falls through` | 兄弟なし |
| `detect_ws_path strategy 2: finds _ws component in path` | 上方向探索 |
| `detect_ws_path strategy 3: falls back to parent directory` | 親ディレクトリフォールバック |
| `write_env creates .env with all required variables` | .env 生成 |
| `main creates .env when it does not exist` | 新規 .env |
| `main sources existing .env and reuses valid WS_PATH` | WS_PATH 再利用 |
| `main re-detects WS_PATH when path in .env no longer exists` | 期限切れ WS_PATH |
| `main uses BASH_SOURCE fallback when --base-path not given` | フォールバックパス |
| `default _base_path resolves to repo root, not script dir` | リグレッションテスト |
| `main returns error on unknown argument` | エラー処理 |
| `main returns error when --base-path value is missing` | 値不足 |
| `_msg returns English messages by default` | i18n 英語 |
| `_msg returns Chinese messages when _LANG=zh` | i18n 中国語 |
| `_msg returns Simplified Chinese messages when _LANG=zh-CN` | i18n 簡体中国語 |
| `_msg returns Japanese messages when _LANG=ja` | i18n 日本語 |
| `_detect_lang returns zh for zh_TW.UTF-8` | 言語検出 zh |
| `_detect_lang returns zh-CN for zh_CN.UTF-8` | 言語検出 zh-CN |
| `_detect_lang returns ja for ja_JP.UTF-8` | 言語検出 ja |
| `_detect_lang returns en for en_US.UTF-8` | 言語検出 en |
| `_detect_lang returns en when LANG is unset` | LANG 未設定 |
| `_detect_lang is overridden by SETUP_LANG` | SETUP_LANG オーバーライド |
| `main --lang zh sets Chinese messages` | --lang フラグ |
| `main --lang requires a value` | --lang 値不足 |

### test/unit/template_spec.bats (36)

| テスト項目 | 説明 |
|------------|------|
| `build.sh exists and is executable` | ファイルチェック |
| `run.sh exists and is executable` | ファイルチェック |
| `exec.sh exists and is executable` | ファイルチェック |
| `stop.sh exists and is executable` | ファイルチェック |
| `setup.sh exists and is executable` | ファイルチェック |
| `ci.sh exists and is executable` | ファイルチェック |
| `ci.sh uses set -euo pipefail` | シェル規約 |
| `Makefile exists` | ファイルチェック |
| `Makefile has test target` | Makefile ターゲット |
| `Makefile has lint target` | Makefile ターゲット |
| `Makefile has clean target` | Makefile ターゲット |
| `test/smoke/test_helper.bash exists` | ディレクトリ構造 |
| `test/smoke/script_help.bats exists` | ディレクトリ構造 |
| `test/smoke/display_env.bats exists` | ディレクトリ構造 |
| `test/unit/ directory exists` | ディレクトリ構造 |
| `doc/readme/ directory exists` | ディレクトリ構造 |
| `doc/test/ directory exists` | ディレクトリ構造 |
| `doc/changelog/ directory exists` | ディレクトリ構造 |
| `build.sh references template/setup.sh` | パス参照 |
| `run.sh references template/setup.sh` | パス参照 |
| `build.sh uses set -euo pipefail` | シェル規約 |
| `run.sh uses set -euo pipefail` | シェル規約 |
| `exec.sh uses set -euo pipefail` | シェル規約 |
| `stop.sh uses set -euo pipefail` | シェル規約 |
| `run.sh contains XDG_SESSION_TYPE check` | Wayland サポート |
| `run.sh contains xhost +SI:localuser for wayland` | Wayland xhost |
| `run.sh contains xhost +local: for X11` | X11 xhost |
| `setup.sh default _base_path uses /..` | 旧 ../../ パスなし |
| `setup.sh default _base_path uses single parent traversal` | 正しい探索 |

### test/bashrc_spec.bats (14)

| テスト項目 | 説明 |
|------------|------|
| `defines alias_func` | 関数存在 |
| `defines swc` | 関数存在 |
| `defines color_git_branch` | 関数存在 |
| `defines ros_complete` | 関数存在 |
| `defines ros_source` | 関数存在 |
| `defines ebc alias` | エイリアス存在 |
| `defines sbc alias` | エイリアス存在 |
| `alias_func is called` | 関数呼び出し |
| `color_git_branch is called` | 関数呼び出し |
| `ros_complete is called` | 関数呼び出し |
| `ros_source is called` | 関数呼び出し |
| `swc searches for catkin devel/setup.bash` | 内容チェック |
| `ros_source references ROS_DISTRO` | 内容チェック |
| `color_git_branch sets PS1` | 内容チェック |

### test/pip_setup_spec.bats (3)

| テスト項目 | 説明 |
|------------|------|
| `pip setup.sh runs pip install with requirements.txt` | pip インストール |
| `pip setup.sh sets PIP_BREAK_SYSTEM_PACKAGES=1` | 環境変数設定 |
| `pip setup.sh fails when pip is not available` | エラー処理 |

### test/terminator_config_spec.bats (10)

| テスト項目 | 説明 |
|------------|------|
| `has [global_config] section` | 設定セクション |
| `has [keybindings] section` | 設定セクション |
| `has [profiles] section` | 設定セクション |
| `has [layouts] section` | 設定セクション |
| `has [plugins] section` | 設定セクション |
| `profiles has [[default]]` | デフォルトプロファイル |
| `default profile disables system font` | フォント設定 |
| `default profile has infinite scrollback` | 無限スクロール |
| `layouts has Window type` | レイアウトタイプ |
| `layouts has Terminal type` | レイアウトタイプ |

### test/terminator_setup_spec.bats (7)

| テスト項目 | 説明 |
|------------|------|
| `check_deps returns 0 when terminator is installed` | 依存チェック成功 |
| `check_deps fails when terminator is not installed` | 依存チェック失敗 |
| `_entry_point calls main when deps pass` | エントリポイント |
| `_entry_point fails when deps missing` | エントリポイント失敗 |
| `main creates terminator config directory` | ディレクトリ作成 |
| `main copies terminator config file` | ファイルコピー |
| `main calls chown with correct user and group` | 権限設定 |

### test/tmux_conf_spec.bats (12)

| テスト項目 | 説明 |
|------------|------|
| `defines prefix key` | コア設定 |
| `sets default shell to bash` | シェル設定 |
| `sets default terminal` | ターミナル設定 |
| `enables mouse support` | マウスサポート |
| `enables vi status-keys` | Vi モード |
| `enables vi mode-keys` | Vi モード |
| `defines split-window bindings` | キーバインド |
| `defines reload config binding` | キーバインド |
| `enables status bar` | ステータスバー |
| `sets status bar position` | ステータスバー |
| `declares tpm plugin` | プラグインマネージャ |
| `initializes tpm at end of file` | プラグイン初期化 |

### test/tmux_setup_spec.bats (8)

| テスト項目 | 説明 |
|------------|------|
| `check_deps returns 0 when tmux and git are installed` | 依存チェック成功 |
| `check_deps fails when tmux is not installed` | tmux 不足 |
| `check_deps fails when git is not installed` | git 不足 |
| `_entry_point calls main when deps pass` | エントリポイント |
| `_entry_point fails when deps missing` | エントリポイント失敗 |
| `main clones tpm repository` | TPM クローン |
| `main creates tmux config directory` | ディレクトリ作成 |
| `main copies tmux.conf to config directory` | ファイルコピー |
