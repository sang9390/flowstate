# flowstate Knowledge Graph

Cumulative concept/entity graph for this repo. One node per entity, edges list relations.

## Nodes

- **install.sh** — bash one-liner installer (`curl | bash`). Clones repo to temp dir, copies `flowstate/` to `~/.claude/skills/flowstate`. Optional engine setup via `FLOWSTATE_WITH_ENGINE=1`.
- **install.ps1** — PowerShell installer for native Windows terminals (`irm | iex`). Mirrors install.sh logic minus engine setup (engine remains manual/Git Bash on Windows).
- **setup-lemmalog.sh** — idempotent engine bootstrap: rustup → clone lemmalog → cargo build → `claude mcp add` (user scope). Unix-only assumptions (sh installer, chmod).
- **skill payload (`flowstate/`)** — SKILL.md + references/ (pure markdown). Platform-independent; works wherever Claude Code runs.
- **`irm | iex` pattern** — PowerShell equivalent of `curl | bash`; used by Scoop/Chocolatey. Bypasses ExecutionPolicy (string eval, no .ps1 on disk). Script must be self-contained (no `$PSScriptRoot`).
- **error-handling mapping** — `set -euo pipefail` ≈ `$ErrorActionPreference='Stop'` + explicit `$LASTEXITCODE` check after external commands (git).
- **install destination** — `$HOME/.claude/skills/flowstate` (unix) = `$env:USERPROFILE\.claude\skills\flowstate` (Windows). Same Claude Code convention.
- **Kimi Code CLI** — Moonshot CLI agent; reads SKILL.md skills (incl. `~/.claude/skills`), MCP config in `~/.kimi/mcp.json`. Subcommands: `kimi mcp add|list|remove|auth|reset-auth|test`. No `get` subcommand, no `--scope` (global only). Stdio add: `kimi mcp add -e KEY=VAL name command args...`.
- **CLI detection branch** — setup-lemmalog.sh picks registration path: `claude` present → `claude mcp add --scope user`; else `kimi` present → `kimi mcp add -e ...`; neither → abort. Fast-path check: `claude mcp get lemmalog` vs `kimi mcp list | grep lemmalog`.

## Edges

- install.sh —(installs)→ skill payload
- install.ps1 —(installs)→ skill payload
- install.ps1 —(mirrors, minus engine)→ install.sh
- install.ps1 —(uses)→ `irm | iex` pattern
- install.ps1 —(uses)→ error-handling mapping
- install.sh —(optionally invokes)→ setup-lemmalog.sh
- setup-lemmalog.sh —(not ported to Windows; manual path documented in README)→ install.ps1
- README.md / README.ko.md —(documents)→ install.sh, install.ps1
- setup-lemmalog.sh —(uses)→ CLI detection branch
- CLI detection branch —(registers MCP on)→ Kimi Code CLI
- skill payload —(also loadable by)→ Kimi Code CLI
