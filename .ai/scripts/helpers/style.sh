#!/usr/bin/env bash
# Run AgentBrain Style, Linter & Local Humanizer scripts.
#   ./.ai/scripts/helpers/style.sh check docs/chapters/00-uvod.tex
#   ./.ai/scripts/helpers/style.sh humanize docs/chapters/00-uvod.tex --in-place
#   ./.ai/scripts/helpers/style.sh learn docs/chapters/00-uvod.tex
set -e

brain="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"
cmd="${1:-}"; shift || true

case "$cmd" in
    check)    script="$brain/scripts/style/check_style.py" ;;
    humanize) script="$brain/scripts/style/local_humanizer.py" ;;
    learn)    script="$brain/scripts/style/learn_style.py" ;;
    *) echo "Usage: $(basename "$0") {check|humanize|learn} [args...]"; exit 1 ;;
esac

[ -f "$script" ] || { echo "Not found: $script — is AgentBrain installed?"; exit 1; }
py="$brain/.venv/bin/python"
[ -f "$py" ] || py="python"
exec "$py" "$script" "$@"
