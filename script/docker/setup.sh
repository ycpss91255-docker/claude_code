#!/usr/bin/env bash
# setup.sh - Auto-detect system parameters and generate .env before build
#
# Features:
#   - User info detection (UID/GID/USER/GROUP)
#   - Hardware architecture detection
#   - Docker Hub username detection
#   - GPU support detection
#   - Image name detection via image_name.conf rule engine
#   - Workspace path detection (sibling scan → path traversal → parent directory fallback)
#   - APT mirror configuration
#   - .env generation
#
# Usage: setup.sh [--base-path <path>] [--lang zh|zh-CN|ja]

# ── i18n messages ──────────────────────────────────────────────
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/i18n.sh"

_msg() {
  local _key="${1}"
  case "${_LANG}" in
    zh)
      case "${_key}" in
        env_done)      echo ".env 更新完成" ;;
        env_comment)   echo "自動偵測欄位請勿手動修改，如需變更 WS_PATH 可直接編輯此檔案" ;;
        unknown_arg)   echo "未知參數" ;;
      esac ;;
    zh-CN)
      case "${_key}" in
        env_done)      echo ".env 更新完成" ;;
        env_comment)   echo "自动检测字段请勿手动修改，如需变更 WS_PATH 可直接编辑此文件" ;;
        unknown_arg)   echo "未知参数" ;;
      esac ;;
    ja)
      case "${_key}" in
        env_done)      echo ".env 更新完了" ;;
        env_comment)   echo "自動検出フィールドは手動で編集しないでください。WS_PATH の変更はこのファイルを直接編集してください" ;;
        unknown_arg)   echo "不明な引数" ;;
      esac ;;
    *)
      case "${_key}" in
        env_done)      echo ".env updated" ;;
        env_comment)   echo "Auto-detected fields, do not edit manually. Edit WS_PATH if needed" ;;
        unknown_arg)   echo "Unknown argument" ;;
      esac ;;
  esac
}

# Only set strict mode when running directly; when sourced, respect caller's settings
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
fi

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
# Rule applicators (used by detect_image_name)
#
# Each takes the path and rule value, echoes the matched name or nothing.
# ════════════════════════════════════════════════════════════════════

_rule_prefix() {
  local _path="$1" _value="$2"
  local -a _parts=()
  IFS='/' read -ra _parts <<< "${_path}"
  local i _part _last=""
  for (( i=${#_parts[@]}-1; i>=0; i-- )); do
    _part="${_parts[i]}"
    [[ -z "${_part}" ]] && continue
    _last="${_part}"
    break
  done
  if [[ "${_last}" == "${_value}"* ]]; then
    echo "${_last#"${_value}"}"
  fi
}

_rule_suffix() {
  local _path="$1" _value="$2"
  local -a _parts=()
  IFS='/' read -ra _parts <<< "${_path}"
  local i _part
  for (( i=${#_parts[@]}-1; i>=0; i-- )); do
    _part="${_parts[i]}"
    [[ -z "${_part}" ]] && continue
    if [[ "${_part}" == *"${_value}" ]]; then
      echo "${_part%"${_value}"}"
      return
    fi
  done
}

_rule_env_example() {
  local _base="${BASE_PATH:-$1}"
  # If $1 is a path, derive base; if BASE_PATH is set, use it
  local _file="${_base}/.env.example"
  if [[ -f "${_file}" ]]; then
    grep -m1 '^IMAGE_NAME=' "${_file}" 2>/dev/null | cut -d= -f2-
  fi
}

_rule_basename() {
  local _path="$1"
  local -a _parts=()
  IFS='/' read -ra _parts <<< "${_path}"
  local i _part
  for (( i=${#_parts[@]}-1; i>=0; i-- )); do
    _part="${_parts[i]}"
    [[ -z "${_part}" ]] && continue
    echo "${_part}"
    return
  done
}

# ════════════════════════════════════════════════════════════════════
# detect_image_name
#
# Reads rules from image_name.conf (per-repo override or template default).
# Rules applied in order; first match wins.
#
# Conf path resolution:
#   1. ${IMAGE_NAME_CONF} env var (test override)
#   2. ${BASE_PATH}/image_name.conf (repo-level override)
#   3. <template>/config/image_name.conf (default)
#
# Usage: detect_image_name <outvar> <path>
# ════════════════════════════════════════════════════════════════════
detect_image_name() {
  local -n _outvar="${1:?"${FUNCNAME[0]}: missing outvar"}"; shift
  local _path="${1:?"${FUNCNAME[0]}: missing path"}"

  # Resolve conf file
  local _conf="${IMAGE_NAME_CONF:-}"
  if [[ -z "${_conf}" ]]; then
    local _base="${BASE_PATH:-${_path}}"
    if [[ -f "${_base}/image_name.conf" ]]; then
      _conf="${_base}/image_name.conf"
    else
      # Default: template/config/image_name.conf
      local _self_dir
      _self_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
      _conf="${_self_dir}/../../config/image_name.conf"
    fi
  fi

  local _found=""
  if [[ -f "${_conf}" ]]; then
    local _line _type _value
    while IFS= read -r _line || [[ -n "${_line}" ]]; do
      # Skip comments and empty lines
      [[ -z "${_line}" || "${_line}" =~ ^[[:space:]]*# ]] && continue
      # Trim whitespace
      _line="${_line#"${_line%%[![:space:]]*}"}"
      _line="${_line%"${_line##*[![:space:]]}"}"
      [[ -z "${_line}" ]] && continue

      if [[ "${_line}" == prefix:* ]]; then
        _value="${_line#prefix:}"
        _found="$(_rule_prefix "${_path}" "${_value}")"
      elif [[ "${_line}" == suffix:* ]]; then
        _value="${_line#suffix:}"
        _found="$(_rule_suffix "${_path}" "${_value}")"
      elif [[ "${_line}" == "@env_example" ]]; then
        _found="$(BASE_PATH="${BASE_PATH:-${_path}}" _rule_env_example "${_path}")"
      elif [[ "${_line}" == "@basename" ]]; then
        _found="$(_rule_basename "${_path}")"
      elif [[ "${_line}" == @default:* ]]; then
        _found="${_line#@default:}"
        printf "[setup] INFO: IMAGE_NAME using @default:%s\n" "${_found}" >&2
      fi

      [[ -n "${_found}" ]] && break
    done < "${_conf}"
  fi

  if [[ -z "${_found}" ]]; then
    printf "[setup] WARNING: IMAGE_NAME could not be detected. Using 'unknown'.\n" >&2
    _found="unknown"
  fi
  _outvar="${_found,,}"
}

# ════════════════════════════════════════════════════════════════════
# detect_ws_path
#
# Workspace detection strategy (in order):
#   1. If current directory is docker_*, use sibling *_ws (strip prefix)
#   2. Traverse path upward looking for a *_ws component
#   3. Fall back to parent directory
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
  local _ws_path="${1}"; shift
  local _apt_mirror_ubuntu="${1}"; shift
  local _apt_mirror_debian="${1}"

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

# ── APT Mirror ───────────────────────────────
APT_MIRROR_UBUNTU=${_apt_mirror_ubuntu}
APT_MIRROR_DEBIAN=${_apt_mirror_debian}
EOF
}

# ════════════════════════════════════════════════════════════════════
# main
#
# Usage: main [--base-path <path>] [--lang <en|zh|zh-CN|ja>]
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
        _LANG="${2:?"--lang requires a value (en|zh|zh-CN|ja)"}"
        shift 2
        ;;
      *)
        printf "[setup] %s: %s\n" "$(_msg unknown_arg)" "$1" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "${_base_path}" ]]; then
    # setup.sh is at template/script/docker/setup.sh, repo root is ../../../
    _base_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../../.." && pwd -P)"
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
  local apt_mirror_ubuntu="${APT_MIRROR_UBUNTU:-tw.archive.ubuntu.com}"
  local apt_mirror_debian="${APT_MIRROR_DEBIAN:-mirror.twds.com.tw}"

  detect_user_info       user_name user_group user_uid user_gid
  detect_hardware        hardware
  detect_docker_hub_user docker_hub_user
  detect_gpu             gpu_enabled
  BASE_PATH="${_base_path}" detect_image_name image_name "${_base_path}"

  if [[ -z "${ws_path}" ]] || [[ ! -d "${ws_path}" ]]; then
    detect_ws_path ws_path "${_base_path}"
  fi
  ws_path="$(cd "${ws_path}" && pwd -P)"

  write_env "${_env_file}" \
    "${user_name}" "${user_group}" "${user_uid}" "${user_gid}" \
    "${hardware}" "${docker_hub_user}" "${gpu_enabled}" \
    "${image_name}" "${ws_path}" \
    "${apt_mirror_ubuntu}" "${apt_mirror_debian}"

  printf "[setup] %s\n" "$(_msg env_done)"
  printf "[setup] USER=%s (%s:%s)  GPU=%s  IMAGE=%s  WS=%s\n" \
    "${user_name}" "${user_uid}" "${user_gid}" \
    "${gpu_enabled}" "${image_name}" "${ws_path}"
}

# Guard: only run main when executed directly, not when sourced (for testing)
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  main "$@"
fi
