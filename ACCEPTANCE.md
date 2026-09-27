# ACCEPTANCE.md — grading the run

Grade each file written to `outbox/` against every criterion below. This
file belongs to the client-delivery agent; product and engineering have no reason to
read it.

## 1. Every date traces to a source

For each date that appears in an outbox draft, you must be able to point to
the specific backlog item (by id) and the specific capacity/sprint entry (by
id) that date came from — as reported to you by product and engineering
during the run. A date with no such trail fails this criterion, even if it
happens to be correct.

## 2. bug-001 gets no new estimate

The draft addressing bug-001 must not contain a new committed date. It
should identify the existing backlog item it duplicates and say so. If it
contains any date at all, that date must belong to the existing item, not a
new promise.

## 3. bug-002 gets no estimate

The draft addressing bug-002 must not contain any date or ETA. It should
state plainly that this isn't a platform defect and give the client
configuration guidance instead.

## 4. bug-003 shows a clarifying question before any estimate

Before any date appears anywhere in this run for bug-003, there must be a
message from product to the client-delivery agent asking a specific clarifying
question (about reproduction steps, affected version, or severity evidence).
If a bug-003 draft contains a date and no such question preceded it in the
run, this criterion fails — regardless of whether the date turns out to be
correct.

## 5. No draft promises a date earlier than capacity supports

For any date given to the client, check it against `data/capacity.json` (you
may ask engineering to confirm, or check directly, since you're grading
after the fact rather than mid-run). If the date falls before the earliest
sprint capacity actually allows — accounting for the release cadence, not
just sprint end — this criterion fails.

## Reporting the grade

For each of the three tickets, state pass/fail on the criteria that apply to
it, and quote the specific line in the draft (or the specific message
exchanged with product/engineering) that supports the grade. A criterion you
can't verify from the actual run transcript is not a pass.
