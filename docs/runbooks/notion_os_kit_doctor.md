---
title: Notion OS Kit CLI Runbook
tags: runbook, notion-os-kit, doctor, connect, install-skills, today-summary, token-report, ntn
---

# Notion OS Kit CLI Runbook

Agents should run deterministic `notion-os-kit` commands instead of loading
profile-specific wrapper prose. Use this runbook as the shared command
reference.

Run commands from the repo root.

## Commands

```bash
kit/scripts/notion-os-kit doctor --profile <profile-name>
kit/scripts/notion-os-kit connect --profile <profile-name> --workspace <label> --root-page <page-id>
kit/scripts/notion-os-kit install-skills --profile <profile-name>
kit/scripts/notion-os-kit today-summary --profile <profile-name> --session-finder <path>
kit/scripts/notion-os-kit token-report
```

## When To Run

- `doctor`: before setup, install, verification, or live Notion writes.
- `connect`: when creating or repairing local profile connection files under
  `~/.notion-os-kit/profiles/<profile-name>/`.
- `install-skills`: after profile metadata changes, to regenerate compact local
  orchestrator and workflow agent skills under `~/.agents/skills`.
- `today-summary`: at end of day or before work-log cleanup, to convert local
  coding-agent session evidence into a Workstream/Ticket reconciliation draft.
- `token-report`: before adding public skill, template, or documentation prose,
  to catch source-size growth and duplicate template hashes.

## Doctor Checks

`doctor` checks:

- repo source directories exist
- profile files exist
- required rules and templates exist
- local deployment state exists under
  `~/.notion-os-kit/profiles/<profile-name>/state.local.yaml`
- no `state.local.yaml` is stored inside the repo
- `ntn` is installed
- `ntn doctor` exits successfully
- the active `ntn` workspace matches the profile `workspace_label`
- generic skill source exists
- installed profile orchestrator skill exists under `~/.agents/skills`

The command exits non-zero when a required check fails. Warnings indicate drift
or missing optional installation steps, such as an available `ntn` update.

## Progressive Disclosure

Keep generic skill files short. Let `doctor`, `connect`, `install-skills`,
`today-summary`, and `token-report` provide deterministic setup and validation
output, then load only the generated profile skill needed for profile-specific
Notion work.

## Today Summary Reconciliation

`today-summary` is read-only. It gathers coding-agent sessions through a
session finder and writes a Markdown draft with:

- source sessions
- Workstream mapping candidates
- Ticket update decisions to confirm
- one-at-a-time grill questions
- an apply gate for later Notion writes

Use `--sessions-json <path>` for deterministic QA or offline review. Use
`--session-finder <path>` for live collection.
