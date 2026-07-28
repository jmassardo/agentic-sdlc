#!/usr/bin/env bash
# agentic-sdlc :: sessionStart hook
#
# Injects a short, generic reminder that this session is running inside the
# agentic-sdlc plugin pipeline. Deliberately persona-agnostic: the active
# agent's own instructions define its role, this only supplies shared context.
#
# Contract:
#   stdin  - JSON: {sessionId, timestamp, cwd, source, initialPrompt?}
#   stdout - exactly one JSON object with additionalContext
#   exit   - ALWAYS 0

set -u

cat >/dev/null 2>&1 || true

printf '%s\n' '{"additionalContext":"You are running inside the agentic-sdlc plugin pipeline. If you are acting as one of its agents (Product Manager, Dispatcher, Tech Lead, Strategy & Design, Architecture & Security, Standards & Consistency, Development, Reviewer, Quality, Integrator, Retrospective, Platform & Ops), stay in that persona and use its declared handoffs to move work forward rather than doing another agent'"'"'s job yourself. Two rules bind every agent: the ENTIRE test suite must pass before any work is declared complete, and no file may ever be written to /tmp or /var/tmp. Both are defined in full by the quality-gate-checklist skill. All work is tracked in GitHub Issues per the github-issue-tracking skill: no work outside an issue, and a comment on start, on handoff, and on every block or retry. Expanded issues follow the implementation-plan-format skill; parallel batching follows the parallel-safety-check skill. Two steps always require explicit human go-ahead: dispatching a parallel wave, and merging to main."}'

exit 0
