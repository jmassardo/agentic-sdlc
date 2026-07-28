---
name: changelog-convention
description: A Keep a Changelog convention for maintaining a running CHANGELOG.md as many small atomic PRs merge, so release history stays coherent instead of fragmenting across dozens of tiny commits. Use when merging a wave, cutting a release, or writing release notes.
---

# Changelog Convention

This pipeline produces a **large number of very small PRs** by design. That is good for merge safety and bad for release history: fifty commits titled `fix: add null check to cart total` tell a human nothing about what shipped.

This skill exists to close that gap. The changelog is written **as waves merge**, in human-facing language, so that cutting a release is a formatting step rather than an archaeology project.

**Who uses this skill**
- **Integrator** — updates `## [Unreleased]` as it merges each wave. This is where entries are actually written.
- **Platform & Ops** — cuts `Unreleased` into a version at deploy time and produces release notes from it.
- **Tech Lead** — ensures a user-visible change carries a changelog-worthy summary out of its pipeline.

## The Rule

**Every user-visible change gets exactly one changelog entry, written when its PR merges.**

Corollaries:
- Internal-only changes (refactors, test additions, CI tweaks, dependency bumps with no behavioral effect) get **no** entry. A changelog padded with noise is as useless as no changelog.
- One entry per *issue*, not per commit. An issue that took four commits is still one line.
- Entries are written for the **person using the software**, not the person who wrote it.

## Format

`CHANGELOG.md` lives at the repo root and follows [Keep a Changelog](https://keepachangelog.com/) with [Semantic Versioning](https://semver.org/).

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Share links for saved designs, with configurable expiry (#142)

### Changed
- Cart totals now round per-line instead of at checkout (#151)

### Fixed
- Timezone drift on scheduled exports for non-UTC users (#149)

## [1.4.0] - 2026-03-14

### Added
- Bulk export to CSV (#118, #121, #124)

[Unreleased]: https://github.com/OWNER/REPO/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/OWNER/REPO/compare/v1.3.0...v1.4.0
```

### Categories

Use only these six, in this order, omitting any that are empty:

| Category | For |
|----------|-----|
| `Added` | New features |
| `Changed` | Changes to existing behavior |
| `Deprecated` | Soon-to-be-removed features |
| `Removed` | Features removed in this release |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability fixes — always call these out explicitly |

### Entry style

- One line, present tense, no trailing period
- Lead with what changed for the user, not the implementation
- End with the issue number(s) in parentheses: `(#142)` or `(#118, #121, #124)`
- Note breaking changes with a bold **BREAKING:** prefix and a one-line migration hint

```markdown
- **BREAKING:** `GET /api/designs` now paginates by default, max 100 per page.
  Pass `?limit=` to control size (#166)
```

## Feature-Flagged Work

Small atomic PRs merge to `main` behind feature flags before the feature is complete. Those PRs are merged but **not shipped**, and the changelog reflects user-visible reality:

- Do **not** write an entry when a flagged-off increment merges
- Write the entry when the flag is **turned on** for users, under the release that enables it
- If a feature ships enabled-by-default in the same release it was built, write one entry for the whole feature — not one per atomic PR

This is the main reason changelog entries are per-issue-outcome rather than per-merge. `Integrator` should note flagged work in the wave summary comment and hold the entry until `Platform & Ops` flips the flag.

## Workflow

**Integrator, as each wave merges:**
1. For each merged issue, decide: user-visible, or internal-only?
2. If user-visible and not flagged off, add one line under the right category in `## [Unreleased]`
3. Commit the changelog update as part of the integration commit, not as a separate PR
4. Note in the wave summary issue comment which entries were added, and which were withheld pending a flag flip

**Platform & Ops, at release time:**
1. Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it
2. Choose the version from the entries themselves: any `Removed` or **BREAKING** → major; any `Added` → minor; only `Fixed`/`Security` → patch
3. Add the newly-enabled flagged features that this deploy turns on
4. Update the comparison links at the bottom
5. Tag the release and paste the section verbatim as the GitHub release body — no rewriting
6. Link the release back to the epic milestone it completes

## Anti-Patterns

- ❌ Generating the changelog from `git log` at release time — that is the fragmentation problem, not the fix
- ❌ One entry per commit or per PR
- ❌ Entries that name files, functions, or internal classes
- ❌ Silently shipping a breaking change without a **BREAKING:** marker
- ❌ Letting `Unreleased` accumulate for months — it should be cut at every deploy
- ❌ Editing an already-released version section; corrections go in the next release
