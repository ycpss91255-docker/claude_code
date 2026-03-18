#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
    cat >&2 <<'EOF'
Usage: ./build.sh [-h] [--no-env] [TARGET]

Options:
  -h, --help   Show this help
  --no-env     Skip .env regeneration

Targets:
  devel      Development environment (default)
  devel-gpu  GPU variant (NVIDIA CUDA)
  test       Run smoke tests
EOF
    exit 0
}

# Parse arguments
TARGET="devel"
SKIP_ENV=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --no-env)
            SKIP_ENV=true
            shift
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# Generate .env
if [[ "${SKIP_ENV}" == false ]]; then
    "${FILE_PATH}/docker_setup_helper/src/setup.sh" --base-path "${FILE_PATH}"
fi

# Derive BASE_IMAGE from GPU_ENABLED
"${FILE_PATH}/post_setup.sh" "${FILE_PATH}/.env"

docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    build "${TARGET}"
