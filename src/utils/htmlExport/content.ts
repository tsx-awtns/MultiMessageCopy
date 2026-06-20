/**
 * htmlExport/content.ts
 *
 * Message content rendering: thin wrapper that delegates to markdown.ts
 * for the full safe Discord Markdown pipeline, plus CDN media detection
 * and URL-suppression helpers used by messages.ts and embeds.ts.
 *
 * RENDERING ORDER — see markdown.ts for the authoritative description.
 */

import type { ExportEmbed } from "../../types/export"
import type { ParticipantMap } from "./users"
import { getExtension } from "./safety"
import { renderDiscordMarkdown } from "./markdown"

export { renderDiscordMarkdown }

const DISCORD_CDN_HOSTS = [
  "cdn.discordapp.com",
  "media.discordapp.net",
]

function isDiscordCdnUrl(url: string): boolean {
  try {
    const u = new URL(url)
    return (
      DISCORD_CDN_HOSTS.some(h => u.hostname === h) ||
      u.hostname.match(/^images-ext-\d+\.discordapp\.net$/) !== null
    )
  } catch {
    return false
  }
}

const IMAGE_EXTS = new Set(["png", "jpg", "jpeg", "webp", "gif"])
const VIDEO_EXTS = new Set(["mp4", "webm", "mov"])
const AUDIO_EXTS = new Set(["mp3", "wav", "ogg", "flac"])

export function isDiscordCdnImageUrl(url: string): boolean {
  return isDiscordCdnUrl(url) && IMAGE_EXTS.has(getExtension(url))
}

export function isDiscordCdnVideoUrl(url: string): boolean {
  return isDiscordCdnUrl(url) && VIDEO_EXTS.has(getExtension(url))
}

export function isDiscordCdnAudioUrl(url: string): boolean {
  return isDiscordCdnUrl(url) && AUDIO_EXTS.has(getExtension(url))
}

export function isDiscordCdnMediaUrl(url: string): boolean {
  return isDiscordCdnImageUrl(url) || isDiscordCdnVideoUrl(url) || isDiscordCdnAudioUrl(url)
}

export function extractDirectMediaLinks(
  content: string,
  existingAttachmentUrls: Set<string>,
  existingEmbedUrls: Set<string>
): string[] {
  const found: string[] = []
  const urlPattern = /https?:\/\/[^\s<>"']+/g
  let m: RegExpExecArray | null
  while ((m = urlPattern.exec(content)) !== null) {
    const url = m[0]
    if (!isDiscordCdnMediaUrl(url)) continue
    if (existingAttachmentUrls.has(url)) continue
    if (existingEmbedUrls.has(url)) continue
    found.push(url)
  }
  return found
}

export function isTenorUrl(url: string): boolean {
  try {
    const u = new URL(url)
    return u.hostname === "tenor.com" || u.hostname === "www.tenor.com"
  } catch {
    return false
  }
}

export function collectSuppressedUrls(
  content: string,
  embeds: ExportEmbed[],
  directMediaLinks: string[]
): Set<string> {
  const suppressed = new Set<string>()

  for (const e of embeds) {
    const isTenor =
      e.type === "gifv" ||
      e.provider?.name?.toLowerCase() === "tenor" ||
      (e.url && isTenorUrl(e.url))
    if (!isTenor) continue
    if (e.url && content.includes(e.url)) suppressed.add(e.url)
  }

  for (const u of directMediaLinks) {
    suppressed.add(u)
  }

  return suppressed
}

export function renderMessageContent(
  content: string,
  participants: ParticipantMap,
  suppressUrls: Set<string> = new Set()
): string {
  return renderDiscordMarkdown(content, { participants, suppressUrls })
}
