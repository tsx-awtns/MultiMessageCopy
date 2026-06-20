/**
 * hooks/selectionState.ts
 *
 * Shared mutable state for the current selection session.
 */

import { Message } from "../types"

export let isSelectionMode = false
export const selectedMessages = new Map<string, Message>()
export let currentChannelId = ""
export let observer: MutationObserver | null = null
export let keyboardListener: ((e: KeyboardEvent) => void) | null = null
export let selectionStarted = false

export function setIsSelectionMode(value: boolean): void {
  isSelectionMode = value
}

export function setCurrentChannelId(value: string): void {
  currentChannelId = value
}

export function setObserver(value: MutationObserver | null): void {
  observer = value
}

export function setKeyboardListener(
  value: ((e: KeyboardEvent) => void) | null,
): void {
  keyboardListener = value
}

export function setSelectionStarted(value: boolean): void {
  selectionStarted = value
}
