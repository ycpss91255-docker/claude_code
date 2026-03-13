#!/usr/bin/env bash
# setup.sh - Auto-detect system parameters and generate .env before build
#
# Replaces get_param.sh with the following features:
#   - User info detection (UID/GID/USER/GROUP)
#   - Hardware architecture detection
#   - Docker Hub username detection
#   - GPU support detection
#   - Image name inference (compatible with docker_* / *_ws naming conventions)
#   - Workspace path detection (path traversal → sibling scan → interactive prompt)
#   - .env generation
#
# Usage: setup.sh [--base-path <path>] [--lang zh]

# ── i18n messages ──────────────────────────────────────────────
_LANG="${SETUP_LANG:-en}"

_msg() {
    local _key="${1}"
    case "${_LANG}" in
        zh)
            case "${_key}" in
                env_done)      echo ".env 更新完成" ;;
                env_comment)   echo "自動偵測欄位請勿手動修改，如需變更 WS_PATH 可直接編輯此檔案" ;;
                unknown_arg)   echo "未知參數" ;;
            esac ;; # LCOV_EXCL_LINE
        *) # LCOV_EXCL_LINE
            case "${_key}" in
                env_done)      echo ".env updated" ;;
                env_comment)   echo "Auto-detected fields, do not edit manually. Edit WS_PATH if needed" ;;
                unknown_arg)   echo "Unknown argument" ;;
            esac ;; # LCOV_EXCL_LINE
    esac
}

# Only set strict mode when running directly; when sourced, respect caller's settings
# LCOV_EXCL_START
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    set -euo pipefail
fi
# LCOV_EXCL_STOP

# ════════════════════════════════════════════════════════════════════
# detect_user_info
#
# Usage: detect_user_info <user_outvar> <group_outvar> <uid_outvar> <gid_outvar>
# ════════════════════════════════════════════════════════════════════
detect_user_info() {
    local -n __dui_user="${1:?"${FUNCNAME[0]}: missing user outvar"}"; shift
    local -n __dui_group="${1:?"${FUNCNAME[0]}: missing group outvar"}"; shift
    local -n __dui_uid="${1:?"${FUNCNAME[0]}: missing uid outvar"}"; shift
    local -n __dui_gid="${1:?"${FUNCNAME[0]}: missing gid outvar"}"

    __dui_user="${USER:-$(id -un)}"
    __dui_group="$(id -gn)"
    __dui_uid="$(id -u)"
    __dui_gid="$(id -g)"
}

# ════════════════════════════════════════════════════════════════════
# detect_hardware
#
# Usage: detect_hardware <outvar>
# ════════════════════════════════════════════════════════════════════
detect_hardware() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"
    _outvar="$(uname -m)"
}

# ════════════════════════════════════════════════════════════════════
# detect_docker_hub_user
#
# Tries docker info first, falls back to USER, then id -un
#
# Usage: detect_docker_hub_user <outvar>
# ════════════════════════════════════════════════════════════════════
detect_docker_hub_user() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"
    local _name=""
    _name="$(docker info 2>/dev/null | awk '/^[[:space:]]*Username:/{print $2}')" || true
    _outvar="${_name:-${USER:-$(id -un)}}"
}

# ════════════════════════════════════════════════════════════════════
# detect_gpu
#
# Checks nvidia-container-toolkit via dpkg-query
#
# Usage: detect_gpu <outvar>
# outvar: "true" or "false"
# ════════════════════════════════════════════════════════════════════
detect_gpu() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"
    if dpkg-query -W -f='${db:Status-Abbrev}\n' -- "nvidia-container-toolkit" 2>/dev/null \
        | grep -q '^ii'; then
        _outvar=true
    else
        _outvar=false
    fi
}

# ════════════════════════════════════════════════════════════════════
# detect_image_name
#
# Detection priority:
#   1. Scan entire path (right to left) for *_ws → use prefix
#   2. Check last directory only for docker_* → strip prefix
#   3. Fallback to "unknown"
#
# Usage: detect_image_name <outvar> <path>
# ════════════════════════════════════════════════════════════════════
detect_image_name() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"; shift
    local _path="${1:?"${FUNCNAME[0]}: missing path"}"

    local -a _parts=()
    local _found="" _last=""

    IFS='/' read -ra _parts <<< "${_path}"

    # 1. Scan entire path for *_ws (right to left)
    local i _part
    for (( i=${#_parts[@]}-1; i>=0; i-- )); do
        _part="${_parts[i]}"
        [[ -z "${_part}" ]] && continue
        if [[ "${_part}" == *_ws ]]; then
            _found="${_part%_ws}"
            break
        fi
    done

    # 2. Check last directory for docker_* prefix
    if [[ -z "${_found}" ]]; then
        for (( i=${#_parts[@]}-1; i>=0; i-- )); do
            _part="${_parts[i]}"
            [[ -z "${_part}" ]] && continue
            _last="${_part}"
            break
        done
        if [[ "${_last}" == docker_* ]]; then
            _found="${_last#docker_}"
        fi
    fi

    # 3. Fallback
    _outvar="${_found:-unknown}"
    _outvar="${_outvar,,}"
}

# ════════════════════════════════════════════════════════════════════
# detect_ws_path
#
# Workspace detection strategy (in order):
#   1. If current directory is docker_*, use sibling *_ws (strip prefix)
#   2. Traverse path upward looking for a *_ws component
#   3. Fall back to parent directory
#
# Compatible with get_param.sh get_workdir behaviour.
#
# Usage: detect_ws_path <outvar> <base_path>
# ════════════════════════════════════════════════════════════════════
detect_ws_path() {
    local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"; shift
    local _base_path="${1:?"${FUNCNAME[0]}: missing base_path"}"

    local _dirname=""
    _dirname="$(basename "${_base_path}")"

    # Strategy 1: docker_* directory → look for sibling *_ws
    if [[ "${_dirname}" == docker_* ]]; then
        local _name="${_dirname#docker_}"
        local _sibling="${_base_path}/../${_name}_ws"
        if [[ -d "${_sibling}" ]]; then
            _outvar="$(cd "${_sibling}" && pwd -P)"
            return 0
        fi
    fi

    # Strategy 2: traverse path upward looking for *_ws component
    local _check="${_base_path}"
    while [[ "${_check}" != "/" && "${_check}" != "." ]]; do
        if [[ "$(basename "${_check}")" == *_ws && -d "${_check}" ]]; then
            _outvar="$(cd "${_check}" && pwd -P)"
            return 0
        fi
        _check="$(dirname "${_check}")"
    done

    # Strategy 3: fall back to parent directory
    _outvar="$(cd "${_base_path}/.." && pwd -P)"
}

# ════════════════════════════════════════════════════════════════════
# write_env
#
# Usage: write_env <env_file> <user_name> <user_group> <uid> <gid>
#                  <hardware> <docker_hub_user> <gpu_enabled>
#                  <image_name> <ws_path>
# ════════════════════════════════════════════════════════════════════
write_env() {
    local _env_file="${1:?"${FUNCNAME[0]}: missing env_file"}"; shift
    local _user_name="${1}"; shift
    local _user_group="${1}"; shift
    local _uid="${1}"; shift
    local _gid="${1}"; shift
    local _hardware="${1}"; shift
    local _docker_hub_user="${1}"; shift
    local _gpu_enabled="${1}"; shift
    local _image_name="${1}"; shift
    local _ws_path="${1}"

    local _comment=""
    _comment="$(_msg env_comment)"
    cat > "${_env_file}" << EOF
# Auto-generated by setup.sh on $(date '+%Y-%m-%d %H:%M:%S')
# ${_comment}

# ── Auto-detected ────────────────────────────
USER_NAME=${_user_name}
USER_GROUP=${_user_group}
USER_UID=${_uid}
USER_GID=${_gid}
HARDWARE=${_hardware}
DOCKER_HUB_USER=${_docker_hub_user}
GPU_ENABLED=${_gpu_enabled}
IMAGE_NAME=${_image_name}

# ── Workspace ────────────────────────────────
WS_PATH=${_ws_path}
EOF
}

# ════════════════════════════════════════════════════════════════════
# main
#
# Usage: main [--base-path <path>] [--lang <en|zh>]
#   --base-path  override script directory (useful for testing)
#   --lang       set message language (default: en)
# ════════════════════════════════════════════════════════════════════
main() {
    local _base_path=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base-path)
                _base_path="${2:?"--base-path requires a value"}"
                shift 2
                ;;
            --lang)
                _LANG="${2:?"--lang requires a value (en|zh)"}"
                shift 2
                ;;
            *)
                printf "[setup] %s: %s\n" "$(_msg unknown_arg)" "$1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "${_base_path}" ]]; then
        _base_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
    fi

    local _env_file="${_base_path}/.env"

    # Load existing .env to preserve manually-set values (e.g. WS_PATH)
    if [[ -f "${_env_file}" ]]; then
        set -o allexport
        # shellcheck disable=SC1090
        source "${_env_file}"
        set +o allexport
    fi

    local user_name="" user_group="" user_uid="" user_gid=""
    local hardware="" docker_hub_user="" gpu_enabled="" image_name=""
    local ws_path="${WS_PATH:-}"

    detect_user_info       user_name user_group user_uid user_gid
    detect_hardware        hardware
    detect_docker_hub_user docker_hub_user
    detect_gpu             gpu_enabled
    detect_image_name      image_name "${_base_path}"

    # Fallback: read IMAGE_NAME from .env.example if detection returned unknown
    if [[ "${image_name}" == "unknown" ]]; then
        local _env_example="${_base_path}/.env.example"
        if [[ -f "${_env_example}" ]]; then
            local _example_name=""
            _example_name="$(grep -m1 '^IMAGE_NAME=' "${_env_example}" | cut -d= -f2)"
            if [[ -n "${_example_name}" && "${_example_name}" != "unknown" ]]; then
                image_name="${_example_name}"
            fi
        fi
    fi

    if [[ -z "${ws_path}" ]] || [[ ! -d "${ws_path}" ]]; then
        detect_ws_path ws_path "${_base_path}"
    fi
    ws_path="$(cd "${ws_path}" && pwd -P)"

    write_env "${_env_file}" \
        "${user_name}" "${user_group}" "${user_uid}" "${user_gid}" \
        "${hardware}" "${docker_hub_user}" "${gpu_enabled}" \
        "${image_name}" "${ws_path}"

    printf "[setup] %s\n" "$(_msg env_done)"
    printf "[setup] USER=%s (%s:%s)  GPU=%s  IMAGE=%s  WS=%s\n" \
        "${user_name}" "${user_uid}" "${user_gid}" \
        "${gpu_enabled}" "${image_name}" "${ws_path}"
}

# Guard: only run main when executed directly, not when sourced (for testing)
# LCOV_EXCL_START
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
# LCOV_EXCL_STOP
