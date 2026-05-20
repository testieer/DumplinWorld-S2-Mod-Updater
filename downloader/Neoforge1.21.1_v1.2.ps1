# --- CONFIGURATION ---
# Replace 'YourName/YourRepo' with your actual GitHub path
$RemoteDownloaderVerUrl = "https://raw.githubusercontent.com/testieer/DumplinWorld-S2-Mod-Updater/refs/heads/main/version.txt"
$DownloaderUpdateUrl    = "https://github.com/testieer/DumplinWorld-S2-Mod-Updater/releases"
$RemoteModsUrl          = "https://raw.githubusercontent.com/testieer/DumplinWorld-S2-Mod-Updater/refs/heads/main/mods.txt"

$CurrentScriptVersion = "1.2" 
$Destination = "$env:USERPROFILE\Desktop\1.21.1_NeoMods"
$HistoryFile = Join-Path $Destination "Mod History\mod_history.txt"

# 1. PRE-FLIGHT CHECKS
if (!(Test-Path $Destination)) { 
    New-Item -Path $Destination -ItemType Directory | Out-Null 
}
# 1. Define the sub-folder pathing
$HistoryFolder = Join-Path $Destination "Mod History"
$HistoryFile   = Join-Path $HistoryFolder "mod_history.txt"

# 2. Ensure the sub-folder exists so the script doesn't crash
if (!(Test-Path $HistoryFolder)) { 
    New-Item -Path $HistoryFolder -ItemType Directory | Out-Null 
}

# 3. THE ACTUAL CHECK: Load the history into a Lookup Table (Hash Table)
$LocalHistory = @{}
if (Test-Path $HistoryFile) {
    Get-Content $HistoryFile | ForEach-Object {
        $hParts = $_ -split ","
        if ($hParts.Count -eq 2) { 
            # Stores ModName as the Key and Version as the Value
            $LocalHistory[$hParts[0].Trim()] = $hParts[1].Trim() 
        }
    }
}
try {
    # 2. SCRIPT VERSION CHECK
    Write-Host "Checking for downloader updates..." -ForegroundColor Gray
    $LatestScriptVer = (Invoke-WebRequest -Uri $RemoteDownloaderVerUrl -UseBasicParsing).Content.Trim()
    if ($LatestScriptVer -ne $CurrentScriptVersion) {
        Write-Host " [!] SCRIPT OUTDATED (Latest: v$LatestScriptVer) -> $DownloaderUpdateUrl" -ForegroundColor Yellow
        Write-Host " ----------------------------------------------------------------"
    }

    # 3. LOAD LOCAL HISTORY (The "Memory")
    $LocalHistory = @{}
    if (Test-Path $HistoryFile) {
        Get-Content $HistoryFile | ForEach-Object {
            $hParts = $_ -split ","
            if ($hParts.Count -eq 2) { $LocalHistory[$hParts[0].Trim()] = $hParts[1].Trim() }
        }
    }

    # 4. FETCH REMOTE MANIFEST
    Write-Host "Fetching manifest from GitHub..." -ForegroundColor Cyan
    $Manifest = (Invoke-WebRequest -Uri $RemoteModsUrl -UseBasicParsing).Content -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    $AllowedFiles = @()   # Whitelist for the cleaner
    $NewHistoryLines = @() # To save at the end
    $DownloadQueue = @()  # List of mods that actually need updating

    foreach ($Line in $Manifest) {
        $Parts = $Line -split ","
        if ($Parts.Count -lt 3) { continue }

        $ModName = $Parts[0].Trim()
        $ModVer  = $Parts[1].Trim()
        $Url     = $Parts[2].Trim()

        # Fix/Unescape filename
        $FileName = [uri]::UnescapeDataString(($Url -split '/')[-1].Split('?')[0])
        $TargetPath = Join-Path $Destination $FileName
        
        $AllowedFiles += $FileName
        $NewHistoryLines += "$ModName,$ModVer"

        # --- THE SMART COMPARISON ---
        $NeedsUpdate = $false
        
        # Condition A: The file simply doesn't exist
        if (!(Test-Path $TargetPath)) { 
            $NeedsUpdate = $true 
        }
        # Condition B: The version in local history doesn't match the manifest
        elseif ($LocalHistory.ContainsKey($ModName) -and $LocalHistory[$ModName] -ne $ModVer) { 
            $NeedsUpdate = $true 
        }

        if ($NeedsUpdate) {
            $DownloadQueue += @{ Name = $ModName; Ver = $ModVer; Url = $Url; Target = $TargetPath }
        } else {
            Write-Host " [Verified] $ModName (v$ModVer)" -ForegroundColor Gray
        }
    }

    # 5. DOWNLOAD EXECUTION
    if ($DownloadQueue.Count -gt 0) {
        Write-Host "`nUpdating $($DownloadQueue.Count) mod(s)..." -ForegroundColor Yellow
        foreach ($Task in $DownloadQueue) {
            Write-Host " -> Downloading: $($Task.Name) (New Ver: $($Task.Ver))" -ForegroundColor Yellow
            Invoke-WebRequest -Uri $Task.Url -OutFile $Task.Target
            Write-Host "    Done!" -ForegroundColor Green
        }
    } else {
        Write-Host "`nNo version changes detected." -ForegroundColor Green
    }

    # 6. HISTORY UPDATE & CLEANER
    # We save the history BEFORE the cleaner so it's an accurate plan
    $NewHistoryLines | Out-File -FilePath $HistoryFile -Force

    $LocalFiles = Get-ChildItem -Path $Destination -Filter "*.jar"
    foreach ($File in $LocalFiles) {
        if ($AllowedFiles -notcontains $File.Name) {
            Write-Host " [Purge] Removing old/unlisted: $($File.Name)" -ForegroundColor Red
            Remove-Item $File.FullName -Force
        }
    }

    Write-Host "`nSync Complete. Mod folder is 1:1 with GitHub." -ForegroundColor DarkGreen

} catch {
    Write-Host "`n[Critical Error] $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")