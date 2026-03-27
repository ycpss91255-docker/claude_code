#!/usr/bin/env bash

set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
_detect_lang() {
    local _sys_lang="${LANG:-}"
    case "${_sys_lang}" in
        zh_TW*) echo "zh" ;; zh_CN*|zh_SG*) echo "zh-CN" ;; ja*) echo "ja" ;; *) echo "en" ;;
    esac
}
_LANG="${SETUP_LANG:-$(_detect_lang)}"

usage() {
    case "${_LANG}" in
        zh)
            cat >&2 <<'EOF'
用法: ./exec.sh [-h] [-t TARGET] [CMD...]

選項:
  -h, --help       顯示此說明
  -t, --target T   服務名稱（預設: devel）

參數:
  CMD              要執行的指令（預設: bash）

範例:
  ./exec.sh                    # 以 bash 進入 devel 容器
  ./exec.sh htop               # 在 devel 容器中執行 htop
  ./exec.sh ls -la /home       # 在 devel 容器中執行 ls
  ./exec.sh -t runtime bash    # 進入 runtime 容器
EOF
            ;;
        zh-CN)
            cat >&2 <<'EOF'
用法: ./exec.sh [-h] [-t TARGET] [CMD...]

选项:
  -h, --help       显示此说明
  -t, --target T   服务名称（默认: devel）

参数:
  CMD              要执行的命令（默认: bash）

示例:
  ./exec.sh                    # 以 bash 进入 devel 容器
  ./exec.sh htop               # 在 devel 容器中运行 htop
  ./exec.sh ls -la /home       # 在 devel 容器中运行 ls
  ./exec.sh -t runtime bash    # 进入 runtime 容器
EOF
            ;;
        ja)
            cat >&2 <<'EOF'
使用法: ./exec.sh [-h] [-t TARGET] [CMD...]

オプション:
  -h, --help       このヘルプを表示
  -t, --target T   サービス名（デフォルト: devel）

引数:
  CMD              実行するコマンド（デフォルト: bash）

例:
  ./exec.sh                    # bash で devel コンテナに接続
  ./exec.sh htop               # devel コンテナで htop を実行
  ./exec.sh ls -la /home       # devel コンテナで ls を実行
  ./exec.sh -t runtime bash    # runtime コンテナに接続
EOF
            ;;
        *)
            cat >&2 <<'EOF'
Usage: ./exec.sh [-h] [-t TARGET] [CMD...]

Options:
  -h, --help       Show this help
  -t, --target T   Service name (default: devel)

Arguments:
  CMD              Command to execute (default: bash)

Examples:
  ./exec.sh                    # Enter devel container with bash
  ./exec.sh htop               # Run htop in devel container
  ./exec.sh ls -la /home       # Run ls in devel container
  ./exec.sh -t runtime bash    # Enter runtime container
EOF
            ;;
    esac
    exit 0
}

TARGET="devel"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -t|--target)
            TARGET="${2:?"--target requires a value"}"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

CMD="${*:-bash}"

# shellcheck disable=SC2086  # Intentional word splitting for multi-word commands
docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    exec "${TARGET}" ${CMD}
