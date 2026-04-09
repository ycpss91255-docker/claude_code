#!/usr/bin/env bats
#
# Integration test: init.sh creating a brand-new repo from scratch.
#
# Verifies that running `./template/init.sh` in an empty directory produces
# a complete, internally-consistent repo skeleton (Dockerfile, compose.yaml,
# symlinks, .env.example, doc tree, .github/workflows, etc.).
#
# This is a Level-1 (file generation) integration test — it does NOT run
# Docker. The Level-2 (real build/run/exec/stop) test lives in CI as a
# separate self-test.yaml job that has access to the host Docker daemon.

setup() {
    load "${BATS_TEST_DIRNAME}/../unit/test_helper"

    # Stage a fake repo dir whose basename will become IMAGE_NAME
    REPO_NAME="myapp_test"
    TMP_ROOT="$(mktemp -d)"
    REPO_DIR="${TMP_ROOT}/${REPO_NAME}"
    mkdir -p "${REPO_DIR}/template"

    # Mirror the template into REPO_DIR/template/ so init.sh's TEMPLATE_DIR
    # detection (../template relative to itself) works correctly. Use cp -a
    # to preserve executable bits and symlinks.
    cp -a /source/. "${REPO_DIR}/template/"

    cd "${REPO_DIR}"
}

teardown() {
    rm -rf "${TMP_ROOT}"
}

# ════════════════════════════════════════════════════════════════════
# init.sh: new repo full-skeleton generation
# ════════════════════════════════════════════════════════════════════

@test "init.sh detects empty dir and creates new repo skeleton" {
    run bash template/init.sh
    assert_success
    assert_output --partial "Done"
}

@test "new repo: Dockerfile is copied from template" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/Dockerfile" ]
}

@test "new repo: compose.yaml exists and references the repo name" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/compose.yaml" ]
    run grep "${REPO_NAME}" "${REPO_DIR}/compose.yaml"
    assert_success
}

@test "new repo: .env.example contains IMAGE_NAME=<reponame>" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/.env.example" ]
    run grep "IMAGE_NAME=${REPO_NAME}" "${REPO_DIR}/.env.example"
    assert_success
}

@test "new repo: script/entrypoint.sh exists and is executable" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/script/entrypoint.sh" ]
}

@test "new repo: smoke test skeleton exists for the repo" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/test/smoke/${REPO_NAME}_env.bats" ]
}

@test "new repo: .github/workflows/main.yaml exists with reusable workflow ref" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/.github/workflows/main.yaml" ]
    run grep -E 'build-worker\.yaml@v' "${REPO_DIR}/.github/workflows/main.yaml"
    assert_success
}

@test "new repo: .gitignore exists" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/.gitignore" ]
}

@test "new repo: doc/ tree exists with README translations" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/README.md" ]
    assert [ -f "${REPO_DIR}/doc/README.zh-TW.md" ]
    assert [ -f "${REPO_DIR}/doc/README.zh-CN.md" ]
    assert [ -f "${REPO_DIR}/doc/README.ja.md" ]
}

@test "new repo: doc/test/TEST.md exists" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/doc/test/TEST.md" ]
}

@test "new repo: doc/changelog/CHANGELOG.md exists" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/doc/changelog/CHANGELOG.md" ]
}

@test "new repo: build.sh symlink → template/script/docker/build.sh" {
    bash template/init.sh
    assert [ -L "${REPO_DIR}/build.sh" ]
    run readlink "${REPO_DIR}/build.sh"
    assert_output "template/script/docker/build.sh"
}

@test "new repo: run.sh / exec.sh / stop.sh / Makefile symlinks correct" {
    bash template/init.sh
    for f in run.sh exec.sh stop.sh Makefile; do
        assert [ -L "${REPO_DIR}/${f}" ]
    done
    run readlink "${REPO_DIR}/run.sh"
    assert_output "template/script/docker/run.sh"
    run readlink "${REPO_DIR}/exec.sh"
    assert_output "template/script/docker/exec.sh"
    run readlink "${REPO_DIR}/stop.sh"
    assert_output "template/script/docker/stop.sh"
    run readlink "${REPO_DIR}/Makefile"
    assert_output "template/script/docker/Makefile"
}

@test "new repo: .template_version exists and matches a known tag format" {
    bash template/init.sh
    assert [ -f "${REPO_DIR}/.template_version" ]
    run cat "${REPO_DIR}/.template_version"
    # Should be vX.Y.Z, "unknown", or "main"
    assert_output --regexp '^(v[0-9]+\.[0-9]+\.[0-9]+|unknown|main)$'
}

@test "new repo: re-running init.sh on the result is idempotent" {
    bash template/init.sh
    # Second run should hit _init_existing_repo (Dockerfile exists)
    run bash template/init.sh
    assert_success
}

@test "new repo: build.sh -h works against the generated symlink" {
    bash template/init.sh
    run bash "${REPO_DIR}/build.sh" -h
    assert_success
    assert_output --partial "Usage"
}

@test "new repo: run.sh -h works against the generated symlink" {
    bash template/init.sh
    run bash "${REPO_DIR}/run.sh" -h
    assert_success
}

@test "new repo: exec.sh -h works against the generated symlink" {
    bash template/init.sh
    run bash "${REPO_DIR}/exec.sh" -h
    assert_success
}

@test "new repo: stop.sh -h works against the generated symlink" {
    bash template/init.sh
    run bash "${REPO_DIR}/stop.sh" -h
    assert_success
}

# ════════════════════════════════════════════════════════════════════
# init.sh --gen-image-conf
# ════════════════════════════════════════════════════════════════════

@test "init.sh --gen-image-conf copies image_name.conf to repo root" {
    bash template/init.sh        # generate skeleton first
    bash template/init.sh --gen-image-conf
    assert [ -f "${REPO_DIR}/image_name.conf" ]
}

@test "init.sh --gen-image-conf refuses to overwrite existing image_name.conf" {
    bash template/init.sh
    bash template/init.sh --gen-image-conf
    run bash template/init.sh --gen-image-conf
    assert_failure
    assert_output --partial "already exists"
}
