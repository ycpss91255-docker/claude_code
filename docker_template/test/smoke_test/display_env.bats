#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
}

# -------------------- compose.yaml: Wayland env vars --------------------

@test "compose.yaml contains WAYLAND_DISPLAY env" {
    run grep "WAYLAND_DISPLAY" /lint/compose.yaml
    assert_success
}

@test "compose.yaml contains XDG_RUNTIME_DIR env" {
    run grep "XDG_RUNTIME_DIR" /lint/compose.yaml
    assert_success
}

@test "compose.yaml contains XAUTHORITY env" {
    run grep "XAUTHORITY" /lint/compose.yaml
    assert_success
}

# -------------------- compose.yaml: Wayland volume mounts --------------------

@test "compose.yaml mounts XDG_RUNTIME_DIR volume" {
    run grep -E 'XDG_RUNTIME_DIR.*:.*XDG_RUNTIME_DIR' /lint/compose.yaml
    assert_success
}

@test "compose.yaml mounts XAUTHORITY volume" {
    run grep -E 'XAUTHORITY.*:.*XAUTHORITY' /lint/compose.yaml
    assert_success
}

@test "compose.yaml mounts X11-unix volume" {
    run grep "/tmp/.X11-unix" /lint/compose.yaml
    assert_success
}

# -------------------- run.sh: xhost branching --------------------

@test "run.sh contains XDG_SESSION_TYPE check" {
    run grep "XDG_SESSION_TYPE" /lint/run.sh
    assert_success
}

@test "run.sh calls xhost +SI:localuser on wayland" {
    local mock_dir="${BATS_TEST_TMPDIR}/bin"
    local log="${BATS_TEST_TMPDIR}/xhost.log"
    mkdir -p "${mock_dir}"
    cat > "${mock_dir}/xhost" <<MOCK
#!/bin/bash
echo "\$*" >> "${log}"
MOCK
    chmod +x "${mock_dir}/xhost"

    env PATH="${mock_dir}:${PATH}" \
        XDG_SESSION_TYPE=wayland \
        USER_NAME=testuser \
        bash -c '
            if [[ "${XDG_SESSION_TYPE:-x11}" == "wayland" ]]; then
                xhost "+SI:localuser:${USER_NAME}" >/dev/null 2>&1 || true
            else
                xhost +local: >/dev/null 2>&1 || true
            fi
        '

    run cat "${log}"
    assert_success
    assert_output --partial "+SI:localuser:testuser"
}

@test "run.sh calls xhost +local: on X11" {
    local mock_dir="${BATS_TEST_TMPDIR}/bin"
    local log="${BATS_TEST_TMPDIR}/xhost.log"
    mkdir -p "${mock_dir}"
    cat > "${mock_dir}/xhost" <<MOCK
#!/bin/bash
echo "\$*" >> "${log}"
MOCK
    chmod +x "${mock_dir}/xhost"

    env PATH="${mock_dir}:${PATH}" \
        XDG_SESSION_TYPE=x11 \
        USER_NAME=testuser \
        bash -c '
            if [[ "${XDG_SESSION_TYPE:-x11}" == "wayland" ]]; then
                xhost "+SI:localuser:${USER_NAME}" >/dev/null 2>&1 || true
            else
                xhost +local: >/dev/null 2>&1 || true
            fi
        '

    run cat "${log}"
    assert_success
    assert_output --partial "+local:"
}

@test "run.sh defaults to X11 xhost when XDG_SESSION_TYPE unset" {
    local mock_dir="${BATS_TEST_TMPDIR}/bin"
    local log="${BATS_TEST_TMPDIR}/xhost.log"
    mkdir -p "${mock_dir}"
    cat > "${mock_dir}/xhost" <<MOCK
#!/bin/bash
echo "\$*" >> "${log}"
MOCK
    chmod +x "${mock_dir}/xhost"

    env -u XDG_SESSION_TYPE \
        PATH="${mock_dir}:${PATH}" \
        USER_NAME=testuser \
        bash -c '
            if [[ "${XDG_SESSION_TYPE:-x11}" == "wayland" ]]; then
                xhost "+SI:localuser:${USER_NAME}" >/dev/null 2>&1 || true
            else
                xhost +local: >/dev/null 2>&1 || true
            fi
        '

    run cat "${log}"
    assert_success
    assert_output --partial "+local:"
}
