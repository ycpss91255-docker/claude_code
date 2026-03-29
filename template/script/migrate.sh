#!/usr/bin/env bash
# migrate.sh - Migrate Docker container repos to use template
#
# Usage:
#   ./migrate.sh <repo_path>          # migrate a single repo
#   ./migrate.sh --all                # migrate all known repos
#   ./migrate.sh --list               # list repos and their migration status
#   ./migrate.sh --dry-run <repo_path> # show what would be done
#
# This script:
#   1. Removes docker_setup_helper subtree and old CI workflows
#   2. Adds template as git subtree
#   3. Replaces shell scripts with symlinks to template/
#   4. Updates Dockerfile (CONFIG_SRC path, smoke test COPY)
#   5. Generates main.yaml with reusable workflow calls
#   6. Commits changes and creates a PR

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
TEMPLATE_REPO="git@github.com:ycpss91255-docker/template.git"
readonly TEMPLATE_REPO
TEMPLATE_VERSION="v0.3.0"
DRY_RUN=false

# ── Repo registry ────────────────────────────────────────────────────────────
# Format: path|image_name|build_args|has_gui|has_runtime|extra_release_files
# build_args: semicolon-separated KEY=VALUE pairs
declare -A REPO_REGISTRY
_register() {
  local path="$1" image="$2" args="${3:-}" gui="${4:-true}" runtime="${5:-true}" extras="${6:-}"
  REPO_REGISTRY["${path}"]="${image}|${args}|${gui}|${runtime}|${extras}"
}

_init_registry() {
  local base
  base="$(cd "${1:-.}" && pwd -P)"

  # env repos
  _register "${base}/env/ros_noetic" "ros_noetic" \
    "ROS_DISTRO=noetic;ROS_TAG=ros-base;UBUNTU_CODENAME=focal"
  _register "${base}/env/ros_kinetic" "ros_kinetic" \
    "ROS_DISTRO=kinetic;ROS_TAG=ros-base;UBUNTU_CODENAME=xenial"
  _register "${base}/env/ros2_humble" "ros2_humble" \
    "ROS_DISTRO=humble;ROS_TAG=ros-base;UBUNTU_CODENAME=jammy"
  _register "${base}/env/osrf_ros_noetic" "osrf_ros_noetic" \
    "ROS_DISTRO=noetic;ROS_TAG=desktop-full;UBUNTU_CODENAME=focal"
  _register "${base}/env/osrf_ros_kinetic" "osrf_ros_kinetic" \
    "ROS_DISTRO=kinetic;ROS_TAG=desktop-full;UBUNTU_CODENAME=xenial"
  _register "${base}/env/osrf_ros2_humble" "osrf_ros2_humble" \
    "ROS_DISTRO=humble;ROS_TAG=desktop-full;UBUNTU_CODENAME=jammy"

  # app repos
  _register "${base}/app/realsense_humble" "realsense_humble" \
    "ROS_DISTRO=humble;ROS_TAG=ros-base;UBUNTU_CODENAME=jammy"
  _register "${base}/app/realsense_noetic" "realsense_noetic" \
    "ROS_DISTRO=noetic;ROS_TAG=ros-base;UBUNTU_CODENAME=focal"
  _register "${base}/app/sick_humble" "sick_humble" \
    "ROS_DISTRO=humble;ROS_TAG=ros-base;UBUNTU_CODENAME=jammy"
  _register "${base}/app/sick_noetic" "sick_noetic" \
    "ROS_DISTRO=noetic;ROS_TAG=ros-base;UBUNTU_CODENAME=focal"
  _register "${base}/app/urg_node_noetic" "urg_node_noetic" \
    "ROS_DISTRO=noetic;ROS_TAG=ros-base;UBUNTU_CODENAME=focal"

  # agent repos (no GUI, no runtime, extra files)
  _register "${base}/agent/ai_agent" "ai_agent" \
    "" "false" "false" "post_setup.sh encrypt_env.sh"
  _register "${base}/agent/claude_code" "claude_code" \
    "" "false" "false" "post_setup.sh encrypt_env.sh"
  _register "${base}/agent/codex_cli" "codex_cli" \
    "" "false" "false" "post_setup.sh encrypt_env.sh"
  _register "${base}/agent/gemini_cli" "gemini_cli" \
    "" "false" "false" "post_setup.sh encrypt_env.sh"
}

# ── Utility functions ────────────────────────────────────────────────────────

_log() { printf "[migrate] %s\n" "$*"; }
_warn() { printf "[migrate] WARNING: %s\n" "$*" >&2; }
_error() { printf "[migrate] ERROR: %s\n" "$*" >&2; exit 1; }

_parse_entry() {
  local entry="$1"
  IMAGE_NAME="${entry%%|*}"; entry="${entry#*|}"
  BUILD_ARGS="${entry%%|*}"; entry="${entry#*|}"
  HAS_GUI="${entry%%|*}"; entry="${entry#*|}"
  HAS_RUNTIME="${entry%%|*}"; entry="${entry#*|}"
  EXTRA_FILES="${entry}"
}

# ── Migration steps ──────────────────────────────────────────────────────────

_check_preconditions() {
  local repo_path="$1"

  [[ -d "${repo_path}/.git" ]] || _error "${repo_path} is not a git repository"

  if [[ -f "${repo_path}/.template_version" ]]; then
    _warn "${repo_path} already has .template_version — skipping"
    return 1
  fi

  if [[ ! -f "${repo_path}/.docker_setup_helper_version" ]]; then
    _warn "${repo_path} has no .docker_setup_helper_version — skipping"
    return 1
  fi

  # Check for clean working tree
  if ! git -C "${repo_path}" diff --quiet 2>/dev/null || \
     ! git -C "${repo_path}" diff --cached --quiet 2>/dev/null; then
    _error "${repo_path} has uncommitted changes — commit or stash first"
  fi

  return 0
}

_create_branch() {
  local repo_path="$1"
  _log "Creating branch feat/migrate-to-docker-template"
  git -C "${repo_path}" checkout -b feat/migrate-to-docker-template
}

_remove_old_subtree() {
  local repo_path="$1"
  _log "Removing docker_setup_helper subtree and old CI workflows"

  git -C "${repo_path}" rm -r docker_setup_helper/ 2>/dev/null || true
  git -C "${repo_path}" rm .docker_setup_helper_version 2>/dev/null || true
  git -C "${repo_path}" rm .github/workflows/build-worker.yaml 2>/dev/null || true
  git -C "${repo_path}" rm .github/workflows/release-worker.yaml 2>/dev/null || true

  git -C "${repo_path}" commit -m "$(cat <<'COMMIT'
refactor: remove docker_setup_helper subtree and local CI workflows

Preparation for template migration.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
COMMIT
)"
}

_add_template_subtree() {
  local repo_path="$1"
  _log "Adding template subtree (${TEMPLATE_VERSION})"

  git -C "${repo_path}" subtree add \
    --prefix=template "${TEMPLATE_REPO}" "${TEMPLATE_VERSION}" --squash
}

_create_symlinks() {
  local repo_path="$1"
  _log "Creating symlinks"

  cd "${repo_path}"

  # Remove original scripts
  git rm -f build.sh run.sh exec.sh stop.sh 2>/dev/null || true

  # Create symlinks for scripts
  ln -sf template/build.sh build.sh
  ln -sf template/run.sh run.sh
  ln -sf template/exec.sh exec.sh
  ln -sf template/stop.sh stop.sh

  # .hadolint.yaml: symlink for GUI repos, keep custom for repos with extra rules
  if [[ ! -f .hadolint.yaml ]] || diff -q .hadolint.yaml template/.hadolint.yaml >/dev/null 2>&1; then
    git rm -f .hadolint.yaml 2>/dev/null || true
    ln -sf template/.hadolint.yaml .hadolint.yaml
  else
    _log "Keeping custom .hadolint.yaml (has extra rules)"
  fi

  # Remove old shared smoke tests (keep repo-specific ones)
  git rm -f test/smoke/test_helper.bash 2>/dev/null || true
  git rm -f test/smoke/script_help.bats 2>/dev/null || true
  git rm -f test/smoke/display_env.bats 2>/dev/null || true

  git add build.sh run.sh exec.sh stop.sh .hadolint.yaml
}

_update_dockerfile() {
  local repo_path="$1" has_gui="$2"
  _log "Updating Dockerfile"

  local dockerfile="${repo_path}/Dockerfile"
  [[ -f "${dockerfile}" ]] || return 0

  # Update CONFIG_SRC path
  sed -i 's|docker_setup_helper/src/config|template/config|g' "${dockerfile}"

  # Ensure smoke tests are copied from template
  if ! grep -q "template/test/smoke" "${dockerfile}"; then
    if [[ "${has_gui}" == "true" ]]; then
      # GUI repos: copy all shared smoke tests (including display_env.bats)
      sed -i '/COPY test\/smoke_test\//i COPY template/test/smoke/ /smoke_test/' "${dockerfile}"
    else
      # Non-GUI repos: copy only script_help + test_helper (skip display_env.bats)
      sed -i '/COPY test\/smoke_test\//i COPY template/test/smoke/test_helper.bash /smoke_test/test_helper.bash\nCOPY template/test/smoke/script_help.bats /smoke_test/script_help.bats' "${dockerfile}"
    fi
  fi

  # Ensure compose.yaml is copied to /lint/ (for display_env.bats)
  if [[ "${has_gui}" == "true" ]] && ! grep -q "COPY compose.yaml /lint/compose.yaml" "${dockerfile}"; then
    sed -i '/COPY Dockerfile \/lint\/Dockerfile/a COPY compose.yaml /lint/compose.yaml' "${dockerfile}"
  fi

  git -C "${repo_path}" add Dockerfile
}

_update_readmes() {
  local repo_path="$1"
  _log "Updating READMEs (docker_setup_helper → template)"

  for f in "${repo_path}/README.md" "${repo_path}"/doc/README.*.md; do
    [[ -f "${f}" ]] || continue

    # Replace escaped markdown: docker\_setup\_helper → docker\_template
    sed -i 's/docker\\_setup\\_helper/docker\\_template/g' "${f}"

    # Replace plain text: docker_setup_helper → template
    sed -i 's/docker_setup_helper/template/g' "${f}"

    # Fix GitHub org URL: ycpss91255/template → ycpss91255-docker/template
    sed -i 's|ycpss91255/template|ycpss91255-docker/template|g' "${f}"

    # Update subtree git URL version
    sed -i "s|template\.git v[0-9.]*|template.git ${TEMPLATE_VERSION}|g" "${f}"

    # Update version in directory tree comment
    sed -i "s|git subtree (v[0-9.]*)|git subtree (${TEMPLATE_VERSION})|g" "${f}"

    # Remove duplicate main.yaml lines left by sed
    sed -i '/│   ├── main.yaml.*pipeline\|│   ├── main.yaml.*パイプライン/d' "${f}"

    # Remove old build-worker/release-worker from directory tree
    sed -i '/│   ├── build-worker.yaml/d' "${f}"
    sed -i 's|│   └── release-worker.yaml.*|│   └── main.yaml                # CI/CD (template reusable workflows)|' "${f}"

    # Remove old shared test files from directory tree
    sed -i '/│       ├── script_help.bats/d' "${f}"
    sed -i '/│       └── test_helper.bash/d' "${f}"

    # Update .docker_setup_helper_version → .template_version
    sed -i 's/\.docker_setup_helper_version/.template_version/g' "${f}"
  done

  git -C "${repo_path}" add README.md doc/ 2>/dev/null || true
}

_generate_main_yaml() {
  local repo_path="$1" image_name="$2" build_args="$3" has_runtime="$4"
  _log "Generating main.yaml with reusable workflows"

  local main_yaml="${repo_path}/.github/workflows/main.yaml"

  # Format build_args: semicolon-separated → YAML multi-line
  local args_yaml=""
  if [[ -n "${build_args}" ]]; then
    args_yaml=$(echo "${build_args}" | tr ';' '\n' | sed 's/^/        /')
    args_yaml="
    build_args: |
${args_yaml}"
  fi

  # Determine build_runtime line
  local runtime_yaml=""
  if [[ "${has_runtime}" == "false" ]]; then
    runtime_yaml="
    build_runtime: false"
  fi

  cat > "${main_yaml}" <<YAML
name: Main CI/CD Pipeline
run-name: \${{ github.actor }} triggered CI/CD on \${{ github.ref_name }}

on:
  push:
  branches:
    - main
    - master
  tags:
    - 'v*'
  pull_request:
  workflow_dispatch:

jobs:

  call-docker-build:
  permissions:
    contents: read
  uses: ycpss91255-docker/template/.github/workflows/build-worker.yaml@${TEMPLATE_VERSION}
  with:
    image_name: ${image_name}${args_yaml}${runtime_yaml}

  call-release:
  needs: call-docker-build
  if: startsWith(github.ref, 'refs/tags/')
  permissions:
    contents: write
  uses: ycpss91255-docker/template/.github/workflows/release-worker.yaml@${TEMPLATE_VERSION}
  with:
    archive_name_prefix: ${image_name}
  secrets: inherit
YAML

  git -C "${repo_path}" add .github/workflows/main.yaml
}

_add_version_file() {
  local repo_path="$1"
  _log "Adding .template_version"
  echo "${TEMPLATE_VERSION}" > "${repo_path}/.template_version"
  git -C "${repo_path}" add .template_version
}

_commit_migration() {
  local repo_path="$1"
  _log "Committing migration"

  git -C "${repo_path}" add -A
  git -C "${repo_path}" commit -m "$(cat <<'COMMIT'
feat: migrate from docker_setup_helper to template

BREAKING CHANGE: replaces docker_setup_helper subtree with template.

- Replace shell scripts with symlinks to template/ subtree
- Replace .hadolint.yaml with symlink to template/.hadolint.yaml
- Update Dockerfile CONFIG_SRC path to template/config
- Merge shared smoke tests from template/test/smoke/ in Dockerfile
- Replace local CI workflows with reusable workflows from template
- Fixes X11/Wayland support via template's run.sh

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
COMMIT
)"
}

_push_and_pr() {
  local repo_path="$1" image_name="$2"
  _log "Pushing branch and creating PR"

  git -C "${repo_path}" push -u origin feat/migrate-to-docker-template

  local pr_url
  pr_url=$(gh pr create \
    --repo "ycpss91255-docker/${image_name}" \
    --title "feat: migrate to template (v2.0.0)" \
    --body "$(cat <<PR_BODY
## Summary

- Replace \`docker_setup_helper\` subtree with \`template\` subtree
- Shell scripts (build.sh, run.sh, exec.sh, stop.sh) are now symlinks to \`template/\`
- Local CI workflows replaced with reusable workflows from \`template\`
- Fixes X11/Wayland support

## BREAKING CHANGE

Version bump to **v2.0.0** after merge.

## Test plan

- [ ] CI passes with reusable workflows
- [ ] \`./build.sh test\` passes locally
- [ ] \`./run.sh\` / \`./exec.sh\` / \`./stop.sh\` work correctly

🤖 Generated with [Claude Code](https://claude.com/claude-code)
PR_BODY
)" 2>&1)

  _log "PR created: ${pr_url}"
}

# ── Main entry point ─────────────────────────────────────────────────────────

_migrate_repo() {
  local repo_path="$1"
  repo_path="$(cd "${repo_path}" && pwd -P)"

  local entry="${REPO_REGISTRY["${repo_path}"]:-}"
  if [[ -z "${entry}" ]]; then
    _error "Unknown repo: ${repo_path}. Add it to the registry in migrate.sh."
  fi

  _parse_entry "${entry}"

  _log "═══════════════════════════════════════════════════════"
  _log "Migrating: ${repo_path}"
  _log "  IMAGE_NAME:  ${IMAGE_NAME}"
  _log "  BUILD_ARGS:  ${BUILD_ARGS:-<none>}"
  _log "  HAS_GUI:     ${HAS_GUI}"
  _log "  HAS_RUNTIME: ${HAS_RUNTIME}"
  _log "  EXTRAS:      ${EXTRA_FILES:-<none>}"
  _log "═══════════════════════════════════════════════════════"

  if ! _check_preconditions "${repo_path}"; then
    return 0
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    _log "(dry-run) Would migrate ${repo_path}"
    return 0
  fi

  _create_branch "${repo_path}"
  _remove_old_subtree "${repo_path}"
  _add_template_subtree "${repo_path}"
  _create_symlinks "${repo_path}"
  _update_dockerfile "${repo_path}" "${HAS_GUI}"
  _update_readmes "${repo_path}"
  _generate_main_yaml "${repo_path}" "${IMAGE_NAME}" "${BUILD_ARGS}" "${HAS_RUNTIME}"
  _add_version_file "${repo_path}"
  _commit_migration "${repo_path}"
  _push_and_pr "${repo_path}" "${IMAGE_NAME}"

  # Return to main branch
  git -C "${repo_path}" checkout main 2>/dev/null || git -C "${repo_path}" checkout master

  _log "Done: ${IMAGE_NAME}"
}

_list_repos() {
  printf "%-30s %-20s %-6s %-8s %s\n" "REPO" "IMAGE" "GUI" "RUNTIME" "STATUS"
  printf "%-30s %-20s %-6s %-8s %s\n" "----" "-----" "---" "-------" "------"

  for repo_path in "${!REPO_REGISTRY[@]}"; do
    _parse_entry "${REPO_REGISTRY["${repo_path}"]}"
    local status="pending"
    if [[ -f "${repo_path}/.template_version" ]]; then
      status="migrated ($(cat "${repo_path}/.template_version"))"
    elif [[ ! -d "${repo_path}" ]]; then
      status="not found"
    fi
    local short_path="${repo_path##*/docker/}"
    printf "%-30s %-20s %-6s %-8s %s\n" "${short_path}" "${IMAGE_NAME}" "${HAS_GUI}" "${HAS_RUNTIME}" "${status}"
  done | sort
}

_usage() {
  cat >&2 <<'EOF'
Usage: migrate.sh [OPTIONS] <repo_path|--all|--list>

Migrate Docker container repos from docker_setup_helper to template.

Commands:
  <repo_path>     Migrate a single repo
  --all           Migrate all registered repos
  --list          List repos and their migration status

Options:
  --dry-run       Show what would be done without making changes
  --version VER   Override template version (default: v0.1.0)
  -h, --help      Show this help

Examples:
  ./migrate.sh ../env/ros_noetic
  ./migrate.sh --dry-run --all
  ./migrate.sh --version v0.2.0 --all

To add a new repo, edit the _init_registry() function in this script.
EOF
  exit 0
}

main() {
  local cmd=""
  local base_dir="${SCRIPT_DIR}/../.."

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) _usage ;;
      --dry-run) DRY_RUN=true; shift ;;
      --version) TEMPLATE_VERSION="${2:?"--version requires a value"}"; shift 2 ;;
      --all) cmd="all"; shift ;;
      --list) cmd="list"; shift ;;
      *) cmd="single"; break ;;
    esac
  done

  _init_registry "${base_dir}"

  case "${cmd}" in
    list)
      _list_repos
      ;;
    all)
      local failed=0
      for repo_path in $(printf '%s\n' "${!REPO_REGISTRY[@]}" | sort); do
        if [[ -d "${repo_path}" ]]; then
          _migrate_repo "${repo_path}" || ((failed++)) || true
        else
          _warn "Repo not found: ${repo_path}"
        fi
      done
      _log "Migration complete. Failures: ${failed}"
      ;;
    single)
      local target="$1"
      # Resolve relative path
      target="$(cd "${target}" 2>/dev/null && pwd -P)" || _error "Directory not found: $1"
      _migrate_repo "${target}"
      ;;
    *)
      _usage
      ;;
  esac
}

main "$@"
