# --- PASTE YOUR LINKS HERE ---
$ModLinks = @(
    "https://cdn.modrinth.com/data/oWaK0Q19/versions/YhZLrAFC/create-aeronautics-bundled-1.21.1-1.2.1.jar"
    "https://cdn.modrinth.com/data/T9PomCSv/versions/3FMsUjO4/sable-neoforge-1.21.1-1.2.2.jar"
    "https://cdn.modrinth.com/data/LNytGWDc/versions/UjX6dr61/create-1.21.1-6.0.10.jar"
    "https://cdn.modrinth.com/data/UT2M39wf/versions/kecZ0sl7/copycats-3.0.4%2Bmc.1.21.1-neoforge.jar"
    "https://cdn.modrinth.com/data/GWp4jCJj/versions/bsGaXKEd/createbigcannons-5.11.3%2Bmc.1.21.1.jar"
    "https://cdn.modrinth.com/data/B3pb093D/versions/hZ6B2Z0x/ritchiesprojectilelib-2.1.2%2Bmc.1.21.1-neoforge.jar"
    "https://cdn.modrinth.com/data/Vg5TIO6d/versions/ffuMPkho/create_connected-1.1.14-mc1.21.1.jar"
    "https://cdn.modrinth.com/data/r4Knci2k/versions/gBrfZy6S/interiors-1.21.1-neoforge-0.6.1.jar"
    "https://cdn.modrinth.com/data/ZM3tt6p1/versions/uxgzKkcD/createdieselgenerators-1.21.1-1.3.11.jar"
    "https://cdn.modrinth.com/data/15fFZ3f4/versions/1BtGyIVR/createframed-1.21.1-1.7.3.jar"
    "https://cdn.modrinth.com/data/wPQ6GgFE/versions/MX6Eqw1t/create_power_loader-2.0.4-mc1.21.1.jar"
    "https://cdn.modrinth.com/data/gOPAFzp0/versions/XrNWi3Wo/createcontraptionterminals-1.21-1.3.0.jar"
    "https://cdn.modrinth.com/data/XZNI4Cpy/versions/x8jcBWWG/toms_storage-1.21-2.3.2.jar"
    "https://cdn.modrinth.com/data/u6dRKJwZ/versions/YAcQ6elZ/jei-1.21.1-neoforge-19.27.0.340.jar"
    "https://cdn.modrinth.com/data/T8bvmqVZ/versions/XKDQlGJW/bits_n_bobs-0.0.44.jar"
    # Add more links here, one per line
)

# --- CHOOSE YOUR FOLDER ---
$SavePath = "$env:USERPROFILE\Desktop\1.21.1_Mods"

if (!(Test-Path $SavePath)) { New-Item -Path $SavePath -ItemType Directory }

foreach ($Url in $ModLinks) {
    try {
        # Extracts the filename and converts %2B back into +
        $CleanName = [uri]::UnescapeDataString(($Url -split '/')[-1])
        $FullDestination = Join-Path $SavePath $CleanName

        Write-Host "Downloading $CleanName..." -ForegroundColor Cyan -NoNewline
        
        Invoke-WebRequest -Uri $Url -OutFile $FullDestination
        
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Warning "Could not download $Url"
    }
}

Write-Host "`nFinished! Mods are in $SavePath" -ForegroundColor Yellow
pause
