#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Load .env for IMAGE_NAME
set -o allexport
# shellcheck disable=SC1091
source "${FILE_PATH}/.env"
set +o allexport

docker exec -it "${IMAGE_NAME}" "${@:-bash}"
