/**
 * htmlExport/safety.ts
 *
 * All sanitization and URL-validation helpers for the HTML export.
 * No side-effects, no DOM, fully testable.
 */

export function escapeHtml(raw: string): string {
  return raw
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
}

export function escapeAttribute(raw: string): string {
  return raw
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
}

export function isSafeUrl(url: string): boolean {
  try {
    const u = new URL(url)
    return (
      u.protocol === "http:" ||
      u.protocol === "https:" ||
      u.protocol === "blob:" ||
      (u.protocol === "data:" && url.startsWith("data:image/"))
    )
  } catch {
    return false
  }
}

export function safeAttr(url: string): string {
  return isSafeUrl(url) ? escapeAttribute(url) : ""
}

export function safeMediaUrl(url: string): string {
  if (!isSafeUrl(url)) return ""
  return escapeAttribute(url)
}

export function formatTimestamp(iso: string): string {
  try {
    const d = new Date(iso)
    const pad = (n: number) => String(n).padStart(2, "0")
    return (
      `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
      `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
    )
  } catch {
    return iso
  }
}

export function formatFileSize(size: number): string {
  if (size <= 0) return "0 B"
  const units = ["B", "KB", "MB", "GB"]
  const i = Math.floor(Math.log2(size) / 10)
  const clamped = Math.min(i, units.length - 1)
  const value = size / Math.pow(1024, clamped)
  return `${value % 1 === 0 ? value : value.toFixed(1)} ${units[clamped]}`
}

export function getExtension(filename: string): string {
  const path = filename.split("?")[0]
  return path.split(".").pop()?.toLowerCase() ?? ""
}
