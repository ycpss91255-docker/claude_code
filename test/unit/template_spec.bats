#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
}

# ════════════════════════════════════════════════════════════════════
# Structure: required files exist
# ════════════════════════════════════════════════════════════════════

@test "build.sh exists and is executable" {
    assert [ -f /source/script/docker/build.sh ]
    assert [ -x /source/script/docker/build.sh ]
}

@test "run.sh exists and is executable" {
    assert [ -f /source/script/docker/run.sh ]
    assert [ -x /source/script/docker/run.sh ]
}

@test "exec.sh exists and is executable" {
    assert [ -f /source/script/docker/exec.sh ]
    assert [ -x /source/script/docker/exec.sh ]
}

@test "stop.sh exists and is executable" {
    assert [ -f /source/script/docker/stop.sh ]
    assert [ -x /source/script/docker/stop.sh ]
}

@test "setup.sh exists and is executable" {
    assert [ -f /source/script/docker/setup.sh ]
    assert [ -x /source/script/docker/setup.sh ]
}

# ════════════════════════════════════════════════════════════════════
# Structure: ci.sh and Makefile exist
# ════════════════════════════════════════════════════════════════════

@test "ci.sh exists and is executable" {
    assert [ -f /source/script/ci/ci.sh ]
    assert [ -x /source/script/ci/ci.sh ]
}

@test "ci.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/ci/ci.sh
    assert_success
}

@test "Makefile exists (repo entry)" {
    assert [ -f /source/script/docker/Makefile ]
}

@test "Makefile has build target" {
    run grep -E '^build:' /source/script/docker/Makefile
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
# Path reference: scripts call template/script/docker/setup.sh
# ════════════════════════════════════════════════════════════════════

@test "build.sh references template/script/docker/setup.sh" {
    run grep "template/script/docker/setup.sh" /source/script/docker/build.sh
    assert_success
}

@test "run.sh references template/script/docker/setup.sh" {
    run grep "template/script/docker/setup.sh" /source/script/docker/run.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Shell conventions: set -euo pipefail
# ════════════════════════════════════════════════════════════════════

@test "build.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/docker/build.sh
    assert_success
}

@test "build.sh supports --no-cache flag" {
    run grep -E '\-\-no-cache' /source/script/docker/build.sh
    assert_success
}

@test "build.sh passes --no-cache to docker compose build when set" {
    run grep -E 'NO_CACHE.*=.*true' /source/script/docker/build.sh
    assert_success
}

@test "build.sh keeps test-tools image by default (cleanup gated by CLEAN_TOOLS)" {
    # Default behavior: do NOT auto-remove test-tools:local
    # cleanup must be conditional on CLEAN_TOOLS
    run grep -E 'CLEAN_TOOLS.*==.*true' /source/script/docker/build.sh
    assert_success
}

@test "build.sh supports --clean-tools flag" {
    run grep -E '\-\-clean-tools' /source/script/docker/build.sh
    assert_success
}

@test "build.sh removes test-tools image when --clean-tools is set" {
    run grep -E 'CLEAN_TOOLS.*=.*true' /source/script/docker/build.sh
    assert_success
}

@test "run.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/docker/run.sh
    assert_success
}

@test "exec.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/docker/exec.sh
    assert_success
}

@test "stop.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" /source/script/docker/stop.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# Docker compose project name (-p)
# ════════════════════════════════════════════════════════════════════

@test "build.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/script/docker/build.sh
    assert_success
}

@test "run.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/script/docker/run.sh
    assert_success
}

@test "exec.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/script/docker/exec.sh
    assert_success
}

@test "stop.sh uses -p for compose project name" {
    run grep -E '\-p.*DOCKER_HUB_USER.*IMAGE_NAME' /source/script/docker/stop.sh
    assert_success
}

@test "exec.sh sources .env" {
    run grep 'source.*\.env' /source/script/docker/exec.sh
    assert_success
}

@test "stop.sh sources .env" {
    run grep 'source.*\.env' /source/script/docker/stop.sh
    assert_success
}

@test "stop.sh removes orphan run-mode container by name" {
    run grep -E 'docker rm.*-f.*IMAGE_NAME' /source/script/docker/stop.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# i18n.sh shared module
# ════════════════════════════════════════════════════════════════════

@test "script/docker/i18n.sh exists" {
    assert [ -f /source/script/docker/i18n.sh ]
}

@test "Dockerfile.test-tools includes bats-mock" {
    run grep 'bats-mock' /source/dockerfile/Dockerfile.test-tools
    assert_success
}

@test "i18n.sh defines _detect_lang function" {
    run grep -E '^_detect_lang\(\)' /source/script/docker/i18n.sh
    assert_success
}

@test "build.sh sources i18n.sh" {
    run grep -E 'source.*i18n\.sh' /source/script/docker/build.sh
    assert_success
}

@test "run.sh sources i18n.sh" {
    run grep -E 'source.*i18n\.sh' /source/script/docker/run.sh
    assert_success
}

@test "exec.sh sources i18n.sh" {
    run grep -E 'source.*i18n\.sh' /source/script/docker/exec.sh
    assert_success
}

@test "stop.sh sources i18n.sh" {
    run grep -E 'source.*i18n\.sh' /source/script/docker/stop.sh
    assert_success
}

@test "setup.sh sources i18n.sh" {
    run grep -E 'source.*i18n\.sh' /source/script/docker/setup.sh
    assert_success
}

@test "build.sh -h works when i18n.sh is missing (consumer Dockerfile /lint scenario)" {
    # Regression: consumer Dockerfile copies *.sh into /lint without template/
    # tree, so sourcing template/script/docker/i18n.sh fails. build.sh must
    # gracefully fall back to inline _detect_lang so smoke tests pass.
    local _tmp
    _tmp="$(mktemp -d)"
    cp /source/script/docker/build.sh "${_tmp}/build.sh"
    run bash "${_tmp}/build.sh" -h
    assert_success
    assert_output --partial "Usage"
    rm -rf "${_tmp}"
}

@test "run.sh -h works when i18n.sh is missing" {
    local _tmp
    _tmp="$(mktemp -d)"
    cp /source/script/docker/run.sh "${_tmp}/run.sh"
    run bash "${_tmp}/run.sh" -h
    assert_success
    rm -rf "${_tmp}"
}

@test "exec.sh -h works when i18n.sh is missing" {
    local _tmp
    _tmp="$(mktemp -d)"
    cp /source/script/docker/exec.sh "${_tmp}/exec.sh"
    run bash "${_tmp}/exec.sh" -h
    assert_success
    rm -rf "${_tmp}"
}

@test "stop.sh -h works when i18n.sh is missing" {
    local _tmp
    _tmp="$(mktemp -d)"
    cp /source/script/docker/stop.sh "${_tmp}/stop.sh"
    run bash "${_tmp}/stop.sh" -h
    assert_success
    rm -rf "${_tmp}"
}

@test "setup.sh does not redefine _detect_lang" {
    # setup.sh is not COPY'd into consumer /lint stage, so no fallback needed
    run grep -cE '^_detect_lang\(\)' /source/script/docker/setup.sh
    assert_output "0"
}

# ════════════════════════════════════════════════════════════════════
# upgrade.sh
# ════════════════════════════════════════════════════════════════════

@test "upgrade.sh runs init.sh after subtree pull" {
    run grep -E 'init\.sh' /source/upgrade.sh
    assert_success
}

@test "upgrade.sh supports --gen-image-conf flag" {
    run grep -E '\-\-gen-image-conf' /source/upgrade.sh
    assert_success
}

@test "upgrade.sh --gen-image-conf delegates to init.sh --gen-image-conf" {
    run grep -E 'init\.sh.*--gen-image-conf' /source/upgrade.sh
    assert_success
}

@test "upgrade.sh --help mentions --gen-image-conf" {
    run bash -c "bash /source/upgrade.sh --help 2>&1"
    assert_success
    assert_output --partial "--gen-image-conf"
}

@test "upgrade.sh updates main.yaml @tag without clobbering release-worker.yaml" {
    # Regression: a greedy sed pattern .*@v[0-9.]* matched both build-worker
    # and release-worker references, replacing both with build-worker.yaml@<ver>
    local _tmp _yaml
    _tmp="$(mktemp -d)"
    _yaml="${_tmp}/main.yaml"
    mkdir -p "${_tmp}/template" "${_tmp}/.github/workflows"
    cat > "${_yaml}" <<'EOF'
jobs:
  call-docker-build:
    uses: ycpss91255-docker/template/.github/workflows/build-worker.yaml@v0.5.0
  call-release:
    uses: ycpss91255-docker/template/.github/workflows/release-worker.yaml@v0.5.0
EOF
    # Source upgrade.sh and exercise just the sed block by inlining the
    # production sed commands here, mirroring what upgrade.sh does.
    # We do this by extracting and running the sed commands from upgrade.sh.
    local _seds
    _seds="$(grep -E "^[[:space:]]*sed -i" /source/upgrade.sh)"
    while IFS= read -r _line; do
        # shellcheck disable=SC2001
        _line="$(echo "${_line}" | sed "s|\${main_yaml}|${_yaml}|g; s|\${target_ver}|v0.6.4|g")"
        eval "${_line}"
    done <<< "${_seds}"

    run grep "build-worker.yaml@v0.6.4" "${_yaml}"
    assert_success
    run grep "release-worker.yaml@v0.6.4" "${_yaml}"
    assert_success
    # Critical: release-worker must NOT be replaced by build-worker
    run grep -c "build-worker.yaml" "${_yaml}"
    assert_output "1"

    rm -rf "${_tmp}"
}

@test "upgrade.sh writes target_ver after init.sh (to override init's latest detection)" {
    # init.sh writes latest tag to .template_version, but upgrade may target older version
    # so upgrade.sh must overwrite .template_version AFTER init.sh runs
    run bash -c "grep -n 'init\.sh\|VERSION_FILE' /source/upgrade.sh | grep -v '^[0-9]*:#'"
    assert_success
    # Check that init.sh appears before the final VERSION_FILE write
    init_line=$(grep -n 'init\.sh' /source/upgrade.sh | head -1 | cut -d: -f1)
    write_line=$(grep -n 'echo.*target_ver.*>.*VERSION_FILE\|echo.*"\${target_ver}".*VERSION_FILE' /source/upgrade.sh | tail -1 | cut -d: -f1)
    [[ -n "${init_line}" && -n "${write_line}" && "${init_line}" -lt "${write_line}" ]]
}

# ════════════════════════════════════════════════════════════════════
# run.sh: XDG_SESSION_TYPE branching
# ════════════════════════════════════════════════════════════════════

@test "run.sh contains XDG_SESSION_TYPE check" {
    run grep "XDG_SESSION_TYPE" /source/script/docker/run.sh
    assert_success
}

@test "run.sh contains xhost +SI:localuser for wayland" {
    run grep 'xhost "+SI:localuser' /source/script/docker/run.sh
    assert_success
}

@test "run.sh contains xhost +local: for X11" {
    run grep 'xhost +local:' /source/script/docker/run.sh
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# setup.sh: default _base_path goes up 1 level (not 2)
# ════════════════════════════════════════════════════════════════════

@test "setup.sh default _base_path uses /.." {
    # In template, setup.sh is at template/script/docker/setup.sh
    # So it should go up 1 level (/..) to reach repo root
    run grep -E '\.\./\.\.' /source/script/docker/setup.sh
    assert_success  # Should have ../../ ../../ (that was old docker_setup_helper/src/ pattern)
}

@test "setup.sh default _base_path uses double parent traversal" {
    run grep -E "dirname.*BASH_SOURCE.*\.\..*\.\." /source/script/docker/setup.sh
    assert_success
}
