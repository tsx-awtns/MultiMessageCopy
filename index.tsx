import { definePluginSettings } from "@api/Settings"
import definePlugin, { OptionType } from "@utils/types"
import { Menu, MessageStore, moment, React } from "@webpack/common"
import "./styles.css"

interface Message {
  id: string
  content: string
  author: {
    id: string
    username: string
    globalName?: string
  }
  timestamp: string
  channel_id: string
  attachments?: Array<{
    id: string
    filename: string
    url: string
    proxy_url: string
    size: number
    width?: number
    height?: number
    content_type?: string
  }>
  embeds?: Array<{
    type: string
    url?: string
    title?: string
    description?: string
    image?: { url: string }
    video?: { url: string }
  }>
}

let isSelectionMode = false
const selectedMessages = new Set<string>()
let currentChannelId = ""
let observer: MutationObserver | null = null
let keyboardListener: ((e: KeyboardEvent) => void) | null = null
let selectionStarted = false

const settings = definePluginSettings({
  dateFormat: {
    type: OptionType.STRING,
    description: "Date format for copied messages",
    default: "DD.MM.YYYY, HH:mm:ss",
  },
  includeAttachments: {
    type: OptionType.BOOLEAN,
    description: "Include media attachments in copied messages",
    default: true,
  },
  includeEmbeds: {
    type: OptionType.BOOLEAN,
    description: "Include embedded media in copied messages",
    default: true,
  },
  mediaFormat: {
    type: OptionType.SELECT,
    description: "How to format media in copied messages",
    default: "separate",
    options: [
      { label: "Inline with text", value: "inline" },
      { label: "Separate lines", value: "separate", default: true },
      { label: "At the end", value: "end" },
    ],
  },
  animationSpeed: {
    type: OptionType.SELECT,
    description: "Animation speed",
    default: "normal",
    options: [
      { label: "Fast", value: "fast" },
      { label: "Normal", value: "normal", default: true },
      { label: "Slow", value: "slow" },
    ],
  },
  enableSoundEffects: {
    type: OptionType.BOOLEAN,
    description: "Enable sound effects for interactions",
    default: true,
  },
  showPreview: {
    type: OptionType.BOOLEAN,
    description: "Show preview of selected messages before copying",
    default: true,
  },
})

function playSound(type: 'select' | 'deselect' | 'copy' | 'error' | 'enter' | 'exit') {
  if (!settings.store.enableSoundEffects) return
  
  const frequencies = {
    select: 800,
    deselect: 600,
    copy: 1000,
    error: 300,
    enter: 900,
    exit: 700
  }
  
  const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
  const oscillator = audioContext.createOscillator()
  const gainNode = audioContext.createGain()
  
  oscillator.connect(gainNode)
  gainNode.connect(audioContext.destination)
  
  oscillator.frequency.setValueAtTime(frequencies[type], audioContext.currentTime)
  oscillator.type = 'sine'
  
  gainNode.gain.setValueAtTime(0, audioContext.currentTime)
  gainNode.gain.linearRampToValueAtTime(0.1, audioContext.currentTime + 0.01)
  gainNode.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.1)
  
  oscillator.start(audioContext.currentTime)
  oscillator.stop(audioContext.currentTime + 0.1)
}

function extractMediaFromMessage(message: Message): string[] {
  const mediaUrls: string[] = []

  if (settings.store.includeAttachments && message.attachments) {
    message.attachments.forEach((attachment) => {
      if (
        attachment.content_type?.startsWith("image/") ||
        attachment.content_type?.startsWith("video/") ||
        attachment.filename.match(/\.(jpg|jpeg|png|gif|webp|mp4|mov|avi|webm)$/i)
      ) {
        mediaUrls.push(`${attachment.filename}: ${attachment.url}`)
      }
    })
  }

  if (settings.store.includeEmbeds && message.embeds) {
    message.embeds.forEach((embed) => {
      if (embed.image?.url) {
        mediaUrls.push(`Image: ${embed.image.url}`)
      }
      if (embed.video?.url) {
        mediaUrls.push(`Video: ${embed.video.url}`)
      }
      if (embed.url && embed.type === "image") {
        mediaUrls.push(`Embed: ${embed.url}`)
      }
    })
  }

  return mediaUrls
}

function formatMessage(message: Message): string {
  const timestamp = moment(message.timestamp).format(settings.store.dateFormat)
  const displayName = message.author.globalName || message.author.username
  const content = message.content || ""
  const mediaUrls = extractMediaFromMessage(message)

  const formattedMessage = `[${timestamp}] ${displayName}:`

  if (mediaUrls.length === 0) {
    return `${formattedMessage} ${content}`
  }

  switch (settings.store.mediaFormat) {
    case "inline":
      if (content) {
        return `${formattedMessage} ${content} | Media: ${mediaUrls.join(", ")}`
      } else {
        return `${formattedMessage} ${mediaUrls.join(", ")}`
      }

    case "separate":
      let result = content ? `${formattedMessage} ${content}` : formattedMessage
      mediaUrls.forEach((url) => {
        result += `\n    📎 ${url}`
      })
      return result

    case "end":
      let endResult = content ? `${formattedMessage} ${content}` : formattedMessage
      if (mediaUrls.length > 0) {
        endResult += `\n📎 Media: ${mediaUrls.join(" | ")}`
      }
      return endResult

    default:
      return `${formattedMessage} ${content}`
  }
}

function showPreviewModal(formattedMessages: string) {
  const modal = document.createElement("div")
  modal.className = "mmc-preview-modal"
  
  const backdrop = document.createElement("div")
  backdrop.className = "mmc-modal-backdrop"
  
  const content = document.createElement("div")
  content.className = "mmc-modal-content"
  
  const header = document.createElement("div")
  header.className = "mmc-modal-header"
  header.innerHTML = `
    <h3>Preview Selected Messages (${selectedMessages.size})</h3>
    <button class="mmc-modal-close" aria-label="Close preview">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
      </svg>
    </button>
  `
  
  const body = document.createElement("div")
  body.className = "mmc-modal-body"
  
  const preview = document.createElement("pre")
  preview.className = "mmc-preview-text"
  preview.textContent = formattedMessages
  
  const footer = document.createElement("div")
  footer.className = "mmc-modal-footer"
  footer.innerHTML = `
    <button class="mmc-btn mmc-btn-secondary mmc-modal-cancel">Cancel</button>
    <button class="mmc-btn mmc-btn-primary mmc-modal-confirm">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/>
      </svg>
      Copy to Clipboard
    </button>
  `
  
  body.appendChild(preview)
  content.appendChild(header)
  content.appendChild(body)
  content.appendChild(footer)
  modal.appendChild(backdrop)
  modal.appendChild(content)
  document.body.appendChild(modal)
  
  // Event listeners
  const closeModal = () => {
    modal.classList.add("mmc-hiding")
    setTimeout(() => modal.remove(), 300)
  }
  
  backdrop.addEventListener("click", closeModal)
  header.querySelector(".mmc-modal-close")?.addEventListener("click", closeModal)
  footer.querySelector(".mmc-modal-cancel")?.addEventListener("click", closeModal)
  footer.querySelector(".mmc-modal-confirm")?.addEventListener("click", () => {
    actuallyPerformCopy(formattedMessages)
    closeModal()
  })
  
  // Keyboard navigation
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Escape") {
      closeModal()
    } else if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      actuallyPerformCopy(formattedMessages)
      closeModal()
    }
  }
  
  document.addEventListener("keydown", handleKeyDown)
  modal.addEventListener("remove", () => {
    document.removeEventListener("keydown", handleKeyDown)
  })
}

function actuallyPerformCopy(formattedMessages: string) {
  try {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard
        .writeText(formattedMessages)
        .then(() => {
          playSound('copy')
          showNotification(`${selectedMessages.size} messages copied successfully!`, "success", "✅")
          exitSelectionMode()
        })
        .catch(() => {
          fallbackCopyTextToClipboard(formattedMessages)
        })
    } else {
      fallbackCopyTextToClipboard(formattedMessages)
    }
  } catch (error) {
    fallbackCopyTextToClipboard(formattedMessages)
  }
}

function copySelectedMessages() {
  if (selectedMessages.size === 0) {
    playSound('error')
    showNotification("No messages selected!", "error", "⚠️")
    return
  }

  const messages = MessageStore.getMessages(currentChannelId)._array
  const selectedMessageObjects = messages.filter((m) => selectedMessages.has(m.id))
  const sortedMessages = selectedMessageObjects.sort(
    (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
  )

  const formattedMessages = sortedMessages.map(formatMessage).join("\n")

  if (settings.store.showPreview && selectedMessages.size > 1) {
    showPreviewModal(formattedMessages)
  } else {
    actuallyPerformCopy(formattedMessages)
  }
}

function fallbackCopyTextToClipboard(text: string) {
  const textArea = document.createElement("textarea")
  textArea.value = text
  textArea.style.position = "fixed"
  textArea.style.left = "-999999px"
  textArea.style.top = "-999999px"
  document.body.appendChild(textArea)
  textArea.focus()
  textArea.select()

  try {
    document.execCommand("copy")
    playSound('copy')
    showNotification(`${selectedMessages.size} messages copied successfully!`, "success", "✅")
    exitSelectionMode()
  } catch (err) {
    console.error("Failed to copy messages:", err)
    playSound('error')
    showNotification("Failed to copy messages to clipboard", "error", "❌")
  }

  document.body.removeChild(textArea)
}

function showNotification(message: string, type: "success" | "error" | "info" | "warning", icon = "") {
  // Remove existing notifications of the same type
  document.querySelectorAll(`.mmc-notification.mmc-${type}`).forEach(n => n.remove())
  
  const notification = document.createElement("div")
  notification.className = `mmc-notification mmc-${type}`
  notification.setAttribute('role', 'alert')
  notification.setAttribute('aria-live', 'polite')

  if (icon) {
    const iconSpan = document.createElement("span")
    iconSpan.className = "mmc-notification-icon"
    iconSpan.textContent = icon
    notification.appendChild(iconSpan)
  }

  const textSpan = document.createElement("span")
  textSpan.className = "mmc-notification-text"
  textSpan.textContent = message
  notification.appendChild(textSpan)

  const progressBar = document.createElement("div")
  progressBar.className = "mmc-progress"
  notification.appendChild(progressBar)

  // Close button
  const closeBtn = document.createElement("button")
  closeBtn.className = "mmc-notification-close"
  closeBtn.setAttribute('aria-label', 'Close notification')
  closeBtn.innerHTML = `
    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
      <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
    </svg>
  `
  closeBtn.addEventListener('click', () => {
    notification.classList.add("mmc-hiding")
    setTimeout(() => notification.remove(), 300)
  })
  notification.appendChild(closeBtn)

  document.body.appendChild(notification)

  const hideTimeout = setTimeout(() => {
    if (notification.parentNode) {
      notification.classList.add("mmc-hiding")
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }
  }, 5000)

  // Clear timeout if manually closed
  closeBtn.addEventListener('click', () => clearTimeout(hideTimeout))
}

function setupKeyboardShortcuts() {
  keyboardListener = (e: KeyboardEvent) => {
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

  document.addEventListener("keydown", keyboardListener)
}

function removeKeyboardShortcuts() {
  if (keyboardListener) {
    document.removeEventListener("keydown", keyboardListener)
    keyboardListener = null
  }
}

function enterSelectionMode(channelId: string) {
  isSelectionMode = true
  currentChannelId = channelId
  selectedMessages.clear()
  selectionStarted = true

  playSound('enter')
  setupKeyboardShortcuts()
  document.body.setAttribute('data-animation-speed', settings.store.animationSpeed)

  const overlay = document.createElement("div")
  overlay.className = "mmc-selection-overlay"
  document.body.appendChild(overlay)

  showNotification("Selection mode activated! Click messages to select them.", "info", "🎯")

  setTimeout(() => {
    addCheckboxesToMessages()
    addControlButtons()
    addSelectionCounter()
    addKeyboardHints()
    startObservingMessages()
  }, 100)
}

function exitSelectionMode() {
  isSelectionMode = false
  selectedMessages.clear()
  currentChannelId = ""
  selectionStarted = false

  playSound('exit')
  removeKeyboardShortcuts()
  stopObservingMessages()

  const elementsToRemove = [
    ".mmc-toolbar",
    ".mmc-counter", 
    ".mmc-overlay",
    ".mmc-selection-overlay",
    ".mmc-keyboard-hints"
  ]

  elementsToRemove.forEach(selector => {
    const element = document.querySelector(selector)
    if (element) {
      element.classList.add("mmc-hiding")
      setTimeout(() => element.remove(), 300)
    }
  })

  cleanupMessageModifications()
}

function cleanupMessageModifications() {
  document.querySelectorAll(".mmc-message-container").forEach((container) => {
    container.classList.remove("mmc-message-container", "mmc-selection-mode", "mmc-selected", "mmc-hover")
    const element = container as HTMLElement
    element.style.paddingLeft = ""
    element.style.background = ""
    element.style.borderLeft = ""
    element.style.borderRadius = ""
    element.style.transition = ""
    element.style.position = ""
  })

  document.querySelectorAll(".mmc-checkbox-container").forEach((checkbox) => {
    checkbox.classList.add("mmc-hiding")
    setTimeout(() => checkbox.remove(), 250)
  })
}

function startObservingMessages() {
  const chatContainer = document.querySelector('[data-list-id="chat-messages"]')
  if (!chatContainer) return

  observer = new MutationObserver(() => {
    if (isSelectionMode) {
      setTimeout(() => addCheckboxesToMessages(), 50)
    }
  })

  observer.observe(chatContainer, {
    childList: true,
    subtree: true,
  })
}

function stopObservingMessages() {
  if (observer) {
    observer.disconnect()
    observer = null
  }
}

function toggleMessageSelection(messageId: string) {
  const wasSelected = selectedMessages.has(messageId)
  
  if (wasSelected) {
    selectedMessages.delete(messageId)
    playSound('deselect')
  } else {
    selectedMessages.add(messageId)
    playSound('select')
  }
  
  updateCheckboxStates()
  updateSelectedCount()
  
  // Visual feedback
  const messageElement = document.getElementById(`chat-messages-${messageId}`)
  if (messageElement) {
    messageElement.style.transform = wasSelected ? 'scale(0.98)' : 'scale(1.02)'
    setTimeout(() => {
      messageElement.style.transform = 'scale(1)'
    }, 150)
  }
}

function invertSelection() {
  const messageElements = document.querySelectorAll(
    '[id^="chat-messages-"][id*="-"]:not([class*="systemMessage"]):not([class*="divider"]):not([class*="welcomeMessage"])',
  )

  let changedCount = 0
  messageElements.forEach((messageElement) => {
    const messageId = messageElement.id.split("-").pop()
    if (!messageId) return

    const isSystemMessage = isSystemMessageElement(messageElement)
    if (!isSystemMessage) {
      if (selectedMessages.has(messageId)) {
        selectedMessages.delete(messageId)
      } else {
        selectedMessages.add(messageId)
      }
      changedCount++
    }
  })

  updateCheckboxStates()
  updateSelectedCount()
  showNotification(`Inverted selection for ${changedCount} messages`, "info", "🔄")
}

function deselectAllMessages() {
  const count = selectedMessages.size
  selectedMessages.clear()
  updateCheckboxStates()
  updateSelectedCount()

  document.querySelectorAll(".mmc-message-container").forEach((container) => {
    container.classList.remove("mmc-hover")
  })

  if (count > 0) {
    playSound('deselect')
    showNotification(`Deselected ${count} messages`, "info", "🗑️")
  }
}

function isSystemMessageElement(messageElement: Element): boolean {
  return !!(
    messageElement.querySelector('[class*="systemMessage"]') ||
    messageElement.querySelector('[class*="welcomeMessage"]') ||
    messageElement.querySelector('[class*="divider"]') ||
    messageElement.querySelector('[class*="newMessagesBar"]') ||
    messageElement.textContent?.includes("This is the beginning of your direct message history") ||
    messageElement.textContent?.includes("Mutual Servers") ||
    messageElement.querySelector('button[aria-label*="Add Friend"]') ||
    messageElement.querySelector('button[aria-label*="Block"]')
  )
}

function addCheckboxesToMessages() {
  const messageElements = document.querySelectorAll(
    '[id^="chat-messages-"][id*="-"]:not([class*="systemMessage"]):not([class*="divider"]):not([class*="welcomeMessage"])',
  )

  messageElements.forEach((messageElement) => {
    if (messageElement.querySelector(".mmc-checkbox-container")) return

    const messageId = messageElement.id.split("-").pop()
    if (!messageId) return

    if (isSystemMessageElement(messageElement)) return

    messageElement.classList.add("mmc-message-container", "mmc-selection-mode")

    const checkboxContainer = document.createElement("div")
    checkboxContainer.className = "mmc-checkbox-container"
    checkboxContainer.setAttribute('role', 'checkbox')
    checkboxContainer.setAttribute('aria-checked', 'false')
    checkboxContainer.setAttribute('tabindex', '0')

    const checkbox = document.createElement("div")
    checkbox.className = "mmc-checkbox"

    const checkmark = document.createElement("div")
    checkmark.className = "mmc-checkmark"
    checkmark.innerHTML = `
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z" fill="white"/>
      </svg>
    `

    checkbox.appendChild(checkmark)
    checkboxContainer.appendChild(checkbox)

    const handleToggle = (e: Event) => {
      e.stopPropagation()
      toggleMessageSelection(messageId)
    }

    checkboxContainer.addEventListener("click", handleToggle)
    checkboxContainer.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault()
        handleToggle(e)
      }
    })

    messageElement.addEventListener("mouseenter", () => {
      if (isSelectionMode) {
        messageElement.classList.add("mmc-hover")
        checkboxContainer.classList.add("mmc-visible")
      }
    })

    messageElement.addEventListener("mouseleave", () => {
      if (isSelectionMode && !selectedMessages.has(messageId)) {
        messageElement.classList.remove("mmc-hover")
        checkboxContainer.classList.remove("mmc-visible")
      }
    })

    messageElement.appendChild(checkboxContainer)
  })
}

function selectAllMessages() {
  const messageElements = document.querySelectorAll(
    '[id^="chat-messages-"][id*="-"]:not([class*="systemMessage"]):not([class*="divider"]):not([class*="welcomeMessage"])',
  )

  let addedCount = 0
  messageElements.forEach((messageElement) => {
    const messageId = messageElement.id.split("-").pop()
    if (!messageId) return

    if (!isSystemMessageElement(messageElement)) {
      selectedMessages.add(messageId)
      addedCount++
    }
  })

  updateCheckboxStates()
  updateSelectedCount()
  playSound('select')
  showNotification(`Selected ${addedCount} messages`, "info", "📋")
}

function addKeyboardHints() {
  if (document.querySelector(".mmc-keyboard-hints")) return

  const hints = document.createElement("div")
  hints.className = "mmc-keyboard-hints"
  hints.innerHTML = `
    <div class="mmc-hint-title">Keyboard Shortcuts</div>
    <div class="mmc-hint-item"><kbd>Ctrl+A</kbd> Select All</div>
    <div class="mmc-hint-item"><kbd>Ctrl+D</kbd> Clear Selection</div>
    <div class="mmc-hint-item"><kbd>Ctrl+I</kbd> Invert Selection</div>
    <div class="mmc-hint-item"><kbd>Ctrl+Enter</kbd> Copy Messages</div>
    <div class="mmc-hint-item"><kbd>Esc</kbd> Exit Mode</div>
  `
  
  document.body.appendChild(hints)
  
  // Auto-hide after 5 seconds
  setTimeout(() => {
    if (hints.parentNode) {
      hints.classList.add("mmc-hiding")
      setTimeout(() => hints.remove(), 300)
    }
  }, 5000)
}

function addControlButtons() {
  if (document.querySelector(".mmc-toolbar")) return

  const toolbar = document.createElement("div")
  toolbar.className = "mmc-toolbar"
  toolbar.setAttribute('role', 'toolbar')
  toolbar.setAttribute('aria-label', 'Message selection controls')

  const buttons = [
    {
      id: "select-all",
      icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/>
      </svg>`,
      text: "Select All",
      className: "mmc-btn-select",
      title: "Select all messages (Ctrl+A)",
      action: selectAllMessages
    },
    {
      id: "invert",
      icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
      </svg>`,
      text: "Invert",
      className: "mmc-btn-invert",
      title: "Invert selection (Ctrl+I)",
      action: invertSelection
    },
    {
      id: "clear",
      icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
      </svg>`,
      text: "Clear",
      className: "mmc-btn-deselect",
      title: "Clear selection (Ctrl+D)",
      action: deselectAllMessages
    },
    {
      id: "copy",
      icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/>
      </svg>`,
      text: "Copy (0)",
      className: "mmc-btn-copy",
      title: "Copy selected messages (Ctrl+Enter)",
      action: copySelectedMessages,
      disabled: true
    }
  ]

  buttons.forEach(btn => {
    const button = document.createElement("button")
    button.id = `mmc-${btn.id}`
    button.innerHTML = `${btn.icon} ${btn.text}`
    button.className = `mmc-btn ${btn.className}`
    button.title = btn.title
    button.disabled = btn.disabled || false
    button.addEventListener("click", btn.action)
    toolbar.appendChild(button)
  })

  const closeButton = document.createElement("button")
  closeButton.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
    </svg>
  `
  closeButton.className = "mmc-btn mmc-btn-close"
  closeButton.title = "Exit selection mode (Escape)"
  closeButton.addEventListener("click", exitSelectionMode)

  toolbar.appendChild(closeButton)
  document.body.appendChild(toolbar)
}

function addSelectionCounter() {
  if (document.querySelector(".mmc-counter")) return

  const counter = document.createElement("div")
  counter.className = "mmc-counter"
  counter.setAttribute('role', 'status')
  counter.setAttribute('aria-live', 'polite')
  counter.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/>
    </svg>
    <span>0 selected</span>
  `
  document.body.appendChild(counter)
}

function updateCheckboxStates() {
  document.querySelectorAll(".mmc-checkbox-container").forEach((container) => {
    const messageElement = container.closest(".mmc-message-container")
    const messageId = messageElement?.id.split("-").pop()

    if (messageId) {
      const checkbox = container.querySelector(".mmc-checkbox")
      const checkmark = container.querySelector(".mmc-checkmark")
      const isSelected = selectedMessages.has(messageId)

      container.setAttribute('aria-checked', isSelected.toString())

      if (isSelected) {
        checkbox?.classList.add("mmc-checked")
        checkmark?.classList.add("mmc-visible")
        messageElement?.classList.add("mmc-selected")
        container.classList.add("mmc-visible")
      } else {
        checkbox?.classList.remove("mmc-checked")
        checkmark?.classList.remove("mmc-visible")
        messageElement?.classList.remove("mmc-selected")
        if (!messageElement?.classList.contains("mmc-hover")) {
          container.classList.remove("mmc-visible")
        }
      }
    }
  })
}

function updateSelectedCount() {
  const copyButton = document.querySelector("#mmc-copy")
  const counter = document.querySelector(".mmc-counter span")

  if (copyButton) {
    copyButton.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
        <path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/>
      </svg>
      Copy (${selectedMessages.size})
    `
    const button = copyButton as HTMLButtonElement
    button.disabled = selectedMessages.size === 0
  }

  if (counter) {
    counter.textContent = `${selectedMessages.size} selected`
  }
}

const messageContextMenuPatch = (children: any[], props: any) => {
  const { message, channel } = props

  if (!message || !channel) return

  children.push(
    <Menu.MenuSeparator />,
    <Menu.MenuItem
      id="select-messages"
      label={isSelectionMode ? "Exit Selection Mode" : "Select Messages"}
      action={() => {
        if (isSelectionMode) {
          exitSelectionMode()
        } else {
          enterSelectionMode(channel.id)
        }
      }}
    />,
  )
}

export default definePlugin({
  name: "MultiMessageCopy",
  description: "Enhanced Discord message selection and copying with beautiful UI/UX",
  authors: [
    {
      name: "dewushka.0",
      id: 1053088103256035419n,
    },
  ],

  settings,

  contextMenus: {
    message: messageContextMenuPatch,
  },

  start() {
    console.log("Enhanced MultiMessageCopy Plugin started")
  },

  stop() {
    console.log("Enhanced MultiMessageCopy Plugin stopped")
    if (isSelectionMode) {
      exitSelectionMode()
    }
  },
})
