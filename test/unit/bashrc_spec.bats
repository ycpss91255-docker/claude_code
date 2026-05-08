#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/test_helper"
  RC="/source/config/shell/bashrc"
}

# ════════════════════════════════════════════════════════════════════
# Function definitions
# ════════════════════════════════════════════════════════════════════

@test "defines alias_func" {
  run grep -q "^alias_func()" "${RC}"
  assert_success
}

@test "defines color_git_branch" {
  run grep -q "^color_git_branch()" "${RC}"
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
  run grep -qE "^alias_func[[:space:]]*$" "${RC}"
  assert_success
}

@test "color_git_branch is called" {
  run grep -qE "^color_git_branch[[:space:]]*$" "${RC}"
  assert_success
}

# ════════════════════════════════════════════════════════════════════
# Key content
# ════════════════════════════════════════════════════════════════════

@test "color_git_branch sets PS1" {
  run grep -q "PS1=" "${RC}"
  assert_success
}
