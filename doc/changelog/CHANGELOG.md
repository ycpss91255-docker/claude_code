# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.5.0] - 2026-03-31

### Added
- `setup.sh`: add `APT_MIRROR_UBUNTU` and `APT_MIRROR_DEBIAN` to `.env`
  - Default: `tw.archive.ubuntu.com` (Ubuntu), `mirror.twds.com.tw` (Debian)
  - Preserves existing values from `.env` on re-run
- `setup.sh`: warn when `IMAGE_NAME` cannot be detected (prints WARNING, uses `unknown`)
- 4 new tests (136 total)

### Removed
- `setup.sh`: remove `.env.example` fallback for `IMAGE_NAME` (replaced by warning)

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

[v0.4.2]: https://github.com/ycpss91255-docker/template/compare/v0.4.1...v0.4.2
[v0.4.1]: https://github.com/ycpss91255-docker/template/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/ycpss91255-docker/template/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/ycpss91255-docker/template/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/ycpss91255-docker/template/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/ycpss91255-docker/template/releases/tag/v0.1.0
