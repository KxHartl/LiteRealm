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
| `data/raw/` | Sirovi ulazni podaci. **APPEND-ONLY** — novi fajlovi da, postojeći se nikad ne mijenjaju | Git hook blokira izmjenu/brisanje |
| `data/processed/` | Obrađeni podaci. Sve u subfolderima oblika `izvor_ddmmyyyy_hhmmss` | |
| `data/staging/` | Izvori koje je `data_fetcher` preuzeo, čekaju pregled korisnika | Binarni gitignorirani; `STAGING_CATALOG.md` i `manifest.yaml` praćeni |
| `data/sources/` | PDF literatura, članci, prezentacije za RAG bazu | Praćeni putem Git LFS |
| `data/*.md` | `SOURCES_LOG.md`, `EXPERIMENTS_LOG.md`, `DATA_DICTIONARY.md` | Logovi izvora i mjerenja |
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
| `data_engineer` | Mjerenja, simulacije, obrada podataka, grafovi i tablice | "novo mjerenje", "obradi podatke", "kreiraj graf" |
| `defense_simulator` | Simulacija obrane pred komisijom → `docs/DEFENSE_PREP.md` | "simuliraj obranu", "ispitaj me" |

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

`data/raw/` sadržava izvorne, nepromijenjene podatke. **Nikad se ne mijenjaju** (append-only).

- Git pre-commit hook (instaliran via bootstrap) dopušta dodavanje novih fajlova, a blokira
  izmjenu, brisanje i preimenovanje postojećih.
- Agenti smiju **čitati** iz `data/raw/` ali ne i pisati.
- Obrađene verzije idu u `data/processed/izvor_ddmmyyyy_hhmmss/`.

## data/sources/ — Git LFS

- Svi PDF-ovi i dokumenti u `data/sources/` praćeni su putem **Git LFS**.
- Potrebno: `git lfs install` jednom na računalu.
- Dodavanje izvora: `git add data/sources/clanak.pdf && git commit -m "feat: add source ..."`.
- **Zabranjeno**: dodavati izvore direktno bez LFS-a (check `.gitattributes`).

## RAG — Citiranje iz izvora

RAG je **uvijek dostupan** kroz AgentBrain (`~/.agentbrain`) — nema toggle opcije.
Embeddings: lokalni Ollama (`OLLAMA_EMBED_MODEL`), zatim Gemini (`GEMINI_API_KEY`), inače
`sentence-transformers`; `RAG_STRICT_EMBED=1` zabranjuje tihu zamjenu modela. Spremište: Qdrant
ako je `QDRANT_URL` postavljen, inače lokalni LanceDB (vidi `.env.example`). Agent može
pretraživati korisnikove PDF izvore:

Koristi `rag` wrapper (`.\.ai\scripts\helpers\rag.ps1` na Windowsu, `./.ai/scripts/helpers/rag.sh` na bashu) — razrješava putanju do braina i izbjegava `~` koji se u PowerShellu ne razvija:

1. **Ingestija**: `rag ingest` — parsira PDF-ove iz `data/sources/` koristeći Docling i sprema u LanceDB bazu u `.ai/rag/db/`.
2. **Pretraga**: `rag query "pitanje" --scope both` — vraća relevantne odlomke s izvorom i stranicom.
3. **Citiranje**: Koristi dobivene reference za precizno citiranje u seminaru (`\cite{key}`).
4. **BibTeX**: `rag cite --doi "10.xxxx/yyyy"`
5. **Inkrementalno**: `rag sync` — indeksira samo nove/promijenjene izvore.
6. **Klasifikacija**: `rag classify <pdf>` — predlaže kategoriju (`data/staging/<category>/`).

**Lokacija baze**: Vektorska baza je regenerabilan artefakt u `.ai/rag/db/`. LanceDB ne može
commitati na FAT/exFAT diskovima, pa se na takvim volumenima baza automatski premješta u
`%LOCALAPPDATA%\AgentBrain\rag\<projekt>\db` (ingest ispiše točnu putanju). PDF izvori ostaju u
`data/sources/`. Override lokacije: postavi `RAG_DB_DIR`.

## Ostali helperi (`.ai/scripts/helpers/`, `.ps1` i `.sh`)

| Helper | Komande | Što radi |
|---|---|---|
| `experiment` | `new --type exp\|sim\|bench\|acq --name <slug> --desc "..."`, `process --raw <dir> --script <py>`, `list`, `audit` | Mape mjerenja u `data/raw/`, provenance u `data/processed/`, `data/EXPERIMENTS_LOG.md` |
| `style` | `check <tex>`, `humanize <tex> [--in-place]`, `learn <tex>` | Human Style Score (cilj > 75), anti-AI klišeji, profil autora `~/.agentbrain/style/` |
| `thesis` | `status`, `audit` | Pregled stanja rada: poglavlja, citati, TODO-i |
| `promote-sources` | vidi Citiranje | `data/staging/` → `data/sources/` |
| `checkpoint` | `[--ai] "type: opis"` | Commit svega; pravilo 1.1 |

## Global Brain

Ovaj projekt koristi `AgentBrain` (`~/.agentbrain`) kao "mozak":
- Čitaj naučene lekcije iz `~/.agentbrain/gotchas/`.
- Čitaj skill definicije iz `~/.agentbrain/skills/`.
- Čitaj definicije agenata iz `~/.agentbrain/agents/`.
- **KONTINUIRANA OPTIMIZACIJA**: Ako otkriješ novi *gotcha*, koristan prompt ili novu vještinu, **samostalno ažuriraj `~/.agentbrain/`**.

## Git & Kontrola Verzija

1. **AI Oznake**: Prefiks `🤖 [AI]` u naslovu commita samo kad je agent napravio posao
   (AGENTS.md pravilo 1.1).
2. **Inkrementalni Commits**: Commitaj svaku logičku cjelinu odmah. Helper:
   `.\.ai\scripts\helpers\checkpoint.ps1 [-Ai] "feat: opis"` (ili `checkpoint.sh [--ai]`) radi
   `add -A` + commit; `-Ai`/`--ai` dodaje `🤖 [AI]` prefiks i `Co-Authored-By` trailer, a bez
   zastavice odbija poruku koja sadrži `[AI]`. `post-commit` hook odmah pusha granu.
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
4. **Staging → sources**: `data_fetcher` sprema samo u `data/staging/<category>/` uz
   `STAGING_CATALOG.md`. Korisnik pregleda i promovira:
   `promote-sources.ps1 -Category <cat>` (bash: `promote-sources.sh <cat>`, `--ingest` odmah indeksira).
   Promocija upisuje red u `data/SOURCES_LOG.md`; tek nakon nje ide `rag cite --doi ... --file <pdf>`.
5. **QA provjera**: `qa_reviewer` flagira kao CRITICAL ako `data/sources/` je prazan
   a `references.bib` ima stavke.

## Komunikacija

- **Chat**: Hrvatski jezik.
- **Kod, komentari, README i commit poruke**: Engleski jezik.
- **Commit format**: Conventional Commits; `🤖 [AI]` prema AGENTS.md pravilu 1.1.
