#!/usr/bin/env bash
# init.sh - Initialize a repo with template
#
# Run from the repo root after git subtree add:
#   ./template/init.sh
#
# Auto-detects:
#   - Has Dockerfile → existing repo: create symlinks + .template_version
#   - No Dockerfile → new repo: generate full project structure

# Only set strict mode when running directly; when sourced, respect caller's settings
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
fi

TEMPLATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly TEMPLATE_DIR
REPO_ROOT="$(cd -- "${TEMPLATE_DIR}/.." && pwd -P)"
readonly REPO_ROOT
TEMPLATE_REL="template"
readonly TEMPLATE_REL

_log() { printf "[init] %s\n" "$*"; }

# ── Symlink helper ──────────────────────────────────────────────────────────

_symlink() {
  local target="$1" link="$2"
  if [[ -L "${link}" || -f "${link}" ]]; then
    rm -f "${link}"
  fi
  ln -sf "${target}" "${link}"
  _log "  ${link} -> ${target}"
}

_create_symlinks() {
  _log "Creating symlinks:"
  _symlink "${TEMPLATE_REL}/script/docker/build.sh" "build.sh"
  _symlink "${TEMPLATE_REL}/script/docker/run.sh" "run.sh"
  _symlink "${TEMPLATE_REL}/script/docker/exec.sh" "exec.sh"
  _symlink "${TEMPLATE_REL}/script/docker/stop.sh" "stop.sh"
  _symlink "${TEMPLATE_REL}/script/docker/Makefile" "Makefile"

  if [[ ! -f .hadolint.yaml ]] \
    || diff -q .hadolint.yaml "${TEMPLATE_REL}/.hadolint.yaml" \
      >/dev/null 2>&1; then
    _symlink "${TEMPLATE_REL}/.hadolint.yaml" ".hadolint.yaml"
  else
    _log "  Keeping custom .hadolint.yaml (differs from template)"
  fi
}

_detect_template_version() {
  git ls-remote --tags --sort=-v:refname \
    git@github.com:ycpss91255-docker/template.git 2>/dev/null \
    | grep -oP 'refs/tags/v\d+\.\d+\.\d+$' \
    | head -1 \
    | sed 's|refs/tags/||' || true
}

_create_version_file() {
  local ver="${1:-unknown}"
  echo "${ver}" > .template_version
  _log "Created .template_version (${ver})"
}

# ── New repo scaffolding ────────────────────────────────────────────────────

_detect_repo_name() {
  basename "${REPO_ROOT}"
}

_create_new_repo() {
  local ref="${1:-main}"
  local name=""
  name="$(_detect_repo_name)"
  _log "Creating new repo: ${name}"

  # Dockerfile
  cp "${TEMPLATE_DIR}/dockerfile/Dockerfile.example" Dockerfile
  _log "  Created Dockerfile (from template)"

  # compose.yaml
  cat > compose.yaml <<YAML
services:
  devel:
    build:
      context: .
      dockerfile: Dockerfile
      target: devel
      args:
        APT_MIRROR_UBUNTU: \${APT_MIRROR_UBUNTU:-tw.archive.ubuntu.com}
        APT_MIRROR_DEBIAN: \${APT_MIRROR_DEBIAN:-mirror.twds.com.tw}
    image: \${DOCKER_HUB_USER:-local}/${name}:devel
    container_name: ${name}\${INSTANCE_SUFFIX:-}
    stdin_open: true
    tty: true

  test:
    build:
      context: .
      dockerfile: Dockerfile
      target: test
      args:
        APT_MIRROR_UBUNTU: \${APT_MIRROR_UBUNTU:-tw.archive.ubuntu.com}
        APT_MIRROR_DEBIAN: \${APT_MIRROR_DEBIAN:-mirror.twds.com.tw}
    image: \${DOCKER_HUB_USER:-local}/${name}:test
    profiles:
      - test
YAML
  _log "  Created compose.yaml"

  # script/entrypoint.sh
  mkdir -p script
  cat > script/entrypoint.sh <<'ENTRY'
#!/usr/bin/env bash

exec "${@}"
ENTRY
  chmod +x script/entrypoint.sh
  _log "  Created script/entrypoint.sh"

  # test/smoke/<name>_env.bats
  mkdir -p test/smoke
  cat > "test/smoke/${name}_env.bats" <<BATS
#!/usr/bin/env bats
#
# Repo-specific runtime smoke tests. Exercise the \`devel\` image built
# from this repo's Dockerfile, via the \`test\` stage. Use the shared
# helpers in test_helper.bash (assert_cmd_installed, assert_file_exists,
# assert_dir_exists, assert_file_owned_by, assert_pip_pkg, ...) to keep
# assertions terse. Add one assertion per meaningful installation
# artifact.

setup() {
  load "\${BATS_TEST_DIRNAME}/test_helper"
}

@test "entrypoint.sh is installed and executable" {
  assert_file_exists /entrypoint.sh
  assert [ -x /entrypoint.sh ]
}

@test "bash is available on PATH" {
  assert_cmd_installed bash
}
BATS
  _log "  Created test/smoke/${name}_env.bats"

  # .env.example
  echo "IMAGE_NAME=${name}" > .env.example
  _log "  Created .env.example"

  # .github/workflows/main.yaml
  mkdir -p .github/workflows
  cat > .github/workflows/main.yaml <<YAML
name: Main CI/CD

on:
  push:
    branches: [main, master]
    tags:
      - 'v*'
  pull_request:
  workflow_dispatch:

jobs:
  call-docker-build:
    uses: ycpss91255-docker/template/.github/workflows/build-worker.yaml@${ref}
    with:
      image_name: ${name}

  call-release:
    needs: call-docker-build
    if: startsWith(github.ref, 'refs/tags/')
    uses: ycpss91255-docker/template/.github/workflows/release-worker.yaml@${ref}
    with:
      archive_name_prefix: ${name}
YAML
  _log "  Created .github/workflows/main.yaml"

  # .gitignore
  cat > .gitignore <<'GIT'
.env
coverage/
.Dockerfile.generated
GIT
  _log "  Created .gitignore"

  # doc/
  mkdir -p doc/test doc/changelog
  cat > README.md <<MD
# ${name}

**[English](README.md)** | **[繁體中文](doc/README.zh-TW.md)** | **[简体中文](doc/README.zh-CN.md)** | **[日本語](doc/README.ja.md)**

## Quick Start

\`\`\`bash
./build.sh && ./run.sh
\`\`\`

## Smoke Tests

See [TEST.md](doc/test/TEST.md) for details.
MD

  for lang_file in "README.zh-TW.md" "README.zh-CN.md" "README.ja.md"; do
    cat > "doc/${lang_file}" <<MD
# ${name}

**[English](../README.md)** | **[繁體中文](README.zh-TW.md)** | **[简体中文](README.zh-CN.md)** | **[日本語](README.ja.md)**
MD
  done
  _log "  Created README.md + doc/ translations"

  cat > doc/test/TEST.md <<MD
# TEST.md

**1 test** total.

## test/smoke/${name}_env.bats (1)

| Test | Description |
|------|-------------|
| \`entrypoint.sh exists and is executable\` | Entrypoint check |
MD
  _log "  Created doc/test/TEST.md"

  cat > doc/changelog/CHANGELOG.md <<MD
# Changelog

## [Unreleased]

### Added
- Initial release
MD
  _log "  Created doc/changelog/CHANGELOG.md"
}

# ── Existing repo initialization ────────────────────────────────────────────

_init_existing_repo() {
  _log "Existing repo detected (Dockerfile found)"
  _create_symlinks
}

# ── Generate per-repo image_name.conf ───────────────────────────────────────

_gen_image_conf() {
  local _src="${TEMPLATE_DIR}/config/image_name.conf"
  local _dst="${REPO_ROOT}/image_name.conf"
  if [[ ! -f "${_src}" ]]; then
    _error "Template image_name.conf not found at ${_src}"
  fi
  if [[ -f "${_dst}" ]]; then
    _error "image_name.conf already exists in repo root. Remove it first or edit directly."
  fi
  cp "${_src}" "${_dst}"
  _log "Created ${_dst}"
  _log "Edit it to customize IMAGE_NAME detection rules for this repo."
}

_error() { printf "[init] ERROR: %s\n" "$*" >&2; exit 1; }

# ── Main ────────────────────────────────────────────────────────────────────

main() {
  if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    cat >&2 <<'EOF'
Usage: ./template/init.sh [--gen-image-conf]

Initialize a repo with template. Auto-detects:
  - Has Dockerfile → create symlinks + .template_version
  - No Dockerfile  → generate full project structure

Options:
  --gen-image-conf   Copy template's image_name.conf to repo root
                     (for per-repo IMAGE_NAME detection rule override)

Run from the repo root after:
  git subtree add --prefix=template \
      git@github.com:ycpss91255-docker/template.git <version> --squash
EOF
    return 0
  fi

  cd "${REPO_ROOT}"

  if [[ "${1:-}" == "--gen-image-conf" ]]; then
    _gen_image_conf
    return 0
  fi

  local template_version=""
  template_version="$(_detect_template_version)"

  if [[ -f Dockerfile ]]; then
    _init_existing_repo
  else
    _create_new_repo "${template_version:-main}"
    _create_symlinks
  fi

  _create_version_file "${template_version}"

  _log ""
  _log "Done!"
}

# Guard: only run main when executed directly, not when sourced (for testing)
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  main "$@"
fi
