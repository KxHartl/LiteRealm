#!/usr/bin/env bash
# Master's Thesis Status Dashboard & Audit helper.
set -euo pipefail

BRAIN="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"
SCRIPT="$BRAIN/scripts/thesis_dashboard.py"

if [[ ! -f "$SCRIPT" ]]; then
    echo "Not found: $SCRIPT - is AgentBrain installed?" >&2
    exit 1
fi

PY="$BRAIN/.venv/bin/python"
if [[ ! -f "$PY" ]]; then
    PY="python3"
fi

exec "$PY" "$SCRIPT" "${1:-status}" --project-root .
