#!/usr/bin/env bash
# ci.sh - Run CI pipeline (ShellCheck + Bats [+ Kcov])
#
# Usage:
#   ./ci.sh              # Run ShellCheck + Bats (fast dev loop)
#   ./ci.sh --ci         # Run inside CI container (called by compose)
#   ./ci.sh --lint-only  # Run ShellCheck only (via docker compose)
#   ./ci.sh --coverage   # Run ShellCheck + Bats + Kcov coverage
#   ./ci.sh -h, --help   # Show this help
#
# Kcov instrumentation wraps every bats command and slows the suite
# 2-5x, so the default no longer runs it. Run `--coverage` (or
# `make coverage`) when you need the HTML report before releasing.

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

Run CI pipeline: ShellCheck + Bats [+ Kcov coverage].

Options:
  --ci          Run directly inside CI container (called by compose);
                honors $COVERAGE=1 to include kcov (else bats only)
  --lint-only   Run ShellCheck only
  --coverage    Run tests with Kcov coverage (slow; CI / release check)
  -h, --help    Show this help

Default (no flag): ShellCheck + bats via docker compose, no kcov.
Kcov wraps every bats command and slows the suite 2-5x, so the
dev-loop default skips it.

Examples:
  ./ci.sh                # Fast: ShellCheck + Bats (no kcov)
  make test              # Same as above
  ./ci.sh --coverage     # Full: ShellCheck + Bats + Kcov
  make coverage          # Same as above
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
      parallel \
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
  # --jobs N uses GNU parallel under the hood; bats parallelizes both
  # across files and within files by default. All specs use per-test
  # mktemp dirs (BATS_TEST_TMPDIR / TEMP_DIR) so there's no shared
  # filesystem state between tests — safe to run concurrently.
  local _jobs
  _jobs="$(nproc 2>/dev/null || echo 4)"
  echo "--- Running Bats Unit Tests (jobs=${_jobs}) ---"
  bats --jobs "${_jobs}" "${REPO_ROOT}/test/unit/"
  echo "--- Running Bats Integration Tests (jobs=${_jobs}) ---"
  bats --jobs "${_jobs}" "${REPO_ROOT}/test/integration/"
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
  local _coverage="${1:-0}"
  docker compose -f "${REPO_ROOT}/compose.yaml" run --rm \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e COVERAGE="${_coverage}" \
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
      # Running inside container. Default path skips kcov for speed
      # (the dev loop is far more frequent than the coverage check).
      # Pass COVERAGE=1 via the outer `--coverage` flag to include it.
      _install_deps
      _run_shellcheck
      if [[ "${COVERAGE:-0}" == "1" ]]; then
        _run_coverage
        _fix_permissions
        echo "Coverage report: ${REPO_ROOT}/coverage/index.html"
      else
        _run_tests
      fi
      ;;
    lint)
      # ShellCheck only — requires shellcheck installed locally
      _run_shellcheck
      ;;
    coverage)
      # Full CI + kcov via docker compose
      _run_via_compose 1
      ;;
    compose)
      # Default: fast CI (shellcheck + bats, no kcov) via docker compose
      _run_via_compose 0
      ;;
  esac
}

# Guard: only run main when executed directly, not when sourced (for testing)
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  main "$@"
fi
