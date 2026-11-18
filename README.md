# App Profiler

An infinite-canvas planner for all your apps and SaaS products — every product's
identity kit (name, package id, icons, screenshots, brand colors, store copy, SEO
metadata) laid out as columns on one pannable, zoomable canvas.

**Live:** https://nbinding.github.io/app-profiler/

## What it does

- **Matrix canvas** — product columns × attribute rows, pan/zoom like Miro/tldraw.
  Zoom out for a portfolio overview (detail rows collapse), zoom in to edit.
- **Rich product cards** — per-type field labels (mobile app / SaaS / custom
  service), live character counters on store copy, name-alternative chips
  (click to promote), identifiers, pricing, privacy/permissions/devices/keyword
  chips, links, notes.
- **Brand kit** — app icon + up to 8 brand colors (picker **and** hex). The lead
  color themes the whole column; uploading an icon samples its dominant color.
- **Screenshots & assets** — drop images into slots; the icon and screenshots.
- **Edit / View modes** — Edit exposes all controls; View is read-only and opens
  a lightbox of a product's assets when you click one.
- **Local-first** — autosaves to IndexedDB. Save / Open / Export your board as a
  self-contained `.appboard` file (JSON with embedded images), or Export JSON.

## Run locally

No build, no dependencies. Open `index.html` in a browser, or serve it:

```
python3 -m http.server 8000   # then visit http://localhost:8000
```

## Tech

Single static `index.html` — vanilla JS, no framework, no build step. Styled with
the [nbinding design system](https://github.com/nbinding/nbinding-design-system)
(fonts, colour tokens, light and dark themes, buttons, fields, dialog, toast): a
copy of its `src/` lives in `ds/`. Update it by copying the design system's `src/`
over that folder. State in a
plain object, IndexedDB for persistence, File System Access API for Save/Open
(with a download fallback on Safari/Firefox). See [prd.md](prd.md) for the full
product spec.

## Branches & deploy

- `main` — development. Contains everything (`index.html`, `prd.md`, this README).
- `public` — the deploy branch GitHub Pages serves. Carries **only** `index.html`
  and `ds/`, so the PRD is not published to the live site.

Deploy the current `index.html` and `ds/` to the live site:

```
./deploy.sh
```

(Pages rebuilds in ~1 minute.)
