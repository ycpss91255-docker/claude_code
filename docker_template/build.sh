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
用法: ./build.sh [-h] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

選項:
  -h, --help     顯示此說明
  --no-env       跳過 .env 重新產生
  --lang LANG    設定訊息語言（預設: en）

目標:
  devel    開發環境（預設）
  test     執行 smoke test
  runtime  最小化 runtime 映像
EOF
            ;;
        zh-CN)
            cat >&2 <<'EOF'
用法: ./build.sh [-h] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

选项:
  -h, --help     显示此说明
  --no-env       跳过 .env 重新生成
  --lang LANG    设置消息语言（默认: en）

目标:
  devel    开发环境（默认）
  test     运行 smoke test
  runtime  最小化 runtime 镜像
EOF
            ;;
        ja)
            cat >&2 <<'EOF'
使用法: ./build.sh [-h] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

オプション:
  -h, --help     このヘルプを表示
  --no-env       .env の再生成をスキップ
  --lang LANG    メッセージ言語を設定（デフォルト: en）

ターゲット:
  devel    開発環境（デフォルト）
  test     smoke test を実行
  runtime  最小化ランタイムイメージ
EOF
            ;;
        *)
            cat >&2 <<'EOF'
Usage: ./build.sh [-h] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

Options:
  -h, --help     Show this help
  --no-env       Skip .env regeneration
  --lang LANG    Set message language (default: en)

Targets:
  devel    Development environment (default)
  test     Run smoke tests
  runtime  Minimal runtime image
EOF
            ;;
    esac
    exit 0
}

SKIP_ENV=false
TARGET="devel"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --no-env)
            SKIP_ENV=true
            shift
            ;;
        --lang)
            _LANG="${2:?"--lang requires a value (en|zh|zh-CN|ja)"}"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# Generate / refresh .env
if [[ "${SKIP_ENV}" == false ]]; then
    "${FILE_PATH}/docker_template/setup.sh" --base-path "${FILE_PATH}" --lang "${_LANG}"
fi

# Load .env for project name
set -o allexport
# shellcheck disable=SC1091
source "${FILE_PATH}/.env"
set +o allexport

docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    build "${TARGET}"
