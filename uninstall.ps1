#Requires -Version 5.1
<#
  uninstall.ps1

  Removes MultiMessageCopy from the Vencord source tree and rebuilds Vencord.
  Only deletes src\userplugins\MultiMessageCopy -- nothing else is touched.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PLUGIN_NAME    = "MultiMessageCopy"
$PLUGIN_SUBPATH = "src\userplugins\$PLUGIN_NAME"
$CONFIG_FILE    = Join-Path $env:APPDATA "MultiMessageCopy\mmc-config.json"

function Write-Success { param([string]$m) Write-Host "  [OK]   $m" -ForegroundColor Green  }
function Write-Info    { param([string]$m) Write-Host "  [INFO] $m" -ForegroundColor White  }
function Write-Warn    { param([string]$m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Fail    { param([string]$m) Write-Host "  [ERROR] $m" -ForegroundColor Red   }
function Write-Cmd     { param([string]$m) Write-Host "         > $m" -ForegroundColor DarkGray }

function Exit-Fatal {
    param([string]$Msg, [string]$Hint = "")
    Write-Fail $Msg
    if ($Hint) {
        Write-Host "  $Hint" -ForegroundColor DarkGray
    }
    Write-Host ""
    exit 1
}

function Ask-YesNo {
    param([string]$Question, [bool]$DefaultYes = $false)
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
            "Run the command manually in the Vencord folder to see the full error."
    }
    Write-Success "Done: $Display"
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
        Exit-Fatal "Safety check failed: '$PluginPath' is not a safe path. Aborting." `
            "Expected path ending with: src\userplugins\$PLUGIN_NAME"
    }
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-VencordFolder {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $p = $Path.TrimEnd('\', '/')
    return ((Test-Path (Join-Path $p "package.json")) -and (Test-Path (Join-Path $p "src")))
}

function Get-VencordPath {
    if (Test-Path $CONFIG_FILE) {
        try {
            $cfg = Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
            if (Test-VencordFolder $cfg.vencordPath) {
                Write-Success "Saved Vencord path: $($cfg.vencordPath)"
                return $cfg.vencordPath
            }
        }
        catch {}
    }
    $valid = $false
    $raw   = ""
    while (-not $valid) {
        $raw = Read-Host "  Enter the full path to your Vencord source folder"
        $raw = $raw.Trim('"').Trim("'").TrimEnd('\', '/')
        if (Test-VencordFolder $raw) {
            $valid = $true
        }
        else {
            Write-Warn "Not a valid Vencord folder."
        }
    }
    return $raw
}

Clear-Host
Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Yellow
Write-Host "  MultiMessageCopy  --  Uninstaller" -ForegroundColor Yellow
Write-Host ("=" * 62) -ForegroundColor Yellow
Write-Host ""
Write-Info "This will remove MultiMessageCopy from your Vencord plugins folder."
Write-Info "Only the following folder will be deleted:"
Write-Host ""

$vencordPath = Get-VencordPath
$pluginDest  = Join-Path $vencordPath $PLUGIN_SUBPATH
Assert-PluginPath $pluginDest

Write-Host "    $pluginDest" -ForegroundColor Red
Write-Host ""
Write-Warn "This action cannot be undone (no automatic backup)."
Write-Host ""

if (-not (Ask-YesNo "Are you sure you want to uninstall $PLUGIN_NAME?")) {
    Write-Info "Uninstall cancelled."
    exit 0
}

if (-not (Test-Path $pluginDest)) {
    Write-Warn "Plugin folder not found: $pluginDest"
    Write-Info "Nothing to remove."
}
else {
    Write-Info "Removing: $pluginDest"
    Write-Cmd  "Remove-Item -Recurse -Force `"$pluginDest`""
    Remove-Item -Recurse -Force -Path $pluginDest
    Write-Success "Plugin folder removed."
}

if (Test-CommandExists "pnpm") {
    Write-Host ""
    if (Ask-YesNo "Rebuild Vencord now (removes the plugin from the Discord patch)?") {
        Push-Location $vencordPath
        try {
            Run-Command "pnpm build" { & pnpm build }
            Write-Success "Vencord rebuilt."
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Info "Remember to run 'pnpm build' in your Vencord folder before restarting Discord."
    }
}
else {
    Write-Warn "pnpm not found -- skipping rebuild. Run 'pnpm build' in your Vencord folder manually."
}

Write-Host ""
if (Ask-YesNo "Restart Discord now?") {
    Get-Process -Name "Discord" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $discordExe = Join-Path $env:LOCALAPPDATA "Discord\Update.exe"
    if (Test-Path $discordExe) {
        Start-Process $discordExe "--processStart Discord.exe"
        Write-Success "Discord is restarting."
    }
    else {
        Write-Warn "Could not locate Discord automatically. Please restart it manually."
    }
}
else {
    Write-Info "Please restart Discord to apply the change."
}

Write-Host ""
Write-Host ("=" * 62) -ForegroundColor Yellow
Write-Host "  MultiMessageCopy has been uninstalled." -ForegroundColor Yellow
Write-Host ("=" * 62) -ForegroundColor Yellow
Write-Host ""
