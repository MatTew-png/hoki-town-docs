# ==============================================================================
# HOKI TOWN - One-Click Git Vault Sync (PowerShell)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host ">>> [HOKI TOWN] Starting Obsidian Vault Git Sync..." -ForegroundColor Cyan

# 1. Pull latest changes
Write-Host ">>> Pulling latest changes from remote..." -ForegroundColor Yellow
git pull --rebase

# 2. Stage all markdown, scripts, canvas, and config files
Write-Host ">>> Staging files..." -ForegroundColor Yellow
git add .

# 3. Check status
$status = git status --porcelain
if ($status) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $commitMsg = "vault backup: $timestamp"
    Write-Host ">>> Committing with message: '$commitMsg'..." -ForegroundColor Green
    git commit -m "$commitMsg"
    
    Write-Host ">>> Pushing to remote..." -ForegroundColor Green
    git push
    Write-Host ">>> [SUCCESS] Obsidian Vault synced successfully!" -ForegroundColor Green
} else {
    Write-Host ">>> [INFO] Working tree is clean. Nothing to sync." -ForegroundColor Gray
}
