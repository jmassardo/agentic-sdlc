#!/usr/bin/env bash
# agentic-sdlc :: preToolUse hook
#
# Mechanically enforces the "NEVER use /tmp or system temp directories" rule
# from the quality-gate-checklist skill by denying any shell command that
# references a hardcoded /tmp or /var/tmp path.
#
# Contract:
#   stdin  - JSON: {sessionId, timestamp, cwd, toolName, toolArgs}
#   stdout - exactly one JSON object
#   exit   - ALWAYS 0. preToolUse command hooks are fail-closed: a non-zero
#            exit denies the tool call outright, so we never let an internal
#            error of this script block legitimate work.

set -u

allow() { printf '{}\n'; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow

# Only police shell-executing tools. File edits are handled by review, not here.
tool="$(printf '%s' "$payload" \
  | sed -n 's/.*"toolName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n 1)"

case "$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')" in
  *bash*|*shell*|*execute*|*command*|*terminal*|*run*) ;;
  *) allow ;;
esac

# Match /tmp and /var/tmp used as real paths, not as substrings of other words
# (e.g. "mytmp", "/tmpl", "$TMPDIR" and "mktemp -d" must not trip this).
if printf '%s' "$payload" \
  | grep -Eq '(^|[^A-Za-z0-9_./-])/(var/)?tmp(/|["'"'"'[:space:]]|\\|$)'; then
  printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"agentic-sdlc: this command references a hardcoded /tmp or /var/tmp path. Shared system temp directories are insecure, non-portable, and collide across the parallel pipelines this plugin runs. Create a private temp directory instead: mktemp -d (shell), tempfile.mkdtemp() or the pytest tmp_path fixture (Python), fs.mkdtemp() (Node), or $RUNNER_TEMP / the runner workspace in CI. See the quality-gate-checklist skill."}'
  exit 0
fi

allow
