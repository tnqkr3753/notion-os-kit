---
title: Notion OS Kit Profile And State Model
tags: decision, notion-os-kit, profile, deployment
date: 2026-07-08
---

# Notion OS Kit Profile And State Model

## Decision

`notion-os-kit` should be a generic, open-sourceable Notion operating-system
framework. A user-defined custom name should become the **profile name**.

An installed profile is not the framework itself. It is one concrete deployment
of the framework into a user's Notion workspace.

## Terminology

- **kit**: reusable framework code, generic templates, generic skills, init
  scripts, verification scripts, and documentation.
- **profile**: a named operating model selected by the user, such as
  `personal-os`, `team-os`, or another custom name.
- **deployment state**: the actual Notion workspace identifiers produced or
  discovered after init, such as data source IDs, database IDs, page IDs, and
  view IDs.

## Repository Shape

Recommended public repo shape:

```text
notion-os-kit/
  kit/
    schemas/
    templates/
    skills/
    scripts/
  profiles/
    <profile-name>/
      profile.yaml
      schema.yaml
      rules/
      templates/
      state.example.yaml
  docs/
    concepts/
    decisions/
    references/
```

Real deployment state should live outside the repo under the user's home
directory:

```text
~/.notion-os-kit/profiles/<profile-name>/state.local.yaml
```

`state.example.yaml` should be committed so users understand the shape without
exposing real IDs.

## Profile Rule

The profile name is the user's custom name. Public examples should use
sanitized names and placeholder workspace labels. A public repo may include a
sample profile when it contains reusable structure, templates, and rules. It
should not include private tokens, secrets, or real Notion IDs.

## Init Flow

The expected init flow is:

1. User chooses a profile name.
2. `notion-os-kit init --profile <profile-name>` creates or discovers Notion
   pages, databases, views, and template surfaces.
3. The init command writes deployment state to:
   `~/.notion-os-kit/profiles/<profile-name>/state.local.yaml`.
4. The install command generates or installs agent skills from the profile.
5. The verify command checks that the workspace matches the profile and local
   state.

## Public / Local Split

Commit:

- generic kit code
- generic skills
- profile schema
- reusable relation/view rules
- reusable templates
- `state.example.yaml`

Do not commit:

- Notion API tokens
- secrets
- machine-local auth files
- `~/.notion-os-kit/profiles/<profile-name>/state.local.yaml`

For a private repo, committing real Notion IDs can be acceptable. For an
open-source repo, keep real IDs in home-directory local state.
