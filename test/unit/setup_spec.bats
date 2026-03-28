#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"

    # Source setup.sh functions only (main is guarded)
    # shellcheck disable=SC1091
    source /source/setup.sh

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

@test "detect_image_name finds *_ws in path" {
    local _result
    detect_image_name _result "/home/user/myapp_ws/src/docker"
    assert_equal "${_result}" "myapp"
}

@test "detect_image_name finds *_ws at end of path" {
    local _result
    detect_image_name _result "/home/user/projects/myapp_ws"
    assert_equal "${_result}" "myapp"
}

@test "detect_image_name prefers docker_* over *_ws in path" {
    local _result
    detect_image_name _result "/home/user/robot_ws/src/docker_nav"
    assert_equal "${_result}" "nav"
}

@test "detect_image_name strips docker_ prefix from last dir" {
    local _result
    detect_image_name _result "/home/user/projects/docker_myapp"
    assert_equal "${_result}" "myapp"
}

@test "detect_image_name strips docker_ from absolute root" {
    local _result
    detect_image_name _result "/docker_project"
    assert_equal "${_result}" "project"
}

@test "detect_image_name returns unknown for plain directory" {
    local _result
    detect_image_name _result "/home/user/projects/ros_noetic"
    assert_equal "${_result}" "unknown"
}

@test "detect_image_name returns unknown for generic path" {
    local _result
    detect_image_name _result "/home/user/MyProject"
    assert_equal "${_result}" "unknown"
}

@test "detect_image_name lowercases the result" {
    local _result
    detect_image_name _result "/home/user/MyApp_ws/src/docker"
    assert_equal "${_result}" "myapp"
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
        source /source/setup.sh
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
        source /source/setup.sh
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
        source /source/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_new_ws}'; }
        main --base-path '${TEMP_DIR}'
    "
    assert_success
    run grep "WS_PATH=${_new_ws}" "${TEMP_DIR}/.env"
    assert_success
}

@test "main reads IMAGE_NAME from .env.example when detection returns unknown" {
    local _ws="${TEMP_DIR}/test_ws"
    local _proj="${TEMP_DIR}/my_generic_project"
    mkdir -p "${_ws}" "${_proj}"

    # Create .env.example with IMAGE_NAME
    echo "IMAGE_NAME=my_custom_image" > "${_proj}/.env.example"

    run bash -c "
        source /source/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_ws}'; }
        main --base-path '${_proj}'
    "
    assert_success
    run grep 'IMAGE_NAME=my_custom_image' "${_proj}/.env"
    assert_success
}

@test "main uses BASH_SOURCE fallback when --base-path not given" {
    local _ws="${TEMP_DIR}/test_ws"
    mkdir -p "${_ws}"
    detect_ws_path() { local -n _o=$1; _o="${_ws}"; }
    run main
    assert_success
}

@test "default _base_path resolves to repo root, not script dir" {
    # Regression: setup.sh lives at docker_template/setup.sh
    # Default _base_path must go up 1 level to repo root
    local _repo_root="${TEMP_DIR}/docker_myapp"
    mkdir -p "${_repo_root}/docker_template"
    cp /source/setup.sh "${_repo_root}/docker_template/setup.sh"

    # Create .env.example as fallback for IMAGE_NAME
    echo "IMAGE_NAME=myapp" > "${_repo_root}/.env.example"

    # Create a dummy ws for detect_ws_path
    local _ws="${TEMP_DIR}/myapp_ws"
    mkdir -p "${_ws}"

    # Run setup.sh directly (no --base-path), simulating user calling it
    run bash -c "cd '${_repo_root}' && bash docker_template/setup.sh"
    assert_success

    # .env should be at repo root, not in docker_template/
    assert [ -f "${_repo_root}/.env" ]
    assert [ ! -f "${_repo_root}/docker_template/.env" ]

    # IMAGE_NAME should derive from repo root dir (docker_myapp → myapp)
    run grep "IMAGE_NAME=myapp" "${_repo_root}/.env"
    assert_success
}

@test "main returns error on unknown argument" {
    run bash -c "source /source/setup.sh; main --invalid-arg"
    assert_failure
}

@test "main returns error when --base-path value is missing" {
    run bash -c "source /source/setup.sh; main --base-path"
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

@test "_msg returns Simplified Chinese messages when _LANG=zh-CN" {
    _LANG="zh-CN"
    assert_equal "$(_msg env_done)"     ".env 更新完成"
    assert_equal "$(_msg env_comment)"  "自动检测字段请勿手动修改，如需变更 WS_PATH 可直接编辑此文件"
    assert_equal "$(_msg unknown_arg)"  "未知参数"
}

@test "_msg returns Japanese messages when _LANG=ja" {
    _LANG="ja"
    assert_equal "$(_msg env_done)"     ".env 更新完了"
    assert_equal "$(_msg env_comment)"  "自動検出フィールドは手動で編集しないでください。WS_PATH の変更はこのファイルを直接編集してください"
    assert_equal "$(_msg unknown_arg)"  "不明な引数"
}

# ════════════════════════════════════════════════════════════════════
# _detect_lang
# ════════════════════════════════════════════════════════════════════

@test "_detect_lang returns zh for zh_TW.UTF-8" {
    LANG="zh_TW.UTF-8"
    assert_equal "$(_detect_lang)" "zh"
}

@test "_detect_lang returns zh-CN for zh_CN.UTF-8" {
    LANG="zh_CN.UTF-8"
    assert_equal "$(_detect_lang)" "zh-CN"
}

@test "_detect_lang returns ja for ja_JP.UTF-8" {
    LANG="ja_JP.UTF-8"
    assert_equal "$(_detect_lang)" "ja"
}

@test "_detect_lang returns en for en_US.UTF-8" {
    LANG="en_US.UTF-8"
    assert_equal "$(_detect_lang)" "en"
}

@test "_detect_lang returns en when LANG is unset" {
    unset LANG
    assert_equal "$(_detect_lang)" "en"
}

@test "_detect_lang is overridden by SETUP_LANG" {
    LANG="ja_JP.UTF-8"
    SETUP_LANG="zh"
    # Re-evaluate _LANG as setup.sh would
    _LANG="${SETUP_LANG:-$(_detect_lang)}"
    assert_equal "${_LANG}" "zh"
}

# ════════════════════════════════════════════════════════════════════
# main --lang
# ════════════════════════════════════════════════════════════════════

@test "main --lang zh sets Chinese messages" {
    local _ws="${TEMP_DIR}/test_ws"
    mkdir -p "${_ws}"
    run bash -c "
        source /source/setup.sh
        detect_ws_path() { local -n _o=\$1; _o='${_ws}'; }
        main --base-path '${TEMP_DIR}' --lang zh
    "
    assert_success
    assert_output --partial ".env 更新完成"
}

@test "main --lang requires a value" {
    run bash -c "source /source/setup.sh; main --lang"
    assert_failure
}
