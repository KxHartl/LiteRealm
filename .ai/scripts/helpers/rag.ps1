<#
.SYNOPSIS
    Run AgentBrain RAG / citation scripts without typing the brain path
    (and without PowerShell's ~-doesn't-expand-in-arguments pitfall).
.EXAMPLE
    .\.ai\scripts\helpers\rag.ps1 ingest
    .\.ai\scripts\helpers\rag.ps1 query "your question"
    .\.ai\scripts\helpers\rag.ps1 cite --doi "10.xxxx/yyyy"
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet("ingest", "query", "cite")][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$brain = if ($env:AGENTBRAIN_PATH) { $env:AGENTBRAIN_PATH } else { Join-Path $env:USERPROFILE ".agentbrain" }
$script = switch ($Command) {
    "ingest" { Join-Path $brain "scripts\rag\ingest.py" }
    "query"  { Join-Path $brain "scripts\rag\query.py" }
    "cite"   { Join-Path $brain "scripts\add_citation.py" }
}

if (-not (Test-Path $script)) {
    Write-Host "Not found: $script - is AgentBrain installed?" -ForegroundColor Red
    exit 1
}

python $script @Rest
exit $LASTEXITCODE
