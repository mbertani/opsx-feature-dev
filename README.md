# opsx-feature-dev

A feature development workflow that combines systematic feature development (codebase exploration, architecture design, quality review) with [OpenSpec](https://openspec.dev/) artifact-driven documentation.

**Supports:** Claude Code | GitHub Copilot

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

- **One of the following:**
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed, **or**
  - [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line) installed
- [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec/) installed and configured in your project
  ```bash
  brew install openspec
  ```

## Installation

### For Claude Code

First, add the repo as a marketplace source:

```bash
claude plugin marketplace add mbertani/opsx-feature-dev
```

Then install the plugin:

```bash
claude plugin install opsx-feature-dev
```

### For GitHub Copilot

Install directly from the GitHub repository:

```bash
copilot plugin install mbertani/opsx-feature-dev
```

Or install via the `gh` wrapper:

```bash
gh copilot -- plugin install mbertani/opsx-feature-dev
```

**Note:** The Copilot version requires the `feature-dev` plugin to be installed (for the specialized agents: `code-explorer`, `code-architect`, `code-reviewer`). If not already installed:

```bash
copilot plugin install github/copilot-plugins:feature-dev
# or
gh copilot -- plugin install github/copilot-plugins:feature-dev
```

## Usage

### Claude Code

```bash
# Full workflow with description
/opsx-feature-dev:feature-dev Add rate limiting to API endpoints

# Or start interactively
/opsx-feature-dev:feature-dev
```

### GitHub Copilot

```bash
# In Copilot CLI session
/openspec-feature-dev Add rate limiting to API endpoints

# Or start interactively
/openspec-feature-dev
```

**Note:** The skill appears as `/openspec-feature-dev` (without namespace prefix) in Copilot's skill list.

The command guides you through each phase, waiting for your input at key decision points (clarifying questions, architecture choice, implementation approval).

### Platform Compatibility

| Feature | Claude | Copilot |
|---------|--------|---------|
| 7-Phase Workflow | ✅ | ✅ |
| Code Explorer Agent | ✅ | ✅ (requires feature-dev plugin) |
| Code Architect Agent | ✅ | ✅ (requires feature-dev plugin) |
| Code Reviewer Agent | ✅ | ✅ (requires feature-dev plugin) |
| OpenSpec Integration | ✅ | ✅ |
| Todo Tracking | TodoWrite | SQL todos table |
| User Questions | AskUserQuestion | ask_user tool |

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

The three agent files (code-explorer, code-architect, code-reviewer) are derived from [Anthropic's feature-dev plugin](https://github.com/anthropics/claude-plugins-official). The command file (`feature-dev.md`) is also based on upstream but includes OpenSpec-specific additions (change creation, artifact generation, apply instructions, archive workflow, output formats, guardrails). The `UPSTREAM_VERSION` file tracks which version was last synced.

When Anthropic updates the official plugin:

```bash
# 1. Pull the latest official plugin into your local cache
claude plugin update feature-dev@claude-code-plugins

# 2. Compare your agents and command against the new version
./update-from-upstream.sh

# 3. Apply updates automatically
./update-from-upstream.sh --apply

# 4. Review and commit
git diff
git commit -am "Sync with upstream feature-dev"
git push
```

The script will:
- Show whether a new upstream version is available (hash comparison)
- Diff each agent file and the command file
- With `--apply`:
  - Copy updated agent files directly (these are identical to upstream)
  - Copy the upstream command file, then apply `openspec-command.patch` to re-add OpenSpec customizations
  - Update the `UPSTREAM_VERSION` hash

#### When the patch fails to apply

If upstream changes conflict with the OpenSpec patch, the script will report the failure. To resolve:

1. Review the conflict — the upstream command is already copied to `commands/feature-dev.md`
2. Manually (or with Claude's help) merge the OpenSpec additions back in
3. Regenerate the patch:
   ```bash
   diff -u <upstream-command-path> commands/feature-dev.md > openspec-command.patch
   ```
4. Fix the patch header to use git-style paths (`a/commands/feature-dev.md` / `b/commands/feature-dev.md`)
5. Commit both the updated command and patch files

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

If any of these change their JSON output shape or flags, the workflow files may need updating (both `commands/feature-dev.md` for Claude and `.copilot/skills/opsx-feature-dev.md` for Copilot).

#### After an openspec CLI upgrade

1. Run `./check-compat.sh` to see if anything changed
2. If the script reports issues, check the [openspec changelog](https://github.com/openspec-dev/openspec/releases)
3. Update both workflow files if CLI flags or JSON output changed:
   - `commands/feature-dev.md` (Claude)
   - `.copilot/skills/opsx-feature-dev.md` (Copilot)
4. Update `OPENSPEC_COMPAT` with the new tested version

## Repository Structure

This repository supports both Claude Code and GitHub Copilot with a dual-platform structure:

```
opsx-feature-dev/
├── .claude-plugin/           # Claude-specific metadata
│   ├── plugin.json
│   └── marketplace.json
├── .copilot/                 # Copilot-specific skills
│   └── skills/
│       └── opsx-feature-dev.md
├── agents/                   # Claude agent definitions
│   ├── code-explorer.md
│   ├── code-architect.md
│   └── code-reviewer.md
├── commands/                 # Claude workflow
│   └── feature-dev.md
├── README.md                # Documentation (this file)
├── check-compat.sh          # OpenSpec compatibility check
├── update-from-upstream.sh  # Sync with upstream feature-dev
├── openspec-command.patch   # OpenSpec additions to upstream command
├── OPENSPEC_COMPAT         # OpenSpec version tracking
└── UPSTREAM_VERSION         # Upstream sync tracking
```

**Platform-specific files:**
- `.claude-plugin/`, `agents/`, `commands/` - Claude Code only
- `.copilot/skills/` - GitHub Copilot only
- Scripts and docs - shared by both platforms

For development guidelines and contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Related Skills

The [openspec CLI](https://github.com/openspec-dev/openspec) provides these skills (managed separately):
- `/opsx:explore` - Thinking partner for exploration
- `/opsx:propose` - Quick artifact generation without the full workflow
- `/opsx:apply` - Implement tasks from an existing change
- `/opsx:archive` - Archive completed changes

## License

MIT
