# Build Documentation Script
# Usage: .\.ai\scripts\helpers\build-docs.ps1 [-Clean] [-Force] [-Engine latexmk]

param (
    [switch]$Clean,
    [switch]$Force,
    [ValidateSet("auto", "tectonic", "latexmk")]
    [string]$Engine = "auto"
)

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }
Set-Location $rootDir

Write-Host "--- Building Documentation ---" -ForegroundColor Cyan

$distDir = Join-Path $rootDir "dist"
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }

# Detect engine
if ($Engine -eq "auto") {
    if (Get-Command tectonic -ErrorAction SilentlyContinue) {
        $Engine = "tectonic"
    } elseif (Get-Command latexmk -ErrorAction SilentlyContinue) {
        $Engine = "latexmk"
    } else {
        Write-Host "No LaTeX compiler found. Install Tectonic or TeX Live." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Engine: $Engine" -ForegroundColor Gray

# Read max_pages from project.yaml (0 = no check)
$maxPages = 0
$yamlPath = Join-Path $rootDir ".ai\config\project.yaml"
if (Test-Path $yamlPath) {
    $yamlContent = Get-Content $yamlPath -Raw
    if ($yamlContent -match 'max_pages:\s*(\d+)') {
        $maxPages = [int]$Matches[1]
    }
}

# Build LaTeX documents
$texFiles = Get-ChildItem -Path "docs" -Filter "*.tex" -Recurse -Depth 1 -ErrorAction SilentlyContinue

if (-not $texFiles) {
    Write-Host "No .tex files found in docs/." -ForegroundColor Yellow
    exit 0
}

foreach ($file in $texFiles) {
    Write-Host "Building $($file.Name)..." -ForegroundColor Yellow
    $outDir = Join-Path $file.DirectoryName "build"

    # -Force: briše build/ da prisili potpunu rekompilaciju (rješava latexmk stale cache)
    if ($Force -and (Test-Path $outDir)) {
        Remove-Item -Recurse -Force $outDir
        Write-Host "  Force clean: build/ obrisan." -ForegroundColor Gray
    }

    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    if ($Engine -eq "tectonic") {
        tectonic -X compile $file.FullName --outdir $outDir
    } else {
        latexmk -pdf -interaction=nonstopmode -shell-escape "-outdir=$outDir" $file.FullName
    }

    if ($LASTEXITCODE -eq 0) {
        $pdfName = $file.BaseName + ".pdf"
        $generatedPdf = Join-Path $outDir $pdfName
        if (Test-Path $generatedPdf) {
            Copy-Item $generatedPdf -Destination (Join-Path $distDir $pdfName) -Force
            Write-Host "Done: $pdfName -> dist/" -ForegroundColor Green
        }

        # Provjera broja stranica (iz .log fajla — latexmk i pdflatex pišu "Output written on ...")
        if ($maxPages -gt 0) {
            $logFile = Join-Path $outDir ($file.BaseName + ".log")
            if (Test-Path $logFile) {
                $logContent = Get-Content $logFile -Raw
                if ($logContent -match 'Output written on[^(]+\((\d+) page') {
                    $pageCount = [int]$Matches[1]
                    if ($pageCount -gt $maxPages) {
                        Write-Host "  UPOZORENJE: $pageCount stranica (limit: $maxPages)!" -ForegroundColor Red
                    } else {
                        Write-Host "  Stranice: $pageCount / $maxPages" -ForegroundColor Green
                    }
                }
            }
        }
    } else {
        Write-Host "FAILED: $($file.Name)" -ForegroundColor Red
    }
}

if ($Clean) {
    Write-Host "Cleaning build directories..." -ForegroundColor Gray
    Get-ChildItem -Path "docs" -Directory -Filter "build" -Recurse | Remove-Item -Recurse -Force
}

Write-Host "--- Build Finished ---" -ForegroundColor Cyan
