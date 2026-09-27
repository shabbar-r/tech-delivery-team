#!/usr/bin/env bash
# Debug hook: appends the raw hook input JSON to .claude/hook-input.log. Always allows.
set -u
root=${CLAUDE_PROJECT_DIR:-$PWD}
mkdir -p "$root/.claude"
{ cat; echo; } >> "$root/.claude/hook-input.log"
exit 0
