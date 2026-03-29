#!/usr/bin/env bash
# upgrade.sh - Upgrade template subtree to the latest version
#
# Run from the repo root:
#   ./template/script/upgrade.sh              # upgrade to latest tag
#   ./template/script/upgrade.sh v0.3.0       # upgrade to specific version
#   ./template/script/upgrade.sh --check      # check if update available

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
readonly REPO_ROOT
TEMPLATE_REMOTE="git@github.com:ycpss91255-docker/template.git"
readonly TEMPLATE_REMOTE
VERSION_FILE="${REPO_ROOT}/.template_version"
readonly VERSION_FILE

cd "${REPO_ROOT}"

_log() { printf "[upgrade] %s\n" "$*"; }
_error() { printf "[upgrade] ERROR: %s\n" "$*" >&2; exit 1; }

# ── Get versions ─────────────────────────────────────────────────────────────

_get_local_version() {
  if [[ -f "${VERSION_FILE}" ]]; then
    tr -d '[:space:]' < "${VERSION_FILE}"
  else
    echo "unknown"
  fi
}

_get_latest_version() {
  git ls-remote --tags --sort=-v:refname "${TEMPLATE_REMOTE}" \
    | grep -oP 'refs/tags/v\d+\.\d+\.\d+$' \
    | head -1 \
    | sed 's|refs/tags/||'
}

# ── Check mode ───────────────────────────────────────────────────────────────

_check() {
  local local_ver latest_ver
  local_ver="$(_get_local_version)"
  latest_ver="$(_get_latest_version)"

  if [[ -z "${latest_ver}" ]]; then
    _error "Could not fetch latest version from ${TEMPLATE_REMOTE}"
  fi

  _log "Local:  ${local_ver}"
  _log "Latest: ${latest_ver}"

  if [[ "${local_ver}" == "${latest_ver}" ]]; then
    _log "Already up to date."
    return 0
  else
    _log "Update available: ${local_ver} → ${latest_ver}"
    return 1
  fi
}

# ── Upgrade ──────────────────────────────────────────────────────────────────

_upgrade() {
  local target_ver="$1"
  local local_ver
  local_ver="$(_get_local_version)"

  if [[ "${local_ver}" == "${target_ver}" ]]; then
    _log "Already at ${target_ver}. Nothing to do."
    return 0
  fi

  _log "Upgrading: ${local_ver} → ${target_ver}"

  # Step 1: subtree pull
  _log "Step 1/3: git subtree pull"
  git subtree pull --prefix=template \
    "${TEMPLATE_REMOTE}" "${target_ver}" --squash \
    -m "chore: upgrade template subtree to ${target_ver}"

  # Step 2: update version file
  _log "Step 2/3: update .template_version"
  echo "${target_ver}" > "${VERSION_FILE}"
  git add "${VERSION_FILE}"

  # Step 3: update main.yaml @tag references
  _log "Step 3/3: update workflow @tag references"
  local main_yaml="${REPO_ROOT}/.github/workflows/main.yaml"
  if [[ -f "${main_yaml}" ]]; then
    # Replace @vX.Y.Z with new version in reusable workflow references
    sed -i "s|template/\.github/workflows/.*@v[0-9.]*|template/.github/workflows/build-worker.yaml@${target_ver}|" "${main_yaml}"
    sed -i "s|build-worker\.yaml@v[0-9.]*|build-worker.yaml@${target_ver}|" "${main_yaml}"
    sed -i "s|release-worker\.yaml@v[0-9.]*|release-worker.yaml@${target_ver}|" "${main_yaml}"
    git add "${main_yaml}"
  fi

  # Commit version + workflow updates
  git commit -m "$(cat <<COMMIT
chore: update template references to ${target_ver}

- .template_version: ${local_ver} → ${target_ver}
- main.yaml: workflow @tag updated to ${target_ver}

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
COMMIT
)" || _log "No additional changes to commit"

  _log "Done! Upgraded to ${target_ver}"
  _log ""
  _log "Next steps:"
  _log "  1. Run ./build.sh test to verify"
  _log "  2. git push"
}

# ── Help ─────────────────────────────────────────────────────────────────────

_usage() {
  cat >&2 <<'EOF'
Usage: ./template/script/upgrade.sh [VERSION|--check]

Upgrade template subtree to the latest (or specified) version.

Arguments:
  VERSION       Target version (e.g. v0.3.0). Defaults to latest tag.
  --check       Check if an update is available (no changes made)
  -h, --help    Show this help

Examples:
  ./template/script/upgrade.sh              # upgrade to latest
  ./template/script/upgrade.sh v0.3.0       # upgrade to specific version
  ./template/script/upgrade.sh --check      # check only
EOF
  exit 0
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  [[ ! -d template ]] && _error "template/ not found. Run from repo root."

  case "${1:-}" in
    -h|--help) _usage ;;
    --check) _check ;;
    v*)
      _upgrade "$1"
      ;;
    "")
      local latest
      latest="$(_get_latest_version)"
      [[ -z "${latest}" ]] && _error "Could not fetch latest version"
      _upgrade "${latest}"
      ;;
    *) _error "Unknown argument: $1" ;;
  esac
}

main "$@"
