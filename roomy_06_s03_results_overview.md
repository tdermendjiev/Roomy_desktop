# Roomy — S03 Results Overview
## Google Stitch Design Prompt · Step 4.1

---

## Context

You are designing the **Results Overview screen** (S03) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This is the most important screen in the app. It is the payoff after the scan — the moment the user sees what was found and decides what to do. Everything before this screen was buildup. Everything after is consequence. This screen must land with impact.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 8A stat cards, 8B summary number, 7D disk space bar)

---

## Screen purpose

The emotional target is: **"I had no idea I had this much junk."**

The design must deliver that reaction through:
1. A large, confident hero number — the total recoverable space, shown immediately
2. A clear breakdown that makes the number feel real and understandable — not just a total, but "where is it?"
3. Immediate, obvious actions — the user should never wonder what to do next

This screen is a dashboard, not a report. It should be scannable in 5 seconds.

---

## Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: app title centered ("Results"), back button not shown (this is a top-level results screen), settings gear right

---

## Layout

Full window. No sidebar. Vertical flow from hero stat → breakdown → actions.

```
[toolbar — 52px]
──────────────────────────────────────────────
[hero section — ~160px]
[divider]
[breakdown section — ~220px]
[divider]
[actions section — ~100px]
[bottom bar — 36px]
```

The window is divided into three horizontal bands stacked vertically. Each band has its own internal padding (20px top/bottom, 32px left/right). The bands are separated by 1px `--border-subtle` dividers.

---

## Elements

### Hero section

Full-width band. Background: `--bg-base`. Internal padding: 32px top/bottom, 40px left/right.

This section contains the single most important number in the app.

#### Hero stat

Centered horizontally in the band.

- **The number:** "47.3" — `display` style but larger: **52px/700**, `--text-primary`
- **The unit:** "GB" — 28px/400, `--text-secondary`, baseline-aligned with the number, 4px gap after the number
- **The label below:** "recoverable across 84 projects" — `body` (14px/400), `--text-secondary`, 8px below the number

The number + unit sit on one line. The label sits on the line below.

**Animation annotation:** On screen entry, the number counts up from 0 to 47.3 over 800ms with ease-out easing. The unit "GB" and label appear immediately — only the number animates. Annotate this behavior.

#### Subtext

Below the label (8px gap):

"Safely deletable — all regenerable from source"

12px/400, `--text-tertiary`, centered. This is the second reassurance note in the app — same purpose as S01's "nothing permanent will be found." Developers need one more reminder before they act.

#### Partial scan banner

If this screen was reached via a cancelled scan (S02 State 4), show a banner at the very top of this section (above the hero number):

- Background: `--status-inactive` at 10% opacity
- Left border: 3px `--status-inactive`
- Icon + text: "Partial scan — results may be incomplete. Re-scan for full results."
- 13px/400, `--text-secondary`
- Right side: ghost link "Re-scan →"

Show as a separate variant frame. Do not show in the primary design.

---

### Breakdown section

Full-width band. Background: `--bg-base`. Internal padding: 20px top/bottom, 32px left/right.

Two sub-sections side by side:

**Left (~55% width): Ecosystem breakdown**
**Right (~45% width): Age breakdown**

A 1px `--border-subtle` vertical divider separates the two sub-sections. 24px padding on each side of the divider.

---

#### Left: Ecosystem breakdown

**Section label:** "By ecosystem" — `caption` (11px/500), `--text-tertiary`, uppercase letter-spacing 0.06em, left-aligned. 12px below: the ecosystem cards row.

Ecosystem cards — use component 8A from Step 2.1, adapted for a horizontal scrolling row.

Row layout:
- Cards in a single horizontal row
- Each card: 140px wide, fixed
- Gap between cards: 8px
- If more than 4 ecosystems found: the row scrolls horizontally. A subtle right fade mask (20px, `--bg-base` transparent gradient) indicates more cards beyond the viewport
- The row does not show a scrollbar

Show 5 ecosystem cards in the primary design (more than 4 to demonstrate the scroll behavior):

| Ecosystem | Size | Projects |
|---|---|---|
| Node.js | 31.2 GB | 54 projects |
| Python | 9.8 GB | 22 projects |
| Rust | 4.1 GB | 6 projects |
| Swift/Xcode | 1.8 GB | 4 projects |
| General | 0.4 GB | 18 projects |

Each card (adapted from component 8A):
- Ecosystem icon: 20px, top of card
- Ecosystem name: 12px/500 `--text-primary`
- Size: 18px/600 `--text-primary` — hero number within the card
- Project count: 11px/400 `--text-secondary`
- Card height: 88px
- The largest ecosystem (Node.js) card gets a very subtle `--accent-subtle` background tint to indicate it's the biggest contributor

---

#### Right: Age breakdown

**Section label:** "By project age" — same style as ecosystem label, left-aligned.

A horizontal stacked bar showing the four activity levels, with a legend below.

**The bar:**
- Width: fills the right sub-section minus 24px padding on each side
- Height: 12px
- Border radius: 6px
- Four segments, proportional to their GB values, using status colors:

| Segment | Value | Color |
|---|---|---|
| Dormant (2y+) | 28.4 GB | `--status-dormant` (red) |
| Inactive (6m–2y) | 14.1 GB | `--status-inactive` (amber) |
| Recent (1–6m) | 4.2 GB | `--status-recent` (blue) |
| Active (<1m) | 0.6 GB | `--status-active` (green) |

The segments are ordered left to right: dormant → inactive → recent → active. This ordering puts the "easiest to delete" content on the left.

No gap between segments — they flow as a single continuous bar. The color transitions convey the zones.

**The legend:** Below the bar (10px gap). Four rows, each row:
- Status dot (8px, using status color)
- Status label (12px/400, `--text-secondary`): "Dormant · 2+ years"
- Size (12px/500, `--text-primary`): "28.4 GB"
- Project count (12px/400, `--text-tertiary`): "31 projects"
- The size and count are right-aligned within the sub-section

Legend rows are 24px tall with 4px gap between them.

**Animation annotation:** On screen entry, the bar segments expand from left to right over 600ms ease-out, each segment starting its animation 80ms after the previous one begins. The dormant segment (largest) expands first.

---

### Actions section

Full-width band. Background: `--bg-elevated` (slightly elevated from the breakdown section — this is the action zone). Internal padding: 24px top/bottom, 40px left/right.

Three actions, left to right, with a clear visual hierarchy:

#### Action 1 — Primary CTA (right-aligned emphasis)

**"Delete dormant only (28.4 GB)"**

This is the single most important button in the entire app. It represents the safest, most confident action: delete only the dormant projects (2+ years inactive), which are the most obviously safe.

Specs:
- Primary button (component 1A), large variant (36px)
- Width: auto (fits label)
- Positioned: right side of the actions band
- Label includes the exact GB amount — recalculated from the dormant segment of the age bar
- Color: `--danger` — this is a destructive action despite being the primary CTA

Why `--danger` and not `--accent`? Because the button moves to deletion. Even though the content is safe to delete, the action color should signal consequence. The user should feel the weight of the choice — not be alarmed, but be present.

#### Action 2 — Secondary (center)

**"Review all findings →"**

Secondary button (component 1C), 32px height. Takes the user to S04 for full control.

#### Action 3 — Tertiary (left)

**"Select dormant projects"**

Ghost text link (component 1D). Pre-selects all dormant items and navigates to S04. Gives power users a shortcut to the list view with dormant pre-filtered.

---

### Bottom bar

A 36px bar pinned to the bottom of the window. Background: `--bg-elevated`. Top border: 1px `--border-subtle`.

Content (left to right):
- "Scanned ~/Projects · 84 projects · 47.3 GB total" — 12px/400, `--text-tertiary`
- Right side: "Re-scan" ghost link · "Change scan settings" ghost link (separated by `·`)

This bar persists as a footer — it provides context and secondary navigation without taking up screen space in the main content areas.

---

## States to design

### State 1 — Primary (full results, standard scan)
The design described above. This is the canonical state.

### State 2 — Partial scan variant
Same layout but with the partial scan banner in the hero section. Show as a separate frame.

### State 3 — Small results (modest findings)
What if the scan only found 2.4 GB across 8 projects? The hero number is less dramatic but the layout must still work. Show a variant with:
- Hero: "2.4 GB · recoverable across 8 projects"
- Only 2 ecosystem cards (Node.js, Python)
- Age bar still present but with different proportions
- Primary CTA: "Delete dormant only (1.1 GB)"
This variant tests that the design doesn't break or look deflated at modest numbers.

### State 4 — Nothing found
The scan found zero artifacts. Rare but possible.
- Hero section: "0 GB" — but don't show this number large and proud. Replace the hero stat with an empty state treatment:
  - SF Symbol `checkmark.circle` (40px, `--status-active`)
  - Title: "Nothing to clean up" — `title-md`, `--text-primary`
  - Subtitle: "No regenerable artifacts found in ~/Projects" — `body`, `--text-secondary`
- No breakdown section — collapse it
- Actions reduced to: "Re-scan" and "Change scan settings"

---

## Micro-details to get right

**The hero number size.** 52px/700 is larger than the `display` style defined in the type scale (28px). This is intentional and the only place in the app where type exceeds the scale. The number needs to land like a punch. 28px would feel timid. Annotate this as a one-time exception.

**The "Delete dormant only" button label** includes the GB amount in parentheses. This is load-bearing copy — the user should never have to calculate what they're about to delete. The button tells them. Keep the parenthetical exactly as shown: `(28.4 GB)`.

**The age bar ordering** (dormant left, active right) is the same left-to-right reading direction as urgency: "the stuff you should delete" to "the stuff you should keep." This is a deliberate information design choice — annotate it.

**The ecosystem card scroll.** The fade mask on the right is essential. Without it, the user has no affordance that more cards exist. The mask is not decorative — it's navigation communication.

**The bottom bar is not a status bar.** It doesn't update live. It shows the scan metadata (path, totals) that contextualizes the results. It persists on S04 and S05 as well — keep it consistent.

---

## What this screen must NOT look like

- **Not a pie chart.** A donut chart was considered (and is in the PRD) but rejected here in favor of the stacked bar. A donut chart feels like a report. A bar feels like a spectrum — which is what project age actually is.
- **Not a dashboard with too many numbers.** The hierarchy is: hero number → breakdown → action. Every element exists to support that flow. No additional metrics, no sparklines, no trend indicators.
- **Not ambiguous about what to do.** The three-action hierarchy (primary / secondary / tertiary) must be obvious at a glance. If a user has to read all three options to decide, the visual hierarchy has failed.
- **Not alarming.** Red on the dormant segment and red on the delete button are the only red elements on this screen. They are calibrated — noticeable but not aggressive. The overall feeling is opportunity, not emergency.

---

## Connections

| Action | Destination |
|---|---|
| "Delete dormant only (X GB)" | S06 — Selection Review (dormant pre-selected) |
| "Review all findings →" | S04 — Project List (no pre-selection) |
| "Select dormant projects" | S04 — Project List (dormant pre-selected) |
| "Re-scan" (bottom bar) | S02 — Scanning Progress |
| "Change scan settings" (bottom bar) | S09 — Settings |
| Settings gear (toolbar) | S09 — Settings |

---

## Deliverable frames

- [ ] S03-primary — Full results, dark mode — 900×600px
- [ ] S03-primary — Light mode variant — 900×600px
- [ ] S03-partial — Partial scan banner variant — 900×600px dark mode
- [ ] S03-modest — Small results variant (2.4 GB) — 900×600px dark mode
- [ ] S03-empty — Nothing found variant — 900×600px dark mode
- [ ] S03-min — At minimum window size 780×520px

---

## Annotation notes for handoff

- Hero number count-up animation: 0 → 47.3 over 800ms ease-out, number only (unit and label appear immediately)
- Age bar expansion animation: segments expand left-to-right, 600ms ease-out, 80ms stagger between segments
- Ecosystem card row: horizontal scroll on overflow, no scrollbar, right fade mask 20px
- Bottom bar: persists on S04 and S05 (same content, not a component that resets)
- "Delete dormant only" button: navigates directly to S06 bypassing S04 — annotate the flow skip
- The 52px hero number is a deliberate one-time exception to the type scale

---

*This prompt is Step 4.1 of 10 in the Roomy design process. This screen is the emotional peak of the first-use flow. The next screen (S04 Project List) is where the user takes control — the mood shifts from discovery to deliberate action.*
