# LiteRealm — Referentni priručnik za AI Agente

> [!WARNING]
> **ZA AI AGENTE:** Ovaj dokument služi isključivo kao *referentni priručnik (on-demand)*. NEMOJ ga čitati u cijelosti prije početka zadatka. Čitaj samo specifične sekcije ako su ti izričito potrebne (npr. RAG detalji, definicije agenta). Sva glavna ponašajna pravila već imaš iz root `AGENTS.md` (Claude/Gemini ga importaju kroz CLAUDE.md / GEMINI.md).

Ovo je workspace za pisanje seminara, zadaća i akademskih radova uz pomoć AI agenata.

## Direktoriji (strogo poštivati)

| Direktorij | Što ide ovdje | Napomena |
|---|---|---|
| `docs/` | LaTeX projekt: `main.tex`, `chapters/`, `figures/`, `references.bib`, generirani PDF-ovi | Prazno dok `latex_architect` ne postavi strukturu |
| `docs/chapters/` | Pojedina poglavlja kao zasebni `.tex` fajlovi | `\input{}` ih iz `main.tex` |
| `docs/figures/` | Slike, dijagrami, grafovi | Samo rasterski/vektorski format |
| `docs/tables/` | Kompleksne tablice i `.csv` podaci | Učitava se via `\input{}` |
| `docs/code/` | Snippeti koda za ispis u dokumentu | Paketi poput `minted` ili `listings` |
| `src/` | Programski kod (`.py`, `.cpp`, `.js`…) ako zadatak to zahtijeva | |
| `dist/` | Konačne verzije za predaju. **Obavezno u podfoldere po verziji**: `dist/v1.0/`, `dist/v1.1/` itd. | PDF-ovi su gitignorirani |
| `data/raw/` | Sirovi ulazni podaci. **READ-ONLY** — nikad se ne mjenjaju | Git hook blokira promjene |
| `data/processed/` | Obrađeni podaci. Sve u subfolderima oblika `izvor_ddmmyyyy_hhmmss` | |
| `data/sources/` | PDF literatura, članci, prezentacije za RAG bazu | Praćeni putem Git LFS |
| `.ai/` | Interne konfiguracije, skripte, RAG baza projekta | Ne mijenjati bez razloga |

## Agent Routing

Specijalizirani agenti su definirani u `~/.agentbrain/agents/` (source of truth). Za
Claude Code su sinkronizirani kao native subagenti u `.claude/agents/` — regeneriraj ih
nakon promjene definicija: `python ~/.agentbrain/scripts/sync_agents.py --project-root .`

Svaki agent ima jasno definirano područje odgovornosti:

| Agent | Zadatak | Kada koristiti |
|---|---|---|
| `latex_architect` | Postavljanje LaTeX strukture u `docs/` | **Jednom**, kad korisnik kaže "počni pisati", "pripremi LaTeX", "setup docs" |
| `data_fetcher` | Pronalaženje i preuzimanje literature | Korisnik traži "pronađi izvore", "preuzmi PDF", "search for papers" |
| `writer` | Pisanje akademskog teksta u LaTeX | Korisnik traži "napiši poglavlje", "proširi tekst", "draft section" |
| `latex_surgeon` | Popravak LaTeX grešaka | Kompilacija pada, `.log` sadrži greške |
| `qa_reviewer` | Pregled i kritika napisanog | Sekcija/poglavlje gotovo, prije predaje |
| `rag_indexer` | Ažuriranje RAG baze | Novi PDF-ovi dodani u `data/sources/` |

**Pipeline redoslijed**: `latex_architect` → fetch → write → review → fix → index

## LaTeX

1. Provjeri `project.yaml` za odabrani LaTeX format (`latex_format` polje).
2. **`latex_architect` automatski kopira predložak** iz `~/.agentbrain/templates/` u `docs/` i kompilira.
3. Nakon postavljanja: piši u `docs/chapters/`, unosi u `docs/main.tex` via `\input{}`.
4. Za kompilaciju koristi: `.ai/scripts/helpers/build-docs.ps1` (ili `.sh`).
5. Podržani compileri: **Tectonic** (preporuka) ili `latexmk` (legacy).
6. Tectonic izlazni PDF je pored `.tex` fajla — skripta ga kopira u `dist/<verzija>/`.

## dist/ — Versioning

- Build skripta uvijek piše u **versionirani podfolder** `dist/<verzija>/`, nikad u `dist/` root.
- Default verzija je `dev` (radni buildovi). Za predaju cuti release s eksplicitnom verzijom:
  `build-docs.ps1 -Version v1.0` (ili `--version v1.0`), ili postavi `dist_version` u `project.yaml`.
- PDF-ovi su gitignorirani (`dist/**/*.pdf`) — commitaj samo `.gitkeep` kad kreiraš novu verziju.
- Primjer toka: `build-docs.ps1 -Version v1.0` → `dist/v1.0/main.pdf`.

## data/raw/ — Read-Only Pravilo

`data/raw/` sadržava izvorne, nepromijenjene podatke. **Nikad se ne mjenjaju.**

- Git pre-commit hook (instaliran via bootstrap) blokira commitanje promjena u `data/raw/`.
- Agenti smiju **čitati** iz `data/raw/` ali ne i pisati.
- Obrađene verzije idu u `data/processed/izvor_ddmmyyyy_hhmmss/`.

## data/sources/ — Git LFS

- Svi PDF-ovi i dokumenti u `data/sources/` praćeni su putem **Git LFS**.
- Potrebno: `git lfs install` jednom na računalu.
- Dodavanje izvora: `git add data/sources/clanak.pdf && git commit -m "feat: add source ..."`.
- **Zabranjeno**: dodavati izvore direktno bez LFS-a (check `.gitattributes`).

## RAG — Citiranje iz izvora

RAG je **uvijek dostupan** kroz AgentBrain (`~/.agentbrain`) — nema toggle opcije.
Embeddings koriste Gemini ako je `GEMINI_API_KEY` postavljen u `.env`, inače lokalni
`sentence-transformers`. Agent može pretraživati korisnikove PDF izvore:

Koristi `rag` wrapper (`.\.ai\scripts\helpers\rag.ps1` na Windowsu, `./.ai/scripts/helpers/rag.sh` na bashu) — razrješava putanju do braina i izbjegava `~` koji se u PowerShellu ne razvija:

1. **Ingestija**: `rag ingest` — parsira PDF-ove iz `data/sources/` koristeći Docling i sprema u LanceDB bazu u `.ai/rag/db/`.
2. **Pretraga**: `rag query "pitanje" --scope both` — vraća relevantne odlomke s izvorom i stranicom.
3. **Citiranje**: Koristi dobivene reference za precizno citiranje u seminaru (`\cite{key}`).
4. **BibTeX**: `rag cite --doi "10.xxxx/yyyy"`

**Lokacija baze**: Vektorska baza je regenerabilan artefakt u `.ai/rag/db/`. LanceDB ne može
commitati na FAT/exFAT diskovima, pa se na takvim volumenima baza automatski premješta u
`%LOCALAPPDATA%\AgentBrain\rag\<projekt>\db` (ingest ispiše točnu putanju). PDF izvori ostaju u
`data/sources/`. Override lokacije: postavi `RAG_DB_DIR`.

## Global Brain

Ovaj projekt koristi `AgentBrain` (`~/.agentbrain`) kao "mozak":
- Čitaj naučene lekcije iz `~/.agentbrain/gotchas/`.
- Čitaj skill definicije iz `~/.agentbrain/skills/`.
- Čitaj definicije agenata iz `~/.agentbrain/agents/`.
- **KONTINUIRANA OPTIMIZACIJA**: Ako otkriješ novi *gotcha*, koristan prompt ili novu vještinu, **samostalno ažuriraj `~/.agentbrain/`**.

## Git & Kontrola Verzija

1. **AI Oznake**: Prefiks `🤖 [AI]` u naslovu commita.
2. **Inkrementalni Commits**: Commitaj svaku logičku cjelinu odmah. Helper:
   `.\.ai\scripts\helpers\checkpoint.ps1 "feat: opis"` (ili `checkpoint.sh`) radi
   `add -A` + commit i sam dodaje `🤖 [AI]` prefiks ako nedostaje.
3. **Strategija Grananja**:
   - Manje prepravke i pisanje teksta: radi izravno na `main`.
   - Veće strukturne promjene: kreiraj granu `ai/ime-featurea`.
4. **Git Worktrees**: Za rizične eksperimentalne zadatke koristi `git worktree add ../<ime> <branch>`.

## Citiranje i Praćenje Izvora

**Redoslijed je obvezan: `data_fetcher` → `writer`. Writer ne počinje pisati bez PDF-ova u `data/sources/`.**

1. **Lokalni Izvori**: Citiraj isključivo radove čiji PDF postoji u `data/sources/`.
   Zabranjeno izmišljanje izvora. Zabranjeno dodavanje `\cite{}` bez PDF-a.
2. **Iznimka (paywalled)**: Ako rad nije open-access, `data_fetcher` to logira u
   `data/SOURCES_LOG.md`. Samo tada writer smije koristiti DOI-generirani BibTeX —
   uz obaveznu napomenu da autori nisu verificirani s originalnim dokumentom.
3. **Writer ne zove `add_citation.py`**: Generiranje BibTeX-a iz DOI-a isključivo
   radi `data_fetcher`. Writer samo koristi ključeve koje je data_fetcher pribavio.
   `data_fetcher` uvijek dodaje citat s `--file <pdf>`, pa `references.bib` veže PDF na
   ključ; `rag query` onda iz `source_file` ispiše točan `\cite[str.~N]{key}` koji writer
   koristi (parafraza + citat po tvrdnji). Writer **ne izmišlja ključ** — nema ga u outputu
   query-ja → izvor nije spreman, traži `data_fetcher`.
4. **Praćenje**: Svako preuzimanje logirati u `data/SOURCES_LOG.md`:
   - `[Datum Vrijeme] - [URL] - [Lokalna putanja] - [Kratki opis]`
5. **QA provjera**: `qa_reviewer` flagira kao CRITICAL ako `data/sources/` je prazan
   a `references.bib` ima stavke.

## Komunikacija

- **Chat**: Hrvatski jezik.
- **Kod, komentari, README i commit poruke**: Engleski jezik.
- **Commit format**: Conventional Commits uz `🤖 [AI]`.
