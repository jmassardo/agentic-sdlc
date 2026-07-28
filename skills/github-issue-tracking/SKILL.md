---
name: github-issue-tracking
description: The system-of-record convention for the agentic-sdlc pipeline - every atomic unit of work must exist as a GitHub issue before any agent starts, and every agent must post a start comment, a handoff comment, and any defect or retry comment to that issue, plus maintain its status label and milestone. Use whenever starting work, handing off, blocking, reporting a defect, retrying, dispatching a wave, or integrating a branch.
---

# GitHub Issues Are the System of Record

Agents move fast and work in parallel. Without a durable, human-readable trail, a human watching a
dozen concurrent pipelines has no idea what is happening, what already happened, or why a decision
was made. Agent-to-agent context is invisible, ephemeral, and lost the moment a session ends.

**GitHub Issues are the pipeline's system of record.** The issue thread — not the agent transcript —
is the authoritative history of a unit of work. If it is not on the issue, it did not happen.

This is not bookkeeping. It is the mechanism that keeps a human in control of an accelerated,
parallel system: any person can open the repository's issue list at any moment and see exactly which
agent is doing what, how far along it is, what went wrong, and how many times it has been retried.

**Who uses this skill: all of them.** Every agent in the plugin — `Product Manager`, `Dispatcher`,
`Tech Lead`, `Strategy & Design`, `Architecture & Security`, `Standards & Consistency`,
`Development`, `Reviewer`, `Quality`, `Integrator`, `Retrospective`, and `Platform & Ops` — is bound
by every rule below.

---

## Rule 1: No work happens outside an issue

**Every atomic unit of work MUST exist as a GitHub issue before any agent starts on it.** No
exceptions, no "quick fixes," no "I'll file it after."

- `Product Manager` creates the issues, expanded per the `implementation-plan-format` skill.
- `Dispatcher` refuses to dispatch anything that is not a real, expanded issue.
- Every other agent receives an issue number and works against it.
- If work is discovered mid-pipeline that falls outside the current issue's scope, **do not do it.**
  File a new issue (or hand back to `Product Manager`) and link it. That is the scope-creep boundary,
  and it is enforced by `Reviewer`.

If you find yourself working without an issue number, stop and get one.

---

## Rule 2: Post a start comment when you begin

The moment an agent picks up an issue, before doing substantive work, it posts a comment naming
itself, its phase, and what it is about to do.

```markdown
### 🤖 Development — started

**Phase:** 3 of 6 (Implementation)
**Agent:** Development
**Branch:** `issue-42-share-link-model`

Implementing the `SharedLink` model and its token generation per the approved architecture spec.
Touching `models/shared_link.py`, `migrations/`, and `tests/test_shared_link.py`.
```

**Required fields:** agent name, phase, and a one-line summary of the intended work. Include the
branch when the agent works on code.

---

## Rule 3: Post a handoff comment when you finish

Every handoff defined in an agent's frontmatter MUST be mirrored as an issue comment. The reader
should be able to reconstruct the entire pipeline run from the thread alone.

```markdown
### ✅ Development — complete, handing off to Reviewer

**What I did**
- Added `SharedLink` model with a 32-byte URL-safe token and an `expires_at` column
- Added migration `0043_shared_link.py`
- Added 11 unit tests covering token uniqueness, expiry, and revocation

**Files changed:** `models/shared_link.py`, `migrations/0043_shared_link.py`, `tests/test_shared_link.py`

**Gate status:** full suite green — lint, types, 1,204 unit, 88 integration, 31 E2E, coverage 84%

**Handing off to:** Reviewer (code review against the implementation plan)
```

**Required fields:** what was done, files touched, the state of the quality gate if the agent ran it,
and the explicit next agent. Match the handoff `label` from the frontmatter so the thread and the
wiring agree.

---

## Rule 4: Blocks, defects, and retries go on the issue

Anything that sends work backwards or stops it MUST be a comment. This is the most important rule in
practice, because retry loops are exactly where a human needs visibility and where agent-to-agent
context is most likely to hide a problem.

- `Reviewer` requesting changes → comment with the specific findings.
- `Quality` reporting defects → comment with failures, reproduction, and severity.
- `Integrator` hitting a cross-feature regression → comment on **both** affected issues.
- `Tech Lead` starting quality-gate retry 2 of 3 → comment naming the attempt number.
- Any agent blocked on a dependency, an ambiguity, or a missing decision → comment, apply
  `status:blocked`, and say precisely what would unblock it.

```markdown
### 🔁 Reviewer — changes requested (retry 1 of 3)

**BLOCKING**
1. `services/share.py:88` calls `Token.generate_secure()` — that method does not exist on `Token`
   (`models/token.py` has `create_secure()`). Hallucinated API.
2. Diff touches `services/billing.py`, which is not in the issue's declared file scope. Out of scope.

**Handing back to:** Development
```

Never relay a defect only through agent context. If a human cannot read the retry history on the
issue, the retry history does not exist.

---

## Rule 5: Status labels track pipeline position

Apply exactly one `status:*` label at a time, updating it as the issue advances. This makes the
repository's issue list a live dashboard of every in-flight pipeline.

| Label | Meaning | Applied by |
|---|---|---|
| `status:backlog` | Expanded and ready, not yet scheduled | `Product Manager` |
| `status:queued` | Assigned to a wave, awaiting dispatch | `Dispatcher` |
| `status:in-progress` | A `Tech Lead` pipeline is actively working it | `Dispatcher` on dispatch |
| `status:in-review` | With `Reviewer` for code review | `Reviewer` |
| `status:in-testing` | With `Quality` for full-suite certification | `Quality` |
| `status:blocked` | Stopped, awaiting a decision or dependency | any agent |
| `status:integrated` | Merged into the integration branch, cross-feature tests green | `Integrator` |
| `status:deployed` | Shipped to production | `Platform & Ops` |

Supporting labels, applied additively and left in place:

| Label | Meaning |
|---|---|
| `agentic-sdlc` | Created by this pipeline — distinguishes agent work from human-filed issues |
| `epic` | An epic tracking issue, not an atomic unit of work |
| `wave:N` | The parallel wave this issue was dispatched in |
| `tech-debt` | Filed by `Retrospective` from a drift scan |
| `needs-human` | Awaiting a human checkpoint decision (wave dispatch, merge to `main`) |

Create labels if they do not exist. Remove the previous `status:*` label when applying a new one —
two status labels at once means nobody can trust either.

---

## Rule 6: Epics get milestones, atomic issues get linked

- Each epic is a **GitHub Milestone**, plus an `epic`-labeled tracking issue describing scope.
- Every atomic issue is assigned to its epic's milestone at creation time.
- The epic tracking issue holds a task list linking every atomic issue, so the milestone's progress
  bar and the epic's checklist agree.
- `Dispatcher` posts wave composition to the **epic** issue; per-issue dispatch details go on the
  **atomic** issues.
- `Integrator` posts the wave's integration result to the epic issue and the per-issue merge result
  to each atomic issue.

---

## Rule 7: Human checkpoints are recorded, not just spoken

The two human approval gates — `Dispatcher` proposing a wave, and `Integrator` merging to `main` —
must leave a written record. Post the proposal as a comment on the epic issue, apply `needs-human`,
and post the human's decision when it arrives before proceeding. A verbal "go ahead" in a chat
session that nobody can find later is not an approval trail.

---

## How to post

Use whichever tooling the surrounding agent file already uses — the `github/*` MCP tools when
available, otherwise the `gh` CLI:

```bash
gh issue comment 42 --body-file <comment-file>
gh issue edit 42 --add-label "status:in-review" --remove-label "status:in-progress"
gh issue edit 42 --milestone "Epic: Shareable Designs"
gh issue create --title "..." --body-file <plan-file> --milestone "..." --label "agentic-sdlc,status:backlog"
```

Write comment bodies from a file or a heredoc rather than a long `--body` string, so Markdown
formatting survives. Never write that file to `/tmp` or `/var/tmp` — see the `quality-gate-checklist`
skill.

---

## Anti-patterns

- ❌ **Doing work first and filing the issue afterwards** — the trail must be live, not reconstructed.
- ❌ **Silent handoffs** — passing context to the next agent without a comment. The next agent knows;
  the human does not.
- ❌ **Batching all comments at the end** — a single summary comment posted after everything finished
  defeats the entire point, which is real-time visibility.
- ❌ **Stale status labels** — an issue sitting on `status:in-progress` after it merged.
- ❌ **Defects relayed only in agent context** — retry loops are invisible unless written down.
- ❌ **Vague comments** — "made some changes" tells a human nothing. Name files, tests, and decisions.
- ❌ **Multiple `status:*` labels at once** — exactly one, always.
