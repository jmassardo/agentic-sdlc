# agentic-sdlc

A GitHub Copilot CLI plugin that packages a complete, opinionated **agentic software development lifecycle** — seven custom agents that take an idea from a one-sentence prompt all the way to deployed, quality-certified production code.

The pipeline is built around two coordinators and five specialists:

- **Product Manager** turns a raw idea into researched GitHub epics (milestones + tracking issues) and atomic, fully-expanded implementation issues.
- **Tech Lead** takes one issue at a time and orchestrates it through strategy, architecture, development, quality, and platform operations — with a 3-retry quality gate.

Every agent enforces the same non-negotiables: no shortcuts, no placeholders, no `/tmp`, and the **entire** test suite must pass before anything is called done.

## Pipeline

```
                    Raw Idea from User
                            ↓
    ┌────────────────────────────────────────────────────┐
    │ 0. Product Manager                                 │
    │    research → epics (milestones + tracking issues) │
    │    → atomic issues → expanded implementation plans  │
    └────────────────────────────────────────────────────┘
                            ↓  (one issue at a time)
    ┌────────────────────────────────────────────────────┐
    │ Tech Lead (orchestrator)                           │
    │                                                    │
    │  1. Strategy & Design                              │
    │     requirements, user stories, design specs       │
    │            ↓                                       │
    │  2. Architecture & Security                        │
    │     architecture, data models, security controls   │
    │            ↓                                       │
    │  3. Development                                    │
    │     production-quality implementation + tests      │
    │            ↓                                       │
    │  4. Quality                                        │
    │     unit, integration, E2E, perf, security         │
    │       ├── fail ──► back to Development (max 3x) ──┐ │
    │       │                                          │ │
    │       │◄─────────────────────────────────────────┘ │
    │       └── pass                                     │
    │            ↓                                       │
    │  5. Platform & Ops                                 │
    │     CI/CD, deploy, monitoring, rollback            │
    └────────────────────────────────────────────────────┘
                            ↓
                          ✅ Done
                            │
     backlog / scope change │
                            ↓
                    Product Manager
                  (revise + re-expand issues)
```

## Installation

```shell
copilot plugin install jmassardo/agentic-sdlc
```

Verify it loaded:

```shell
copilot plugin list
```

Then, in an interactive Copilot CLI session, list the agents it added:

```
/agent
```

To install a local checkout while developing:

```shell
copilot plugin install ./agentic-sdlc
```

To remove it:

```shell
copilot plugin uninstall agentic-sdlc
```

## Usage

Start new work with the **Product Manager** agent — it is the entry point for this pattern:

```
/agent Product Manager
```

> I want users to be able to share their saved designs with a public link.

It will research, delegate story writing to Strategy & Design, create a GitHub milestone and epic tracking issue, break the epic into atomic issues, expand every issue with acceptance criteria and file-level implementation notes, and then hand issues one at a time to **Tech Lead** for execution.

If you already have a well-specified issue, you can skip straight to **Tech Lead**. If you just want requirements and design for something, go directly to **Strategy & Design**.

## Agents

| Agent | Role |
|-------|------|
| **Product Manager** | Entry point for new work. Researches the idea (market, technical, competitive, codebase), delegates story writing to Strategy & Design, creates GitHub milestones + epic tracking issues, breaks epics into atomic task issues, and cycles through every issue to write a concrete implementation plan back into it. **Handoffs:** → Strategy & Design (refine requirements), → Tech Lead (execute issue). |
| **Tech Lead** | Orchestrator. Runs one work item through the full five-phase pipeline, accumulating context between phases, tracking progress with todos, applying skip logic for small changes, and enforcing the quality gate with up to 3 retry cycles. Writes no code itself. **Handoffs:** → Product Manager (update backlog when scope changes). |
| **Strategy & Design** | Business analysis, product management, work breakdown, UI/UX, accessibility (WCAG 2.1 AA), and documentation planning. Produces INVEST user stories with Given-When-Then acceptance criteria and a complete handoff package. **Handoffs:** → Architecture & Security (design architecture), → Product Manager (update backlog). |
| **Architecture & Security** | System architecture, data models, data engineering, security architecture, compliance, and technical debt management. Turns the story package into technical specs, API contracts, and security controls. **Handoffs:** → Development (start development), → Strategy & Design (refine requirements). |
| **Development** | Technical leadership and senior implementation. Turns architecture into production-quality code with unit tests — no TODOs, no placeholders, no partial features. **Handoffs:** → Quality (start testing), → Architecture & Security (security review), → Strategy & Design (fix requirements issue). |
| **Quality** | Test architecture plus unit, integration, E2E, performance, and security testing. Certifies the **entire** suite, not just the changed files, and reports defects back for rework. **Handoffs:** → Platform & Ops (deploy to production), → Development (report defects), → Strategy & Design (clarify requirements). |
| **Platform & Ops** | Platform engineering, DevOps, SRE, and security operations. Final agent in the chain: infrastructure, CI/CD, deployment with rollback, monitoring, and alerting. **Handoffs:** → Development (report app issue), → Architecture & Security (report infra issue), → Strategy & Design (new feature request). |

## Repository layout

```text
agentic-sdlc/
├── plugin.json                          # Plugin manifest
├── README.md
├── LICENSE
├── .gitignore
└── agents/
    ├── product-manager.agent.md         # Product Manager  (entry point)
    ├── orchestrator.agent.md            # Tech Lead
    ├── strategy-design.agent.md         # Strategy & Design
    ├── architecture-security.agent.md   # Architecture & Security
    ├── development.agent.md             # Development
    ├── quality.agent.md                 # Quality
    └── platform-ops.agent.md            # Platform & Ops
```

## Global rules enforced across every agent

- **All tests must pass — the entire suite, every time.** Lint, type checks, unit, integration, E2E, coverage thresholds, and the build. "Pre-existing" and "unrelated" failures still block completion.
- **Never write to `/tmp` or system temp directories.** Use `tempfile`/`tmp_path`, `fs.mkdtemp`, `mktemp -d`, or `$RUNNER_TEMP`.
- **No shortcuts, no deferrals, no placeholders.** No TODOs, no FIXMEs, no "TBD" acceptance criteria.
- **Respect established patterns and technology choices.** New frameworks or databases require explicit Architecture & Security review with justification.

## License

MIT © Jenna Massardo
