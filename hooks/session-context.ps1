# agentic-sdlc :: sessionStart hook (Windows / PowerShell)
#
# Injects a short, generic reminder that this session is running inside the
# agentic-sdlc plugin pipeline. Deliberately persona-agnostic.
#
# Contract:
#   stdin  - JSON: {sessionId, timestamp, cwd, source, initialPrompt?}
#   stdout - exactly one JSON object with additionalContext
#   exit   - ALWAYS 0

$ErrorActionPreference = 'Continue'

try { [Console]::In.ReadToEnd() | Out-Null } catch { }

$context = 'You are running inside the agentic-sdlc plugin pipeline. If you are acting as one of its ' +
    'agents (Product Manager, Dispatcher, Tech Lead, Strategy & Design, Architecture & Security, ' +
    'Standards & Consistency, Development, Quality, Integrator, Platform & Ops), stay in that persona ' +
    'and use its declared handoffs to move work forward rather than doing another agent''s job yourself. ' +
    'Two rules bind every agent: the ENTIRE test suite must pass before any work is declared complete, ' +
    'and no file may ever be written to /tmp or /var/tmp. Both are defined in full by the ' +
    'quality-gate-checklist skill. Expanded issues follow the implementation-plan-format skill; ' +
    'parallel batching follows the parallel-safety-check skill.'

Write-Output ([ordered]@{ additionalContext = $context } | ConvertTo-Json -Compress -Depth 3)
exit 0
