**[English](CHANGELOG.md)** | **[繁體中文](CHANGELOG.zh-TW.md)** | **[简体中文](CHANGELOG.zh-CN.md)** | **[日本語](CHANGELOG.ja.md)**

# 変更履歴

フォーマットは [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
バージョン番号は [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [未リリース]

## [v2.0.0] - 2026-03-28

### 追加
- migrate from docker_setup_helper to template

### 変更
- remove docker_setup_helper subtree and local CI workflows

### 修正
- use custom .hadolint.yaml for agent repos
- copy only non-GUI smoke tests from template

## [v1.5.0] - 2026-03-25

### 追加
- add subtree docs, i18n, and version check (#1)
- add config symlink to docker_setup_helper/src/config

### 変更
- move smoke/ to test/smoke/
- move READMEs to doc/, entrypoint.sh to script/

## [v1.4.0] - 2026-03-20

### 変更
- test: add script_help.bats for shell script -h/--help tests

## [v1.3.1] - 2026-03-19

### 追加
- add stop.sh for stopping background containers

## [v1.3.0] - 2026-03-19

### 追加
- auto down before up -d, remove stop.sh
- add stop.sh to clean up background containers

### 変更
- exec.sh use -t flag for target, args as command

## [v1.2.1] - 2026-03-19

### 変更
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 3c969ca..e29f35a
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from 3bafb77..3c969ca
- remove lint-worker.yaml, lint runs in Dockerfile test stage

## [v1.2.0] - 2026-03-19

### 追加
- add ShellCheck + Hadolint to Dockerfile test stage

## [v1.1.1] - 2026-03-18

- Maintenance release

## [v1.1.0] - 2026-03-18

### 追加
- always regenerate .env on build/run, add --no-env flag

### 変更
- add agent-specific hadolint ignores (DL3015/DL3016/DL3059)
- add .hadolint.yaml to ignore inapplicable rules
- update docker_setup_helper subtree
- Squashed 'docker_setup_helper/' changes from ad9e7f8..3bafb77
- add ShellCheck and Hadolint static analysis

### 修正
- suppress shellcheck warnings in entrypoint.sh

## [v1.0.0] - 2026-03-18

### 追加
- add -h/--help support to all interactive scripts

### 変更
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

### 修正
- release-worker.yaml archive list and exec.sh bugs
- update CUDA version in .env.example comment

