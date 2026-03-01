#!/bin/bash
# PreToolUse: Warn when committing large media files (>50MB)
# This is a warning only, does not block the commit.

INPUT=$(cat)

if command -v jq &>/dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

[ -z "$COMMAND" ] && exit 0

# Only check on git add/commit commands
if echo "$COMMAND" | grep -qE 'git (add|commit)'; then
    # Find staged files larger than 50MB
    LARGE_FILES=""
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        if [ -f "$file" ]; then
            SIZE=$(stat --printf="%s" "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
            if [ -n "$SIZE" ] && [ "$SIZE" -gt 52428800 ]; then
                SIZE_MB=$((SIZE / 1048576))
                LARGE_FILES="${LARGE_FILES}${file} (${SIZE_MB}MB), "
            fi
        fi
    done < <(git diff --cached --name-only 2>/dev/null)

    if [ -n "$LARGE_FILES" ]; then
        LARGE_FILES="${LARGE_FILES%, }"
        cat <<EOF
{"decision":"warn","reason":"Large media files staged (>50MB): ${LARGE_FILES}. Consider using Git LFS or excluding from commit."}
EOF
        exit 0
    fi
fi
