#!/usr/bin/env bash
set -euo pipefail

# Derive BASE_IMAGE and GPU_VARIANT from GPU_ENABLED in .env
# Called by build.sh and run.sh after docker_setup_helper generates .env

ENV_FILE="${1:-.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Error: ${ENV_FILE} not found."
    exit 1
fi

if grep -q '^BASE_IMAGE=' "${ENV_FILE}"; then
    exit 0
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

if [[ "${GPU_ENABLED}" == "true" ]]; then
    printf '\nBASE_IMAGE=nvidia/cuda:12.3.2-cudnn9-devel-ubuntu22.04\nGPU_VARIANT=true\n' >> "${ENV_FILE}"
else
    printf '\nBASE_IMAGE=node:20-slim\nGPU_VARIANT=false\n' >> "${ENV_FILE}"
fi
