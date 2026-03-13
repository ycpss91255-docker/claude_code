#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
    RC="/source/src/config/shell/bashrc"
}

# ════════════════════════════════════════════════════════════════════
# Function definitions
# ════════════════════════════════════════════════════════════════════

@test "defines alias_func" {
    run grep -q "^function alias_func" "${RC}"
    assert_success
}

@test "defines swc" {
    run grep -q "^function swc" "${RC}"
    assert_success
}

@test "defines color_git_branch" {
    run grep -q "^function color_git_branch" "${RC}"
    assert_success
}

@test "defines ros_complete" {
    run grep -q "^function ros_complete" "${RC}"
    assert_success
}

@test "defines ros_source" {
    run grep -q "^function ros_source" "${RC}"
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Aliases
# ════════════════════════════════════════════════════════════════════

@test "defines ebc alias" {
    run grep -q "alias ebc=" "${RC}"
    assert_success
}

@test "defines sbc alias" {
    run grep -q "alias sbc=" "${RC}"
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Functions are called at the bottom
# ════════════════════════════════════════════════════════════════════

@test "alias_func is called" {
    run grep -q "^alias_func" "${RC}"
    assert_success
}

@test "color_git_branch is called" {
    run grep -q "^color_git_branch" "${RC}"
    assert_success
}

@test "ros_complete is called" {
    run grep -q "^ros_complete" "${RC}"
    assert_success
}

@test "ros_source is called" {
    run grep -q "^ros_source" "${RC}"
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Key content
# ════════════════════════════════════════════════════════════════════

@test "swc searches for catkin devel/setup.bash" {
    run grep -q "devel" "${RC}"
    assert_success
}

@test "ros_source references ROS_DISTRO" {
    run grep -q "ROS_DISTRO" "${RC}"
    assert_success
}

@test "color_git_branch sets PS1" {
    run grep -q "PS1=" "${RC}"
    assert_success
}
