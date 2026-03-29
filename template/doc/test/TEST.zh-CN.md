# 测试文档

模板自身测试：共 **132 个**。

## 测试文件

### test/setup_spec.bats (42)

| 测试项目 | 说明 |
|----------|------|
| `detect_user_info uses USER env when set` | 使用 USER 环境变量 |
| `detect_user_info falls back to id -un when USER unset` | USER 未设置时回退到 id 命令 |
| `detect_user_info sets group uid gid correctly` | 所有字段正确填入 |
| `detect_hardware returns uname -m output` | 返回硬件架构 |
| `detect_docker_hub_user uses docker info username when logged in` | Docker Hub 检测 |
| `detect_docker_hub_user falls back to USER when docker returns empty` | USER 回退 |
| `detect_docker_hub_user falls back to id -un when USER also unset` | id 回退 |
| `detect_gpu returns true when nvidia-container-toolkit is installed` | GPU 已检测 |
| `detect_gpu returns false when nvidia-container-toolkit is not installed` | 无 GPU |
| `detect_image_name finds *_ws in path` | 工作区命名 |
| `detect_image_name finds *_ws at end of path` | 路径末端工作区 |
| `detect_image_name prefers docker_* over *_ws in path` | 优先级检查 |
| `detect_image_name strips docker_ prefix from last dir` | 前缀移除 |
| `detect_image_name strips docker_ from absolute root` | 根路径 |
| `detect_image_name returns unknown for plain directory` | unknown 回退 |
| `detect_image_name returns unknown for generic path` | 通用路径 |
| `detect_image_name lowercases the result` | 小写转换 |
| `detect_ws_path strategy 1: docker_* finds sibling *_ws` | 同层扫描 |
| `detect_ws_path strategy 1: docker_* without sibling falls through` | 无同层目录 |
| `detect_ws_path strategy 2: finds _ws component in path` | 向上遍历 |
| `detect_ws_path strategy 3: falls back to parent directory` | 父目录回退 |
| `write_env creates .env with all required variables` | .env 生成 |
| `main creates .env when it does not exist` | 全新 .env |
| `main sources existing .env and reuses valid WS_PATH` | WS_PATH 重用 |
| `main re-detects WS_PATH when path in .env no longer exists` | 过期 WS_PATH |
| `main uses BASH_SOURCE fallback when --base-path not given` | 回退路径 |
| `default _base_path resolves to repo root, not script dir` | 回归测试 |
| `main returns error on unknown argument` | 错误处理 |
| `main returns error when --base-path value is missing` | 缺少值 |
| `_msg returns English messages by default` | i18n 英文 |
| `_msg returns Chinese messages when _LANG=zh` | i18n 中文 |
| `_msg returns Simplified Chinese messages when _LANG=zh-CN` | i18n 简中 |
| `_msg returns Japanese messages when _LANG=ja` | i18n 日文 |
| `_detect_lang returns zh for zh_TW.UTF-8` | 语言检测 zh |
| `_detect_lang returns zh-CN for zh_CN.UTF-8` | 语言检测 zh-CN |
| `_detect_lang returns ja for ja_JP.UTF-8` | 语言检测 ja |
| `_detect_lang returns en for en_US.UTF-8` | 语言检测 en |
| `_detect_lang returns en when LANG is unset` | LANG 未设置 |
| `_detect_lang is overridden by SETUP_LANG` | SETUP_LANG 覆盖 |
| `main --lang zh sets Chinese messages` | --lang 标志 |
| `main --lang requires a value` | 缺少 --lang 值 |

### test/unit/template_spec.bats (36)

| 测试项目 | 说明 |
|----------|------|
| `build.sh exists and is executable` | 文件检查 |
| `run.sh exists and is executable` | 文件检查 |
| `exec.sh exists and is executable` | 文件检查 |
| `stop.sh exists and is executable` | 文件检查 |
| `setup.sh exists and is executable` | 文件检查 |
| `ci.sh exists and is executable` | 文件检查 |
| `ci.sh uses set -euo pipefail` | Shell 惯例 |
| `Makefile exists` | 文件检查 |
| `Makefile has test target` | Makefile target |
| `Makefile has lint target` | Makefile target |
| `Makefile has clean target` | Makefile target |
| `test/smoke/test_helper.bash exists` | 目录结构 |
| `test/smoke/script_help.bats exists` | 目录结构 |
| `test/smoke/display_env.bats exists` | 目录结构 |
| `test/unit/ directory exists` | 目录结构 |
| `doc/readme/ directory exists` | 目录结构 |
| `doc/test/ directory exists` | 目录结构 |
| `doc/changelog/ directory exists` | 目录结构 |
| `build.sh references template/setup.sh` | 路径引用 |
| `run.sh references template/setup.sh` | 路径引用 |
| `build.sh uses set -euo pipefail` | Shell 惯例 |
| `run.sh uses set -euo pipefail` | Shell 惯例 |
| `exec.sh uses set -euo pipefail` | Shell 惯例 |
| `stop.sh uses set -euo pipefail` | Shell 惯例 |
| `run.sh contains XDG_SESSION_TYPE check` | Wayland 支持 |
| `run.sh contains xhost +SI:localuser for wayland` | Wayland xhost |
| `run.sh contains xhost +local: for X11` | X11 xhost |
| `setup.sh default _base_path uses /..` | 无旧 ../../ 路径 |
| `setup.sh default _base_path uses single parent traversal` | 正确遍历 |

### test/bashrc_spec.bats (14)

| 测试项目 | 说明 |
|----------|------|
| `defines alias_func` | 函数存在 |
| `defines swc` | 函数存在 |
| `defines color_git_branch` | 函数存在 |
| `defines ros_complete` | 函数存在 |
| `defines ros_source` | 函数存在 |
| `defines ebc alias` | 别名存在 |
| `defines sbc alias` | 别名存在 |
| `alias_func is called` | 函数被调用 |
| `color_git_branch is called` | 函数被调用 |
| `ros_complete is called` | 函数被调用 |
| `ros_source is called` | 函数被调用 |
| `swc searches for catkin devel/setup.bash` | 内容检查 |
| `ros_source references ROS_DISTRO` | 内容检查 |
| `color_git_branch sets PS1` | 内容检查 |

### test/pip_setup_spec.bats (3)

| 测试项目 | 说明 |
|----------|------|
| `pip setup.sh runs pip install with requirements.txt` | pip 安装 |
| `pip setup.sh sets PIP_BREAK_SYSTEM_PACKAGES=1` | 环境变量设置 |
| `pip setup.sh fails when pip is not available` | 错误处理 |

### test/terminator_config_spec.bats (10)

| 测试项目 | 说明 |
|----------|------|
| `has [global_config] section` | 配置区段 |
| `has [keybindings] section` | 配置区段 |
| `has [profiles] section` | 配置区段 |
| `has [layouts] section` | 配置区段 |
| `has [plugins] section` | 配置区段 |
| `profiles has [[default]]` | 默认 profile |
| `default profile disables system font` | 字体设置 |
| `default profile has infinite scrollback` | 无限滚动 |
| `layouts has Window type` | 布局类型 |
| `layouts has Terminal type` | 布局类型 |

### test/terminator_setup_spec.bats (7)

| 测试项目 | 说明 |
|----------|------|
| `check_deps returns 0 when terminator is installed` | 依赖检查通过 |
| `check_deps fails when terminator is not installed` | 依赖检查失败 |
| `_entry_point calls main when deps pass` | 入口点 |
| `_entry_point fails when deps missing` | 入口点失败 |
| `main creates terminator config directory` | 目录创建 |
| `main copies terminator config file` | 文件复制 |
| `main calls chown with correct user and group` | 权限设置 |

### test/tmux_conf_spec.bats (12)

| 测试项目 | 说明 |
|----------|------|
| `defines prefix key` | 核心设置 |
| `sets default shell to bash` | Shell 设置 |
| `sets default terminal` | 终端设置 |
| `enables mouse support` | 鼠标支持 |
| `enables vi status-keys` | Vi 模式 |
| `enables vi mode-keys` | Vi 模式 |
| `defines split-window bindings` | 快捷键 |
| `defines reload config binding` | 快捷键 |
| `enables status bar` | 状态栏 |
| `sets status bar position` | 状态栏 |
| `declares tpm plugin` | 插件管理器 |
| `initializes tpm at end of file` | 插件初始化 |

### test/tmux_setup_spec.bats (8)

| 测试项目 | 说明 |
|----------|------|
| `check_deps returns 0 when tmux and git are installed` | 依赖检查通过 |
| `check_deps fails when tmux is not installed` | tmux 缺失 |
| `check_deps fails when git is not installed` | git 缺失 |
| `_entry_point calls main when deps pass` | 入口点 |
| `_entry_point fails when deps missing` | 入口点失败 |
| `main clones tpm repository` | TPM 克隆 |
| `main creates tmux config directory` | 目录创建 |
| `main copies tmux.conf to config directory` | 文件复制 |
