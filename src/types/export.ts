/**
 * types/export.ts
 *
 * Type definitions for the chat export pipeline.
 */

export interface ExportAttachment {
  id: string
  filename: string
  url: string
  proxy_url?: string
  size: number
  content_type?: string
  width?: number
  height?: number
}

export interface ExportEmbed {
  type: string
  url?: string
  title?: string
  description?: string
  color?: number
  provider?: { name?: string; url?: string }
  author?: { name?: string; url?: string; icon_url?: string }
  footer?: { text?: string; icon_url?: string }
  timestamp?: string
  thumbnail?: { url: string; proxy_url?: string; width?: number; height?: number }
  image?: { url: string; proxy_url?: string; width?: number; height?: number }
  video?: { url: string; proxy_url?: string; width?: number; height?: number }
}

export interface ExportSticker {
  id: string
  name: string
  format_type: number
}

export interface ExportMessageReference {
  message_id?: string
  channel_id?: string
  guild_id?: string
  /** Author of the referenced message — resolved at export time */
  author_id?: string
  author_username?: string
  author_global_name?: string
  author_display_name?: string
  author_avatar_url?: string
  /** Truncated content of the referenced message */
  content?: string
  /** True when the message has no content (deleted or unavailable) */
  deleted?: boolean
}

export interface ExportMessage {
  id: string
  channel_id: string
  guild_id?: string
  author_id: string
  author_username: string
  author_discriminator?: string
  author_global_name?: string
  author_display_name?: string
  author_avatar?: string
  author_avatar_url?: string
  timestamp: string
  edited_timestamp?: string
  content: string
  attachments: ExportAttachment[]
  embeds: ExportEmbed[]
  stickers: ExportSticker[]
  referenced_message?: ExportMessageReference
  /** True when this is a forwarded message (type 1 snapshot / MESSAGE_FORWARD) */
  is_forwarded?: boolean
  /** The original author of the forwarded message, if available */
  forwarded_author_username?: string
  forwarded_author_global_name?: string
  forwarded_author_avatar_url?: string
}

export interface ExportParticipant {
  id: string
  username?: string
  discriminator?: string
  global_name?: string
  display_name?: string
  avatar?: string
  avatar_url?: string
}

export interface ExportDocument {
  export_version: 1
  exported_at: string
  channel_id: string
  guild_id?: string
  channel_name?: string
  channel_type?: number
  message_count: number
  messages: ExportMessage[]
  participants?: Record<string, ExportParticipant>
  current_user_id?: string
  dm_recipient?: ExportParticipant
  recipients?: ExportParticipant[]
}

export type ExportFormat = "json" | "txt" | "html"

export type ExportPhase =
  | "fetching"
  | "formatting"
  | "building"
  | "downloading"

export interface ExportProgressState {
  status: "running" | "done" | "error" | "cancelled"
  fetched: number
  totalMessages?: number
  statusText: string
  phase?: ExportPhase
  elapsedSeconds?: number
}
