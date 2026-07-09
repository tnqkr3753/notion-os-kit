# Notion OS Kit

`kit/` contains reusable source for building Notion-based operating systems.
It should stay independent from any one Notion workspace.

The generic workflow set includes daily reconciliation: `today-summary` gathers
local coding-agent session evidence and prepares Workstream/Ticket updates
without mutating Notion.

Profile-specific names, rules, and deployment choices belong under
`profiles/<profile-name>/`.

Machine-local deployment state belongs under:

```text
~/.notion-os-kit/profiles/<profile-name>/state.local.yaml
```
