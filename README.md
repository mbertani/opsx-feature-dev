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

## Keeping in Sync with OpenSpec

This plugin depends on the openspec CLI and its skill conventions. When openspec updates, the CLI commands or artifact structure may change.

### Checking for breaking changes

Run the compatibility check script to compare your openspec CLI version against the version this plugin was tested with:

```bash
./check-compat.sh
```

This will:
1. Show your installed openspec CLI version
2. Compare it against the tested version recorded in `OPENSPEC_COMPAT`
3. List any openspec CLI commands this plugin uses and verify they still work
4. Flag potential issues

### What to watch for on openspec upgrades

This plugin calls these openspec CLI commands:
- `openspec new change "<name>"` — creates a change directory
- `openspec status --change "<name>" --json` — reads artifact graph and schema
- `openspec instructions <artifact-id> --change "<name>" --json` — gets artifact templates/rules
- `openspec instructions apply --change "<name>" --json` — gets implementation context
- `openspec list --json` — lists active changes

If any of these change their JSON output shape or flags, the feature-dev command may need updating.

### After an openspec upgrade

1. Run `./check-compat.sh` to see if anything changed
2. If the script reports issues, check the [openspec changelog](https://github.com/openspec-dev/openspec/releases)
3. Update the `feature-dev.md` command if CLI flags or JSON output changed
4. Update `OPENSPEC_COMPAT` with the new tested version

## Related Skills

The [openspec CLI](https://github.com/openspec-dev/openspec) provides these skills (managed separately):
- `/opsx:explore` - Thinking partner for exploration
- `/opsx:propose` - Quick artifact generation without the full workflow
- `/opsx:apply` - Implement tasks from an existing change
- `/opsx:archive` - Archive completed changes

## License

MIT
