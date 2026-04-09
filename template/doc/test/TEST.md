# TEST.md

Template self-tests: **247 tests** total (226 unit + 21 integration).

## Test Files

### test/unit/lib_spec.bats (15)

| Test | Description |
|------|-------------|
| `_lib.sh sets _LANG to 'en' when LANG is unset` | Default language |
| `_lib.sh sets _LANG to 'zh' for zh_TW.UTF-8` | Traditional Chinese |
| `_lib.sh sets _LANG to 'zh-CN' for zh_CN.UTF-8` | Simplified Chinese |
| `_lib.sh sets _LANG to 'zh-CN' for zh_SG (Singapore)` | Singapore variant |
| `_lib.sh sets _LANG to 'ja' for ja_JP.UTF-8` | Japanese |
| `_lib.sh honors SETUP_LANG override` | Env override |
| `_lib.sh is idempotent when sourced twice` | Double-source guard |
| `_load_env exports variables from a .env file` | Env loader works |
| `_load_env errors when no path is given` | Required arg check |
| `_compute_project_name with empty instance produces clean PROJECT_NAME` | Default instance |
| `_compute_project_name with named instance suffixes both` | Named instance |
| `_compute_project_name exports INSTANCE_SUFFIX so child processes see it` | Export propagation |
| `_compose with DRY_RUN=true prints command instead of running` | DRY_RUN path |
| `_compose without DRY_RUN tries to invoke docker compose (sanity)` | Real-call branch |
| `_compose_project pre-fills -p / -f / --env-file from PROJECT_NAME and FILE_PATH` | Project wrapper |

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

### test/unit/template_spec.bats (97)

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
| `_lib.sh derives PROJECT_NAME from DOCKER_HUB_USER and IMAGE_NAME` | Shared derivation |
| `_lib.sh _compose_project wraps -p with PROJECT_NAME` | Shared compose wrapper |
| `_lib.sh defines _load_env helper` | Shared env loader |
| `_lib.sh defines _compute_project_name helper` | Shared helper |
| `_lib.sh defines _compose wrapper` | Shared compose wrapper |
| `build.sh routes compose call through _compose_project` | Uses shared lib |
| `run.sh routes compose calls through _compose_project` | Uses shared lib |
| `exec.sh routes compose call through _compose_project` | Uses shared lib |
| `stop.sh routes compose call through _compose_project` | Uses shared lib |
| `exec.sh loads .env via _load_env helper` | Uses shared lib |
| `stop.sh loads .env via _load_env helper` | Uses shared lib |
| `stop.sh no longer needs orphan cleanup (run.sh devel uses up not run)` | No more orphan |
| `run.sh devel target uses compose up -d (not compose run --name)` | up + exec model |
| `run.sh devel branch uses compose exec to enter shell` | up + exec model |
| `run.sh devel branch installs trap to auto-down on exit` | Auto cleanup |
| `run.sh _devel_cleanup uses short timeout to avoid 10s grace period` | Fast exit |
| `run.sh non-devel TARGET still uses compose run --rm` | One-shot stages |
| `run.sh devel branch does not use 'compose run --name'` | Old pattern gone |
| `run.sh supports --instance flag` | --instance |
| `exec.sh supports --instance flag` | --instance |
| `stop.sh supports --instance flag` | --instance |
| `stop.sh supports --all flag` | --all |
| `run.sh exports INSTANCE_SUFFIX env var to compose` | env passing |
| `exec.sh exports INSTANCE_SUFFIX env var to compose` | env passing |
| `stop.sh exports INSTANCE_SUFFIX env var to compose` | env passing |
| `run.sh refuses when default container already running and no --instance` | collision |
| `init.sh-generated compose.yaml uses parameterized container_name` | template gen |
| `run.sh -h shows --instance in help` | help text |
| `exec.sh -h shows --instance in help` | help text |
| `stop.sh -h shows --instance in help` | help text |
| `build.sh supports --dry-run flag` | --dry-run |
| `run.sh supports --dry-run flag` | --dry-run |
| `exec.sh supports --dry-run flag` | --dry-run |
| `stop.sh supports --dry-run flag` | --dry-run |
| `build.sh -h shows --dry-run in help` | --dry-run help |
| `run.sh -h shows --dry-run in help` | --dry-run help |
| `exec.sh -h shows --dry-run in help` | --dry-run help |
| `stop.sh -h shows --dry-run in help` | --dry-run help |
| `exec.sh checks container is running before exec` | precheck |
| `exec.sh precheck error mentions run.sh hint` | friendly hint |
| `exec.sh exits non-zero with friendly hint when container not running` | precheck e2e |
| `exec.sh --dry-run skips precheck and prints compose command` | dry-run e2e |
| `script/docker/i18n.sh exists` | i18n module exists |
| `Dockerfile.test-tools includes bats-mock` | bats-mock available in test image |
| `i18n.sh defines _detect_lang function` | _detect_lang in i18n.sh |
| `build.sh sources _lib.sh` | build.sh uses shared lib |
| `run.sh sources _lib.sh` | run.sh uses shared lib |
| `exec.sh sources _lib.sh` | exec.sh uses shared lib |
| `stop.sh sources _lib.sh` | stop.sh uses shared lib |
| `_lib.sh sources i18n.sh (delegates language detection)` | _lib delegates i18n |
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

### test/integration/init_new_repo_spec.bats (21)

End-to-end verification that `init.sh` produces a complete repo skeleton in
an empty directory. **Level 1** (file generation only, no Docker). The
**Level 2** equivalent (real `build.sh` / `run.sh` / `exec.sh` / `stop.sh`)
runs as the `integration-e2e` job in `.github/workflows/self-test.yaml`,
which has access to a Docker daemon on the host runner.

| Test | Description |
|------|-------------|
| `init.sh detects empty dir and creates new repo skeleton` | Smoke |
| `new repo: Dockerfile is copied from template` | Dockerfile gen |
| `new repo: compose.yaml exists and references the repo name` | compose gen |
| `new repo: .env.example contains IMAGE_NAME=<reponame>` | env fallback |
| `new repo: script/entrypoint.sh exists and is executable` | entrypoint gen |
| `new repo: smoke test skeleton exists for the repo` | smoke skeleton |
| `new repo: .github/workflows/main.yaml exists with reusable workflow ref` | CI gen |
| `new repo: .gitignore exists` | gitignore |
| `new repo: doc/ tree exists with README translations` | i18n docs |
| `new repo: doc/test/TEST.md exists` | TEST.md gen |
| `new repo: doc/changelog/CHANGELOG.md exists` | CHANGELOG gen |
| `new repo: build.sh symlink → template/script/docker/build.sh` | symlink target |
| `new repo: run.sh / exec.sh / stop.sh / Makefile symlinks correct` | symlink set |
| `new repo: .template_version exists and matches a known tag format` | version file |
| `new repo: re-running init.sh on the result is idempotent` | idempotent |
| `new repo: build.sh -h works against the generated symlink` | smoke build.sh |
| `new repo: run.sh -h works against the generated symlink` | smoke run.sh |
| `new repo: exec.sh -h works against the generated symlink` | smoke exec.sh |
| `new repo: stop.sh -h works against the generated symlink` | smoke stop.sh |
| `init.sh --gen-image-conf copies image_name.conf to repo root` | conf gen |
| `init.sh --gen-image-conf refuses to overwrite existing image_name.conf` | conf safety |
