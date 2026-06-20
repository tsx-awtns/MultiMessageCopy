/**
 * patches/channelContextMenu.tsx
 *
 * Adds an Export Chat context menu item to DM and Group DM channels.
 */

import { NavContextMenuPatchCallback } from "@api/ContextMenu"
import { Menu } from "@webpack/common"
import { React } from "@webpack/common"

import settings from "../settings"
import { createCancelToken, startExport } from "../utils/exportChat"
import {
  closeExportProgressModal,
  openExportProgressModal,
} from "../components/ExportProgressModal"
import { showNotification } from "../utils/notification"

const PRIVATE_CHANNEL_TYPES = new Set([1, 3])

function hasGuild(channel: any): boolean {
  if (channel.guild_id) return true
  if (channel.guildId) return true
  if (typeof channel.getGuildId === "function" && channel.getGuildId()) return true
  return false
}

function isExportableChannel(channel: any): boolean {
  if (!channel) return false
  if (!PRIVATE_CHANNEL_TYPES.has(channel.type)) return false
  if (hasGuild(channel)) return false
  return true
}

function handleExportChat(channelId: string) {
  const cancelToken = createCancelToken()
  const exportFmt = (settings.store.exportChatFormat as string | undefined) ?? "json"
  const { update } = openExportProgressModal(cancelToken, exportFmt)

  startExport(channelId, cancelToken, state => {
    update(state)

    if (state.status === "done") {
      showNotification("Chat export completed.", "success", 5000)
    } else if (state.status === "error") {
      showNotification(`Export failed: ${state.statusText}`, "error", 7000)
    }
  }).catch(err => {
    closeExportProgressModal()
    showNotification(
      `Export error: ${err?.message ?? String(err)}`,
      "error",
      7000
    )
  })
}

function buildExportItem(channelId: string) {
  return (
    <Menu.MenuItem
      id="mmc-export-chat"
      label="Export Chat"
      action={() => handleExportChat(channelId)}
    />
  )
}

export const channelContextMenuPatch: NavContextMenuPatchCallback = (
  children,
  { channel }
) => {
  if (!settings.store.exportChatEnabled) return
  if (!isExportableChannel(channel)) return

  children.push(
    <Menu.MenuSeparator />,
    buildExportItem(String(channel.id))
  )
}

export const userContextMenuPatch: NavContextMenuPatchCallback = (
  children,
  { channel, user }
) => {
  if (!settings.store.exportChatEnabled) return
  if (!isExportableChannel(channel)) return

  children.push(
    <Menu.MenuSeparator />,
    buildExportItem(String(channel.id))
  )
}
