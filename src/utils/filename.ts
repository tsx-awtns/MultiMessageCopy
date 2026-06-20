/**
 * filename.ts
 *
 * Builds a safe, human-readable filename for chat exports.
 *
 * Patterns:
 *   DM       → discord-export-dm-{displayName}-{YYYY-MM-DD-HH-mm}.{ext}
 *   Group DM → discord-export-group-{groupNameOrParticipants}-{YYYY-MM-DD-HH-mm}.{ext}
 *   Channel  → discord-export-{channelName}-{YYYY-MM-DD-HH-mm}.{ext}
 *   Fallback → discord-export-{channelId}-{YYYY-MM-DD-HH-mm}.{ext}
 */

import type { ExportDocument, ExportFormat, ExportParticipant } from "../types/export"

const DM_CHANNEL_TYPE = 1
const GROUP_DM_CHANNEL_TYPE = 3

function pad2(n: number): string {
  return String(n).padStart(2, "0")
}

function datestamp(): string {
  const now = new Date()
  return [
    now.getFullYear(),
    pad2(now.getMonth() + 1),
    pad2(now.getDate()),
    pad2(now.getHours()),
    pad2(now.getMinutes()),
  ].join("-")
}

export function sanitizeSlug(raw: string, fallback: string): string {
  const cleaned = raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")   // strip accent marks
    .replace(/[/\\:*?"<>|]+/g, "-")    // unsafe chars → hyphen
    .replace(/\s+/g, "-")              // spaces → hyphen
    .replace(/-{2,}/g, "-")            // collapse multiple hyphens
    .replace(/^-+|-+$/g, "")           // trim leading/trailing hyphens
    .slice(0, 48)

  return cleaned.length > 0 ? cleaned : fallback
}

function participantBestName(p: ExportParticipant): string {
  return p.display_name ?? p.global_name ?? p.username ?? p.id
}

export function buildExportFilename(
  doc: ExportDocument,
  format: ExportFormat
): string {
  const ext = format
  const date = datestamp()
  const channelId = String(doc.channel_id ?? "unknown")

  // ── Group DM ────────────────────────────────────────────────────────────
  if (doc.channel_type === GROUP_DM_CHANNEL_TYPE) {
    // 1. Named group (channel has a name)
    if (doc.channel_name) {
      const slug = sanitizeSlug(doc.channel_name, channelId)
      return `discord-export-group-${slug}-${date}.${ext}`
    }

    // 2. Build from participant names (excluding current user)
    const recipients: ExportParticipant[] = []
    if (Array.isArray(doc.recipients) && doc.recipients.length > 0) {
      for (const r of doc.recipients) {
        if (doc.current_user_id && r.id === doc.current_user_id) continue
        recipients.push(r)
      }
    } else if (doc.participants) {
      for (const [id, p] of Object.entries(doc.participants)) {
        if (doc.current_user_id && id === doc.current_user_id) continue
        recipients.push(p)
      }
    }

    if (recipients.length > 0) {
      const names = recipients
        .slice(0, 3)
        .map(r => sanitizeSlug(participantBestName(r), r.id))
        .filter(n => n.length > 0)
      if (names.length > 0) {
        const slug = names.join("-")
        return `discord-export-group-${slug}-${date}.${ext}`
      }
    }

    // 3. Fallback: channelId
    return `discord-export-group-${channelId}-${date}.${ext}`
  }

  // ── Direct Message ───────────────────────────────────────────────────────
  if (doc.channel_type === DM_CHANNEL_TYPE || doc.channel_type == null) {
    // 1. dm_recipient field (most reliable — set explicitly in exportChat.ts)
    if (doc.dm_recipient?.id) {
      const name = participantBestName(doc.dm_recipient)
      const slug = sanitizeSlug(name, doc.dm_recipient.id)
      return `discord-export-dm-${slug}-${date}.${ext}`
    }

    // 2. recipients array — find the non-current-user participant
    if (Array.isArray(doc.recipients) && doc.recipients.length > 0) {
      const other = doc.current_user_id
        ? doc.recipients.find(r => r.id !== doc.current_user_id) ?? doc.recipients[0]
        : doc.recipients[0]
      if (other?.id) {
        const name = participantBestName(other)
        const slug = sanitizeSlug(name, other.id)
        return `discord-export-dm-${slug}-${date}.${ext}`
      }
    }

    // 3. participants map — pick the non-current participant with most messages
    if (doc.participants) {
      const msgCount: Record<string, number> = {}
      for (const m of doc.messages) {
        msgCount[m.author_id] = (msgCount[m.author_id] ?? 0) + 1
      }
      let best: ExportParticipant | null = null
      let bestCount = -1
      for (const [id, p] of Object.entries(doc.participants)) {
        if (doc.current_user_id && id === doc.current_user_id) continue
        const c = msgCount[id] ?? 0
        if (c > bestCount) { bestCount = c; best = p }
      }
      if (best) {
        const name = participantBestName(best)
        const slug = sanitizeSlug(name, best.id)
        return `discord-export-dm-${slug}-${date}.${ext}`
      }
    }

    // 4. channel_name as last resort before unknown
    if (doc.channel_name) {
      const slug = sanitizeSlug(doc.channel_name, channelId)
      return `discord-export-dm-${slug}-${date}.${ext}`
    }

    // 5. Real fallback: channelId (never just "unknown")
    return `discord-export-dm-${channelId}-${date}.${ext}`
  }

  // ── Server channel ───────────────────────────────────────────────────────
  if (doc.channel_name) {
    const slug = sanitizeSlug(doc.channel_name, channelId)
    return `discord-export-${slug}-${date}.${ext}`
  }

  return `discord-export-${channelId}-${date}.${ext}`
}
