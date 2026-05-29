# Roomy — S04 Results: Project List
## Google Stitch Design Prompt · Step 4.2

---

## Context

You are designing the **Project List screen** (S04) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This is the main working view. The user spends more time here than on any other screen. It is where they browse, inspect, select, and build their deletion list. It must handle information density gracefully — dozens of projects, multiple ecosystems, varying states — without feeling overwhelming.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 3A/3B/3C project rows, 6A/6B/6C filter controls, 8B summary number)

---

## Screen purpose

The user arrives here from S03 in one of three states:
- **No pre-selection** ("Review all findings") — everything visible, nothing selected
- **Dormant pre-selected** ("Select dormant projects") — all dormant projects have checkboxes checked
- **Navigating back** from S05 Project Detail — their previous selections intact

The screen must support two modes of use:
1. **Quick mode** — user scans the list, checks a few things, hits "Review and delete". Entire interaction under 60 seconds.
2. **Careful mode** — user sorts, filters, drills into individual projects, builds a precise selection. May take several minutes.

Both modes must feel natural. The layout should not impose a workflow.

---

## Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: "Results" label centered, back button "← Results" pointing back to S03, settings gear right

---

## Layout

Two-column layout. The window is divided vertically into a left column (project list) and a right column (selection summary). They are separated by a 1px `--border-subtle` vertical divider.

```
[toolbar — 52px]
┌─────────────────────────────┬──────────────────────┐
│  Left column — 60%          │  Right column — 40%  │
│  (540px at 900px window)    │  (360px)             │
│                             │                       │
│  List controls — 76px       │  Selection summary   │
│  ─────────────────          │  (sticky, full height│
│  Project rows               │   minus toolbar)     │
│  (scrollable)               │                       │
│                             │                       │
├─────────────────────────────┴──────────────────────┤
│  Bottom bar — 36px                                  │
└────────────────────────────────────────────────────┘
```

The right column is sticky — it does not scroll with the project list. The left column scrolls independently.

The bottom bar spans the full width.

---

## Left column — Project list

### List controls bar

Two sub-bars stacked vertically, total 76px.

**Sub-bar 1 — Sort and filter controls (44px height):**
Background: `--bg-elevated`. Bottom border: 1px `--border-subtle`. Padding: 0 16px.

Content left to right, vertically centered:
1. **Select all checkbox** (component 5A, 16px) — leftmost. Indeterminate when some rows are selected. Checked when all visible rows are selected.
2. **Selection count label** — 12px/400, `--text-tertiary`, 8px gap after checkbox. "41 of 84 selected" when items are selected. Hidden when nothing selected.
3. **Spacer (flex)**
4. **Search input** (component 6C) — 160px wide, "Filter projects…"
5. **Ecosystem dropdown** (component 6B) — 8px gap. "All ecosystems" default label.
6. **Sort dropdown** (component 6B) — 8px gap. "Oldest first" default label.

**Sub-bar 2 — Activity filter chips (32px height):**
Background: `--bg-base`. Bottom border: 1px `--border-subtle`. Padding: 0 16px.

Content: filter chips row (component 6A) — All · Dormant · Inactive · Recent · Active. "All" selected by default. Left-aligned, 6px gap between chips.

---

### Project rows

Uses component 3A (collapsed) and 3B (expanded) from Step 2.1.

**Row height:** 52px collapsed. Expands to accommodate artifact sub-rows (40px each) when opened.

**Scroll behavior:** The list is independently scrollable. Standard macOS overlay scrollbar.

**Visible rows:** At 900×600px, with toolbar (52px) + controls (76px) + bottom bar (36px), the scrollable content height is 436px. At 52px per row, approximately **8 complete rows** are visible. Show exactly 8 rows in the primary design — no partial rows.

---

#### Primary design state — dormant pre-selected

Show the list with all dormant projects pre-selected (arrived from S03 "Select dormant projects"). This is the most visually rich state.

Show 8 rows:

| # | Project | Path | Status | Ecosystems | Size | Selected |
|---|---|---|---|---|---|---|
| 1 | startup-2021 | ~/projects/startup-2021 | Dormant · 3 years ago | npm | 4.2 GB | ✓ |
| 2 | ml-experiments | ~/code/ml-experiments | Dormant · 2.5 years ago | py | 3.8 GB | ✓ |
| 3 | learning-rust | ~/rust/learning-rust | Dormant · 2 years ago | rust | 4.1 GB | ✓ |
| 4 | client-portal-v1 | ~/projects/clients/portal | Dormant · 4 years ago | npm, py | 2.9 GB | ✓ |
| 5 | portfolio-2020 | ~/projects/portfolio-2020 | Inactive · 14 months ago | npm | 890 MB | ✗ |
| 6 | data-analysis | ~/code/data-analysis | Inactive · 8 months ago | py | 2.3 GB | ✗ |
| 7 | ios-prototype | ~/dev/ios-prototype | Recent · 3 months ago | swift | 1.8 GB | ✗ |
| 8 | current-project | ~/projects/current | Active · 2 days ago | npm, rust | 340 MB | ✗ |

This distribution shows the full range of status colors in a single viewport. The top of the list is red (delete confidently) and the bottom is green (keep). This is the visual argument for the app made in a single list view.

**Row 1 — show in expanded state.** The startup-2021 row is expanded to show two artifact sub-rows:
- `node_modules` · `~/projects/startup-2021/node_modules` · 3.9 GB · selected
- `.next/` · `~/projects/startup-2021/.next` · 340 MB · selected

The expanded group adds ~80px to row 1 (2 sub-rows × 40px). A 2px left border in `--status-dormant` color runs the full height of the expanded group, visually tying the sub-rows to their parent.

**Row 8 (active project)** — show with `--status-active` at 6% opacity background tint. Unselected. Green activity dot. This is the gentlest possible visual warning: "this project is alive."

---

### Empty list state

When filters produce zero results, show component 9A centered in the list area (Step 2.1).

---

## Right column — Selection summary

Sticky. Always visible. Answers one question at all times: "What will happen if I proceed?"

### Empty state (nothing selected)

Centered vertically in the column:
- SF Symbol `checkmark.circle.dashed` (32px, `--text-tertiary`)
- "Select projects to delete" — 14px/500, `--text-secondary`, 8px below icon
- "Check rows in the list to build your deletion set." — 13px/400, `--text-tertiary`, 4px below

"Review and delete →" button is present but disabled (35% opacity).

### Active state (items selected — primary design)

**Header:** "Selected for deletion" — `title-md` (16px/600), `--text-primary`. 20px from top, 20px left padding.

**Total size:** "31.4 GB" — component 8B (summary number), 12px below header. Updates live as checkboxes toggle.

**Ecosystem breakdown:** Below total (12px gap):
- "Node.js" · "24.1 GB"
- "Python" · "7.3 GB"
Label: 13px/400 `--text-secondary` · Value: 13px/500 `--text-primary`. Each row 24px tall.

**Item count:** "67 artifact folders across 41 projects" — 12px/400, `--text-tertiary`, 8px below breakdown.

**Divider** — 1px `--border-subtle`, full column width, 16px vertical margin.

**"Review and delete →" button:** Primary large button (component 1A), `--danger` color, full column width minus 40px (20px padding each side).

**"Clear selection" link:** Ghost text link (component 1D), centered, 8px below button.

---

## Bottom bar

Full window width, 36px height, `--bg-elevated`, top border 1px `--border-subtle`.

- Left: "84 projects · 47.3 GB total found" — 12px/400, `--text-tertiary`
- Right: "41 projects · 31.4 GB selected" — selected portion in `--text-primary`, updates live

---

## States to design

### State 1 — Dormant pre-selected (primary)
As fully described above.

### State 2 — Nothing selected
Same list, no checkboxes checked. Right panel in empty/nudge state. "Review and delete" button disabled.

### State 3 — Filter active: "Dormant" chip
Only rows 1–4 visible (all dormant). "Dormant" chip active with `--status-dormant` color. Bottom bar: "31 projects visible · 28.4 GB".

### State 4 — Search active
Search input shows "startup". Only row 1 visible. Clear (×) button shown in search input.

### State 5 — All selected
All 84 projects selected. Header checkbox checked. Right panel shows 47.3 GB. Controls bar selection count: "84 of 84 selected".

---

## Micro-details to get right

**Default sort order.** Although the PRD suggests "largest first" as default, this design uses **"Oldest first"** as the default sort. Rationale: the most actionable projects for a developer are the oldest ones, not necessarily the largest. The list sorted oldest-first immediately shows the user their most confidently deletable projects at the top. Annotate this as a deliberate deviation from the PRD default, with the rationale.

**The 2px left border on expanded rows** is load-bearing. Without it, the artifact sub-rows appear to float unconnected below the project row. The border creates a visual bracket that says "these belong to that."

**The "What is this?" link on sub-rows.** Must be visible but not dominant. `--accent` 11px/400, positioned between the artifact name and the size column. Appears on hover in a more focused state if needed, but should be visible by default — it is an important affordance for developers who don't know every artifact type.

**The right panel updates live.** Every checkbox toggle immediately updates the total, breakdown, and count in the right panel. The number change uses an 80ms count animation — fast enough to feel responsive, slow enough to be perceptible.

**Row 8's green tint.** Very subtle — 6% opacity. If it reads as a strong green background, it's too heavy. It should be the kind of thing the user notices on second glance, not immediately. The green activity dot is the primary signal; the tint is reinforcement.

**The minimum window (780px).** At this width, the left column is ~468px and the right column is ~312px. The right column "Review and delete →" button must remain readable and tappable. Test this specifically.

---

## What this screen must NOT look like

- **Not a file manager.** No tree view, no folder hierarchy beyond one-level expansion, no file type icons.
- **Not a spreadsheet.** No column headers above the rows. The row layout is self-evident from context.
- **Not visually uniform.** The contrast between red dormant rows and green active rows is the entire visual argument of the app. Rows must look meaningfully different based on their status.
- **Not a modal with a list.** The right column is a permanent fixture — not a panel that appears on demand. It is always there.

---

## Connections

| Action | Destination |
|---|---|
| "Review and delete →" (right panel) | S06 — Selection Review |
| Project row click (not checkbox area) | S05 — Project Detail |
| Expand arrow on row | Inline expansion — stays on S04 |
| Back button (toolbar) | S03 — Results Overview |
| Settings gear | S09 — Settings |

---

## Deliverable frames

- [ ] S04-primary — Dormant pre-selected, row 1 expanded — 900×600px dark mode
- [ ] S04-primary — Light mode variant — 900×600px
- [ ] S04-empty-selection — Nothing selected, right panel nudge state — 900×600px dark mode
- [ ] S04-filter-dormant — "Dormant" filter chip active — 900×600px dark mode
- [ ] S04-search — Search active, 1 result — 900×600px dark mode
- [ ] S04-all-selected — All selected — 900×600px dark mode
- [ ] S04-min — Minimum window size 780×520px

---

## Annotation notes for handoff

- Left column: independently scrollable, standard macOS overlay scrollbar
- Right column: sticky, does not scroll
- Checkbox toggle → right panel updates, 80ms count animation
- Expand arrow: 150ms ease-out rotation, sub-rows slide in 150ms ease-out
- "What is this?" tooltip: 400ms hover delay, component 4A from Step 2.1
- Bottom bar right side: live update on selection change
- Default sort: "Oldest first" (deliberate deviation from PRD — annotate rationale)
- Row 8 active tint: `--status-active` at 6% opacity — annotate exact value
- Min right column: 312px at 780px window — verify button fit

---

*This prompt is Step 4.2 of 10 in the Roomy design process. The next screen (S05 Project Detail) is the drill-down view — it should feel like a natural child of this list, not a separate context.*
