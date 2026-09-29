<#
.SYNOPSIS
    One-shot checkpoint commit (rule 1: proactive git).
    Stages everything and commits in the user's name by default.
.DESCRIPTION
    The AI marker is NOT added by default. Per AGENTS.md rule 1.1 it means an AI
    agent did the work in that commit. If the user did the work - or gave the
    direction and the decision while the agent carried it out - the commit is
    theirs: omit -Ai.

    The git history is the record of AI use, so the marker must be accurate.
.EXAMPLE
    .\.ai\scripts\helpers\checkpoint.ps1 "feat: add uvod chapter"
    .\.ai\scripts\helpers\checkpoint.ps1 -Ai "chore: refresh standards register"
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Message,
    [switch]$Ai
)

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

if (-not (git -C $root status --porcelain)) {
    Write-Host "Nothing to commit - working tree clean." -ForegroundColor Gray
    exit 0
}

$body = $Message

if ($Ai) {
    # ASCII-only source file: build the robot emoji from its code point.
    $marker = [char]::ConvertFromUtf32(0x1F916) + " [AI]"

    if ($Message -notmatch '\[AI\]') {
        if ($Message -match '^[a-z]+(\([^)]+\))?!?:\s*(.+)$') {
            # Conventional commit: insert the marker after "type(scope):".
            $body = $Message -replace '^([a-z]+(\([^)]+\))?!?:)\s*', "`$1 $marker "
        } else {
            $body = "chore: $marker $Message"
        }
    }
    $body = $body + "`n`nCo-Authored-By: Claude <noreply@anthropic.com>"
} elseif ($Message -match '\[AI\]') {
    Write-Host "Refusing: message carries the AI marker but -Ai was not passed." -ForegroundColor Red
    Write-Host "See AGENTS.md rule 1.1 - use it only when an agent did the work." -ForegroundColor Red
    exit 1
}

git -C $root add -A
git -C $root commit -m $body
exit $LASTEXITCODE
