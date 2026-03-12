---
description: Guided feature development with deep codebase understanding, architecture design, and OpenSpec artifact-driven documentation. Use when the user wants to build a new feature with proper exploration, design, and documentation tracked through OpenSpec changes.
argument-hint: Optional feature description
---

# OpenSpec Feature Development

You are helping a developer implement a new feature using a systematic workflow that combines deep codebase understanding with OpenSpec's artifact-driven documentation. Every phase produces or consumes OpenSpec artifacts so the work is traceable and resumable.

## Core Principles

- **Ask clarifying questions**: Identify all ambiguities and edge cases. Ask specific, concrete questions rather than making assumptions. Wait for answers before proceeding.
- **Understand before acting**: Read and comprehend existing code patterns first.
- **Read files identified by agents**: When launching agents, ask them to return lists of the most important files. After agents complete, read those files to build detailed context.
- **Document through OpenSpec**: All decisions, designs, and tasks flow through OpenSpec artifacts.
- **Use TodoWrite**: Track phase progress throughout the workflow.

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
3. Derive a kebab-case change name from the description (e.g., "add user authentication" -> `add-user-auth`).
4. Create the OpenSpec change:
   ```bash
   openspec new change "<name>"
   ```
5. Get the schema and artifact structure:
   ```bash
   openspec status --change "<name>" --json
   ```
6. Summarize your understanding and confirm with the user before proceeding.

---

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns at both high and low levels.

**Actions**:
1. Launch 2-3 **code-explorer** agents in parallel. Each agent should:
   - Trace through the code comprehensively
   - Focus on a different aspect (similar features, architecture, user experience)
   - Return a list of 5-10 key files to read

   **Example agent prompts**:
   - "Find features similar to [feature] and trace through their implementation comprehensively"
   - "Map the architecture and abstractions for [feature area], tracing through the code comprehensively"
   - "Analyze the current implementation of [existing feature/area], tracing through the code comprehensively"

2. Once agents return, read all identified files to build deep understanding.
3. Present a comprehensive summary of findings and patterns discovered.

---

## Phase 3: Clarifying Questions

**Goal**: Fill in gaps and resolve all ambiguities before designing.

**CRITICAL**: This is one of the most important phases. DO NOT SKIP.

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

2. Review all approaches and form your opinion on which fits best.

3. Present to user: brief summary of each approach, trade-offs comparison, **your recommendation with reasoning**, concrete implementation differences.

4. **Ask the user which approach they prefer.**

5. Once the user decides, generate OpenSpec artifacts using the chosen architecture.

   Get instructions for each artifact:
   ```bash
   openspec instructions <artifact-id> --change "<name>" --json
   ```

   Build artifacts in dependency order. For each artifact:
   - Read dependency artifacts for context.
   - Use the `template` from instructions as structure.
   - Apply `context` and `rules` as constraints (do NOT copy them into the file).
   - Write the artifact to `outputPath`.

   Key artifacts to produce:
   - **proposal.md**: What and why - the feature description, motivation, scope, and chosen approach.
   - **design.md**: How - the architecture decision, component design, data flow, integration points.
   - **tasks.md**: Implementation steps - concrete, ordered tasks derived from the build sequence.

6. Verify artifact status:
   ```bash
   openspec status --change "<name>" --json
   ```
   Ensure all `applyRequires` artifacts are `done`.

---

## Phase 5: Implementation

**Goal**: Build the feature by working through OpenSpec tasks.

**DO NOT START WITHOUT USER APPROVAL.**

**Actions**:
1. Wait for explicit user approval.
2. Get apply instructions:
   ```bash
   openspec instructions apply --change "<name>" --json
   ```
3. Read all context files listed in the apply instructions.
4. For each pending task:
   - Show which task is being worked on.
   - Make the code changes required.
   - Keep changes minimal and focused.
   - Mark task complete in the tasks file: `- [ ]` -> `- [x]`
   - Continue to next task.
5. Update todos as you progress.

**Pause if:**
- Task is unclear -> ask for clarification
- Implementation reveals a design issue -> suggest updating artifacts
- Error or blocker encountered -> report and wait for guidance

---

## Phase 6: Quality Review

**Goal**: Ensure code is simple, DRY, elegant, and functionally correct.

**Actions**:
1. Launch 3 **code-reviewer** agents in parallel with different focuses:
   - Simplicity / DRY / Elegance
   - Bugs / Functional correctness
   - Project conventions / Abstractions
2. Consolidate findings and identify highest severity issues.
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
3. Summarize:
   - What was built
   - Key decisions made
   - Files modified
   - Suggested next steps
4. Ask the user if they want to archive the change now.
   - If yes, suggest running `/opsx:archive`
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

Ready to archive. Run `/opsx:archive` when done.
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
- Use `openspec instructions` to get artifact templates and rules - don't invent structure.
- `context` and `rules` from instructions are constraints for YOU, not content for the artifact files.
- Keep code changes minimal and scoped to each task.
- If implementation reveals design issues, suggest updating OpenSpec artifacts before continuing.
- Pause on errors, blockers, or unclear requirements - don't guess.
- Use contextFiles from CLI output, don't assume specific file names.
