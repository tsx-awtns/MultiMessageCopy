/**
 * components/ExportProgressModal.tsx
 *
 * Native Discord/Vencord export progress modal used while exporting chats.
 */

import { openModal, closeModal, ModalRoot, ModalHeader, ModalContent, ModalFooter } from "@utils/modal"
import { Button, Forms, React } from "@webpack/common"
import type { CancelToken } from "../utils/exportChat"
import type { ExportProgressState } from "../types/export"

const MAX_LOG_LINES = 6

const PHASE_LABELS: Record<string, string> = {
    fetching:    "Fetching messages",
    formatting:  "Formatting messages",
    building:    "Building file",
    downloading: "Downloading",
}

function fmtElapsed(sec: number): string {
    const m = Math.floor(sec / 60)
    const s = sec % 60
    return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
}

function fmtCount(n: number): string {
    return n.toLocaleString()
}

interface ModalState {
    title: string
    subtitle: string
    phase: string
    fetched: number
    formatted: number | null
    totalMessages: number | null
    elapsedSeconds: number | null
    format: string
    logLines: string[]
    barWidth: number
    barIndeterminate: boolean
    barError: boolean
    warning: string | null
    status: "running" | "done" | "error" | "cancelled"
}

function initialState(exportFormat: string): ModalState {
    return {
        title: "Exporting chat",
        subtitle: "Preparing\u2026",
        phase: "",
        fetched: 0,
        formatted: null,
        totalMessages: null,
        elapsedSeconds: null,
        format: exportFormat ? exportFormat.toUpperCase() : "\u2014",
        logLines: [],
        barWidth: 0,
        barIndeterminate: true,
        barError: false,
        warning: null,
        status: "running",
    }
}

interface ExportProgressModalProps {
    modalProps: any
    getState: () => ModalState
    subscribe: (cb: () => void) => () => void
    onCancel: () => void
}

function ExportProgressModal({ modalProps, getState, subscribe, onCancel }: ExportProgressModalProps) {
    const [state, setState] = React.useState<ModalState>(getState)

    React.useEffect(() => {
        return subscribe(() => setState(getState()))
    }, [getState, subscribe])

    const isDone = state.status === "done" || state.status === "error" || state.status === "cancelled"

    const phaseLabel = state.phase
        ? (() => {
            const label = PHASE_LABELS[state.phase] ?? state.phase
            const elapsed = state.elapsedSeconds != null ? ` \u00b7 ${fmtElapsed(state.elapsedSeconds)}` : ""
            return `${label}${elapsed}`
        })()
        : "\u00a0"

    const barFillStyle: React.CSSProperties = {
        height: "100%",
        borderRadius: "3px",
        transition: "width 0.4s ease",
        minWidth: "8px",
        background: state.barError
            ? "var(--button-danger-background, #ed4245)"
            : "var(--brand-experiment, var(--brand-500, #5865f2))",
        ...(state.barIndeterminate
            ? { width: "40%", animation: "mmcExportIndeterminate 1.4s ease-in-out infinite" }
            : { width: `${state.barWidth}%` }),
    }

    return (
        <ModalRoot {...modalProps} size="medium">

            <ModalHeader separator={false}>
                <Forms.FormTitle tag="h4" style={{ flexGrow: 1 }}>
                    {state.title}
                </Forms.FormTitle>
            </ModalHeader>

            <ModalContent>
                <div className="mmc-export-modal-body">

                    <Forms.FormText type={Forms.FormText.Types?.DESCRIPTION}>
                        {state.subtitle}
                    </Forms.FormText>

                    <Forms.FormText className="mmc-export-phase">
                        {phaseLabel}
                    </Forms.FormText>
                    <div className="mmc-export-bar-track">
                        <div style={barFillStyle} />
                    </div>

                    <div className="mmc-export-stats">

                        <div className="mmc-export-stat-row">
                            <Forms.FormText className="mmc-export-stat-label">
                                {"Messages fetched:"}
                            </Forms.FormText>
                            <Forms.FormText className="mmc-export-stat-value">
                                {fmtCount(state.fetched)}
                            </Forms.FormText>
                        </div>

                        {state.totalMessages != null && (
                            <div className="mmc-export-stat-row">
                                <Forms.FormText className="mmc-export-stat-label">
                                    {"Messages formatted:"}
                                </Forms.FormText>
                                <Forms.FormText className="mmc-export-stat-value">
                                    {`${fmtCount(state.fetched)} / ${fmtCount(state.totalMessages)}`}
                                </Forms.FormText>
                            </div>
                        )}

                        <div className="mmc-export-stat-row">
                            <Forms.FormText className="mmc-export-stat-label">
                                {"Elapsed:"}
                            </Forms.FormText>
                            <Forms.FormText className="mmc-export-stat-value">
                                {state.elapsedSeconds != null ? fmtElapsed(state.elapsedSeconds) : "\u2014"}
                            </Forms.FormText>
                        </div>

                        <div className="mmc-export-stat-row">
                            <Forms.FormText className="mmc-export-stat-label">
                                {"Format:"}
                            </Forms.FormText>
                            <Forms.FormText className="mmc-export-stat-value">
                                {state.format}
                            </Forms.FormText>
                        </div>

                    </div>

                    {state.warning && (
                        <div className="mmc-export-warning mmc-visible">
                            <Forms.FormText>{state.warning}</Forms.FormText>
                        </div>
                    )}

                    <div className="mmc-export-progress-log">
                        {(state.logLines.length > 0 ? state.logLines : ["Waiting for export to start\u2026"]).map((line, i) => (
                            <Forms.FormText key={i} className="mmc-export-log-line">
                                {line}
                            </Forms.FormText>
                        ))}
                    </div>

                </div>
            </ModalContent>

            <ModalFooter>
                <Button
                    color={isDone ? Button.Colors.PRIMARY : Button.Colors.RED}
                    look={isDone ? Button.Looks.OUTLINED : Button.Looks.FILLED}
                    disabled={state.status === "running" && false}
                    onClick={() => {
                        if (!isDone) {
                            onCancel()
                        } else {
                            modalProps.onClose()
                        }
                    }}
                >
                    {isDone ? "Close" : "Cancel"}
                </Button>
            </ModalFooter>

        </ModalRoot>
    )
}

export function openExportProgressModal(
    cancelToken: CancelToken,
    exportFormat?: string
): {
    update: (state: ExportProgressState) => void
    close: () => void
    isCancelled: () => boolean
} {
    let currentState = initialState(exportFormat ?? "")
    const listeners = new Set<() => void>()
    let modalKey: string | null = null

    function getState(): ModalState { return currentState }

    function subscribe(cb: () => void): () => void {
        listeners.add(cb)
        return () => listeners.delete(cb)
    }

    function notify() {
        listeners.forEach(cb => cb())
    }

    function appendLog(text: string) {
        const line = `${new Date().toLocaleTimeString()} \u2014 ${text}`
        const lines = [...currentState.logLines, line]
        if (lines.length > MAX_LOG_LINES) lines.shift()
        currentState = { ...currentState, logLines: lines }
    }

    function update(progress: ExportProgressState) {
        let next: Partial<ModalState> = {
            subtitle: progress.statusText,
            fetched: progress.fetched,
            elapsedSeconds: progress.elapsedSeconds ?? currentState.elapsedSeconds,
            totalMessages: progress.totalMessages ?? currentState.totalMessages,
        }

        if (progress.phase) {
            next.phase = progress.phase
        }

        if (
            progress.statusText.toLowerCase().includes("large export") ||
            progress.statusText.toLowerCase().includes("very large")
        ) {
            next.warning = progress.statusText
        }

        currentState = { ...currentState, ...next }
        appendLog(progress.statusText)

        if (progress.status === "done") {
            currentState = {
                ...currentState,
                title: "Export completed",
                subtitle: `${fmtCount(progress.fetched)} messages exported`,
                phase: "Download started",
                barIndeterminate: false,
                barWidth: 100,
                status: "done",
            }
            appendLog(`Exported ${fmtCount(progress.fetched)} messages.`)
            currentState = { ...currentState }
            notify()
            setTimeout(() => close(), 2500)
            return
        } else if (progress.status === "error") {
            currentState = {
                ...currentState,
                title: "Export failed",
                barIndeterminate: false,
                barWidth: 0,
                barError: true,
                status: "error",
            }
        } else if (progress.status === "cancelled") {
            currentState = {
                ...currentState,
                title: "Export cancelled",
                subtitle: `Stopped after ${fmtCount(progress.fetched)} messages`,
                barIndeterminate: false,
                barWidth: 0,
                status: "cancelled",
            }
        }

        notify()
    }

    function close() {
        if (modalKey) {
            closeModal(modalKey)
            modalKey = null
        }
    }

    function isCancelled(): boolean {
        return cancelToken.cancelled
    }

    modalKey = openModal(props =>
        <ExportProgressModal
            modalProps={props}
            getState={getState}
            subscribe={subscribe}
            onCancel={() => {
                if (!cancelToken.cancelled) {
                    cancelToken.cancel()
                }
            }}
        />
    )

    return { update, close, isCancelled }
}

export function closeExportProgressModal(): void { }
