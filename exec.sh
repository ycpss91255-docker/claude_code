#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
    cat >&2 <<'EOF'
Usage: ./exec.sh [-h] [-t TARGET] [CMD...]

Options:
  -h, --help       Show this help
  -t, --target T   Service name (default: devel)

Arguments:
  CMD              Command to execute (default: bash)

Examples:
  ./exec.sh                        # Enter devel container with bash
  ./exec.sh htop                   # Run htop in devel container
  ./exec.sh ls -la /home           # Run ls in devel container
  ./exec.sh -t devel-gpu bash      # Enter GPU container
EOF
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

docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    exec "${TARGET}" ${CMD}
