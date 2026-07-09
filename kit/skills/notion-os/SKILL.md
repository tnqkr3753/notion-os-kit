---
name: notion-os
description: Use this whenever the user wants to initialize, create, capture, organize, or verify a Notion OS profile. This generic orchestrator reads a profile definition from the repo and deployment state from ~/.notion-os-kit, then routes work to the appropriate Project, Workstream, Ticket, Meeting, Knowledge, Area, or Inbox workflow.
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

Run these from the repo root:

```bash
kit/scripts/notion-os-kit doctor --profile <profile-name>
kit/scripts/notion-os-kit connect --profile <profile-name> --workspace <label> --root-page <page-id>
kit/scripts/notion-os-kit install-skills --profile <profile-name>
kit/scripts/notion-os-kit token-report
```

Use `docs/runbooks/notion_os_kit_doctor.md` for command details. Do not
duplicate that runbook here.

## Work Routing

1. Run `doctor` before live Notion work.
2. Run `connect` to create or repair local profile state.
3. Run `install-skills` to generate compact profile and workflow skills.
4. Run `token-report` before expanding public skill or template prose.
5. After deterministic setup, use the generated profile skill for
   profile-specific relation, interview, and verification rules.

Do not commit tokens, secrets, or local state files.
