# LiteRealm

**LiteRealm** is a GitHub Template for academic papers, assignments, and software projects powered by AI agents (Claude, Gemini, Copilot).

All generic assets — templates, agent definitions, skills, and RAG scripts — live in a separate global repository: **[AgentBrain](https://github.com/KxHartl/AgentBrain)** (`~/.agentbrain`). LiteRealm stays lightweight and project-focused.

---

## Quick Start

### 1. Create a New Project

1. Click **"Use this template"** → **"Create a new repository"** on GitHub.
2. The `Initialize from Template` workflow runs automatically and replaces all placeholders with your repo name.
3. Clone your new repo:
   ```bash
   git clone <YOUR_NEW_REPO_URL>
   cd <YOUR_FOLDER>
   ```

### 2. Bootstrap

Run once after cloning to set up the local environment:

**Windows (PowerShell):**
```powershell
.\.ai\scripts\bootstrap.ps1 -Name "My_Project_Name" -Rag local
```
**Linux / macOS (Bash):**
```bash
./.ai/scripts/bootstrap.sh --name "My_Project_Name" --rag local
```

The bootstrap script:
- Writes the project name into `STATE.md` and `project.yaml`
- Creates all directories (`data/raw`, `data/processed`, `docs`, `src`)
- Configures `.env`
- Creates a Python virtual environment with dependencies
- Clones `AgentBrain` to `~/.agentbrain` if not already present
- Installs a pre-commit hook to protect `data/raw/` from accidental edits
- Checks the LaTeX compiler

### 3. Start Writing

Tell your AI agent:
```
počni pisati
```
The `latex_architect` agent copies the correct LaTeX template from `~/.agentbrain/templates/` into `docs/`, compiles it to verify, and hands off to `writer`.

---

## Directory Structure

| Directory | Purpose | Rules |
|---|---|---|
| `docs/` | LaTeX project: `main.tex`, `chapters/`, `figures/`, PDFs | Set up by `latex_architect` on first use |
| `docs/chapters/` | Individual chapter `.tex` files | `\input{}`'d from `main.tex` |
| `docs/figures/` | Images and diagrams | Raster or vector formats |
| `docs/tables/` | Complex tables as separate `.tex` files | `\input{}`'d from chapters |
| `docs/code/` | Code listings for display in the document | Use `minted` or `listings` packages |
| `src/` | Source code, scripts, algorithms | |
| `dist/` | Final submission versions | **Versioned subfolders**: `dist/v1.0/`, `dist/v1.1/` |
| `data/raw/` | Raw input data | **Read-only** — enforced by pre-commit hook |
| `data/processed/` | Processed data | Subfolders: `source_ddmmyyyy_hhmmss/` |
| `data/sources/` | Literature PDFs for RAG | Tracked via **Git LFS** |
| `.ai/` | Config (`AGENTS.md`), scripts, RAG database | Internal — do not edit manually |
| `~/.agentbrain/` | Global templates, skills, agents, RAG scripts | Shared across all projects |

---

## AI Agents

Six specialized agents are defined in `~/.agentbrain/agents/`:

| Agent | Role | Trigger |
|---|---|---|
| `latex_architect` | Sets up `docs/` LaTeX structure | "počni pisati", "setup docs" |
| `data_fetcher` | Finds and downloads literature | "pronađi izvore", "search for papers" |
| `writer` | Writes academic content in LaTeX | "napiši poglavlje", "draft section" |
| `qa_reviewer` | Reviews content, produces `REVIEW.md` | "pregledaj", "review chapter" |
| `latex_surgeon` | Debugs LaTeX compilation errors | When compilation fails |
| `rag_indexer` | Maintains the RAG vector database | After adding PDFs to `data/sources/` |

**Pipeline**: `latex_architect` → fetch → write → review → fix → index

---

## RAG (Chat with your literature)

PDFs are parsed with **Docling** (IBM — understands tables, multi-column layouts, figures) and stored in **LanceDB**. No hallucinated citations.

1. Place literature in `data/sources/` (auto-tracked by Git LFS).
2. Ingest:
   ```bash
   python ~/.agentbrain/scripts/rag/ingest.py
   python ~/.agentbrain/scripts/rag/ingest.py --ocr    # for scanned PDFs
   ```
3. Query:
   ```bash
   python ~/.agentbrain/scripts/rag/query.py "Your question" --scope both
   ```
4. Auto-generate BibTeX from DOI:
   ```bash
   python ~/.agentbrain/scripts/add_citation.py --doi "10.1109/TRO.2024.1234567"
   ```

---

## Building PDFs

```powershell
.\.ai\scripts\helpers\build-docs.ps1        # PowerShell
./.ai/scripts/helpers/build-docs.sh         # Bash
```

Supports **Tectonic** (default, auto-downloads packages) and **latexmk** (legacy).

The `Build LaTeX Document` workflow compiles automatically on every push to `main` and attaches the PDF as an artifact.

---

## Tooling

| Tool | Purpose | Install |
|---|---|---|
| [Tectonic](https://tectonic-typesetting.github.io/) | LaTeX compiler | `winget install tectonic` / `brew install tectonic` |
| [uv](https://docs.astral.sh/uv/) | Fast Python package manager | `pip install uv` |
| [Docling](https://docling-project.github.io/docling/) | ML-based PDF parser | `pip install docling` |
| [LanceDB](https://lancedb.github.io/lancedb/) | File-based vector store | `pip install lancedb` |
| [Git LFS](https://git-lfs.github.com/) | Large file storage for PDFs | `git lfs install` |
