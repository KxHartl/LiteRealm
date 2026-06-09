#!/usr/bin/env bash
# Bootstrap a new LiteRealm project.
# Usage:
#   ./.ai/scripts/bootstrap.sh --name "Autonomni_Vilicari"
#   ./.ai/scripts/bootstrap.sh --auto   (reads name from project.yaml)
# RAG is always available via AgentBrain (~/.agentbrain/.venv) — no flag needed.

set -e

NAME=""
BRAIN="global"
AUTO=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)  NAME="$2"; shift 2 ;;
        --brain) BRAIN="$2"; shift 2 ;;
        --auto)  AUTO=true; shift ;;
        *)       echo "Unknown option: $1"; exit 1 ;;
    esac
done

root="$(cd "$(dirname "$0")/../.." && pwd)"
marker="$root/.ai/.bootstrapped"
brain_version="unknown"   # set once AgentBrain is located; used in the marker

# --- Auto mode: read name from project.yaml ---
if [[ "$AUTO" == true && -z "$NAME" ]]; then
    if [[ -f "$root/.ai/config/project.yaml" ]]; then
        existing_name=$(grep '^name:' "$root/.ai/config/project.yaml" | sed 's/name: *"//' | sed 's/"//')
        if [[ -n "$existing_name" && "$existing_name" != "TBD" ]]; then
            NAME="$existing_name"
        fi
    fi
    if [[ -z "$NAME" ]]; then
        echo ""
        echo "Project name not set yet. Run bootstrap manually:"
        echo "  ./.ai/scripts/bootstrap.sh --name \"Your_Project_Name\""
        echo ""
        echo "Continuing with directory setup only..."
    fi
fi

if [[ "$AUTO" != true && -z "$NAME" ]]; then
    echo "Error: --name is required."
    echo "Usage: ./.ai/scripts/bootstrap.sh --name \"Project_Name\"  (or --auto to read it from project.yaml)"
    exit 1
fi

# --- Idempotency check ---
if [[ -f "$marker" ]]; then
    echo ""
    echo "Project already bootstrapped ($(cat "$marker"))."
    echo "Re-running will update config only."
    echo ""
fi

echo ""
echo "=== LiteRealm Bootstrap ==="
echo "Project: ${NAME:-[not set]}"
echo "Brain:   $BRAIN"
echo ""

# --- 1. Set project name in config files ---
echo "[1/7] Setting project name..."
if [[ -n "$NAME" ]]; then
    state_file="$root/STATE.md"
    yaml_file="$root/.ai/config/project.yaml"

    if [[ -f "$state_file" ]] && grep -q "_TBD_" "$state_file"; then
        sed -i.bak "s/_TBD_/$NAME/g" "$state_file" && rm -f "$state_file.bak"
    fi
    if [[ -f "$yaml_file" ]] && grep -q '"TBD"' "$yaml_file"; then
        sed -i.bak "s/\"TBD\"/\"$NAME\"/g" "$yaml_file" && rm -f "$yaml_file.bak"
    fi

    echo "  Name '$NAME' written to config files."
else
    echo "  Skipped (no name provided)."
fi

# --- 2. Create directory structure ---
echo "[2/7] Creating directories..."
mkdir -p "$root"/{docs,src,dist,data/raw,data/processed,data/sources}

# Kreiraj SOURCES_LOG.md ako ne postoji
sources_log="$root/data/SOURCES_LOG.md"
if [[ ! -f "$sources_log" ]]; then
    cat > "$sources_log" << 'EOF'
# Sources Log

Log svih preuzetih izvora. Svaki unos popunjava `data_fetcher`.

| Datum | URL | Lokalna putanja | Opis | Status |
|-------|-----|-----------------|------|--------|
| <!-- [YYYY-MM-DD HH:MM] | [URL] | data/sources/naziv.pdf | kratki opis | ok|paywalled|failed --> |
EOF
fi

echo "  Directories created."

# --- 3. Setup .env ---
echo "[3/7] Configuring .env..."
env_file="$root/.env"
env_example="$root/.env.example"

if [[ -f "$env_file" ]]; then
    echo "  .env already exists, skipping."
elif [[ -f "$env_example" ]]; then
    cp "$env_example" "$env_file"
    echo "  .env created from .env.example."
else
    echo "  No .env.example found, skipping."
fi

# --- 4. AgentBrain setup + version contract ---
echo "[4/7] Checking AgentBrain..."
brain_path="${AGENTBRAIN_PATH:-$HOME/.agentbrain}"

if [[ "$BRAIN" == "global" ]]; then
    if [[ ! -d "$brain_path" ]]; then
        echo "  AgentBrain not found at $brain_path. Cloning..."
        repo_url="https://github.com/KxHartl/AgentBrain.git"
        if git clone "$repo_url" "$brain_path" 2>/dev/null; then
            echo "  AgentBrain cloned successfully."
        else
            echo "  WARNING: Failed to clone AgentBrain (no internet?)."
            echo "  Copying offline fallback template..."
            fallback="$root/.ai/fallback"
            if [[ -d "$fallback" ]]; then
                cp -n "$fallback/minimal.tex" "$root/docs/" 2>/dev/null || true
                cp -n "$fallback/references.bib" "$root/docs/" 2>/dev/null || true
                echo "  Fallback template copied to docs/. RAG will not be available."
            fi
        fi
    else
        echo "  AgentBrain found: $brain_path"
    fi

    # Shared manifest handling — runs whether AgentBrain was just cloned or already present.
    manifest="$brain_path/manifest.yaml"
    if [[ -f "$manifest" ]]; then
        brain_version=$(grep '^version:' "$manifest" | awk '{print $2}' | tr -d '"')
        brain_version="${brain_version:-unknown}"
        echo "  AgentBrain version: $brain_version"

        # Version contract: warn if this LiteRealm is older than the brain requires.
        version_file="$root/VERSION"
        lite_version=$(if [[ -f "$version_file" ]]; then tr -d '[:space:]' < "$version_file"; else echo "unknown"; fi)
        min_lite=$(grep '^min_literealm_version:' "$manifest" | awk '{print $2}' | tr -d '"')
        if [[ -n "$min_lite" && "$lite_version" != "unknown" ]]; then
            lowest=$(printf '%s\n%s\n' "$lite_version" "$min_lite" | sort -V | head -1)
            if [[ "$lite_version" != "$min_lite" && "$lowest" == "$lite_version" ]]; then
                echo "  WARNING: LiteRealm $lite_version is older than AgentBrain requires (min $min_lite)."
                echo "           Update this project from the latest LiteRealm template."
            fi
        fi

        # Stamp brain version + commit into project.yaml (once).
        yaml_file="$root/.ai/config/project.yaml"
        if [[ -f "$yaml_file" ]] && ! grep -q "agentbrain_version" "$yaml_file"; then
            brain_commit=$(cd "$brain_path" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            echo "" >> "$yaml_file"
            echo "# AgentBrain version used during bootstrap" >> "$yaml_file"
            echo "agentbrain_version: \"$brain_version\"" >> "$yaml_file"
            echo "agentbrain_commit: \"$brain_commit\"" >> "$yaml_file"
        fi
    else
        echo "  WARNING: AgentBrain manifest.yaml not found. Consider updating AgentBrain."
    fi

    # Ensure the shared RAG environment exists (always-on RAG via AgentBrain).
    # ~1.5GB (docling + torch + models), so skip it inside Codespaces to keep
    # container creation light — the RAG scripts build the venv on first use there.
    # One-time per machine; non-fatal.
    if [[ -n "$CODESPACES" ]]; then
        echo "  In Codespaces — RAG deps install on first use (keeping creation light)."
    elif [[ -d "$brain_path/.venv" ]]; then
        echo "  RAG environment present (~/.agentbrain/.venv)."
    elif [[ -f "$brain_path/scripts/setup_env.sh" ]]; then
        echo "  Setting up RAG environment (one-time, may take a few minutes)..."
        if bash "$brain_path/scripts/setup_env.sh"; then
            echo "  RAG environment ready."
        else
            echo "  WARNING: RAG setup failed. Run later: bash $brain_path/scripts/setup_env.sh"
        fi
    fi
fi

# --- 5. Python environment (best-effort; must NOT abort the rest of bootstrap) ---
echo "[5/7] Python environment..."
set +e   # dependency install is non-fatal — hooks/LFS/marker must still run

venv_path="$root/.venv"
# Locate the venv interpreter for both Linux (bin/) and Windows-bash (Scripts/) layouts.
detect_vpy() {
    if [[ -x "$venv_path/bin/python" ]]; then echo "$venv_path/bin/python"
    elif [[ -f "$venv_path/Scripts/python.exe" ]]; then echo "$venv_path/Scripts/python.exe"
    else echo ""; fi
}

if command -v uv &>/dev/null; then
    echo "  Using uv (fast mode)."
    [[ -d "$venv_path" ]] || uv venv "$venv_path"
    vpy="$(detect_vpy)"
    if [[ -n "$vpy" ]]; then
        uv pip install --python "$vpy" -q python-dotenv
        # RAG deps are NOT installed per-project — they live once in ~/.agentbrain/.venv.
        echo "  Python OK (uv)."
    else
        echo "  WARNING: could not locate venv interpreter; skipping dependency install."
    fi
else
    # Fallback to traditional pip/venv
    python_cmd=""
    for cmd in python3 python; do
        if $cmd --version 2>&1 | grep -q "Python 3\."; then python_cmd="$cmd"; break; fi
    done

    if [[ -n "$python_cmd" ]]; then
        [[ -d "$venv_path" ]] || $python_cmd -m venv "$venv_path"
        pip_cmd="$venv_path/bin/pip"; [[ -x "$pip_cmd" ]] || pip_cmd="$venv_path/Scripts/pip.exe"
        if [[ -e "$pip_cmd" ]]; then
            "$pip_cmd" install -q python-dotenv
            # RAG deps are NOT installed per-project — they live once in ~/.agentbrain/.venv.
        fi
        echo "  Python OK ($python_cmd)."
    else
        echo "  Python not found — skipping venv setup."
    fi
fi

set -e

# --- 6. Git setup: pre-commit hook + Git LFS ---
echo "[6/7] Git setup (hooks + LFS)..."

inside_repo=false
if git -C "$root" rev-parse --is-inside-work-tree &>/dev/null; then
    inside_repo=true
fi

hook_dir="$root/.git/hooks"
pre_commit_hook="$hook_dir/pre-commit"

if [[ -d "$hook_dir" ]]; then
    if [[ ! -f "$pre_commit_hook" ]]; then
        cat > "$pre_commit_hook" << 'HOOK'
#!/bin/sh
# LiteRealm: block changes to data/raw/ — it is read-only source data.
if git diff --cached --name-only | grep -q "^data/raw/"; then
    echo "ERROR: data/raw/ is read-only. Move processed files to data/processed/." >&2
    exit 1
fi
HOOK
        chmod +x "$pre_commit_hook"
        echo "  pre-commit hook installed (data/raw/ protection)."
    else
        echo "  pre-commit hook already exists, skipping."
    fi
else
    echo "  Not a git repo (no .git/hooks) — skipping pre-commit hook."
fi

if command -v git-lfs &>/dev/null || git lfs version &>/dev/null; then
    if [[ "$inside_repo" == true ]]; then
        git -C "$root" lfs install --local &>/dev/null
        echo "  Git LFS installed (data/sources/ large files tracked)."
    else
        echo "  Git LFS present but not inside a repo — skipping install."
    fi
else
    echo "  WARNING: git-lfs not found. Install it (https://git-lfs.com) so PDFs in"
    echo "           data/sources/ are tracked via LFS, not committed as large blobs."
fi

# --- 7. Check LaTeX (Tectonic) ---
echo "[7/7] Checking LaTeX compiler..."
if command -v tectonic &>/dev/null; then
    echo "  tectonic found (recommended engine)."
elif command -v latexmk &>/dev/null; then
    echo "  latexmk found (legacy fallback). Tectonic is the canonical engine."
else
    echo "  No LaTeX compiler found."
    echo "  Install Tectonic: curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh"
    echo "  Or install TeX Live / MiKTeX for latexmk."
fi

# --- Done ---
echo "$(date -Iseconds) | brain=${brain_version}" > "$marker"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Next steps:"
echo "  1. Fill in STATE.md and .ai/config/project.yaml with your assignment details"
echo "  2. Tell your AI agent: 'pocni pisati' — latex_architect sets up docs/ automatically"
echo "  3. Add literature PDFs to data/sources/ (tracked via Git LFS)"
echo "  4. Index them for RAG: ./.ai/scripts/helpers/rag.sh ingest"
echo ""
