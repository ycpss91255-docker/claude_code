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
用法: ./stop.sh [-h]

停止並移除此專案的所有容器。

選項:
  -h, --help     顯示此說明
EOF
            ;;
        zh-CN)
            cat >&2 <<'EOF'
用法: ./stop.sh [-h]

停止并移除此项目的所有容器。

选项:
  -h, --help     显示此说明
EOF
            ;;
        ja)
            cat >&2 <<'EOF'
使用法: ./stop.sh [-h]

このプロジェクトのすべてのコンテナを停止・削除します。

オプション:
  -h, --help     このヘルプを表示
EOF
            ;;
        *)
            cat >&2 <<'EOF'
Usage: ./stop.sh [-h]

Stop and remove all containers for this project.

Options:
  -h, --help     Show this help
EOF
            ;;
    esac
    exit 0
}

if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    usage
fi

# Load .env for project name
set -o allexport
# shellcheck disable=SC1091
source "${FILE_PATH}/.env"
set +o allexport

docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    down "$@"
