#!/usr/bin/env bash
#
# _lib.sh - Shared helpers for build.sh / run.sh / exec.sh / stop.sh.
#
# Sourced (not executed). Provides:
#   _LANG                            : detected message language
#   _load_env <env_file>             : source .env into the environment
#   _compute_project_name <instance> : set INSTANCE_SUFFIX and PROJECT_NAME
#   _compose                         : `docker compose` wrapper honoring DRY_RUN
#
# Style: Google Shell Style Guide.

# Guard against double-sourcing.
if [[ -n "${_DOCKER_LIB_SOURCED:-}" ]]; then
  return 0
fi
_DOCKER_LIB_SOURCED=1

# _detect_lang prints the language code derived from $LANG.
_detect_lang() {
  case "${LANG:-}" in
    zh_TW*) echo "zh" ;;
    zh_CN*|zh_SG*) echo "zh-CN" ;;
    ja*) echo "ja" ;;
    *) echo "en" ;;
  esac
}

# Load i18n.sh if present, otherwise fall back to a minimal _LANG.
_lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -f "${_lib_dir}/i18n.sh" ]]; then
  # shellcheck disable=SC1091
  source "${_lib_dir}/i18n.sh"
else
  _LANG="${SETUP_LANG:-$(_detect_lang)}"
fi
unset _lib_dir

# _load_env sources the given .env file with allexport so every assignment
# becomes an exported variable visible to docker compose.
#
# Args:
#   $1: absolute path to .env file
_load_env() {
  local env_file="${1:?_load_env requires an env file path}"
  set -o allexport
  # shellcheck disable=SC1090
  source "${env_file}"
  set +o allexport
}

# _compute_project_name derives INSTANCE_SUFFIX and PROJECT_NAME for the
# current invocation, and exports INSTANCE_SUFFIX so compose.yaml can resolve
# ${INSTANCE_SUFFIX:-} when computing container_name.
#
# Args:
#   $1: instance name (may be empty for the default instance)
#
# Requires:
#   DOCKER_HUB_USER, IMAGE_NAME already in the environment (from .env).
#
# Sets (and exports INSTANCE_SUFFIX):
#   INSTANCE_SUFFIX  e.g. "-foo" or ""
#   PROJECT_NAME     e.g. "alice-myrepo-foo"
_compute_project_name() {
  local instance="${1:-}"
  if [[ -n "${instance}" ]]; then
    INSTANCE_SUFFIX="-${instance}"
  else
    INSTANCE_SUFFIX=""
  fi
  export INSTANCE_SUFFIX
  # shellcheck disable=SC2034  # PROJECT_NAME is consumed by callers, not _lib.sh
  PROJECT_NAME="${DOCKER_HUB_USER}-${IMAGE_NAME}${INSTANCE_SUFFIX}"
}

# _compose runs `docker compose` with the given args, or prints what it would
# run if DRY_RUN=true. Use this instead of calling docker compose directly so
# every script honors --dry-run uniformly.
_compose() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    printf '[dry-run] docker compose'
    printf ' %q' "$@"
    printf '\n'
  else
    docker compose "$@"
  fi
}

# _compose_project runs `_compose` with -p / -f / --env-file pre-filled, so
# callers only need to pass the verb and its args.
#
# Requires:
#   PROJECT_NAME : set by _compute_project_name
#   FILE_PATH    : the repo root (where compose.yaml and .env live)
_compose_project() {
  _compose -p "${PROJECT_NAME}" \
    -f "${FILE_PATH}/compose.yaml" \
    --env-file "${FILE_PATH}/.env" \
    "$@"
}
