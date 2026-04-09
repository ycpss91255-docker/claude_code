#!/usr/bin/env bats
#
# lib_spec.bats - Execution tests for script/docker/_lib.sh helpers.
#
# These tests source _lib.sh in a fresh subshell and call each helper so
# the bash branches actually run (kcov can then attribute coverage).

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
    LIB="/source/script/docker/_lib.sh"
}

# ── _detect_lang / _LANG ────────────────────────────────────────────────────

@test "_lib.sh sets _LANG to 'en' when LANG is unset" {
    run bash -c "unset LANG SETUP_LANG; source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "en"
}

@test "_lib.sh sets _LANG to 'zh' for zh_TW.UTF-8" {
    run bash -c "unset SETUP_LANG; LANG=zh_TW.UTF-8 source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "zh"
}

@test "_lib.sh sets _LANG to 'zh-CN' for zh_CN.UTF-8" {
    run bash -c "unset SETUP_LANG; LANG=zh_CN.UTF-8 source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "zh-CN"
}

@test "_lib.sh sets _LANG to 'zh-CN' for zh_SG (Singapore)" {
    run bash -c "unset SETUP_LANG; LANG=zh_SG.UTF-8 source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "zh-CN"
}

@test "_lib.sh sets _LANG to 'ja' for ja_JP.UTF-8" {
    run bash -c "unset SETUP_LANG; LANG=ja_JP.UTF-8 source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "ja"
}

@test "_lib.sh honors SETUP_LANG override" {
    run bash -c "SETUP_LANG=ja LANG=en_US.UTF-8 source ${LIB}; echo \"\${_LANG}\""
    assert_success
    assert_output "ja"
}

# ── double-source guard ─────────────────────────────────────────────────────

@test "_lib.sh is idempotent when sourced twice" {
    run bash -c "source ${LIB}; source ${LIB}; echo \"\${_DOCKER_LIB_SOURCED}\""
    assert_success
    assert_output "1"
}

# ── _load_env ───────────────────────────────────────────────────────────────

@test "_load_env exports variables from a .env file" {
    local _tmp
    _tmp="$(mktemp)"
    cat > "${_tmp}" <<EOF
FOO=bar
BAZ=qux
EOF
    run bash -c "source ${LIB}; _load_env '${_tmp}'; echo \"\${FOO}-\${BAZ}\""
    assert_success
    assert_output "bar-qux"
    rm -f "${_tmp}"
}

@test "_load_env errors when no path is given" {
    run bash -c "source ${LIB}; _load_env"
    assert_failure
}

# ── _compute_project_name ───────────────────────────────────────────────────

@test "_compute_project_name with empty instance produces clean PROJECT_NAME" {
    run bash -c "
        source ${LIB}
        DOCKER_HUB_USER=alice IMAGE_NAME=myrepo
        _compute_project_name ''
        echo \"\${PROJECT_NAME}|\${INSTANCE_SUFFIX}\"
    "
    assert_success
    assert_output "alice-myrepo|"
}

@test "_compute_project_name with named instance suffixes both" {
    run bash -c "
        source ${LIB}
        DOCKER_HUB_USER=alice IMAGE_NAME=myrepo
        _compute_project_name 'dev2'
        echo \"\${PROJECT_NAME}|\${INSTANCE_SUFFIX}\"
    "
    assert_success
    assert_output "alice-myrepo-dev2|-dev2"
}

@test "_compute_project_name exports INSTANCE_SUFFIX so child processes see it" {
    run bash -c "
        source ${LIB}
        DOCKER_HUB_USER=alice IMAGE_NAME=myrepo
        _compute_project_name 'foo'
        bash -c 'echo \"\${INSTANCE_SUFFIX}\"'
    "
    assert_success
    assert_output "-foo"
}

# ── _compose / _compose_project (DRY_RUN path) ──────────────────────────────

@test "_compose with DRY_RUN=true prints command instead of running" {
    run bash -c "source ${LIB}; DRY_RUN=true _compose ps --all"
    assert_success
    assert_output --partial "[dry-run] docker compose"
    assert_output --partial "ps"
    assert_output --partial "--all"
}

@test "_compose without DRY_RUN tries to invoke docker compose (sanity)" {
    # When DRY_RUN is unset/false, _compose calls real docker compose; on a
    # CI runner without docker the command exits non-zero, but we just want
    # to confirm the false branch executes (kcov coverage).
    run bash -c "source ${LIB}; PATH=/nonexistent _compose version"
    # Either docker compose ran (rc 0) or PATH lookup failed (rc 127);
    # both are fine. We assert the script *attempted* the call by checking
    # we did not see the dry-run prefix in output.
    refute_output --partial "[dry-run]"
}

@test "_compose_project pre-fills -p / -f / --env-file from PROJECT_NAME and FILE_PATH" {
    run bash -c "
        source ${LIB}
        DOCKER_HUB_USER=alice IMAGE_NAME=myrepo
        _compute_project_name ''
        FILE_PATH=/tmp/fakerepo
        DRY_RUN=true _compose_project ps
    "
    assert_success
    assert_output --partial "-p alice-myrepo"
    assert_output --partial "-f /tmp/fakerepo/compose.yaml"
    assert_output --partial "--env-file /tmp/fakerepo/.env"
    assert_output --partial " ps"
}
