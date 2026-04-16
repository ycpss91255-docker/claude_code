#!/usr/bin/env bats
#
# Unit tests for init.sh helpers. Complements the Level-1 integration test
# in test/integration/init_new_repo_spec.bats — which already covers
# end-to-end init.sh runs — by exercising individual helpers against
# edge cases that are hard to trigger from a real `bash template/init.sh`
# invocation (e.g. network-down version detection, main.yaml @ref
# fallback, _create_version_file with no argument).

setup() {
  load "${BATS_TEST_DIRNAME}/test_helper"
  create_mock_dir

  # Mimic the integration-test layout so `init.sh` resolves TEMPLATE_DIR /
  # REPO_ROOT to a writable temp tree instead of /source. Symlinking
  # init.sh back to the real source keeps all edits in one place.
  TMP_REPO="$(mktemp -d)"
  mkdir -p "${TMP_REPO}/template/dockerfile" \
           "${TMP_REPO}/template/config" \
           "${TMP_REPO}/template/script/docker"
  ln -s /source/init.sh "${TMP_REPO}/template/init.sh"

  # Minimal Dockerfile.example stub for _create_new_repo's `cp` step.
  cat > "${TMP_REPO}/template/dockerfile/Dockerfile.example" <<'EOF'
FROM alpine
EOF

  # Stub scripts referenced by _create_symlinks — empty files are fine
  # because symlinks only need a valid target path, not a valid payload.
  for _f in build.sh run.sh exec.sh stop.sh Makefile; do
    : > "${TMP_REPO}/template/script/docker/${_f}"
  done
  : > "${TMP_REPO}/template/.hadolint.yaml"

  cd "${TMP_REPO}"
}

teardown() {
  cleanup_mock_dir
  rm -rf "${TMP_REPO}"
}

# Source init.sh within a `bash -c` so the test controls when functions
# are loaded and can mutate PATH / cwd before invocation. `bash -c ... "$0"`
# pattern via `run` is awkward — we wrap in a helper.
_source_init() {
  # shellcheck disable=SC1091
  source "${TMP_REPO}/template/init.sh"
}

# ════════════════════════════════════════════════════════════════════
# _detect_template_version
# ════════════════════════════════════════════════════════════════════

@test "_detect_template_version: parses newest vX.Y.Z tag from git ls-remote" {
  # Mock emits refs in the order the real `--sort=-v:refname` would produce
  # (newest-first). _detect_template_version trusts the sort and just
  # takes `head -1`.
  mock_cmd "git" '
    if [[ "$1" == "ls-remote" ]]; then
      cat <<REMOTE
def456  refs/tags/v0.7.2
ghi789  refs/tags/v0.7.1
abc123  refs/tags/v0.7.0
REMOTE
      exit 0
    fi
    exit 0'
  _source_init
  local result
  result="$(_detect_template_version)"
  assert_equal "${result}" "v0.7.2"
}

@test "_detect_template_version: returns empty when git ls-remote fails" {
  mock_cmd "git" 'exit 128'
  _source_init
  local result
  result="$(_detect_template_version)"
  assert_equal "${result}" ""
}

@test "_detect_template_version: returns empty when no v*.*.* tags exist" {
  mock_cmd "git" '
    if [[ "$1" == "ls-remote" ]]; then
      cat <<REMOTE
abc123  refs/heads/main
def456  refs/tags/latest
REMOTE
      exit 0
    fi
    exit 0'
  _source_init
  local result
  result="$(_detect_template_version)"
  assert_equal "${result}" ""
}

@test "_detect_template_version: ignores non-semver tags (e.g. rc suffixes)" {
  # --sort=-v:refname would rank v0.8.0-rc2 > v0.7.2-rc1 > v0.7.0, but
  # the regex strips the rc variants, leaving v0.7.0 as the only valid
  # vX.Y.Z entry.
  mock_cmd "git" '
    if [[ "$1" == "ls-remote" ]]; then
      cat <<REMOTE
ghi789  refs/tags/v0.8.0-rc2
def456  refs/tags/v0.7.2-rc1
abc123  refs/tags/v0.7.0
REMOTE
      exit 0
    fi
    exit 0'
  _source_init
  local result
  result="$(_detect_template_version)"
  assert_equal "${result}" "v0.7.0"
}

# ════════════════════════════════════════════════════════════════════
# _create_version_file
# ════════════════════════════════════════════════════════════════════

@test "_create_version_file: writes given version to .template_version" {
  _source_init
  _create_version_file "v1.2.3"
  assert [ -f "${TMP_REPO}/.template_version" ]
  run cat "${TMP_REPO}/.template_version"
  assert_output "v1.2.3"
}

@test "_create_version_file: writes 'unknown' when no argument given" {
  _source_init
  _create_version_file ""
  run cat "${TMP_REPO}/.template_version"
  assert_output "unknown"
}

@test "_create_version_file: writes 'unknown' when called with zero arguments" {
  _source_init
  _create_version_file
  run cat "${TMP_REPO}/.template_version"
  assert_output "unknown"
}

@test "_create_version_file: overwrites existing .template_version" {
  echo "v0.1.0" > "${TMP_REPO}/.template_version"
  _source_init
  _create_version_file "v2.0.0"
  run cat "${TMP_REPO}/.template_version"
  assert_output "v2.0.0"
}

# ════════════════════════════════════════════════════════════════════
# _create_new_repo: ref threading into main.yaml
# ════════════════════════════════════════════════════════════════════

@test "_create_new_repo: main.yaml uses given ref in workflow @ref" {
  _source_init
  _create_new_repo "v9.9.9"
  assert [ -f "${TMP_REPO}/.github/workflows/main.yaml" ]
  run grep -E 'build-worker\.yaml@v9\.9\.9' \
    "${TMP_REPO}/.github/workflows/main.yaml"
  assert_success
  run grep -E 'release-worker\.yaml@v9\.9\.9' \
    "${TMP_REPO}/.github/workflows/main.yaml"
  assert_success
}

@test "_create_new_repo: main.yaml falls back to @main when ref arg omitted" {
  _source_init
  _create_new_repo
  run grep -E 'build-worker\.yaml@main' \
    "${TMP_REPO}/.github/workflows/main.yaml"
  assert_success
  run grep -E 'release-worker\.yaml@main' \
    "${TMP_REPO}/.github/workflows/main.yaml"
  assert_success
}

@test "_create_new_repo: main.yaml falls back to @main when ref arg is empty" {
  _source_init
  _create_new_repo ""
  run grep -E 'build-worker\.yaml@main' \
    "${TMP_REPO}/.github/workflows/main.yaml"
  assert_success
}

@test "_create_new_repo: generates .env.example with IMAGE_NAME=<repo>" {
  _source_init
  _create_new_repo "main"
  run cat "${TMP_REPO}/.env.example"
  assert_output --partial "IMAGE_NAME="
  # TMP_REPO's basename is random; the entry should reference it.
  local _expected
  _expected="$(basename "${TMP_REPO}")"
  assert_output "IMAGE_NAME=${_expected}"
}

# ════════════════════════════════════════════════════════════════════
# _create_symlinks
# ════════════════════════════════════════════════════════════════════

@test "_create_symlinks: produces all five docker-script symlinks" {
  _source_init
  _create_symlinks
  for _f in build.sh run.sh exec.sh stop.sh Makefile; do
    assert [ -L "${TMP_REPO}/${_f}" ]
    run readlink "${TMP_REPO}/${_f}"
    assert_output "template/script/docker/${_f}"
  done
}

@test "_create_symlinks: replaces a stale file at the symlink path" {
  # Pretend an earlier run left a regular file where the symlink should go
  echo "stale" > "${TMP_REPO}/build.sh"
  _source_init
  _create_symlinks
  assert [ -L "${TMP_REPO}/build.sh" ]
}

@test "_create_symlinks: keeps custom .hadolint.yaml when it differs" {
  echo "# repo-specific rules" > "${TMP_REPO}/.hadolint.yaml"
  # Template's stub is empty — force a difference
  _source_init
  run _create_symlinks
  assert_success
  assert_output --partial "Keeping custom .hadolint.yaml"
  # Custom file should still be a regular file, not a symlink
  assert [ ! -L "${TMP_REPO}/.hadolint.yaml" ]
}
