#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
}

# ════════════════════════════════════════════════════════════════════
# Structure: required files exist
# ════════════════════════════════════════════════════════════════════

@test "build.sh exists and is executable" {
    assert [ -f /source/build.sh ]
    assert [ -x /source/build.sh ]
}

@test "run.sh exists and is executable" {
    assert [ -f /source/run.sh ]
    assert [ -x /source/run.sh ]
}

@test "exec.sh exists and is executable" {
    assert [ -f /source/exec.sh ]
    assert [ -x /source/exec.sh ]
}

@test "stop.sh exists and is executable" {
    assert [ -f /source/stop.sh ]
    assert [ -x /source/stop.sh ]
}

@test "setup.sh exists and is executable" {
    assert [ -f /source/setup.sh ]
    assert [ -x /source/setup.sh ]
}

# ════════════════════════════════════════════════════════════════════
# Structure: smoke_test files exist
# ════════════════════════════════════════════════════════════════════

@test "smoke_test/test_helper.bash exists" {
    assert [ -f /source/smoke_test/test_helper.bash ]
}

@test "smoke_test/script_help.bats exists" {
    assert [ -f /source/smoke_test/script_help.bats ]
}

@test "smoke_test/display_env.bats exists" {
    assert [ -f /source/smoke_test/display_env.bats ]
}

# ════════════════════════════════════════════════════════════════════
# Path reference: scripts call docker_template/setup.sh
# ════════════════════════════════════════════════════════════════════

@test "build.sh references docker_template/setup.sh" {
    run grep "docker_template/setup.sh" /source/build.sh
    assert_success
}

@test "run.sh references docker_template/setup.sh" {
    run grep "docker_template/setup.sh" /source/run.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Shell conventions: set -euo pipefail
# ════════════════════════════════════════════════════════════════════

@test "build.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/build.sh
    assert_success
}

@test "run.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/run.sh
    assert_success
}

@test "exec.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/exec.sh
    assert_success
}

@test "stop.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/stop.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# run.sh: XDG_SESSION_TYPE branching
# ════════════════════════════════════════════════════════════════════

@test "run.sh contains XDG_SESSION_TYPE check" {
    run grep "XDG_SESSION_TYPE" /source/run.sh
    assert_success
}

@test "run.sh contains xhost +SI:localuser for wayland" {
    run grep 'xhost "+SI:localuser' /source/run.sh
    assert_success
}

@test "run.sh contains xhost +local: for X11" {
    run grep 'xhost +local:' /source/run.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# setup.sh: default _base_path goes up 1 level (not 2)
# ════════════════════════════════════════════════════════════════════

@test "setup.sh default _base_path uses /.." {
    # In docker_template, setup.sh is at docker_template/setup.sh
    # So it should go up 1 level (/..) to reach repo root
    run grep -E '\.\./\.\.' /source/setup.sh
    assert_failure  # Should NOT have ../../ (that was old docker_setup_helper/src/ pattern)
}

@test "setup.sh default _base_path uses single parent traversal" {
    run grep -E 'dirname.*BASH_SOURCE.*\.\.' /source/setup.sh
    assert_success
}
