/**
 * hooks/selectionManager.ts
 *
 * Selection mode lifecycle, keyboard shortcuts, message toggling,
 * and copy actions for MultiMessageCopy.
 */

import settings from "../settings"
import {
  isSelectionMode,
  selectedMessages,
  currentChannelId,
  observer,
  keyboardListener,
  selectionStarted,
  setIsSelectionMode,
  setCurrentChannelId,
  setObserver,
  setKeyboardListener,
  setSelectionStarted,
} from "./selectionState"
import { Message } from "../types"
import { playSound } from "../utils/sound"
import { showNotification } from "../utils/notification"
import { copyToClipboard } from "../utils/clipboard"
import { formatMessagesForCopy } from "../utils/copyFormats"
import { isSystemMessageElement } from "../utils/domHelpers"
import {
  addCheckboxesToMessages,
  updateCheckboxStates,
  cleanupMessageModifications,
  registerToggleMessageSelection,
  attachDelegatedClickHandler,
  attachDelegatedKeydownHandler,
} from "../components/CheckboxManager"
import {
  addControlButtons,
  addSelectionCounter,
  addKeyboardHints,
  updateSelectedCount,
  registerToolbarCallbacks,
} from "../components/Toolbar"
import { showPreviewModal } from "../components/PreviewModal"
import {
  MESSAGE_SELECTOR,
  CHAT_CONTAINER_SELECTOR,
  ELEMENTS_TO_REMOVE_ON_EXIT,
} from "../constants"
import { MessageStore } from "@webpack/common"

function startObservingMessages(): void {
  const chatContainer = document.querySelector(CHAT_CONTAINER_SELECTOR)
  if (!chatContainer) return

  let rafPending = false

  const obs = new MutationObserver(() => {
    if (!isSelectionMode || rafPending) return
    rafPending = true
    requestAnimationFrame(() => {
      rafPending = false
      if (isSelectionMode) addCheckboxesToMessages()
    })
  })

  obs.observe(chatContainer, { childList: true, subtree: true })
  setObserver(obs)
}

function stopObservingMessages(): void {
  if (observer) {
    observer.disconnect()
    setObserver(null)
  }
}

function setupKeyboardShortcuts(): void {
  const listener = (e: KeyboardEvent) => {
    if (!isSelectionMode) return

    if (e.key === "Escape") {
      e.preventDefault()
      exitSelectionMode()
    } else if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      copySelectedMessages()
    } else if (e.key === "a" && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      selectAllMessages()
    } else if (e.key === "d" && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      deselectAllMessages()
    } else if (e.key === "i" && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      invertSelection()
    }
  }

  document.addEventListener("keydown", listener)
  setKeyboardListener(listener)
}

function removeKeyboardShortcuts(): void {
  if (keyboardListener) {
    document.removeEventListener("keydown", keyboardListener)
    setKeyboardListener(null)
  }
}

function resolveMessage(messageId: string): Message | null {
  if (selectedMessages.has(messageId)) {
    return selectedMessages.get(messageId)!
  }

  try {
    const storeMessages = MessageStore.getMessages(currentChannelId)?._array as Message[] | undefined
    if (storeMessages) {
      const found = storeMessages.find((m: Message) => m.id === messageId)
      if (found) return found
    }
  } catch { }

  const el = document.getElementById(`chat-messages-${messageId}`)
    ?? document.querySelector(`[id$="-${messageId}"]`)
  if (el) {
    const authorEl = el.querySelector("[class*='username']") ?? el.querySelector("[class*='author']")
    const contentEl = el.querySelector("[id*='message-content']") ?? el.querySelector("[class*='messageContent']")
    const timestampEl = el.querySelector("time")
    return {
      id: messageId,
      channel_id: currentChannelId,
      content: contentEl?.textContent ?? "",
      timestamp: timestampEl?.getAttribute("datetime") ?? new Date().toISOString(),
      author: {
        id: "",
        username: authorEl?.textContent ?? "Unknown",
        globalName: undefined,
      },
    }
  }

  return null
}

function sortMessagesBySnowflake(messages: Message[]): Message[] {
  return [...messages].sort((a, b) => {
    const aId = BigInt(a.id)
    const bId = BigInt(b.id)
    return aId < bId ? -1 : aId > bId ? 1 : 0
  })
}

export function toggleMessageSelection(messageId: string): void {
  const wasSelected = selectedMessages.has(messageId)

  if (wasSelected) {
    selectedMessages.delete(messageId)
    playSound("deselect")
  } else {
    const message = resolveMessage(messageId)
    if (message) {
      selectedMessages.set(messageId, message)
    } else {
      selectedMessages.set(messageId, {
        id: messageId,
        channel_id: currentChannelId,
        content: "[Message content unavailable]",
        timestamp: new Date().toISOString(),
        author: { id: "", username: "Unknown" },
      })
    }
    playSound("select")
  }

  updateCheckboxStates()
  updateSelectedCount()

  const messageElement = document.getElementById(`chat-messages-${messageId}`)
  if (messageElement) {
    messageElement.style.transform = wasSelected ? "scale(0.98)" : "scale(1.02)"
    setTimeout(() => {
      messageElement.style.transform = "scale(1)"
    }, 150)
  }
}

export function selectAllMessages(): void {
  const messageElements = document.querySelectorAll(MESSAGE_SELECTOR)

  let addedCount = 0
  messageElements.forEach((messageElement) => {
    const messageId = messageElement.id.split("-").pop()
    if (!messageId) return
    if (isSystemMessageElement(messageElement)) return
    if (selectedMessages.has(messageId)) return

    const message = resolveMessage(messageId)
    if (message) {
      selectedMessages.set(messageId, message)
      addedCount++
    }
  })

  updateCheckboxStates()
  updateSelectedCount()
  playSound("select")
  showNotification(`Selected ${addedCount} messages`, "info", "📋")
}

export function deselectAllMessages(): void {
  const count = selectedMessages.size
  selectedMessages.clear()
  updateCheckboxStates()
  updateSelectedCount()

  document.querySelectorAll(".mmc-message-container").forEach((container) => {
    container.classList.remove("mmc-hover")
  })

  if (count > 0) {
    playSound("deselect")
    showNotification(`Deselected ${count} messages`, "info", "🗑️")
  }
}

export function invertSelection(): void {
  const messageElements = document.querySelectorAll(MESSAGE_SELECTOR)

  let changedCount = 0
  messageElements.forEach((messageElement) => {
    const messageId = messageElement.id.split("-").pop()
    if (!messageId) return
    if (isSystemMessageElement(messageElement)) return

    if (selectedMessages.has(messageId)) {
      selectedMessages.delete(messageId)
    } else {
      const message = resolveMessage(messageId)
      if (message) {
        selectedMessages.set(messageId, message)
      }
    }
    changedCount++
  })

  updateCheckboxStates()
  updateSelectedCount()
  showNotification(`Inverted selection for ${changedCount} messages`, "info", "🔄")
}

export function copySelectedMessages(): void {
  if (selectedMessages.size === 0) {
    playSound("error")
    showNotification("No messages selected!", "error", "⚠️")
    return
  }

  const sortedMessages    = sortMessagesBySnowflake(Array.from(selectedMessages.values()))
  const formattedMessages = formatMessagesForCopy(sortedMessages)

  if (settings.store.showPreview && selectedMessages.size > 1) {
    showPreviewModal(formattedMessages, exitSelectionMode)
  } else {
    copyToClipboard(formattedMessages, selectedMessages.size, exitSelectionMode)
  }
}

export function enterSelectionMode(channelId: string): void {
  setIsSelectionMode(true)
  setCurrentChannelId(channelId)
  selectedMessages.clear()
  setSelectionStarted(true)

  playSound("enter")
  setupKeyboardShortcuts()
  document.body.setAttribute("data-animation-speed", settings.store.animationSpeed)

  const overlay = document.createElement("div")
  overlay.className = "mmc-selection-overlay"
  document.body.appendChild(overlay)

  showNotification(
    "Selection mode activated! Click messages to select them.",
    "info",
    "🎯",
  )

  attachDelegatedClickHandler()
  attachDelegatedKeydownHandler()

  setTimeout(() => {
    addCheckboxesToMessages()
    addControlButtons()
    addSelectionCounter()
    addKeyboardHints()
    startObservingMessages()
  }, 100)
}

export function exitSelectionMode(): void {
  setIsSelectionMode(false)
  selectedMessages.clear()
  setCurrentChannelId("")
  setSelectionStarted(false)

  playSound("exit")
  removeKeyboardShortcuts()
  stopObservingMessages()

  ELEMENTS_TO_REMOVE_ON_EXIT.forEach((selector) => {
    const element = document.querySelector(selector)
    if (element) {
      element.classList.add("mmc-hiding")
      setTimeout(() => element.remove(), 300)
    }
  })

  cleanupMessageModifications()
}

registerToggleMessageSelection(toggleMessageSelection)
registerToolbarCallbacks({
  copySelectedMessages,
  exitSelectionMode,
  selectAllMessages,
  deselectAllMessages,
  invertSelection,
})
