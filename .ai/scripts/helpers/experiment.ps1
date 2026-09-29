<#
.SYNOPSIS
    Run AgentBrain Experiment & Research Data Manager without typing brain path.
.EXAMPLE
    .\.ai\scripts\helpers\experiment.ps1 new --type exp --name "motor-torque" --desc "Step response"
    .\.ai\scripts\helpers\experiment.ps1 process --raw "2026-08-20_143000_exp_motor-torque"
    .\.ai\scripts\helpers\experiment.ps1 list
    .\.ai\scripts\helpers\experiment.ps1 audit
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet("new", "process", "list", "audit")][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$brain = if ($env:AGENTBRAIN_PATH) { $env:AGENTBRAIN_PATH } else { Join-Path $env:USERPROFILE ".agentbrain" }
$script = Join-Path $brain "scripts\data\experiment_manager.py"

if (-not (Test-Path $script)) {
    Write-Host "Not found: $script - is AgentBrain installed?" -ForegroundColor Red
    exit 1
}

$py = Join-Path $brain ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }

& $py $script $Command --project-root . @Rest
exit $LASTEXITCODE
