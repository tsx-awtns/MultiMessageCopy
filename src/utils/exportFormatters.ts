/**
 * utils/exportFormatters.ts
 *
 * Public formatting API for JSON, TXT, and HTML export formats.
 */

import type { ExportDocument, ExportFormat } from "../types/export"
import { formatExportAsHtml as _formatHtml } from "./htmlExport/index"

export function formatExportAsHtml(doc: ExportDocument): string {
  return _formatHtml(doc)
}

export function formatExportAsJson(doc: ExportDocument): string {
  return JSON.stringify(doc, null, 2)
}

export function formatExportAsTxt(doc: ExportDocument): string {
  const lines: string[] = []

  function fmt(iso: string): string {
    try {
      const d = new Date(iso)
      const p = (n: number) => String(n).padStart(2, "0")
      return (
        `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ` +
        `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
      )
    } catch {
      return iso
    }
  }

  lines.push("Discord Chat Export")
  lines.push("===================")
  lines.push(`Channel: ${doc.channel_name ?? doc.channel_id}`)
  lines.push(`Channel ID: ${doc.channel_id}`)
  if (doc.guild_id) lines.push(`Guild ID: ${doc.guild_id}`)
  lines.push(`Exported At: ${doc.exported_at}`)
  lines.push(`Messages: ${doc.message_count}`)
  lines.push("")

  for (const msg of doc.messages) {
    const displayName =
      msg.author_display_name ?? msg.author_global_name ?? msg.author_username
    lines.push(`[${fmt(msg.timestamp)}] ${displayName} (${msg.author_id}):`)

    if (msg.content) lines.push(msg.content)

    if (msg.attachments.length > 0) {
      lines.push("Attachments:")
      for (const att of msg.attachments) {
        lines.push(`  - ${att.filename}: ${att.url}`)
      }
    }

    if (msg.stickers.length > 0) {
      lines.push("Stickers:")
      for (const s of msg.stickers) {
        lines.push(`  - ${s.name}`)
      }
    }

    if (msg.embeds.length > 0) {
      lines.push("Embeds:")
      for (const e of msg.embeds) {
        const parts: string[] = []
        if (e.title) parts.push(e.title)
        if (e.description) parts.push(e.description)
        if (e.url) parts.push(`<${e.url}>`)
        lines.push(`  - ${parts.join(" | ") || "(embed)"}`)
      }
    }

    lines.push("")
  }

  return lines.join("\n")
}

export function getExportMimeType(format: ExportFormat): string {
  switch (format) {
    case "txt":  return "text/plain"
    case "html": return "text/html"
    case "json":
    default:     return "application/json"
  }
}

export function getExportExtension(format: ExportFormat): string {
  return format
}
