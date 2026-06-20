/**
 * htmlExport/messages.ts
 *
 * Single-message rendering with stable two-column layout (avatar-slot +
 * message-main), reply previews, and proper grouped-message support.
 * No negative margins, no layout tricks that cause embed misalignment.
 */

import type { ExportMessage } from "../../types/export"
import { escapeAttribute, escapeHtml, formatTimestamp } from "./safety"
import { type ParticipantMap, buildParticipantStats, renderAvatar } from "./users"
import {
  collectSuppressedUrls,
  extractDirectMediaLinks,
  renderMessageContent,
} from "./content"
import { renderAttachments, renderDiscordCdnMediaLinks, renderStickers } from "./media"
import { renderEmbeds } from "./embeds"

function isGrouped(msg: ExportMessage, prev: ExportMessage | null): boolean {
  if (!prev) return false
  if (msg.author_id !== prev.author_id) return false
  if (msg.referenced_message) return false
  try {
    const diff =
      new Date(msg.timestamp).getTime() - new Date(prev.timestamp).getTime()
    return diff < 7 * 60 * 1000
  } catch {
    return false
  }
}

/** Discord-style reply preview bar above a message */
function renderReplyPreview(msg: ExportMessage): string {
  const ref = msg.referenced_message
  if (!ref?.message_id) return ""

  const refId = escapeAttribute(ref.message_id)

  // Resolve the display name of the referenced author
  const authorName = escapeHtml(
    ref.author_display_name ?? ref.author_global_name ?? ref.author_username ?? "Unknown"
  )

  // Avatar — tiny 16px circle
  const avatarHtml = ref.author_avatar_url
    ? `<img class="reply-avatar" src="${escapeAttribute(ref.author_avatar_url)}" alt="" aria-hidden="true" width="16" height="16">`
    : `<span class="reply-avatar reply-avatar-fallback" aria-hidden="true"></span>`

  // Content — truncated, italicised on deleted
  let contentHtml: string
  if (ref.deleted) {
    contentHtml = `<span class="reply-content reply-content-deleted">Original message was deleted</span>`
  } else if (ref.content) {
    // strip newlines for preview
    const preview = escapeHtml(ref.content.replace(/\n+/g, " "))
    contentHtml = `<span class="reply-content">${preview}</span>`
  } else {
    contentHtml = `<span class="reply-content reply-content-media">[Click to see attachment]</span>`
  }

  // The curved connector SVG (Discord's reply line)
  const connectorSvg =
    `<svg class="reply-connector" viewBox="0 0 44 24" fill="none" aria-hidden="true">` +
    `<path d="M4 0 V16 Q4 24 12 24 H44" stroke="currentColor" stroke-width="2" fill="none"/>` +
    `</svg>`

  return (
    `<div class="reply-preview">` +
    connectorSvg +
    `<a class="reply-body" href="#msg-${refId}" title="Jump to original message">` +
    avatarHtml +
    `<span class="reply-author">${authorName}</span>` +
    contentHtml +
    `</a>` +
    `</div>`
  )
}

/** Discord-style "Forwarded" badge — shown above the message header */
function renderForwardBadge(msg: ExportMessage): string {
  if (!msg.is_forwarded) return ""

  const fwdName = escapeHtml(
    msg.forwarded_author_global_name ?? msg.forwarded_author_username ?? ""
  )
  const fwdAvatarHtml = msg.forwarded_author_avatar_url
    ? `<img class="forward-avatar" src="${escapeAttribute(msg.forwarded_author_avatar_url)}" alt="" aria-hidden="true" width="14" height="14">`
    : ""

  // Forward arrow icon matching Discord
  const arrowSvg =
    `<svg class="forward-icon" width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">` +
    `<path d="M14.5 11H3v2h11.5l-5 5 1.4 1.4L18 12l-7.1-7.4L9.5 6l5 5z"/>` +
    `</svg>`

  return (
    `<div class="forward-badge">` +
    arrowSvg +
    `<span class="forward-label">Forwarded</span>` +
    (fwdAvatarHtml ? `<span class="forward-sep" aria-hidden="true">·</span>` + fwdAvatarHtml : "") +
    (fwdName ? `<span class="forward-from">${fwdName}</span>` : "") +
    `</div>`
  )
}

export function renderMessage(
  msg: ExportMessage,
  previousMessage: ExportMessage | null,
  participants: ParticipantMap,
  msgCountByAuthor: Record<string, number>
): string {
  const grouped = isGrouped(msg, previousMessage)

  const displayName = escapeHtml(
    msg.author_display_name ?? msg.author_global_name ?? msg.author_username
  )
  const userId      = escapeHtml(msg.author_id)
  const time        = escapeHtml(formatTimestamp(msg.timestamp))
  const timeIso     = escapeAttribute(msg.timestamp)
  const msgId       = escapeAttribute(msg.id)

  const p = participants.get(msg.author_id)
  const avatarUrl   = msg.author_avatar_url ?? p?.avatar_url
  const msgCount    = msgCountByAuthor[msg.author_id] ?? 0

  // Build attachment/embed URL sets scoped strictly to THIS message
  const attachmentUrls = new Set(msg.attachments.map(a => a.url))
  const embedUrls = new Set<string>()
  for (const e of msg.embeds) {
    if (e.video?.url) embedUrls.add(e.video.url)
    if (e.image?.url) embedUrls.add(e.image.url)
    if (e.thumbnail?.url) embedUrls.add(e.thumbnail.url)
    if (e.url) embedUrls.add(e.url)
  }

  // Direct CDN media links from THIS message's content only
  const directMediaLinks = extractDirectMediaLinks(
    msg.content,
    attachmentUrls,
    embedUrls
  )

  const suppressedUrls = collectSuppressedUrls(msg.content, msg.embeds, directMediaLinks)

  // Render all media/embeds/stickers scoped to this message
  const attachmentsHtml   = renderAttachments(msg.attachments)
  const cdnMediaHtml      = renderDiscordCdnMediaLinks(directMediaLinks)
  const combinedMediaHtml = attachmentsHtml + cdnMediaHtml
  const embedsHtml        = renderEmbeds(msg.embeds)
  const stickersHtml      = renderStickers(msg.stickers)

  let out = ""

  // Reply preview + forward badge INSIDE the article — strictly scoped to this message
  if (grouped) {
    out += (
      `<article class="message message-grouped" id="msg-${msgId}" ` +
      `data-author-id="${userId}" data-msg-id="${msgId}">`
    )
    out += renderForwardBadge(msg)
    out += renderReplyPreview(msg)
    out += (
      `<div class="avatar-slot avatar-slot-grouped">` +
      `<time class="grouped-timestamp" datetime="${timeIso}" aria-label="${time}">${time}</time>` +
      `</div>` +
      `<div class="message-main">`
    )
  } else {
    out += (
      `<article class="message" id="msg-${msgId}" ` +
      `data-author-id="${userId}" data-msg-id="${msgId}">`
    )
    out += renderForwardBadge(msg)
    out += renderReplyPreview(msg)
    out += (
      `<div class="avatar-slot">` +
      renderAvatar(
        msg.author_global_name ?? msg.author_username,
        msg.author_id,
        avatarUrl,
        msgCount
      ) +
      `</div>` +
      `<div class="message-main">` +
      `<div class="message-header">` +
      `<span class="msg-author" ` +
      `title="@${escapeAttribute(msg.author_username)} · ID: ${userId}" ` +
      `data-user-id="${userId}" ` +
      `role="button" tabindex="0" ` +
      `onclick="openPopout(this)" ` +
      `onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openPopout(this)}">` +
      displayName +
      `</span>` +
      `<time class="msg-time" datetime="${timeIso}" title="${timeIso}">${time}</time>` +
      `</div>`
    )
  }

  if (msg.content) {
    const rendered = renderMessageContent(msg.content, participants, suppressedUrls)
    out += `<div class="message-content">${rendered}</div>`
  }

  // All media, embeds, stickers are rendered inside THIS article — strictly owned by msg.id
  if (combinedMediaHtml) {
    out += `<div class="media-container" data-owner-id="${msgId}">${combinedMediaHtml}</div>`
  }

  if (embedsHtml) {
    out += `<div class="embeds" data-owner-id="${msgId}">${embedsHtml}</div>`
  }

  if (stickersHtml) {
    out += `<div class="stickers" data-owner-id="${msgId}">${stickersHtml}</div>`
  }

  out += `</div>`
  out += `</article>`

  return out
}

export function renderMessages(
  messages: ExportMessage[],
  participants: ParticipantMap
): string {
  const stats = buildParticipantStats(messages)
  const msgCountByAuthor: Record<string, number> = {}
  for (const [id, s] of Object.entries(stats)) {
    msgCountByAuthor[id] = s.msgCount
  }

  const rows: string[] = []
  for (let i = 0; i < messages.length; i++) {
    const prev = i > 0 ? messages[i - 1] : null
    rows.push(renderMessage(messages[i], prev, participants, msgCountByAuthor))
  }
  return rows.join("\n")
}
