#!/usr/bin/env bash
# One-shot AI checkpoint commit (LiteRealm rule 1: proactive git).
# Stages everything and commits with the AI marker prefix.
# Usage: ./.ai/scripts/helpers/checkpoint.sh "feat: add uvod chapter"
set -euo pipefail

msg="${1:?Usage: checkpoint.sh \"type: message\"}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ai="🤖 [AI]"

if [ -z "$(git -C "$root" status --porcelain)" ]; then
    echo "Nothing to commit - working tree clean."
    exit 0
fi

if [[ "$msg" != *"[AI]"* ]]; then
    if [[ "$msg" =~ ^[a-z]+(\([^\)]+\))?\!?:\ *(.+)$ ]]; then
        # Conventional commit: insert the marker after "type(scope):".
        prefix="${msg%%:*}"
        rest="${msg#*:}"
        msg="${prefix}: ${ai}${rest:+ }$(echo "$rest" | sed 's/^ *//')"
    else
        msg="chore: ${ai} ${msg}"
    fi
fi

git -C "$root" add -A
git -C "$root" commit -m "$msg"
