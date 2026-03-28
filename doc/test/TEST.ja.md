# テストドキュメント

**55 件のテスト**。

## test/smoke_test/claude_env.bats

### AI tools (3)

| テスト項目 | 説明 |
|------------|------|
| `claude command is available` | Claude CLI installed |
| `node is available` | Node.js runtime |
| `npm is available` | npm package manager |

### Dev tools (12)

| テスト項目 | 説明 |
|------------|------|
| `git is available` | Version control |
| `python3 is available` | Python interpreter |
| `make is available` | Build tool |
| `cmake is available` | Build system generator |
| `g++ is available` | C++ compiler |
| `curl is available` | HTTP client |
| `wget is available` | HTTP client |
| `jq is available` | JSON processor |
| `rg (ripgrep) is available` | Fast search tool |
| `tree is available` | Directory listing |
| `docker is available` | Container runtime |
| `gpg is available` | Encryption tool |

### System (8)

| テスト項目 | 説明 |
|------------|------|
| `user is not root` | Non-root user |
| `user can sudo` | Sudo access |
| `timezone is Asia/Taipei` | Timezone setting |
| `LANG is en_US.UTF-8` | Locale setting |
| `work directory exists` | Work dir present |
| `work directory is writable` | Work dir permissions |
| `entrypoint.sh exists` | Entrypoint script present |
| `encrypt_env.sh is in PATH` | Encryption helper in PATH |

### Excluded tools (6)

| テスト項目 | 説明 |
|------------|------|
| `gemini is NOT installed` | Single-agent: Gemini excluded |
| `codex is NOT installed` | Single-agent: Codex excluded |
| `tmux is NOT installed` | Agent containers exclude tmux |
| `vim is NOT installed` | Agent containers exclude vim |
| `fzf is NOT installed` | Agent containers exclude fzf |
| `terminator is NOT installed` | Agent containers exclude terminator |

## docker_template/test/smoke_test/display_env.bats

### Wayland env vars (3)

| テスト項目 | 説明 |
|------------|------|
| `compose.yaml contains WAYLAND_DISPLAY env` | Wayland display variable |
| `compose.yaml contains XDG_RUNTIME_DIR env` | XDG runtime directory |
| `compose.yaml contains XAUTHORITY env` | X authority variable |

### Wayland volume mounts (3)

| テスト項目 | 説明 |
|------------|------|
| `compose.yaml mounts XDG_RUNTIME_DIR volume` | Runtime dir mount |
| `compose.yaml mounts XAUTHORITY volume` | Xauthority mount |
| `compose.yaml mounts X11-unix volume` | X11 socket mount |

### xhost branching (4)

| テスト項目 | 説明 |
|------------|------|
| `run.sh contains XDG_SESSION_TYPE check` | Session type detection |
| `run.sh calls xhost +SI:localuser on wayland` | Wayland xhost call |
| `run.sh calls xhost +local: on X11` | X11 xhost call |
| `run.sh defaults to X11 xhost when XDG_SESSION_TYPE unset` | Default fallback to X11 |

## docker_template/test/smoke_test/script_help.bats

### build.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `build.sh -h exits 0` | Help flag exits successfully |
| `build.sh --help exits 0` | Long help flag exits successfully |
| `build.sh -h prints usage` | Help output contains "Usage:" |

### run.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `run.sh -h exits 0` | Help flag exits successfully |
| `run.sh --help exits 0` | Long help flag exits successfully |
| `run.sh -h prints usage` | Help output contains "Usage:" |

### exec.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `exec.sh -h exits 0` | Help flag exits successfully |
| `exec.sh --help exits 0` | Long help flag exits successfully |
| `exec.sh -h prints usage` | Help output contains "Usage:" |

### stop.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `stop.sh -h exits 0` | Help flag exits successfully |
| `stop.sh --help exits 0` | Long help flag exits successfully |
| `stop.sh -h prints usage` | Help output contains "Usage:" |

### LANG auto-detect (4)

| テスト項目 | 説明 |
|------------|------|
| `build.sh detects zh from LANG=zh_TW.UTF-8` | Chinese locale detection |
| `build.sh detects ja from LANG=ja_JP.UTF-8` | Japanese locale detection |
| `build.sh defaults to en for LANG=en_US.UTF-8` | English default |
| `build.sh SETUP_LANG overrides LANG` | SETUP_LANG takes priority |
