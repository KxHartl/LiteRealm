# LiteRealm

> **LiteRealm** is an AI-agent workspace template for academic work — seminars, theses, papers and assignments — that writes, cites and compiles **LaTeX** for you.

[![Made with LiteRealm](https://img.shields.io/badge/template-LiteRealm-6f42c1)](https://github.com/KxHartl/LiteRealm)
[![LaTeX · Tectonic](https://img.shields.io/badge/LaTeX-Tectonic-008080)](https://tectonic-typesetting.github.io/)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-3776AB)](https://www.python.org/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue)](LICENSE)

LiteRealm is the **per-project** half of a two-part system. All the heavy, reusable
machinery — LaTeX templates, AI agent definitions, RAG scripts and learned lessons —
lives once on your machine in **[AgentBrain](https://github.com/KxHartl/AgentBrain)**
(`~/.agentbrain`). Each new project stays tiny and focused; the brain is shared.

```
   ┌─────────────────────────┐         ┌──────────────────────────────┐
   │  LiteRealm  (this repo)  │         │  AgentBrain  (~/.agentbrain)  │
   │  · one per project       │ ◀────▶  │  · one per machine, shared    │
   │  · your text, data, PDFs │  uses   │  · templates · agents         │
   │  · config + state        │         │  · RAG scripts · gotchas      │
   └─────────────────────────┘         └──────────────────────────────┘
```

---

## 🚀 Quick Start

### Option A — GitHub Codespaces (zero setup)

1. Click **`Use this template`** → **`Create a new repository`**.
2. Wait ~30 s: the **Initialize from Template** workflow renames every placeholder to your repo name and commits the result.
3. Click **`Code`** → **`Codespaces`** → **`Create codespace`**.
   The dev container runs `bootstrap --auto` for you — environment ready, brain cloned, done.

### Option B — Local machine

1. **`Use this template`** → **`Create a new repository`** (same auto-init as above).
2. Clone and bootstrap. The script reads your project name from `project.yaml` automatically — no need to type it again:

   **Windows (PowerShell):**
   ```powershell
   git clone <YOUR_NEW_REPO_URL>; cd <YOUR_FOLDER>
   .\.ai\scripts\bootstrap.ps1 -Auto
   ```
   **Linux / macOS (Bash):**
   ```bash
   git clone <YOUR_NEW_REPO_URL> && cd <YOUR_FOLDER>
   ./.ai/scripts/bootstrap.sh --auto
   ```

### Then — start writing

Fill in the four required fields in [`.ai/config/project.yaml`](.ai/config/project.yaml)
(author, course, title, professor), then tell your AI agent:

```
počni pisati
```

The **`latex_architect`** agent copies the right LaTeX template into `docs/`, compiles it to
prove it works, and hands off to the **`writer`** agent. You write prose; the agents handle LaTeX.

---

## 🧠 What bootstrap does

Run once after cloning. It is **idempotent** — safe to re-run any time.

- ✅ Writes your project name into `STATE.md` and `project.yaml`
- ✅ Creates the directory skeleton (`docs/`, `src/`, `data/{raw,processed,sources}`, `dist/`)
- ✅ Copies `.env` from `.env.example`
- ✅ Clones **AgentBrain** to `~/.agentbrain` if it isn't there yet
- ✅ Creates a minimal project `.venv` (just `python-dotenv`); on first run, also builds the shared RAG env in `~/.agentbrain/.venv` (one-time, ~500 MB — docling + models)
- ✅ Installs a Git pre-commit hook that protects `data/raw/` from edits
- ✅ Enables Git LFS for `data/sources/` and checks your LaTeX compiler

> No internet? Bootstrap falls back to a minimal template in `.ai/fallback/` so you can still compile.

---

## 🤖 The AI agents

Six specialists live in `~/.agentbrain/agents/`. You don't call them by name — you describe what
you want and the right one picks it up.

| Agent | Role | Say something like… |
|---|---|---|
| `latex_architect` | Sets up the `docs/` LaTeX project | *"počni pisati"*, *"setup docs"* |
| `data_fetcher` | Finds & downloads literature | *"pronađi izvore"*, *"search for papers"* |
| `writer` | Writes academic content in LaTeX | *"napiši poglavlje"*, *"draft section"* |
| `qa_reviewer` | Reviews content → `docs/REVIEW.md` | *"pregledaj"*, *"review chapter"* |
| `latex_surgeon` | Fixes LaTeX compile errors | *(auto, when a build fails)* |
| `rag_indexer` | Maintains the RAG vector database | *(auto, after you add PDFs)* |

```
latex_architect → data_fetcher → writer → qa_reviewer → latex_surgeon → rag_indexer
   set up docs       find PDFs     write     critique      fix build       index sources
```

**Citations are grounded:** the `writer` only cites papers whose PDF actually exists in
`data/sources/`. No invented references.

---

## 📁 Project layout

| Path | What lives here | Rule |
|---|---|---|
| `docs/` | The LaTeX project: `main.tex`, `chapters/`, `figures/`, PDFs | Created by `latex_architect` on first run |
| `docs/chapters/` | One `.tex` file per chapter | `\input{}`'d from `main.tex` |
| `docs/figures/` · `tables/` · `code/` | Images, complex tables, code listings | `\input{}`'d where needed |
| `src/` | Source code, scripts, algorithms | Optional — empty if your work needs no code |
| `dist/` | Final hand-in builds | **Versioned**: `dist/v1.0/`, `dist/v1.1/` … (PDFs gitignored) |
| `data/raw/` | Original input data | 🔒 **Read-only** — enforced by pre-commit hook |
| `data/processed/` | Derived data | Subfolders `source_ddmmyyyy_hhmmss/` |
| `data/sources/` | Literature PDFs for RAG | Tracked via **Git LFS** |
| `.ai/` | Project config, scripts, RAG database | Internal — `REFERENCE.md` holds the on-demand details |
| `~/.agentbrain/` | Templates, agents, skills, RAG scripts | Shared across every project |

---

## 📚 RAG — chat with your literature

Drop PDFs into `data/sources/` and your agents can quote them with page-accurate citations.
PDFs are parsed with **Docling** (understands tables, multi-column layouts, figures) and stored
in **LanceDB**. Scripts and their Python deps live **once** in `~/.agentbrain/` — never duplicated.

Use the `rag` helper so you never have to type the brain path (and to avoid `~` not
expanding in PowerShell). Replace `.ps1`/`.sh` for your shell:

```powershell
# 1. Add literature (auto-tracked by Git LFS)
git add data/sources/paper.pdf; git commit -m "feat: add source"

# 2. Index it           (Windows: rag.ps1 · Linux/macOS: rag.sh ingest)
.\.ai\scripts\helpers\rag.ps1 ingest          # add --ocr for scanned PDFs

# 3. Ask questions
.\.ai\scripts\helpers\rag.ps1 query "your question" --scope both

# 4. Generate BibTeX from a DOI
.\.ai\scripts\helpers\rag.ps1 cite --doi "10.1109/TRO.2024.1234567"
```

RAG is **always on** — no flag to enable, nothing to configure per-project. The first
`ingest`/`query` builds the shared `~/.agentbrain/.venv` automatically if it isn't there
yet (≈1.5 GB, one-time). Embeddings use Gemini if `GEMINI_API_KEY` is set in `.env`,
otherwise local `sentence-transformers`. Either way it just works.

---

## 🛠️ Building the PDF

```powershell
.\.ai\scripts\helpers\build-docs.ps1                 # Windows
```
```bash
./.ai/scripts/helpers/build-docs.sh                  # Linux / macOS
```

Builds go to a **versioned** subfolder. Pass a version for hand-in releases:

```bash
./.ai/scripts/helpers/build-docs.sh --version v1.0   # → dist/v1.0/main.pdf
```

The **Build LaTeX Document** workflow also compiles on every push that touches `docs/**/*.tex`
and uploads the PDF as a CI artifact.

---

## ⚙️ Configuration

Two files drive everything. The init workflow fills in the project name; you fill in the rest.

**[`.ai/config/project.yaml`](.ai/config/project.yaml)** — the cover page & build settings.
These four are **required** before agents will write:

```yaml
author_name:    "Ime Prezime"
course_name:    "NAZIV KOLEGIJA"
seminar_title:  "Puni naslov rada"
professor_name: "Ime Prezime"
```

Also choose your `latex_format` (`fsb-seminar` · `fsb-thesis` · `fsb-paper` · `fsb-presentation` · `fsb-video`).

**[`STATE.md`](STATE.md)** — a short scratchpad: what you're working on now and notes for the agent.

---

## 📦 Requirements

| Tool | Why | Install |
|---|---|---|
| [Tectonic](https://tectonic-typesetting.github.io/) | LaTeX compiler (auto-fetches packages) | `winget install tectonic` · `brew install tectonic` |
| [Git LFS](https://git-lfs.com/) | Large-file storage for PDFs | `git lfs install` |
| [uv](https://docs.astral.sh/uv/) *(optional)* | Fast Python env for bootstrap | `pip install uv` |
| [Docling](https://docling-project.github.io/docling/) · [LanceDB](https://lancedb.github.io/lancedb/) | RAG parser + vector store | installed once in `~/.agentbrain/.venv` |

> **Don't have these?** Bootstrap detects what's missing and tells you exactly what to install —
> nothing fails silently.

---

## ❓ FAQ

**Do I need to install AgentBrain manually?** No — bootstrap clones it to `~/.agentbrain` the first time.

**Why is my `data/raw/` commit rejected?** That's the point — raw data is read-only. Put derived files in `data/processed/`.

**The chat is in Croatian but the code isn't — why?** Convention: chat in Hrvatski, but code, comments, commits and docs in English. See [`AGENTS.md`](AGENTS.md).

**Where are the agent rules?** Core behavioral rules live in [`AGENTS.md`](AGENTS.md) (single source of truth — `CLAUDE.md`/`GEMINI.md` import it). On-demand details in [`.ai/config/REFERENCE.md`](.ai/config/REFERENCE.md), agent definitions in `~/.agentbrain/agents/` (synced to `.claude/agents/` for Claude Code).

---

<sub>Powered by <a href="https://github.com/KxHartl/AgentBrain">AgentBrain</a> · LaTeX via Tectonic · Apache-2.0 licensed</sub>
