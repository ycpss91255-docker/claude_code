**[English](CHANGELOG.md)** | **[繁體中文](CHANGELOG.zh-TW.md)** | **[简体中文](CHANGELOG.zh-CN.md)** | **[日本語](CHANGELOG.ja.md)**

# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v2.0.0] - 2026-03-28

### Added
- migrate from docker_setup_helper to template

### Changed
- remove docker_setup_helper subtree and local CI workflows

### Fixed
- use custom .hadolint.yaml for agent repos
- copy only non-GUI smoke tests from template

## [v1.5.0] - 2026-03-25

### Added
- add subtree docs, i18n, and version check (#1)
- add config symlink to docker_setup_helper/src/config

### Changed
- move smoke/ to test/smoke/
- move READMEs to doc/, entrypoint.sh to script/

## [v1.4.0] - 2026-03-20

### Changed
- test: add script_help.bats for shell script -h/--help tests

## [v1.3.1] - 2026-03-19

### Added
- add stop.sh for stopping background containers

## [v1.3.0] - 2026-03-19

### Added
- auto down before up -d, remove stop.sh
- add stop.sh to clean up background containers

### Changed
- exec.sh use -t flag for target, args as command

## [v1.2.1] - 2026-03-19

### Changed
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 3c969ca..e29f35a
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 3bafb77..3c969ca
- remove lint-worker.yaml, lint runs in Dockerfile test stage

## [v1.2.0] - 2026-03-19

### Added
- add ShellCheck + Hadolint to Dockerfile test stage

## [v1.1.1] - 2026-03-18

- Maintenance release

## [v1.1.0] - 2026-03-18

### Added
- always regenerate .env on build/run, add --no-env flag

### Changed
- add agent-specific hadolint ignores (DL3015/DL3016/DL3059)
- add .hadolint.yaml to ignore inapplicable rules
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from ad9e7f8..3bafb77
- add ShellCheck and Hadolint static analysis

### Fixed
- suppress shellcheck warnings in entrypoint.sh

## [v1.0.0] - 2026-03-18

### Added
- add -h/--help support to all interactive scripts

### Changed
- unify help text to usage() function, add smoke test tables
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from f80a781..ad9e7f8
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 2c15ade..f80a781
- Squashed 'docker_setup_helper/' changes from 6924234..2c15ade
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 05c341f..6924234
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from f08786a..05c341f
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 6f75fb6..f08786a
- update docker_setup_helper subtree
- Update CUDA to 13.1.1 + cuDNN on Ubuntu 24.04
- Remove incorrectly named README_zh-TW.md (replaced by README.zh-TW.md)
- Add Traditional Chinese README
- Add detach mode to run.sh and rewrite exec.sh

### Fixed
- release-worker.yaml archive list and exec.sh bugs
- update CUDA version in .env.example comment

