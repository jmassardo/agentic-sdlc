---
name: parallel-safety-check
description: Heuristics and a step-by-step procedure for deciding whether two or more GitHub issues can safely execute in parallel - comparing the file/module scope of their implementation plans, checking dependency links, and detecting shared migration, schema, contract, or registry changes. Use when batching issues into concurrent waves or when deciding if two in-flight changes will collide.
---

# Parallel Safety Check

This skill defines how to decide whether issues can run **at the same time, on separate branches, in separate pipelines** — or whether they must be serialized.

**Who uses this skill**
- **Dispatcher** — when batching issues into parallel waves. This is the core decision procedure.
- **Integrator** — when diagnosing why a wave produced conflicts, to feed the answer back into batching.
- **Product Manager** — when an issue keeps failing the check and needs re-scoping.
- **Retrospective** — when a wave's collisions turn out to be a pattern worth fixing in how issues are scoped.

The governing bias: **a false conflict costs one wave; a missed conflict costs an integration failure.** When in doubt, serialize.

## Serialization rules

Two issues **MUST be serialized** if **any** of the following holds.

| # | Condition | Why |
|---|-----------|-----|
| 1 | A lists `Blocked by: #B` (or B lists `Blocks: #A`) | Hard, declared dependency |
| 2 | Their `Files to Create or Modify` lists intersect | Guaranteed merge conflict |
| 3 | They change the same API contract, route, or endpoint shape | Semantic conflict invisible to per-branch testing |
| 4 | They change the same schema, model, or shared type | Two branches disagree about the data |
| 5 | Both add a database migration | Migration ordering / duplicate-head conflict |
| 6 | Both edit a central registry — routes table, DI container, exports barrel, `__init__.py`, design tokens, i18n catalog, feature flags | Structural conflict at a chokepoint file |
| 7 | B consumes an interface, type, or helper that A creates | Ordering dependency even with no declared blocker |
| 8 | Both modify shared config, CI workflow, or dependency manifests (`package.json`, `pyproject.toml`, lockfiles) | Lockfile and config conflicts are near-certain |
| 9 | Either issue's file list is missing, vague, or uses wildcards | Safety cannot be established; not dispatchable |

Two issues are **parallel-safe** only when **none** of these holds.

## Procedure

### Step 1 — Load every candidate issue
Pull all open issues under the epic's milestone with their bodies:

```bash
gh issue list --milestone "Epic: <name>" --state open \
  --json number,title,body,labels
```

### Step 2 — Extract the scope of each issue
From each issue body (see the `implementation-plan-format` skill), extract:
- **File list** — every path under `## Files to Create or Modify`
- **Declared dependencies** — `Blocked by:` / `Blocks:` references
- **Shared surfaces** — mentions of API routes, schemas, migrations, shared types, design tokens, registries, config, or dependency manifests in the Technical Approach

If an issue has no usable file list, stop: it fails rule 9. Return it to **Product Manager**.

### Step 3 — Diff the file scopes pairwise
For every candidate pair, intersect their normalized file paths. Any non-empty intersection ⇒ **serialize** (rule 2).

Treat these as intersecting even when the literal paths differ:
- The same module reached by different relative paths
- A file and a directory that contains it
- Generated files and the source they are generated from
- A migration directory shared by two "different" migration files (rule 5)

### Step 4 — Check declared dependencies
Apply rules 1 and 7. Rule 7 is the one people miss: a consumer issue can depend on a producer issue **without anyone writing down a blocker**. Read the Technical Approach sections and ask "does B reference something that only exists after A lands?"

### Step 5 — Check shared surfaces
Apply rules 3–6 and 8. These are the conflicts that pass every per-branch test suite and then explode at merge time, because `Quality` only ever validated one branch at a time.

### Step 6 — Build the wave
From the issues with no pairwise conflict, select a **maximal safe set**, preferring:
1. Issues that unblock the most downstream work (highest out-degree)
2. Foundational issues — schemas, migrations, shared types, contracts — **alone and early**; they are conflict magnets
3. Independent leaf issues (docs, isolated UI, isolated endpoints) batched aggressively

Practical wave size is **2–6** concurrent pipelines. Go higher only when the issues are genuinely disjoint (e.g. seven unrelated docs pages); beyond that, tracking and integration cost exceeds the throughput gain.

### Step 7 — Record the decision
Write wave membership and the serialization reasons into the epic tracking issue, so the reasoning survives:

```markdown
### Wave 2 — dispatched <date>
- [ ] #13 Add POST /designs/{id}/share — branch `issue-13-share-endpoint`
- [ ] #16 Add Share button to design detail page — branch `issue-16-share-button`
- [ ] #17 Document public sharing — branch `issue-17-sharing-docs`

Serialized to Wave 3:
- #14 — rule 2: shares `api/designs.py` with #13
- #15 — rule 7: consumes the token contract #13 creates
```

### Step 8 — Re-batch after every wave
Integration changes the codebase. **Recompute conflicts against the new state after each wave integrates** — never reuse a stale batching plan.

## Worked example

Seven issues under "Epic: Public Design Sharing":

| Issue | Files | Notes |
|-------|-------|-------|
| #12 | `models/design.py`, `migrations/00X_share_token.py` | Migration + schema |
| #13 | `api/designs.py`, `tests/test_designs_share.py` | POST share |
| #14 | `api/designs.py`, `tests/test_designs_share.py` | DELETE revoke |
| #15 | `api/public.py`, `routes/index.ts` | Public GET, consumes token contract |
| #16 | `ui/DesignDetail.tsx`, `ui/ShareDialog.tsx` | Share button |
| #17 | `docs/sharing.md` | Docs |
| #18 | `models/design.py` | Adds an index |

Analysis:
- **#12 vs everything** — rules 4 and 5: foundational schema + migration ⇒ **Wave 1, alone**
- **#13 vs #14** — rule 2: both touch `api/designs.py` ⇒ serialize
- **#15 vs #13** — rule 7: #15 consumes the token contract #13 creates ⇒ must follow #13
- **#18 vs #12** — rule 2: both touch `models/design.py` ⇒ must follow #12
- **#16, #17** — disjoint from everything ⇒ batch freely

Resulting waves:
- **Wave 1:** #12 (alone)
- **Wave 2:** #13, #16, #17, #18 — pairwise disjoint
- **Wave 3:** #14, #15 — disjoint from each other (`api/designs.py` vs `api/public.py`), and #15's producer (#13) landed in Wave 2

## When in doubt

- **Doubt about file overlap** → serialize
- **Doubt about whether B needs A** → serialize
- **Doubt because the file list looks incomplete** → do not dispatch; return the issue to **Product Manager**
- **Two issues that keep colliding across waves** → they are one issue wearing two hats; ask **Product Manager** to merge them

## Mid-flight collisions

If two in-flight pipelines turn out to collide after dispatch:
1. Stop the **later-started** pipeline before it opens a PR
2. Let the earlier one finish and integrate
3. Re-dispatch the stopped issue in the next wave, re-checked against the new codebase state
4. Record the missed rule so the next batching pass catches it
