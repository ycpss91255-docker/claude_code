# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.7.1] - 2026-04-10

### Fixed
- `run.sh` foreground devel: `./run.sh` appeared to hang for ~10s after the
  user typed `exit` because the cleanup trap ran `compose down` with the
  default 10s SIGTERM grace period. Pass `-t 0` so the already-exited
  interactive container is killed immediately.

## [v0.7.0] - 2026-04-09

### Added
- `build.sh` / `run.sh` / `exec.sh` / `stop.sh`: `--dry-run` flag prints the
  `docker` / `docker compose` commands that would run instead of executing them.
  Useful for debugging compose / env / instance resolution without side effects.
- `exec.sh`: precheck refuses with a friendly error pointing at `./run.sh`
  (and `--instance NAME` if applicable) when the target container is not running,
  instead of letting `compose exec` print the cryptic `service "devel" is not running`.

### Changed
- Refactor: extracted shared helpers (`_LANG` setup, `_load_env`, `_compute_project_name`,
  `_compose`, `_compose_project`) into `template/script/docker/_lib.sh`. `build.sh`,
  `run.sh`, `exec.sh`, and `stop.sh` now source `_lib.sh` and call the helpers instead
  of duplicating the same i18n / env-loading / compose-flag boilerplate.
- `exec.sh`: passes the user command as a positional array (`"$@"`) to `compose exec`,
  so arguments containing whitespace are preserved instead of being word-split.
- `run.sh`: trap is now `trap _devel_cleanup EXIT` (calls a named function) instead of
  an inline string-expanded command, matching `build.sh`'s style.

## [v0.6.8] - 2026-04-09

### Added
- `run.sh` / `exec.sh` / `stop.sh`: `--instance NAME` flag for parallel container instances
  - `./run.sh --instance dev2` starts a parallel container alongside the default
  - `./exec.sh --instance dev2 [cmd]` enters that named instance
  - `./stop.sh --instance dev2` stops only that one
  - `./stop.sh --all` stops the default + every named instance for this image
- Project name and container name now include `${INSTANCE_SUFFIX}` so each
  instance has isolated docker compose project (own network/volumes)
- `init.sh`-generated `compose.yaml` uses
  `container_name: ${IMAGE_NAME}${INSTANCE_SUFFIX:-}`
  - Default invocation (no `--instance`) keeps the clean name `${IMAGE_NAME}` —
    backward-compatible with external tools that grep `docker exec ${IMAGE_NAME}`

### Changed
- `run.sh`: foreground devel now refuses to start if a container with the
  default name is already running. Use `./stop.sh` first or pass
  `--instance NAME` to start a parallel one.

### Note
- Existing 17 consumer repos must update their `compose.yaml` to use
  `container_name: ${IMAGE_NAME}${INSTANCE_SUFFIX:-}` (one-line edit) before
  `--instance` works there. Default behavior unchanged until they upgrade.

## [v0.6.7] - 2026-04-09

### Added
- `test/integration/init_new_repo_spec.bats`: 21 Level-1 integration tests
  - Verifies `init.sh` produces a complete repo skeleton in an empty dir
    (Dockerfile, compose.yaml, .env.example, symlinks, doc tree, .github/workflows, etc.)
  - Runs inside the existing `make -f Makefile.ci test` container — no Docker needed
  - Total tests: 180 → 201 (180 unit + 21 integration)
- `.github/workflows/self-test.yaml`: new `integration-e2e` job (Level 2)
  - Runs `init.sh` → `build.sh test` → `build.sh` → `run.sh -d` → `exec.sh` → `stop.sh`
    on a synthetic temp repo, on a real GitHub runner with Docker daemon
  - `release` job now depends on both `test` and `integration-e2e`
- `script/ci/ci.sh`: now also runs `bats test/integration/` alongside `test/unit/`

## [v0.6.6] - 2026-04-09

### Fixed
- `run.sh`: foreground `devel` mode could not be entered via `./exec.sh` from another terminal
  - Symptom: `service "devel" is not running` even though `docker ps` showed it
  - Root cause: foreground used `compose run --name`, which creates a one-off container
    invisible to `compose exec` (the underlying mechanism behind `./exec.sh`)
  - Fix: foreground `devel` now uses `compose up -d` + `compose exec devel bash`
    + a `trap … down EXIT` to preserve the original "exit shell = container gone" semantic
  - Other targets (`test`, `runtime`, ...) still use `compose run --rm` (one-shot stages
    that don't need exec)
  - `compose.yaml` `container_name: ${IMAGE_NAME}` is unchanged, so external scripts
    that do `docker exec ${IMAGE_NAME}` (e.g. local CI helpers) continue to work

### Removed
- `stop.sh`: orphan-container cleanup `docker rm -f "${IMAGE_NAME}"` no longer needed
  (no more orphan from `compose run --name`)

## [v0.6.5] - 2026-04-09

### Fixed
- `build.sh`/`run.sh`/`exec.sh`/`stop.sh`: graceful fallback when `i18n.sh` is missing
  - v0.6.1 added `source template/script/docker/i18n.sh` but consumer Dockerfile
    `test` stages do `COPY *.sh /lint/` without the template tree, so the source
    failed and broke smoke tests in all consumer repos
  - Fix: each script checks for i18n.sh and falls back to inline `_detect_lang`
    if missing — no Dockerfile changes required in consumer repos

## [v0.6.4] - 2026-04-09

### Fixed
- `upgrade.sh`: greedy sed pattern clobbered `release-worker.yaml@<ver>` reference,
  replacing it with `build-worker.yaml@<ver>` and breaking release CI in consumer repos
  - Root cause: `s|template/\.github/workflows/.*@v[0-9.]*|...build-worker.yaml@...|`
    matched both worker references; the dedicated `release-worker` line that follows
    only worked when the first sed didn't already overwrite it
  - Fix: drop the greedy first sed, keep only the per-worker-name targeted seds

## [v0.6.3] - 2026-04-09

### Added
- `upgrade.sh`: `--gen-image-conf` flag (delegates to `init.sh --gen-image-conf`)
  - Lets users copy `image_name.conf` to repo root for per-repo customization
    without needing to remember the init.sh path

## [v0.6.2] - 2026-04-09

### Changed
- Remove all `# LCOV_EXCL_*` markers from shell scripts to expose real coverage
  - Coverage now reflects actual instrumented lines (95.76% vs prior masked 100%)
  - 2 new direct-run tests for `tmux/setup.sh` and `terminator/setup.sh` (171 total)
  - Remaining 10 uncovered lines in `setup.sh` are kcov bash backend limitations
    (case `;;` arms, `done` redirect close, child-bash guards)

## [v0.6.1] - 2026-04-08

### Added
- `build.sh`: `--clean-tools` flag to remove `test-tools:local` image after build
- `script/docker/i18n.sh`: shared `_detect_lang()` and `_LANG` initialization
  - Sourced by build.sh, run.sh, exec.sh, stop.sh, setup.sh
  - Eliminates ~28 lines of duplication across 5 scripts
  - Adding a new language now requires editing only one file
- `dockerfile/Dockerfile.test-tools`: include `bats-mock` (jasonkarns v1.2.5)
  - Other repos' smoke tests can now use `stub`/`unstub` for command mocking

### Changed
- `build.sh`: keep `test-tools:local` image by default (was removed on EXIT)
  - Avoids race conditions in parallel builds
  - Subsequent builds skip the test-tools build (Docker layer cache)
  - Use `--clean-tools` to restore old behavior

## [v0.6.0] - 2026-04-01

### Added
- `build.sh`: `--no-cache` flag for force rebuild (passes to both
  test-tools image build and docker compose build)
- `config/image_name.conf`: rule-driven IMAGE_NAME detection
  - Rule types: `prefix:<value>`, `suffix:<value>`, `@env_example`, `@basename`, `@default:<value>`
  - Per-repo override: place `image_name.conf` in repo root
  - Default rules: `@env_example` → `prefix:docker_` → `suffix:_ws` → `@default:unknown`
- `init.sh --gen-image-conf`: copy template's image_name.conf to repo root
  for per-repo customization

### Changed
- `detect_image_name`: refactored to read rules from `image_name.conf` instead
  of hardcoded logic
- **BREAKING**: `image_name.conf` keywords now require `@` prefix
  (`env_example` → `@env_example`, `basename` → `@basename`) to distinguish
  from user-defined values
- Default conf order: `@env_example` → `prefix:docker_` → `suffix:_ws` → `@default:unknown`
  (`.env.example` highest priority; `@default:unknown` as final fallback
  prints INFO log so users know to set IMAGE_NAME explicitly)
- New `@default:<value>` keyword: explicit fallback value with INFO log
- WARNING only when no rule matches AND no `@default:` set (custom conf scenario)

### Fixed
- `stop.sh`: remove orphan container left by `docker compose run --name`
  (`docker compose down` only cleans up `up`-mode containers, not `run`-mode)
- `upgrade.sh`: re-run `init.sh` after subtree pull to sync symlinks
  (avoids stale symlinks when template directory structure changes)

### Removed
- Stale comments referencing `get_param.sh` (historical, no longer relevant)

## [v0.5.0] - 2026-03-31

### Added
- `setup.sh`: add `APT_MIRROR_UBUNTU` and `APT_MIRROR_DEBIAN` to `.env`
  - Default: `tw.archive.ubuntu.com` (Ubuntu), `mirror.twds.com.tw` (Debian)
  - Preserves existing values from `.env` on re-run
- `setup.sh`: warn when `IMAGE_NAME` cannot be detected and `.env.example` not found
- `display_env.bats`: auto-skip GUI tests for headless repos
- `dockerfile/Dockerfile.test-tools`: pre-built test tools image (ShellCheck + Hadolint + Bats)
- `dockerfile/Dockerfile.example`: Dockerfile template for new repos
- `init.sh`: support creating new repo with full project structure
- `build.sh`: auto-build `test-tools:local` before compose build
- 5 new tests (137 total)

### Changed
- **BREAKING**: Directory restructure
  - `build.sh`, `run.sh`, `exec.sh`, `stop.sh`, `Makefile`, `setup.sh` → `script/docker/`
  - `ci.sh` → `script/ci/`
  - `init.sh`, `upgrade.sh` → template root (user-facing)
- Other repos symlink path: `template/build.sh` → `template/script/docker/build.sh`

## [v0.4.2] - 2026-03-30

### Fixed
- `run.sh`: set `--name "${IMAGE_NAME}"` in foreground mode (`docker compose run`) so container name matches `container_name` in compose.yaml

### Removed
- `script/migrate.sh`: all repos migrated, no longer needed
- i18n translations for TEST.md and CHANGELOG.md (keep English only)

## [v0.4.1] - 2026-03-29

### Changed
- Rename `test/smoke_test/` → `test/smoke/`
- Fix README.md TOC anchor and add missing Tests section

## [v0.4.0] - 2026-03-29

### Changed
- Move `config/` back to root level (was `script/config/` in v0.3.0) — configs are not scripts
- Fix `self-test.yaml` release archive: remove stale root `setup.sh` reference
- Fix mermaid architecture diagrams: `setup.sh` shown in correct `script/` box
- Add Table of Contents to zh-TW and zh-CN READMEs
- Add `Makefile.ci` entry to "What's included" table (all translations)
- Fix "Running Tests" section to use `make -f Makefile.ci` (all translations)
- Rename `test/smoke_test/` → `test/smoke/`

## [v0.3.0] - 2026-03-29

### Changed
- **BREAKING**: Rename repo `docker_template` → `template`
- **BREAKING**: Move `setup.sh` → `script/setup.sh`
- **BREAKING**: Move `config/` → `script/config/` (reverted in v0.4.0)
- Apply Google Shell Style Guide to all shell scripts
- Split `Makefile` into `Makefile` (repo entry) + `Makefile.ci` (CI entry)
- Fix directory structure, test counts, bashrc style in documentation
- 132 tests (was 124)

### Migration notes
- Other repos: subtree prefix changes from `docker_template/` to `template/`
- `CONFIG_SRC` path in Dockerfile: `docker_template/config` → `template/config`
- Symlinks: `docker_template/*.sh` → `template/*.sh`

## [v0.2.0] - 2026-03-28

### Added
- `script/ci.sh`: CI pipeline script (local + remote)
- `Makefile`: unified command entry
- Restructured `test/unit/` and `test/smoke_test/`
- Restructured `doc/` with i18n (readme/, test/, changelog/)
- Coverage permissions fix (chown with HOST_UID/HOST_GID)

### Changed
- `smoke_test/` moved to `test/smoke_test/` (**BREAKING**: Dockerfile COPY path change)
- `compose.yaml` calls `script/ci.sh --ci` instead of inline bash
- `self-test.yaml` calls `script/ci.sh` instead of docker compose directly

## [v0.1.0] - 2026-03-28

### Added
- **Shared shell scripts**: `build.sh`, `run.sh` (with X11/Wayland support), `exec.sh`, `stop.sh`
- **setup.sh**: `.env` generator merged from `docker_setup_helper` (auto-detect UID/GID, GPU, workspace path, image name)
- **Config files**: bashrc, tmux, terminator, pip configs from `docker_setup_helper`
- **Shared smoke tests** (`smoke_test/`):
  - `script_help.bats` — 16 tests for script help/usage
  - `display_env.bats` — 10 tests for X11/Wayland environment (GUI repos)
  - `test_helper.bash` — unified bats loader
- **Template self-tests** (`test/`): 114 tests with ShellCheck + Bats + Kcov coverage
- **CI reusable workflows**:
  - `build-worker.yaml` — parameterized Docker build + smoke test
  - `release-worker.yaml` — parameterized GitHub Release
  - `self-test.yaml` — template's own CI
- **`migrate.sh`**: batch migration script for converting repos from `docker_setup_helper` to `template`
- `.hadolint.yaml`: shared Hadolint rules
- `.codecov.yaml`: coverage configuration
- Documentation: README (English), README.zh-TW.md, README.zh-CN.md, README.ja.md, TEST.md

### Changed
- `setup.sh` default `_base_path` traverses 1 level up (`/..`) instead of 2 (`/../..`) to match new `template/setup.sh` location

### Migration notes
- Replace `docker_setup_helper/` subtree with `template/` subtree
- Shell scripts at root become symlinks to `template/`
- Local `build-worker.yaml` / `release-worker.yaml` replaced by reusable workflow calls in `main.yaml`
- Dockerfile `CONFIG_SRC` path: `docker_setup_helper/src/config` → `template/config`
- Shared smoke tests loaded via `COPY template/smoke_test/` in Dockerfile (not symlinks)

[v0.6.8]: https://github.com/ycpss91255-docker/template/compare/v0.6.7...v0.6.8
[v0.6.7]: https://github.com/ycpss91255-docker/template/compare/v0.6.6...v0.6.7
[v0.6.6]: https://github.com/ycpss91255-docker/template/compare/v0.6.5...v0.6.6
[v0.6.5]: https://github.com/ycpss91255-docker/template/compare/v0.6.4...v0.6.5
[v0.6.4]: https://github.com/ycpss91255-docker/template/compare/v0.6.3...v0.6.4
[v0.6.3]: https://github.com/ycpss91255-docker/template/compare/v0.6.2...v0.6.3
[v0.6.2]: https://github.com/ycpss91255-docker/template/compare/v0.6.1...v0.6.2
[v0.6.1]: https://github.com/ycpss91255-docker/template/compare/v0.6.0...v0.6.1
[v0.6.0]: https://github.com/ycpss91255-docker/template/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/ycpss91255-docker/template/compare/v0.4.2...v0.5.0
[v0.4.2]: https://github.com/ycpss91255-docker/template/compare/v0.4.1...v0.4.2
[v0.4.1]: https://github.com/ycpss91255-docker/template/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/ycpss91255-docker/template/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/ycpss91255-docker/template/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/ycpss91255-docker/template/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/ycpss91255-docker/template/releases/tag/v0.1.0
