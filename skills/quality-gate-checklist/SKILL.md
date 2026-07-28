---
name: quality-gate-checklist
description: The canonical, non-negotiable definition of done for the agentic-sdlc pipeline - the full lint, type-check, unit, integration, E2E, coverage, and build suite that must pass across the ENTIRE codebase, plus the prohibition on hardcoded /tmp and system temp directories. Use before declaring any work complete, certifying a branch, or integrating a merge.
---

# Quality Gate Checklist

This skill is the **single source of truth** for what "done" means in the agentic-sdlc pipeline. Every agent that declares work complete is bound by it.

**Who uses this skill**
- **Quality** — certifying a branch. Nothing ships without this passing.
- **Tech Lead** — enforcing the gate across every phase, and reviewing sub-agent claims against it.
- **Integrator** — re-running this after **every single merge**, because per-branch certification never saw the combined state.
- **Reviewer** — pre-checking the diff for violations (`/tmp` paths, added TODOs, stubs, weakened tests) before a single test runs.
- **Development** — self-checking before handoff, so `Quality` isn't the first to find a failure.

---

## Rule 1: ALL tests must pass — the entire suite, every time

**No agent may declare work complete unless the ENTIRE test suite passes.** This is the most critical quality gate in the pipeline.

### "All tests" means all of it

- [ ] **Lint** — every rule across the entire codebase (Ruff, ESLint, and any project-specific linters)
- [ ] **Type checks** — the entire codebase (mypy, TypeScript `tsc`)
- [ ] **Unit tests** — every unit test in every module (pytest, Vitest), **not just tests related to the change**
- [ ] **Integration tests** — the full integration suite
- [ ] **E2E tests** — the full end-to-end suite (Playwright)
- [ ] **Coverage** — thresholds met (≥80%)
- [ ] **Build** — succeeds (for example, frontend `npm run build`)

Discover the actual commands from the project itself — its task runner, `package.json` scripts, `Makefile`, `pyproject.toml`, or CI workflow. Do not invent commands, and do not run a narrower subset than CI runs.

### Why this is non-negotiable

**CI runs the full suite on every PR.** If any single check fails anywhere, the PR is rejected. There is no such thing as "only my tests need to pass."

### Enforcement when reviewing sub-agent output

- A **Development** agent says "all related tests pass" → **send it back.** They must run the FULL suite.
- A **Quality** agent validates only the changed files → **send it back.** They must certify the ENTIRE suite.
- Any agent reports failures as "pre-existing" or "unrelated" → **those still must be fixed** before the work is complete.
- Any agent weakens, skips, `xfail`s, or deletes a test to make the suite green → **reject it.** That is falsifying the gate, not passing it.
- A test is genuinely flaky → quarantine it **with a filed issue and a named owner**, never with a silent skip.

### Extra checks at integration time

`Integrator` runs everything above after **each** merge, plus:

- [ ] No unresolved conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) anywhere in the tree
- [ ] Database migrations apply cleanly **from scratch**, not just incrementally
- [ ] The application boots
- [ ] Every previously-merged issue's acceptance criteria still hold
- [ ] No duplicated abstractions introduced by parallel work (two helpers doing the same job)

---

## Rule 2: NEVER use `/tmp` or system temp directories

**No agent may write files to `/tmp`, `/var/tmp`, or any hardcoded system temporary directory.** This applies to application code, tests, scripts, build processes, and CI/CD pipelines alike.

### Why

- `/tmp` is shared across all users and processes on the machine — it is a real security risk (symlink attacks, information disclosure, collisions between concurrent runs)
- Hardcoded temp paths are not portable across environments, containers, or CI runners
- Concurrent pipelines in this plugin run side by side; a fixed path in `/tmp` is a collision waiting to happen

### Use instead

| Context | Correct approach |
|---------|------------------|
| Python | `tempfile.mkdtemp()`, `tempfile.NamedTemporaryFile()` |
| Python tests | pytest `tmp_path` / `tmp_path_factory` fixtures |
| TypeScript / Node | `fs.mkdtemp()`, or `os.tmpdir()` with a unique subdirectory |
| Shell | `mktemp -d` |
| CI/CD | The runner workspace directory or `$RUNNER_TEMP` |
| Build artifacts | Project-local directories (for example `./build`, `./.cache`) |

### Enforcement

- Any hardcoded `/tmp` or `/var/tmp` path found in a diff, spec, issue body, or acceptance criterion is a **defect** — flag it and send it back for correction.
- `Standards & Consistency` treats this as a **BLOCKING** finding, always.
- This plugin also enforces the rule mechanically: a `preToolUse` hook denies shell commands that reference `/tmp` or `/var/tmp` paths.

---

## Rule 3: No shortcuts, no deferrals, no placeholders

Work is not complete if it contains any of:

- [ ] `TODO`, `FIXME`, or `XXX` markers added by this change
- [ ] Placeholder implementations, stubbed returns, or commented-out logic
- [ ] Unhandled edge cases or error paths that the acceptance criteria named
- [ ] "We'll add tests later" / "we'll wire this up in a follow-up"
- [ ] Documentation left stale when behavior changed

If the work cannot be finished completely, report the blocker — do not hand off a partial result described as complete.

---

## Pass/fail report format

When certifying, report explicitly. "Tests pass" is not a certification.

```markdown
## Quality Gate Report
**Scope:** [branch / integration branch] @ [commit]

| Check | Command | Result |
|-------|---------|--------|
| Lint | `<project command>` | ✅ / ❌ |
| Types | `<project command>` | ✅ / ❌ |
| Unit | `<project command>` | ✅ / ❌ (N passed) |
| Integration | `<project command>` | ✅ / ❌ (N passed) |
| E2E | `<project command>` | ✅ / ❌ (N passed) |
| Coverage | `<project command>` | ✅ / ❌ (N% vs ≥80%) |
| Build | `<project command>` | ✅ / ❌ |
| No `/tmp` paths | `grep` scan of the diff | ✅ / ❌ |

**Verdict:** CERTIFIED | REJECTED — [defect summary]
```

A verdict of CERTIFIED requires **every** row to be ✅. There is no partial credit.
