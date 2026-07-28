---
name: implementation-plan-format
description: The canonical template for expanding a GitHub issue into an atomic, autonomous-agent-ready implementation plan - acceptance criteria, technical approach, file/module scope, dependencies, and definition of done. Use when writing or reviewing an issue that a coding agent will execute unattended, and when checking whether an issue is atomic and complete enough to dispatch.
---

# Implementation Plan Format

This skill defines the **single canonical shape** of an expanded GitHub issue in the agentic-sdlc pipeline. An issue in this format is the contract between planning and execution: it must be complete enough that an autonomous coding agent can finish it without asking a question, and scoped tightly enough that it can run concurrently with other issues.

**Who uses this skill**
- **Product Manager** — when expanding base issues (Phase 5, the expansion loop). This is the template to write.
- **Dispatcher** — when validating that an issue is atomic and ready before dispatching it. This is the template to check against.
- **Tech Lead / Development** — when reading an issue as the authoritative spec.

## The template

Write this into the **issue body** (preferred, so it is the first thing an agent reads). Post it as a comment only when the original body must be preserved verbatim.

```markdown
## Context
[Why this task exists, one paragraph, linking to the epic issue]

## Acceptance Criteria
- [ ] Given [context], when [action], then [outcome]
- [ ] Given [context], when [action], then [outcome]
- [ ] Edge case: [specific edge case and expected behavior]
- [ ] Error case: [specific failure and expected handling]

## Technical Approach
[Concrete approach: the pattern to follow, the existing code to extend,
the API shape, the data model changes. Reference existing files by path.]

## Files to Create or Modify
- `path/to/file.ts` — [what changes and why]
- `path/to/other.py` — [what changes and why]
- `path/to/test_file.py` — [tests to add]

## Test Plan
- Unit: [what to test]
- Integration: [what to test]
- E2E: [only if the task touches a critical user path]

## Definition of Done
- [ ] Implementation complete, no TODOs or placeholders
- [ ] Tests written and the FULL suite passes (see the quality-gate-checklist skill)
- [ ] Documentation updated if behavior changed

## Out of Scope
[Explicitly excluded work, with issue links where that work lives instead]

## Dependencies
Blocked by: #N
Blocks: #M
```

## Section rules

### Context
One paragraph. States the user-facing or system-facing reason the task exists and links the epic tracking issue. An agent that reads only this section should understand why it is being asked to do the work.

### Acceptance Criteria
- **Given-When-Then, always.** "Works correctly" is not a criterion.
- Every criterion must be **independently verifiable** by running something.
- Include at least one **edge case** and at least one **error case**. Bugs hide in exactly the branches nobody wrote down.
- No criterion may depend on work in another issue unless that issue is listed under Dependencies.

### Technical Approach
- Name the **existing pattern to follow** and the file that establishes it. "Follow the pattern in `api/designs.py:88`" beats three paragraphs of prose.
- Specify the concrete API shape, schema change, or component contract — not "add an endpoint".
- Call out anything the implementer must **not** change (shared contracts, public interfaces used by sibling issues).
- If the approach requires a new dependency, framework, or pattern, say so explicitly so `Standards & Consistency` and `Architecture & Security` can rule on it.

### Files to Create or Modify
This section is **load-bearing** — `Dispatcher` uses it to compute parallel safety (see the `parallel-safety-check` skill). It must be:
- **Complete** — every file the change touches, including tests, migrations, config, and docs
- **Specific** — real paths, not `src/**` or "the API layer"
- **Honest** — if you don't know the file set, the issue is not ready to expand; go read the code first

An issue with a missing, vague, or wildcard file list **cannot be dispatched**.

### Test Plan
State what to test at each level, not just "add tests". Skip a level explicitly ("E2E: none — no user-facing path") rather than omitting it silently.

### Definition of Done
Always includes a full-suite pass. Do not restate the full checklist here — reference the `quality-gate-checklist` skill, which is the source of truth.

### Out of Scope
The cheapest section to write and the most valuable in review. It stops an autonomous agent from helpfully expanding the blast radius, and it stops humans from re-litigating scope later. Link the issues where excluded work actually lives.

### Dependencies
Use GitHub issue references so the graph is machine-readable:
- `Blocked by: #N` — cannot start until #N merges
- `Blocks: #M` — #M is waiting on this

## Atomicity test

An issue is atomic when **all** of these are true:

- [ ] It has exactly one concern and one clear "done"
- [ ] It can be completed and reviewed as a single PR
- [ ] It is ≤1 day of work for a competent agent
- [ ] It includes its own tests — never split "code" and "tests" into separate issues
- [ ] It can be verified without merging any other issue, or its blockers are explicit
- [ ] Its file list is small and specific enough to reason about conflicts

If an issue fails any of these, **split it** and re-expand each piece, then update the epic tracking issue's task list.

## Anti-patterns

❌ "Implement the feature" — decompose it
❌ "Add tests" as its own trailing issue — tests belong inside each task issue
❌ "See the epic for details" — every issue must stand alone
❌ "Refactor as needed" — name the refactor or leave it out
❌ "Frontend work" / "Backend work" as a title — describe the actual change
❌ `Files: src/` — a wildcard is not a file list
❌ "TBD" / "TODO" / "details to follow" anywhere in the body
❌ Hardcoded `/tmp` or `/var/tmp` paths in the approach or criteria — specify secure temp creation instead (`tempfile`, pytest `tmp_path`, `fs.mkdtemp`, `mktemp -d`)

## Readiness check (used by Dispatcher)

Before dispatching, confirm:

- [ ] All template sections present and populated (no placeholders)
- [ ] Acceptance criteria are Given-When-Then and verifiable
- [ ] `Files to Create or Modify` is complete, specific, and wildcard-free
- [ ] Test plan names levels explicitly
- [ ] Dependencies use `Blocked by:` / `Blocks:` issue references
- [ ] Out of scope is stated
- [ ] The atomicity test passes

If any check fails, return the issue to **Product Manager** rather than dispatching it.
