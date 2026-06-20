/**
 * htmlExport/styles.ts
 *
 * Fully premium HTML export CSS.
 * Dark glass UI, rich color system, animated effects, layered depth.
 */

export const HTML_EXPORT_CSS = `
/* ── Reset ── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

/* ── Design Tokens ── */
:root {
  /* === Layered backgrounds === */
  --bg-base:        #0b0c0e;
  --bg-1:           #111214;
  --bg-2:           #18191c;
  --bg-3:           #1e1f22;
  --bg-4:           #232428;
  --bg-5:           #282b30;
  --bg-6:           #2e3035;
  --bg-elevated:    #36393f;
  --bg-hover:       rgba(255,255,255,0.03);
  --bg-hover-strong:rgba(255,255,255,0.055);
  --bg-active:      rgba(255,255,255,0.08);

  /* === Glass === */
  --glass-bg:       rgba(28,29,33,0.82);
  --glass-border:   rgba(255,255,255,0.06);
  --glass-blur:     blur(18px) saturate(180%);

  /* === Borders === */
  --border-hair:    rgba(255,255,255,0.025);
  --border-faint:   rgba(255,255,255,0.05);
  --border-subtle:  rgba(255,255,255,0.08);
  --border-muted:   rgba(255,255,255,0.12);
  --border-strong:  rgba(255,255,255,0.18);
  --border-bright:  rgba(255,255,255,0.28);

  /* === Text hierarchy === */
  --text-white:     #ffffff;
  --text-primary:   #f2f3f5;
  --text-normal:    #dcddde;
  --text-secondary: #b5bac1;
  --text-muted:     #80848e;
  --text-faint:     #4e5058;
  --text-ghost:     #2e3035;

  /* === Accent — electric indigo === */
  --accent:         #5865f2;
  --accent-light:   #7289da;
  --accent-hover:   #4752c4;
  --accent-active:  #3c45a5;
  --accent-dim:     rgba(88,101,242,0.20);
  --accent-soft:    rgba(88,101,242,0.12);
  --accent-glow:    rgba(88,101,242,0.35);
  --accent-glow-lg: rgba(88,101,242,0.18);

  /* === Semantic === */
  --link:           #00aff4;
  --link-hover:     #53d7ff;
  --link-dim:       rgba(0,175,244,0.15);
  --success:        #23a559;
  --success-soft:   rgba(35,165,89,0.15);
  --warning:        #f0b232;
  --warning-soft:   rgba(240,178,50,0.13);
  --danger:         #da373c;
  --danger-soft:    rgba(218,55,60,0.14);
  --info:           #00b0f4;
  --info-soft:      rgba(0,176,244,0.12);
  --mention-bg:     rgba(88,101,242,0.18);
  --mention-hover:  rgba(88,101,242,0.32);

  /* === Radius scale === */
  --r-xs:   3px;
  --r-sm:   6px;
  --r-md:   8px;
  --r-lg:   12px;
  --r-xl:   16px;
  --r-2xl:  20px;
  --r-pill: 999px;

  /* === Shadows === */
  --shadow-xs:  0 1px 2px rgba(0,0,0,0.40);
  --shadow-sm:  0 2px 8px rgba(0,0,0,0.50);
  --shadow-md:  0 4px 16px rgba(0,0,0,0.55);
  --shadow-lg:  0 8px 30px rgba(0,0,0,0.65);
  --shadow-xl:  0 16px 50px rgba(0,0,0,0.75);
  --shadow-2xl: 0 32px 80px rgba(0,0,0,0.85);
  --glow-accent:0 0 24px rgba(88,101,242,0.22);
  --glow-media: 0 0 16px rgba(0,0,0,0.60);

  /* === Transitions === */
  --t-fast: 90ms cubic-bezier(0.2,0,0.1,1);
  --t-base: 150ms cubic-bezier(0.2,0,0.1,1);
  --t-slow: 250ms cubic-bezier(0.2,0,0.1,1);
  --t-spring: 220ms cubic-bezier(0.34,1.56,0.64,1);

  /* === Typography === */
  --font-sans: "gg sans","Noto Sans","Helvetica Neue",Helvetica,Arial,sans-serif;
  --font-mono: "Consolas","Andale Mono WT","Andale Mono","Lucida Console",monospace;
  --font-display: "gg sans","Noto Sans",sans-serif;
}

/* ── Base ── */
html, body { height: 100%; }

body {
  background: var(--bg-base);
  color: var(--text-normal);
  font-family: var(--font-sans);
  font-size: 16px;
  line-height: 1.375;
  overflow: hidden;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

/* ── Scrollbar ── */
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb {
  background: rgba(255,255,255,0.06);
  border-radius: 4px;
  border: 2px solid transparent;
  background-clip: content-box;
  transition: background var(--t-base);
}
::-webkit-scrollbar-thumb:hover {
  background: rgba(255,255,255,0.14);
  background-clip: content-box;
}

/* ── App shell ── */
.app-shell {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: var(--bg-base);
}

/* ── Sidebar ── */
.sidebar {
  width: 244px;
  min-width: 244px;
  background: var(--bg-2);
  display: flex;
  flex-direction: column;
  padding: 18px 12px 18px;
  gap: 2px;
  overflow-y: auto;
  border-right: 1px solid var(--border-faint);
  flex-shrink: 0;
  position: relative;
}

.sidebar::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: linear-gradient(180deg, rgba(88,101,242,0.035) 0%, transparent 35%);
}

.server-icon {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  background: linear-gradient(145deg, var(--accent), var(--accent-light));
  color: #fff;
  font-size: 20px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin: 0 6px 14px;
  overflow: hidden;
  box-shadow: var(--shadow-md), var(--glow-accent), 0 0 0 1px var(--border-subtle);
  transition: border-radius var(--t-slow), box-shadow var(--t-slow);
}
.server-icon:hover {
  border-radius: 50%;
  box-shadow: var(--shadow-lg), 0 0 28px rgba(88,101,242,0.4), 0 0 0 1px var(--border-muted);
}
.server-icon img { width: 100%; height: 100%; object-fit: cover; border-radius: inherit; }

.sidebar-dm-name {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-primary);
  padding: 4px 8px 8px;
  letter-spacing: 0.01em;
}

.sidebar-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--border-faint) 30%, var(--border-faint) 70%, transparent);
  margin: 8px 6px;
}

.sidebar-section { padding: 2px 8px 8px; }

.sidebar-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin-bottom: 4px;
}

.sidebar-value {
  font-size: 12.5px;
  color: var(--text-secondary);
  word-break: break-word;
  line-height: 1.5;
}

.sidebar-meta-row {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 5px 8px;
  border-radius: var(--r-md);
  font-size: 12.5px;
  color: var(--text-muted);
  transition: background var(--t-fast), color var(--t-fast);
}
.sidebar-meta-row:hover { background: var(--bg-hover-strong); color: var(--text-secondary); }
.sidebar-meta-row svg { flex-shrink: 0; color: var(--text-faint); opacity: 0.7; }

.sidebar-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--bg-3);
  border: 1px solid var(--border-subtle);
  border-radius: var(--r-pill);
  padding: 4px 12px;
  font-size: 11.5px;
  color: var(--text-muted);
  margin: 2px 8px 0;
  width: fit-content;
}
.sidebar-badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--success);
  flex-shrink: 0;
  box-shadow: 0 0 6px var(--success);
}

/* ── Chat area ── */
.chat {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: var(--bg-4);
  min-width: 0;
  position: relative;
}

/* Subtle noise texture overlay */
.chat::before {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.025'/%3E%3C/svg%3E");
  opacity: 0.3;
  z-index: 0;
}

/* ── Chat header ── */
.chat-header {
  height: 49px;
  min-height: 49px;
  background: var(--bg-4);
  border-bottom: 1px solid var(--border-faint);
  display: flex;
  align-items: center;
  padding: 0 18px;
  gap: 11px;
  flex-shrink: 0;
  box-shadow: 0 1px 0 rgba(0,0,0,0.30);
  position: relative;
  z-index: 2;
}

.chat-header-icon { color: var(--text-faint); flex-shrink: 0; opacity: 0.7; }

.chat-header-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-primary);
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  letter-spacing: -0.015em;
}

.chat-header-meta {
  font-size: 12px;
  color: var(--text-faint);
  white-space: nowrap;
  background: var(--bg-2);
  border: 1px solid var(--border-faint);
  border-radius: var(--r-pill);
  padding: 3px 12px;
  font-variant-numeric: tabular-nums;
}

/* ── Search / filter bar ── */
.search-bar {
  background: var(--bg-3);
  border-bottom: 1px solid var(--border-faint);
  padding: 10px 18px 9px;
  display: flex;
  flex-direction: column;
  gap: 9px;
  flex-shrink: 0;
  position: relative;
  z-index: 2;
  box-shadow: 0 1px 0 rgba(0,0,0,0.18);
}

.search-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

/* Search input wrap */
.search-input-wrap {
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 160px;
  background: var(--bg-1);
  border: 1px solid var(--border-muted);
  border-radius: var(--r-md);
  padding: 0 6px 0 10px;
  gap: 7px;
  transition: border-color var(--t-base), box-shadow var(--t-base);
}
.search-input-wrap:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-soft), 0 0 0 1px var(--accent);
}

.search-icon { color: var(--text-faint); flex-shrink: 0; opacity: 0.65; }

.search-input {
  background: transparent;
  border: none;
  outline: none;
  color: var(--text-normal);
  font-size: 13.5px;
  font-family: var(--font-sans);
  padding: 7px 0;
  flex: 1;
  min-width: 0;
}
.search-input::placeholder { color: var(--text-faint); }
.search-input::-webkit-search-cancel-button { display: none; }

.search-clear-btn {
  background: transparent;
  border: none;
  color: var(--text-faint);
  cursor: pointer;
  padding: 4px;
  border-radius: var(--r-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--t-fast), background var(--t-fast), color var(--t-fast);
  flex-shrink: 0;
}
.search-input-wrap:focus-within .search-clear-btn,
.search-input-wrap.has-value .search-clear-btn {
  opacity: 1;
  pointer-events: auto;
}
.search-clear-btn:hover { background: var(--bg-active); color: var(--text-primary); }

/* User dropdown */
.search-select {
  background: var(--bg-1);
  border: 1px solid var(--border-muted);
  border-radius: var(--r-md);
  color: var(--text-secondary);
  font-size: 13px;
  font-family: var(--font-sans);
  padding: 7px 10px;
  outline: none;
  cursor: pointer;
  min-width: 110px;
  max-width: 180px;
  transition: border-color var(--t-base), box-shadow var(--t-base), color var(--t-base);
}
.search-select:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-soft);
  color: var(--text-normal);
}
.search-select option { background: var(--bg-4); }

/* ── Filter chips ── */
.search-filters-row { align-items: center; }

.filter-chips {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 11px 4px 7px;
  border-radius: var(--r-pill);
  border: 1px solid var(--border-subtle);
  background: var(--bg-3);
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
  transition: background var(--t-base), border-color var(--t-base),
              color var(--t-base), box-shadow var(--t-base);
  position: relative;
}

.filter-chip:hover {
  background: var(--bg-6);
  border-color: var(--border-muted);
  color: var(--text-secondary);
}

.filter-chip:has(.filter-chip-input:checked) {
  background: var(--accent-dim);
  border-color: rgba(88,101,242,0.45);
  color: #c9cdfb;
  box-shadow: 0 0 0 1px rgba(88,101,242,0.14), 0 0 10px rgba(88,101,242,0.10);
}

.filter-chip:has(.filter-chip-input:checked):hover {
  background: rgba(88,101,242,0.26);
  border-color: rgba(88,101,242,0.65);
  color: #dde0ff;
}

.filter-chip:has(.filter-chip-input:focus-visible) {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

.filter-chip-input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
  pointer-events: none;
}

.filter-chip-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 15px;
  height: 15px;
  border-radius: 4px;
  background: var(--bg-5);
  border: 1px solid var(--border-subtle);
  flex-shrink: 0;
  transition: background var(--t-base), border-color var(--t-base), box-shadow var(--t-base);
}
.filter-chip:hover .filter-chip-icon { background: var(--bg-elevated); border-color: var(--border-muted); }
.filter-chip:has(.filter-chip-input:checked) .filter-chip-icon {
  background: var(--accent);
  border-color: transparent;
  box-shadow: 0 0 6px var(--accent-glow);
}

.filter-chip-icon svg { stroke: var(--text-faint); transition: stroke var(--t-base); }
.filter-chip:has(.filter-chip-input:checked) .filter-chip-icon svg { stroke: #fff; }
.filter-chip-label { line-height: 1; }

/* ── Search spacer + navigation ── */
.search-spacer { flex: 1; min-width: 4px; }

.search-nav { display: flex; align-items: center; gap: 3px; }

.search-result-count {
  font-size: 12px;
  color: var(--text-faint);
  white-space: nowrap;
  min-width: 60px;
  text-align: right;
  font-variant-numeric: tabular-nums;
  padding-right: 4px;
}

.search-nav-btn {
  background: var(--bg-3);
  border: 1px solid var(--border-subtle);
  border-radius: var(--r-sm);
  color: var(--text-muted);
  width: 27px;
  height: 27px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  padding: 0;
  transition: background var(--t-fast), color var(--t-fast), border-color var(--t-fast),
              box-shadow var(--t-fast);
  flex-shrink: 0;
}
.search-nav-btn:hover:not(:disabled) {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
  box-shadow: 0 0 10px var(--accent-glow);
}
.search-nav-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.search-nav-btn:disabled { opacity: 0.28; cursor: default; }

/* ── Messages container ── */
.messages {
  flex: 1;
  overflow-y: auto;
  padding: 0 0 64px;
  display: flex;
  flex-direction: column;
  position: relative;
  z-index: 1;
}

/* ── Begin-of-chat header ── */
.messages-begin {
  padding: 36px 24px 24px;
  position: relative;
}

.messages-begin-icon {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: linear-gradient(145deg, var(--accent) 0%, #7289da 55%, #8ea1e1 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  box-shadow: var(--shadow-lg), var(--glow-accent), 0 0 0 1px rgba(88,101,242,0.30);
  position: relative;
}

.messages-begin-icon::after {
  content: "";
  position: absolute;
  inset: -3px;
  border-radius: 50%;
  background: conic-gradient(
    from 0deg,
    transparent 0%,
    rgba(88,101,242,0.5) 25%,
    transparent 50%,
    rgba(114,137,218,0.4) 75%,
    transparent 100%
  );
  animation: spinRing 6s linear infinite;
  opacity: 0.6;
  z-index: -1;
}

@keyframes spinRing { to { transform: rotate(360deg); } }

.messages-begin-title {
  font-size: 30px;
  font-weight: 900;
  color: var(--text-primary);
  margin-bottom: 6px;
  letter-spacing: -0.03em;
  line-height: 1.1;
}

.messages-begin-sub {
  font-size: 13.5px;
  color: var(--text-muted);
  border-top: 1px solid var(--border-faint);
  margin-top: 12px;
  padding-top: 10px;
  line-height: 1.55;
}

/* ── Date separator ── */
.date-separator {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 24px 24px 8px;
  pointer-events: none;
  user-select: none;
}

.date-separator-line {
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--border-faint) 20%, var(--border-faint) 80%, transparent);
}

.date-separator-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-faint);
  letter-spacing: 0.055em;
  text-transform: uppercase;
  background: var(--bg-4);
  border: 1px solid var(--border-faint);
  border-radius: var(--r-pill);
  padding: 3px 12px;
  white-space: nowrap;
}

/* ── Message rows ── */
.message {
  display: flex;
  align-items: flex-start;
  padding: 3px 24px;
  transition: background var(--t-fast);
  position: relative;
}

/* Hover accent bar on left edge */
.message::before {
  content: "";
  position: absolute;
  left: 0;
  top: 4px;
  bottom: 4px;
  width: 2px;
  border-radius: 0 2px 2px 0;
  background: var(--accent);
  opacity: 0;
  transition: opacity var(--t-fast);
}

.message:hover { background: var(--bg-hover); }
.message:hover::before { opacity: 0.45; }

.message-grouped { padding-top: 1px; padding-bottom: 1px; }

/* Highlighted / selected message */
.message.highlighted {
  background: var(--accent-soft) !important;
}
.message.highlighted::before { opacity: 1 !important; }

/* ── Avatar column ── */
.avatar-slot {
  width: 56px;
  min-width: 56px;
  flex-shrink: 0;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 3px;
}

.avatar-slot-grouped {
  align-items: center;
  justify-content: flex-end;
  padding-right: 12px;
}

/* Grouped timestamp (revealed on hover) */
.grouped-timestamp {
  font-size: 10px;
  color: var(--text-faint);
  line-height: 1.375rem;
  opacity: 0;
  transition: opacity var(--t-fast);
  pointer-events: none;
  user-select: none;
  white-space: nowrap;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
.message:hover .grouped-timestamp { opacity: 1; }

/* ── Message main content column ── */
.message-main {
  flex: 1;
  min-width: 0;
  padding-top: 3px;
  padding-bottom: 3px;
}

.message-header {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 2px;
  flex-wrap: wrap;
}

/* ── Avatar ── */
.avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  overflow: hidden;
  transition: opacity var(--t-fast), filter var(--t-fast), box-shadow var(--t-fast);
}
.avatar:hover {
  opacity: 0.9;
  filter: brightness(1.08);
  box-shadow: 0 0 0 3px rgba(88,101,242,0.35);
}
.avatar:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

.avatar-img {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  display: block;
}

/* ── Author name + timestamp ── */
.msg-author {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  cursor: pointer;
  line-height: 1.375;
  transition: color var(--t-fast);
}
.msg-author:hover {
  color: var(--text-white);
  text-decoration: underline;
  text-underline-offset: 2px;
  text-decoration-color: rgba(255,255,255,0.35);
}

.msg-time {
  font-size: 11px;
  color: var(--text-faint);
  line-height: 1.375;
  font-variant-numeric: tabular-nums;
  letter-spacing: 0.01em;
}

/* ── Message text content ── */
.message-content {
  font-size: 15px;
  color: var(--text-normal);
  word-break: break-word;
  line-height: 1.4375rem;
}

/* ── Media / attachments / embeds container spacing ── */
.media-container { margin-top: 6px; display: flex; flex-direction: column; gap: 6px; }
.embeds         { margin-top: 6px; display: flex; flex-direction: column; gap: 6px; }
.stickers       { margin-top: 6px; }

/* ── Reply preview — Discord-accurate ── */

/*
  Layout:
    [connector-svg] [avatar] [author-name] [content-preview]

  The connector SVG draws a curved line from the left that visually
  "comes from" the avatar column and points right at the reply bar.
*/
.reply-preview {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 0 0 4px 14px;    /* left-align under the avatar column */
  font-size: 0.8125rem;      /* 13px */
  color: var(--text-muted);
  min-height: 20px;
  position: relative;
}

/* Curved connector — matches Discord's curved reply line */
.reply-connector {
  width: 44px;
  height: 24px;
  flex-shrink: 0;
  color: var(--border-muted);
  margin-right: 4px;
  margin-top: 2px;
  align-self: flex-end;
}

/* Clickable reply bar — flex row of [avatar] [name] [content] */
.reply-body {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
  max-width: 520px;
  text-decoration: none;
  color: var(--text-muted);
  border-radius: var(--r-xs);
  padding: 1px 4px 1px 2px;
  transition: background var(--t-fast), color var(--t-fast);
  cursor: pointer;
}
.reply-body:hover {
  background: var(--bg-hover-strong);
  color: var(--text-secondary);
}
.reply-body:hover .reply-author { color: var(--text-primary); }
.reply-body:hover .reply-content { color: var(--text-secondary); }

/* Tiny avatar */
.reply-avatar {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  opacity: 0.9;
}
.reply-avatar-fallback {
  display: inline-block;
  background: var(--bg-5);
  border-radius: 50%;
}

/* Author name — blurple accent */
.reply-author {
  font-weight: 500;
  color: var(--text-secondary);
  white-space: nowrap;
  flex-shrink: 0;
  transition: color var(--t-fast);
}

/* Content preview text — truncated single line */
.reply-content {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
  min-width: 0;
  color: var(--text-muted);
  transition: color var(--t-fast);
}

/* Deleted / unavailable original */
.reply-content-deleted {
  font-style: italic;
  color: var(--text-faint);
}

/* Media-only fallback */
.reply-content-media {
  font-style: italic;
  color: var(--text-faint);
}

/* ── Forward badge — Discord-accurate ── */

/*
  Layout:
    [arrow-icon] "Forwarded" [sep ·] [tiny-avatar] [from-name]
*/
.forward-badge {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 0 0 5px 14px;
  font-size: 0.75rem;        /* 12px */
  color: var(--text-faint);
  line-height: 1;
  user-select: none;
}

/* The forward arrow icon */
.forward-icon {
  flex-shrink: 0;
  color: var(--text-faint);
  opacity: 0.75;
}

/* "Forwarded" label text */
.forward-label {
  font-weight: 500;
  color: var(--text-faint);
  letter-spacing: 0.01em;
}

/* · separator */
.forward-sep {
  color: var(--text-ghost);
}

/* Original author avatar (14px) */
.forward-avatar {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  opacity: 0.75;
}

/* Original author name */
.forward-from {
  font-weight: 500;
  color: var(--text-faint);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 200px;
}

/* ── Inline formatting ── */
.mention {
  background: var(--mention-bg);
  color: #c9cdfb;
  border-radius: var(--r-xs);
  padding: 0 4px;
  cursor: default;
  font-weight: 500;
  transition: background var(--t-fast), color var(--t-fast);
}
.mention:hover { background: var(--mention-hover); color: #fff; }

.role-mention {
  background: rgba(240,178,50,0.15);
  color: #d9a72b;
}
.role-mention:hover { background: rgba(240,178,50,0.28); color: #f0b232; }

.link { color: var(--link); text-decoration: none; }
.link:hover {
  text-decoration: underline;
  text-underline-offset: 2px;
  color: var(--link-hover);
}
.muted-link { color: var(--text-faint); font-size: 12px; }
.suppressed-url { display: none; }

.inline-code {
  background: var(--bg-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--r-xs);
  padding: 1px 6px;
  font-family: var(--font-mono);
  font-size: 87%;
  color: #e3e5e8;
  white-space: pre-wrap;
}

/* ── Code blocks ── */
.code-block-wrap {
  position: relative;
  background: var(--bg-1);
  border: 1px solid var(--border-faint);
  border-radius: var(--r-md);
  margin: 6px 0;
  max-width: 100%;
  overflow: hidden;
  box-shadow: var(--shadow-xs);
}

.code-language {
  display: block;
  font-family: var(--font-mono);
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--text-faint);
  padding: 8px 14px 7px;
  user-select: none;
  border-bottom: 1px solid var(--border-faint);
  background: rgba(255,255,255,0.015);
}

.code-block {
  margin: 0;
  padding: 10px 14px 13px;
  overflow-x: auto;
  white-space: pre;
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.55;
  color: var(--text-normal);
  background: transparent;
  border: none;
  border-radius: 0;
  tab-size: 2;
}

/* ── Blockquote ── */
.blockquote {
  border-left: 3px solid var(--border-muted);
  padding: 2px 0 2px 14px;
  margin: 3px 0;
  color: var(--text-normal);
}
.blockquote-inline { display: block; }

/* ── Headings / lists ── */
.markdown-heading {
  color: var(--text-primary);
  font-weight: 700;
  line-height: 1.2;
  margin: 8px 0 3px;
}
.markdown-h1 { font-size: 1.5em; border-bottom: 1px solid var(--border-faint); padding-bottom: 6px; }
.markdown-h2 { font-size: 1.25em; }
.markdown-h3 { font-size: 1.05em; }

.markdown-list { padding-left: 20px; margin: 4px 0; color: var(--text-normal); }
.markdown-ul { list-style-type: disc; }
.markdown-ol { list-style-type: decimal; }
.markdown-list li { margin: 2px 0; line-height: 1.45; }

.markdown-bold { font-weight: 700; }
.markdown-italic { font-style: italic; }
.markdown-underline { text-decoration: underline; text-underline-offset: 2px; }
.markdown-strike { text-decoration: line-through; color: var(--text-muted); }

.spoiler {
  background: var(--bg-3);
  color: transparent;
  border-radius: var(--r-xs);
  padding: 0 4px;
  cursor: pointer;
  transition: background var(--t-base), color var(--t-base);
  user-select: none;
  border: 1px solid var(--border-subtle);
}
.spoiler:hover, .spoiler.revealed { background: var(--bg-elevated); color: var(--text-normal); }

/* ── Emoji ── */
.custom-emoji {
  display: inline-block;
  width: 22px;
  height: 22px;
  vertical-align: middle;
  object-fit: contain;
  border-radius: 3px;
  margin: 0 1px;
}

.emoji-fallback-pill {
  display: inline-block;
  vertical-align: middle;
  background: var(--bg-4);
  border: 1px solid var(--border-faint);
  border-radius: 4px;
  padding: 1px 5px;
  font-size: 12px;
  color: var(--text-muted);
  font-family: var(--font-mono);
  margin: 0 1px;
}

/* ── Attachments wrapper ── */
.msg-attachments { display: flex; flex-direction: column; gap: 7px; }

/* ── Image grid ── */
.media-grid { display: grid; gap: 3px; }
.media-grid-1   { grid-template-columns: 1fr; max-width: 420px; }
.media-grid-2   { grid-template-columns: 1fr 1fr; max-width: 420px; }
.media-grid-many { grid-template-columns: 1fr 1fr; max-width: 420px; }

/* ── Image preview card ── */
.media-preview {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  cursor: zoom-in;
  border-radius: var(--r-md);
  overflow: hidden;
  background: var(--bg-2);
  transition: filter var(--t-base), transform var(--t-base), box-shadow var(--t-base);
  box-shadow: var(--shadow-sm), 0 0 0 1px var(--border-faint);
}
.media-preview:hover {
  filter: brightness(1.06) saturate(1.06);
  transform: scale(1.008);
  box-shadow: var(--glow-media), var(--shadow-md), 0 0 0 1px var(--border-muted);
}
.media-preview:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

.media-img {
  display: block;
  max-width: 100%;
  max-height: 350px;
  width: 100%;
  height: auto;
  object-fit: contain;
  background: var(--bg-2);
}
.media-grid-2 .media-img,
.media-grid-many .media-img {
  max-height: 200px;
  object-fit: cover;
  width: 100%;
}

.media-filename {
  font-size: 11px;
  color: var(--text-secondary);
  padding: 4px 8px;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
  background: var(--bg-1);
  border-top: 1px solid var(--border-faint);
}

/* GIF / type badge */
.media-badge {
  position: absolute;
  bottom: 6px;
  left: 6px;
  padding: 2px 7px;
  border-radius: var(--r-xs);
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  pointer-events: none;
}
.gif-badge {
  background: rgba(0,0,0,0.76);
  color: #fff;
  backdrop-filter: blur(6px);
  border: 1px solid rgba(255,255,255,0.12);
}

/* ── Video card ── */
.video-wrap {
  display: flex;
  flex-direction: column;
  background: var(--bg-2);
  border: 1px solid var(--border-faint);
  border-radius: var(--r-md);
  overflow: hidden;
  max-width: 440px;
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--t-base), border-color var(--t-base);
}
.video-wrap:hover {
  box-shadow: var(--shadow-md);
  border-color: var(--border-subtle);
}

.media-video {
  display: block;
  max-width: 100%;
  max-height: 340px;
  width: 100%;
  background: var(--bg-1);
}

.video-caption {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: var(--bg-2);
  border-top: 1px solid var(--border-faint);
}

.video-caption-name {
  font-size: 12px;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
  min-width: 0;
}

.att-fallback-link {
  font-size: 12px;
  color: var(--link);
  text-decoration: none;
  padding: 6px 12px;
  background: var(--bg-2);
  border-top: 1px solid var(--border-faint);
  display: block;
  transition: color var(--t-fast), background var(--t-fast);
}
.att-fallback-link:hover { color: var(--link-hover); background: var(--bg-3); }

/* ── Audio card ── */
.audio-wrap {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  background: var(--bg-2);
  border: 1px solid var(--border-faint);
  border-left: 3px solid var(--accent);
  border-radius: var(--r-md);
  padding: 12px 16px;
  max-width: 420px;
  box-shadow: var(--shadow-xs);
  transition: border-color var(--t-base), box-shadow var(--t-base), background var(--t-base);
}
.audio-wrap:hover {
  background: var(--bg-3);
  box-shadow: var(--shadow-sm);
}

.audio-icon { color: var(--accent); flex-shrink: 0; margin-top: 1px; }
.audio-info { display: flex; flex-direction: column; gap: 8px; flex: 1; min-width: 0; }
.audio-player { width: 100%; }

/* ── Generic file attachment card ── */
.att-card {
  display: flex;
  align-items: center;
  gap: 13px;
  background: var(--bg-2);
  border: 1px solid var(--border-faint);
  border-left: 3px solid var(--accent);
  border-radius: var(--r-md);
  padding: 10px 16px;
  max-width: 420px;
  text-decoration: none;
  transition: background var(--t-base), border-color var(--t-base), box-shadow var(--t-base);
  box-shadow: var(--shadow-xs);
}
.att-card:hover {
  background: var(--bg-3);
  border-color: var(--border-subtle);
  border-left-color: var(--accent);
  box-shadow: var(--shadow-sm), 0 0 12px rgba(88,101,242,0.10);
}

.att-icon { color: var(--accent); flex-shrink: 0; opacity: 0.90; }
.att-meta { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
.att-filename {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--link);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.att-size { font-size: 11.5px; color: var(--text-faint); }

/* ── Embeds ── */
.embed {
  border-left: 4px solid var(--accent);
  background: var(--bg-2);
  border-radius: 0 var(--r-md) var(--r-md) 0;
  padding: 12px 16px 12px 14px;
  max-width: 520px;
  display: flex;
  flex-direction: column;
  gap: 5px;
  overflow: hidden;
  box-shadow: var(--shadow-xs), 0 0 0 1px var(--border-faint);
  transition: box-shadow var(--t-base);
}
.embed:hover {
  box-shadow: var(--shadow-sm), 0 0 0 1px var(--border-subtle);
}

.embed-gif { padding: 0; border-left: none; background: transparent; max-width: 440px; }
.embed-gif-card { padding: 10px 14px; max-width: 440px; }

.embed-provider {
  font-size: 12px;
  color: var(--text-muted);
  text-decoration: none;
  letter-spacing: 0.01em;
}
a.embed-provider:hover { text-decoration: underline; color: var(--text-secondary); }

.embed-author { display: flex; align-items: center; gap: 8px; margin-bottom: 2px; }
.embed-author-icon { width: 22px; height: 22px; border-radius: 50%; object-fit: cover; }
.embed-author-name {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--text-primary);
  text-decoration: none;
}
a.embed-author-name:hover { text-decoration: underline; }

.embed-thumbnail {
  float: right;
  max-width: 80px;
  max-height: 80px;
  border-radius: var(--r-md);
  margin-left: 10px;
  object-fit: cover;
  box-shadow: var(--shadow-xs);
}

.embed-title {
  font-size: 14.5px;
  font-weight: 600;
  color: var(--link);
  text-decoration: none;
  line-height: 1.35;
}
a.embed-title:hover { text-decoration: underline; }

.embed-desc {
  font-size: 13.5px;
  color: var(--text-secondary);
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.45;
}

.embed-url {
  font-size: 12px;
  color: var(--link);
  word-break: break-all;
  text-decoration: none;
}
.embed-url:hover { text-decoration: underline; }

.embed-image {
  margin-top: 6px;
  max-width: 100%;
  max-height: 300px;
  border-radius: var(--r-sm);
  display: block;
  object-fit: contain;
  clear: both;
  box-shadow: var(--shadow-xs);
}

.embed-video {
  max-width: 100%;
  max-height: 260px;
  border-radius: var(--r-sm);
  display: block;
  margin-top: 6px;
  clear: both;
}

.embed-footer {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 4px;
  font-size: 12px;
  color: var(--text-muted);
  clear: both;
}
.embed-footer-icon { width: 18px; height: 18px; border-radius: 50%; object-fit: cover; }
.embed-footer-sep { color: var(--text-faint); }
.embed-footer-ts { color: var(--text-faint); font-variant-numeric: tabular-nums; }

/* GIF embed */
.gif-video {
  display: block;
  max-width: 100%;
  max-height: 340px;
  border-radius: var(--r-md);
  background: var(--bg-2);
}
.gif-img { border-radius: var(--r-md); }

.gif-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 12px;
  font-size: 12px;
  background: rgba(0,0,0,0.42);
  border-radius: 0 0 var(--r-md) var(--r-md);
  border: 1px solid var(--border-faint);
  border-top: none;
  backdrop-filter: blur(6px);
}
.gif-provider {
  font-weight: 800;
  color: var(--text-faint);
  text-transform: uppercase;
  font-size: 10px;
  letter-spacing: 0.09em;
}
.gif-title { color: var(--text-secondary); }
.gif-link { margin-left: auto; }

/* ── Stickers ── */
.msg-stickers { display: flex; gap: 8px; flex-wrap: wrap; }
.sticker-preview, .sticker-wrap {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}
.sticker-img {
  max-width: 160px;
  max-height: 160px;
  border-radius: var(--r-sm);
  display: block;
  object-fit: contain;
}
.sticker-fallback-card { display: flex; align-items: center; }
.sticker-chip {
  background: var(--bg-4);
  border: 1px solid var(--border-faint);
  border-radius: var(--r-pill);
  padding: 3px 12px;
  font-size: 12px;
  color: var(--text-muted);
}

/* ── Missing content placeholder ── */
.missing-content-card {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: var(--bg-2);
  border: 1px solid var(--border-faint);
  border-left: 3px solid var(--warning);
  border-radius: var(--r-md);
  padding: 10px 14px;
  max-width: 420px;
  margin: 2px 0;
}
.missing-content-icon { color: var(--warning); flex-shrink: 0; margin-top: 1px; opacity: 0.8; }
.missing-content-body { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
.missing-content-text { font-size: 12.5px; color: var(--text-muted); font-style: italic; }
.missing-link { font-size: 11px; color: var(--link); word-break: break-all; }

/* ── Lightbox ── */
.lightbox {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.92);
  backdrop-filter: blur(22px) saturate(140%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 32px;
  animation: lbIn 140ms cubic-bezier(0.2,0,0.1,1);
}
.lightbox[hidden] { display: none; }

@keyframes lbIn {
  from { opacity: 0; }
  to   { opacity: 1; }
}

.lightbox-img {
  max-width: 100%;
  max-height: calc(100vh - 140px);
  border-radius: var(--r-lg);
  object-fit: contain;
  display: block;
  box-shadow: var(--shadow-2xl), 0 0 60px rgba(0,0,0,0.80);
  animation: lbImgIn 180ms cubic-bezier(0.34,1.2,0.64,1);
}

@keyframes lbImgIn {
  from { transform: scale(0.92); opacity: 0; }
  to   { transform: scale(1);    opacity: 1; }
}

.lightbox-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  background: var(--glass-bg);
  border: 1px solid var(--glass-border);
  border-radius: var(--r-pill);
  padding: 7px 12px 7px 16px;
  box-shadow: var(--shadow-lg);
  backdrop-filter: var(--glass-blur);
  animation: lbIn 200ms 60ms both;
}

.lightbox-filename {
  font-size: 12.5px;
  color: var(--text-secondary);
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.lightbox-btn {
  background: rgba(255,255,255,0.07);
  color: var(--text-secondary);
  border: 1px solid var(--border-subtle);
  border-radius: var(--r-md);
  padding: 5px 13px;
  font-size: 12.5px;
  font-family: var(--font-sans);
  cursor: pointer;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  transition: background var(--t-fast), border-color var(--t-fast), color var(--t-fast),
              box-shadow var(--t-fast);
  white-space: nowrap;
}
.lightbox-btn:hover {
  background: var(--accent);
  color: #fff;
  border-color: transparent;
  box-shadow: 0 0 14px var(--accent-glow);
}
.lightbox-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

/* ── User profile popout ── */
.popout-overlay { position: fixed; inset: 0; z-index: 8888; }
.popout-overlay[hidden] { display: none; }

.popout {
  position: fixed;
  z-index: 8889;
  background: var(--bg-2);
  border-radius: var(--r-xl);
  border: 1px solid var(--border-faint);
  box-shadow: var(--shadow-xl), var(--glow-accent);
  width: 272px;
  overflow: hidden;
  animation: popoutIn 160ms cubic-bezier(0.34,1.2,0.64,1);
}
@keyframes popoutIn {
  from { opacity: 0; transform: scale(0.90) translateY(6px); }
  to   { opacity: 1; transform: scale(1)    translateY(0);   }
}
.popout[hidden] { display: none; }

.popout-banner {
  height: 64px;
  background: linear-gradient(135deg, var(--accent) 0%, #7289da 60%, #8ea1e1 100%);
  position: relative;
  overflow: hidden;
}
.popout-banner::after {
  content: "";
  position: absolute;
  inset: 0;
  background: url("data:image/svg+xml,%3Csvg viewBox='0 0 80 80' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.08'/%3E%3C/svg%3E");
  pointer-events: none;
}

.popout-body { padding: 0 16px 16px; position: relative; }

.popout-avatar-wrap {
  position: relative;
  margin-top: -32px;
  margin-bottom: 10px;
  display: inline-block;
}

.popout-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 6px solid var(--bg-2);
  object-fit: cover;
  display: block;
  box-shadow: var(--shadow-md);
}

.popout-display-name {
  font-size: 20px;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1.2;
  margin-bottom: 2px;
  letter-spacing: -0.02em;
}
.popout-username { font-size: 13px; color: var(--text-muted); margin-bottom: 10px; }
.popout-divider { height: 1px; background: var(--border-faint); margin: 8px 0; }

.popout-field-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin-bottom: 4px;
}
.popout-field-value { font-size: 12.5px; color: var(--text-normal); word-break: break-all; }
.popout-id-row { display: flex; align-items: center; gap: 8px; margin-top: 2px; }

.popout-copy-btn {
  background: var(--bg-5);
  color: var(--text-secondary);
  border: 1px solid var(--border-subtle);
  border-radius: var(--r-sm);
  padding: 3px 10px;
  font-size: 11px;
  font-family: var(--font-sans);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: background var(--t-fast), color var(--t-fast), border-color var(--t-fast),
              box-shadow var(--t-fast);
  white-space: nowrap;
}
.popout-copy-btn:hover {
  background: var(--accent);
  color: #fff;
  border-color: transparent;
  box-shadow: 0 0 10px var(--accent-glow);
}
.popout-copy-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.popout-copy-btn.copied { background: var(--success); color: #fff; border-color: transparent; }

.popout-msg-count {
  font-size: 12px;
  color: var(--text-faint);
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 5px;
}

/* ── Search highlights ── */
.search-hidden { display: none !important; }

mark.search-highlight {
  background: rgba(240,178,50,0.30);
  color: var(--text-primary);
  border-radius: 2px;
  padding: 0 1px;
}

.search-current {
  outline: 2px solid var(--accent) !important;
  outline-offset: -1px !important;
  background: var(--accent-soft) !important;
  border-radius: 2px;
}

/* ── Reduced motion ── */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    transition-duration: 0ms !important;
    animation-duration: 0ms !important;
    animation-iteration-count: 1 !important;
  }
  .messages-begin-icon::after { animation: none; }
}

/* ── Responsive / mobile ── */
@media (max-width: 680px) {
  body { overflow: auto; }
  .app-shell { flex-direction: column; height: auto; overflow: visible; }
  .sidebar {
    width: 100%;
    min-width: 0;
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    border-right: none;
    border-bottom: 1px solid var(--border-faint);
    padding: 10px 14px;
    gap: 8px;
  }
  .sidebar::after { display: none; }
  .server-icon { margin: 0; width: 40px; height: 40px; font-size: 16px; border-radius: 11px; }
  .sidebar-dm-name { font-size: 14px; padding: 0 4px; }
  .sidebar-section, .sidebar-meta-row, .sidebar-divider, .sidebar-badge { display: none; }
  .chat { overflow: visible; }
  .messages { overflow: visible; padding-bottom: 32px; }
  .message { padding: 2px 12px; }
  .message::before { display: none; }
  .reply-preview { padding-left: 8px; }
  .forward-badge { padding-left: 8px; }
  .chat-header { padding: 0 12px; }
  .chat-header-meta { display: none; }
  .search-bar { padding: 9px 12px; }
  .search-select { min-width: 80px; font-size: 12px; }
  .media-grid-1, .media-grid-2, .media-grid-many { max-width: 100%; }
  .att-card, .video-wrap, .audio-wrap, .embed, .missing-content-card { max-width: 100%; }
  .embed-gif, .embed-gif-card { max-width: 100%; }
  .filter-chips { gap: 4px; }
  .filter-chip { font-size: 11.5px; padding: 3px 9px 3px 6px; }
  .popout { width: calc(100vw - 32px); }
  .lightbox { padding: 16px; }
  .lightbox-footer { flex-wrap: wrap; border-radius: var(--r-lg); }
}
`
