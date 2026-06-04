<#
.SYNOPSIS
    Bootstrap a new LiteRealm project.
.EXAMPLE
    .\.ai\scripts\bootstrap.ps1 -Name "Autonomni_Vilicari"
    .\.ai\scripts\bootstrap.ps1 -Name "Seminar_MEV" -Rag cloud
    .\.ai\scripts\bootstrap.ps1 -Auto
#>

param (
    [string]$Name,
    [ValidateSet("none", "cloud", "local")]
    [string]$Rag = "none",
    [ValidateSet("none", "global")]
    [string]$Brain = "global",
    [switch]$Auto
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $root) { $root = Get-Location }

$marker = Join-Path $root ".ai\.bootstrapped"
$brainVersion = "unknown"   # set once AgentBrain is located; used in the marker

# --- Auto mode: read name from project.yaml ---
if ($Auto -and -not $Name) {
    $yamlFile = Join-Path $root ".ai\config\project.yaml"
    if (Test-Path $yamlFile) {
        $content = Get-Content $yamlFile -Raw
        if ($content -match 'name:\s*"([^"]+)"') {
            $existing = $Matches[1]
            if ($existing -ne "TBD") {
                $Name = $existing
            }
        }
    }
    if (-not $Name) {
        Write-Host ""
        Write-Host "Project name not set yet. Run bootstrap manually:" -ForegroundColor Yellow
        Write-Host "  .\.ai\scripts\bootstrap.ps1 -Name 'Your_Project_Name'"
        Write-Host ""
        Write-Host "Continuing with directory setup only..."
    }
}

if (-not $Auto -and -not $Name) {
    Write-Host "Error: -Name is required." -ForegroundColor Red
    Write-Host "Usage: .\.ai\scripts\bootstrap.ps1 -Name 'Project_Name' [-Rag none|cloud|local]"
    exit 1
}

# --- Idempotency check ---
if (Test-Path $marker) {
    $prev = Get-Content $marker -Raw
    Write-Host ""
    Write-Host "Project already bootstrapped ($prev)." -ForegroundColor Yellow
    Write-Host "Re-running will update config only."
    Write-Host ""
}

Write-Host "`n=== LiteRealm Bootstrap ===" -ForegroundColor Cyan
Write-Host "Project: $(if ($Name) { $Name } else { '[not set]' })"
Write-Host "RAG:     $Rag"
Write-Host "Brain:   $Brain"
Write-Host ""

# --- 1. Set project name in config files ---
Write-Host "[1/7] Setting project name..." -ForegroundColor Yellow

if ($Name) {
    $stateFile = Join-Path $root "STATE.md"
    $yamlFile = Join-Path $root ".ai\config\project.yaml"

    if ((Test-Path $stateFile) -and (Get-Content $stateFile -Raw) -match '_TBD_') {
        (Get-Content $stateFile -Raw) -replace '_TBD_', $Name | Set-Content $stateFile -NoNewline
    }
    if ((Test-Path $yamlFile) -and (Get-Content $yamlFile -Raw) -match '"TBD"') {
        $yamlContent = (Get-Content $yamlFile -Raw) -replace '"TBD"', ('"' + $Name + '"')
        $yamlContent = $yamlContent -replace 'rag_mode: "none"', ('rag_mode: "' + $Rag + '"')
        $yamlContent | Set-Content $yamlFile -NoNewline
    }

    Write-Host "  Name '$Name' written to config files." -ForegroundColor Green
} else {
    Write-Host "  Skipped (no name provided)." -ForegroundColor Gray
}

# --- 2. Create directory structure ---
Write-Host "[2/7] Creating directories..." -ForegroundColor Yellow

$dirs = @("docs", "src", "dist", "data\raw", "data\processed", "data\sources")
foreach ($d in $dirs) {
    $path = Join-Path $root $d
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Kreiraj SOURCES_LOG.md ako ne postoji
$sourcesLog = Join-Path $root "data\SOURCES_LOG.md"
if (-not (Test-Path $sourcesLog)) {
    @"
# Sources Log

Log svih preuzetih izvora. Svaki unos popunjava `data_fetcher`.

| Datum | URL | Lokalna putanja | Opis | Status |
|-------|-----|-----------------|------|--------|
| <!-- [YYYY-MM-DD HH:MM] | [URL] | data/sources/naziv.pdf | kratki opis | ok\|paywalled\|failed --> |
"@ | Set-Content $sourcesLog -Encoding utf8
}

Write-Host "  Directories created." -ForegroundColor Green

# --- 3. Setup .env ---
Write-Host "[3/7] Configuring .env..." -ForegroundColor Yellow

$envFile = Join-Path $root ".env"
$envExample = Join-Path $root ".env.example"

if (Test-Path $envFile) {
    Write-Host "  .env already exists, skipping." -ForegroundColor Gray
} elseif (Test-Path $envExample) {
    Copy-Item $envExample $envFile
    Write-Host "  .env created from .env.example." -ForegroundColor Green
} else {
    Write-Host "  No .env.example found, skipping." -ForegroundColor Gray
}

# --- 4. AgentBrain setup + version contract ---
Write-Host "[4/7] Checking AgentBrain..." -ForegroundColor Yellow

$brainPath = if ($env:AGENTBRAIN_PATH) { $env:AGENTBRAIN_PATH } else { Join-Path $env:USERPROFILE ".agentbrain" }

if ($Brain -eq "global") {
    if (-not (Test-Path $brainPath)) {
        Write-Host "  AgentBrain not found at $brainPath. Cloning..." -ForegroundColor Yellow
        $repoUrl = "https://github.com/KxHartl/AgentBrain.git"
        git clone $repoUrl $brainPath 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  AgentBrain cloned successfully." -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Failed to clone AgentBrain (no internet?)." -ForegroundColor Red
            $fallback = Join-Path $root ".ai\fallback"
            if (Test-Path $fallback) {
                Copy-Item (Join-Path $fallback "minimal.tex") (Join-Path $root "docs\") -ErrorAction SilentlyContinue
                Copy-Item (Join-Path $fallback "references.bib") (Join-Path $root "docs\") -ErrorAction SilentlyContinue
                Write-Host "  Fallback template copied to docs/. RAG will not be available." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  AgentBrain found: $brainPath" -ForegroundColor Green
    }

    # Shared manifest handling — runs whether AgentBrain was just cloned or already present.
    $manifest = Join-Path $brainPath "manifest.yaml"
    if (Test-Path $manifest) {
        $manifestContent = Get-Content $manifest -Raw
        if ($manifestContent -match 'version:\s*"([^"]+)"') { $brainVersion = $Matches[1] }
        Write-Host "  AgentBrain version: $brainVersion" -ForegroundColor Green

        # Version contract: warn if this LiteRealm is older than the brain requires.
        $versionFile = Join-Path $root "VERSION"
        $liteVersion = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "unknown" }
        if ($manifestContent -match 'min_literealm_version:\s*"([^"]+)"') {
            $minLite = $Matches[1]
            try {
                if ([version]$liteVersion -lt [version]$minLite) {
                    Write-Host "  WARNING: LiteRealm $liteVersion is older than AgentBrain requires (min $minLite)." -ForegroundColor Red
                    Write-Host "           Update this project from the latest LiteRealm template." -ForegroundColor Red
                }
            } catch {
                Write-Host "  NOTE: cannot compare versions (LiteRealm '$liteVersion' vs min '$minLite')." -ForegroundColor Gray
            }
        }

        # Stamp brain version + commit into project.yaml (once).
        $yamlFile = Join-Path $root ".ai\config\project.yaml"
        if ((Test-Path $yamlFile) -and -not ((Get-Content $yamlFile -Raw) -match 'agentbrain_version')) {
            $brainCommit = "unknown"
            try {
                Push-Location $brainPath
                $brainCommit = git rev-parse --short HEAD 2>$null
                Pop-Location
            } catch { Pop-Location }

            Add-Content $yamlFile "`n# AgentBrain version used during bootstrap"
            Add-Content $yamlFile ('agentbrain_version: "' + $brainVersion + '"')
            Add-Content $yamlFile ('agentbrain_commit: "' + $brainCommit + '"')
        }
    } else {
        Write-Host "  WARNING: AgentBrain manifest.yaml not found. Consider updating AgentBrain." -ForegroundColor Yellow
    }
}

# --- 5. Python environment ---
Write-Host "[5/7] Python environment..." -ForegroundColor Yellow

$uvAvailable = Get-Command uv -ErrorAction SilentlyContinue

if ($uvAvailable) {
    Write-Host "  Using uv (fast mode)." -ForegroundColor Gray
    $venvPath = Join-Path $root ".venv"
    if (-not (Test-Path $venvPath)) {
        uv venv $venvPath
    }
    $pythonPath = Join-Path $venvPath "Scripts\python.exe"
    uv pip install --python $pythonPath -q python-dotenv

    # RAG deps only needed locally if NOT using global brain (agentbrain already has them)
    if ($Rag -ne "none" -and $Brain -ne "global") {
        Write-Host "  Installing RAG dependencies..." -ForegroundColor Gray
        uv pip install --python $pythonPath -q docling lancedb sentence-transformers pypdf
    } elseif ($Rag -ne "none") {
        Write-Host "  RAG enabled — using ~/.agentbrain/.venv (skipping local install)." -ForegroundColor Gray
    }
    Write-Host "  Python OK (uv)." -ForegroundColor Green
} else {
    # Fallback to traditional pip/venv
    $pythonCmd = $null
    foreach ($cmd in @("python3", "python")) {
        try {
            $ver = & $cmd --version 2>&1
            if ($ver -match "Python 3\.") {
                $pythonCmd = $cmd
                break
            }
        } catch {}
    }

    if ($pythonCmd) {
        $venvPath = Join-Path $root ".venv"
        if (-not (Test-Path $venvPath)) {
            Write-Host "  Creating virtual environment..." -ForegroundColor Gray
            & $pythonCmd -m venv $venvPath
        }

        $pipCmd = Join-Path $venvPath "Scripts\pip.exe"
        if (Test-Path $pipCmd) {
            $oldPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                & $pipCmd install -q python-dotenv

                # RAG deps only needed locally if NOT using global brain
                if ($Rag -ne "none" -and $Brain -ne "global") {
                    Write-Host "  Installing RAG dependencies..." -ForegroundColor Gray
                    & $pipCmd install -q docling lancedb sentence-transformers pypdf
                } elseif ($Rag -ne "none") {
                    Write-Host "  RAG enabled — using ~/.agentbrain/.venv (skipping local install)." -ForegroundColor Gray
                }
            }
            finally {
                $ErrorActionPreference = $oldPreference
            }
        }
        Write-Host "  Python OK ($pythonCmd)." -ForegroundColor Green
    } else {
        Write-Host "  Python not found - skipping venv setup." -ForegroundColor Yellow
    }
}

# --- 6. Git setup: pre-commit hook + Git LFS ---
Write-Host "[6/7] Git setup (hooks + LFS)..." -ForegroundColor Yellow

$insideRepo = $false
try {
    Push-Location $root
    git rev-parse --is-inside-work-tree *> $null
    $insideRepo = ($LASTEXITCODE -eq 0)
    Pop-Location
} catch { try { Pop-Location } catch {} }

$hookDir = Join-Path $root ".git\hooks"
$preCommitHook = Join-Path $hookDir "pre-commit"

$hookContent = @'
#!/bin/sh
# LiteRealm: block changes to data/raw/ — it is read-only source data.
if git diff --cached --name-only | grep -q "^data/raw/"; then
    echo "ERROR: data/raw/ is read-only. Move processed files to data/processed/." >&2
    exit 1
fi
'@

if (Test-Path $hookDir) {
    if (-not (Test-Path $preCommitHook)) {
        $hookContent | Set-Content $preCommitHook -Encoding utf8
        Write-Host "  pre-commit hook installed (data/raw/ protection)." -ForegroundColor Green
    } else {
        Write-Host "  pre-commit hook already exists, skipping." -ForegroundColor Gray
    }
} else {
    Write-Host "  Not a git repo (no .git/hooks) — skipping pre-commit hook." -ForegroundColor Gray
}

git lfs version *> $null
if ($LASTEXITCODE -eq 0) {
    if ($insideRepo) {
        Push-Location $root
        git lfs install --local *> $null
        Pop-Location
        Write-Host "  Git LFS installed (data/sources/ large files tracked)." -ForegroundColor Green
    } else {
        Write-Host "  Git LFS present but not inside a repo — skipping install." -ForegroundColor Gray
    }
} else {
    Write-Host "  WARNING: git-lfs not found. Install it (https://git-lfs.com) so PDFs in" -ForegroundColor Yellow
    Write-Host "           data/sources/ are tracked via LFS, not committed as large blobs." -ForegroundColor Yellow
}

# --- 7. Check LaTeX (Tectonic) ---
Write-Host "[7/7] Checking LaTeX compiler..." -ForegroundColor Yellow

$tectonic = Get-Command tectonic -ErrorAction SilentlyContinue
$latexmk = Get-Command latexmk -ErrorAction SilentlyContinue

if ($tectonic) {
    Write-Host "  tectonic found (recommended engine)." -ForegroundColor Green
} elseif ($latexmk) {
    Write-Host "  latexmk found (legacy fallback). Tectonic is the canonical engine." -ForegroundColor Yellow
} else {
    Write-Host "  No LaTeX compiler found." -ForegroundColor Red
    Write-Host "  Install Tectonic: https://tectonic-typesetting.github.io/en-US/install.html"
    Write-Host "  Or install MiKTeX / TeX Live for latexmk."
}

# --- Done ---
$timestamp = Get-Date -Format "o"
"$timestamp | brain=$brainVersion | rag=$Rag" | Set-Content $marker

Write-Host "`n=== Bootstrap complete ===" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor White
Write-Host '  1. Fill in STATE.md and .ai/config/project.yaml with your assignment details'
Write-Host '  2. Tell your AI agent: "počni pisati" — latex_architect sets up docs/ automatically'
Write-Host '  3. Add literature PDFs to data/sources/ (tracked via Git LFS)'
if ($Rag -ne 'none') {
    Write-Host '  4. Run ingest.py to build the RAG database from your sources'
}
Write-Host ''
