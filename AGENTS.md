# LiteRealm — Core Rules (svi AI agenti)

> **Jedini izvor istine** za pravila ponašanja. `CLAUDE.md` i `GEMINI.md` importaju
> ovaj fajl — pravila se mijenjaju OVDJE, nikad u shimovima. Antigravity/Codex
> čitaju ovaj fajl direktno.

## 1. PROAKTIVNI GIT (CRITICAL)

- Nakon **SVAKE logičke cjeline** (poglavlje napisano, bug popravljen, izvori preuzeti):
  odmah `git add` + `git commit`. **Ne čekaj kraj zadatka i ne čekaj korisnika.**
- Format poruke: Conventional Commits + prefiks `🤖 [AI]` — npr. `feat: 🤖 [AI] add uvod chapter`.
- Najlakše jednim pozivom: `.\.ai\scripts\helpers\checkpoint.ps1 "feat: opis"` (bash: `checkpoint.sh`).
- Male prepravke → izravno na `main`. Veće strukturne promjene → grana `ai/<feature>` + PR.
- **Samoprovjera prije završetka odgovora**: `git status --porcelain` mora biti prazan.

## 2. Read-only podaci

- `data/raw/` se **NIKAD ne mijenja** (pre-commit hook to blokira; u Claude Codeu i hook na alatima).
- Obrađene verzije idu u `data/processed/<izvor_ddmmyyyy_hhmmss>/`.

## 3. Kontekst (pročitaj prije rada)

- `STATE.md` — trenutni zadatak i fokus.
- `.ai/config/project.yaml` — LaTeX metapodaci i format.
- `.ai/config/REFERENCE.md` — **isključivo on-demand referenca** (RAG komande, build,
  dist versioning, citation workflow, direktoriji). NE čitaj preventivno.

## 4. Orkestracija — delegiraj specijalistima

Glavni agent je **orkestrator**: ne radi posao specijalista sam, nego ga delegira.
Definicije: `~/.agentbrain/agents/` (Claude Code ih ima native u `.claude/agents/`).

| Agent | Kada |
|---|---|
| `latex_architect` | "počni pisati", setup `docs/` — točno jednom |
| `data_fetcher` | pronalaženje i preuzimanje literature |
| `writer` | pisanje LaTeX sadržaja |
| `qa_reviewer` | pregled prije predaje (read-only, piše samo `docs/REVIEW.md`) |
| `latex_surgeon` | LaTeX kompilacija pada |
| `rag_indexer` | novi PDF-ovi u `data/sources/` |

**Obavezan redoslijed**: `data_fetcher` → `writer`. Writer ne piše sadržaj dok
PDF-ovi nisu u `data/sources/` (detalji i iznimke: REFERENCE.md → Citiranje).

## 5. Točnost — RAG umjesto memorije

- Sve činjenice i citati iz literature idu kroz `rag query` (wrapper:
  `.\.ai\scripts\helpers\rag.ps1` / `rag.sh`). **Nikad ne citiraj iz vlastite memorije.**
- **Nikad ne izmišljaj `\cite` ključ** — koristi isključivo ključ koji `rag query` ispiše.

## 6. Token ekonomija

- Ciljano pretraživanje (grep/glob) umjesto čitanja cijelih fajlova ili `ls -R`.
- `REFERENCE.md`, `~/.agentbrain/{gotchas,skills,prompts}` čitaj samo kad konkretno zatrebaju.
- Dugi zadatak: svakih ~5 koraka sažmi napredak u `STATE.md` (sekcija "Trenutni fokus")
  umjesto držanja svega u kontekstu.
- Delegiranje specijalistima drži glavni kontekst malim — koristi ga.

## 7. Komunikacija

- **Chat**: hrvatski. **Kod, komentari, commit poruke, README**: engleski.
