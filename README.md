# MultiMessageCopy

Enhanced Discord message selection, copying, and chat export plugin for Vencord.

> **Unofficial Vencord UserPlugin.** Not affiliated with, endorsed by, or registered with the Vencord project or Discord Inc.

---

## Features

- **Selection mode** — right-click any message to enter; click or drag to select a range
- **Toolbar** — live counter; copy or clear with one click
- **Copy formats** — plain, compact, Discord, Markdown, JSON, WhatsApp; fully configurable
- **Preview modal** — inspect formatted text before copying
- **Sound effects** — subtle tones on select / copy / exit (toggleable)
- **Export Chat** *(off by default)* — export full DM or Group DM history as JSON, TXT, or HTML
  - HTML export includes Discord-style rendering, emoji, embeds, Tenor GIFs, spoilers, lightbox, and full-text search/filtering
  - Progress modal shows phase, message count, elapsed time, and a live log
- **In-plugin update detection** — checks for updates on startup and shows a native modal; Run Update opens a visible PowerShell updater window
- **Theme compatible** — works on Discord light, dark, and custom themes

---

## Requirements

| Requirement | Notes |
|---|---|
| [Vencord](https://github.com/Vendicated/Vencord) latest `dev` branch | Source install — not the Desktop app |
| [Git](https://git-scm.com) | Required to clone Vencord |
| [Node.js](https://nodejs.org) 18 LTS or newer | Required to build |
| pnpm 8+ (`npm install -g pnpm`) | Package manager |
| Windows (PowerShell 5.1+) | Only required for the automatic scripts |

---

## Installation

### Automatic (Windows)

```powershell
Remove-Item "$env:TEMP\mmc-update.ps1" -Force -ErrorAction SilentlyContinue
iwr -UseB https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1 -OutFile "$env:TEMP\mmc-update.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\mmc-update.ps1"
```

The installer checks Git / Node.js / pnpm, auto-detects your Vencord folder, copies the plugin files, runs `pnpm build`, and optionally runs `pnpm inject`. Your Vencord path is saved to `%APPDATA%\MultiMessageCopy\mmc-config.json`. Restart Discord from the system tray when done.

### Manual (all platforms)

```bash
git clone https://github.com/tsx-awtns/MultiMessageCopy \
    Vencord/src/userplugins/MultiMessageCopy
cd Vencord
pnpm build
pnpm inject   # optional — injects into the installed Discord app
```

---

## Updating

### In-plugin (Windows)

Open Discord > User Settings > Vencord > Plugins > MultiMessageCopy settings. If an update is available, the update modal appears automatically. Click **Run Update** to open a visible PowerShell window that downloads and runs the official updater. The updater creates a timestamped backup before replacing files and asks before restarting Discord. Discord is never closed automatically.

### Automatic script (Windows)

```powershell
Remove-Item "$env:TEMP\mmc-update.ps1" -Force -ErrorAction SilentlyContinue
iwr -UseB https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/update.ps1 -OutFile "$env:TEMP\mmc-update.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\mmc-update.ps1"
```

### Manual

```bash
cd Vencord/src/userplugins/MultiMessageCopy
git pull
cd ../../..
pnpm build
```

---

## Uninstalling

### Automatic (Windows)

```powershell
Remove-Item "$env:TEMP\mmc-update.ps1" -Force -ErrorAction SilentlyContinue
iwr -UseB https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/uninstall.ps1 -OutFile "$env:TEMP\mmc-update.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\mmc-update.ps1"
```

The uninstaller asks for confirmation, deletes only `src/userplugins/MultiMessageCopy`, rebuilds Vencord, and offers to restart Discord.

### Manual

```bash
rm -rf Vencord/src/userplugins/MultiMessageCopy
cd Vencord
pnpm build
```

---

## Enabling the Plugin

User Settings > Vencord > Plugins > search `MultiMessageCopy` > toggle on.

---

## Settings

| Setting | Default | Description |
|---|---|---|
| Date format | `DD.MM.YYYY, HH:mm:ss` | Timestamp format |
| Include attachments | on | Append attachment URLs |
| Include embeds | on | Append embed URLs |
| Media format | `Separate lines` | Inline, separate lines, or end |
| Animation speed | `Normal` | UI transition speed |
| Sound effects | on | Tones on select / copy / exit |
| Show preview | on | Preview modal before copy |
| Export Chat | off | Adds Export Chat to DM context menus |
| Export format | `JSON` | JSON / TXT / HTML |

---

## Notes

- The Vencord **source path** must be the cloned repository, not the installed app directory.
- The updater **creates a timestamped backup** of your current install before replacing files.
- Running `pnpm inject` after `pnpm build` injects into the installed Discord app. It is optional if you are running Vencord directly from source.
- Update detection runs on startup. Manual checks are available from the plugin settings.
- **Run Update** opens a visible PowerShell window — nothing runs silently.
- Large HTML exports can take time; the progress modal shows live status and a cancel button.
- HTML exports are self-contained and include search/filtering without any server.
- Export is only available for DMs and Group DMs. Server channels are intentionally unsupported.

---

## Changelog

### v5.5.0

- Rebuilt the update modal with native Discord/Vencord components.
- Rebuilt the export progress modal as a native React/Vencord modal.
- Fixed modal readability across light, dark, AMOLED, and custom themes.
- Added in-plugin update detection using GitHub `version.json`.
- Added a safe Run Update flow that opens a visible PowerShell updater window.
- Improved PowerShell setup/update scripts with backups, version tracking, safer path handling, dependency checks, and optional `pnpm inject`.
- Added `installed-version.json` tracking for updater status.
- Improved large chat export performance with progress phases, batching, and clearer export status.
- Added searchable/filterable HTML exports.
- Added multiple copy formats and copy options.
- Cleaned temporary debug logs and excessive comments.

---

## License

[MultiMessageCopy Custom Source License](https://github.com/tsx-awtns/MultiMessageCopy?tab=License-1-ov-file)

You may view, install, and modify this plugin. You may not claim ownership, remove attribution, or represent this as an official Vencord plugin or official Discord feature.
