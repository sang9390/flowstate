# flowstate

**English** | [한국어](README.ko.md)

A state-management + instruction-pipeline skill for Claude Code.

Every task instruction flows through a 7-stage pipeline (intake → spec → resolution → plan → execute → record → handoff). Facts and decisions learned along the way are recorded in `.flowstate/facts.md`, one fact per line. Refuted facts are never deleted — they are retired (moved to a RETIRED section with a reason and timestamp) — and shorthand instructions like "that function we fixed earlier" are resolved from the fact store and code-structure analysis instead of guessing.

The design borrows from [Lemmalog](https://github.com/JordyZomer/lemmalog), a Datalog engine for LLM agent memory. When the engine is installed, the skill delegates to it automatically (incremental invalidation, proof trees, conflict detection). Without it, the skill runs in pure file mode.

## Install

### Ubuntu / macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | bash
```

With the lemmalog engine (optional — installs rustup ~1.5GB and builds for a few minutes):

```bash
curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | FLOWSTATE_WITH_ENGINE=1 bash
```

### Windows

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/sang9390/flowstate/main/install.ps1 | iex
```

The engine setup script is bash-only — on Windows, run `scripts/setup-lemmalog.sh` from Git Bash or WSL.

The skill activates in new `claude` sessions automatically. You can also invoke it directly with `/flowstate`.

## Layout

```
flowstate/
├── SKILL.md                      # 7-stage pipeline body
├── references/
│   ├── fact-protocol.md          # fact line format + retraction rules
│   └── handoff-template.md       # session handoff template
└── scripts/
    └── setup-lemmalog.sh         # one-shot engine setup (idempotent)
```

## File mode vs engine mode

| | File mode (default) | Engine mode (lemmalog) |
|---|---|---|
| Requirements | none | Rust toolchain (installed by the script) |
| Fact storage | `.flowstate/facts.md` | facts.md + `.flowstate/lemmalog.snapshot` (isolated per project) |
| Extras | — | automatic conflict detection, proof trees (why), µs queries over large fact sets |

Benchmark results (7 scenarios plus a 12-session long-horizon scenario, LLM-judged): plain Claude Code without the skill scored 62/70; flowstate scored 70/70. File and engine modes tied up to the 12-session scale — file mode is enough for everyday work, and the engine pays off on long-running projects with thousands of facts.

## How it works

- **Every instruction goes through the same pipeline** — clear instructions pass through at near-zero cost; vague ones get a deeper resolution stage (fact-store lookup → filesystem/code analysis → ask the user only as a last resort)
- **Adaptive gate** — stops for confirmation only on destructive/irreversible actions or scope expansion
- **Retraction discipline** — when a decision changes, the old fact moves to RETIRED (with reason and timestamp), derived facts are retracted in cascade, and premises are tracked via `premised_on`
- **Environment variable** — `FLOWSTATE_NO_SETUP=1` skips the automatic engine setup

## License

MIT. Lemmalog is also MIT (JordyZomer/lemmalog).
