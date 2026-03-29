#!/usr/bin/env bash
# run.sh - Run Docker containers (interactive or detached)

set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly FILE_PATH
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
用法: ./run.sh [-h] [-d|--detach] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

選項:
  -h, --help     顯示此說明
  -d, --detach   背景執行（docker compose up -d）
  --no-env       跳過 .env 重新產生
  --lang LANG    設定訊息語言（預設: en）

目標:
  devel    開發環境（預設）
  runtime  最小化 runtime
EOF
      ;;
    zh-CN)
      cat >&2 <<'EOF'
用法: ./run.sh [-h] [-d|--detach] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

选项:
  -h, --help     显示此说明
  -d, --detach   后台运行（docker compose up -d）
  --no-env       跳过 .env 重新生成
  --lang LANG    设置消息语言（默认: en）

目标:
  devel    开发环境（默认）
  runtime  最小化 runtime
EOF
      ;;
    ja)
      cat >&2 <<'EOF'
使用法: ./run.sh [-h] [-d|--detach] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

オプション:
  -h, --help     このヘルプを表示
  -d, --detach   バックグラウンドで実行（docker compose up -d）
  --no-env       .env の再生成をスキップ
  --lang LANG    メッセージ言語を設定（デフォルト: en）

ターゲット:
  devel    開発環境（デフォルト）
  runtime  最小化ランタイム
EOF
      ;;
    *)
      cat >&2 <<'EOF'
Usage: ./run.sh [-h] [-d|--detach] [--no-env] [--lang <en|zh|zh-CN|ja>] [TARGET]

Options:
  -h, --help     Show this help
  -d, --detach   Run in background (docker compose up -d)
  --no-env       Skip .env regeneration
  --lang LANG    Set message language (default: en)

Targets:
  devel    Development environment (default)
  runtime  Minimal runtime
EOF
      ;;
  esac
  exit 0
}

# Parse arguments
SKIP_ENV=false
DETACH=false
TARGET="devel"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -d|--detach)
      DETACH=true
      shift
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
  "${FILE_PATH}/template/script/setup.sh" --base-path "${FILE_PATH}" --lang "${_LANG}"
fi

# Load .env for xhost
set -o allexport
# shellcheck disable=SC1091
source "${FILE_PATH}/.env"
set +o allexport

# Allow X11 forwarding (X11 or XWayland)
if [[ "${XDG_SESSION_TYPE:-x11}" == "wayland" ]]; then
  xhost "+SI:localuser:${USER_NAME}" >/dev/null 2>&1 || true
else
  xhost +local: >/dev/null 2>&1 || true
fi

if [[ "${DETACH}" == true ]]; then
  docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    down 2>/dev/null || true
  docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    up -d "${TARGET}"
else
  docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    run --rm "${TARGET}"
fi
