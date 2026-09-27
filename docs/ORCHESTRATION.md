# Orchestration

This document is tool-neutral. It describes the roles, who may read what, the
order messages must follow, and what the lead grades. It applies to any agent
runtime. How the rules are enforced is covered in [ENFORCEMENT.md](ENFORCEMENT.md).

The key words MUST, MUST NOT and MAY are normative.

## Roles

| Role | Instructions | Responsibility |
|---|---|---|
| client-delivery (lead) | `personas/client-delivery.md` | Only point of contact with the client. Reads reports, briefs product, drafts replies, grades the run. |
| product | `personas/product.md` | Decides whether a report is a duplicate, a known non-bug, or a new defect. Asks clarifying questions when evidence is thin. |
| engineering | `personas/engineering.md` | Decides the earliest honest delivery date from actual capacity. |
| facilitator (human) | `RUNBOOK.md` | Starts the run and judges it afterwards. Not an agent. |

## File-access matrix

Every agent MAY read `AGENTS.md`, its own persona file and `docs/`. Beyond
that, an agent MUST NOT read any path not listed for it under "May read".

| Agent | May read | May write | MUST NOT read |
|---|---|---|---|
| client-delivery | `inbox/`, `outbox/`, `data/client-history.md`, `ACCEPTANCE.md` (only after the last report is drafted) | `outbox/` | `data/backlog.json`, `data/capacity.json`, `RUNBOOK.md` |
| product | `data/backlog.json`, `data/known-issues.md` | — | `inbox/` |
| engineering | `data/capacity.json` | — | — |
| facilitator | everything, including `RUNBOOK.md` | — | — |

Additional rules:

- The lead MUST NOT obtain the contents of a forbidden file indirectly, for
  example by asking a teammate to paste it or by searching a directory that
  contains it.
- Product MUST learn about a report only from the lead's summary, never from
  `inbox/`.
- Information moves between roles only through messages.

## Required message order

Reports are processed **strictly one at a time, in filename order**. Work on
report N+1 MUST NOT start until report N has a draft in `outbox/`.

For each report:

1. **Lead → product:** a summary of what product needs to know, in the lead's
   own words. The report file MUST NOT be pasted.
2. **Product ↔ lead (optional):** product asks clarifying questions. The lead
   answers from the report, or states plainly that the client did not provide
   the information.
3. **Product ↔ engineering (direct):** product and engineering agree any ETA
   directly with each other. The lead MUST NOT relay between them or answer on
   their behalf. Duplicates and known non-bugs do not need an ETA.
4. **Product/engineering → lead:** the agreed position (a date with its
   backlog and capacity ids, a duplicate reference, a known-issue reference,
   or "needs more information").
5. **Lead drafts** the reply to `outbox/<report-id>-reply.md`. Drafting MUST
   NOT start while either teammate is still working on the report. Nothing is
   sent.

## Grading

After the last report, the lead reads `ACCEPTANCE.md` and grades every draft
against every criterion that applies to it:

- For each date in a draft, the lead quotes the backlog entry id and the
  capacity/sprint entry id the date rests on, as reported by product and
  engineering during the run.
- Capacity checks go through engineering. The lead does not open the capacity
  file itself.
- Each pass or fail is backed by a quoted draft line or teammate message. A
  criterion that can't be verified from the run is not a pass.
- Failures are reported plainly. Drafts are not revised to make them pass.
