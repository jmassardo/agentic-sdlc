# agentic-sdlc :: preToolUse hook (Windows / PowerShell)
#
# The security half of this plugin's "velocity AND safety" premise. Parallel
# pipelines commit fast and often; a leaked credential is the one mistake that
# cannot be fixed by a follow-up commit, because rotation - not reverting - is
# the only real remedy. So committed secrets are blocked mechanically rather
# than left to the Reviewer to catch by eye.
#
# Denies shell commands that appear to introduce a credential: known provider
# key formats, private key headers, high-entropy literals assigned to
# secret-shaped variable names, and `git add` / `git commit` of a real .env file.
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

$remedy = 'Never commit credentials: rotation is the only remedy once one lands in git history. ' +
    'Use a secrets manager (AWS Secrets Manager, Vault, GitHub Actions secrets), an environment ' +
    'variable injected at runtime, or a gitignored local config file, and commit only a ' +
    '.env.example with placeholder values.'

function Deny-Tool {
    param([string]$Finding)
    $result = [ordered]@{
        permissionDecision       = 'deny'
        permissionDecisionReason = "agentic-sdlc: $Finding $remedy"
    }
    Write-Output ($result | ConvertTo-Json -Compress -Depth 3)
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

# 1. Known credential formats - unambiguous, no placeholder check needed.
if ($payload -match '-----BEGIN [A-Z ]*PRIVATE KEY-----') {
    Deny-Tool 'this command embeds a private key block (-----BEGIN ... PRIVATE KEY-----).'
}
if ($payload -match '(AKIA|ASIA)[0-9A-Z]{16}') {
    Deny-Tool 'this command contains what looks like an AWS access key ID (AKIA/ASIA followed by 16 characters).'
}
if ($payload -match 'gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}') {
    Deny-Tool 'this command contains what looks like a GitHub token.'
}
if ($payload -match 'xox[abprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20}') {
    Deny-Tool 'this command contains what looks like a provider API token (Slack, OpenAI, Google, or GitLab format).'
}

# 2. Generic: a long, mixed-charset literal assigned to a secret-shaped name.
$assignment = '(?i)[A-Za-z0-9_.-]*(secret|token|password|passwd|api[_-]?key|access[_-]?key|' +
    'auth[_-]?key|private[_-]?key)[A-Za-z0-9_.-]*\s*[=:]\s*[\\"'']*([A-Za-z0-9+/=_.-]{16,})'
$placeholder = '(?i)change_?me|changeit|your[_-]|my[_-]secret|example|placeholder|dummy|sample|' +
    'redacted|test[_-]?only|not[_-]?a[_-]?real|fake|xxxx+|\*\*\*|^(true|false|null|none)$'

foreach ($m in [regex]::Matches($payload, $assignment)) {
    $value = $m.Groups[2].Value
    if ($value -match $placeholder) { continue }
    if ($value -match '^(\$|\{\{|<|%)') { continue }
    # Require mixed charset: a long all-lowercase word is prose, not a key.
    if ($value -notmatch '[0-9]') { continue }
    if ($value -notmatch '[A-Za-z]') { continue }
    Deny-Tool 'this command assigns what looks like a real credential to a secret-shaped variable name.'
}

# 3. Staging or committing a real .env file. Example/template variants are fine.
if ($payload -match 'git\s+(add|commit)(\s|\\)') {
    if ($payload -match '(^|[^A-Za-z0-9_./-])\.env([^A-Za-z0-9_.-]|\\|$)') {
        Deny-Tool ('this command stages or commits a .env file, which normally holds real ' +
            'credentials. Add .env to .gitignore and commit a .env.example instead.')
    }
}

Grant-Tool
