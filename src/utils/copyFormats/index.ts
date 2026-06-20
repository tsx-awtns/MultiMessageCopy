/**
 * utils/copyFormats/index.ts
 *
 * Selects and runs the appropriate copy-format function based on settings.
 */

import settings from "../../settings"
import type { Message } from "../../types"
import { formatPlain }     from "./plain"
import { formatDiscord }   from "./discord"
import { formatWhatsApp }  from "./whatsapp"
import { formatMarkdown }  from "./markdown"
import { formatCompact }   from "./compact"
import { formatJson }      from "./json"

export type CopyFormat = "plain" | "discord" | "whatsapp" | "markdown" | "compact" | "json"

export type SeparatorStyle = "blank" | "line" | "compact"

export function formatMessagesForCopy(messages: Message[]): string {
  const fmt          = (settings.store.copyFormat as CopyFormat) ?? "plain"
  const separator    = (settings.store.separatorStyle as SeparatorStyle) ?? "blank"

  const formatOne = pickFormatter(fmt)
  const formatted = messages.map(formatOne)

  if (fmt === "json") {
    return `[\n${formatted.join(",\n")}\n]`
  }

  return joinWithSeparator(formatted, separator)
}

function pickFormatter(fmt: CopyFormat): (msg: Message) => string {
  switch (fmt) {
    case "discord":   return formatDiscord
    case "whatsapp":  return formatWhatsApp
    case "markdown":  return formatMarkdown
    case "compact":   return formatCompact
    case "json":      return formatJson
    case "plain":
    default:          return formatPlain
  }
}

function joinWithSeparator(lines: string[], style: SeparatorStyle): string {
  switch (style) {
    case "line":    return lines.join("\n---\n")
    case "compact": return lines.join("\n")
    case "blank":
    default:        return lines.join("\n\n")
  }
}

export function wrapJsonLines(lines: string[]): string {
  return `[\n${lines.join(",\n")}\n]`
}
