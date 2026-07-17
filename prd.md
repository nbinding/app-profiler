# PRD — App Profiler

A single-screen, infinite-canvas workspace for planning and visualising every app / SaaS product you own or are incubating. Think "Miro meets a product catalogue": each product is a card living in a column (kanban-style lane), and every card holds the full identity kit for that product — name, package id, logos, icons, copy, SEO metadata — so the whole portfolio is scannable at a glance and deep-editable on click.

---

## 1. Problem

Product ideas and their branding assets (names, package ids, logo variants, store copy, SEO descriptions) end up scattered across notes apps, Figma files, folders, and app store consoles. There is no single place to:

- See the entire portfolio on one screen.
- Compare naming/branding across products.
- Track products as they evolve from "idea" to "shipped".
- Keep the canonical identity kit (the stuff you paste into App Store Connect / Play Console / landing pages) in one editable record.

## 2. Goals

1. **One screen, whole portfolio.** Every app/service visible at once on a pannable, zoomable canvas.
2. **Rich product cards.** Each card is a structured record, not a sticky note.
3. **Evolvable structure.** Columns (lanes) can be created, renamed, reordered, and deleted as the portfolio grows — e.g. `Ideas → Validating → Building → Live → Sunset`, or lanes by category instead of stage.
4. **Fast capture.** Adding a new idea takes < 10 seconds (name + lane, everything else optional).
5. **Local-first.** Works offline, data is yours, no account required for v1.

### Non-goals (v1)

- Multi-user real-time collaboration.
- Task/issue tracking inside cards (this is a portfolio planner, not Jira).
- Automated store publishing or API integrations.
- Mobile app (desktop-browser first; canvas UX is poor on small screens anyway).

## 3. Users

- **Primary:** solo developer / indie hacker with 5–50 apps and ideas.
- **Secondary:** small studio or agency cataloguing client apps.

## 4. Core concepts & data model

```
Board
 ├─ id, name
 ├─ lanes: Lane[]          // ordered
 └─ settings (zoom/pan persisted per board)

Lane (column)
 ├─ id, title, color, order
 └─ cardIds: string[]      // ordered

Card (product profile)
 ├─ id, laneId, order
 ├─ appName            string, required
 ├─ tagline            string           // one-liner
 ├─ summary            string           // short paragraph
 ├─ seoTitle           string (~60 chars, live char counter)
 ├─ seoDescription     string (~160 chars, live char counter)
 ├─ packageName        string           // com.example.app
 ├─ bundleId           string           // optional iOS distinct id
 ├─ platforms          enum[]           // ios | android | web | desktop | api
 ├─ status             derived from lane, plus optional badge override
 ├─ urls               { website, repo, appStore, playStore, ... }[]
 ├─ keywords           string[]         // ASO/SEO keywords
 ├─ logos              Asset[]          // full logo variants (light/dark/mono)
 ├─ icons              Asset[]          // app icons, favicons, maskable
 ├─ brandColors        string[]         // hex values
 ├─ notes              markdown
 ├─ createdAt / updatedAt
 └─ archived           bool

Asset
 ├─ id, kind (logo|icon), label (e.g. "dark", "1024 master")
 ├─ blob ref (stored locally), mime, dimensions
 └─ isPrimary bool
```

**Naming-options pattern:** `appName`, `packageName`, `tagline` each support an *alternatives list* — a card can hold multiple candidate names/ids with one marked as chosen. This is the "as many options as possible" requirement: brainstorm candidates live on the card until one is promoted.

## 5. UX

### 5.1 Canvas

- Infinite canvas with smooth pan (space-drag / trackpad / middle-mouse) and zoom (pinch / ctrl-scroll), tldraw/Miro-style.
- Zoom-to-fit button; per-lane "focus" (zoom to lane).
- Semantic zoom: zoomed out, cards render as icon + name only; zoomed in, full card detail. Keeps 50 cards legible on one screen.
- Minimap (v1.1, optional).

### 5.2 Lanes (columns)

- Vertical columns laid side by side, kanban view.
- `+ New lane` at the end of the row; inline rename; drag to reorder; color tag.
- Lane header shows card count.
- Collapse a lane to a slim bar (declutter).

### 5.3 Cards

- **Collapsed (canvas) view:** primary icon, app name, tagline, platform badges, brand-color strip.
- **Expanded view:** click opens a side panel (not a modal — canvas stays visible) with all fields, asset gallery, char-counted SEO fields, alternatives lists, markdown notes.
- Drag card between lanes / reorder within lane.
- Duplicate card (fork an idea), archive card (hidden, recoverable).

### 5.4 Assets

- Drag-and-drop image upload onto a card or into the asset gallery.
- Multiple logo/icon variants per card with labels; pick a primary (shown on the collapsed card).
- Click asset for full-size preview; download original.

### 5.5 Capture & search

- Global `N` shortcut / `+` button: quick-add card (name + lane).
- `Cmd-K` search: fuzzy match on name/package/keywords, jump-and-zoom to the card.

### 5.6 Files — Save As, export, import

**Native file format: `.appboard`** — a zip container:

```
myportfolio.appboard (zip)
 ├─ board.json        // schema-versioned: { formatVersion, board, lanes, cards }
 └─ assets/           // original image files, referenced by id from board.json
     ├─ <assetId>.png
     └─ ...
```

- `formatVersion` field in `board.json` so future versions can migrate old files.
- Plain zip on purpose: rename to `.zip`, open anywhere — no lock-in, hand-inspectable.
- **Prototype note:** the working `index.html` prototype ships the simpler variant — `.appboard` is a single JSON file with images embedded as base64 data-URLs (no zip, no separate `assets/` folder). One self-contained file the File System Access API writes directly. Graduate to the zip container above only when embedded images make files unwieldy.

**File operations (File menu + shortcuts):**

| Operation | Behavior |
|---|---|
| **Save** (`Cmd-S`) | Writes to the linked `.appboard` file via File System Access API. If board has no linked file, behaves as Save As. IndexedDB autosave still runs continuously regardless — the file is the portable copy, IndexedDB is the crash-safety copy. |
| **Save As** (`Cmd-Shift-S`) | OS file picker, writes a new `.appboard`, links board to that file for future Saves. |
| **Open / Import** (`Cmd-O`) | Pick a `.appboard` (or bare `board.json`); loads as a new board. On id collision with an existing board: prompt *replace* or *import as copy*. Also drag-and-drop a `.appboard` file onto the window to open. |
| **Export JSON** | `board.json` only, no assets — small, diff-able, good for version control. |
| **Export zip** | Same as Save As but without linking the file (one-off backup/share). |

- File System Access API (`showSaveFilePicker` / `showOpenFilePicker`) in Chromium; fallback to download-blob + `<input type="file">` in Safari/Firefox. Feature-detect, same menu either way.
- Unsaved-changes indicator (dot on title) when linked file is stale vs. in-memory state.
- Per-card "copy identity kit" — copies name/package/summary/SEO block as markdown to clipboard for pasting into store consoles.

## 6. Tech approach (recommended)

**Principle: local-first single-page app, no backend for v1.** Everything below runs in the browser; ship it as a static site.

| Layer | Choice | Why |
|---|---|---|
| Framework | React + TypeScript + Vite | Boring, fast, huge ecosystem. |
| Canvas | **Custom DOM canvas**: absolutely-positioned lanes inside a pan/zoom container (CSS transform), e.g. via `react-zoom-pan-pinch` | Cards are rich HTML forms/images — DOM renders them for free. tldraw/konva/pixi are built for freeform drawing shapes, which this isn't: it's structured columns that happen to pan/zoom. DOM keeps text selectable, inputs native, a11y intact. |
| Drag & drop | `@dnd-kit` | Lane reorder + cross-lane card drag, works with transformed containers. |
| State | Zustand (or plain React context) | Board state is one tree; no need for Redux. |
| Persistence | IndexedDB via `Dexie` — structured records + image blobs | Blobs don't fit localStorage; IndexedDB is the native answer. Autosave on every mutation. |
| Search | Client-side fuzzy (`fuse.js` or simple `includes`) | ≤ a few hundred cards; no index server needed. |
| Files | `JSZip` for `.appboard` (zip) pack/unpack + File System Access API with download/`<input type="file">` fallback | Native Save/Save As/Open UX in Chromium; portable everywhere else. |
| Styling | Tailwind | Fast iteration on card/panel UI. |

### Why not tldraw SDK?

tldraw gives world-class pan/zoom and could host cards as custom shapes — but its model is freeform shapes, and this product's model is *structured lanes with ordered cards*. Fighting tldraw's free positioning to enforce column layout costs more than adding pan/zoom (one library) to a normal kanban DOM. Revisit tldraw only if freeform annotation (arrows between apps, sticky notes, drawings on the canvas) becomes a requirement — that's listed under Future.

### Sync / backend (later, v2)

When multi-device sync matters: add a sync layer rather than a rewrite — options in order of laziness:

1. File-based: export/import zip via iCloud/Drive folder (zero backend).
2. CRDT local-first sync (Yjs or Automerge + a tiny relay / y-websocket) — keeps offline-first intact.
3. Full backend (Supabase: Postgres + storage + auth) if accounts/sharing needed.

## 7. Milestones

**M1 — Walking skeleton (1–2 weeks part-time)**
Board with lanes, quick-add cards, drag between lanes, pan/zoom, IndexedDB persistence. Card = name + tagline only.

**M2 — Full card profile**
Side-panel editor, all fields, SEO char counters, alternatives lists, markdown notes.

**M3 — Assets & files**
Image upload, variants gallery, primary icon on collapsed card, blob storage. `.appboard` format: Save / Save As / Open, JSON export, drag-file-to-open.

**M4 — Polish**
Semantic zoom, Cmd-K search, collapse lanes, copy-identity-kit, keyboard shortcuts, archive.

## 8. Success criteria

- Entire portfolio (≥20 cards) legible on one screen at fit-zoom.
- Quick-add a new idea in <10s.
- Zero data loss across browser restarts (autosave verified).
- 60fps pan/zoom with 50 cards and images.

## 9. Risks

| Risk | Mitigation |
|---|---|
| DOM canvas jank with many image cards | Semantic zoom (render cheap card at low zoom); lazy-load blobs; `content-visibility: auto`. |
| IndexedDB eviction by browser | Request `navigator.storage.persist()`; prominent export/backup. |
| Scope creep toward full design tool | Non-goals list; freeform drawing explicitly deferred. |

## 10. Future ideas (parking lot)

- Freeform layer: arrows/relations between apps, sticky notes (this is the tldraw-SDK trigger).
- AI assists: generate SEO description / name candidates from summary.
- Icon pipeline: upload one 1024px master, auto-generate all store sizes.
- Domain/package availability checker.
- Public read-only share link of the board.
- Store-listing sync (pull live metadata from App Store / Play Store).
