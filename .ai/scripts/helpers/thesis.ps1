<#
.SYNOPSIS
    Master's Thesis Status Dashboard & Audit helper.
.EXAMPLE
    .\.ai\scripts\helpers\thesis.ps1 status
    .\.ai\scripts\helpers\thesis.ps1 audit
#>
param(
    [Parameter(Position = 0)][ValidateSet("status", "audit")][string]$Command = "status",
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$brain = if ($env:AGENTBRAIN_PATH) { $env:AGENTBRAIN_PATH } else { Join-Path $env:USERPROFILE ".agentbrain" }
$script = Join-Path $brain "scripts\thesis_dashboard.py"

if (-not (Test-Path $script)) {
    Write-Host "Not found: $script - is AgentBrain installed?" -ForegroundColor Red
    exit 1
}

$py = Join-Path $brain ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }

& $py $script $Command --project-root . @Rest
exit $LASTEXITCODE
