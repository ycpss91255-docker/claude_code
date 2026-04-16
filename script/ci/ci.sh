#!/usr/bin/env bash
# ci.sh - Run CI pipeline (ShellCheck + Bats + Kcov)
#
# Usage:
#   ./ci.sh              # Run full CI via docker compose (default)
#   ./ci.sh --ci         # Run inside CI container (called by compose)
#   ./ci.sh --lint-only  # Run ShellCheck only (via docker compose)
#   ./ci.sh --coverage   # Run tests + coverage (via docker compose)
#   ./ci.sh -h, --help   # Show this help

# Only set strict mode when running directly; when sourced, respect caller's settings
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
readonly REPO_ROOT

# ── Help ─────────────────────────────────────────────────────────────────────

usage() {
  cat >&2 <<'EOF'
Usage: ./ci.sh [OPTIONS]

Run CI pipeline: ShellCheck + Bats unit tests + Kcov coverage.

Options:
  --ci          Run directly inside CI container (called by compose)
  --lint-only   Run ShellCheck only
  --coverage    Run tests with Kcov coverage
  -h, --help    Show this help

Without options, runs the full CI via docker compose.

Examples:
  ./ci.sh                # Full CI (docker compose)
  make test              # Same as above (via Makefile)
  make lint              # ShellCheck only
EOF
  exit 0
}

# ── CI container setup ───────────────────────────────────────────────────────

_die() { printf "[ci] ERROR: %s\n" "$*" >&2; exit 1; }

_install_deps() {
  command -v bats >/dev/null 2>&1 && return 0

  apt-get update -qq \
    || _die "apt-get update failed. Check network / apt mirror reachability."

  apt-get install -y --no-install-recommends \
      bats bats-support bats-assert \
      shellcheck git ca-certificates \
    || _die "apt-get install failed for bats/shellcheck deps."

  # bats-mock is distro-packaged on newer distros but missing on bookworm,
  # so we always pin to upstream v1.2.5 for reproducibility.
  git clone --depth 1 -b v1.2.5 \
      https://github.com/jasonkarns/bats-mock /usr/lib/bats/bats-mock \
    || _die "git clone bats-mock failed. Check network / GitHub access."
}

# ── ShellCheck ───────────────────────────────────────────────────────────────

_run_shellcheck() {
  echo "--- Running ShellCheck ---"
  find "${REPO_ROOT}/script/docker" -maxdepth 1 -name "*.sh" -print0 | xargs -0 shellcheck -x
  shellcheck -x "${REPO_ROOT}/script/ci/ci.sh"
  shellcheck -x "${REPO_ROOT}/init.sh"
  shellcheck -x "${REPO_ROOT}/upgrade.sh"
  shellcheck -x "${REPO_ROOT}/config/pip/setup.sh"
  shellcheck -x "${REPO_ROOT}/config/shell/terminator/setup.sh"
  shellcheck -x "${REPO_ROOT}/config/shell/tmux/setup.sh"
}

# ── Bats tests ───────────────────────────────────────────────────────────────

_run_tests() {
  echo "--- Running Bats Unit Tests ---"
  bats "${REPO_ROOT}/test/unit/"
  echo "--- Running Bats Integration Tests ---"
  bats "${REPO_ROOT}/test/integration/"
}

# ── Kcov coverage ────────────────────────────────────────────────────────────

_run_coverage() {
  local _excludes=(
    "${REPO_ROOT}/test/"
    "${REPO_ROOT}/script/ci/"
    "${REPO_ROOT}/init.sh"
    "${REPO_ROOT}/upgrade.sh"
    "${REPO_ROOT}/config/shell/bashrc"
    "${REPO_ROOT}/config/shell/terminator/config"
    "${REPO_ROOT}/config/shell/tmux/tmux.conf"
    "${REPO_ROOT}/.github/"
  )
  local _exclude_path
  _exclude_path="$(IFS=,; printf '%s' "${_excludes[*]}")"

  echo "--- Running Tests with Kcov Coverage ---"
  kcov \
    --include-path="${REPO_ROOT}" \
    --exclude-path="${_exclude_path}" \
    "${REPO_ROOT}/coverage" \
    bats "${REPO_ROOT}/test/unit/" "${REPO_ROOT}/test/integration/"
}

# ── Fix coverage permissions ─────────────────────────────────────────────────

_fix_permissions() {
  local uid="${HOST_UID:-}"
  local gid="${HOST_GID:-}"
  if [[ -n "${uid}" && -n "${gid}" && -d "${REPO_ROOT}/coverage" ]]; then
    chown -R "${uid}:${gid}" "${REPO_ROOT}/coverage"
  fi
}

# ── Docker compose wrapper ───────────────────────────────────────────────────

_run_via_compose() {
  docker compose -f "${REPO_ROOT}/compose.yaml" run --rm \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    ci
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  local mode="compose"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage ;;
      --ci) mode="ci"; shift ;;
      --lint-only) mode="lint"; shift ;;
      --coverage) mode="coverage"; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  case "${mode}" in
    ci)
      # Running inside container
      _install_deps
      _run_shellcheck
      _run_coverage
      _fix_permissions
      echo "Coverage report: ${REPO_ROOT}/coverage/index.html"
      ;;
    lint)
      # ShellCheck only — requires shellcheck installed locally
      _run_shellcheck
      ;;
    coverage)
      # Full CI via docker compose (same as default)
      _run_via_compose
      ;;
    compose)
      # Default: full CI via docker compose
      _run_via_compose
      ;;
  esac
}

# Guard: only run main when executed directly, not when sourced (for testing)
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  main "$@"
fi
