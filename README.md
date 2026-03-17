# opsx-feature-dev

A Claude Code plugin that combines systematic feature development (codebase exploration, architecture design, quality review) with [OpenSpec](https://github.com/openspec-dev/openspec) artifact-driven documentation.

## What It Does

Instead of jumping straight into code, this plugin guides you through a 7-phase workflow where every decision, design, and task is captured in OpenSpec artifacts - making the work traceable, resumable, and reviewable.

### The 7 Phases

| Phase | Goal | Produces |
|-------|------|----------|
| 1. Discovery | Understand what to build | OpenSpec change created |
| 2. Codebase Exploration | Understand existing code | Findings summary via code-explorer agents |
| 3. Clarifying Questions | Resolve all ambiguities | User answers |
| 4. Architecture & Artifacts | Design and document | proposal.md, design.md, tasks.md |
| 5. Implementation | Build the feature | Code changes, task checkboxes |
| 6. Quality Review | Verify quality | Review findings via code-reviewer agents |
| 7. Summary & Archive | Document completion | Summary, optional archive |

### Specialized Agents

- **code-explorer** - Traces execution paths, maps architecture layers, documents dependencies
- **code-architect** - Designs architectures with implementation blueprints, analyzes codebase patterns
- **code-reviewer** - Reviews for bugs, quality issues, and project convention adherence (confidence >= 80 threshold)

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [OpenSpec CLI](https://github.com/openspec-dev/openspec) installed and configured in your project
- OpenSpec skills installed in your project (these are managed by the openspec CLI)

## Installation

First, add the repo as a marketplace source:

```bash
claude plugin marketplace add mbertani/opsx-feature-dev
```

Then install the plugin:

```bash
claude plugin install opsx-feature-dev
```

## Usage

```bash
# Full workflow with description
/opsx-feature-dev:feature-dev Add rate limiting to API endpoints

# Or start interactively
/opsx-feature-dev:feature-dev
```

The command guides you through each phase, waiting for your input at key decision points (clarifying questions, architecture choice, implementation approval).

### When to Use This

- New features touching multiple files
- Features requiring architectural decisions
- Complex integrations with existing code
- Features where requirements are unclear

### When NOT to Use This

- Single-line bug fixes
- Trivial, well-defined changes
- Urgent hotfixes

## How It Integrates with OpenSpec

This plugin **layers on top** of the core openspec skills rather than bundling them. The openspec CLI manages its own skills (explore, propose, apply, archive) and generates them to match the CLI version. This plugin adds the feature-dev workflow that calls the openspec CLI directly and references the opsx skills by name.

The workflow creates an OpenSpec change in Phase 1 and uses `openspec instructions` to generate properly structured artifacts. The implementation phase works through tasks.md exactly like `/opsx:apply`. When done, you can archive with `/opsx:archive`.

This means you can:
- **Pause mid-workflow** and resume later with `/opsx:apply`
- **Review artifacts** independently of the workflow
- **Archive completed work** with full traceability

## Keeping in Sync

This plugin has two upstream dependencies that may change independently:

1. **OpenSpec CLI** — the `openspec` commands and artifact structure
2. **Official feature-dev plugin** — the agent prompts (code-explorer, code-architect, code-reviewer)

### Syncing with the official feature-dev plugin

The three agent files (code-explorer, code-architect, code-reviewer) are derived from [Anthropic's feature-dev plugin](https://github.com/anthropics/claude-plugins-official). The `UPSTREAM_VERSION` file tracks which version they were last synced from.

When Anthropic updates the official plugin:

```bash
# 1. Pull the latest official plugin into your local cache
claude plugin update feature-dev@claude-code-plugins

# 2. Compare your agents against the new version
./update-from-upstream.sh

# 3. If agent diffs are shown, apply them automatically
./update-from-upstream.sh --apply

# 4. Review and commit
git diff
git commit -am "Sync agents with upstream"
git push
```

The script will:
- Show whether a new upstream version is available (hash comparison)
- Diff each agent file and the command file
- With `--apply`: copy updated agents and update the `UPSTREAM_VERSION` hash

The command file (`feature-dev.md`) will always differ from upstream because it includes the OpenSpec integration. The script flags this but won't overwrite it - review command diffs manually for workflow changes you may want to incorporate.

### Syncing with OpenSpec CLI

Run the compatibility check to verify the openspec CLI commands this plugin uses still work:

```bash
./check-compat.sh
```

This compares your installed openspec CLI version against the version recorded in `OPENSPEC_COMPAT` and verifies all required CLI commands are available.

#### OpenSpec CLI commands used by this plugin

- `openspec new change "<name>"` — creates a change directory
- `openspec status --change "<name>" --json` — reads artifact graph and schema
- `openspec instructions <artifact-id> --change "<name>" --json` — gets artifact templates/rules
- `openspec instructions apply --change "<name>" --json` — gets implementation context
- `openspec list --json` — lists active changes

If any of these change their JSON output shape or flags, the `feature-dev.md` command may need updating.

#### After an openspec CLI upgrade

1. Run `./check-compat.sh` to see if anything changed
2. If the script reports issues, check the [openspec changelog](https://github.com/openspec-dev/openspec/releases)
3. Update `commands/feature-dev.md` if CLI flags or JSON output changed
4. Update `OPENSPEC_COMPAT` with the new tested version

## Related Skills

The [openspec CLI](https://github.com/openspec-dev/openspec) provides these skills (managed separately):
- `/opsx:explore` - Thinking partner for exploration
- `/opsx:propose` - Quick artifact generation without the full workflow
- `/opsx:apply` - Implement tasks from an existing change
- `/opsx:archive` - Archive completed changes

## License

MIT
