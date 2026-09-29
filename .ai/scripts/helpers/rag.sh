#!/usr/bin/env bash
# Run AgentBrain RAG / citation scripts without typing the brain path.
#   ./.ai/scripts/helpers/rag.sh ingest [--ocr]
#   ./.ai/scripts/helpers/rag.sh query "your question"
#   ./.ai/scripts/helpers/rag.sh serve            # warm server -> instant queries
#   ./.ai/scripts/helpers/rag.sh cite --doi "10.xxxx/yyyy"
set -e

brain="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"
cmd="${1:-}"; shift || true

case "$cmd" in
    ingest)   script="$brain/scripts/rag/ingest.py" ;;
    query)    script="$brain/scripts/rag/query.py" ;;
    serve)    script="$brain/scripts/rag/serve.py" ;;
    cite)     script="$brain/scripts/add_citation.py" ;;
    sync)     script="$brain/scripts/rag/sync.py" ;;
    classify) script="$brain/scripts/rag/classify_source.py" ;;
    *) echo "Usage: $(basename "$0") {ingest|query|serve|cite|sync|classify} [args...]"; exit 1 ;;
esac

[ -f "$script" ] || { echo "Not found: $script — is AgentBrain installed?"; exit 1; }
py="$brain/.venv/bin/python"
[ -f "$py" ] || py="python"
exec "$py" "$script" "$@"
