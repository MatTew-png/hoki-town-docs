param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

Write-Host "[1/3] Running StyLua AST Check..." -ForegroundColor Cyan
stylua --check $FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] StyLua check failed on: $FilePath"
    exit 1
}

Write-Host "[2/3] Running Selene (Roblox Std)..." -ForegroundColor Cyan
selene $FilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Selene linter failed on: $FilePath"
    exit 1
}

Write-Host "[3/3] Running Luau-LSP Analyze..." -ForegroundColor Cyan
luau-lsp analyze --definitions=globalTypes.d.luau $FilePath

Write-Host "[DONE] Pre-Flight Verification Finished!" -ForegroundColor Green
