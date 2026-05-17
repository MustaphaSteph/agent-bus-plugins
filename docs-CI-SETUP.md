# Manual CI setup (one-time)

The OAuth token used during initial push lacks `workflow` scope, so
this file has to be added by hand via the GitHub web UI.

## Add this workflow at `.github/workflows/sync-check.yml`

```yaml
name: sync-check

on:
  pull_request:
    paths:
      - "plugins/agent-bus/skills/**"
      - "scripts/sync-skill.sh"
      - ".sync-version"
  push:
    branches: [main]

jobs:
  drift:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run sync-skill --check
        run: ./scripts/sync-skill.sh --check
```

## Easiest way

1. Go to https://github.com/MustaphaSteph/agent-bus-plugins/actions/new
2. Click "set up a workflow yourself"
3. Paste the YAML above
4. Save (commits to `.github/workflows/sync-check.yml` directly)

After that, future commits to `main` and PRs touching the vendored
skill, the sync script, or `.sync-version` will run the drift gate
automatically.

Or, the next time `gh auth refresh -s workflow` is run locally, this
file can be moved into place from `.tmp/sync-check.yml.deferred` and
pushed normally.
