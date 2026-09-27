# Platform Delivery Demo

This is a practice environment for running a small agent team through a
realistic support-triage workflow at a B2B software vendor.

## Scenario

The vendor sells a B2B platform to business clients. Clients report problems
through a support inbox. Before anything gets promised back to a client, the
team needs to work out: is this actually a bug, is it already known, and if
it's genuinely new — what can honestly be committed to given the team's
current capacity.

The team for this exercise has three roles:

- **client-delivery** — the lead. Talks to the client: reads the inbox, drafts
  the outbox. Never promises a date it hasn't actually obtained from product.
- **product** — owns the backlog and the list of known (non-bug) issues.
  Decides whether a report is new, a duplicate, or a known misconfiguration.
- **engineering** — owns team capacity. Decides what's honestly achievable
  given what's already committed.

Each role's full instructions live in `personas/<role>.md`. Roles, message
order and grading are described in [docs/ORCHESTRATION.md](docs/ORCHESTRATION.md).

## Layout

```
platform-delivery-demo/
  AGENTS.md                      this file (tool-neutral project instructions)
  CLAUDE.md                      Claude Code pointer: imports AGENTS.md
  personas/
    client-delivery.md           lead persona
    product.md                   product persona
    engineering.md               engineering persona
  docs/
    ORCHESTRATION.md             roles, access matrix, message order, grading
    ENFORCEMENT.md               access constraints as a contract + implementations
    TOOL-SPECIFIC.md             parts that only one runtime uses, and how to read them
  skills/                        tool-neutral skills (<name>/SKILL.md), if any
  scripts/                       enforcement hook scripts (Claude Code implementation)
  inbox/                         incoming client bug reports
  outbox/                        drafted (unsent) replies
  data/
    backlog.json                 product's backlog
    capacity.json                engineering's capacity
    known-issues.md              product's known-issues list
    client-history.md            client-delivery's account history
  ACCEPTANCE.md                  grading criteria for the run
  RUNBOOK.md                     how to start the run (facilitator only)
  .mcp.json                      MCP servers shared by every agent (Claude Code)
  .claude/
    settings.json                project hooks (Claude Code)
    agents/
      client-delivery.md         pointer to personas/client-delivery.md
      product.md                 pointer to personas/product.md
      engineering.md             pointer to personas/engineering.md
```

## The one rule that matters

**Each agent only reads the files its own persona assigns it.** The persona
files each name exactly which files that agent owns and may open. Do not read
a file outside your own list, even if it would be faster or you're curious
what it says — the exercise is testing whether the right information reaches
the right agent through conversation, not through everyone reading everything.

The normative file-access matrix is in
[docs/ORCHESTRATION.md](docs/ORCHESTRATION.md).

## Enforcement

How these access rules are enforced, and what happens on runtimes that can't
enforce them, is in [docs/ENFORCEMENT.md](docs/ENFORCEMENT.md).

## Agent definitions

Tool-specific agent definitions (for example `.claude/agents/*.md`) hold only
runtime metadata and a pointer to the matching `personas/` file. All
substance belongs in `personas/`.

Files and concepts that only one runtime uses are listed in
[docs/TOOL-SPECIFIC.md](docs/TOOL-SPECIFIC.md). If you are not that runtime,
don't treat them as instructions.

## Skills

Skills live in `skills/<name>/SKILL.md` at the project root.

## MCP servers (Claude Code)

- The root `.mcp.json` is reserved for servers that every agent genuinely
  needs. Servers there are inherited by every agent, and their tool
  descriptions consume context everywhere.
- A server needed by only one agent belongs inline in that agent's
  frontmatter `mcpServers` field. This scopes it to that agent and keeps its
  tool descriptions out of the main conversation.
- To strip an inherited server from an agent, add an `mcp__<server>` pattern
  to that agent's `disallowedTools` frontmatter field.
