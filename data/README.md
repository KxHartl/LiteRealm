# data/

## `data/raw/`
Original, untouched input data — reports, camera captures, downloaded tables, raw datasets.
🔒 **Read-only: never modified by code.** A pre-commit hook blocks any commit that changes it.

## `data/processed/`
Processed data, charts and models.
**Rule:** every processed output goes in a subfolder named `source_ddmmyyyy_hhmmss`.

## `data/sources/`
PDF literature for RAG — books, lecture notes, papers. Drop files here, then index them:

```bash
./.ai/scripts/helpers/rag.sh ingest          # Windows: .\.ai\scripts\helpers\rag.ps1 ingest
```

Files in this folder are tracked via **Git LFS**.

## Logs
| File | Written by | Content |
|---|---|---|
| `SOURCES_LOG.md` | `data_fetcher` | every downloaded source (created by bootstrap) |
| `EXPERIMENTS_LOG.md` | `data_engineer` / `experiment` helper | every measurement or simulation run, raw ↔ processed ↔ figure |
| `DATA_DICTIONARY.md` | you / `data_engineer` | signal names, units, sensors — adapt the example rows to your project |

```bash
./.ai/scripts/helpers/experiment.sh new --type exp --name motor-torque --desc "Step response"
./.ai/scripts/helpers/experiment.sh list | audit
```
