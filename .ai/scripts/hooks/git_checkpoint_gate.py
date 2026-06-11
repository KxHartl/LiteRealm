#!/usr/bin/env python3
"""Claude Code Stop hook: enforce LiteRealm rule 1 (proactive git).

If the working tree is dirty when Claude tries to finish its turn, block the
stop once and tell it to commit. `stop_hook_active` prevents an infinite loop:
after one forced continuation the next stop is always allowed, so Claude can
still finish (e.g. to ask the user about unrelated changes it should not commit).
Dependency-free; exits 0 always.
"""
import json
import subprocess
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if data.get("stop_hook_active"):
    sys.exit(0)

try:
    r = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True, text=True, timeout=15,
    )
except Exception:
    sys.exit(0)

dirty = r.stdout.strip() if r.returncode == 0 else ""
if dirty:
    n = len(dirty.splitlines())
    print(json.dumps({
        "decision": "block",
        "reason": (
            f"LiteRealm rule 1 (PROAKTIVNI GIT): {n} uncommitted change(s) in the "
            "working tree. Commit each logical unit now — conventional commit with "
            "the '\U0001F916 [AI]' prefix (helper: .ai/scripts/helpers/checkpoint.ps1 "
            "or checkpoint.sh). Unfinished work: commit as 'wip: ...'. Changes that "
            "are NOT yours (user's own edits): leave them and tell the user instead."
        ),
    }))

sys.exit(0)
