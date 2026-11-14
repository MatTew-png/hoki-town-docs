param (
    [string[]]$FilePath
)

$ErrorActionPreference = "Stop"

if (-not $FilePath -or $FilePath.Count -eq 0) {
    $FilePath = @(Get-ChildItem -Path src -Recurse -Filter *.luau | ForEach-Object { $_.FullName })
}

if (-not $FilePath -or $FilePath.Count -eq 0) {
    Write-Host "[SKIP] No .luau targets to validate." -ForegroundColor Gray
    exit 0
}

Write-Host "[1/2] Running StyLua AST Check on $($FilePath.Count) file(s)..." -ForegroundColor Cyan
stylua --check @FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] StyLua check failed."
    exit 1
}

Write-Host "[2/2] Running Selene (Roblox Std)..." -ForegroundColor Cyan
selene @FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Selene linter failed."
    exit 1
}

Write-Host "[DONE] Pre-Flight Verification Passed!" -ForegroundColor Green
