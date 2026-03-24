#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
}

# -------------------- build.sh --------------------

@test "build.sh -h exits 0" {
    run bash /lint/build.sh -h
    assert_success
}

@test "build.sh --help exits 0" {
    run bash /lint/build.sh --help
    assert_success
}

@test "build.sh -h prints usage" {
    run bash /lint/build.sh -h
    assert_line --partial "Usage:"
}

# -------------------- run.sh --------------------

@test "run.sh -h exits 0" {
    run bash /lint/run.sh -h
    assert_success
}

@test "run.sh --help exits 0" {
    run bash /lint/run.sh --help
    assert_success
}

@test "run.sh -h prints usage" {
    run bash /lint/run.sh -h
    assert_line --partial "Usage:"
}

# -------------------- exec.sh --------------------

@test "exec.sh -h exits 0" {
    run bash /lint/exec.sh -h
    assert_success
}

@test "exec.sh --help exits 0" {
    run bash /lint/exec.sh --help
    assert_success
}

@test "exec.sh -h prints usage" {
    run bash /lint/exec.sh -h
    assert_line --partial "Usage:"
}

# -------------------- stop.sh --------------------

@test "stop.sh -h exits 0" {
    run bash /lint/stop.sh -h
    assert_success
}

@test "stop.sh --help exits 0" {
    run bash /lint/stop.sh --help
    assert_success
}

@test "stop.sh -h prints usage" {
    run bash /lint/stop.sh -h
    assert_line --partial "Usage:"
}
