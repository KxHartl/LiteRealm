<#
.SYNOPSIS
    Promote user-approved files from data/staging/<category>/ to data/sources/<category>/.
    data_fetcher only stages; promotion is the user's explicit decision (REFERENCE.md -> Citiranje).
.EXAMPLE
    .\.ai\scripts\helpers\promote-sources.ps1 -Category papers
    .\.ai\scripts\helpers\promote-sources.ps1 -Category papers -Filenames a.pdf, b.pdf
    .\.ai\scripts\helpers\promote-sources.ps1 -All -Ingest
#>
param(
    [string]$Category,
    [string[]]$Filenames,
    [switch]$All,
    [switch]$Ingest,
    [switch]$DryRun
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$staging = Join-Path $root "data\staging"
$log = Join-Path $root "data\SOURCES_LOG.md"

if (-not $All -and -not $Category) {
    Write-Host "Usage: promote-sources.ps1 -Category <name> [-Filenames ...] | -All  [-Ingest] [-DryRun]" -ForegroundColor Red
    exit 1
}

$categories = if ($All) {
    Get-ChildItem $staging -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.Name }
} else { @($Category) }

$moved = 0
foreach ($cat in $categories) {
    $src = Join-Path $staging $cat
    if (-not (Test-Path $src -PathType Container)) {
        Write-Host "No staging folder: data/staging/$cat" -ForegroundColor Red
        exit 1
    }
    $candidates = if ($Filenames) {
        $Filenames | ForEach-Object { Join-Path $src $_ }
    } else {
        Get-ChildItem $src -File | Where-Object { $_.Extension -match '^\.(pdf|docx|pptx|xlsx)$' } |
            Sort-Object Name | ForEach-Object { $_.FullName }
    }
    foreach ($f in $candidates) {
        if (-not (Test-Path $f -PathType Leaf)) { Write-Host "Not found: $f" -ForegroundColor Red; exit 1 }
        $name = Split-Path $f -Leaf
        $destDir = Join-Path $root "data\sources\$cat"
        $dest = Join-Path $destDir $name
        if (Test-Path $dest) { Write-Host "  skip (exists): data/sources/$cat/$name"; continue }
        Write-Host "  data/staging/$cat/$name -> data/sources/$cat/$name"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
            Move-Item $f $dest
            $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
            Add-Content $log "| $stamp | see data/staging/$cat/manifest.yaml | data/sources/$cat/$name | promoted from staging | ok |"
        }
        $moved++
    }
}

$suffix = if ($DryRun) { " (dry run)" } else { "" }
Write-Host "Promoted: $moved file(s)$suffix."
if ($moved -gt 0 -and -not $DryRun) {
    Write-Host "Next: add BibTeX with 'rag.ps1 cite --doi ... --file <data/sources/...>'."
    if ($Ingest) { & (Join-Path $PSScriptRoot "rag.ps1") ingest; exit $LASTEXITCODE }
}
