#Requires -Version 5.1
<#
  setup.ps1

  Installs MultiMessageCopy into a Vencord source tree, builds Vencord, and injects it into Discord.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PLUGIN_NAME    = "MultiMessageCopy"
$PLUGIN_REPO    = "https://github.com/tsx-awtns/MultiMessageCopy.git"
$PLUGIN_ZIP_URL = "https://github.com/tsx-awtns/MultiMessageCopy/archive/refs/heads/main.zip"
$VENCORD_REPO   = "https://github.com/Vendicated/Vencord.git"
$VERSION_URL    = "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/refs/heads/main/version.json"
$PLUGIN_SUBPATH = "src\userplugins\$PLUGIN_NAME"
$CONFIG_FILE    = Join-Path $env:APPDATA "MultiMessageCopy\mmc-config.json"
$TEMP_BASE      = Join-Path $env:TEMP "mmc_setup_$([System.IO.Path]::GetRandomFileName())"

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
    Write-Progress -Activity "MultiMessageCopy Setup" -Status $Name `
        -PercentComplete ([Math]::Round(($script:CurrentStage / $script:TotalStages) * 100))
}

function Complete-Stage {
    param([string]$Name = "")
    if ($Name) { Write-Success $Name }
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
    Write-Progress -Activity "MultiMessageCopy Setup" -Completed
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

function Test-WingetExists {
    return [bool](Get-Command "winget" -ErrorAction SilentlyContinue)
}

function Install-Or-Guide-Git {
    if (Test-CommandExists "git") {
        $v = & git --version 2>&1
        Write-Success "Git found: $v"
        return
    }
    Write-Fail "Git is not installed or not on PATH."
    Write-Info  "Git is required to clone MultiMessageCopy and Vencord."
    if (Test-WingetExists) {
        if (Ask-YesNo "Install Git automatically via winget?") {
            Run-Command "winget install --id Git.Git -e" { winget install --id Git.Git -e }
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if (Test-CommandExists "git") {
                Write-Success "Git installed successfully."
                return
            }
        }
    }
    Write-Info "Please install Git manually from https://git-scm.com"
    Write-Info "Then re-run this script."
    if (Ask-YesNo "Open the Git download page now?" $false) {
        Start-Process "https://git-scm.com/downloads"
    }
    Exit-Fatal "Git is required. Please install it and re-run setup.ps1."
}

function Install-Or-Guide-Node {
    if (Test-CommandExists "node") {
        $v     = & node --version 2>&1
        $major = [int]($v -replace 'v', '').Split('.')[0]
        if ($major -lt 18) {
            Exit-Fatal "Node.js $v is too old -- v18 or newer is required." `
                "Download the latest LTS from https://nodejs.org"
        }
        Write-Success "Node.js found: $v"
        return
    }
    Write-Fail "Node.js is not installed."
    Write-Info  "Node.js 18 LTS or newer is required."
    if (Test-WingetExists) {
        if (Ask-YesNo "Install Node.js LTS automatically via winget?") {
            Run-Command "winget install --id OpenJS.NodeJS.LTS -e" { winget install --id OpenJS.NodeJS.LTS -e }
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if (Test-CommandExists "node") {
                Write-Success "Node.js installed successfully."
                return
            }
        }
    }
    Write-Info "Please install Node.js from https://nodejs.org (LTS recommended)."
    if (Ask-YesNo "Open the Node.js download page now?" $false) {
        Start-Process "https://nodejs.org/en/download/"
    }
    Exit-Fatal "Node.js is required. Please install it and re-run setup.ps1."
}

function Install-Or-Guide-Pnpm {
    if (Test-CommandExists "pnpm") {
        $v = & pnpm --version 2>&1
        Write-Success "pnpm found: $v"
        return
    }
    Write-Fail "pnpm is not installed."
    if (-not (Test-CommandExists "npm")) {
        Exit-Fatal "npm (from Node.js) is also missing. Please install Node.js first." `
            "Download from https://nodejs.org"
    }
    Write-Info "pnpm can be installed via npm."
    if (Ask-YesNo "Install pnpm globally now via npm?") {
        Run-Command "npm install -g pnpm" { npm install -g pnpm }
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if (Test-CommandExists "pnpm") {
            Write-Success "pnpm installed successfully."
            return
        }
        Exit-Fatal "pnpm installation failed." "Run manually: npm install -g pnpm"
    }
    Exit-Fatal "pnpm is required. Run 'npm install -g pnpm' then re-run setup.ps1."
}

function Test-VencordFolder {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $p = $Path.TrimEnd('\', '/')
    return ((Test-Path (Join-Path $p "package.json")) -and (Test-Path (Join-Path $p "src")))
}

function Find-VencordFolder {
    $candidates = @(
        (Join-Path $env:USERPROFILE "Vencord"),
        (Join-Path $env:USERPROFILE "Documents\Vencord"),
        (Join-Path $env:USERPROFILE "Desktop\Vencord"),
        (Join-Path $env:LOCALAPPDATA "Vencord"),
        "C:\Vencord"
    )
    foreach ($c in $candidates) {
        if (Test-VencordFolder $c) { return $c }
    }
    return $null
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
        Write-Info "Created directory: $Path"
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

function Install-Or-Clone-Vencord {
    Write-Warn "No Vencord source folder was found on this machine."
    Write-Info "MultiMessageCopy requires a Vencord source install (not the Vencord Desktop app)."
    Write-Info "Vencord source: $VENCORD_REPO"
    Write-Host ""
    if (-not (Ask-YesNo "Clone and set up Vencord source automatically?")) {
        Exit-Fatal "Vencord source is required." `
            "Clone it manually: git clone $VENCORD_REPO"
    }
    $parentRaw = Read-Host "  Enter the folder where Vencord should be created (e.g. C:\Users\You\Projects)"
    $parentDir = $parentRaw.Trim('"').Trim("'").TrimEnd('\', '/')
    if (-not (Test-Path $parentDir)) {
        Exit-Fatal "The folder '$parentDir' does not exist." "Create it first and re-run setup."
    }
    $vencordDest = Join-Path $parentDir "Vencord"
    Write-Info "Cloning Vencord into: $vencordDest"
    Run-Command "git clone Vencord" { & git clone "$VENCORD_REPO" "$vencordDest" }
    Push-Location $vencordDest
    try {
        Run-Command "pnpm install" { & pnpm install }
    }
    finally {
        Pop-Location
    }
    Write-Success "Vencord cloned and dependencies installed."
    return $vencordDest
}

function Save-Config {
    param([string]$VencordPath, [string]$InstalledVersion = "")
    Ensure-Directory (Split-Path $CONFIG_FILE -Parent)
    $cfg = [ordered]@{ vencordPath = $VencordPath }
    if (-not [string]::IsNullOrWhiteSpace($InstalledVersion)) {
        $cfg["installedVersion"] = $InstalledVersion
    }
    $cfg | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Encoding UTF8
    Write-Success "Config saved: $CONFIG_FILE"
}

function Copy-PluginFiles {
    param([string]$Source, [string]$Dest)
    Ensure-Directory $Dest
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
        return $json.version
    }
    catch {
        return $null
    }
}

Clear-Host
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Cyan
Write-Host "  MultiMessageCopy  --  Installer" -ForegroundColor Cyan
Write-Host "  Unofficial Vencord UserPlugin" -ForegroundColor DarkGray
Write-Host "  https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor DarkGray
Write-Host ("=" * 62) -ForegroundColor Cyan

Start-Stage "Checking requirements"
Install-Or-Guide-Git
Install-Or-Guide-Node
Install-Or-Guide-Pnpm
Complete-Stage "All requirements satisfied."

Start-Stage "Fetching version information"
$remoteVer = Get-RemoteVersion
if ($remoteVer) {
    Write-Info "Latest version : $remoteVer"
    Write-Info "Source         : $PLUGIN_ZIP_URL"
}
else {
    Write-Warn "Could not fetch version info. Continuing with main branch."
}

Start-Stage "Locating Vencord source folder"
$vencordPath = $null

$autoFound = Find-VencordFolder
if ($autoFound) {
    Write-Success "Detected Vencord at: $autoFound"
    if (Ask-YesNo "Use this path?") {
        $vencordPath = $autoFound
    }
}

if (-not $vencordPath) {
    Write-Info "Common paths checked: ~/Vencord, ~/Documents/Vencord, ~/Desktop/Vencord, C:\Vencord"
    $raw = Read-Host "  Enter full path to your Vencord source folder (or leave blank to clone Vencord)"
    $raw = $raw.Trim('"').Trim("'").TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $vencordPath = Install-Or-Clone-Vencord
    }
    elseif (Test-VencordFolder $raw) {
        $vencordPath = $raw
    }
    else {
        Write-Warn "That path does not look like a Vencord source folder."
        $vencordPath = Install-Or-Clone-Vencord
    }
}

Assert-VencordPath $vencordPath
Complete-Stage "Vencord folder: $vencordPath"

Start-Stage "Preparing plugin folder"
$pluginsDir = Join-Path $vencordPath "src\userplugins"
$pluginDest = Join-Path $pluginsDir $PLUGIN_NAME
Assert-PluginPath $pluginDest
Ensure-Directory $pluginsDir

if (Test-Path $pluginDest) {
    Write-Info "Existing installation found at:"
    Write-Info "  $pluginDest"
    if (-not (Ask-YesNo "Replace it with a fresh install?")) {
        Exit-Fatal "Installation cancelled by user."
    }
    Write-Info "Removing old installation..."
    Remove-Item -Recurse -Force -Path $pluginDest
    Write-Success "Old installation removed."
}
Complete-Stage "Plugin folder ready."

Start-Stage "Downloading MultiMessageCopy"
Ensure-Directory $TEMP_BASE

$zipPath     = Join-Path $TEMP_BASE "mmc.zip"
$extractPath = Join-Path $TEMP_BASE "extracted"

Write-Info "Downloading from GitHub..."
Write-Cmd  "Invoke-WebRequest -Uri `"$PLUGIN_ZIP_URL`" -OutFile `"$zipPath`""
try {
    Invoke-WebRequest -Uri $PLUGIN_ZIP_URL -OutFile $zipPath -UseBasicParsing
}
catch {
    Exit-Fatal "Download failed: $_" "Check your internet connection and try again."
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
Complete-Stage "Download complete."

Start-Stage "Copying runtime plugin files"
Write-Info "Copying to: $pluginDest"
Write-Info "Files: $($RUNTIME_FILES -join ', ')"
Write-Info "Skipping: setup.ps1, update.ps1, uninstall.ps1, version.json, .git, .github"
Copy-PluginFiles -Source $inner -Dest $pluginDest
Write-InstalledVersionFile -PluginDest $pluginDest -Version $remoteVer
Remove-Item -Recurse -Force -Path $TEMP_BASE -ErrorAction SilentlyContinue
Complete-Stage "Runtime files installed."

Start-Stage "Checking Vencord dependencies"
$nodeModules = Join-Path $vencordPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Warn "node_modules not found -- running pnpm install..."
    Push-Location $vencordPath
    try {
        Run-Command "pnpm install" { & pnpm install }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Success "node_modules already present -- skipping pnpm install."
}

Start-Stage "Building Vencord"
Write-Info "Running pnpm build in: $vencordPath"
Write-Progress -Activity "MultiMessageCopy Setup" -Completed
$prevPrefBuild = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
Push-Location $vencordPath
try {
    Run-Command "pnpm build" { & pnpm build }
}
finally {
    Pop-Location
    $ProgressPreference = $prevPrefBuild
}
Complete-Stage "Build successful."

Start-Stage "Injecting Vencord into Discord"
Write-Info "This patches the Discord app to load Vencord."
Write-Cmd  "pnpm inject"
$prevPrefInject = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
Push-Location $vencordPath
try {
    & pnpm inject 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "pnpm inject returned exit code $LASTEXITCODE."
        Write-Info "You may need to run 'pnpm inject' manually from the Vencord folder."
    }
    else {
        Write-Success "Injection complete."
    }
}
finally {
    Pop-Location
    $ProgressPreference = $prevPrefInject
}

Save-Config -VencordPath $vencordPath -InstalledVersion ($remoteVer ?? "")
Write-Progress -Activity "MultiMessageCopy Setup" -Completed

Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host "  MultiMessageCopy installation completed" -ForegroundColor Green
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host ""
Write-Host "  Plugin folder:" -ForegroundColor White
Write-Host "    $pluginDest" -ForegroundColor Gray
Write-Host ""
Write-Host "  Vencord folder:" -ForegroundColor White
Write-Host "    $vencordPath" -ForegroundColor Gray
if ($remoteVer) {
    Write-Host ""
    Write-Host "  Version installed: $remoteVer" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Restart Discord completely (close from system tray first)." -ForegroundColor Gray
Write-Host "    2. Open User Settings > Vencord > Plugins." -ForegroundColor Gray
Write-Host "    3. Search for 'MultiMessageCopy' and enable it." -ForegroundColor Gray
Write-Host ""
Write-Host "  To update later, run:" -ForegroundColor White
Write-Host "    powershell -ExecutionPolicy Bypass -File .\update.ps1" -ForegroundColor DarkCyan
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Green
Write-Host ""
