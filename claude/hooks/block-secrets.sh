#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
BASENAME=$(basename "$FILE")
if echo "$BASENAME" | grep -qE '^\.(env|pem|key)$|^\.env\.|^credentials|^secrets'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked: editing secrets/env files requires explicit user approval. Ask the user first."
    }
  }'
fi
exit 0
