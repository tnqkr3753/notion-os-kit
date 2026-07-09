---
title: Notion OS Generation-First Skills
tags: decision, notion, notion-os-kit, skills
date: 2026-07-08
---

# Notion OS Generation-First Skills

## Decision

Notion OS profile automation should use a **generation-first** skill model.
Agents should create the correct Notion page directly when the target database
and required relations are clear. Agents should ask concise grill-me-style
questions only when missing information would create the wrong database row,
wrong relation, or wrong page split.

## Skill Structure

The skill system is split into:

- `<profile-name>`: integrated orchestrator for routing, interview gating, relation
  guardrails, template selection, and verification.
- `<profile-name>-area`: Area creation and organization.
- `<profile-name>-project`: Project creation and Project-level views.
- `<profile-name>-workstream`: Workstream creation and Workstream-level views.
- `<profile-name>-ticket`: Ticket creation under Workstreams.
- `<profile-name>-meeting`: Meeting capture, meeting prep, decisions, and action items.
- `<profile-name>-knowledge`: durable Knowledge capture.
- `<profile-name>-inbox`: raw capture for unresolved classification.
- `<profile-name>-today-summary`: daily reconciliation from coding-agent
  sessions into Workstream and Ticket updates.

Public examples live under:

```text
examples/<profile-name>/
```

Concrete profile implementation references live outside the public repo under:

```text
~/.notion-os-kit/profiles/<profile-name>/
```

Runtime Notion IDs and live deployment state also live outside the repo:

```text
~/.notion-os-kit/profiles/<profile-name>/state.local.yaml
```

## Operating Rules

- Preserve the `Area -> Project -> Workstream -> Ticket` model.
- Do not create direct operational Project-Ticket mappings.
- Prefer Workstream-level Ticket creation.
- Attach Meetings to Workstreams when specific, otherwise Projects.
- Attach Knowledge to the most specific clear source:
  Ticket, Meeting, Workstream, then Project.
- Use Inbox only when structured creation would require guessing.
- Use Today Summary to reconcile completed and in-progress agent sessions back
  into Workstreams and Tickets before creating free-form daily notes.

## Interview Rules

Ask before writing only when the answer changes:

- target database
- required relation
- page count or split
- operational meaning
- whether a coding-agent session updates an existing Ticket, creates a new
  Ticket, or should only update Workstream progress

Examples:

- `어느 Workstream 밑 Ticket으로 둘까?`
- `회의로 저장할까, Knowledge로 남길까?`
- `이건 하나의 Meeting으로 저장하고 액션아이템은 Ticket으로 쪼갤까?`
- `Project 단위 기록이야, Workstream 단위 기록이야?`
- `이 세션은 기존 Ticket 업데이트야, 새 Ticket 후보야?`

## Verification

Every Notion write should be verified through the matching surface:

- `ntn doctor` confirms the active workspace expected by the profile.
- created page can be fetched.
- title, key body sections, and relation properties are present.
- Project and Workstream pages have their required relation-filtered linked views.
- normal rows are not hidden by template flags such as `Archived = true`.
- Inbox rows default to `Processed = false`.
- Today Summary drafts are read-only until the user confirms Workstream/Ticket
  mappings and status changes.
