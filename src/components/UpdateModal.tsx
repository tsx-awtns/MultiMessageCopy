/**
 * components/UpdateModal.tsx
 *
 * Update notification modal for MultiMessageCopy.
 */

import { ModalRoot, ModalHeader, ModalContent, ModalFooter, ModalCloseButton } from "@utils/modal"
import { Button } from "@webpack/common"
import { React } from "@webpack/common"
import { showToast, Toasts } from "@webpack/common"
import { Forms } from "@webpack/common"
import { REPO_URL, UPDATE_COMMAND, isRunUpdaterAvailable, runUpdaterNative } from "../utils/updateChecker"

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

interface UpdateModalProps {
    remoteInfo: RemoteVersionInfo
    installedVersion: string
    onDismiss: () => void
    modalProps: any
}

interface ConfirmRunModalProps {
    onConfirm: () => void
    onCancel: () => void
    modalProps: any
}

function ConfirmRunModal({ onConfirm, onCancel, modalProps }: ConfirmRunModalProps) {
    return (
        <ModalRoot {...modalProps} size="small">
            <ModalHeader>
                <Forms.FormTitle tag="h4">Open PowerShell updater?</Forms.FormTitle>
            </ModalHeader>
            <ModalContent>
                <div style={{ marginTop: "12px", marginBottom: "16px" }}>
                    <Forms.FormText>
                        This will open a visible PowerShell window and run the official
                        MultiMessageCopy updater. The updater will rebuild Vencord and
                        may ask whether to restart Discord. It will not do anything automatically.
                    </Forms.FormText>
                </div>
            </ModalContent>
            <ModalFooter>
                <div className="mmc-update-confirm-footer">
                    <Button
                        color={Button.Colors.TRANSPARENT}
                        look={Button.Looks.LINK}
                        onClick={() => { onCancel(); modalProps.onClose() }}
                    >
                        Cancel
                    </Button>
                    <Button
                        color={Button.Colors.PRIMARY}
                        onClick={() => { onConfirm(); modalProps.onClose() }}
                    >
                        Open PowerShell Updater
                    </Button>
                </div>
            </ModalFooter>
        </ModalRoot>
    )
}

export function UpdateModal({ remoteInfo, installedVersion, onDismiss, modalProps }: UpdateModalProps) {
    const [copied, setCopied] = React.useState(false)
    const [runState, setRunState] = React.useState<"idle" | "confirming" | "launching">("idle")
    const nativeAvailable = isRunUpdaterAvailable()

    async function handleCopyCommand() {
        try {
            if (navigator.clipboard?.writeText) {
                await navigator.clipboard.writeText(UPDATE_COMMAND)
            } else {
                const ta = document.createElement("textarea")
                ta.value = UPDATE_COMMAND
                ta.style.cssText = "position:fixed;opacity:0;pointer-events:none"
                document.body.appendChild(ta)
                ta.select()
                document.execCommand("copy")
                ta.remove()
            }
            setCopied(true)
            setTimeout(() => setCopied(false), 3000)
            try { showToast("Update command copied. Paste it into PowerShell.", Toasts.Type.SUCCESS) } catch {}
        } catch { }
    }

    function handleOpenGitHub() {
        window.open(REPO_URL, "_blank", "noopener,noreferrer")
    }

    async function handleRunConfirmed() {
        setRunState("launching")
        try {
            await runUpdaterNative()
            try {
                showToast(
                    "PowerShell updater opened. Follow the instructions in the terminal.",
                    Toasts.Type.SUCCESS
                )
            } catch {}
        } catch {
            await handleCopyCommand()
            try {
                showToast(
                    "Could not open PowerShell automatically. Update command copied instead.",
                    Toasts.Type.FAILURE
                )
            } catch {}
        } finally {
            setRunState("idle")
        }
    }

    function handleRunUpdate() {
        if (!nativeAvailable) {
            handleCopyCommand()
            try {
                showToast(
                    "Automatic updater is not available. Command copied instead.",
                    Toasts.Type.MESSAGE
                )
            } catch {}
            return
        }
        setRunState("confirming")
    }

    if (runState === "confirming") {
        return (
            <ConfirmRunModal
                modalProps={modalProps}
                onConfirm={handleRunConfirmed}
                onCancel={() => setRunState("idle")}
            />
        )
    }

    return (
        <ModalRoot {...modalProps} size="small">

            <ModalHeader separator={false}>
                <Forms.FormTitle tag="h4" style={{ flexGrow: 1 }}>
                    MultiMessageCopy update available
                </Forms.FormTitle>
                <ModalCloseButton onClick={modalProps.onClose} />
            </ModalHeader>

            <ModalContent>
                <div className="mmc-update-content">

                    <Forms.FormText className="mmc-update-version-line">
                        {"Installed "}
                        <strong>v{installedVersion}</strong>
                        {" \u2192 Latest "}
                        <strong className="mmc-update-version-latest">v{remoteInfo.version}</strong>
                    </Forms.FormText>

                    <Forms.FormText type={Forms.FormText.Types?.DESCRIPTION}>
                        A new version is available. You can run the updater automatically
                        in PowerShell, or copy the command to run it manually.
                    </Forms.FormText>

                    {remoteInfo.changelog && (
                        <div>
                            <Forms.FormTitle tag="h5" className="mmc-update-section-title">
                                {"What's new"}
                            </Forms.FormTitle>
                            <div className="mmc-update-panel mmc-update-panel-scrollable">
                                <Forms.FormText>{remoteInfo.changelog}</Forms.FormText>
                            </div>
                        </div>
                    )}

                    <div>
                        <Forms.FormTitle tag="h5" className="mmc-update-section-title">
                            Manual command
                        </Forms.FormTitle>
                        <div
                            className="mmc-update-code"
                            title="Click to select all"
                            onClick={e => {
                                const sel = window.getSelection()
                                if (sel) {
                                    const range = document.createRange()
                                    range.selectNodeContents(e.currentTarget)
                                    sel.removeAllRanges()
                                    sel.addRange(range)
                                }
                            }}
                        >
                            <Forms.FormText>{UPDATE_COMMAND}</Forms.FormText>
                        </div>
                        <Forms.FormText type={Forms.FormText.Types?.DESCRIPTION} style={{ marginTop: "5px" }}>
                            Paste into PowerShell and run. The updater will ask before restarting Discord.
                        </Forms.FormText>
                    </div>

                </div>
            </ModalContent>

            <ModalFooter>
                <div className="mmc-update-footer">

                    <Button
                        look={Button.Looks.OUTLINED}
                        color={Button.Colors.PRIMARY}
                        className="mmc-update-footer-dismiss"
                        onClick={() => { onDismiss(); modalProps.onClose() }}
                    >
                        Dismiss
                    </Button>

                    <div className="mmc-update-footer-actions">

                        <Button
                            look={Button.Looks.OUTLINED}
                            color={Button.Colors.PRIMARY}
                            onClick={handleOpenGitHub}
                        >
                            Open GitHub
                        </Button>

                        <Button
                            color={Button.Colors.PRIMARY}
                            look={Button.Looks.OUTLINED}
                            onClick={handleCopyCommand}
                        >
                            {copied ? "Copied!" : "Copy Command"}
                        </Button>

                        <Button
                            color={Button.Colors.BRAND}
                            disabled={runState === "launching"}
                            onClick={handleRunUpdate}
                        >
                            {runState === "launching" ? "Opening\u2026" : "Run Update"}
                        </Button>

                    </div>

                </div>
            </ModalFooter>

        </ModalRoot>
    )
}
