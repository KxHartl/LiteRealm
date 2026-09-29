<#
.SYNOPSIS
    Run AgentBrain Style, Linter & Local Humanizer scripts without typing brain path.
.EXAMPLE
    .\.ai\scripts\helpers\style.ps1 check docs/chapters/00-uvod.tex
    .\.ai\scripts\helpers\style.ps1 humanize docs/chapters/00-uvod.tex --in-place
    .\.ai\scripts\helpers\style.ps1 learn docs/chapters/00-uvod.tex
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet("check", "humanize", "learn")][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$brain = if ($env:AGENTBRAIN_PATH) { $env:AGENTBRAIN_PATH } else { Join-Path $env:USERPROFILE ".agentbrain" }
$script = switch ($Command) {
    "check"    { Join-Path $brain "scripts\style\check_style.py" }
    "humanize" { Join-Path $brain "scripts\style\local_humanizer.py" }
    "learn"    { Join-Path $brain "scripts\style\learn_style.py" }
}

if (-not (Test-Path $script)) {
    Write-Host "Not found: $script - is AgentBrain installed?" -ForegroundColor Red
    exit 1
}

$py = Join-Path $brain ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }
& $py $script @Rest
exit $LASTEXITCODE
