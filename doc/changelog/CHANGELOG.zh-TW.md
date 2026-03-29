# 變更記錄

本文件記錄所有重要變更。

格式基於 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本號遵循 [語意化版本](https://semver.org/spec/v2.0.0.html)。

## [v0.4.0] - 2026-03-29

### 變更
- `config/` 從 `script/config/` 搬回根目錄（v0.3.0 時移入，設定檔不應放在 script/）
- 修正 `self-test.yaml` release archive：移除不存在的 root `setup.sh` 引用
- 修正 mermaid 架構圖：`setup.sh` 顯示在正確的 `script/` 區塊
- zh-TW / zh-CN README 補上目錄（Table of Contents）
- 翻譯同步：「包含內容」表格補上 `Makefile.ci` 條目
- 翻譯同步：「本地執行測試」改為正確的 `make -f Makefile.ci` 指令
- 重新命名 `test/smoke_test/` → `test/smoke/`

## [v0.3.0] - 2026-03-29

### 變更
- **破壞性變更**：Repo 更名 `docker_template` → `template`
- **破壞性變更**：`setup.sh` 移至 `script/setup.sh`
- **破壞性變更**：`config/` 移至 `script/config/`（v0.4.0 已搬回）
- 所有 Shell 腳本套用 Google Shell Style Guide
- `Makefile` 拆分為 `Makefile`（repo 用）+ `Makefile.ci`（CI 用）
- 修正文件中的目錄結構、測試數量、bashrc style
- 132 個測試（原 124 個）

### 遷���注意事項
- Other repos：subtree prefix 從 `docker_template/` 改為 `template/`
- Dockerfile `CONFIG_SRC` 路徑：`docker_template/config` → `template/config`
- Symlinks：`docker_template/*.sh` → `template/*.sh`

## [v0.2.0] - 2026-03-28

### 新增
- `script/ci.sh`：CI pipeline 腳本（本地 + 遠端）
- `Makefile`：統一指令入口
- 重整 `test/unit/` 和 `test/smoke_test/`
- 重整 `doc/`（含 i18n：readme/、test/、changelog/）
- 修復 coverage 權限（使用 HOST_UID/HOST_GID 的 chown）

### 變更
- `smoke_test/` 移至 `test/smoke_test/`（**破壞性變更**：Dockerfile COPY 路徑變更）
- `compose.yaml` 改為呼叫 `script/ci.sh --ci`（取代 inline bash）
- `self-test.yaml` 改為呼叫 `script/ci.sh`（取代直接呼叫 docker compose）

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
- **`migrate.sh`**：批次遷移腳本（從 `docker_setup_helper` 轉換至 `template`）
- `.hadolint.yaml`：共用 Hadolint 規則
- `.codecov.yaml`：覆蓋率設定
- 文件：README（英文）、README.zh-TW.md、README.zh-CN.md、README.ja.md、TEST.md

### 變更
- `setup.sh` 預設 `_base_path` 改為向上 1 層（`/..`），以符合新的 `template/setup.sh` 位置

### 遷移注意事項
- 將 `docker_setup_helper/` subtree 替換為 `template/` subtree
- 根目錄的 Shell 腳本改為指向 `template/` 的 symlinks
- 本地 `build-worker.yaml` / `release-worker.yaml` 替換為 `main.yaml` 中的可重用 workflow 呼叫
- Dockerfile `CONFIG_SRC` 路徑：`docker_setup_helper/src/config` → `template/config`
- 共用 smoke tests 透過 Dockerfile `COPY template/test/smoke_test/` 載入（非 symlinks）

[v0.4.0]: https://github.com/ycpss91255-docker/template/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/ycpss91255-docker/template/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/ycpss91255-docker/template/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/ycpss91255-docker/template/releases/tag/v0.1.0
