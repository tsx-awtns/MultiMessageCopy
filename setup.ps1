# PowerShell 
# MultiMessageCopy Setup Script v1.0 (Windows)
# Author: mays_024

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall,
    [string]$VencordPath = "",
    [switch]$Help
)

function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error   { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info    { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Step    { param($Message) Write-Host "`n=== $Message ===" -ForegroundColor Magenta }

function Show-Help {
    Write-Host @"
MultiMessageCopy Plugin Automated Setup Script v1.0

USAGE:
    .\setup.ps1 [OPTIONS]

OPTIONS:
    -SkipNodeInstall    Skip Node.js installation check
    -SkipGitInstall     Skip Git installation check  
    -VencordPath        Specify custom Vencord installation path
    -Help               Show this help message

EXAMPLES:
    .\setup.ps1
    .\setup.ps1 -SkipNodeInstall -SkipGitInstall
    .\setup.ps1 -VencordPath "C:\MyVencord"
"@ -ForegroundColor White
}

# [Helper functions are unchanged — include the ones like:]
# Test-Administrator, Test-Command, Test-ValidPath, Find-VencordDirectory,
# Install-NodeJS, Install-Git, Install-Pnpm, Get-VencordPath,
# Install-Vencord, Install-VencordDependencies, Build-Vencord, Inject-Vencord

function Install-MultiMessageCopy {
    param($VencordPath)

    Write-Step "Installing MultiMessageCopy Plugin"

    try {
        $userPluginsPath = Join-Path $VencordPath "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"

        if (Test-Path "$pluginPath\index.tsx") {
            Write-Success "MultiMessageCopy plugin already exists!"
            return
        }

        if (!(Test-Path $userPluginsPath)) {
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null
            Write-Info "Created userplugins directory"
        }

        Write-Info "Cloning MultiMessageCopy plugin repository..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath

        if (Test-Path $pluginPath) {
            Write-Info "Removing existing MultiMessageCopy directory..."
            Remove-Item $pluginPath -Recurse -Force
        }

        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-multimessagecopy

        if (Test-Path "temp-multimessagecopy\MultiMessageCopyFiles") {
            Copy-Item "temp-multimessagecopy\MultiMessageCopyFiles" -Destination "MultiMessageCopy" -Recurse -Force
            Remove-Item "temp-multimessagecopy" -Recurse -Force
        } else {
            throw "MultiMessageCopyFiles subfolder not found in repository"
        }

        Set-Location $currentLocation

        if (Test-Path "$pluginPath\index.tsx") {
            Write-Success "MultiMessageCopy plugin cloned successfully!"
        } else {
            throw "Plugin files not found after cloning"
        }
    }
    catch {
        Write-Error "Failed to clone MultiMessageCopy plugin: $($_.Exception.Message)"
        Write-Info "Manual clone: https://github.com/tsx-awtns/MultiMessageCopy (files are in MultiMessageCopyFiles/ subfolder)"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

function Main {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║           MultiMessageCopy Setup Script - Version 1.0       ║
║                        by mays_024                          ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    try {
        if (!(Test-Administrator)) {
            Write-Warning "You are not running this script as Administrator. Some steps may fail."
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                Write-Info "Exiting..."
                Read-Host "Press Enter to exit"
                exit 0
            }
        }

        if (!$SkipNodeInstall) { Install-NodeJS }
        if (!$SkipGitInstall)  { Install-Git }
        Install-Pnpm

        if ([string]::IsNullOrEmpty($VencordPath)) {
            $VencordPath = Get-VencordPath
        }

        $vencordDir = Install-Vencord -InstallPath $VencordPath
        Install-VencordDependencies -VencordPath $vencordDir
        Install-MultiMessageCopy -VencordPath $vencordDir
        Build-Vencord -VencordPath $vencordDir

        Write-Info "`nVencord and MultiMessageCopy plugin are ready!"
        $inject = Read-Host "Inject Vencord into Discord now? (Y/n)"
        if ($inject -ne "n" -and $inject -ne "N") {
            Inject-Vencord -VencordPath $vencordDir
        }

        Write-Step "Setup Complete!"
        Write-Success @"
✅ MultiMessageCopy plugin installed successfully!

NEXT STEPS:
1. Restart Discord
2. Go to: Settings > Vencord > Plugins > Enable 'MultiMessageCopy'
3. Use the plugin according to the instructions on GitHub

SUPPORT: https://discord.gg/aBvYsY2GnQ
"@

        Write-Info "`nInstallation path: $vencordDir"
        if ($inject -eq "n" -or $inject -eq "N") {
            Write-Warning "Run 'pnpm inject' inside the Vencord folder to inject manually."
        }

        Write-Info "`nSetup completed successfully!"
        Read-Host "Press Enter to exit"
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Info "Try manual installation or check README.md"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

try {
    Main
}
catch {
    Write-Error "Critical error: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}
finally {
    try {
        if ($PWD.Path -ne $PSScriptRoot -and $PSScriptRoot) {
            Set-Location $PSScriptRoot
        }
    }
    catch {}
}
