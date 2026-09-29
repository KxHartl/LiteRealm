#!/usr/bin/env bash
# Run AgentBrain Experiment & Research Data Manager without typing brain path.
set -euo pipefail

BRAIN="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"
SCRIPT="$BRAIN/scripts/data/experiment_manager.py"

if [[ ! -f "$SCRIPT" ]]; then
    echo "Not found: $SCRIPT - is AgentBrain installed?" >&2
    exit 1
fi

PY="$BRAIN/.venv/bin/python"
if [[ ! -f "$PY" ]]; then
    PY="python3"
fi

exec "$PY" "$SCRIPT" "$@" --project-root .
