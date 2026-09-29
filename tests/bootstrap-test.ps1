<#
.SYNOPSIS
    Bootstrap smoke test (PowerShell): run bootstrap.ps1 in an isolated copy and
    assert the result. Deterministic (-Brain none, no network).
#>
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$script:fail = 0

function Assert([string]$name, [bool]$cond) {
    if ($cond) { Write-Host "  OK:   $name" }
    else { Write-Host "  FAIL: $name" -ForegroundColor Red; $script:fail = 1 }
}

function New-Skeleton([string]$dst) {
    Copy-Item "$repo\.ai" "$dst\.ai" -Recurse
    Remove-Item "$dst\.ai\.bootstrapped" -ErrorAction SilentlyContinue
    foreach ($f in @("STATE.md", "VERSION", ".env.example")) {
        if (Test-Path "$repo\$f") { Copy-Item "$repo\$f" $dst }
    }
    git -C $dst init -q
    git -C $dst config user.email t@example.com
    git -C $dst config user.name tester
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("bt_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    New-Skeleton $tmp
    Push-Location $tmp
    & "$tmp\.ai\scripts\bootstrap.ps1" -Name "Boot_Win" -Brain none *> $null
    Pop-Location

    Assert "marker created"            (Test-Path "$tmp\.ai\.bootstrapped")
    Assert "docs/ created"             (Test-Path "$tmp\docs")
    Assert "data/sources/ created"     (Test-Path "$tmp\data\sources")
    Assert "pre-commit hook installed" (Test-Path "$tmp\.git\hooks\pre-commit")
    Assert "name written to yaml"      ([bool](Select-String -Path "$tmp\.ai\config\project.yaml" -Pattern "Boot_Win" -Quiet))
    Assert "marker has brain=unknown"  ([bool](Select-String -Path "$tmp\.ai\.bootstrapped" -Pattern "brain=unknown" -Quiet))

    # The hook must actually SPAWN and RUN (catches a BOM/CRLF corrupting the shebang).
    Push-Location $tmp
    New-Item -ItemType Directory -Path "$tmp\src" -Force | Out-Null
    "ok" | Set-Content "$tmp\src\ok.txt"
    git add src/ok.txt 2>&1 | Out-Null
    git commit -m "ok" 2>&1 | Out-Null
    $normalOk = ($LASTEXITCODE -eq 0)
    # data/raw/ is append-only: adding is allowed, modifying an existing file is blocked.
    "raw" | Set-Content "$tmp\data\raw\x.txt"
    git add -f data/raw/x.txt 2>&1 | Out-Null
    git commit -m "raw" 2>&1 | Out-Null
    $addOk = ($LASTEXITCODE -eq 0)
    "changed" | Set-Content "$tmp\data\raw\x.txt"
    git add -f data/raw/x.txt 2>&1 | Out-Null
    git commit -m "raw2" 2>&1 | Out-Null
    $blocked = ($LASTEXITCODE -ne 0)
    git reset -q --hard 2>&1 | Out-Null

    # Re-run must succeed and must not duplicate the auto-push block.
    Remove-Item "$tmp\.ai\.bootstrapped" -ErrorAction SilentlyContinue
    & "$tmp\.ai\scripts\bootstrap.ps1" -Auto -Brain none *> $null
    $rerunOk = Test-Path "$tmp\.ai\.bootstrapped"
    Pop-Location
    $postHook = "$tmp\.git\hooks\post-commit"
    $pushCount = if (Test-Path $postHook) { @(Select-String -Path $postHook -Pattern "LiteRealm auto-push").Count } else { 0 }
    $postBytes = if (Test-Path $postHook) { [IO.File]::ReadAllBytes($postHook) } else { @() }
    $noBom = ($postBytes.Count -gt 2) -and -not ($postBytes[0] -eq 0xEF -and $postBytes[1] -eq 0xBB)
    Assert "normal commit succeeds (hook spawns)"   $normalOk
    Assert "hook allows adding a new data/raw file" $addOk
    Assert "hook blocks modifying data/raw"         $blocked
    Assert "bootstrap re-run succeeds"              $rerunOk
    Assert "auto-push hook installed exactly once"  ($pushCount -eq 1)
    Assert "post-commit hook has no BOM"            $noBom
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

if ($script:fail) { Write-Host "BOOTSTRAP TEST (PS): FAILED" -ForegroundColor Red }
else { Write-Host "BOOTSTRAP TEST (PS): PASSED" -ForegroundColor Green }
exit $script:fail
