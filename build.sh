#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Generate .env if not exists
if [[ ! -f "${FILE_PATH}/.env" ]]; then
    "${FILE_PATH}/docker_setup_helper/src/setup.sh" --base-path "${FILE_PATH}"
fi

# Derive BASE_IMAGE from GPU_ENABLED
"${FILE_PATH}/post_setup.sh" "${FILE_PATH}/.env"

# Build target: devel (default), devel-cpu, test
TARGET="${1:-devel}"

docker compose -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    build "${TARGET}"
