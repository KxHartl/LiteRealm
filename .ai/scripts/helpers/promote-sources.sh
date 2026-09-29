#!/usr/bin/env bash
# Promote user-approved files from data/staging/<category>/ to data/sources/<category>/.
# data_fetcher only stages; promotion is the user's explicit decision (REFERENCE.md -> Citiranje).
#   ./.ai/scripts/helpers/promote-sources.sh papers                 # everything in data/staging/papers/
#   ./.ai/scripts/helpers/promote-sources.sh papers a.pdf b.pdf     # only these files
#   ./.ai/scripts/helpers/promote-sources.sh --all --ingest         # all categories, then rag ingest
# Options: --all, --ingest, --dry-run
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
staging="$root/data/staging"
log="$root/data/SOURCES_LOG.md"
all=0; ingest=0; dry=0; category=""; files=()

for arg in "$@"; do
    case "$arg" in
        --all) all=1 ;;
        --ingest) ingest=1 ;;
        --dry-run) dry=1 ;;
        -*) echo "Unknown option: $arg" >&2; exit 1 ;;
        *) if [[ -z "$category" && "$all" -eq 0 ]]; then category="$arg"; else files+=("$arg"); fi ;;
    esac
done

if [[ "$all" -eq 0 && -z "$category" ]]; then
    echo "Usage: $(basename "$0") <category> [file...] | --all  [--ingest] [--dry-run]" >&2
    exit 1
fi

if [[ "$all" -eq 1 ]]; then
    mapfile -t categories < <(find "$staging" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)
else
    categories=("$category")
fi

moved=0
for cat in "${categories[@]}"; do
    src="$staging/$cat"
    [[ -d "$src" ]] || { echo "No staging folder: data/staging/$cat" >&2; exit 1; }
    if [[ ${#files[@]} -gt 0 ]]; then
        candidates=("${files[@]/#/$src/}")
    else
        mapfile -t candidates < <(find "$src" -maxdepth 1 -type f \( -iname '*.pdf' -o -iname '*.docx' -o -iname '*.pptx' -o -iname '*.xlsx' \) | sort)
    fi
    for f in "${candidates[@]}"; do
        [[ -f "$f" ]] || { echo "Not found: ${f#$root/}" >&2; exit 1; }
        dest="$root/data/sources/$cat/$(basename "$f")"
        if [[ -e "$dest" ]]; then echo "  skip (exists): ${dest#$root/}"; continue; fi
        echo "  ${f#$root/} -> ${dest#$root/}"
        if [[ "$dry" -eq 0 ]]; then
            mkdir -p "$(dirname "$dest")"
            mv "$f" "$dest"
            printf '| %s | see data/staging/%s/manifest.yaml | %s | promoted from staging | ok |\n' \
                "$(date '+%Y-%m-%d %H:%M')" "$cat" "${dest#$root/}" >> "$log"
        fi
        moved=$((moved + 1))
    done
done

echo "Promoted: $moved file(s)$([[ $dry -eq 1 ]] && echo ' (dry run)')."
[[ "$moved" -gt 0 && "$dry" -eq 0 ]] && echo "Next: add BibTeX with 'rag.sh cite --doi ... --file <data/sources/...>'."
if [[ "$ingest" -eq 1 && "$dry" -eq 0 && "$moved" -gt 0 ]]; then
    "$root/.ai/scripts/helpers/rag.sh" ingest
fi
