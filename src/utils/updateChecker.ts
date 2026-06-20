/**
 * utils/updateChecker.ts
 *
 * Version check, update notification, and updater command helpers for MultiMessageCopy.
 */

import { openModal } from "@utils/modal"
import { PluginNative } from "@utils/types"
import { React } from "@webpack/common"
import { showToast, Toasts } from "@webpack/common"
import { UpdateModal } from "../components/UpdateModal"

type NativeExports = typeof import("../../native")
type MMCNative = PluginNative<NativeExports>

function getNative(): MMCNative | null {
    try {
        const h = (window as any).VencordNative?.pluginHelpers?.MultiMessageCopy
        if (h == null) return null
        if (typeof h.fetchVersionJson !== "function") return null
        return h as MMCNative
    } catch {
        return null
    }
}

export function isRunUpdaterAvailable(): boolean {
    try {
        const h = (window as any).VencordNative?.pluginHelpers?.MultiMessageCopy
        return typeof h?.runUpdater === "function"
    } catch {
        return false
    }
}

export async function runUpdaterNative(): Promise<{ started: boolean }> {
    const native = getNative()
    if (!native || typeof (native as any).runUpdater !== "function") {
        throw new Error("Native runUpdater is not available in this build.")
    }
    const result = await (native as any).runUpdater()
    if (!result.ok) {
        throw new Error(result.error ?? "runUpdater failed")
    }
    return result.value
}

export const PLUGIN_VERSION = "5.5.1"

export const REPO_URL = "https://github.com/tsx-awtns/MultiMessageCopy"

export const UPDATE_COMMAND =
    'iwr -UseB https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/update.ps1' +
    ' -OutFile "$env:TEMP\\mmc-update.ps1"; powershell -ExecutionPolicy Bypass' +
    ' -File "$env:TEMP\\mmc-update.ps1"'

const VERSION_URL =
    "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/refs/heads/main/version.json"

const DISMISSED_UPDATE_KEY = "MultiMessageCopy:dismissedUpdateVersion"

const FETCH_TIMEOUT_MS = 8000

export interface RemoteVersionInfo {
    name: string
    version: string
    repo: string
    latestRelease: string
    setupUrl: string
    updateUrl: string
    uninstallUrl: string
    changelog?: string
}

type FetchSource = "renderer" | "native" | "failed"

interface FetchResult {
    info: RemoteVersionInfo | null
    source: FetchSource
}

export function isNewerVersion(remote: string, local: string): boolean {
    try {
        const clean = (v: string) => v.replace(/^v/, "").trim()
        const parse = (v: string) => clean(v).split(".").map(n => {
            const num = parseInt(n, 10)
            return isNaN(num) ? 0 : num
        })
        const [rMaj, rMin, rPatch] = parse(remote)
        const [lMaj, lMin, lPatch] = parse(local)
        if (rMaj !== lMaj) return rMaj > lMaj
        if (rMin !== lMin) return rMin > lMin
        return rPatch > lPatch
    } catch {
        return false
    }
}

function getDismissedVersion(): string | null {
    try {
        return localStorage.getItem(DISMISSED_UPDATE_KEY)
    } catch {
        return null
    }
}

function setDismissedVersion(version: string): void {
    try {
        localStorage.setItem(DISMISSED_UPDATE_KEY, version)
    } catch { }
}

async function fetchWithTimeout(url: string, ms: number): Promise<Response> {
    const controller = new AbortController()
    const timer = setTimeout(() => controller.abort(), ms)
    try {
        return await fetch(url, {
            signal: controller.signal,
            cache: "no-store",
            headers: {
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
            },
        })
    } finally {
        clearTimeout(timer)
    }
}

async function parseVersionJson(res: Response): Promise<RemoteVersionInfo | null> {
    if (!res.ok) return null
    try {
        const json = await res.json()
        if (typeof json.version !== "string") return null
        return json as RemoteVersionInfo
    } catch {
        return null
    }
}

async function rendererFetch(cacheBust: boolean): Promise<RemoteVersionInfo | null> {
    try {
        const url = cacheBust ? `${VERSION_URL}?t=${Date.now()}` : VERSION_URL
        const res = await fetchWithTimeout(url, FETCH_TIMEOUT_MS)
        return await parseVersionJson(res)
    } catch {
        return null
    }
}

async function nativeFetch(cacheBust: boolean): Promise<RemoteVersionInfo | null> {
    try {
        const native = getNative()
        if (!native) return null

        const result = await native.fetchVersionJson(cacheBust)

        if (!result || !result.ok) {
            if (!result.ok) {
                console.warn(
                    "[MultiMessageCopy] Native fetch failed:",
                    (result as { ok: false; error: string }).error
                )
            }
            return null
        }

        const info = result.value
        if (typeof info?.version !== "string") return null
        return info
    } catch {
        return null
    }
}

async function fetchRemoteVersion(cacheBust: boolean): Promise<FetchResult> {
    const renderer = await rendererFetch(cacheBust)
    if (renderer) return { info: renderer, source: "renderer" }

    const native = await nativeFetch(cacheBust)
    if (native) return { info: native, source: "native" }

    return { info: null, source: "failed" }
}

function toast(msg: string, type: "success" | "failure" | "message") {
    try {
        const toastType = type === "success"
            ? Toasts.Type.SUCCESS
            : type === "failure"
                ? Toasts.Type.FAILURE
                : Toasts.Type.MESSAGE
        showToast(msg, toastType)
    } catch {
        console.info(`[MultiMessageCopy] ${msg}`)
    }
}

async function runCheck(force: boolean): Promise<void> {
    const { info: remote } = await fetchRemoteVersion(force)

    if (!remote) {
        if (force) {
            toast("Could not check for updates.", "failure")
        } else {
            console.warn("[MultiMessageCopy] Automatic update check failed: could not reach version.json")
        }
        return
    }

    const localVersion = PLUGIN_VERSION
    const hasUpdate = isNewerVersion(remote.version, localVersion)

    if (!hasUpdate) {
        if (force) {
            toast(
                `MultiMessageCopy is up to date. Installed v${localVersion}, latest v${remote.version}.`,
                "success"
            )
        }
        return
    }

    const dismissed = getDismissedVersion()
    if (!force && dismissed === remote.version) return

    openModal((props: { onClose: () => void }) =>
        React.createElement(UpdateModal, {
            remoteInfo: remote,
            installedVersion: localVersion,
            modalProps: props,
            onDismiss: () => {
                setDismissedVersion(remote.version)
                props.onClose()
            },
        })
    )
}

export async function checkForUpdates(
    checkEnabled: boolean,
    notifyEnabled: boolean
): Promise<void> {
    if (!checkEnabled || !notifyEnabled) return
    setTimeout(() => runCheck(false).catch(() => { }), 3000)
}

export async function checkForUpdatesManual(): Promise<void> {
    toast("Checking for updates\u2026", "message")
    await runCheck(true)
}
