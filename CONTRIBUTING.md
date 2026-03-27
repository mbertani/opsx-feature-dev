# Contributing to opsx-feature-dev

Thank you for your interest in contributing to opsx-feature-dev! This guide will help you understand the dual-platform structure and how to make changes.

## Repository Structure

This repository supports both **Claude Code** and **GitHub Copilot** with platform-specific implementations:

```
opsx-feature-dev/
├── .claude-plugin/           # Claude metadata (plugin.json, marketplace.json)
├── .copilot/                 # Copilot skills
│   └── skills/
│       └── opsx-feature-dev.md
├── agents/                   # Claude agent definitions
│   ├── code-explorer.md
│   ├── code-architect.md
│   └── code-reviewer.md
├── commands/                 # Claude workflow
│   └── feature-dev.md
├── README.md                # Shared documentation
├── check-compat.sh          # OpenSpec compatibility checker (shared)
├── update-from-upstream.sh  # Upstream sync script (shared)
├── OPENSPEC_COMPAT         # OpenSpec version tracking
└── UPSTREAM_VERSION         # Upstream sync tracking
```

## Platform-Specific vs Shared Files

### Claude-Specific
- `.claude-plugin/` - Plugin metadata and marketplace registration
- `agents/` - Agent definitions (code-explorer, code-architect, code-reviewer)
- `commands/feature-dev.md` - Main workflow using Claude APIs

### Copilot-Specific
- `.copilot/skills/opsx-feature-dev.md` - Main workflow using Copilot APIs

### Shared (Platform-Agnostic)
- `README.md` - Documentation for both platforms
- `check-compat.sh` - OpenSpec compatibility verification
- `update-from-upstream.sh` - Sync with Anthropic's official feature-dev plugin
- `OPENSPEC_COMPAT` - OpenSpec CLI version tracking
- `UPSTREAM_VERSION` - Upstream feature-dev plugin version tracking

## Making Changes

### Workflow Changes

When modifying the 7-phase workflow, you need to update **both** platform-specific files:

1. **Claude**: `commands/feature-dev.md`
   - Uses `AskUserQuestion` for user input
   - Uses `TodoWrite` for progress tracking
   - Task tool with standard syntax

2. **Copilot**: `.copilot/skills/opsx-feature-dev.md`
   - Uses `ask_user` tool for user input
   - Uses `sql` tool with todos table for progress tracking
   - Task tool with `agent_type` parameter

**API Mapping:**
```
Claude Tool          → Copilot Tool
-------------------------------------------------
AskUserQuestion      → ask_user
TodoWrite            → sql (INSERT/UPDATE todos)
ReadFile             → view
EditFile             → edit
task (agent)         → task (agent_type: "feature-dev/...")
```

### Agent Changes (Claude Only)

The three agent files in `agents/` are used by Claude only. Copilot uses the globally installed `feature-dev` plugin agents.

If you modify agent prompts:
1. Update files in `agents/` directory
2. Consider whether Copilot users need the changes (may require updating the global feature-dev plugin)

### Documentation Changes

When updating `README.md`:
- Clearly distinguish between Claude and Copilot usage
- Update the platform compatibility table if features change
- Keep installation instructions accurate for both platforms

## Testing

Before submitting changes, test on **both platforms** if possible:

### Testing on Claude Code

```bash
# Install locally
claude plugin install /path/to/opsx-feature-dev

# Test the workflow
/opsx-feature-dev:feature-dev Test feature description
```

### Testing on GitHub Copilot

```bash
# Install locally
copilot plugin install /path/to/opsx-feature-dev

# Or via gh wrapper
gh copilot -- plugin install /path/to/opsx-feature-dev

# Test the workflow
copilot -i "/opsx-feature-dev Test feature description" --allow-all-tools
```

## Syncing with Upstream

This plugin syncs agents from [Anthropic's official feature-dev plugin](https://github.com/anthropics/claude-plugins-official).

### When to Sync

- Anthropic releases a new version of feature-dev
- Agent prompts are improved or bug-fixed upstream
- New capabilities are added to the agents

### How to Sync

```bash
# 1. Update your local Claude plugin cache
claude plugin update feature-dev

# 2. Check for differences
./update-from-upstream.sh

# 3. Review the diffs shown

# 4. Apply updates automatically
./update-from-upstream.sh --apply

# 5. Review changes
git diff agents/

# 6. Test on both platforms

# 7. Commit
git commit -am "Sync agents with upstream feature-dev vX.Y.Z"
git push
```

**Note:** The `commands/feature-dev.md` file will always show diffs because it includes OpenSpec integration. This is expected - review command changes manually and incorporate relevant improvements.

## OpenSpec Compatibility

### Checking Compatibility

```bash
./check-compat.sh
```

This verifies:
- Your installed OpenSpec CLI version
- Required CLI commands are available
- JSON output formats haven't changed

### After OpenSpec CLI Updates

If the OpenSpec CLI changes its command structure or JSON output:

1. Run `./check-compat.sh` to identify issues
2. Check the [OpenSpec changelog](https://github.com/openspec-dev/openspec/releases)
3. Update **both** workflow files:
   - `commands/feature-dev.md` (Claude)
   - `.copilot/skills/opsx-feature-dev.md` (Copilot)
4. Update `OPENSPEC_COMPAT` with the new tested version
5. Test on both platforms
6. Document breaking changes in release notes

## Pull Request Guidelines

### Checklist

- [ ] Updated both `commands/feature-dev.md` and `.copilot/skills/opsx-feature-dev.md` if workflow changed
- [ ] Updated README.md if installation/usage changed
- [ ] Tested on Claude Code (or noted you couldn't)
- [ ] Tested on GitHub Copilot (or noted you couldn't)
- [ ] Verified OpenSpec compatibility with `./check-compat.sh`
- [ ] Updated `OPENSPEC_COMPAT` if minimum version changed
- [ ] Added/updated tests if applicable
- [ ] Followed existing code style and conventions

### PR Description Template

```markdown
## Description
Brief description of changes

## Platform Impact
- [ ] Claude Code only
- [ ] GitHub Copilot only
- [ ] Both platforms

## Testing
- [ ] Tested on Claude Code
- [ ] Tested on GitHub Copilot
- [ ] OpenSpec compatibility verified

## Breaking Changes
List any breaking changes and migration steps

## Related Issues
Closes #XXX
```

## Code of Conduct

- Be respectful and constructive
- Focus on improving the tool for all users
- Test thoroughly before submitting
- Document platform-specific behavior clearly

## Questions?

Open an issue or start a discussion on GitHub!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
