# docker_template

[![Self Test](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml)

[ycpss91255-docker](https://github.com/ycpss91255-docker) 組織下所有 Docker 容器 repo 的共用模板。

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

## 概述

此 repo 集中管理所有 Docker 容器 repo 共用的腳本、測試和 CI workflow。各 repo 透過 **git subtree** 拉入此模板，並使用 symlink 引用共用檔案。

### 包含內容

| 檔案 | 說明 |
|------|------|
| `build.sh` | 建置容器（呼叫 `setup.sh` 產生 `.env`） |
| `run.sh` | 執行容器（支援 X11/Wayland） |
| `exec.sh` | 進入執行中的容器 |
| `stop.sh` | 停止並移除容器 |
| `setup.sh` | 自動偵測系統參數並產生 `.env` |
| `config/` | Shell 設定檔（bashrc、tmux、terminator、pip） |
| `smoke_test/` | 給各 consumer repo 使用的共用測試 |
| `.hadolint.yaml` | 共用 Hadolint 規則 |
| `.github/workflows/build-worker.yaml` | 可重用的 CI 建置 workflow |
| `.github/workflows/release-worker.yaml` | 可重用的 CI 發布 workflow |

### 各 repo 自行維護的檔案（不共用）

- `Dockerfile`
- `compose.yaml`
- `.env.example`
- `script/entrypoint.sh`
- `doc/` 和 `README.md`
- Repo 專屬的 smoke test

## 快速開始

### 加入新 repo

```bash
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash
echo "v1.0.0" > .docker_template_version
```

### 建立 symlinks

```bash
# 根目錄腳本
ln -sf docker_template/build.sh build.sh
ln -sf docker_template/run.sh run.sh
ln -sf docker_template/exec.sh exec.sh
ln -sf docker_template/stop.sh stop.sh
ln -sf docker_template/.hadolint.yaml .hadolint.yaml

# Smoke tests
ln -sf ../../docker_template/smoke_test/test_helper.bash test/smoke_test/test_helper.bash
ln -sf ../../docker_template/smoke_test/script_help.bats test/smoke_test/script_help.bats
# 僅 GUI repos:
ln -sf ../../docker_template/smoke_test/display_env.bats test/smoke_test/display_env.bats
```

### 更新 subtree

```bash
git subtree pull --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash \
    -m "chore: update docker_template subtree"
```

更新 `.docker_template_version` 為最新 tag。

## CI Reusable Workflows

各 repo 將本地的 `build-worker.yaml` / `release-worker.yaml` 替換為呼叫此 repo 的 reusable workflows：

```yaml
# .github/workflows/main.yaml
jobs:
  call-docker-build:
    uses: ycpss91255-docker/docker_template/.github/workflows/build-worker.yaml@v1
    with:
      image_name: ros_noetic
      build_args: |
        ROS_DISTRO=noetic
        ROS_TAG=ros-base
        UBUNTU_CODENAME=focal

  call-release:
    needs: call-docker-build
    if: startsWith(github.ref, 'refs/tags/')
    uses: ycpss91255-docker/docker_template/.github/workflows/release-worker.yaml@v1
    with:
      archive_name_prefix: ros_noetic
```

### build-worker.yaml 參數

| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| `image_name` | string | 是 | - | 容器映像名稱 |
| `build_args` | string | 否 | `""` | 多行 KEY=VALUE 建置參數 |
| `build_runtime` | boolean | 否 | `true` | 是否建置 runtime stage |

### release-worker.yaml 參數

| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| `archive_name_prefix` | string | 是 | - | Archive 名稱前綴 |
| `extra_files` | string | 否 | `""` | 額外檔案（空格分隔） |

## 本地執行測試

```bash
docker compose run --rm ci
```

執行 ShellCheck + Bats 測試 + Kcov 覆蓋率報表。

## Smoke Tests

位於 `smoke_test/` — 共 **22 個測試**。

<details>
<summary>點擊展開測試詳情</summary>

### script_help.bats (16)

| 測試項目 | 說明 |
|----------|------|
| `build.sh -h exits 0` | Help 旗標正常退出 |
| `build.sh --help exits 0` | 長 help 旗標正常退出 |
| `build.sh -h prints usage` | Help 輸出包含 "Usage:" |
| `run.sh -h exits 0` | Help 旗標正常退出 |
| `run.sh --help exits 0` | 長 help 旗標正常退出 |
| `run.sh -h prints usage` | Help 輸出包含 "Usage:" |
| `exec.sh -h exits 0` | Help 旗標正常退出 |
| `exec.sh --help exits 0` | 長 help 旗標正常退出 |
| `exec.sh -h prints usage` | Help 輸出包含 "Usage:" |
| `stop.sh -h exits 0` | Help 旗標正常退出 |
| `stop.sh --help exits 0` | 長 help 旗標正常退出 |
| `stop.sh -h prints usage` | Help 輸出包含 "Usage:" |
| `build.sh detects zh` | 自動偵測中文 |
| `build.sh detects ja` | 自動偵測日文 |
| `build.sh defaults to en` | 預設英文 |
| `build.sh SETUP_LANG overrides` | SETUP_LANG 覆蓋 LANG |

### display_env.bats (6)

| 測試項目 | 說明 |
|----------|------|
| `compose.yaml contains WAYLAND_DISPLAY` | Wayland 環境變數 |
| `compose.yaml contains XDG_RUNTIME_DIR` | XDG runtime 目錄 |
| `compose.yaml contains XAUTHORITY` | X authority |
| `compose.yaml mounts XDG_RUNTIME_DIR` | Volume 掛載 |
| `compose.yaml mounts XAUTHORITY` | Volume 掛載 |
| `compose.yaml mounts X11-unix` | X11 socket 掛載 |

</details>

## 目錄結構

```
docker_template/
├── build.sh                          # 共用建置腳本
├── run.sh                            # 共用執行腳本（X11/Wayland）
├── exec.sh                           # 共用 exec 腳本
├── stop.sh                           # 共用停止腳本
├── setup.sh                          # .env 產生器
├── config/                           # Shell/工具設定
│   ├── pip/
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       └── tmux/
├── smoke_test/                       # 給各 repo 使用的共用測試
│   ├── test_helper.bash
│   ├── script_help.bats
│   └── display_env.bats
├── test/                             # 模板自身測試（114 個）
├── compose.yaml                      # 本地 CI 執行器
├── .hadolint.yaml                    # 共用 Hadolint 規則
├── .github/workflows/
│   ├── self-test.yaml                # 模板 CI
│   ├── build-worker.yaml             # 可重用建置 workflow
│   └── release-worker.yaml           # 可重用發布 workflow
├── .codecov.yaml
├── .gitignore
├── LICENSE
├── README.md
├── doc/
└── TEST.md
```
