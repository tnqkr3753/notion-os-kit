# Notion OS Kit

Generic tooling for profile-based Notion operating systems.

## Quick Use

Run from a checkout:

```bash
kit/scripts/notion-os-kit doctor --profile personal-os
```

Run as an installed tool:

```bash
nok doctor --profile personal-os
```

Run directly from GitHub with `uvx`:

```bash
uvx --from git+https://github.com/tnqkr3753/notion-os-kit nok --help
```

Run the PR branch directly:

```bash
uvx --from git+https://github.com/tnqkr3753/notion-os-kit@codex/today-summary nok today-summary --help
```

Use a concrete profile only after connecting or preserving local profile state
under:

```text
~/.notion-os-kit/profiles/<profile-name>/
```
