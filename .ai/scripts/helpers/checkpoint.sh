#!/usr/bin/env bash
# One-shot checkpoint commit (rule 1: proactive git).
# Stages everything and commits in the user's name by default.
#
# The AI marker is NOT added by default. Per AGENTS.md rule 1.1 it means an AI
# agent did the work in that commit. If the user did the work - or gave the
# direction and the decision while the agent carried it out - the commit is
# theirs: omit --ai.
#
# The git history is the record of AI use, so the marker must be accurate.
#
# Usage: ./.ai/scripts/helpers/checkpoint.sh [--ai] "feat: add uvod chapter"
set -euo pipefail

use_ai=0
if [ "${1:-}" = "--ai" ]; then
    use_ai=1
    shift
fi

msg="${1:?Usage: checkpoint.sh [--ai] \"type: message\"}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
marker="🤖 [AI]"

if [ -z "$(git -C "$root" status --porcelain)" ]; then
    echo "Nothing to commit - working tree clean."
    exit 0
fi

if [ "$use_ai" -eq 1 ]; then
    if [[ "$msg" != *"[AI]"* ]]; then
        if [[ "$msg" =~ ^[a-z]+(\([^\)]+\))?\!?:\ *(.+)$ ]]; then
            # Conventional commit: insert the marker after "type(scope):".
            prefix="${msg%%:*}"
            rest="${msg#*:}"
            msg="${prefix}: ${marker} $(echo "$rest" | sed 's/^ *//')"
        else
            msg="chore: ${marker} ${msg}"
        fi
    fi
    msg="${msg}

Co-Authored-By: Claude <noreply@anthropic.com>"
elif [[ "$msg" == *"[AI]"* ]]; then
    echo "Refusing: message carries the AI marker but --ai was not passed." >&2
    echo "See AGENTS.md rule 1.1 - use it only when an agent did the work." >&2
    exit 1
fi

git -C "$root" add -A
git -C "$root" commit -m "$msg"
