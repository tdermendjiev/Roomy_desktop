# Roomy — S01 Welcome / Empty State
## Google Stitch Design Prompt · Step 3.1

---

## Context

You are designing the **Welcome screen** (S01) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This is the first screen a user sees on launch. It sets the entire tone of the product. It must feel confident, minimal, and immediately trustworthy — a developer should look at this and think "this was made by someone like me."

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 1.2 — App icon
- Step 2.1 — Component library

All colors, type styles, spacing, and components referenced below are defined in those documents. Do not introduce new values.

---

## Screen purpose

Two states exist for this screen:

**State A — First launch:** The user has never run a scan. No previous results exist.
**State B — Return visit:** The user has run at least one scan. A "View last scan" option is available.

Design both states. State A is the primary design. State B is a variant with one additional element (the "View last scan" link).

---

## Window specifications

- Window size: 900×600px (default)
- Minimum: 780×520px
- Standard macOS window chrome: traffic lights top-left, no sidebar
- Toolbar: present but minimal — just the app title centered and settings gear top-right. No back button (this is the root screen).

---

## Layout

Full window. Single centered column. The content does not fill the window — generous whitespace is intentional. The emptiness of the welcome screen mirrors the emptiness the app will create.

Vertical rhythm (approximate, from top of content area below toolbar):

```
[toolbar — 52px]
─────────────────────────────────────────────
[top padding — 48px]
[app icon — 64px]
[app name — 8px gap]
[tagline — 16px gap]
─────────────────────────────────────────────
[section gap — 40px]
─────────────────────────────────────────────
["Where should I look?" — heading]
[scan path selector — 16px gap]
[selected path pill — 12px gap]
[reassurance note — 8px gap]
─────────────────────────────────────────────
[section gap — 32px]
─────────────────────────────────────────────
[advanced disclosure — ecosystem filter]
─────────────────────────────────────────────
[section gap — 32px]
─────────────────────────────────────────────
[Start scan button]
[estimated time hint — 8px gap]
─────────────────────────────────────────────
[bottom padding — 48px]
```

Total content column width: 480px, horizontally centered in the 900px window. This leaves 210px of whitespace on each side — intentional breathing room.

---

## Elements

### App icon + identity (top)

The app icon from Step 1.2 at **64×64px**, centered above the app name.

Below the icon:
- **App name:** "Roomy" — `title-lg` (20px/600), `--text-primary`
- **Tagline:** "Reclaim disk space from dormant projects." — `body` (14px/400), `--text-secondary`

The icon, name, and tagline form a single centered identity block. Spacing between elements: icon → name 8px, name → tagline 4px.

---

### Scan path selector

**Heading:** "Where should I look?" — `title-md` (16px/600), `--text-primary`, left-aligned within the 480px column.

Below the heading (12px gap): three path option buttons in a horizontal row.

#### Path option buttons

Three equal-width buttons in a row, filling the 480px column with 8px gaps between them. Each button: approximately 152px wide.

Specs:
- Height: 72px
- Border radius: 8px
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Layout: centered icon + label + sublabel

Each button contains:
- **SF Symbol icon** (20px, `--text-secondary`) — top, centered
- **Label** (13px/500, `--text-primary`) — below icon, 6px gap
- **Sublabel** (11px/400, `--text-tertiary`) — below label, 2px gap

| Option | Icon | Label | Sublabel |
|---|---|---|---|
| Home folder | `house` | "Home folder" | "~/" |
| Custom | `folder.badge.plus` | "Custom folder…" | "Choose a path" |
| Entire Mac | `desktopcomputer` | "Entire Mac" | "All accessible paths" |

**Selected state:**
- Border becomes 1.5px `--accent`
- Background: `--accent-subtle`
- Icon and label text: `--accent`
- A subtle checkmark (SF Symbol `checkmark.circle.fill`, 14px, `--accent`) appears in the top-right corner of the button

**Default selected:** "Home folder" — show this button in its selected state in the primary design.

**Hover state:** `--bg-hover` background, `--border-default` border.

Show all three buttons with "Home folder" selected.

---

#### Selected path pill

Below the three buttons (12px gap): the currently selected path displayed as a path pill component (from Step 2.1, component 10A).

Content: `~/` (for Home folder selection)

When "Custom folder…" is selected: the pill shows the chosen path, or if none chosen yet, shows a ghost state — "No folder selected" in `--text-tertiary`.

When "Entire Mac" is selected: the pill shows "All user-accessible paths" in `--text-secondary`.

---

#### Reassurance note

Below the path pill (8px gap): a single line of small text, centered.

"Scans only regenerable files — nothing permanent will be found."

Specs: 12px/400, `--text-tertiary`, centered in the 480px column.

This line is important — it lowers the fear of the first scan. Style it to be noticed but not prominent. Consider a subtle SF Symbol `shield.checkmark` (12px, `--text-tertiary`) leading the text.

---

### Advanced ecosystem filter (collapsed by default)

A disclosure row (component 4B from Step 2.1) below the reassurance note (32px gap).

**Collapsed state label:** "Advanced · Choose ecosystems" — 13px/400, `--text-tertiary`.

**Expanded state:** The disclosure triangle rotates 90°, and below it appears a grid of ecosystem checkboxes:

- 4 columns × 2 rows = 8 ecosystem options
- Each cell: 16px checkbox (from component 5A) + ecosystem icon (14px) + ecosystem name (13px/400, `--text-primary`)
- Cell height: 32px
- Gap between cells: 4px
- All checked by default

Ecosystem list: Node.js · Python · Rust · Ruby · Go · Java/Kotlin · Swift/Xcode · General

Below the grid (8px gap): "Select all / None" — two ghost button links (component 1D), separated by a `·` divider. Right-aligned within the 480px column.

**Show both states:** the collapsed state as the primary design, and the expanded state as a variant frame.

---

### Primary CTA

Below the ecosystem filter section (32px gap from the disclosure row, whether collapsed or expanded):

**"Start scan →" button** — Primary button (component 1A), large variant (36px height), 200px wide, centered.

The `→` in the label is deliberate — implies forward motion. Use it literally in the button label.

Below the button (8px gap):

**Estimated time hint:** "Usually under 60 seconds" — 12px/400, `--text-tertiary`, centered.

---

### State B addition — "View last scan" link

Only visible in State B (return visit). Appears below the estimated time hint (16px gap):

"View last scan from March 14" — Ghost button / text link (component 1D), centered, 13px/400.

---

## Micro-details to get right

**The emptiness is the design.** The welcome screen has a lot of vertical whitespace. Do not fill it. The 48px top and bottom padding, and the 40px gap between the identity block and the scan section, should feel like a considered choice — not a layout that hasn't been finished.

**The reassurance note** must be present. It is easy to omit and important to keep. A developer running this for the first time is slightly worried — will it accidentally delete something important? That note preemptively answers the concern.

**The "Home folder" pre-selection** should look clearly selected, not just highlighted. The checkmark in the corner of the button is key — without it, the selected state might look like a hover state.

**The tagline full stop.** "Reclaim disk space from dormant projects." ends with a period. This is intentional — it reads as a declarative statement, confident and complete. Preserve it.

**The icon size.** 64px on the welcome screen — not 80px, not 48px. Large enough to be read, small enough to not dominate.

---

## What this screen must NOT look like

- **Not a splash screen.** No fullscreen illustration, no hero image, no decorative background.
- **Not an onboarding flow.** No step indicators, no "1 of 3", no progress dots.
- **Not a marketing page.** No feature bullets, no testimonials.
- **Not a dialog.** This is a full window — not a centered card on a blurred background.

---

## Connections (for prototype/flow annotation)

| Action | Destination |
|---|---|
| "Start scan →" button | S02 — Scanning Progress |
| "View last scan from [date]" | S03 — Results Overview |
| Settings gear (toolbar) | S09 — Settings |

---

## Deliverable frames

- [ ] S01-A — First launch (Home folder selected, ecosystem filter collapsed) — 900×600px dark mode
- [ ] S01-A — Light mode variant — 900×600px
- [ ] S01-B — Return visit (with "View last scan" link) — 900×600px dark mode
- [ ] S01-expanded — Ecosystem filter expanded variant — 900×600px dark mode
- [ ] S01-custom — "Custom folder" selected state variant — 900×600px dark mode
- [ ] S01-min — At minimum window size 780×520px — verify nothing breaks

---

## Annotation notes for handoff

- The 480px content column width and horizontal centering
- The 52px toolbar height
- The three-button row with equal widths and 8px gaps
- The path pill component reference (Step 2.1 / 10A)
- The disclosure triangle behavior (collapsed → expanded: 150ms ease-out chevron rotation)
- The "Start scan →" button: transitions to S02 with 180ms ease-in-out screen transition
- The reassurance note: always visible, never hidden even on resize

---

*This prompt is Step 3.1 of 10 in the Roomy design process. The visual language established here — generous whitespace, centered single column, confidence through restraint — sets the tone that all subsequent screens should echo.*
