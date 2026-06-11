#!/usr/bin/env python3
"""Claude Code PreToolUse hook: deny Write/Edit/NotebookEdit into data/raw/.

data/raw/ is user-seeded, read-only input (LiteRealm rule 2). The git pre-commit
hook is the backstop; this denies the write before it even happens.
Dependency-free; exits 0 always (a hook crash must never block normal work).
"""
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = data.get("tool_input") or {}
path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
norm = path.replace("\\", "/").lower()

if "data/raw/" in norm:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "data/raw/ is READ-ONLY (LiteRealm rule 2). Never modify raw input "
                "data. Write derived files to data/processed/<source_ddmmyyyy_hhmmss>/ "
                "instead."
            ),
        }
    }))

sys.exit(0)
