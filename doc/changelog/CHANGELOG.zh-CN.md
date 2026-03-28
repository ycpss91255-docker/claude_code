# 变更记录

本文件记录所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/spec/v2.0.0.html)。

## [未发布]

### 新增
- `scripts/init.sh`：一键为 consumer repo 创建 symlinks
- `Makefile`：统一命令入口（`make test`、`make lint`、`make migrate` 等）

### 变更
- 管理脚本移至 `scripts/`（ci.sh、migrate.sh、init.sh）— 与用户操作脚本分离
- `Makefile` 和 `compose.yaml` 留在根目录（用户操作用）
- 重整 `test/`：`test/unit/`（自身测试）+ `test/smoke_test/`（consumer 共用测试）
- 重整 `doc/`：`doc/readme/`、`doc/test/`、`doc/changelog/`（按文件类型分，含 i18n）
- README：简化测试/变更记录章节，改为链接至详细文档
- 124 个测试（原 114 个）

## [v0.2.0] - 2026-03-28

### 新增
- `scripts/ci.sh`：CI pipeline 脚本（本地 + 远端）
- `Makefile`：统一命令入口
- 重整 `test/unit/` 和 `test/smoke_test/`
- 重整 `doc/`（含 i18n：readme/、test/、changelog/）
- 修复 coverage 权限（使用 HOST_UID/HOST_GID 的 chown）

### 变更
- `smoke_test/` 移至 `test/smoke_test/`（**破坏性变更**：consumer Dockerfile COPY 路径变更）
- `compose.yaml` 改为调用 `scripts/ci.sh --ci`（替代 inline bash）
- `self-test.yaml` 改为调用 `scripts/ci.sh`（替代直接调用 docker compose）

## [v0.1.0] - 2026-03-28

### 新增
- **共用 Shell 脚本**：`build.sh`、`run.sh`（含 X11/Wayland 支持）、`exec.sh`、`stop.sh`
- **setup.sh**：`.env` 生成器，从 `docker_setup_helper` 合并（自动检测 UID/GID、GPU、工作区路径、镜像名称）
- **配置文件**：bashrc、tmux、terminator、pip 配置（来自 `docker_setup_helper`）
- **共用 Smoke Tests**（`smoke_test/`）：
  - `script_help.bats` — 16 个脚本 help/usage 测试
  - `display_env.bats` — 10 个 X11/Wayland 环境测试（GUI repos）
  - `test_helper.bash` — 统一 bats 加载器
- **模板自身测试**（`test/`）：114 个测试（ShellCheck + Bats + Kcov 覆盖率）
- **CI 可重用 Workflows**：
  - `build-worker.yaml` — 参数化 Docker build + smoke test
  - `release-worker.yaml` — 参数化 GitHub Release
  - `self-test.yaml` — 模板自身 CI
- **`migrate.sh`**：批量迁移脚本（从 `docker_setup_helper` 转换至 `docker_template`）
- `.hadolint.yaml`：共用 Hadolint 规则
- `.codecov.yaml`：覆盖率配置
- 文档：README（英文）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 变更
- `setup.sh` 默认 `_base_path` 改为向上 1 层（`/..`），替代原本的 2 层（`/../..`），以匹配新的 `docker_template/setup.sh` 位置

### 迁移注意事项
- Consumer repos 将 `docker_setup_helper/` subtree 替换为 `docker_template/` subtree
- 根目录的 Shell 脚本改为指向 `docker_template/` 的 symlinks
- 本地 `build-worker.yaml` / `release-worker.yaml` 替换为 `main.yaml` 中的可重用 workflow 调用
- Dockerfile `CONFIG_SRC` 路径变更：`docker_setup_helper/src/config` → `docker_template/config`
- 共用 smoke tests 通过 Dockerfile `COPY docker_template/test/smoke_test/` 加载（非 symlinks — Docker COPY 不 follow symlinks）

[未发布]: https://github.com/ycpss91255-docker/docker_template/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/ycpss91255-docker/docker_template/releases/tag/v0.1.0
