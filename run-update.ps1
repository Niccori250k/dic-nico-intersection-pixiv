# PowerShell script to run the dictionary update process

# Set working directory to the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Function to log messages
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formatted = "[$timestamp] [PowerShell] $message"
    Write-Output $formatted
    try {
        Add-Content -Path "cache/log.txt" -Value $formatted -Encoding UTF8
    } catch {}
}

Write-Log "Starting automatic dictionary raw data update..."

# Git pull
Write-Log "Running git pull..."
git pull
if ($LASTEXITCODE -ne 0) {
    Write-Log "Warning: git pull failed. Proceeding anyway..."
}

# Run scraper
Write-Log "Running python scrape_raw.py..."
python scrape_raw.py
if ($LASTEXITCODE -ne 0) {
    Write-Log "Error: Python scraper failed. Aborting commit/push."
    exit 1
}

# Check git status for changes in raw data files
Write-Log "Checking for changes in raw data files..."
$gitStatus = git status --porcelain cache/nico-raw.txt cache/pixiv-raw.txt cache/nico-special-yomi.txt cache/pixiv-sitemap-cache.txt

if ($gitStatus) {
    Write-Log "Changes detected. Preparing to commit and push..."
    git add cache/nico-raw.txt cache/pixiv-raw.txt cache/nico-special-yomi.txt cache/pixiv-sitemap-cache.txt
    
    $commitMsg = "Update raw dictionary data (auto-crawled)"
    git commit -m $commitMsg
    
    Write-Log "Pushing changes to GitHub..."
    git push
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Successfully pushed updated raw data to GitHub."
    } else {
        Write-Log "Error: git push failed."
        exit 1
    }
} else {
    Write-Log "No changes in raw data. Nothing to push."
}

$completionTime = Get-Date
$completionTimestamp = $completionTime.ToString("yyyy-MM-ddTHH:mm:ss") + $completionTime.ToString("zzz").Replace(":", "")
New-Item -ItemType Directory -Path "cache" -Force | Out-Null
Set-Content -Path "cache/scrape-completed-at.txt" -Value $completionTimestamp -Encoding UTF8

Write-Log "Update process finished."
