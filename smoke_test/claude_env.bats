#!/usr/bin/env bats

setup() { load "${BATS_TEST_DIRNAME}/test_helper"; }

# -------------------- AI tools --------------------
@test "claude command is available"    { run which claude;   assert_success; }
@test "node is available"             { run node --version;  assert_success; }
@test "npm is available"              { run npm --version;   assert_success; }

# -------------------- Dev tools --------------------
@test "git is available"              { run which git;       assert_success; }
@test "python3 is available"          { run which python3;   assert_success; }
@test "make is available"             { run which make;      assert_success; }
@test "cmake is available"            { run which cmake;     assert_success; }
@test "g++ is available"              { run which g++;       assert_success; }
@test "curl is available"             { run which curl;      assert_success; }
@test "wget is available"             { run which wget;      assert_success; }
@test "jq is available"               { run which jq;       assert_success; }
@test "rg (ripgrep) is available"     { run which rg;       assert_success; }
@test "tree is available"             { run which tree;      assert_success; }
@test "docker is available"           { run which docker;    assert_success; }
@test "gpg is available"              { run which gpg;       assert_success; }

# -------------------- System --------------------
@test "user is not root"              { run id -u; assert_success; refute_output "0"; }
@test "user can sudo"                 { run sudo true; assert_success; }
@test "timezone is Asia/Taipei"       { run cat /etc/timezone; assert_success; assert_output "Asia/Taipei"; }
@test "LANG is en_US.UTF-8"          { assert_equal "${LANG}" "en_US.UTF-8"; }
@test "work directory exists"         { assert [ -d "${HOME}/work" ]; }
@test "work directory is writable"    { run bash -c "touch '${HOME}/work/.smoke_test' && rm '${HOME}/work/.smoke_test'"; assert_success; }
@test "entrypoint.sh exists"         { assert [ -f "/entrypoint.sh" ]; }
@test "encrypt_env.sh is in PATH"    { run which encrypt_env.sh; assert_success; }

# -------------------- Excluded tools --------------------
@test "gemini is NOT installed"      { run which gemini;      assert_failure; }
@test "codex is NOT installed"       { run which codex;       assert_failure; }
@test "tmux is NOT installed"         { run which tmux;        assert_failure; }
@test "vim is NOT installed"          { run which vim;         assert_failure; }
@test "fzf is NOT installed"          { run which fzf;         assert_failure; }
@test "terminator is NOT installed"   { run which terminator;  assert_failure; }
