#!/usr/bin/env bash
# run.sh - Run Docker containers (interactive or detached)

set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly FILE_PATH
if [[ -f "${FILE_PATH}/template/script/docker/_lib.sh" ]]; then
  # shellcheck disable=SC1091
  source "${FILE_PATH}/template/script/docker/_lib.sh"
else
  # Fallback for /lint stage. See build.sh for rationale.
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
用法: ./run.sh [-h] [-d|--detach] [--no-env] [--dry-run] [--instance NAME] [--lang <en|zh|zh-CN|ja>] [TARGET]

選項:
  -h, --help        顯示此說明
  -d, --detach      背景執行（docker compose up -d）
  --no-env          跳過 .env 重新產生
  --dry-run         只印出將執行的 docker 指令，不實際執行
  --instance NAME   啟動命名 instance（與預設並行,suffix=-NAME）
  --lang LANG       設定訊息語言（預設: en）

目標:
  devel    開發環境（預設）
  runtime  最小化 runtime
EOF
      ;;
    zh-CN)
      cat >&2 <<'EOF'
用法: ./run.sh [-h] [-d|--detach] [--no-env] [--dry-run] [--instance NAME] [--lang <en|zh|zh-CN|ja>] [TARGET]

选项:
  -h, --help        显示此说明
  -d, --detach      后台运行（docker compose up -d）
  --no-env          跳过 .env 重新生成
  --dry-run         只打印将执行的 docker 命令，不实际执行
  --instance NAME   启动命名 instance（与默认并行,suffix=-NAME）
  --lang LANG       设置消息语言（默认: en）

目标:
  devel    开发环境（默认）
  runtime  最小化 runtime
EOF
      ;;
    ja)
      cat >&2 <<'EOF'
使用法: ./run.sh [-h] [-d|--detach] [--no-env] [--dry-run] [--instance NAME] [--lang <en|zh|zh-CN|ja>] [TARGET]

オプション:
  -h, --help        このヘルプを表示
  -d, --detach      バックグラウンドで実行（docker compose up -d）
  --no-env          .env の再生成をスキップ
  --dry-run         実行される docker コマンドを表示するのみ（実行はしない）
  --instance NAME   名前付き instance を起動（デフォルトと並行、suffix=-NAME）
  --lang LANG       メッセージ言語を設定（デフォルト: en）

ターゲット:
  devel    開発環境（デフォルト）
  runtime  最小化ランタイム
EOF
      ;;
    *)
      cat >&2 <<'EOF'
Usage: ./run.sh [-h] [-d|--detach] [--no-env] [--dry-run] [--instance NAME] [--lang <en|zh|zh-CN|ja>] [TARGET]

Options:
  -h, --help        Show this help
  -d, --detach      Run in background (docker compose up -d)
  --no-env          Skip .env regeneration
  --dry-run         Print the docker commands that would run, but do not execute
  --instance NAME   Start a named parallel instance (suffix=-NAME)
  --lang LANG       Set message language (default: en)

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
DRY_RUN=false
TARGET="devel"
INSTANCE=""

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
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --instance)
      INSTANCE="${2:?"--instance requires a value"}"
      shift 2
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
export DRY_RUN

# Generate / refresh .env
if [[ "${SKIP_ENV}" == false ]]; then
  "${FILE_PATH}/template/script/docker/setup.sh" --base-path "${FILE_PATH}" --lang "${_LANG}"
fi

# Load .env, derive PROJECT_NAME (sets/exports INSTANCE_SUFFIX too).
_load_env "${FILE_PATH}/.env"
_compute_project_name "${INSTANCE}"

# Allow X11 forwarding (X11 or XWayland)
if [[ "${XDG_SESSION_TYPE:-x11}" == "wayland" ]]; then
  xhost "+SI:localuser:${USER_NAME}" >/dev/null 2>&1 || true
else
  xhost +local: >/dev/null 2>&1 || true
fi

# Container name mirrors compose.yaml's `container_name:`.
CONTAINER_NAME="${IMAGE_NAME}${INSTANCE_SUFFIX}"

# Refuse to start if the target container is already running and user did not
# explicitly opt into a parallel instance via --instance.
# (For -d mode, the existing `down` step handles restart, so collision is OK.)
if [[ "${DETACH}" != true && "${TARGET}" == "devel" && "${DRY_RUN}" != true ]]; then
  if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    printf "[run] ERROR: Container '%s' is already running.\n" "${CONTAINER_NAME}" >&2
    printf "[run] Either stop it with './stop.sh%s' or start a parallel instance with './run.sh --instance NAME'.\n" \
      "$([[ -n "${INSTANCE}" ]] && printf ' --instance %s' "${INSTANCE}")" >&2
    exit 1
  fi
fi

# _devel_cleanup tears down the project on shell exit so the container does
# not outlive the foreground `./run.sh` session.
#
# `down -t 0` skips the default 10s SIGTERM grace period: the user already
# exited the interactive bash, so there is nothing to drain gracefully —
# without -t 0 the script appears to hang for ~10s after `exit`.
_devel_cleanup() {
  _compose_project down -t 0 >/dev/null 2>&1 || true
}

if [[ "${DETACH}" == true ]]; then
  _compose_project down 2>/dev/null || true
  _compose_project up -d "${TARGET}"
elif [[ "${TARGET}" == "devel" ]]; then
  # Foreground devel: `up -d` + `exec` so a second terminal can join via
  # `./exec.sh`. Trap auto-`down` on exit to preserve the
  # "exit shell = container gone" semantic of the previous `compose run`.
  trap _devel_cleanup EXIT
  _compose_project up -d "${TARGET}"
  _compose_project exec "${TARGET}" bash
else
  # Other one-shot stages (test, runtime, ...): keep `compose run --rm`.
  _compose_project run --rm "${TARGET}"
fi
