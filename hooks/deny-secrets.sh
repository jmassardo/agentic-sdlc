#!/usr/bin/env bash
# agentic-sdlc :: preToolUse hook
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
#   exit   - ALWAYS 0. preToolUse command hooks are fail-closed: a non-zero
#            exit denies the tool call outright, so we never let an internal
#            error of this script block legitimate work.

set -u

allow() { printf '{}\n'; exit 0; }

REMEDY="Never commit credentials: rotation is the only remedy once one lands in git history. Use a secrets manager (AWS Secrets Manager, Vault, GitHub Actions secrets), an environment variable injected at runtime, or a gitignored local config file, and commit only a .env.example with placeholder values."

deny() {
  printf '{"permissionDecision":"deny","permissionDecisionReason":"agentic-sdlc: %s %s"}\n' "$1" "$REMEDY"
  exit 0
}

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow

# Only police shell-executing tools, matching the deny-tmp-paths hook.
tool="$(printf '%s' "$payload" \
  | sed -n 's/.*"toolName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n 1)"

case "$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')" in
  *bash*|*shell*|*execute*|*command*|*terminal*|*run*) ;;
  *) allow ;;
esac

# ---------------------------------------------------------------------------
# 1. Known credential formats. These are unambiguous - no placeholder check.
# ---------------------------------------------------------------------------
if printf '%s' "$payload" | grep -Eq -- '-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  deny "this command embeds a private key block (-----BEGIN ... PRIVATE KEY-----)."
fi

if printf '%s' "$payload" | grep -Eq '(AKIA|ASIA)[0-9A-Z]{16}'; then
  deny "this command contains what looks like an AWS access key ID (AKIA/ASIA followed by 16 characters)."
fi

if printf '%s' "$payload" | grep -Eq 'gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}'; then
  deny "this command contains what looks like a GitHub token."
fi

if printf '%s' "$payload" | grep -Eq 'xox[abprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20}'; then
  deny "this command contains what looks like a provider API token (Slack, OpenAI, Google, or GitLab format)."
fi

# ---------------------------------------------------------------------------
# 2. Generic: a long, mixed-charset literal assigned to a secret-shaped name.
#    Placeholders, variable references, and template expressions are allowed.
# ---------------------------------------------------------------------------
# Quote characters that may sit between the '=' and the value: a backslash
# (JSON-escaped double quote), a double quote, or a single quote.
q="[\\\\\"']*"

candidates="$(printf '%s' "$payload" \
  | grep -Eoi "[A-Za-z0-9_.-]*(secret|token|password|passwd|api[_-]?key|access[_-]?key|auth[_-]?key|private[_-]?key)[A-Za-z0-9_.-]*[[:space:]]*[=:][[:space:]]*${q}[A-Za-z0-9+/=_.-]{16,}" \
  2>/dev/null || true)"

if [ -n "$candidates" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    value="${line##*[=:]}"
    value="$(printf '%s' "$value" | sed "s/^[[:space:]]*//; s/^[\\\\\"']*//")"

    # Placeholders, references, and templating are not secrets.
    printf '%s' "$value" | grep -Eqi \
      'change_?me|changeit|your[_-]|my[_-]secret|example|placeholder|dummy|sample|redacted|test[_-]?only|not[_-]?a[_-]?real|fake|xxxx+|\*\*\*|^(true|false|null|none)$' \
      && continue
    case "$value" in
      '$'*|'{{'*|'<'*|'%'*) continue ;;
    esac

    # Require mixed charset: a long all-lowercase word is prose, not a key.
    printf '%s' "$value" | grep -Eq '[0-9]' || continue
    printf '%s' "$value" | grep -Eq '[A-Za-z]' || continue

    deny "this command assigns what looks like a real credential to a secret-shaped variable name."
  done <<EOF
$candidates
EOF
fi

# ---------------------------------------------------------------------------
# 3. Staging or committing a real .env file. Example/template variants are fine.
# ---------------------------------------------------------------------------
if printf '%s' "$payload" | grep -Eq 'git[[:space:]]+(add|commit)([[:space:]]|\\)'; then
  if printf '%s' "$payload" | grep -Eq '(^|[^A-Za-z0-9_./-])\.env([^A-Za-z0-9_.-]|\\|$)'; then
    deny "this command stages or commits a .env file, which normally holds real credentials. Add .env to .gitignore and commit a .env.example instead."
  fi
fi

allow
