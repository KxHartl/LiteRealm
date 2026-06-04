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
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

if ($script:fail) { Write-Host "BOOTSTRAP TEST (PS): FAILED" -ForegroundColor Red }
else { Write-Host "BOOTSTRAP TEST (PS): PASSED" -ForegroundColor Green }
exit $script:fail
