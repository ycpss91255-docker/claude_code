# docker_template

[![Self Test](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml/badge.svg)](https://github.com/ycpss91255-docker/docker_template/actions/workflows/self-test.yaml)

Shared template for Docker container repos in the [ycpss91255-docker](https://github.com/ycpss91255-docker) organization.

[繁體中文](doc/README.zh-TW.md) | [简体中文](doc/README.zh-CN.md) | [日本語](doc/README.ja.md)

## Overview

This repo consolidates shared scripts, tests, and CI workflows used across all Docker container repos. Instead of maintaining identical files in 15+ repos, each repo pulls this template as a **git subtree** and uses symlinks.

### What's included

| File | Description |
|------|-------------|
| `build.sh` | Build containers (calls `setup.sh` for `.env` generation) |
| `run.sh` | Run containers (X11/Wayland support) |
| `exec.sh` | Exec into running containers |
| `stop.sh` | Stop and remove containers |
| `setup.sh` | Auto-detect system parameters and generate `.env` |
| `config/` | Shell configs (bashrc, tmux, terminator, pip) |
| `smoke_test/` | Shared smoke tests for consumer repos |
| `.hadolint.yaml` | Shared Hadolint rules |
| `.github/workflows/build-worker.yaml` | Reusable CI build workflow |
| `.github/workflows/release-worker.yaml` | Reusable CI release workflow |

### What stays in each repo (not shared)

- `Dockerfile`
- `compose.yaml`
- `.env.example`
- `script/entrypoint.sh`
- `doc/` and `README.md`
- Repo-specific smoke tests

## Quick Start

### Adding to a new repo

```bash
git subtree add --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash
echo "v1.0.0" > .docker_template_version
```

### Creating symlinks

```bash
# Root-level scripts
ln -sf docker_template/build.sh build.sh
ln -sf docker_template/run.sh run.sh
ln -sf docker_template/exec.sh exec.sh
ln -sf docker_template/stop.sh stop.sh
ln -sf docker_template/.hadolint.yaml .hadolint.yaml

# Smoke tests
ln -sf ../../docker_template/smoke_test/test_helper.bash test/smoke_test/test_helper.bash
ln -sf ../../docker_template/smoke_test/script_help.bats test/smoke_test/script_help.bats
# GUI repos only:
ln -sf ../../docker_template/smoke_test/display_env.bats test/smoke_test/display_env.bats
```

### Updating the subtree

```bash
git subtree pull --prefix=docker_template \
    git@github.com:ycpss91255-docker/docker_template.git main --squash \
    -m "chore: update docker_template subtree"
```

Update `.docker_template_version` to the latest tag.

## CI Reusable Workflows

Consumer repos replace local `build-worker.yaml` / `release-worker.yaml` with calls to this repo's reusable workflows:

```yaml
# .github/workflows/main.yaml
jobs:
  call-docker-build:
    uses: ycpss91255-docker/docker_template/.github/workflows/build-worker.yaml@v1
    with:
      image_name: ros_noetic
      build_args: |
        ROS_DISTRO=noetic
        ROS_TAG=ros-base
        UBUNTU_CODENAME=focal

  call-release:
    needs: call-docker-build
    if: startsWith(github.ref, 'refs/tags/')
    uses: ycpss91255-docker/docker_template/.github/workflows/release-worker.yaml@v1
    with:
      archive_name_prefix: ros_noetic
```

### build-worker.yaml inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `image_name` | string | yes | - | Container image name |
| `build_args` | string | no | `""` | Multi-line KEY=VALUE build args |
| `build_runtime` | boolean | no | `true` | Whether to build runtime stage |

### release-worker.yaml inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `archive_name_prefix` | string | yes | - | Archive name prefix |
| `extra_files` | string | no | `""` | Space-separated extra files |

## Running Tests Locally

```bash
docker compose run --rm ci
```

This runs ShellCheck + Bats tests with Kcov coverage.

## Smoke Tests

Located in `smoke_test/` — **22 tests** total.

<details>
<summary>Click to expand test details</summary>

### script_help.bats (16)

| Test | Description |
|------|-------------|
| `build.sh -h exits 0` | Help flag exits successfully |
| `build.sh --help exits 0` | Long help flag exits successfully |
| `build.sh -h prints usage` | Help output contains "Usage:" |
| `run.sh -h exits 0` | Help flag exits successfully |
| `run.sh --help exits 0` | Long help flag exits successfully |
| `run.sh -h prints usage` | Help output contains "Usage:" |
| `exec.sh -h exits 0` | Help flag exits successfully |
| `exec.sh --help exits 0` | Long help flag exits successfully |
| `exec.sh -h prints usage` | Help output contains "Usage:" |
| `stop.sh -h exits 0` | Help flag exits successfully |
| `stop.sh --help exits 0` | Long help flag exits successfully |
| `stop.sh -h prints usage` | Help output contains "Usage:" |
| `build.sh detects zh` | Auto-detect Chinese from LANG |
| `build.sh detects ja` | Auto-detect Japanese from LANG |
| `build.sh defaults to en` | Defaults to English |
| `build.sh SETUP_LANG overrides` | SETUP_LANG overrides LANG |

### display_env.bats (6)

| Test | Description |
|------|-------------|
| `compose.yaml contains WAYLAND_DISPLAY` | Wayland env var present |
| `compose.yaml contains XDG_RUNTIME_DIR` | XDG runtime dir present |
| `compose.yaml contains XAUTHORITY` | X authority present |
| `compose.yaml mounts XDG_RUNTIME_DIR` | Volume mount present |
| `compose.yaml mounts XAUTHORITY` | Volume mount present |
| `compose.yaml mounts X11-unix` | X11 socket mount present |

</details>

## Directory Structure

```
docker_template/
├── build.sh                          # Shared build script
├── run.sh                            # Shared run script (X11/Wayland)
├── exec.sh                           # Shared exec script
├── stop.sh                           # Shared stop script
├── setup.sh                          # .env generator
├── config/                           # Shell/tool configs
│   ├── pip/
│   └── shell/
│       ├── bashrc
│       ├── terminator/
│       └── tmux/
├── smoke_test/                       # Shared tests for consumer repos
│   ├── test_helper.bash
│   ├── script_help.bats
│   └── display_env.bats
├── test/                             # Template self-tests (114 tests)
├── compose.yaml                      # Local CI runner
├── .hadolint.yaml                    # Shared Hadolint rules
├── .github/workflows/
│   ├── self-test.yaml                # Template CI
│   ├── build-worker.yaml             # Reusable build workflow
│   └── release-worker.yaml           # Reusable release workflow
├── .codecov.yaml
├── .gitignore
├── LICENSE
├── README.md
├── doc/
└── TEST.md
```
