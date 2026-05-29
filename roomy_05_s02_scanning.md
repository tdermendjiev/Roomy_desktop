# Roomy — S02 Scanning Progress
## Google Stitch Design Prompt · Step 3.2

---

## Context

You are designing the **Scanning Progress screen** (S02) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This screen is shown while the filesystem scan is running. It has one job: make the user feel like something real and intelligent is happening. Not a generic spinner — a live window into what the app is actually doing.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 7A/7B progress bars and 8D findings ticker)

---

## Screen purpose

The scan takes up to 60 seconds. This screen must hold the user's attention without asking anything of them. It does this through:

1. **Live stats** that update in real time — numbers actually moving makes the wait feel productive
2. **A scrolling ticker** of discoveries — watching `node_modules` folders accumulate is genuinely satisfying
3. **A growing "recoverable" number** — by the time the scan completes, the user is already excited

The emotional target: mild surprise building to anticipation. "I had no idea I had this much junk."

---

## Window specifications

- 900×600px default, 780×520px minimum
- Same toolbar as S01: app title centered, settings gear right. No back button during an active scan.
- The toolbar's bottom border is the only visual separator from the content area.

---

## Layout

Full window. Centered content column, 560px wide. Unlike S01's 480px column, this screen can breathe a little wider because the findings ticker benefits from more horizontal space for paths.

Vertical rhythm:

```
[toolbar — 52px]
──────────────────────────────────────────────
[top padding — 40px]
[header block — scanning title + path]
[gap — 32px]
[progress section — indicator + live stats]
[gap — 32px]
[findings ticker — 5 rows visible]
[gap — 24px]
[cancel link]
[bottom padding — 40px]
```

---

## Elements

### Header block

**Title:** "Scanning your projects…"
- `title-lg` (20px/600), `--text-primary`, centered

**Scanning path** (below title, 6px gap):
- Currently active scan path — shown as a truncated monospace path
- Example: "~/Projects and subfolders"
- `mono-body` (13px/400), `--text-secondary`, centered
- As the scan progresses, this updates live to show the deepest directory currently being traversed — e.g. `~/projects/old-client/node_modules/lodash/…`
- The live path should truncate in the middle if too long: `~/projects/old-client/…/lodash`
- Show the live-updating variant as a labeled annotation on the frame ("updates live during scan")

---

### Progress section

Two sub-states: **indeterminate** (scan start, file count unknown) and **determinate** (once file count is estimated).

#### Progress bar

Use component 7A (indeterminate) transitioning to 7B (determinate) from Step 2.1.

Specs:
- Width: 360px, horizontally centered
- Indeterminate: 2px shimmer bar, `--accent`, pulsing left-to-right
- Determinate: 4px filled bar, `--accent`, filling left to right as scan progresses

Show both variants — indeterminate as the primary state (more interesting visually), determinate as an annotated variant.

**Percentage label** (determinate only): appears below the bar, right-aligned to its width. "63%" — 12px/400, `--text-tertiary`.

Gap between progress bar and stats grid: 28px.

---

#### Live stats grid

Four stats displayed in a 2×2 grid below the progress bar. These numbers tick upward in real time as the scan runs.

Grid specs:
- Total width: 360px (matching the progress bar width)
- 2 columns, 2 rows
- Each cell: 172px wide, 56px tall
- Gap between cells: 16px horizontal, 12px vertical
- Cell background: `--bg-elevated`
- Cell border: 1px `--border-subtle`
- Cell border radius: 8px
- Cell padding: 12px

Each stat cell contains:
- **Value** — `title-lg` (20px/600), `--text-primary`, left-aligned
- **Label** — `caption` (11px/400), `--text-tertiary`, left-aligned, 4px below value

| Cell | Example value | Label |
|---|---|---|
| Top-left | 14,203 | Folders scanned |
| Top-right | 47 | Projects found |
| Bottom-left | 89 | Artifacts found |
| Bottom-right | 23.4 GB | Recoverable so far |

**The "Recoverable so far" stat** is the hero number. It should visually stand out from the other three:
- Value in `--accent` color instead of `--text-primary`
- Consider a very subtle `--accent-subtle` background tint on this cell only
- This number climbing is the emotional core of the screen

Show the grid in a mid-scan state with the example values above. Annotate that all four numbers update live every ~200ms.

---

### Findings ticker

The scrolling log of artifacts being discovered. Uses component 8D from Step 2.1, adapted here in context.

Position: below the stats grid (32px gap), centered in the 560px column.

Specs:
- Container width: 480px, centered
- Visible rows: 5 (110px total height at 22px per row)
- Top and bottom fade masks: 20px gradient from transparent to `--bg-base` — creates the illusion of content scrolling out of view
- New items appear at the top with a 150ms fade-in + 4px upward slide
- The container does not show a scrollbar — it's a viewport into a stream

Each row layout (left to right, single line, 22px row height):
- **Ecosystem icon** — 12px, `--text-tertiary`, fixed 20px width
- **Artifact name** — `label-medium` (13px/500), `--text-primary`, fixed 120px width (e.g. "node_modules")
- **Path** — `mono-body` (13px/400), `--text-tertiary`, flex-fill, middle-truncated (e.g. `~/projects/startup-2021/…`)
- **Size** — `label-medium` (13px/500), `--accent`, fixed 64px width, right-aligned (e.g. "1.2 GB")

Show a static mockup with 5 rows of realistic data:

```
[npm]   node_modules    ~/projects/startup-2021/…          1.2 GB
[py]    __pycache__     ~/code/ml-experiments/…           340 MB
[rust]  target/         ~/rust/learning-project/…          4.1 GB
[npm]   .next/          ~/projects/portfolio-2020/…       890 MB
[py]    venv/           ~/code/data-analysis/…             2.3 GB
```

The newest item (top row) should appear slightly brighter than the older rows — `--text-primary` fading toward `--text-tertiary` as items age. This creates a subtle "recency" effect without animation in a static frame.

---

### Cancel affordance

Below the findings ticker (24px gap):

"Cancel scan" — ghost text link (component 1D), centered, 12px/400, `--text-tertiary` (not `--accent` — this is a low-emphasis action).

A developer who accidentally scanned the wrong path needs an out. But this should not be prominent — cancelling is the exception, not the expected flow.

---

## States to design

### State 1 — Scan start (primary design)
- Indeterminate progress bar (shimmer)
- Stats: Folders scanned: 0 · Projects found: 0 · Artifacts found: 0 · Recoverable so far: 0 GB
- Ticker: empty or showing first 1–2 items
- Show this as the default frame

### State 2 — Mid-scan (primary annotated variant)
- Determinate progress bar at ~40%
- Stats: Folders scanned: 14,203 · Projects found: 47 · Artifacts found: 89 · Recoverable so far: 23.4 GB
- Ticker: 5 rows of data (use the realistic data above)
- This is the most visually interesting state — annotate which elements are live-updating

### State 3 — Scan complete (transition state)
- Progress bar at 100%, fully filled `--accent`
- Stats frozen at final values
- Ticker stopped
- A subtle completion indicator: the progress bar briefly flashes brighter (annotate as a 300ms pulse), then the screen transitions to S03
- No explicit "Done" button — the transition is automatic after 800ms
- Annotate: "auto-transitions to S03 after 800ms"

### State 4 — Partial scan (cancelled)
- Progress bar stopped at whatever percentage
- Stats frozen
- A banner appears at the top of the content area (below the toolbar, above the header):
  - Background: `--status-inactive` at 10% opacity
  - Border-bottom: 1px `--status-inactive` at 30% opacity
  - Icon: SF Symbol `exclamationmark.triangle` (14px, `--status-inactive`)
  - Text: "Partial scan — not all folders were checked" — 13px/400, `--text-secondary`
  - The screen still transitions to S03, but S03 will show the partial scan banner too

---

## Micro-details to get right

**The "Recoverable so far" accent color** is the single most important detail on this screen. That number climbing in blue while everything else is white/gray creates a quiet but effective focal point. The user's eye goes there. By the time it hits 40 GB, they're sold.

**The ticker rows must use real-looking paths** — not `/Users/user/folder/artifact`. Use tilde-abbreviated paths with realistic project names: `~/projects/`, `~/code/`, `~/dev/`. Developers will notice immediately if the paths look fake.

**The fade masks on the ticker** are essential. Without them the ticker looks like a list. With them it looks like a stream. The difference in feel is significant.

**The stats grid cells** should not look like KPI cards from a dashboard. They're compact, borderline utilitarian. The `--bg-elevated` background and subtle border exist to group them visually — not to make them look important individually. The "Recoverable so far" cell is the only one that earns visual distinction.

**No percentage text on the indeterminate bar.** Showing "0%" or "—" while the bar is still indeterminate looks wrong. The percentage label only appears once the bar becomes determinate.

---

## What this screen must NOT look like

- **Not a loading screen.** A loading screen is passive. This screen is active — the numbers are moving, the ticker is scrolling. Every frame tells the user something new.
- **Not an activity monitor.** The stats are human-readable summaries, not raw system metrics. "47 projects found" not "47 directory trees with matching manifest files".
- **Not anxious.** No red indicators, no warning icons, no "this may take a while" hedging. The tone is confident and efficient.
- **Not cluttered.** Five elements: header, progress bar, stats grid, ticker, cancel link. Nothing else. The temptation to add more information should be resisted.

---

## Animation annotations (for handoff)

Annotate these behaviors on the frame even though they can't be shown statically:

- Progress bar: updates every ~500ms in real-time increments
- Folders scanned: increments rapidly (hundreds per second)
- Projects found / Artifacts found: increments less frequently, each new find feels like an event
- Recoverable so far: increments when each artifact's size is calculated (may lag slightly behind artifact count)
- Ticker: new row appears at top every 1–3 seconds on average, older rows slide down and fade
- Scan path label: updates every ~200ms to show current directory

---

## Connections

| Action | Destination |
|---|---|
| Scan completes (auto, 800ms delay) | S03 — Results Overview |
| "Cancel scan" | S03 — Results Overview (with partial scan banner) |
| Settings gear | S09 — Settings (disabled during active scan — annotate this) |

---

## Deliverable frames

- [ ] S02-start — Scan just started, indeterminate bar, empty ticker — 900×600px dark mode
- [ ] S02-mid — Mid-scan, determinate bar at 40%, 5-row ticker, stats populated — 900×600px dark mode
- [ ] S02-complete — Scan complete, full bar, frozen stats — 900×600px dark mode
- [ ] S02-partial — Cancelled scan with partial banner — 900×600px dark mode
- [ ] S02-mid — Light mode variant — 900×600px
- [ ] S02-min — At minimum window size 780×520px

---

*This prompt is Step 3.2 of 10 in the Roomy design process. The next screen (S03 Results Overview) is where the emotional payoff happens — everything on this screen builds anticipation for that moment.*
