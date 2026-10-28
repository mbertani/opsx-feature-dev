---
description: Guided feature development with deep codebase understanding, architecture design, and OpenSpec artifact-driven documentation. Use when the user wants to build a new feature with proper exploration, design, and documentation tracked through OpenSpec changes.
argument-hint: Optional feature description
allowed-tools: Bash(openspec:*)
---

# OpenSpec Feature Development

You are helping a developer implement a new feature using a systematic workflow that combines deep codebase understanding with OpenSpec's artifact-driven documentation. Every phase produces or consumes OpenSpec artifacts so the work is traceable and resumable.

## Core Principles

- **Ask clarifying questions**: Identify all ambiguities, edge cases, and underspecified behaviors. Ask specific, concrete questions rather than making assumptions. Wait for user answers before proceeding with implementation. Ask questions early (after understanding the codebase, before designing architecture).
- **Understand before acting**: Read and comprehend existing code patterns first.
- **Read files identified by agents**: When launching agents, ask them to return lists of the most important files to read. After agents complete, read those files to build detailed context before proceeding.
- **Simple and elegant**: Prioritize readable, maintainable, architecturally sound code.
- **Document through OpenSpec**: All decisions, designs, and tasks flow through OpenSpec artifacts.
- **Use TodoWrite**: Track all progress throughout the workflow.

---

## Phase 1: Discovery

**Goal**: Understand what needs to be built and create the OpenSpec change.

Initial request: $ARGUMENTS

**Actions**:
1. Create a todo list with all 7 phases.
2. If the feature is unclear, use the **AskUserQuestion tool** to ask:
   - What problem are they solving?
   - What should the feature do?
   - Any constraints or requirements?
3. Confirm the project uses OpenSpec:
   ```bash
   openspec context --json
   ```
   If `root` is `null`, stop and ask the user whether to run `openspec init`. Never create the OpenSpec root yourself (no hand-made `openspec/` files). If `openspec/config.yaml` under `root.path` has a `context` field, apply it as project constraints for the rest of the workflow.
4. Derive a kebab-case change name from the description (e.g., "add user authentication" -> `add-user-auth`).
5. Create the OpenSpec change:
   ```bash
   openspec new change "<name>"
   ```
6. Get the schema and artifact structure:
   ```bash
   openspec status --change "<name>" --json
   ```
   Use `changeRoot` and `artifactPaths` from this output for file locations - don't assume `openspec/changes/<name>/`.
7. Summarize your understanding and confirm with the user before proceeding.

---

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns at both high and low levels.

**Actions**:
1. Launch 2-3 **code-explorer** agents in parallel. Each agent should:
   - Trace the abstractions, architecture and flow of control relevant to the feature
   - Target a different aspect of the codebase (e.g. similar features, high level understanding, architectural understanding, user experience)
   - Include a list of 5-10 key files to read

   **Example agent prompts**:
   - "Find features similar to [feature] and trace through their implementation"
   - "Map the architecture and abstractions for [feature area]"
   - "Analyze the current implementation of [existing feature/area]"
   - "Identify UI patterns, testing approaches, or extension points relevant to [feature]"

2. Once the agents return, read all files identified by agents to build deep understanding.
3. Present comprehensive summary of findings and patterns discovered.

---

## Phase 3: Clarifying Questions

**Goal**: Fill in gaps and resolve all ambiguities before designing.

Don't skip this phase: gaps resolved now are much cheaper than a redesign later.

**Actions**:
1. Review the codebase findings and original feature request.
2. Identify underspecified aspects: edge cases, error handling, integration points, scope boundaries, design preferences, backward compatibility, performance needs.
3. **Present all questions to the user in a clear, organized list.**
4. **Wait for answers before proceeding to architecture design.**

If the user says "whatever you think is best", provide your recommendation and get explicit confirmation.

---

## Phase 4: Architecture Design & OpenSpec Artifacts

**Goal**: Design the architecture and capture it in OpenSpec artifacts.

**Actions**:
1. Launch 2-3 **code-architect** agents in parallel with different focuses:
   - Minimal changes (smallest change, maximum reuse)
   - Clean architecture (maintainability, elegant abstractions)
   - Pragmatic balance (speed + quality)

2. Review all approaches and form your opinion on which fits best for this specific task (consider: small fix vs large feature, urgency, complexity, team context).

3. Present to user: brief summary of each approach, trade-offs comparison, **your recommendation with reasoning**, concrete implementation differences.

4. **Ask the user which approach they prefer.**

5. Once the user decides, generate OpenSpec artifacts using the chosen architecture.

   Get instructions for each artifact:
   ```bash
   openspec instructions <artifact-id> --change "<name>" --json
   ```

   Build artifacts in dependency order (follow each artifact's `requires` in the status output). For each artifact:
   - Re-read its dependency artifacts from disk - the user may have edited them since you last saw them.
   - If the instructions contain `skipped`/`warning`, the change declares `skip_specs`: do not create that artifact.
   - Follow `instruction` - it is authoritative, even for familiar artifact names. If it delegates to a specific skill or command, use that.
   - Use the `template` from instructions as structure.
   - Apply `context` and `rules` as constraints (do NOT copy them into the file).
   - Write the artifact to `resolvedOutputPath`. If it is a glob, choose a concrete path inside `changeRoot` that matches it.

   Key artifacts to produce (spec-driven schema):
   - **proposal.md**: What and why - the feature description, motivation, scope, and chosen approach.
   - **specs/<capability>/spec.md**: Delta specs - the requirements this change adds, modifies, or removes. Apply is blocked without them unless the change declares `skip_specs: true` (pure refactors, docs).
   - **design.md**: How - the architecture decision, component design, data flow, integration points.
   - **tasks.md**: Implementation steps - concrete, ordered tasks derived from the build sequence. Each task group includes its own tests and doc updates, and each task says how you'd know it's done.

6. Verify artifact status and validate:
   ```bash
   openspec status --change "<name>" --json
   openspec validate "<name>" --strict
   ```
   `status` only checks that files exist. Make sure every artifact in `applyRequires` *and* everything they transitively `requires` is `done` or `skipped`, and fix any validation errors.

7. **Ask the user if they want to review the OpenSpec artifacts before continuing to implementation.** Pause and wait for their response. If they want to review, list the artifact file paths so they can inspect them. Only proceed to Phase 5 once the user confirms they are ready.

---

## Phase 5: Implementation

**Goal**: Build the feature by working through OpenSpec tasks.

Start only after the user has explicitly approved the design and artifacts.

**Actions**:
1. Get apply instructions:
   ```bash
   openspec instructions apply --change "<name>" --json
   ```
   - `state: "blocked"` with `missingArtifacts` -> go back to Phase 4 and create them. Don't start implementing while blocked.
   - `state: "all_done"` -> skip to Phase 6.
2. Read every file listed in `contextFiles`. Apply `context` as project constraints and consider any `operationGuidance` - neither is evidence that a task is done.
3. For each pending task:
   - Show which task is being worked on.
   - Make the code changes required.
   - Keep changes minimal and focused.
   - Mark the task complete at its returned `sourcePath` and `line`: `- [ ]` -> `- [x]`. If that line no longer matches the task, rerun the apply instructions first.
   - Only mark a task done when its specified behavior is fully implemented.
   - Continue to next task.
4. Update todos as you progress, and rerun the apply instructions to confirm progress.

**Pause if:**
- Task is unclear -> ask for clarification
- A task needs work beyond the spec, or you're tempted to narrow, defer, or drop specified behavior -> surface the added scope and ask
- Implementation reveals a design issue -> suggest updating artifacts
- Error or blocker encountered -> report and wait for guidance

---

## Phase 6: Quality Review

**Goal**: Ensure code is simple, DRY, elegant, easy to read, and functionally correct.

**Actions**:
1. Launch 3 **code-reviewer** agents in parallel with different focuses:
   - Simplicity / DRY / Elegance
   - Bugs / Functional correctness
   - Project conventions / Abstractions

   Give each reviewer the list of files changed for this feature - reviewers have no Bash tool, so they can't run `git diff` themselves.
2. Consolidate findings, drop low-confidence ones (below ~80) and nitpicks, and identify the highest severity issues that you recommend fixing.
3. **Present findings to user and ask what they want to do** (fix now, fix later, or proceed as-is).
4. Address issues based on user decision.

---

## Phase 7: Summary & Archive

**Goal**: Document what was accomplished and optionally archive the change.

**Actions**:
1. Mark all todos complete.
2. Show implementation status:
   ```bash
   openspec status --change "<name>"
   ```
   The output ends with a `Next:` line naming the command that moves the change forward.
3. Summarize:
   - What was built
   - Key decisions made
   - Files modified
   - Suggested next steps
4. Ask the user if they want to archive the change now.
   - If yes, suggest `/opsx:verify` (if installed) to check the implementation against the specs, then `/opsx:archive`
   - If no, note that the change remains active for future work.

---

## Output Formats

**During Implementation:**
```
## Implementing: <change-name>

Working on task 3/7: <task description>
[...implementation...]
Task complete

Working on task 4/7: <task description>
[...implementation...]
Task complete
```

**On Completion:**
```
## Feature Complete: <change-name>

**Progress:** 7/7 tasks complete

### What Was Built
- ...

### Key Decisions
- ...

### Files Modified
- ...

### Next Steps
- ...

All tracked tasks complete. Review or run `/opsx:verify`, then `/opsx:archive`.
```

**On Pause (Issue Encountered):**
```
## Implementation Paused: <change-name>

**Progress:** 4/7 tasks complete

### Issue Encountered
<description>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

---

## Guardrails

- Always create the OpenSpec change in Phase 1 before doing design work.
- Never create the OpenSpec root as a side effect - if `openspec context --json` finds none, ask before `openspec init`.
- Use `openspec instructions` to get artifact templates and rules - don't invent structure.
- Use paths from CLI JSON (`changeRoot`, `resolvedOutputPath`, `contextFiles`, `sourcePath`) - don't assume repo-local paths.
- `context` and `rules` from instructions are constraints for YOU, not content for the artifact files.
- Keep code changes minimal and scoped to each task.
- If implementation reveals design issues, suggest updating OpenSpec artifacts before continuing.
- Pause on errors, blockers, or unclear requirements - don't guess.
- Use contextFiles from CLI output, don't assume specific file names.
