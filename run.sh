#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Parse arguments
TARGET="devel"
DATA_DIR_ARG=""
DETACH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--detach)
            DETACH=true
            shift
            ;;
        --data-dir)
            DATA_DIR_ARG="$2"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# Generate .env if not exists
if [[ ! -f "${FILE_PATH}/.env" ]]; then
    "${FILE_PATH}/docker_setup_helper/src/setup.sh" --base-path "${FILE_PATH}"
fi

# Derive BASE_IMAGE from GPU_ENABLED
"${FILE_PATH}/post_setup.sh" "${FILE_PATH}/.env"

# Detect agent_* directory by scanning upward from FILE_PATH
detect_agent_dir() {
    local dir="${FILE_PATH}"
    while [[ "${dir}" != "/" ]]; do
        dir="$(dirname "${dir}")"
        for candidate in "${dir}"/agent_*; do
            if [[ -d "${candidate}" ]]; then
                echo "${candidate}"
                return
            fi
        done
    done
}

# Set DATA_DIR priority: --data-dir > agent_* auto-detect > ./data/
if [[ -n "${DATA_DIR_ARG}" ]]; then
    export DATA_DIR="${DATA_DIR_ARG}"
elif [[ -z "${DATA_DIR:-}" ]]; then
    agent_dir="$(detect_agent_dir)"
    if [[ -n "${agent_dir}" ]]; then
        export DATA_DIR="${agent_dir}"
        echo "Using agent data directory: ${DATA_DIR}"
    else
        export DATA_DIR="${FILE_PATH}/data"
    fi
fi

if [[ "${DETACH}" == true ]]; then
    docker compose -f "${FILE_PATH}/compose.yaml" \
        --env-file "${FILE_PATH}/.env" \
        up -d "${TARGET}"
else
    docker compose -f "${FILE_PATH}/compose.yaml" \
        --env-file "${FILE_PATH}/.env" \
        run --rm "${TARGET}"
fi
