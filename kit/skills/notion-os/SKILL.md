---
name: notion-os
description: Use this whenever the user wants to initialize, create, capture, organize, reconcile today's agent work, or verify a Notion OS profile. This generic orchestrator reads a profile definition from the repo and deployment state from ~/.notion-os-kit, then routes work to the appropriate Project, Workstream, Ticket, Meeting, Knowledge, Area, Inbox, or Today Summary workflow.
---

# Notion OS

Use this generic skill as a compact router. Prefer deterministic CLI commands
over loading profile-specific wrapper prose.

## Source Layout

- Public example profile: `examples/<profile-name>/`
- Local profile definition: `~/.notion-os-kit/profiles/<profile-name>/`
- Local deployment state:
  `~/.notion-os-kit/profiles/<profile-name>/state.local.yaml`

## CLI First

Use the installed CLI first:

```bash
nok doctor --profile <profile-name>
nok init --profile <profile-name> --workspace <label> --root-page <page-id>
nok install-skills --profile <profile-name>
nok today-summary --profile <profile-name> --session-finder <path>
nok token-report
```

From a source checkout, `kit/scripts/notion-os-kit ...` is the fallback. Use
`docs/runbooks/notion_os_kit_doctor.md` for command details. Do not duplicate
that runbook here.

## Work Routing

1. Run `doctor` before live Notion work.
2. Run `init` to create or repair local profile state.
3. Run `install-skills` to generate compact profile and workflow skills.
4. Run `today-summary` to draft Workstream/Ticket reconciliation from local
   coding-agent sessions.
5. Run `token-report` before expanding public skill or template prose.
6. After deterministic setup, use the generated profile skill for
   profile-specific relation, interview, and verification rules.

Do not commit tokens, secrets, or local state files.
