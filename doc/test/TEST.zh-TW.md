# 測試文件

**45 個測試**。

## test/smoke/claude_env.bats

### AI tools (3)

| 測試項目 | 說明 |
|----------|------|
| `claude command is available` | Claude CLI installed |
| `node is available` | Node.js runtime |
| `npm is available` | npm package manager |

### Dev tools (12)

| 測試項目 | 說明 |
|----------|------|
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

| 測試項目 | 說明 |
|----------|------|
| `user is not root` | Non-root user |
| `user can sudo` | Sudo access |
| `timezone is Asia/Taipei` | Timezone setting |
| `LANG is en_US.UTF-8` | Locale setting |
| `work directory exists` | Work dir present |
| `work directory is writable` | Work dir permissions |
| `entrypoint.sh exists` | Entrypoint script present |
| `encrypt_env.sh is in PATH` | Encryption helper in PATH |

### Excluded tools (6)

| 測試項目 | 說明 |
|----------|------|
| `gemini is NOT installed` | Single-agent: Gemini excluded |
| `codex is NOT installed` | Single-agent: Codex excluded |
| `tmux is NOT installed` | Agent containers exclude tmux |
| `vim is NOT installed` | Agent containers exclude vim |
| `fzf is NOT installed` | Agent containers exclude fzf |
| `terminator is NOT installed` | Agent containers exclude terminator |

## template/test/smoke/script_help.bats

### build.sh (3)

| 測試項目 | 說明 |
|----------|------|
| `build.sh -h exits 0` | Help flag exits successfully |
| `build.sh --help exits 0` | Long help flag exits successfully |
| `build.sh -h prints usage` | Help output contains "Usage:" |

### run.sh (3)

| 測試項目 | 說明 |
|----------|------|
| `run.sh -h exits 0` | Help flag exits successfully |
| `run.sh --help exits 0` | Long help flag exits successfully |
| `run.sh -h prints usage` | Help output contains "Usage:" |

### exec.sh (3)

| 測試項目 | 說明 |
|----------|------|
| `exec.sh -h exits 0` | Help flag exits successfully |
| `exec.sh --help exits 0` | Long help flag exits successfully |
| `exec.sh -h prints usage` | Help output contains "Usage:" |

### stop.sh (3)

| 測試項目 | 說明 |
|----------|------|
| `stop.sh -h exits 0` | Help flag exits successfully |
| `stop.sh --help exits 0` | Long help flag exits successfully |
| `stop.sh -h prints usage` | Help output contains "Usage:" |

### LANG auto-detect (4)

| 測試項目 | 說明 |
|----------|------|
| `build.sh detects zh from LANG=zh_TW.UTF-8` | Chinese locale detection |
| `build.sh detects ja from LANG=ja_JP.UTF-8` | Japanese locale detection |
| `build.sh defaults to en for LANG=en_US.UTF-8` | English default |
| `build.sh SETUP_LANG overrides LANG` | SETUP_LANG takes priority |
