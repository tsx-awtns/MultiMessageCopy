/**
 * native.ts
 *
 * Electron main-process IPC handlers for MultiMessageCopy.
 * Exposes fetchVersionJson and runUpdater via VencordNative.pluginHelpers.MultiMessageCopy.
 */

import type { IpcMainInvokeEvent } from "electron"
import * as https from "https"
import { spawn } from "child_process"

interface RemoteVersionInfo {
    name: string
    version: string
    repo: string
    latestRelease: string
    setupUrl: string
    updateUrl: string
    uninstallUrl: string
    changelog?: string
}

type NativeResult<T> =
    | { ok: true;  value: T }
    | { ok: false; error: string }

const VERSION_JSON_URL =
    "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/refs/heads/main/version.json"

function httpsGet(url: string, timeoutMs = 8000): Promise<string> {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url)
        const options: https.RequestOptions = {
            hostname: parsedUrl.hostname,
            path: parsedUrl.pathname + parsedUrl.search,
            timeout: timeoutMs,
            headers: {
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "User-Agent": "MultiMessageCopy-UpdateChecker/1.0",
            },
        }
        const req = https.get(options, res => {
            if (
                res.statusCode !== undefined &&
                res.statusCode >= 300 &&
                res.statusCode < 400 &&
                res.headers.location
            ) {
                httpsGet(res.headers.location, timeoutMs).then(resolve, reject)
                return
            }

            if (!res.statusCode || res.statusCode < 200 || res.statusCode >= 300) {
                reject(new Error(`HTTP ${res.statusCode ?? "unknown"}`))
                return
            }

            const chunks: Buffer[] = []
            res.on("data", (chunk: Buffer) => chunks.push(chunk))
            res.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")))
            res.on("error", reject)
        })

        req.on("timeout", () => {
            req.destroy()
            reject(new Error(`Request timed out after ${timeoutMs}ms`))
        })

        req.on("error", reject)
    })
}

export async function fetchVersionJson(
    _event: IpcMainInvokeEvent,
    cacheBust = false
): Promise<NativeResult<RemoteVersionInfo>> {
    try {
        const url = cacheBust ? `${VERSION_JSON_URL}?t=${Date.now()}` : VERSION_JSON_URL
        const body = await httpsGet(url)
        const json = JSON.parse(body)

        if (typeof json?.version !== "string") {
            return { ok: false, error: "version.json missing required 'version' field" }
        }

        return { ok: true, value: json as RemoteVersionInfo }
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err)
        return { ok: false, error: message }
    }
}

const UPDATER_SCRIPT_URL =
    "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/update.ps1"

export async function runUpdater(
    _event: IpcMainInvokeEvent
): Promise<NativeResult<{ started: boolean }>> {
    return new Promise(resolve => {
        try {
            const psCommand = [
                "Remove-Item \"$env:TEMP\\mmc-update.ps1\" -Force -ErrorAction SilentlyContinue",
                `iwr -UseB "${UPDATER_SCRIPT_URL}" -OutFile "$env:TEMP\\mmc-update.ps1"`,
                "powershell -ExecutionPolicy Bypass -File \"$env:TEMP\\mmc-update.ps1\"",
            ].join("; ")

            const child = spawn("cmd.exe", [
                "/d",
                "/c",
                "start",
                "",
                "powershell.exe",
                "-NoExit",
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command", psCommand,
            ], {
                detached: true,
                stdio: "ignore",
                windowsHide: false,
            })

            child.on("error", (err: Error) => {
                resolve({ ok: false, error: err.message })
            })

            child.unref()
            resolve({ ok: true, value: { started: true } })
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err)
            resolve({ ok: false, error: message })
        }
    })
}
