#!/usr/bin/env bash
# init.sh - Initialize a repo with template symlinks
#
# Run from the repo root after git subtree add:
#   ./template/script/init.sh
#
# Creates symlinks for shared scripts and removes old docker_setup_helper
# artifacts if present.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
TEMPLATE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly TEMPLATE_DIR
REPO_ROOT="$(cd -- "${TEMPLATE_DIR}/.." && pwd -P)"
readonly REPO_ROOT
TEMPLATE_REL="template"
readonly TEMPLATE_REL

cd "${REPO_ROOT}"

_log() { printf "[init] %s\n" "$*"; }

# ── Clean up old docker_setup_helper artifacts ───────────────────────────────

if [[ -d docker_setup_helper ]]; then
  _log "Removing old docker_setup_helper/"
  git rm -rf docker_setup_helper/ 2>/dev/null || rm -rf docker_setup_helper/
fi

if [[ -f .docker_setup_helper_version ]]; then
  _log "Removing .docker_setup_helper_version"
  git rm -f .docker_setup_helper_version 2>/dev/null || rm -f .docker_setup_helper_version
fi

# ── Create script symlinks ───────────────────────────────────────────────────

_symlink() {
  local target="$1" link="$2"
  if [[ -L "${link}" || -f "${link}" ]]; then
    rm -f "${link}"
  fi
  ln -sf "${target}" "${link}"
  _log "  ${link} -> ${target}"
}

_log "Creating symlinks:"
_symlink "${TEMPLATE_REL}/build.sh" "build.sh"
_symlink "${TEMPLATE_REL}/run.sh" "run.sh"
_symlink "${TEMPLATE_REL}/exec.sh" "exec.sh"
_symlink "${TEMPLATE_REL}/stop.sh" "stop.sh"
_symlink "${TEMPLATE_REL}/Makefile" "Makefile"

# .hadolint.yaml: only symlink if no custom version exists
if [[ ! -f .hadolint.yaml ]] || diff -q .hadolint.yaml "${TEMPLATE_REL}/.hadolint.yaml" >/dev/null 2>&1; then
  _symlink "${TEMPLATE_REL}/.hadolint.yaml" ".hadolint.yaml"
else
  _log "  Keeping custom .hadolint.yaml (differs from template)"
fi

# ── Remove old shared smoke tests (now provided by template) ──────────

for f in test/smoke/test_helper.bash test/smoke/script_help.bats test/smoke/display_env.bats; do
  if [[ -f "${f}" ]] && [[ -L "${f}" || ! -s "${f}" ]]; then
    rm -f "${f}"
    _log "  Removed old ${f}"
  fi
done

# ── Remove old local CI workflows ───────────────────────────────────────────

for f in .github/workflows/build-worker.yaml .github/workflows/release-worker.yaml; do
  if [[ -f "${f}" ]]; then
    git rm -f "${f}" 2>/dev/null || rm -f "${f}"
    _log "  Removed ${f}"
  fi
done

# ── Version file ─────────────────────────────────────────────────────────────

if [[ -f "${TEMPLATE_DIR}/script/migrate.sh" ]]; then
  # Extract TEMPLATE_VERSION from migrate.sh
  ver=$(grep -oP 'TEMPLATE_VERSION="\K[^"]+' "${TEMPLATE_DIR}/script/migrate.sh" 2>/dev/null || echo "v0.2.0")
else
  ver="v0.2.0"
fi
echo "${ver}" > .template_version
_log "Created .template_version (${ver})"

# ── Summary ──────────────────────────────────────────────────────────────────

_log ""
_log "Done! Next steps:"
_log "  1. Update Dockerfile CONFIG_SRC: docker_setup_helper/src/config → template/config"
_log "  2. Update Dockerfile smoke test COPY:"
_log "       COPY template/test/smoke/ /smoke/"
_log "       COPY test/smoke/ /smoke/"
_log "  3. Update .github/workflows/main.yaml to use reusable workflows"
_log "  4. git add -A && git commit"
