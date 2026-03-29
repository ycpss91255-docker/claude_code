# 測試文件

模板自身測試：共 **132 個**。

## 測試檔案

### test/setup_spec.bats (42)

| 測試項目 | 說明 |
|----------|------|
| `detect_user_info uses USER env when set` | 使用 USER 環境變數 |
| `detect_user_info falls back to id -un when USER unset` | USER 未設定時退回 id 指令 |
| `detect_user_info sets group uid gid correctly` | 所有欄位正確填入 |
| `detect_hardware returns uname -m output` | 回傳硬體架構 |
| `detect_docker_hub_user uses docker info username when logged in` | Docker Hub 偵測 |
| `detect_docker_hub_user falls back to USER when docker returns empty` | USER 退回 |
| `detect_docker_hub_user falls back to id -un when USER also unset` | id 退回 |
| `detect_gpu returns true when nvidia-container-toolkit is installed` | GPU 已偵測 |
| `detect_gpu returns false when nvidia-container-toolkit is not installed` | 無 GPU |
| `detect_image_name finds *_ws in path` | 工作區命名 |
| `detect_image_name finds *_ws at end of path` | 路徑末端工作區 |
| `detect_image_name prefers docker_* over *_ws in path` | 優先順序檢查 |
| `detect_image_name strips docker_ prefix from last dir` | 前綴移除 |
| `detect_image_name strips docker_ from absolute root` | 根路徑 |
| `detect_image_name returns unknown for plain directory` | unknown 退回 |
| `detect_image_name returns unknown for generic path` | 一般路徑 |
| `detect_image_name lowercases the result` | 小寫轉換 |
| `detect_ws_path strategy 1: docker_* finds sibling *_ws` | 同層掃描 |
| `detect_ws_path strategy 1: docker_* without sibling falls through` | 無同層目錄 |
| `detect_ws_path strategy 2: finds _ws component in path` | 向上遍歷 |
| `detect_ws_path strategy 3: falls back to parent directory` | 父目錄退回 |
| `write_env creates .env with all required variables` | .env 產生 |
| `main creates .env when it does not exist` | 全新 .env |
| `main sources existing .env and reuses valid WS_PATH` | WS_PATH 重用 |
| `main re-detects WS_PATH when path in .env no longer exists` | 過期 WS_PATH |
| `main uses BASH_SOURCE fallback when --base-path not given` | 退回路徑 |
| `default _base_path resolves to repo root, not script dir` | 迴歸測試 |
| `main returns error on unknown argument` | 錯誤處理 |
| `main returns error when --base-path value is missing` | 缺少值 |
| `_msg returns English messages by default` | i18n 英文 |
| `_msg returns Chinese messages when _LANG=zh` | i18n 中文 |
| `_msg returns Simplified Chinese messages when _LANG=zh-CN` | i18n 簡中 |
| `_msg returns Japanese messages when _LANG=ja` | i18n 日文 |
| `_detect_lang returns zh for zh_TW.UTF-8` | 語言偵測 zh |
| `_detect_lang returns zh-CN for zh_CN.UTF-8` | 語言偵測 zh-CN |
| `_detect_lang returns ja for ja_JP.UTF-8` | 語言偵測 ja |
| `_detect_lang returns en for en_US.UTF-8` | 語言偵測 en |
| `_detect_lang returns en when LANG is unset` | LANG 未設定 |
| `_detect_lang is overridden by SETUP_LANG` | SETUP_LANG 覆蓋 |
| `main --lang zh sets Chinese messages` | --lang 旗標 |
| `main --lang requires a value` | 缺少 --lang 值 |

### test/unit/template_spec.bats (36)

| 測試項目 | 說明 |
|----------|------|
| `build.sh exists and is executable` | 檔案檢查 |
| `run.sh exists and is executable` | 檔案檢查 |
| `exec.sh exists and is executable` | 檔案檢查 |
| `stop.sh exists and is executable` | 檔案檢查 |
| `setup.sh exists and is executable` | 檔案檢查 |
| `ci.sh exists and is executable` | 檔案檢查 |
| `ci.sh uses set -euo pipefail` | Shell 慣例 |
| `Makefile exists` | 檔案檢查 |
| `Makefile has test target` | Makefile target |
| `Makefile has lint target` | Makefile target |
| `Makefile has clean target` | Makefile target |
| `test/smoke/test_helper.bash exists` | 目錄結構 |
| `test/smoke/script_help.bats exists` | 目錄結構 |
| `test/smoke/display_env.bats exists` | 目錄結構 |
| `test/unit/ directory exists` | 目錄結構 |
| `doc/readme/ directory exists` | 目錄結構 |
| `doc/test/ directory exists` | 目錄結構 |
| `doc/changelog/ directory exists` | 目錄結構 |
| `build.sh references template/setup.sh` | 路徑引用 |
| `run.sh references template/setup.sh` | 路徑引用 |
| `build.sh uses set -euo pipefail` | Shell 慣例 |
| `run.sh uses set -euo pipefail` | Shell 慣例 |
| `exec.sh uses set -euo pipefail` | Shell 慣例 |
| `stop.sh uses set -euo pipefail` | Shell 慣例 |
| `run.sh contains XDG_SESSION_TYPE check` | Wayland 支援 |
| `run.sh contains xhost +SI:localuser for wayland` | Wayland xhost |
| `run.sh contains xhost +local: for X11` | X11 xhost |
| `setup.sh default _base_path uses /..` | 無舊 ../../ 路徑 |
| `setup.sh default _base_path uses single parent traversal` | 正確遍歷 |

### test/bashrc_spec.bats (14)

| 測試項目 | 說明 |
|----------|------|
| `defines alias_func` | 函式存在 |
| `defines swc` | 函式存在 |
| `defines color_git_branch` | 函式存在 |
| `defines ros_complete` | 函式存在 |
| `defines ros_source` | 函式存在 |
| `defines ebc alias` | 別名存在 |
| `defines sbc alias` | 別名存在 |
| `alias_func is called` | 函式被呼叫 |
| `color_git_branch is called` | 函式被呼叫 |
| `ros_complete is called` | 函式被呼叫 |
| `ros_source is called` | 函式被呼叫 |
| `swc searches for catkin devel/setup.bash` | 內容檢查 |
| `ros_source references ROS_DISTRO` | 內容檢查 |
| `color_git_branch sets PS1` | 內容檢查 |

### test/pip_setup_spec.bats (3)

| 測試項目 | 說明 |
|----------|------|
| `pip setup.sh runs pip install with requirements.txt` | pip 安裝 |
| `pip setup.sh sets PIP_BREAK_SYSTEM_PACKAGES=1` | 環境變數設定 |
| `pip setup.sh fails when pip is not available` | 錯誤處理 |

### test/terminator_config_spec.bats (10)

| 測試項目 | 說明 |
|----------|------|
| `has [global_config] section` | 設定區段 |
| `has [keybindings] section` | 設定區段 |
| `has [profiles] section` | 設定區段 |
| `has [layouts] section` | 設定區段 |
| `has [plugins] section` | 設定區段 |
| `profiles has [[default]]` | 預設 profile |
| `default profile disables system font` | 字體設定 |
| `default profile has infinite scrollback` | 無限捲動 |
| `layouts has Window type` | 版面類型 |
| `layouts has Terminal type` | 版面類型 |

### test/terminator_setup_spec.bats (7)

| 測試項目 | 說明 |
|----------|------|
| `check_deps returns 0 when terminator is installed` | 相依檢查通過 |
| `check_deps fails when terminator is not installed` | 相依檢查失敗 |
| `_entry_point calls main when deps pass` | 進入點 |
| `_entry_point fails when deps missing` | 進入點失敗 |
| `main creates terminator config directory` | 目錄建立 |
| `main copies terminator config file` | 檔案複製 |
| `main calls chown with correct user and group` | 權限設定 |

### test/tmux_conf_spec.bats (12)

| 測試項目 | 說明 |
|----------|------|
| `defines prefix key` | 核心設定 |
| `sets default shell to bash` | Shell 設定 |
| `sets default terminal` | 終端機設定 |
| `enables mouse support` | 滑鼠支援 |
| `enables vi status-keys` | Vi 模式 |
| `enables vi mode-keys` | Vi 模式 |
| `defines split-window bindings` | 快捷鍵 |
| `defines reload config binding` | 快捷鍵 |
| `enables status bar` | 狀態列 |
| `sets status bar position` | 狀態列 |
| `declares tpm plugin` | 套件管理器 |
| `initializes tpm at end of file` | 套件初始化 |

### test/tmux_setup_spec.bats (8)

| 測試項目 | 說明 |
|----------|------|
| `check_deps returns 0 when tmux and git are installed` | 相依檢查通過 |
| `check_deps fails when tmux is not installed` | tmux 缺失 |
| `check_deps fails when git is not installed` | git 缺失 |
| `_entry_point calls main when deps pass` | 進入點 |
| `_entry_point fails when deps missing` | 進入點失敗 |
| `main clones tpm repository` | TPM 複製 |
| `main creates tmux config directory` | 目錄建立 |
| `main copies tmux.conf to config directory` | 檔案複製 |
