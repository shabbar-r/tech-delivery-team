#!/usr/bin/env bash
# PreToolUse guard for the client-delivery lead (matcher "Read|Grep|Bash").
# Blocks access to data/backlog.json, data/capacity.json and RUNBOOK.md.
# Exit 0 = allow, exit 2 = block (stderr is shown to the agent).
# Registered only in .claude/agents/client-delivery.md, never in settings.json.
set -u

if ! command -v jq >/dev/null 2>&1; then
  echo "guard-lead-reads: jq is not installed, so this read cannot be checked. Blocking. Install jq." >&2
  exit 2
fi

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")
root=${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}
base=${cwd:-$root}

protected=(data/backlog.json data/capacity.json RUNBOOK.md)

lower() { tr '[:upper:]' '[:lower:]' <<<"$1"; }

resolve() {
  local p=$1
  [[ -z $p ]] && p=$base
  [[ $p != /* ]] && p=$base/$p
  realpath -m -- "$p"
}

block() {
  echo "Blocked: the client-delivery lead may not read $1. Backlog belongs to product, capacity to engineering, RUNBOOK.md to the facilitator. Ask the owning teammate instead." >&2
  exit 2
}

case $tool in
  Read|Grep)
    if [[ $tool == Read ]]; then
      raw=$(jq -r '.tool_input.file_path // ""' <<<"$input")
    else
      raw=$(jq -r '.tool_input.path // ""' <<<"$input")
    fi
    target=$(lower "$(resolve "$raw")")
    for f in "${protected[@]}"; do
      pf=$(lower "$(realpath -m -- "$root/$f")")
      if [[ $target == "$pf" ]]; then
        block "$f"
      fi
      # A search rooted at a directory containing a protected file would read it too.
      if [[ $tool == Grep && $pf == "$target"/* ]]; then
        echo "Blocked: searching '${raw:-.}' would include $f. Narrow the path to inbox/, outbox/ or data/client-history.md." >&2
        exit 2
      fi
    done
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    if grep -Eiq 'backlog\.json|capacity\.json|runbook\.md' <<<"$cmd"; then
      block "backlog.json, capacity.json or RUNBOOK.md (referenced in the command)"
    fi
    ;;
esac

exit 0
