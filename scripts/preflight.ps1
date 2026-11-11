param (
    [string[]]$FilePath
)

$ErrorActionPreference = "Stop"

if (-not $FilePath -or $FilePath.Count -eq 0) {
    $changed = git status --porcelain -- src/ | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^[MARC\?\!]{1,2}\s+(.+)$') {
            $p = $Matches[1] -replace '^"|"$', ''
            if ($p -match ' -> (.+)$') { $p = $Matches[1] -replace '^"|"$', '' }
            $p
        }
    } | Where-Object {
        $_ -and ($_ -like '*.luau') -and ($_ -notlike '*TeslaRoadster_Day1*') -and (Test-Path $_)
    }
    $FilePath = @($changed | Select-Object -Unique)
}

if (-not $FilePath -or $FilePath.Count -eq 0) {
    Write-Host "[SKIP] No modified .luau targets to validate." -ForegroundColor Gray
    exit 0
}

Write-Host "[1/3] Running StyLua AST Check on $($FilePath.Count) file(s)..." -ForegroundColor Cyan
stylua --check @FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] StyLua check failed."
    exit 1
}

Write-Host "[2/3] Running Selene (Roblox Std)..." -ForegroundColor Cyan
selene @FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Selene linter failed."
    exit 1
}

if (-not (Test-Path "sourcemap.json") -or ((Get-Item "default.project.json").LastWriteTimeUtc -gt (Get-Item "sourcemap.json").LastWriteTimeUtc)) {
    Write-Host "[LSP] Regenerating sourcemap.json..." -ForegroundColor DarkCyan
    rojo sourcemap default.project.json -o sourcemap.json | Out-Null
}

Write-Host "[3/3] Running Luau-LSP Analyze..." -ForegroundColor Cyan
luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json @FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Luau-LSP analyze reported diagnostics."
    exit 1
}

Write-Host "[DONE] Pre-Flight Verification Passed!" -ForegroundColor Green
