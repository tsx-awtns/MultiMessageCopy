/**
 * htmlExport/markdown.ts
 *
 * Safe Discord-flavoured Markdown renderer for the HTML export.
 */

import { escapeAttribute, escapeHtml } from "./safety"
import type { ParticipantMap } from "./users"
import { participantDisplayName } from "./users"

type TokenMap = Map<string, string>

let _counter = 0

function nextToken(): string {
  return `\x02T${(_counter++).toString(36).toUpperCase()}\x03`
}

function replaceAll(src: string, needle: string, replacement: string): string {
  return src.split(needle).join(replacement)
}

export function extractCodeBlocks(raw: string, tokens: TokenMap): string {
  return raw.replace(
    /```([^\n`]*)\n?([\s\S]*?)```/g,
    (_, rawLang, code) => {
      const lang = rawLang.trim()
      const safeCode = escapeHtml(code)
      const langAttr = lang ? ` data-lang="${escapeAttribute(lang)}"` : ""
      const langLabel = lang
        ? `<span class="code-language" aria-hidden="true">${escapeHtml(lang)}</span>`
        : ""
      const html =
        `<div class="code-block-wrap"${langAttr}>` +
        langLabel +
        `<pre class="code-block"><code>${safeCode}</code></pre>` +
        `</div>`
      const tok = nextToken()
      tokens.set(tok, html)
      return tok
    }
  )
}

export function extractInlineCode(raw: string, tokens: TokenMap): string {
  let out = raw.replace(/``([^`]+)``/g, (_, code) => {
    const html = `<code class="inline-code">${escapeHtml(code)}</code>`
    const tok = nextToken()
    tokens.set(tok, html)
    return tok
  })
  out = out.replace(/`([^`\n]+)`/g, (_, code) => {
    const html = `<code class="inline-code">${escapeHtml(code)}</code>`
    const tok = nextToken()
    tokens.set(tok, html)
    return tok
  })
  return out
}

export function extractCustomEmojis(raw: string, tokens: TokenMap): string {
  return raw.replace(
    /<(a?):([A-Za-z0-9_]{1,32}):(\d{17,20})>/g,
    (_, animated, name, id) => {
      const ext = animated === "a" ? "gif" : "webp"
      const src = `https://cdn.discordapp.com/emojis/${id}.${ext}?size=48&quality=lossless`
      const safeName = escapeAttribute(name)
      const safeSrc = escapeAttribute(src)
      const html =
        `<img class="custom-emoji" ` +
        `src="${safeSrc}" ` +
        `alt=":${safeName}:" ` +
        `title=":${safeName}:" ` +
        `aria-label=":${safeName}:" ` +
        `loading="lazy" ` +
        `data-missing-fallback="true" ` +
        `data-emoji-name="${safeName}">`
      const tok = nextToken()
      tokens.set(tok, html)
      return tok
    }
  )
}

function renderBlockquotes(escaped: string): string {
  escaped = escaped.replace(
    /^&gt;&gt;&gt; ([\s\S]*)$/m,
    (_, content) =>
      `<blockquote class="blockquote">${content.trimEnd()}</blockquote>`
  )
  escaped = escaped.replace(
    /^&gt; (.+)$/gm,
    (_, content) =>
      `<blockquote class="blockquote blockquote-inline">${content}</blockquote>`
  )
  return escaped
}

function renderHeadings(escaped: string): string {
  return escaped
    .replace(
      /^### (.+)$/gm,
      (_, t) => `<h3 class="markdown-heading markdown-h3">${t}</h3>`
    )
    .replace(
      /^## (.+)$/gm,
      (_, t) => `<h2 class="markdown-heading markdown-h2">${t}</h2>`
    )
    .replace(
      /^# (.+)$/gm,
      (_, t) => `<h1 class="markdown-heading markdown-h1">${t}</h1>`
    )
}

function renderLists(escaped: string): string {
  escaped = escaped.replace(
    /((?:^[-*] .+$\n?)+)/gm,
    (block) => {
      const items = block
        .trim()
        .split(/\n/)
        .map(line => line.replace(/^[-*] /, "").trim())
        .filter(Boolean)
        .map(item => `<li>${item}</li>`)
        .join("")
      return `<ul class="markdown-list markdown-ul">${items}</ul>`
    }
  )
  escaped = escaped.replace(
    /((?:^\d+\. .+$\n?)+)/gm,
    (block) => {
      const items = block
        .trim()
        .split(/\n/)
        .map(line => line.replace(/^\d+\. /, "").trim())
        .filter(Boolean)
        .map(item => `<li>${item}</li>`)
        .join("")
      return `<ol class="markdown-list markdown-ol">${items}</ol>`
    }
  )
  return escaped
}

function applyInlineFormatting(text: string): string {
  text = text.replace(
    /\*{3}(.+?)\*{3}/gs,
    (_, c) =>
      `<strong class="markdown-bold"><em class="markdown-italic">${c}</em></strong>`
  )
  text = text.replace(
    /__\*{2}(.+?)\*{2}__/gs,
    (_, c) =>
      `<u class="markdown-underline"><strong class="markdown-bold">${c}</strong></u>`
  )
  text = text.replace(
    /\*{2}(.+?)\*{2}/gs,
    (_, c) => `<strong class="markdown-bold">${c}</strong>`
  )
  text = text.replace(
    /__(.+?)__/gs,
    (_, c) => `<u class="markdown-underline">${c}</u>`
  )
  text = text.replace(
    /\*(.+?)\*/gs,
    (_, c) => `<em class="markdown-italic">${c}</em>`
  )
  text = text.replace(
    /_(.+?)_/gs,
    (_, c) => `<em class="markdown-italic">${c}</em>`
  )
  text = text.replace(
    /~~(.+?)~~/gs,
    (_, c) => `<s class="markdown-strike">${c}</s>`
  )
  text = text.replace(
    /\|\|(.+?)\|\|/gs,
    (_, c) =>
      `<span class="spoiler" role="button" tabindex="0" ` +
      `aria-label="Spoiler (click to reveal)">${c}</span>`
  )
  return text
}

function renderInlineFormatting(mixed: string): string {
  const parts = mixed.split(/(<[^>]+>)/g)
  return parts
    .map((part, i) => (i % 2 === 0 ? applyInlineFormatting(part) : part))
    .join("")
}

function resolveMentions(
  escaped: string,
  participants: ParticipantMap
): string {
  escaped = escaped.replace(/&lt;@!?(\d+)&gt;/g, (_, id) => {
    const p = participants.get(id)
    const name = escapeHtml(p ? participantDisplayName(p) : id)
    return `<span class="mention" title="User ID: ${escapeAttribute(id)}">@${name}</span>`
  })
  escaped = escaped.replace(
    /&lt;#(\d+)&gt;/g,
    (_, id) => `<span class="mention">#${escapeHtml(id)}</span>`
  )
  escaped = escaped.replace(
    /&lt;@&amp;(\d+)&gt;/g,
    (_, id) =>
      `<span class="mention role-mention">@role-${escapeHtml(id)}</span>`
  )
  return escaped
}

function renderLinks(mixed: string, suppressSet: Set<string>): string {
  const parts = mixed.split(/(<[^>]+>)/g)
  return parts
    .map((part, i) => {
      if (i % 2 !== 0) return part
      return part.replace(/(https?:\/\/[^\s<>"'&]+)/g, (url) => {
        if (suppressSet.has(url)) {
          return (
            `<span class="suppressed-url">` +
            `<a class="link muted-link" href="${escapeAttribute(url)}" ` +
            `target="_blank" rel="noopener noreferrer">${url}</a>` +
            `</span>`
          )
        }
        return (
          `<a class="link" href="${escapeAttribute(url)}" ` +
          `target="_blank" rel="noopener noreferrer">${url}</a>`
        )
      })
    })
    .join("")
}

function restoreTokens(mixed: string, tokens: TokenMap): string {
  let out = mixed
  for (const [tok, html] of tokens) {
    out = replaceAll(out, tok, html)
  }
  return out
}

export interface RenderContext {
  participants: ParticipantMap
  suppressUrls?: Set<string>
}

export function renderDiscordMarkdown(
  content: string,
  ctx: RenderContext
): string {
  const tokens: TokenMap = new Map()
  const suppress = ctx.suppressUrls ?? new Set<string>()

  let out = extractCodeBlocks(content, tokens)
  out = extractInlineCode(out, tokens)
  out = extractCustomEmojis(out, tokens)

  out = escapeHtml(out)

  out = renderBlockquotes(out)
  out = renderHeadings(out)
  out = renderLists(out)
  out = renderInlineFormatting(out)

  out = resolveMentions(out, ctx.participants)

  out = renderLinks(out, suppress)

  out = restoreTokens(out, tokens)

  out = out.replace(/\n/g, "<br>")

  return out
}
