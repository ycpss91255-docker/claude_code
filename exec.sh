#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    cat <<'EOF'
Usage: ./exec.sh [-h] [TARGET] [CMD...]

Arguments:
  TARGET   Service name (default: devel)
  CMD      Command to execute (default: bash)

Examples:
  ./exec.sh                  # Enter devel container with bash
  ./exec.sh devel-gpu        # Enter GPU container
  ./exec.sh devel htop       # Run htop in devel container
EOF
    exit 0
fi

TARGET="${1:-devel}"
shift 2>/dev/null || true
CMD="${*:-bash}"

docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    exec "${TARGET}" ${CMD}
