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
    assert [ -f /source/script/setup.sh ]
    assert [ -x /source/script/setup.sh ]
}

# ════════════════════════════════════════════════════════════════════
# Structure: ci.sh and Makefile exist
# ════════════════════════════════════════════════════════════════════

@test "ci.sh exists and is executable" {
    assert [ -f /source/script/ci.sh ]
    assert [ -x /source/script/ci.sh ]
}

@test "ci.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/ci.sh
    assert_success
}

@test "Makefile exists (repo entry)" {
    assert [ -f /source/Makefile ]
}

@test "Makefile has build target" {
    run grep -E '^build:' /source/Makefile
    assert_success
}

@test "Makefile.ci exists (template CI)" {
    assert [ -f /source/Makefile.ci ]
}

@test "Makefile.ci has test target" {
    run grep -E '^test:' /source/Makefile.ci
    assert_success
}

@test "Makefile.ci has lint target" {
    run grep -E '^lint:' /source/Makefile.ci
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Structure: test directory layout
# ════════════════════════════════════════════════════════════════════

@test "test/smoke/test_helper.bash exists" {
    assert [ -f /source/test/smoke/test_helper.bash ]
}

@test "test/smoke/script_help.bats exists" {
    assert [ -f /source/test/smoke/script_help.bats ]
}

@test "test/smoke/display_env.bats exists" {
    assert [ -f /source/test/smoke/display_env.bats ]
}

@test "test/unit/ directory exists" {
    assert [ -d /source/test/unit ]
}

# ════════════════════════════════════════════════════════════════════
# Structure: doc directory layout
# ════════════════════════════════════════════════════════════════════

@test "doc/readme/ directory exists" {
    assert [ -d /source/doc/readme ]
}

@test "doc/test/ directory exists" {
    assert [ -d /source/doc/test ]
}

@test "doc/changelog/ directory exists" {
    assert [ -d /source/doc/changelog ]
}

# ════════════════════════════════════════════════════════════════════
# Path reference: scripts call template/script/setup.sh
# ════════════════════════════════════════════════════════════════════

@test "build.sh references template/script/setup.sh" {
    run grep "template/script/setup.sh" /source/build.sh
    assert_success
}

@test "run.sh references template/script/setup.sh" {
    run grep "template/script/setup.sh" /source/run.sh
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
# Docker compose project name (-p)
# ════════════════════════════════════════════════════════════════════

@test "build.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/build.sh
    assert_success
}

@test "run.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/run.sh
    assert_success
}

@test "exec.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/exec.sh
    assert_success
}

@test "stop.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/stop.sh
    assert_success
}

@test "exec.sh sources .env" {
    run grep 'source.*\.env' /source/exec.sh
    assert_success
}

@test "stop.sh sources .env" {
    run grep 'source.*\.env' /source/stop.sh
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
    # In template, setup.sh is at template/script/setup.sh
    # So it should go up 1 level (/..) to reach repo root
    run grep -E '\.\./\.\.' /source/script/setup.sh
    assert_success  # Should have ../../ ../../ (that was old docker_setup_helper/src/ pattern)
}

@test "setup.sh default _base_path uses double parent traversal" {
    run grep -E "dirname.*BASH_SOURCE.*\.\..*\.\." /source/script/setup.sh
    assert_success
}
