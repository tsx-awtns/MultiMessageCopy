#Requires -Version 5.1
<#
  update.ps1

  Downloads the latest MultiMessageCopy, backs up the current install,
  replaces runtime plugin files, and rebuilds Vencord.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PLUGIN_NAME    = "MultiMessageCopy"
$PLUGIN_ZIP_URL = "https://github.com/tsx-awtns/MultiMessageCopy/archive/refs/heads/main.zip"
$VERSION_URL    = "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/refs/heads/main/version.json"
$PLUGIN_SUBPATH = "src\userplugins\$PLUGIN_NAME"
$CONFIG_FILE    = Join-Path $env:APPDATA "MultiMessageCopy\mmc-config.json"
$BACKUP_ROOT    = Join-Path $env:APPDATA "MultiMessageCopy\backups"
$TEMP_BASE      = Join-Path $env:TEMP "mmc_update_$([System.IO.Path]::GetRandomFileName())"

$RUNTIME_FILES  = @("index.tsx", "native.ts", "styles.css", "src", "README.md", "LICENSE")

$script:CurrentStage = 0
$script:TotalStages  = 9

function Start-Stage {
    param([string]$Name)
    $script:CurrentStage++
    $pad = $script:CurrentStage.ToString().PadLeft(2)
    Write-Host ""
    Write-Host "  [$pad/$($script:TotalStages)] $Name" -ForegroundColor Cyan
    Write-Host "  $('-' * 54)" -ForegroundColor DarkGray
    Write-Progress -Activity "MultiMessageCopy Update" -Status $Name `
        -PercentComplete ([Math]::Round(($script:CurrentStage / $script:TotalStages) * 100))
}

function Write-Success { param([string]$m) Write-Host "  [OK]   $m" -ForegroundColor Green  }
function Write-Info    { param([string]$m) Write-Host "  [INFO] $m" -ForegroundColor White  }
function Write-Warn    { param([string]$m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Fail    { param([string]$m) Write-Host "  [ERROR] $m" -ForegroundColor Red   }
function Write-Cmd     { param([string]$m) Write-Host "         > $m" -ForegroundColor DarkGray }

function Exit-Fatal {
    param([string]$Msg, [string]$Hint = "")
    Write-Host ""
    Write-Fail $Msg
    if ($Hint) {
        Write-Host "  $Hint" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Progress -Activity "MultiMessageCopy Update" -Completed
    exit 1
}

function Ask-YesNo {
    param([string]$Question, [bool]$DefaultYes = $true)
    $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host "  $Question $suffix"
    if ($answer -eq '') { return $DefaultYes }
    return $answer -imatch '^y'
}

function Run-Command {
    param([string]$Display, [scriptblock]$Block)
    Write-Cmd $Display
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Block
    }
    finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Command failed (exit $LASTEXITCODE): $Display" `
            "Open the Vencord folder and run the command manually to see full details."
    }
    Write-Success "Done: $Display"
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Assert-Requirements {
    if (-not (Test-CommandExists "git")) {
        Exit-Fatal "Git is not installed or not on PATH." "Download from https://git-scm.com"
    }
    Write-Success "Git    : $(& git --version 2>&1)"

    if (-not (Test-CommandExists "node")) {
        Exit-Fatal "Node.js is not installed." "Download LTS from https://nodejs.org"
    }
    Write-Success "Node   : $(& node --version 2>&1)"

    if (-not (Test-CommandExists "pnpm")) {
        Exit-Fatal "pnpm is not installed." "Run: npm install -g pnpm"
    }
    Write-Success "pnpm   : $(& pnpm --version 2>&1)"
}

function Test-VencordFolder {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $p = $Path.TrimEnd('\', '/')
    return ((Test-Path (Join-Path $p "package.json")) -and (Test-Path (Join-Path $p "src")))
}

function Assert-VencordPath {
    param([string]$Path)
    if (-not (Test-VencordFolder $Path)) {
        Exit-Fatal "The path '$Path' does not look like a valid Vencord source folder." `
            "It must contain package.json and a src/ folder."
    }
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Assert-PluginPath {
    param([string]$PluginPath)
    $norm   = $PluginPath.TrimEnd('\', '/')
    $parent = Split-Path $norm -Parent
    $endsOk   = $norm.EndsWith("src\userplugins\$PLUGIN_NAME",
                    [System.StringComparison]::OrdinalIgnoreCase)
    $parentOk = $parent.EndsWith("src\userplugins",
                    [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $endsOk -or -not $parentOk) {
        Exit-Fatal "Safety check failed: '$PluginPath' is not a safe plugin path. Aborting." `
            "Expected path ending with: src\userplugins\$PLUGIN_NAME"
    }
}

function Get-VencordPath {
    if (Test-Path $CONFIG_FILE) {
        try {
            $cfg = Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
            if (Test-VencordFolder $cfg.vencordPath) {
                Write-Success "Saved Vencord path: $($cfg.vencordPath)"
                return $cfg.vencordPath
            }
            Write-Warn "Saved path '$($cfg.vencordPath)' is no longer valid."
        }
        catch {
            Write-Warn "Could not read config: $CONFIG_FILE"
        }
    }

    Write-Info "No valid saved config found. Please enter your Vencord folder path."
    $valid = $false
    $raw   = ""
    while (-not $valid) {
        $raw = Read-Host "  Full path to your Vencord source folder"
        $raw = $raw.Trim('"').Trim("'").TrimEnd('\', '/')
        if (Test-VencordFolder $raw) {
            $valid = $true
        }
        else {
            Write-Warn "That path does not look like a valid Vencord source folder."
        }
    }

    Ensure-Directory (Split-Path $CONFIG_FILE -Parent)
    @{ vencordPath = $raw; installedVersion = $null } | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Encoding UTF8
    Write-Success "Config saved: $CONFIG_FILE"
    return $raw
}

function Write-InstalledVersionFile {
    param([string]$PluginDest, [string]$Version)
    if ([string]::IsNullOrWhiteSpace($Version)) { return }
    $isoNow = [datetime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $json = [ordered]@{
        name        = $PLUGIN_NAME
        version     = $Version
        installedAt = $isoNow
        source      = "github-main"
        repo        = "https://github.com/tsx-awtns/MultiMessageCopy"
    } | ConvertTo-Json
    $outPath = Join-Path $PluginDest "installed-version.json"
    Set-Content -Path $outPath -Value $json -Encoding UTF8
    Write-Success "installed-version.json written: v$Version"
}

function Get-RemoteVersion {
    try {
        $bustUrl = "${VERSION_URL}?t=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
        $headers = @{
            "Cache-Control" = "no-cache, no-store, must-revalidate"
            "Pragma"        = "no-cache"
        }
        $content = Invoke-WebRequest -Uri $bustUrl -UseBasicParsing -TimeoutSec 8 `
                       -Headers $headers |
                   Select-Object -ExpandProperty Content
        $json = $content | ConvertFrom-Json
        return $json
    }
    catch {
        return $null
    }
}

function Get-LocalVersion {
    param([string]$PluginDest)

    $ivf = Join-Path $PluginDest "installed-version.json"
    if (Test-Path $ivf) {
        try {
            $j = Get-Content $ivf -Raw | ConvertFrom-Json
            if ($j.version) { return $j.version }
        }
        catch {}
    }

    $ucf = Join-Path $PluginDest "src\utils\updateChecker.ts"
    if (Test-Path $ucf) {
        try {
            $lines = Get-Content $ucf
            foreach ($line in $lines) {
                if ($line -match 'PLUGIN_VERSION\s*=\s*"([^"]+)"') {
                    return $Matches[1]
                }
            }
        }
        catch {}
    }

    $vf = Join-Path $PluginDest "version.json"
    if (Test-Path $vf) {
        try {
            $j = Get-Content $vf -Raw | ConvertFrom-Json
            if ($j.version) { return $j.version }
        }
        catch {}
    }

    Write-Info "No installed-version.json found. This is normal for older installs."
    return $null
}

function Backup-PluginFolder {
    param([string]$PluginDest)
    $timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $BACKUP_ROOT "$PLUGIN_NAME-$timestamp"
    $succeeded  = $false
    try {
        Ensure-Directory $BACKUP_ROOT
        Copy-Item -Path $PluginDest -Destination $backupPath -Recurse -Force
        Write-Success "Backup created: $backupPath"
        $succeeded = $true
    }
    catch {
        Write-Warn "Backup failed: $_"
    }

    if (-not $succeeded) {
        if (-not (Ask-YesNo "Continue without a backup?" $false)) {
            Exit-Fatal "Update cancelled -- backup failed and user declined to continue."
        }
        return $null
    }
    return $backupPath
}

function Copy-PluginFiles {
    param([string]$Source, [string]$Dest)
    $copied  = 0
    $skipped = 0
    foreach ($name in $RUNTIME_FILES) {
        $srcPath = Join-Path $Source $name
        if (Test-Path $srcPath) {
            Copy-Item -Path $srcPath -Destination $Dest -Recurse -Force
            Write-Info "  Copied : $name"
            $copied++
        }
        else {
            Write-Warn "  Missing: $name (skipped)"
            $skipped++
        }
    }
    Write-Success "Files copied: $copied  |  Skipped: $skipped"
}

Clear-Host
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Cyan
Write-Host "  MultiMessageCopy  --  Updater" -ForegroundColor Cyan
Write-Host "  Unofficial Vencord UserPlugin" -ForegroundColor DarkGray
Write-Host "  https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor DarkGray
Write-Host ("=" * 62) -ForegroundColor Cyan

Start-Stage "Checking requirements"
Assert-Requirements

Start-Stage "Loading saved configuration"
$vencordPath = Get-VencordPath
Assert-VencordPath $vencordPath
$pluginDest  = Join-Path $vencordPath $PLUGIN_SUBPATH
Assert-PluginPath $pluginDest
Ensure-Directory (Join-Path $vencordPath "src\userplugins")

Start-Stage "Checking version information"
$remoteInfo = Get-RemoteVersion
$localVer   = Get-LocalVersion -PluginDest $pluginDest

if ($localVer) {
    Write-Info "Installed version : $localVer"
}
else {
    Write-Info "Installed version : (unknown)"
}

if ($remoteInfo) {
    Write-Info "Latest version    : $($remoteInfo.version)"
    Write-Info "Source            : $PLUGIN_ZIP_URL"
    if ($localVer -and ($localVer -eq $remoteInfo.version)) {
        Write-Warn "You already have the latest version ($localVer)."
        if (-not (Ask-YesNo "Reinstall anyway?")) {
            Write-Host ""
            Write-Info "Nothing to do. Your plugin is up to date."
            exit 0
        }
    }
}
else {
    Write-Warn "Could not fetch latest version info. Continuing with main branch."
}

Start-Stage "Downloading latest plugin files"
Ensure-Directory $TEMP_BASE

$zipPath     = Join-Path $TEMP_BASE "mmc.zip"
$extractPath = Join-Path $TEMP_BASE "extracted"

Write-Info "Downloading from GitHub..."
Write-Cmd  "Invoke-WebRequest -Uri `"$PLUGIN_ZIP_URL`""
try {
    Invoke-WebRequest -Uri $PLUGIN_ZIP_URL -OutFile $zipPath -UseBasicParsing
}
catch {
    Exit-Fatal "Download failed: $_" "Check your internet connection."
}

Write-Info "Extracting archive..."
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$inner = Join-Path $extractPath "MultiMessageCopy-main"
if (-not (Test-Path $inner)) {
    $subdirs = Get-ChildItem $extractPath -Directory
    if ($subdirs.Count -eq 1) {
        $inner = $subdirs[0].FullName
    }
    else {
        Exit-Fatal "Unexpected ZIP structure -- cannot find plugin source."
    }
}
Write-Success "Download and extraction complete."

Start-Stage "Backing up current installation"
$backupPath = $null
if (Test-Path $pluginDest) {
    $backupPath = Backup-PluginFolder -PluginDest $pluginDest
}
else {
    Write-Info "No existing installation found -- skipping backup."
}

Start-Stage "Replacing runtime plugin files"
Assert-PluginPath $pluginDest

if (Test-Path $pluginDest) {
    Write-Info "Removing old plugin files from: $pluginDest"
    Remove-Item -Recurse -Force -Path $pluginDest
}

Ensure-Directory $pluginDest
Write-Info "Copying to: $pluginDest"
Write-Info "Files: $($RUNTIME_FILES -join ', ')"
Write-Info "Skipping: setup.ps1, update.ps1, uninstall.ps1, version.json, .git, .github"
Copy-PluginFiles -Source $inner -Dest $pluginDest
    if ($remoteInfo -and $remoteInfo.version) {
        Write-InstalledVersionFile -PluginDest $pluginDest -Version $remoteInfo.version
        try {
        $cfgDir = Split-Path $CONFIG_FILE -Parent
        Ensure-Directory $cfgDir
        $cfg = if (Test-Path $CONFIG_FILE) {
            Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
        } else {
            [PSCustomObject]@{ vencordPath = $vencordPath }
        }
        $cfg | Add-Member -NotePropertyName "installedVersion" -NotePropertyValue $remoteInfo.version -Force
        $cfg | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Encoding UTF8
        Write-Info "mmc-config.json updated with installedVersion: $($remoteInfo.version)"
    }
    catch {
        Write-Warn "Could not update mmc-config.json: $_"
    }
}

Remove-Item -Recurse -Force -Path $TEMP_BASE -ErrorAction SilentlyContinue
Write-Success "Plugin files updated."

Start-Stage "Building Vencord"
Write-Info "Running pnpm build in: $vencordPath"
Write-Progress -Activity "MultiMessageCopy Update" -Completed
$prevPref = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

Write-Host ""
Write-Host "  NOTE: Vencord runs multiple esbuild tasks in parallel." -ForegroundColor DarkGray
Write-Host "  Build output below may appear interleaved. This is normal." -ForegroundColor DarkGray
Write-Host "  The exit code at the end is the real success/failure indicator." -ForegroundColor DarkGray
Write-Host ""

Push-Location $vencordPath
try {
    Run-Command "pnpm build" { & pnpm build }
}
finally {
    Pop-Location
    $ProgressPreference = $prevPref
}
Write-Success "Build successful."

Start-Stage "Optional: inject Vencord into Discord"
$injectStatus = "Skipped"
Write-Info "pnpm inject patches Discord to load Vencord."
Write-Info "This is usually only needed if Vencord is not loading after a Discord update."
if (Ask-YesNo "Run pnpm inject now? This is usually only needed if Vencord is not loading." $false) {
    Write-Info "Running pnpm inject..."
    $prevPrefInject = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
    Push-Location $vencordPath
    try {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        Write-Cmd "pnpm inject"
        & pnpm inject 2>&1 | Out-Host
        $injectExit = $LASTEXITCODE
        $ErrorActionPreference = $prev
    }
    finally {
        Pop-Location
        $ProgressPreference = $prevPrefInject
    }
    if ($injectExit -eq 0) {
        Write-Success "Injection complete."
        $injectStatus = "Success"
    }
    else {
        Write-Warn "pnpm inject failed (exit $injectExit)."
        Write-Info "You can run it manually from the Vencord folder:"
        Write-Cmd  "pnpm inject"
        $injectStatus = "Failed"
    }
}
else {
    Write-Info "Skipping inject. Run 'pnpm inject' manually from the Vencord folder if needed."
}

Start-Stage "Finishing up"
Write-Progress -Activity "MultiMessageCopy Update" -Completed

Write-Host ""
if (Ask-YesNo "Restart Discord now to apply the update?" $false) {
    Write-Info "Closing Discord..."
    Get-Process -Name "Discord" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $discordExe = Join-Path $env:LOCALAPPDATA "Discord\Update.exe"
    if (Test-Path $discordExe) {
        Write-Cmd "Start-Process Discord"
        Start-Process $discordExe "--processStart Discord.exe"
        Write-Success "Discord is restarting."
    }
    else {
        Write-Warn "Could not locate Discord automatically. Please restart it manually."
    }
}
else {
    Write-Info "Please restart Discord manually to apply the update."
}

Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host "  MultiMessageCopy update completed" -ForegroundColor Green
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host ""
Write-Host "  Updated from:" -ForegroundColor White
Write-Host "    https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Gray
Write-Host ""
Write-Host "  Plugin folder:" -ForegroundColor White
Write-Host "    $pluginDest" -ForegroundColor Gray
if ($backupPath) {
    Write-Host ""
    Write-Host "  Backup:" -ForegroundColor White
    Write-Host "    $backupPath" -ForegroundColor Gray
}
if ($remoteInfo -and $remoteInfo.version) {
    Write-Host ""
    Write-Host "  Version: $($remoteInfo.version)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  Build:" -ForegroundColor White
Write-Host "    Success" -ForegroundColor Green
Write-Host ""
Write-Host "  Inject:" -ForegroundColor White
$injectColor = switch ($injectStatus) {
    "Success" { "Green"  }
    "Failed"  { "Yellow" }
    default   { "Gray"   }
}
Write-Host "    $injectStatus" -ForegroundColor $injectColor
Write-Host ""
Write-Host "  Next step:" -ForegroundColor White
Write-Host "    Restart Discord to use the latest version." -ForegroundColor Gray
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host ""
