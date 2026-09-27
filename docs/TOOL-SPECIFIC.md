# Tool-specific parts of this project

Most of this project is tool-neutral: `AGENTS.md`, `personas/`, `docs/`,
`ACCEPTANCE.md`, `inbox/`, `outbox/` and `data/` mean the same thing to any
agent runtime.

A few parts can't be made neutral, because they exist only to wire the
project into a particular runtime (currently Claude Code). This document lists
them so that other agent tools can:

- recognise them and **not treat them as instructions or content to process**;
- still understand what they do, and find the neutral source they point to.

If you are an agent on a runtime other than Claude Code, the short version:
**your instructions are `AGENTS.md` plus your `personas/<role>.md` file. Ignore
everything listed below as input. Read it only to understand the setup.**

## Summary

| Path / concept | Runtime | Neutral source of truth | Other tools should |
|---|---|---|---|
| `CLAUDE.md` | Claude Code | `AGENTS.md` | Ignore. It only imports `AGENTS.md`. |
| `.claude/agents/*.md` | Claude Code | `personas/*.md` | Ignore. They hold runtime metadata plus a pointer to the persona. |
| `.claude/settings.json` | Claude Code | `docs/ENFORCEMENT.md` §1 | Ignore. It registers the agent-body guard hook. |
| `scripts/*.sh` | Claude Code hooks | `docs/ENFORCEMENT.md` §1 | Do not execute as part of a run. Read only as a reference implementation. |
| `.mcp.json` | Claude Code (format shared by some other tools) | `AGENTS.md` → MCP servers | Use only if your runtime reads this format. It is empty today. |
| `@AGENTS.md` import syntax | Claude Code | `AGENTS.md` | Read `AGENTS.md` directly. |
| "Agent team", "agent type", teammates messaging each other directly | Claude Code agent teams (experimental) | `docs/ORCHESTRATION.md` → message order | Map to your runtime's closest equivalent (see below). |
| `skills/` at the root | Neutral location; Claude Code does not discover it | `skills/<name>/SKILL.md` | Use it if your runtime supports skills. |
| `.claude/agent-memory/`, `.claude/hook-input.log`, `.claude/settings.local.json` | Claude Code local state | — | Ignore. They are git-ignored. |

## Details

### `CLAUDE.md`

Contains only `@AGENTS.md`. Claude Code loads `CLAUDE.md` automatically, and
`@path` is its import syntax. Other tools that read `AGENTS.md` natively need
nothing from this file.

### `.claude/agents/*.md`

Claude Code agent definitions. Each has two parts:

- **YAML frontmatter:** Claude Code metadata such as `name`, `description`,
  `tools` (Claude Code tool names like `Read`, `Grep`, `SendMessage`, `Agent`),
  and `hooks` for the lead. Other runtimes may define `mcpServers` and
  `disallowedTools` here too. None of these field names or tool names mean
  anything elsewhere.
- **Body:** exactly two lines, pointing to `personas/<name>.md` plus a
  hard-fail rule. A hook enforces this (see `docs/ENFORCEMENT.md`), so the body
  never holds real instructions.

The behavioural content for every role is in `personas/`. Build your
runtime's agent definitions from there, not from these files.

### Enforcement: `.claude/settings.json`, `scripts/`, frontmatter `hooks`

The access rules in `docs/ORCHESTRATION.md` and the constraints in
`docs/ENFORCEMENT.md` §1 are tool-neutral. The **mechanism** that enforces
them is not. It uses Claude Code `PreToolUse` hooks:

- `scripts/guard-lead-reads.sh` is registered in the lead's frontmatter. It
  stops the lead reading the backlog, capacity and runbook files.
- `scripts/guard-agent-bodies.sh` is registered in `.claude/settings.json`. It
  keeps agent definition bodies pointer-only.
- `scripts/hook-input-debug.sh` is a debugging aid.

The scripts read Claude Code's hook JSON on stdin and rely on its exit code
contract (0 allows, 2 blocks), and they need `jq`. **On a runtime without
comparable interception, these rules are advisory:** agents must follow them
from their persona instructions, and violations can only be found by
reviewing the transcript. To enforce them on another runtime, add an
implementation section to `docs/ENFORCEMENT.md`. Do not change §1.

### Agent teams and direct messaging

`personas/client-delivery.md` tells the lead to create an **agent team (not
subagents)**, with teammates `product` and `engineering`. It also requires
product and engineering to **message each other directly**. These wordings
come from Claude Code's experimental agent-teams feature:

- a teammate is a separate, long-lived agent session;
- teammates can message each other without going through the lead;
- a subagent is a one-shot helper that reports only to its caller.

The neutral requirement behind the wording (see `docs/ORCHESTRATION.md`) is:

1. product and engineering are separate agents with separate file access;
2. they agree an ETA between themselves, and the lead does not relay or
   answer for them;
3. the lead waits for their agreed position.

On a runtime without peer-to-peer messaging, requirement 2 **cannot be met as
written**. The nearest fallback is a shared channel that all three can see,
where the lead stays silent while product and engineering converge. Record any
such deviation in the grading report.

### `.mcp.json` and MCP scoping

`.mcp.json` uses the MCP server configuration format that Claude Code reads.
Some other tools read it too. The scoping guidance in `AGENTS.md` describes
Claude Code behaviour:

- servers in the root file are inherited by every agent;
- per-agent `mcpServers` in frontmatter;
- `disallowedTools: mcp__<server>`.

Another runtime may scope servers differently. The intent is portable: give a
server only to the agents that need it.

### `skills/`

Skills live in `skills/<name>/SKILL.md` at the root, so no single tool owns
them. Claude Code only auto-discovers skills in `.claude/skills/`. If skills
are added, Claude Code needs a symlink (`.claude/skills -> ../skills`) or
similar. There are no skills today.

### Launch command

`RUNBOOK.md` starts the run with `claude --agent client-delivery` and the
environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Both are
Claude Code specific. On another runtime:

1. start a session whose instructions are `AGENTS.md` plus
   `personas/client-delivery.md`;
2. make sure it can start the product and engineering agents defined by
   `personas/product.md` and `personas/engineering.md`;
3. send `begin`.
