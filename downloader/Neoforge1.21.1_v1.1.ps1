# --- CONFIGURATION ---
$RemoteDownloaderVerUrl = "https://raw.githubusercontent.com/testieer/DumplinWorld-S2-Mod-Updater/refs/heads/main/version.txt"
$DownloaderUpdateUrl    = "https://github.com/testieer/DumplinWorld-S2-Mod-Updater/releases"
$RemoteModsUrl          = "https://raw.githubusercontent.com/testieer/DumplinWorld-S2-Mod-Updater/refs/heads/main/mods.txt"

$CurrentScriptVersion = "1.1" 
$Destination = "$env:USERPROFILE\Desktop\1.21.1_NeoMods"
$HistoryFile = Join-Path $Destination "mod_history.txt"

if (!(Test-Path $Destination)) { New-Item -Path $Destination -ItemType Directory | Out-Null }

try {
    # 1. VERSION CHECK (Downloader Update)
    Write-Host "Checking for script updates..." -ForegroundColor Gray
    $LatestScriptVer = (Invoke-WebRequest -Uri $RemoteDownloaderVerUrl -UseBasicParsing).Content.Trim()
    if ($LatestScriptVer -ne $CurrentScriptVersion) {
        Write-Host " [!] SCRIPT OUTDATED -> $DownloaderUpdateUrl`n" -ForegroundColor Yellow
    }

    # 2. THE "PLANNING" STAGE (Copying mods.txt logic first)
    Write-Host "Creating mod_history.txt!" -ForegroundColor Cyan
    $Manifest = (Invoke-WebRequest -Uri $RemoteModsUrl -UseBasicParsing).Content -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    $AllowedFiles = @()   # Names for the Cleaner
    $HistoryLines = @()   # Data for the mod_history.txt
    $DownloadQueue = @()  # Tasks for the Downloader

    foreach ($Line in $Manifest) {
        $Parts = $Line -split ","
        if ($Parts.Count -lt 3) { continue }

        $ModName = $Parts[0].Trim()
        $ModVer  = $Parts[1].Trim()
        $Url     = $Parts[2].Trim()

        # Fix names (unescape %2B, etc)
        $FileName = [uri]::UnescapeDataString(($Url -split '/')[-1].Split('?')[0])
        $TargetPath = Join-Path $Destination $FileName
        
        $AllowedFiles += $FileName
        $HistoryLines += "$ModName,$ModVer"

        # If we don't have it, add it to the to-do list
        if (!(Test-Path $TargetPath)) {
            $DownloadQueue += @{ Name = $ModName; Ver = $ModVer; Url = $Url; Target = $TargetPath }
        }
    }

    # --- SAVE THE ACCURATE REPRESENTATION IMMEDIATELY ---
    $HistoryLines | Out-File -FilePath $HistoryFile -Force
    Write-Host "Local mod_history.txt updated with the latest manifest targets." -ForegroundColor DarkGray

    # 3. THE EXECUTION STAGE (Downloads)
    if ($DownloadQueue.Count -gt 0) {
        Write-Host "`nStarting downloads ($($DownloadQueue.Count) total)..." -ForegroundColor Yellow
        foreach ($Task in $DownloadQueue) {
            Write-Host "Downloading: $($Task.Name) (v$($Task.Ver))..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $Task.Url -OutFile $Task.Target
            Write-Host "  -> Finished!" -ForegroundColor Green
        }
    } else {
        Write-Host "`nAll mods already present. No downloads needed." -ForegroundColor Green
    }

    # 4. THE CLEANER (Using the plan to delete extras)
    $LocalFiles = Get-ChildItem -Path $Destination -Filter "*.jar"
    foreach ($File in $LocalFiles) {
        if ($AllowedFiles -notcontains $File.Name) {
            Write-Host "Deleting unlisted mod: $($File.Name)" -ForegroundColor Red
            Remove-Item $File.FullName -Force
        }
    }

    Write-Host "`nSync Complete. Folder is 1:1 with GitHub." -ForegroundColor DarkGreen

} catch {
    Write-Host "`nCritical Error: $_" -ForegroundColor Red
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")