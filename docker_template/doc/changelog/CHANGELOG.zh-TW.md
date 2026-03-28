# 變更記錄

本文件記錄所有重要變更。

格式基於 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本號遵循 [語意化版本](https://semver.org/spec/v2.0.0.html)。

## [未發布]

### 新增
- `scripts/init.sh`：一鍵為 consumer repo 建立 symlinks
- `Makefile`：統一指令入口（`make test`、`make lint`、`make migrate` 等）

### 變更
- 管理腳本移至 `scripts/`（ci.sh、migrate.sh、init.sh）— 與使用者操作腳本分離
- `Makefile` 和 `compose.yaml` 留在根目錄（使用者操作用）
- 重整 `test/`：`test/unit/`（自身測試）+ `test/smoke_test/`（consumer 共用測試）
- 重整 `doc/`：`doc/readme/`、`doc/test/`、`doc/changelog/`（依檔案類型分，含 i18n）
- README：簡化測試/變更記錄章節，改為連結至詳細文件
- 124 個測試（原 114 個）

## [v0.2.0] - 2026-03-28

### 新增
- `scripts/ci.sh`：CI pipeline 腳本（本地 + 遠端）
- `Makefile`：統一指令入口
- 重整 `test/unit/` 和 `test/smoke_test/`
- 重整 `doc/`（含 i18n：readme/、test/、changelog/）
- 修復 coverage 權限（使用 HOST_UID/HOST_GID 的 chown）

### 變更
- `smoke_test/` 移至 `test/smoke_test/`（**破壞性變更**：consumer Dockerfile COPY 路徑變更）
- `compose.yaml` 改為呼叫 `scripts/ci.sh --ci`（取代 inline bash）
- `self-test.yaml` 改為呼叫 `scripts/ci.sh`（取代直接呼叫 docker compose）

## [v0.1.0] - 2026-03-28

### 新增
- **共用 Shell 腳本**：`build.sh`、`run.sh`（含 X11/Wayland 支援）、`exec.sh`、`stop.sh`
- **setup.sh**：`.env` 產生器，從 `docker_setup_helper` 合併（自動偵測 UID/GID、GPU、工作區路徑、映像名稱）
- **設定檔**：bashrc、tmux、terminator、pip 設定（來自 `docker_setup_helper`）
- **共用 Smoke Tests**（`smoke_test/`）：
  - `script_help.bats` — 16 個腳本 help/usage 測試
  - `display_env.bats` — 10 個 X11/Wayland 環境測試（GUI repos）
  - `test_helper.bash` — 統一 bats 載入器
- **模板自身測試**（`test/`）：114 個測試（ShellCheck + Bats + Kcov 覆蓋率）
- **CI 可重用 Workflows**：
  - `build-worker.yaml` — 參數化 Docker build + smoke test
  - `release-worker.yaml` — 參數化 GitHub Release
  - `self-test.yaml` — 模板自身 CI
- **`migrate.sh`**：批次遷移腳本（從 `docker_setup_helper` 轉換至 `docker_template`）
- `.hadolint.yaml`：共用 Hadolint 規則
- `.codecov.yaml`：覆蓋率設定
- 文件：README（英文）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 變更
- `setup.sh` 預設 `_base_path` 改為向上 1 層（`/..`），取代原本的 2 層（`/../..`），以符合新的 `docker_template/setup.sh` 位置

### 遷移注意事項
- Consumer repos 將 `docker_setup_helper/` subtree 替換為 `docker_template/` subtree
- 根目錄的 Shell 腳本改為指向 `docker_template/` 的 symlinks
- 本地 `build-worker.yaml` / `release-worker.yaml` 替換為 `main.yaml` 中的可重用 workflow 呼叫
- Dockerfile `CONFIG_SRC` 路徑變更：`docker_setup_helper/src/config` → `docker_template/config`
- 共用 smoke tests 透過 Dockerfile `COPY docker_template/test/smoke_test/` 載入（非 symlinks — Docker COPY 不 follow symlinks）

[未發布]: https://github.com/ycpss91255-docker/docker_template/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/ycpss91255-docker/docker_template/releases/tag/v0.1.0
