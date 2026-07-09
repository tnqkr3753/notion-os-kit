# Scripts

Use `docs/runbooks/notion_os_kit_doctor.md` as the command reference for
progressive disclosure. Keep this README as a short map, not duplicated command
documentation.

Runnable commands:

- `kit/scripts/notion-os-kit doctor --profile <profile-name>`
- `kit/scripts/notion-os-kit connect --profile <profile-name> --workspace <label> --root-page <page-id>`
- `kit/scripts/notion-os-kit install-skills --profile <profile-name>`
- `kit/scripts/notion-os-kit today-summary --profile <profile-name> --session-finder <path>`
- `kit/scripts/notion-os-kit token-report`

`install-skills` writes a compact orchestrator plus workflow wrappers such as
`<skill-prefix>-project` and `<skill-prefix>-today-summary`, based on the
profile `templates:` metadata.

The default local state path is:

```text
~/.notion-os-kit/profiles/<profile-name>/state.local.yaml
```
