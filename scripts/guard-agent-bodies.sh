#!/usr/bin/env bash
# PreToolUse guard (matcher "Edit|Write", registered in .claude/settings.json).
# Keeps .claude/agents/*.md bodies pointer-only:
#   Write -> body after the closing frontmatter --- must be exactly the pointer
#            line and the hard-fail line for that agent; frontmatter is free.
#   Edit  -> always blocked, so every change goes through a validated Write.
# Exit 0 = allow, exit 2 = block (stderr is shown to the agent).
set -u

if ! command -v jq >/dev/null 2>&1; then
  echo "guard-agent-bodies: jq is not installed, so this edit cannot be checked. Blocking. Install jq." >&2
  exit 2
fi

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
path=$(jq -r '.tool_input.file_path // ""' <<<"$input")

case $path in
  */.claude/agents/*.md|.claude/agents/*.md) ;;
  *) exit 0 ;;
esac

name=$(basename "$path" .md)
expected="Read personas/$name.md and follow it fully.
If personas/$name.md cannot be read, stop immediately and report the failure — do not improvise."

if [[ $tool != Write ]]; then
  echo "Blocked: $path may not be changed with $tool. Frontmatter changes must be made by rewriting the whole file with Write, so the body can be validated." >&2
  exit 2
fi

content=$(jq -r '.tool_input.content // ""' <<<"$input")

if [[ $(head -n1 <<<"$content") != "---" ]]; then
  echo "Blocked: $path must start with YAML frontmatter (first line '---')." >&2
  exit 2
fi

# Body = everything after the second '---' line, with blank lines removed.
body=$(awk 'c>=2 {print; next} /^---[[:space:]]*$/ {c++}' <<<"$content" | sed '/^[[:space:]]*$/d')
closed=$(grep -c '^---[[:space:]]*$' <<<"$content")

if (( closed < 2 )); then
  echo "Blocked: $path has no closing frontmatter '---'." >&2
  exit 2
fi

if [[ $body != "$expected" ]]; then
  {
    echo "Blocked: the body of $path must contain only the pointer and hard-fail lines. All substance belongs in personas/$name.md. Expected body:"
    echo
    echo "$expected"
  } >&2
  exit 2
fi

exit 0
