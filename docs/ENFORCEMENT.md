# Enforcement

This document is a contract. Section 1 states the constraints independently
of any agent runtime. Each later section is one implementation of that
contract for a specific runtime. To support another runtime, add a new
section; section 1 does not change.

---

## 1. Contract

These constraints are **enforced** only on a runtime that can intercept an
agent's tool calls before they execute. **On a runtime without an enforcement
mechanism, these constraints degrade from enforced to advisory:** they are
still binding through the persona instructions and `docs/ORCHESTRATION.md`,
but nothing stops a violation, and it can only be caught afterwards by
reviewing the transcript.

### C1. The lead must be prevented from reading owner-only files

The client-delivery lead MUST be prevented from reading:

- `data/backlog.json` (owned by product)
- `data/capacity.json` (owned by engineering)
- `RUNBOOK.md` (owned by the human facilitator)

This covers every way of getting at their contents: direct file reads,
content searches whose scope includes these files, and shell commands that
reference them. It applies only to the lead. Product and engineering MUST
still be able to read the files they own.

- **Violation:** the lead's tool call targets one of these files, or searches
  a directory that contains one, or runs a shell command naming one.
- **Detection:** the call is intercepted before it runs, checked against the
  three paths (resolved to absolute form, and including ancestor directories
  for searches), and refused with an explanation back to the lead. As a
  fallback, a reviewer can spot it in the run transcript: any tool call by the
  lead naming these paths.

### C2. Agent definition bodies must not hold substance

Runtime-specific agent definition files MUST contain only runtime metadata
(frontmatter) plus a body of exactly two lines:

1. an instruction to read the matching `personas/<name>.md` file and follow
   it fully;
2. a hard-fail rule: if that file cannot be read, stop immediately and report
   the failure rather than improvising.

All behavioural substance lives in `personas/`, so every runtime gets the
same instructions.

- **Violation:** any write that leaves an agent definition body containing
  anything other than those two lines, or a partial edit that can't be checked
  against the whole resulting file.
- **Detection:** writes to agent definition files are intercepted before they
  run. The proposed whole-file content is parsed, and the body after the
  frontmatter is compared with the two expected lines. Partial edits are
  refused so that every change arrives as a full file that can be checked. As
  a fallback, a reviewer can compare each definition body with the expected
  two lines.

---

## 2. Implementation: Claude Code

This section is **one implementation** of the contract in section 1. It uses
Claude Code `PreToolUse` hooks.

### Exit code semantics

Each hook script receives the pending tool call as JSON on stdin.

| Exit code | Meaning |
|---|---|
| `0` | Allow the tool call. |
| `2` | Block the tool call. stderr is returned to the agent as the reason. |
| other | Non-blocking error: the call **proceeds**. |

Because any code other than 2 lets the call through, both guards exit `2` if
`jq` is missing. A guard that can't check a call blocks it rather than
allowing it.

### C1 → `scripts/guard-lead-reads.sh`

| | |
|---|---|
| Registered in | `.claude/agents/client-delivery.md` frontmatter, `hooks.PreToolUse` |
| Matcher | `Read\|Grep\|Bash` |
| Target field | `Read`: `.tool_input.file_path` · `Grep`: `.tool_input.path` · `Bash`: `.tool_input.command` |
| Blocks when | the resolved path is one of the three files; for `Grep`, the path is empty or a directory containing one of them; for `Bash`, the command mentions one of the file names (case-insensitive) |

**Why it is registered in the lead's frontmatter rather than
`settings.json`:** hooks in `settings.json` apply session-wide, to every
agent. A read guard there would also block product from `data/backlog.json`
and engineering from `data/capacity.json`, the files they own. Frontmatter
hooks apply only while that agent is running, which scopes the guard to the
lead. The lead is started with `claude --agent client-delivery` so that the
main session runs as that agent.

### C2 → `scripts/guard-agent-bodies.sh`

| | |
|---|---|
| Registered in | `.claude/settings.json`, `hooks.PreToolUse` |
| Matcher | `Edit\|Write` |
| Applies to | paths matching `.claude/agents/*.md` (any other path: exit 0) |
| `Write` | parses `.tool_input.content`; after the closing frontmatter `---`, the non-blank lines must be exactly the pointer and hard-fail lines for that file's basename; otherwise exit 2. Frontmatter is not checked and stays freely editable. |
| `Edit` | always exit 2; frontmatter changes must be made by rewriting the whole file with `Write`, so the body can be validated. |

This guard is session-wide on purpose: no agent should be able to put
substance into an agent definition.

### Debugging

`scripts/hook-input-debug.sh` appends the raw hook input to
`.claude/hook-input.log` and always exits 0. It is not registered by default.
Add it temporarily as an extra hook to see exactly what a guard receives.

### Known gaps

- Writes to agent definition files made through `Bash` (for example shell
  redirection) are not intercepted by the C2 guard.
- The C1 `Bash` check is a substring match. Globs such as `data/*.json` get
  past it. The lead's tool list does not include `Bash`, so this is a second
  line of defence only.
- `Glob` is not guarded. It returns file names, not contents.

---

<!-- Add "## 3. Implementation: <runtime>" here for another runtime. -->
