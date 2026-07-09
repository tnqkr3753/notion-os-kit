# Today Summary Reconciliation

Use this workflow to reconcile one local day of coding-agent work back into
Notion OS Workstreams and Tickets.

## Source Evidence

- Collect local coding-agent sessions for the target local day.
- Include session id, platform, cwd/repo clue, first/last prompt clue, update time,
  and token usage when available.
- Keep raw transcripts private unless a specific quote or command output is needed
  to justify a Notion update.

## Mapping Rules

- Map work to the most specific existing Workstream first.
- Update existing Tickets when the session clearly corresponds to tracked work.
- Create new Ticket candidates only for concrete follow-ups or work discovered
  during the day.
- Use Workstream progress notes when work spans several Tickets.
- Use Knowledge only for durable decisions, references, or reusable learnings.
- Keep Tickets under Workstreams. Do not add direct operational Project-Ticket
  mappings.

## Interview Rules

Ask one question at a time when the answer changes:

- Workstream selection
- existing Ticket vs new Ticket
- Ticket status change
- Workstream progress note vs Knowledge
- whether evidence is strong enough to mark work complete

Every question should include a recommended answer and the evidence behind it.

## Verification

Before writing, run `doctor` for the profile. After writing, fetch changed
Workstreams/Tickets and verify title, relation, status/progress, and body notes.
