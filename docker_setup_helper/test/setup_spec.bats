#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"

    # Source setup.sh functions only (main is guarded)
    # shellcheck disable=SC1091
    source /source/src/setup.sh

    create_mock_dir
    TEMP_DIR="$(mktemp -d)"
}

teardown() {
    cleanup_mock_dir
    rm -rf "${TEMP_DIR}"
}

# ════════════════════════════════════════════════════════════════════
# detect_user_info
# ════════════════════════════════════════════════════════════════════

@test "detect_user_info uses USER env when set" {
    local _user _group _uid _gid
    USER="mockuser" detect_user_info _user _group _uid _gid
    assert_equal "${_user}" "mockuser"
}

@test "detect_user_info falls back to id -un when USER unset" {
    local _user _group _uid _gid
    mock_cmd "id" '
case "$1" in
    -un) echo "fallbackuser" ;;
    -u)  echo "1001" ;;
    -gn) echo "fallbackgroup" ;;
    -g)  echo "1001" ;;
esac'
    unset USER
    detect_user_info _user _group _uid _gid
    assert_equal "${_user}" "fallbackuser"
}

@test "detect_user_info sets group uid gid correctly" {
    local _user _group _uid _gid
    mock_cmd "id" '
case "$1" in
    -un) echo "testuser" ;;
    -u)  echo "1234" ;;
    -gn) echo "testgroup" ;;
    -g)  echo "5678" ;;
esac'
    USER="testuser" detect_user_info _user _group _uid _gid
    assert_equal "${_group}" "testgroup"
    assert_equal "${_uid}" "1234"
    assert_equal "${_gid}" "5678"
}

# ════════════════════════════════════════════════════════════════════
# detect_hardware
# ════════════════════════════════════════════════════════════════════

@test "detect_hardware returns uname -m output" {
    local _hw
    mock_cmd "uname" 'echo "aarch64"'
    detect_hardware _hw
    assert_equal "${_hw}" "aarch64"
}

# ════════════════════════════════════════════════════════════════════
# detect_docker_hub_user
# ════════════════════════════════════════════════════════════════════

@test "detect_docker_hub_user uses docker info username when logged in" {
    local _result
    mock_cmd "docker" 'echo " Username: dockerhubuser"'
    detect_docker_hub_user _result
    assert_equal "${_result}" "dockerhubuser"
}

@test "detect_docker_hub_user falls back to USER when docker returns empty" {
    local _result
    mock_cmd "docker" 'echo "no username line here"'
    USER="localuser" detect_docker_hub_user _result
    assert_equal "${_result}" "localuser"
}

@test "detect_docker_hub_user falls back to id -un when USER also unset" {
    local _result
    mock_cmd "docker" 'echo "no username line here"'
    mock_cmd "id" '
case "$1" in
    -un) echo "iduser" ;;
esac'
    unset USER
    detect_docker_hub_user _result
    assert_equal "${_result}" "iduser"
}

# ════════════════════════════════════════════════════════════════════
# detect_gpu
# ════════════════════════════════════════════════════════════════════

@test "detect_gpu returns true when nvidia-container-toolkit is installed" {
    local _result
    mock_cmd "dpkg-query" 'echo "ii"'
    detect_gpu _result
    assert_equal "${_result}" "true"
}

@test "detect_gpu returns false when nvidia-container-toolkit is not installed" {
    local _result
    mock_cmd "dpkg-query" 'echo "un"'
    detect_gpu _result
    assert_equal "${_result}" "false"
}

# ════════════════════════════════════════════════════════════════════
# detect_image_name
# ════════════════════════════════════════════════════════════════════

@test "detect_image_name strips docker_ prefix" {
    local _result
    detect_image_name _result "/home/user/projects/docker_myapp"
    assert_equal "${_result}" "myapp"
}

@test "detect_image_name strips _ws suffix" {
    local _result
    detect_image_name _result "/home/user/projects/myapp_ws"
    assert_equal "${_result}" "myapp"
}

@test "detect_image_name uses plain directory name" {
    local _result
    detect_image_name _result "/home/user/projects/ros_noetic"
    assert_equal "${_result}" "ros_noetic"
}

@test "detect_image_name lowercases the result" {
    local _result
    detect_image_name _result "/home/user/MyProject"
    assert_equal "${_result}" "myproject"
}

@test "detect_image_name skips empty parts from absolute path" {
    local _result
    detect_image_name _result "/docker_project"
    assert_equal "${_result}" "project"
}

# ════════════════════════════════════════════════════════════════════
# detect_ws_path
# ════════════════════════════════════════════════════════════════════

@test "detect_ws_path strategy 1: docker_* finds sibling *_ws" {
    local _ws_dir="${TEMP_DIR}/myapp_ws"
    local _proj_dir="${TEMP_DIR}/docker_myapp"
    mkdir -p "${_ws_dir}" "${_proj_dir}"
    local _result
    detect_ws_path _result "${_proj_dir}"
    assert_equal "${_result}" "${_ws_dir}"
}

@test "detect_ws_path strategy 1: docker_* without sibling falls through" {
    local _proj_dir="${TEMP_DIR}/docker_nosibling"
    mkdir -p "${_proj_dir}"
    local _result
    detect_ws_path _result "${_proj_dir}"
    # No sibling *_ws, no *_ws in path → falls back to parent
    assert_equal "${_result}" "${TEMP_DIR}"
}

@test "detect_ws_path strategy 2: finds _ws component in path" {
    local _ws_dir="${TEMP_DIR}/myproject_ws"
    local _sub_dir="${_ws_dir}/docker_ros"
    mkdir -p "${_sub_dir}"
    local _result
    detect_ws_path _result "${_sub_dir}"
    assert_equal "${_result}" "${_ws_dir}"
}

@test "detect_ws_path strategy 3: falls back to parent directory" {
    local _no_ws="${TEMP_DIR}/no_ws_here"
    mkdir -p "${_no_ws}"
    local _result
    detect_ws_path _result "${_no_ws}"
    assert_equal "${_result}" "${TEMP_DIR}"
}

# ════════════════════════════════════════════════════════════════════
# write_env
# ════════════════════════════════════════════════════════════════════

@test "write_env creates .env with all required variables" {
    local _env_file="${TEMP_DIR}/.env"
    write_env "${_env_file}" \
        "testuser" "testgroup" "1001" "1001" \
        "x86_64" "dockerhub" "false" \
        "ros_noetic" "/workspace"

    assert [ -f "${_env_file}" ]
    run grep "USER_NAME=testuser"        "${_env_file}"; assert_success
    run grep "USER_GROUP=testgroup"      "${_env_file}"; assert_success
    run grep "USER_UID=1001"             "${_env_file}"; assert_success
    run grep "USER_GID=1001"             "${_env_file}"; assert_success
    run grep "HARDWARE=x86_64"           "${_env_file}"; assert_success
    run grep "DOCKER_HUB_USER=dockerhub" "${_env_file}"; assert_success
    run grep "GPU_ENABLED=false"         "${_env_file}"; assert_success
    run grep "IMAGE_NAME=ros_noetic"     "${_env_file}"; assert_success
    run grep "WS_PATH=/workspace"        "${_env_file}"; assert_success
}

# ════════════════════════════════════════════════════════════════════
# main
# ════════════════════════════════════════════════════════════════════

@test "main creates .env when it does not exist" {
    local _ws="${TEMP_DIR}/test_ws"
    mkdir -p "${_ws}"
    run bash -c "
        source /source/src/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_ws}'; }
        main --base-path '${TEMP_DIR}'
    "
    assert_success
    assert [ -f "${TEMP_DIR}/.env" ]
}

@test "main sources existing .env and reuses valid WS_PATH" {
    local _ws="${TEMP_DIR}/existing_ws"
    mkdir -p "${_ws}"
    cat > "${TEMP_DIR}/.env" << EOF
WS_PATH=${_ws}
EOF
    run bash -c "
        source /source/src/setup.sh
        main --base-path '${TEMP_DIR}'
    "
    assert_success
    run grep "WS_PATH=${_ws}" "${TEMP_DIR}/.env"
    assert_success
}

@test "main re-detects WS_PATH when path in .env no longer exists" {
    local _new_ws="${TEMP_DIR}/new_ws"
    mkdir -p "${_new_ws}"
    cat > "${TEMP_DIR}/.env" << EOF
WS_PATH=/this/path/does/not/exist
EOF
    run bash -c "
        source /source/src/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_new_ws}'; }
        main --base-path '${TEMP_DIR}'
    "
    assert_success
    run grep "WS_PATH=${_new_ws}" "${TEMP_DIR}/.env"
    assert_success
}

@test "main uses BASH_SOURCE fallback when --base-path not given" {
    local _ws="${TEMP_DIR}/test_ws"
    mkdir -p "${_ws}"
    detect_ws_path() { local -n _o=$1; _o="${_ws}"; }
    run main
    assert_success
}

@test "main returns error on unknown argument" {
    run bash -c "source /source/src/setup.sh; main --invalid-arg"
    assert_failure
}

@test "main returns error when --base-path value is missing" {
    run bash -c "source /source/src/setup.sh; main --base-path"
    assert_failure
}

# ════════════════════════════════════════════════════════════════════
# _msg (i18n)
# ════════════════════════════════════════════════════════════════════

@test "_msg returns English messages by default" {
    _LANG="en"
    assert_equal "$(_msg env_done)"     ".env updated"
    assert_equal "$(_msg env_comment)"  "Auto-detected fields, do not edit manually. Edit WS_PATH if needed"
    assert_equal "$(_msg unknown_arg)"  "Unknown argument"
}

@test "_msg returns Chinese messages when _LANG=zh" {
    _LANG="zh"
    assert_equal "$(_msg env_done)"     ".env 更新完成"
    assert_equal "$(_msg env_comment)"  "自動偵測欄位請勿手動修改，如需變更 WS_PATH 可直接編輯此檔案"
    assert_equal "$(_msg unknown_arg)"  "未知參數"
}

# ════════════════════════════════════════════════════════════════════
# main --lang
# ════════════════════════════════════════════════════════════════════

@test "main --lang zh sets Chinese messages" {
    local _ws="${TEMP_DIR}/test_ws"
    mkdir -p "${_ws}"
    run bash -c "
        source /source/src/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_ws}'; }
        main --base-path '${TEMP_DIR}' --lang zh
    "
    assert_success
    assert_output --partial ".env 更新完成"
}

@test "main --lang requires a value" {
    run bash -c "source /source/src/setup.sh; main --lang"
    assert_failure
}
