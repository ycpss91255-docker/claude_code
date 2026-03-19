#!/usr/bin/env bash

set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
    cat >&2 <<'EOF'
Usage: ./stop.sh [-h]

Stop and remove all containers for this project.
Equivalent to: docker compose down

Options:
  -h, --help     Show this help
EOF
    exit 0
}

if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    usage
fi

docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    down "$@"
