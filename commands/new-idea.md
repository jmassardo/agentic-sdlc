---
name: new-idea
description: Start the agentic-sdlc pipeline from a raw idea - hands off to the Product Manager agent to research, shape, and break the idea down into epics and atomic, agent-ready GitHub issues.
argument-hint: [a one-line description of your idea]
---

# New Idea

This is the front door to the **agentic-sdlc** pipeline. It routes a raw, unshaped idea into the
**Product Manager** agent, which owns everything from "I have an idea" to "here is a backlog of
atomic issues an autonomous coding agent can execute."

## What to do

1. **Capture the idea.**

   The user's idea is: `$ARGUMENTS`

   If that is empty, ask the user — in one short question — to describe their idea. Prompt them with:

   > What do you want to build? A rough one-or-two-sentence description is enough — who it's for,
   > what problem it solves, and anything you already know you want. I'll research it, shape it into
   > epics, and break it down into atomic issues.

   Do **not** interrogate them further. The Product Manager agent runs its own clarification pass;
   your only job here is to get the raw idea and hand it over.

2. **Confirm the target repository.**

   Establish which GitHub repository the epics and issues should be created in. Default to the
   repository of the current working directory (`gh repo view --json nameWithOwner`). If there is no
   repository, or the user clearly means a different one, ask which repo to use before handing off.

3. **Hand off to the Product Manager agent.**

   Invoke the **Product Manager** agent with the raw idea plus the target repository. Pass the idea
   through as close to verbatim as possible — do not pre-solve it, do not propose an architecture,
   and do not start writing issues yourself. Product Manager owns research, strategy, epic creation,
   issue decomposition, and issue expansion.

   Give it a handoff prompt along these lines:

   > New idea from the user, entering the agentic-sdlc pipeline.
   >
   > **Idea:** [verbatim idea]
   > **Repository:** [owner/repo]
   >
   > Run your full pipeline: research → strategy & design → epic creation (milestone + tracking
   > issue) → decomposition into base issues → expansion of every issue into an implementation plan
   > following the implementation-plan-format skill. When the backlog is expanded, hand off to
   > **Dispatcher** to batch the work into parallel-safe waves.

4. **Stay out of the way.**

   Once the handoff is made, let the pipeline run. Product Manager will come back to the user for
   scope decisions; the pipeline continues Product Manager → Dispatcher → Tech Lead (×N in
   parallel) → Integrator → Platform & Ops.

## What this command does NOT do

❌ Design the solution — that is Strategy & Design's job, invoked by Product Manager
❌ Create issues or milestones directly — that is Product Manager's job
❌ Write code — that is the Tech Lead pipeline's job
❌ Decide what can run in parallel — that is Dispatcher's job
