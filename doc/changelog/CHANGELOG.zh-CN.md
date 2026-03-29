# 变更记录

本文件记录所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/spec/v2.0.0.html)。

## [v0.4.0] - 2026-03-29

### 变更
- `config/` 从 `script/config/` 搬回根目录（v0.3.0 时移入，配置文件不应放在 script/）
- 修正 `self-test.yaml` release archive：移除不存在的 root `setup.sh` 引用
- 修正 mermaid 架构图：`setup.sh` 显示在正确的 `script/` 区块
- zh-TW / zh-CN README 补上目录（Table of Contents）
- 翻译同步：「包含内容」表格补上 `Makefile.ci` 条目
- 翻译同步：「本地运行测试」改为正确的 `make -f Makefile.ci` 命令
- 重命名 `test/smoke_test/` → `test/smoke/`

## [v0.3.0] - 2026-03-29

### 变更
- **破坏性变更**：Repo 更名 `docker_template` → `template`
- **破坏性变更**：`setup.sh` 移至 `script/setup.sh`
- **破坏性变更**：`config/` 移至 `script/config/`（v0.4.0 已搬回）
- 所有 Shell 脚本套用 Google Shell Style Guide
- `Makefile` 拆分为 `Makefile`（repo 用）+ `Makefile.ci`（CI 用）
- 修正文档中的目录结构、测试数量、bashrc style
- 132 个测试（原 124 个）

### 迁移注意事项
- Other repos：subtree prefix 从 `docker_template/` 改为 `template/`
- Dockerfile `CONFIG_SRC` 路径：`docker_template/config` → `template/config`
- Symlinks：`docker_template/*.sh` → `template/*.sh`

## [v0.2.0] - 2026-03-28

### 新增
- `script/ci.sh`：CI pipeline 脚本（本地 + 远端）
- `Makefile`：统一命令入口
- 重整 `test/unit/` 和 `test/smoke_test/`
- 重整 `doc/`（含 i18n：readme/、test/、changelog/）
- 修复 coverage 权限（使用 HOST_UID/HOST_GID 的 chown）

### 变更
- `smoke_test/` 移至 `test/smoke_test/`（**破坏性变更**：Dockerfile COPY 路径变更）
- `compose.yaml` 改为调用 `script/ci.sh --ci`（取代 inline bash）
- `self-test.yaml` 改为调用 `script/ci.sh`（取代直接调用 docker compose）

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
- **`migrate.sh`**：批量迁移脚本（从 `docker_setup_helper` 转换至 `template`）
- `.hadolint.yaml`：共用 Hadolint 规则
- `.codecov.yaml`：覆盖率配置
- 文档：README（英文）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 变更
- `setup.sh` 默认 `_base_path` 改为向上 1 层（`/..`），以符合新的 `template/setup.sh` 位置

### 迁移注意事项
- 将 `docker_setup_helper/` subtree 替换为 `template/` subtree
- 根目录的 Shell 脚本改为指向 `template/` 的 symlinks
- 本地 `build-worker.yaml` / `release-worker.yaml` 替换为 `main.yaml` 中的可重用 workflow 调用
- Dockerfile `CONFIG_SRC` 路径：`docker_setup_helper/src/config` → `template/config`
- 共用 smoke tests 通过 Dockerfile `COPY template/test/smoke_test/` 加载（非 symlinks）

[v0.4.0]: https://github.com/ycpss91255-docker/template/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/ycpss91255-docker/template/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/ycpss91255-docker/template/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/ycpss91255-docker/template/releases/tag/v0.1.0
