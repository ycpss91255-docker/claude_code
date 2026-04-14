#!/usr/bin/env bash
# exec.sh - Execute commands in a running container

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
用法: ./exec.sh [-h] [-t TARGET] [--instance NAME] [--dry-run] [CMD...]

選項:
  -h, --help        顯示此說明
  -t, --target T    服務名稱（預設: devel）
  --instance NAME   進入命名 instance（預設為 default instance）
  --dry-run         只印出將執行的 docker 指令，不實際執行

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
用法: ./exec.sh [-h] [-t TARGET] [--instance NAME] [--dry-run] [CMD...]

选项:
  -h, --help        显示此说明
  -t, --target T    服务名称（默认: devel）
  --instance NAME   进入命名 instance（默认为 default instance）
  --dry-run         只打印将执行的 docker 命令，不实际执行

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
使用法: ./exec.sh [-h] [-t TARGET] [--instance NAME] [--dry-run] [CMD...]

オプション:
  -h, --help        このヘルプを表示
  -t, --target T    サービス名（デフォルト: devel）
  --instance NAME   名前付き instance に入る（デフォルトは default instance）
  --dry-run         実行される docker コマンドを表示するのみ（実行はしない）

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
Usage: ./exec.sh [-h] [-t TARGET] [--instance NAME] [--dry-run] [CMD...]

Options:
  -h, --help        Show this help
  -t, --target T    Service name (default: devel)
  --instance NAME   Enter a named instance (default: default instance)
  --dry-run         Print the docker commands that would run, but do not execute

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

main() {
  local TARGET="devel"
  local INSTANCE=""
  DRY_RUN=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        ;;
      -t|--target)
        TARGET="${2:?"--target requires a value"}"
        shift 2
        ;;
      --instance)
        INSTANCE="${2:?"--instance requires a value"}"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done
  export DRY_RUN

  # Default to bash when no command is supplied. Using an array preserves
  # arguments containing whitespace, unlike the previous `${CMD}` splitting.
  if [[ $# -eq 0 ]]; then
    set -- bash
  fi

  # Load .env, derive PROJECT_NAME (sets/exports INSTANCE_SUFFIX too).
  _load_env "${FILE_PATH}/.env"
  _compute_project_name "${INSTANCE}"

  # Precheck: refuse with a friendly hint if the target container is not
  # running. Skipped under --dry-run since the user is asking what *would* run.
  local _container_name="${IMAGE_NAME}${INSTANCE_SUFFIX}"
  if [[ "${DRY_RUN}" != true ]] \
      && ! docker ps --format '{{.Names}}' | grep -qx "${_container_name}"; then
    printf "[exec] ERROR: Container '%s' is not running.\n" \
      "${_container_name}" >&2
    if [[ -n "${INSTANCE}" ]]; then
      printf "[exec] Start it first with './run.sh --instance %s'.\n" \
        "${INSTANCE}" >&2
    else
      printf "[exec] Start it first with './run.sh' (or use './run.sh --instance NAME' for a parallel one).\n" >&2
    fi
    exit 1
  fi

  _compose_project exec "${TARGET}" "$@"
}

main "$@"
