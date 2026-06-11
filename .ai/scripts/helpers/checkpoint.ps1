<#
.SYNOPSIS
    One-shot AI checkpoint commit (LiteRealm rule 1: proactive git).
    Stages everything and commits with the AI marker prefix.
.EXAMPLE
    .\.ai\scripts\helpers\checkpoint.ps1 "feat: add uvod chapter"
    .\.ai\scripts\helpers\checkpoint.ps1 "wip: half-written results section"
#>
param(
    [Parameter(Mandatory = $true)][string]$Message
)

# ASCII-only source file: build the robot emoji from its code point.
$ai = [char]::ConvertFromUtf32(0x1F916) + " [AI]"

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

if (-not (git -C $root status --porcelain)) {
    Write-Host "Nothing to commit - working tree clean." -ForegroundColor Gray
    exit 0
}

if ($Message -notmatch '\[AI\]') {
    if ($Message -match '^[a-z]+(\([^)]+\))?!?:\s*(.+)$') {
        # Conventional commit: insert the marker after "type(scope):".
        $Message = $Message -replace '^([a-z]+(\([^)]+\))?!?:)\s*', "`$1 $ai "
    } else {
        $Message = "chore: $ai $Message"
    }
}

git -C $root add -A
git -C $root commit -m $Message
exit $LASTEXITCODE
