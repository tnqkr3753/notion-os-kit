# Notion OS Kit

`kit/` contains reusable source for building Notion-based operating systems.
It should stay independent from any one Notion workspace.

Profile-specific names, rules, and deployment choices belong under
`profiles/<profile-name>/`.

Machine-local deployment state belongs under:

```text
~/.notion-os-kit/profiles/<profile-name>/state.local.yaml
```

