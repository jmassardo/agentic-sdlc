# agentic-sdlc :: preToolUse hook (Windows / PowerShell)
#
# Mechanically enforces the "NEVER use /tmp or system temp directories" rule
# from the quality-gate-checklist skill by denying any shell command that
# references a hardcoded /tmp or /var/tmp path.
#
# Contract:
#   stdin  - JSON: {sessionId, timestamp, cwd, toolName, toolArgs}
#   stdout - exactly one JSON object
#   exit   - ALWAYS 0. preToolUse command hooks are fail-closed, so an internal
#            error here must never deny a legitimate tool call.

$ErrorActionPreference = 'Continue'

function Grant-Tool {
    Write-Output '{}'
    exit 0
}

try {
    $payload = [Console]::In.ReadToEnd()
} catch {
    Grant-Tool
}

if ([string]::IsNullOrWhiteSpace($payload)) { Grant-Tool }

$tool = ''
try {
    $tool = ([regex]::Match($payload, '"toolName"\s*:\s*"([^"]*)"')).Groups[1].Value
} catch {
    Grant-Tool
}

if ($tool -notmatch '(?i)bash|shell|execute|command|terminal|run') { Grant-Tool }

$tmpPattern = '(^|[^A-Za-z0-9_./-])/(var/)?tmp(/|["''\s]|\\|$)'
if ($payload -match $tmpPattern) {
    $reason = 'agentic-sdlc: this command references a hardcoded /tmp or /var/tmp path. ' +
        'Shared system temp directories are insecure, non-portable, and collide across the parallel ' +
        'pipelines this plugin runs. Create a private temp directory instead: mktemp -d (shell), ' +
        'tempfile.mkdtemp() or the pytest tmp_path fixture (Python), fs.mkdtemp() (Node), or ' +
        '$RUNNER_TEMP / the runner workspace in CI. See the quality-gate-checklist skill.'
    $result = [ordered]@{
        permissionDecision       = 'deny'
        permissionDecisionReason = $reason
    }
    Write-Output ($result | ConvertTo-Json -Compress -Depth 3)
    exit 0
}

Grant-Tool
