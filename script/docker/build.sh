#!/usr/bin/env bash
# build.sh - Build Docker container images

set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly FILE_PATH
if [[ -f "${FILE_PATH}/template/script/docker/i18n.sh" ]]; then
  # shellcheck disable=SC1091
  source "${FILE_PATH}/template/script/docker/i18n.sh"
else
  # Fallback for environments without template/ tree (e.g. consumer
  # Dockerfile /lint smoke test stage that COPYs only *.sh files)
  _detect_lang() {
    case "${LANG:-}" in
      zh_TW*) echo "zh" ;;
      zh_CN*|zh_SG*) echo "zh-CN" ;;
      ja*) echo "ja" ;;
      *) echo "en" ;;
    esac
  }
  _LANG="${SETUP_LANG:-$(_detect_lang)}"
fi

usage() {
  case "${_LANG}" in
    zh)
      cat >&2 <<'EOF'
用法: ./build.sh [-h] [--no-env] [--no-cache] [--clean-tools] [--lang <en|zh|zh-CN|ja>] [TARGET]

選項:
  -h, --help     顯示此說明
  --no-env       跳過 .env 重新產生
  --no-cache     強制不使用 cache 重建
  --clean-tools  build 結束後移除 test-tools:local image（預設保留以加速下次 build）
  --lang LANG    設定訊息語言（預設: en）

目標:
  devel    開發環境（預設）
  test     執行 smoke test
  runtime  最小化 runtime 映像
EOF
      ;;
    zh-CN)
      cat >&2 <<'EOF'
用法: ./build.sh [-h] [--no-env] [--no-cache] [--clean-tools] [--lang <en|zh|zh-CN|ja>] [TARGET]

选项:
  -h, --help     显示此说明
  --no-env       跳过 .env 重新生成
  --no-cache     强制不使用 cache 重建
  --clean-tools  build 结束后移除 test-tools:local image（默认保留以加速下次 build）
  --lang LANG    设置消息语言（默认: en）

目标:
  devel    开发环境（默认）
  test     运行 smoke test
  runtime  最小化 runtime 镜像
EOF
      ;;
    ja)
      cat >&2 <<'EOF'
使用法: ./build.sh [-h] [--no-env] [--no-cache] [--clean-tools] [--lang <en|zh|zh-CN|ja>] [TARGET]

オプション:
  -h, --help     このヘルプを表示
  --no-env       .env の再生成をスキップ
  --no-cache     キャッシュを使わず強制リビルド
  --clean-tools  build 終了後に test-tools:local image を削除（デフォルトは保持）
  --lang LANG    メッセージ言語を設定（デフォルト: en）

ターゲット:
  devel    開発環境（デフォルト）
  test     smoke test を実行
  runtime  最小化ランタイムイメージ
EOF
      ;;
    *)
      cat >&2 <<'EOF'
Usage: ./build.sh [-h] [--no-env] [--no-cache] [--clean-tools] [--lang <en|zh|zh-CN|ja>] [TARGET]

Options:
  -h, --help     Show this help
  --no-env       Skip .env regeneration
  --no-cache     Force rebuild without cache
  --clean-tools  Remove test-tools:local image after build (default: keep for faster next build)
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
NO_CACHE=false
CLEAN_TOOLS=false
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
    --no-cache)
      NO_CACHE=true
      shift
      ;;
    --clean-tools)
      CLEAN_TOOLS=true
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
  "${FILE_PATH}/template/script/docker/setup.sh" --base-path "${FILE_PATH}" --lang "${_LANG}"
fi

# Load .env for project name
set -o allexport
# shellcheck disable=SC1091
source "${FILE_PATH}/.env"
set +o allexport

# Build test-tools image if Dockerfile exists
_tools_dockerfile="${FILE_PATH}/template/dockerfile/Dockerfile.test-tools"
_tools_args=()
[[ "${NO_CACHE}" == true ]] && _tools_args+=(--no-cache)
if [[ -f "${_tools_dockerfile}" ]]; then
  docker build "${_tools_args[@]}" -t test-tools:local -f "${_tools_dockerfile}" "${FILE_PATH}" -q >/dev/null
fi

if [[ "${CLEAN_TOOLS}" == true ]]; then
  _cleanup() { docker rmi test-tools:local 2>/dev/null || true; }
  trap _cleanup EXIT
fi

_compose_args=()
[[ "${NO_CACHE}" == true ]] && _compose_args+=(--no-cache)

docker compose -p "${DOCKER_HUB_USER}-${IMAGE_NAME}" \
  -f "${FILE_PATH}/compose.yaml" \
  --env-file "${FILE_PATH}/.env" \
  build "${_compose_args[@]}" "${TARGET}"
