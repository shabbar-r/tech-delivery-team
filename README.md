# Tech Delivery Team

A small multi-agent team that triages client bug reports the way a careful
B2B software vendor would. It checks whether a report is really a bug,
whether it's already known, and what delivery date can honestly be promised
before anything goes back to the client.

The project is also a working example of a **tool-neutral agent project**. All
behaviour lives in plain Markdown that any agent runtime can read. Claude Code
is wired in through thin pointer files and hooks that enforce the rules.

> **Status:** practice/demo environment. The inbox, backlog, capacity and
> client history are fictional fixtures. Replies are drafted, never sent.

---

## Contents

- [Why this exists](#why-this-exists)
- [How it works](#how-it-works)
- [Project structure](#project-structure)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Rule enforcement](#rule-enforcement)
- [Working with other agent tools](#working-with-other-agent-tools)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Why this exists

When a client reports a problem, the tempting reply is a reassuring date. The
honest reply depends on things the client-facing person usually can't see:

- **Is it already tracked?** Duplicates shouldn't get a new promise.
- **Is it a bug at all?** Many "defects" are configuration or expected
  behaviour.
- **Is there capacity?** Priority says what matters; capacity says when there
  is actually room to do the work.

This project models that as three agents with **deliberately separated
knowledge**. The right answer can only be reached if the right information
passes between them through conversation. No agent can shortcut by reading
everything.

## How it works

### The team

| Agent | Role | Owns |
|---|---|---|
| **client-delivery** (lead) | The only one who talks to the client. Reads reports, briefs product, drafts replies, grades the run. | `inbox/`, `outbox/`, client history |
| **product** | Decides whether a report is a duplicate, a known non-bug, or a genuine new defect. Asks clarifying questions when the evidence is thin. | Backlog, known-issues list |
| **engineering** | Decides the earliest date the team can *honestly* deliver, given what's already committed. Pushes back on optimistic dates. | Capacity and release cadence |

### The flow for each report

```
            ┌──────────────────────┐
 inbox/ ──▶ │   client-delivery    │ ──▶ outbox/  (draft only, never sent)
            └──────────┬───────────┘
                       │ 1. brief (summary, never the raw file)
                       ▼        ▲ 2. clarifying questions (if needed)
            ┌──────────────────────┐
            │       product        │  duplicate? known issue? new defect?
            └──────────┬───────────┘
                       │ 3. agree the ETA directly
                       ▼        ▲    (the lead does not relay)
            ┌──────────────────────┐
            │     engineering      │  earliest honest date from capacity
            └──────────────────────┘
                 4. agreed position back to the lead → 5. lead drafts reply
```

- Reports are processed **strictly one at a time, in order**.
- The lead **never writes a date** that product and engineering didn't agree.
  It doesn't round dates earlier, and it doesn't fill gaps with reassurance.
- Duplicates point to the existing item, and known non-bugs get configuration
  guidance. Neither gets a new date.
- If a report is too vague to estimate, product asks specific questions
  first, and the draft asks the client for exactly that information.
- After the last report, the lead grades the run against `ACCEPTANCE.md`. It
  quotes the backlog and capacity ids behind every date, and it **never
  revises a draft to make it pass**.

The full protocol and access rules are in
[docs/ORCHESTRATION.md](docs/ORCHESTRATION.md).

## Project structure

```
AGENTS.md                 tool-neutral project instructions (source of truth for agents)
CLAUDE.md                 Claude Code pointer: "@AGENTS.md"
README.md                 this file (for humans)

personas/                 what each agent does, as plain Markdown
  client-delivery.md
  product.md
  engineering.md

docs/
  ORCHESTRATION.md        roles, file-access matrix, message order, grading
  ENFORCEMENT.md          access rules as a runtime-independent contract + implementations
  TOOL-SPECIFIC.md        which parts are Claude Code-only, and how other tools should treat them

data/                     fixtures: backlog, capacity, known issues, client history
inbox/                    incoming client reports (fixtures)
outbox/                   drafted replies (generated per run, git-ignored)
ACCEPTANCE.md             grading criteria
RUNBOOK.md                facilitator guide: how to start a run and judge it

scripts/                  hook scripts that enforce the rules (Claude Code implementation)
.claude/
  settings.json           project-wide hook (keeps agent definitions pointer-only)
  agents/*.md             Claude Code agent definitions: metadata + pointer to personas/
.mcp.json                 MCP servers shared by all agents (intentionally empty)
```

**The layering in one sentence:** the *substance* (`AGENTS.md`, `personas/`,
`docs/`) is tool-neutral; the *wiring* (`CLAUDE.md`, `.claude/`, `scripts/`) is
tool-specific and only points at the substance.

## Requirements

| Dependency | Why | Notes |
|---|---|---|
| [Claude Code](https://docs.claude.com/en/docs/claude-code) | Runs the agent team | Tested with 2.1.283 |
| Agent teams (experimental) | Lets product and engineering message each other directly | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| `bash`, GNU coreutils | Hook scripts | Uses `realpath -m`. On macOS, install `coreutils`. |
| [`jq`](https://jqlang.github.io/jq/) 1.6+ | Hook scripts parse tool-call JSON | **Required.** Without it, the guards block every call they check. |
| `git` | Version control | — |

Linux, WSL and macOS (with GNU coreutils) should all work. The project has
been run on Ubuntu 24.04 under WSL2.

## Getting started

```bash
git clone https://github.com/shabbar-r/tech-delivery-team.git
cd tech-delivery-team

# 1. make sure jq is available
jq --version

# 2. enable agent teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# 3. start Claude Code as the lead agent
claude --agent client-delivery
```

Then type:

```
begin
```

The lead creates the team, works through every report in `inbox/`, writes
drafts to `outbox/`, and finishes with a graded report. Start each run in a
fresh session. Clear `outbox/` between runs for a clean result.

If you're facilitating the exercise, read `RUNBOOK.md` *after* a run. It
contains the answer key. Don't paste it into the session.

## Rule enforcement

The access rules aren't left to good behaviour alone.

| Rule | How it's enforced (Claude Code) |
|---|---|
| The lead must never read the backlog, capacity or runbook files, whether directly, through a broad search, or from the shell | `scripts/guard-lead-reads.sh`: a `PreToolUse` hook registered **only** in the lead's agent definition, so product and engineering can still read their own files |
| Agent definition files must stay pointer-only, with all behaviour in `personas/` | `scripts/guard-agent-bodies.sh`: a project-wide `PreToolUse` hook on `Edit`/`Write` |

Both guards **fail closed**: if they can't check a call, they block it. On a
runtime without equivalent hooks, the same rules still apply as instructions
but are only *advisory*. The contract, the implementation details and the
known gaps are in [docs/ENFORCEMENT.md](docs/ENFORCEMENT.md).

## Working with other agent tools

Any agent tool that reads `AGENTS.md` can understand and work on this project:

- Instructions: `AGENTS.md` plus the relevant file in `personas/`.
- Protocol and access rules: `docs/ORCHESTRATION.md`.
- Tool-specific files other tools should **not** treat as instructions:
  [docs/TOOL-SPECIFIC.md](docs/TOOL-SPECIFIC.md). This covers `CLAUDE.md`,
  `.claude/`, the hook scripts, and the Claude-specific launch and
  agent-team wording.

To run the team on another runtime, give each agent `AGENTS.md` plus its
persona. To enforce the rules there, add an implementation section to
`docs/ENFORCEMENT.md`; the contract itself stays unchanged.

## Testing

Guard scripts can be tested without starting an agent by piping in a sample
hook input:

```bash
export CLAUDE_PROJECT_DIR=$PWD

# expect exit 2 (blocked): the lead reading the backlog
echo "{\"cwd\":\"$PWD\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$PWD/data/backlog.json\"}}" \
  | scripts/guard-lead-reads.sh; echo "exit $?"

# expect exit 0 (allowed): the lead reading a report
echo "{\"cwd\":\"$PWD\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$PWD/inbox/bug-001.md\"}}" \
  | scripts/guard-lead-reads.sh; echo "exit $?"
```

To see exactly what a hook receives in a live session, temporarily register
`scripts/hook-input-debug.sh` alongside a guard. It appends the raw input to
`.claude/hook-input.log`, which is git-ignored.

## Roadmap

Everything below is **planned, not implemented**.

### External connectors

The fixtures in `inbox/` and `data/` are placeholders for live systems. Each
connector would be attached **only to the agent that owns that data**, using
per-agent MCP configuration rather than the shared `.mcp.json`. That keeps the
knowledge separation intact and each agent's context lean.

| Source | Replaces | Attached to |
|---|---|---|
| Support email / shared inbox | `inbox/` | client-delivery |
| Helpdesk / ticketing (e.g. Zendesk, Freshdesk) | `inbox/`, client history | client-delivery |
| Issue tracker / backlog (e.g. Jira, Linear, GitHub Issues) | `data/backlog.json` | product |
| Knowledge base / docs | `data/known-issues.md` | product |
| Sprint and capacity planning | `data/capacity.json` | engineering |
| CRM / account notes | `data/client-history.md` | client-delivery |

Replies would stay **drafts that a human approves** before sending. A
connector that sends would be separate and gated by approval.

### Learning from human feedback

The goal is for the team to get better at a given client and project over
time, without giving up the honesty rules that make it trustworthy.

- **Feedback capture:** a human reviews each draft and grade and records
  structured feedback: what was right, what was wrong, and why.
- **Per-role lessons:** feedback is turned into short, reviewable lessons per
  role (for example "this client's 'critical' usually means a single user is
  affected"). They are stored as neutral files beside each persona, so every
  runtime benefits.
- **Humans approve changes:** agents may *propose* changes to personas or
  lessons. Changes land only through a reviewed pull request. They may make
  behaviour sharper but never weaker than the contract in
  `docs/ENFORCEMENT.md` and `docs/ORCHESTRATION.md`.
- **Agent memory:** runtime-native memory (for example Claude Code agent
  memory, git-ignored here) holds working context between runs. Anything
  durable graduates into the reviewed lesson files.
- **Regression checks:** every accepted change is replayed against the fixture
  scenarios and `ACCEPTANCE.md`, so that a lesson which fixes one case can't
  quietly break another.

### Other ideas

- Enforcement sections for further agent runtimes in `docs/ENFORCEMENT.md`.
- More fixture scenarios: conflicting capacity, reopened bugs, multi-client
  impact.
- An automated run harness that replays scenarios and records grades over
  time.

## Contributing

Issues and pull requests are welcome. Please keep to the project's structure:

1. **Behaviour goes in `personas/`, never in `.claude/agents/`.** A hook
   blocks any agent definition body that is more than its two-line pointer.
2. **Rules are stated once.** Put access rules in `docs/ORCHESTRATION.md` and
   enforcement contracts in `docs/ENFORCEMENT.md`; link to them rather than
   restating them.
3. **Anything tool-specific** goes in the wiring layer and gets an entry in
   `docs/TOOL-SPECIFIC.md`.
4. **Fixtures are only changed on purpose.** `data/`, `inbox/` and
   `ACCEPTANCE.md` define the exercise.

## License

No license has been chosen yet. Until one is added, all rights are reserved by
the author. Open an issue if you'd like to reuse the material.
