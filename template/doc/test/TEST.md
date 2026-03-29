# TEST.md

Template self-tests: **132 tests** total.

## Test Files

### test/setup_spec.bats (42)

| Test | Description |
|------|-------------|
| `detect_user_info uses USER env when set` | Uses USER env var |
| `detect_user_info falls back to id -un when USER unset` | Falls back to id command |
| `detect_user_info sets group uid gid correctly` | All fields populated |
| `detect_hardware returns uname -m output` | Returns architecture |
| `detect_docker_hub_user uses docker info username when logged in` | Docker Hub detection |
| `detect_docker_hub_user falls back to USER when docker returns empty` | USER fallback |
| `detect_docker_hub_user falls back to id -un when USER also unset` | id fallback |
| `detect_gpu returns true when nvidia-container-toolkit is installed` | GPU detected |
| `detect_gpu returns false when nvidia-container-toolkit is not installed` | No GPU |
| `detect_image_name finds *_ws in path` | Workspace naming |
| `detect_image_name finds *_ws at end of path` | Workspace at end |
| `detect_image_name prefers docker_* over *_ws in path` | Priority check |
| `detect_image_name strips docker_ prefix from last dir` | Prefix stripping |
| `detect_image_name strips docker_ from absolute root` | Root path |
| `detect_image_name returns unknown for plain directory` | Unknown fallback |
| `detect_image_name returns unknown for generic path` | Generic path |
| `detect_image_name lowercases the result` | Lowercase |
| `detect_ws_path strategy 1: docker_* finds sibling *_ws` | Sibling scan |
| `detect_ws_path strategy 1: docker_* without sibling falls through` | No sibling |
| `detect_ws_path strategy 2: finds _ws component in path` | Path traversal |
| `detect_ws_path strategy 3: falls back to parent directory` | Parent fallback |
| `write_env creates .env with all required variables` | .env generation |
| `main creates .env when it does not exist` | Fresh .env |
| `main sources existing .env and reuses valid WS_PATH` | WS_PATH reuse |
| `main re-detects WS_PATH when path in .env no longer exists` | Stale WS_PATH |
| `main uses BASH_SOURCE fallback when --base-path not given` | Fallback path |
| `default _base_path resolves to repo root, not script dir` | Regression test |
| `main returns error on unknown argument` | Error handling |
| `main returns error when --base-path value is missing` | Missing value |
| `_msg returns English messages by default` | i18n English |
| `_msg returns Chinese messages when _LANG=zh` | i18n Chinese |
| `_msg returns Simplified Chinese messages when _LANG=zh-CN` | i18n Simplified Chinese |
| `_msg returns Japanese messages when _LANG=ja` | i18n Japanese |
| `_detect_lang returns zh for zh_TW.UTF-8` | Language detection zh |
| `_detect_lang returns zh-CN for zh_CN.UTF-8` | Language detection zh-CN |
| `_detect_lang returns ja for ja_JP.UTF-8` | Language detection ja |
| `_detect_lang returns en for en_US.UTF-8` | Language detection en |
| `_detect_lang returns en when LANG is unset` | Unset LANG |
| `_detect_lang is overridden by SETUP_LANG` | SETUP_LANG override |
| `main --lang zh sets Chinese messages` | --lang flag |
| `main --lang requires a value` | Missing --lang value |

### test/unit/template_spec.bats (36)

| Test | Description |
|------|-------------|
| `build.sh exists and is executable` | File check |
| `run.sh exists and is executable` | File check |
| `exec.sh exists and is executable` | File check |
| `stop.sh exists and is executable` | File check |
| `setup.sh exists and is executable` | File check |
| `ci.sh exists and is executable` | File check |
| `ci.sh uses set -euo pipefail` | Shell convention |
| `Makefile exists` | File check |
| `Makefile has test target` | Makefile target |
| `Makefile has lint target` | Makefile target |
| `Makefile has clean target` | Makefile target |
| `test/smoke/test_helper.bash exists` | Directory structure |
| `test/smoke/script_help.bats exists` | Directory structure |
| `test/smoke/display_env.bats exists` | Directory structure |
| `test/unit/ directory exists` | Directory structure |
| `doc/readme/ directory exists` | Directory structure |
| `doc/test/ directory exists` | Directory structure |
| `doc/changelog/ directory exists` | Directory structure |
| `build.sh references template/setup.sh` | Path reference |
| `run.sh references template/setup.sh` | Path reference |
| `build.sh uses set -euo pipefail` | Shell convention |
| `run.sh uses set -euo pipefail` | Shell convention |
| `exec.sh uses set -euo pipefail` | Shell convention |
| `stop.sh uses set -euo pipefail` | Shell convention |
| `run.sh contains XDG_SESSION_TYPE check` | Wayland support |
| `run.sh contains xhost +SI:localuser for wayland` | Wayland xhost |
| `run.sh contains xhost +local: for X11` | X11 xhost |
| `setup.sh default _base_path uses /..` | No old ../../ path |
| `setup.sh default _base_path uses single parent traversal` | Correct traversal |

### test/bashrc_spec.bats (14)

| Test | Description |
|------|-------------|
| `defines alias_func` | Function exists |
| `defines swc` | Function exists |
| `defines color_git_branch` | Function exists |
| `defines ros_complete` | Function exists |
| `defines ros_source` | Function exists |
| `defines ebc alias` | Alias exists |
| `defines sbc alias` | Alias exists |
| `alias_func is called` | Function invoked |
| `color_git_branch is called` | Function invoked |
| `ros_complete is called` | Function invoked |
| `ros_source is called` | Function invoked |
| `swc searches for catkin devel/setup.bash` | Content check |
| `ros_source references ROS_DISTRO` | Content check |
| `color_git_branch sets PS1` | Content check |

### test/pip_setup_spec.bats (3)

| Test | Description |
|------|-------------|
| `pip setup.sh runs pip install with requirements.txt` | pip install |
| `pip setup.sh sets PIP_BREAK_SYSTEM_PACKAGES=1` | env var set |
| `pip setup.sh fails when pip is not available` | Error handling |

### test/terminator_config_spec.bats (10)

| Test | Description |
|------|-------------|
| `has [global_config] section` | Config section |
| `has [keybindings] section` | Config section |
| `has [profiles] section` | Config section |
| `has [layouts] section` | Config section |
| `has [plugins] section` | Config section |
| `profiles has [[default]]` | Default profile |
| `default profile disables system font` | Font setting |
| `default profile has infinite scrollback` | Scrollback |
| `layouts has Window type` | Layout type |
| `layouts has Terminal type` | Layout type |

### test/terminator_setup_spec.bats (7)

| Test | Description |
|------|-------------|
| `check_deps returns 0 when terminator is installed` | Dep check pass |
| `check_deps fails when terminator is not installed` | Dep check fail |
| `_entry_point calls main when deps pass` | Entry point |
| `_entry_point fails when deps missing` | Entry point fail |
| `main creates terminator config directory` | Directory creation |
| `main copies terminator config file` | File copy |
| `main calls chown with correct user and group` | Ownership |

### test/tmux_conf_spec.bats (12)

| Test | Description |
|------|-------------|
| `defines prefix key` | Core setting |
| `sets default shell to bash` | Shell setting |
| `sets default terminal` | Terminal setting |
| `enables mouse support` | Mouse support |
| `enables vi status-keys` | Vi mode |
| `enables vi mode-keys` | Vi mode |
| `defines split-window bindings` | Key bindings |
| `defines reload config binding` | Key bindings |
| `enables status bar` | Status bar |
| `sets status bar position` | Status bar |
| `declares tpm plugin` | Plugin manager |
| `initializes tpm at end of file` | Plugin init |

### test/tmux_setup_spec.bats (8)

| Test | Description |
|------|-------------|
| `check_deps returns 0 when tmux and git are installed` | Dep check pass |
| `check_deps fails when tmux is not installed` | tmux missing |
| `check_deps fails when git is not installed` | git missing |
| `_entry_point calls main when deps pass` | Entry point |
| `_entry_point fails when deps missing` | Entry point fail |
| `main clones tpm repository` | TPM clone |
| `main creates tmux config directory` | Directory creation |
| `main copies tmux.conf to config directory` | File copy |
