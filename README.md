# LiteRealm

**LiteRealm** je napredni *boilerplate* (predložak) dizajniran za brzu, robusnu i OS-neovisnu izradu akademskih radova, zadaća i softverskih projekata uz pomoć AI agenata (Gemini, Claude, Copilot). 

Umjesto instaliranja teških alata poput LaTeX-a lokalno, LiteRealm nudi **Dev Containers** (opcionalno, ali preporučeno) kako bi sve radilo savršeno u izoliranom Docker okruženju. Ako ne želiš Docker, možeš raditi potpuno lokalno (potrebni su ti samo Python i LaTeX instalacija).

Sve opće skripte, predlošci (seminari, radovi) i "vještine" agenata pohranjene su u odvojenom globalnom repozitoriju: **`AgentBrain`**. LiteRealm je namjerno "lagan" i usredotočen isključivo na tvoj specifični rad.

---

## 🚀 Brzi Start (Inicijalizacija)

### 1. Preduvjeti
Ovisno o tome kako želiš raditi, osiguraj jedno od navedenog:
- **Lokalno**: Python 3.10+ i TeX Live / MiKTeX distribucija (za kompilaciju PDF-ova).
- **Preko Dockera (Opcionalno)**: Docker Desktop i VS Code ekstenzija *Dev Containers*.

### 2. Kreiranje novog projekta i AgentBrain
Ovaj repozitorij koristi se kao predložak:
1. Na GitHubu klikni na zeleni gumb **"Use this template"** -> **"Create a new repository"**.
2. Nazovi repozitorij imenom svog seminara/rada i kloniraj ga na svoje računalo:
   ```bash
   git clone <URL_tvog_novog_repoa>
   cd <Ime_Tvoje_Mape>
   ```
3. **Važno:** LiteRealm oslanja se na globalni "mozak". Ako već nemaš kloniran `AgentBrain` repozitorij, kloniraj ga u svoj *home* direktorij:
   ```bash
   git clone <URL_tvog_AgentBrain_repoa> ~/.agentbrain
   ```
   *(Ako radiš na Windowsu, to je `C:\Users\TvojeIme\.agentbrain`)*

*(Opcionalno: Ako koristiš Docker, sada otvori VS Code i klikni "Reopen in Container".)*

### 3. Inicijalizacija Projekta
Sada kada si unutar kontejnera, otvori terminal (u VS Code-u) i pokreni instalacijsku skriptu:

**Windows (PowerShell unutar kontejnera/hosta):**
```powershell
.\.ai\scripts\bootstrap.ps1 -Name "Naziv_Mog_Rada" -Rag cloud
```
**Linux / macOS (Bash unutar kontejnera):**
```bash
./.ai/scripts/bootstrap.sh --name "Naziv_Mog_Rada" --rag cloud
```

Skripta će automatski:
- Kreirati sve potrebne direktorije (`data/raw`, `data/processed`, `docs`, `src`).
- Podesiti `.env` datoteku.
- Kreirati virtualno okruženje (`.venv`) i instalirati Python pakete.
- Napisati naziv projekta u `STATE.md` i `project.yaml`.

### 4. Kopiranje Predloška
Tvoji LaTeX i Word predlošci žive u globalnom mozgu (`AgentBrain`).
Nakon što se projekt inicijalizira, jednostavno prekopiraj željeni predložak iz `~/.agentbrain/templates/` (npr. `fsb-seminar` ili `fsb-paper`) u mapu `docs/`. Zatim pozovi svog AI agenta da počne pisati!

---

## 📁 Struktura Direktorija

| Direktorij | Svrha |
|---|---|
| `docs/` | Tvoj pisani rad! `.tex` fajlovi, slike i generirani PDF-ovi. |
| `src/` | Programski kod, skripte i algoritmi. |
| `dist/` | Konačne verzije za predaju (npr. zip, finalni PDF). |
| `data/raw/` | Izvorni podaci (izvješća, tablice, dumpovi s API-ja). **Samo za čitanje.** |
| `data/processed/` | Tvoje obrade. (Obavezno u podmape oblika `izvor_ddmmyyyy_hhmmss`). |
| `data/sources/` | PDF dokumenti i literatura iz koje RAG uči (stavljati direktno ovdje). |
| `.ai/` | Interna pravila (`AGENTS.md`) i skripte okruženja. |
| `~/.agentbrain/` | (Zasebni repozitorij) Globalni predlošci, vještine i RAG skripte. |

---

## 🤖 Rad s AI Agentima

LiteRealm nameće vrlo stroga i čista pravila za rad agenata kako ne bi uništili repozitorij:
1. **Zapisivanje izvora**: Kad god AI skine sliku ili dokument s interneta, mora to upisati u `data/SOURCES_LOG.md`.
2. **Vidljivi Git Commits**: AI agenti dužni su raditi **inkrementalne** commitove. Svaki zadatak koji AI završi mora sadržavati oznaku `🤖 [AI]` u Git povijesti.
3. **Izolirani rad**: Za sve riskantne zadatke (instalacije ovisnosti, masovno preuređivanje), AI je dužan koristiti `git worktree` kako bi zaštitio glavni kod, te zatražiti tvoj *review* (pregled) prije spajanja na `main` granu.

---

## 📚 RAG (Razgovor s tvojom literaturom)

Umjesto haluciniranja izvora, agenti koriste **Retrieval-Augmented Generation (RAG)** bazu spojenu na tvoj `data/sources/` folder.
1. Stavi literature u `data/sources/`.
2. Ingestiraj ih (baza ide skriveno u `.ai/rag/db/`):
   ```bash
   python ~/.agentbrain/scripts/rag/ingest.py
   ```
3. Zatraži od agenta: *"Napiši mi odlomak koristeći lokalne izvore."*

---

## 🔨 Kompilacija PDF-a

Za ručnu kompilaciju, pokreni:
```powershell
.\.ai\scripts\helpers\build-docs.ps1       # PowerShell
./.ai/scripts/helpers/build-docs.sh        # Bash
```
S obzirom na to da se radi u `.devcontainer` okruženju, svi fontovi, jezični paketi i prevoditelji već su automatski spremni!
