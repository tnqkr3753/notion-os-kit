---
title: Notion OS Kit CLI Runbook
tags: runbook, notion-os-kit, doctor, connect, install-skills, token-report, ntn
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
kit/scripts/notion-os-kit token-report
```

## When To Run

- `doctor`: before setup, install, verification, or live Notion writes.
- `connect`: when creating or repairing local profile connection files under
  `~/.notion-os-kit/profiles/<profile-name>/`.
- `install-skills`: after profile metadata changes, to regenerate compact local
  orchestrator and workflow agent skills under `~/.agents/skills`.
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

Keep generic skill files short. Let `doctor`, `connect`, `install-skills`, and
`token-report` provide deterministic setup and validation output, then load only
the generated profile skill needed for profile-specific Notion work.
