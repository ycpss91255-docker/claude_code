# TEST.md

Template self-tests: **175 tests** total.

## Test Files

### test/unit/setup_spec.bats (58)

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
| `detect_image_name returns unknown for plain directory (default conf)` | Unknown fallback |
| `detect_image_name returns unknown for generic path (default conf)` | Unknown fallback |
| `detect_image_name lowercases the result` | Lowercase |
| `detect_image_name uses repo-level image_name.conf when present` | Per-repo override (env var) |
| `detect_image_name auto-discovers image_name.conf via BASE_PATH` | Per-repo auto-discover |
| `detect_image_name reads env_example rule from conf` | env_example rule |
| `detect_image_name applies rules in order (first match wins)` | Rule order |
| `detect_image_name skips comments and empty lines in conf` | Conf parsing |
| `detect_image_name skips whitespace-only lines in conf` | Conf parsing |
| `detect_image_name returns unknown when no rule matches and no basename` | Unknown fallback |
| `detect_image_name uses @basename when no other rule matches` | @basename rule |
| `detect_image_name applies @default:<value> as fallback` | @default rule |
| `detect_image_name @default:<value> is skipped if earlier rule matches` | @default skip |
| `detect_ws_path strategy 1: docker_* finds sibling *_ws` | Sibling scan |
| `detect_ws_path strategy 1: docker_* without sibling falls through` | No sibling |
| `detect_ws_path strategy 2: finds _ws component in path` | Path traversal |
| `detect_ws_path strategy 3: falls back to parent directory` | Parent fallback |
| `write_env creates .env with all required variables` | .env generation |
| `write_env includes APT_MIRROR_UBUNTU` | APT mirror in .env |
| `write_env includes APT_MIRROR_DEBIAN` | APT mirror in .env |
| `main creates .env when it does not exist` | Fresh .env |
| `main sources existing .env and reuses valid WS_PATH` | WS_PATH reuse |
| `main re-detects WS_PATH when path in .env no longer exists` | Stale WS_PATH |
| `main: env_example rule reads IMAGE_NAME from .env.example` | env_example rule via main |
| `main warns when conf has no fallback and detection fails` | WARNING when no rule matches |
| `main: default conf @default:unknown applies for repo without docker_/_ws naming` | @default:unknown INFO |
| `main uses BASH_SOURCE fallback when --base-path not given` | Fallback path |
| `default _base_path resolves to repo root, not script dir` | Regression test |
| `main returns error on unknown argument` | Error handling |
| `main returns error when --base-path value is missing` | Missing value |
| `main sets APT_MIRROR defaults in fresh .env` | Default mirrors |
| `main preserves existing APT_MIRROR values from .env` | Mirror preservation |
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

### test/unit/template_spec.bats (61)

| Test | Description |
|------|-------------|
| `build.sh exists and is executable` | File check |
| `run.sh exists and is executable` | File check |
| `exec.sh exists and is executable` | File check |
| `stop.sh exists and is executable` | File check |
| `setup.sh exists and is executable` | File check |
| `ci.sh exists and is executable` | File check |
| `ci.sh uses set -euo pipefail` | Shell convention |
| `Makefile exists (repo entry)` | File check |
| `Makefile has build target` | Makefile target |
| `Makefile.ci exists (template CI)` | File check |
| `Makefile.ci has test target` | Makefile target |
| `Makefile.ci has lint target` | Makefile target |
| `test/smoke/test_helper.bash exists` | Directory structure |
| `test/smoke/script_help.bats exists` | Directory structure |
| `test/smoke/display_env.bats exists` | Directory structure |
| `test/unit/ directory exists` | Directory structure |
| `doc/readme/ directory exists` | Directory structure |
| `doc/test/ directory exists` | Directory structure |
| `doc/changelog/ directory exists` | Directory structure |
| `build.sh references template/script/docker/setup.sh` | Path reference |
| `run.sh references template/script/docker/setup.sh` | Path reference |
| `build.sh uses set -euo pipefail` | Shell convention |
| `build.sh supports --no-cache flag` | Force rebuild flag |
| `build.sh passes --no-cache to docker compose build when set` | NO_CACHE forwarded |
| `build.sh keeps test-tools image by default (cleanup gated by CLEAN_TOOLS)` | Default keep tools |
| `build.sh supports --clean-tools flag` | Clean tools flag |
| `build.sh removes test-tools image when --clean-tools is set` | CLEAN_TOOLS forwarded |
| `run.sh uses set -euo pipefail` | Shell convention |
| `exec.sh uses set -euo pipefail` | Shell convention |
| `stop.sh uses set -euo pipefail` | Shell convention |
| `build.sh uses -p for compose project name` | Compose project |
| `run.sh uses -p for compose project name` | Compose project |
| `exec.sh uses -p for compose project name` | Compose project |
| `stop.sh uses -p for compose project name` | Compose project |
| `exec.sh sources .env` | Env loading |
| `stop.sh sources .env` | Env loading |
| `stop.sh removes orphan run-mode container by name` | docker rm fallback |
| `script/docker/i18n.sh exists` | i18n module exists |
| `Dockerfile.test-tools includes bats-mock` | bats-mock available in test image |
| `i18n.sh defines _detect_lang function` | _detect_lang in i18n.sh |
| `build.sh sources i18n.sh` | build.sh uses shared i18n |
| `run.sh sources i18n.sh` | run.sh uses shared i18n |
| `exec.sh sources i18n.sh` | exec.sh uses shared i18n |
| `stop.sh sources i18n.sh` | stop.sh uses shared i18n |
| `setup.sh sources i18n.sh` | setup.sh uses shared i18n |
| `build.sh -h works when i18n.sh is missing (consumer Dockerfile /lint scenario)` | i18n fallback |
| `run.sh -h works when i18n.sh is missing` | i18n fallback |
| `exec.sh -h works when i18n.sh is missing` | i18n fallback |
| `stop.sh -h works when i18n.sh is missing` | i18n fallback |
| `setup.sh does not redefine _detect_lang` | No duplication |
| `upgrade.sh runs init.sh after subtree pull` | Sync symlinks |
| `upgrade.sh writes target_ver after init.sh (to override init's latest detection)` | Version override |
| `upgrade.sh supports --gen-image-conf flag` | Flag exists |
| `upgrade.sh --gen-image-conf delegates to init.sh --gen-image-conf` | Delegation |
| `upgrade.sh --help mentions --gen-image-conf` | Help text |
| `upgrade.sh updates main.yaml @tag without clobbering release-worker.yaml` | sed regression |
| `run.sh contains XDG_SESSION_TYPE check` | X11/Wayland branch |
| `run.sh contains xhost +SI:localuser for wayland` | Wayland xhost |
| `run.sh contains xhost +local: for X11` | X11 xhost |
| `setup.sh default _base_path uses /..` | Path resolution |
| `setup.sh default _base_path uses double parent traversal` | Repo root traversal |

### test/unit/bashrc_spec.bats (14)

| Test | Description |
|------|-------------|
| `defines alias_func` | Function definition |
| `defines swc` | Function definition |
| `defines color_git_branch` | Function definition |
| `defines ros_complete` | Function definition |
| `defines ros_source` | Function definition |
| `defines ebc alias` | Alias definition |
| `defines sbc alias` | Alias definition |
| `alias_func is called` | Function call |
| `color_git_branch is called` | Function call |
| `ros_complete is called` | Function call |
| `ros_source is called` | Function call |
| `swc searches for catkin devel/setup.bash` | Catkin search |
| `ros_source references ROS_DISTRO` | ROS env var |
| `color_git_branch sets PS1` | PS1 setting |

### test/unit/pip_setup_spec.bats (3)

| Test | Description |
|------|-------------|
| `pip setup.sh runs pip install with requirements.txt` | pip install |
| `pip setup.sh sets PIP_BREAK_SYSTEM_PACKAGES=1` | Break system packages |
| `pip setup.sh fails when pip is not available` | Missing pip error |

### test/unit/terminator_config_spec.bats (10)

| Test | Description |
|------|-------------|
| `has [global_config] section` | Config section |
| `has [keybindings] section` | Config section |
| `has [profiles] section` | Config section |
| `has [layouts] section` | Config section |
| `has [plugins] section` | Config section |
| `profiles has [[default]]` | Default profile |
| `default profile disables system font` | Font setting |
| `default profile has infinite scrollback` | Scrollback setting |
| `layouts has Window type` | Window layout |
| `layouts has Terminal type` | Terminal layout |

### test/unit/terminator_setup_spec.bats (8)

| Test | Description |
|------|-------------|
| `check_deps returns 0 when terminator is installed` | Dependency check |
| `check_deps fails when terminator is not installed` | Missing dep |
| `_entry_point calls main when deps pass` | Entry point |
| `_entry_point fails when deps missing` | Entry point fail |
| `main creates terminator config directory` | Config dir |
| `main copies terminator config file` | Config copy |
| `main calls chown with correct user and group` | Permissions |
| `script runs entry_point when executed directly` | Direct-run guard |

### test/unit/tmux_conf_spec.bats (12)

| Test | Description |
|------|-------------|
| `defines prefix key` | tmux prefix |
| `sets default shell to bash` | Shell setting |
| `sets default terminal` | Terminal setting |
| `enables mouse support` | Mouse |
| `enables vi status-keys` | vi mode |
| `enables vi mode-keys` | vi mode |
| `defines split-window bindings` | Split bindings |
| `defines reload config binding` | Reload binding |
| `enables status bar` | Status bar |
| `sets status bar position` | Status bar position |
| `declares tpm plugin` | tpm plugin |
| `initializes tpm at end of file` | tpm init |

### test/unit/tmux_setup_spec.bats (9)

| Test | Description |
|------|-------------|
| `check_deps returns 0 when tmux and git are installed` | Dependency check |
| `check_deps fails when tmux is not installed` | Missing tmux |
| `check_deps fails when git is not installed` | Missing git |
| `_entry_point calls main when deps pass` | Entry point |
| `_entry_point fails when deps missing` | Entry point fail |
| `main clones tpm repository` | tpm clone |
| `main creates tmux config directory` | Config dir |
| `main copies tmux.conf to config directory` | Config copy |
| `script runs entry_point when executed directly` | Direct-run guard |
