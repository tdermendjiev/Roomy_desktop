# Roomy — S09 Settings + S10 Exclusions Manager
## Google Stitch Design Prompt · Step 5.2

---

## Context

You are designing two utility screens for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts:

- **S09 — Settings:** App preferences. Scan paths, ecosystems, activity thresholds, deletion behavior.
- **S10 — Exclusions Manager:** Manage paths and projects that should never appear in scan results.

These are the backstage screens — rarely visited, but essential. A developer who uses Roomy regularly will configure it once and mostly forget these screens exist. The design must make that one-time configuration feel effortless.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 5A checkboxes, 5B toggles, 5C radio buttons, 10B dividers)

---

## Design philosophy for utility screens

Settings screens earn respect through clarity and restraint. They do not need to be beautiful — they need to be immediately comprehensible. Every preference should answer the question "what does this control?" without requiring a tooltip.

Reference: macOS System Settings in Sonoma — the grouped sections, the label/control alignment, the lack of decoration. Roomy's settings should feel like they belong in that ecosystem.

Specific principles:
- **Labels left, controls right.** Standard macOS settings layout. Never stack label above control for simple preferences.
- **Section grouping via whitespace and subtle headers**, not heavy card borders.
- **No decorative elements.** No icons next to every section header, no gradient backgrounds, no feature callouts.
- **Destructive settings are visually demoted**, not promoted. "Permanent delete" being a radio option does not mean it should look prominent.

---

## S09 — Settings

### Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: "Settings" centered, back button navigates to wherever the user came from (S01 or S03), settings gear hidden (already in settings)
- The toolbar back button label dynamically reflects the origin: "← Results" if coming from S03, "← Roomy" if coming from S01

### Layout

Single-column settings layout. The content column is 560px wide, centered in the window. Scrollable if content exceeds window height.

```
[toolbar — 52px]
──────────────────────────────────────────────
[scrollable content]
  [section: Scan paths]
  [divider]
  [section: Ecosystems]
  [divider]
  [section: Activity thresholds]
  [divider]
  [section: Deletion behavior]
  [divider]
  [section: Exclusions]
  [divider]
  [section: About]
[bottom padding — 32px]
```

Content padding: 24px top, 0 left/right (the 560px column handles horizontal centering).

---

### Section structure

Each section follows this pattern:

**Section header:**
- Section name — `label-medium` (13px/500), `--text-tertiary`, uppercase, letter-spacing 0.06em
- Top margin: 24px above header (except first section)
- Bottom margin: 12px below header

**Preference rows:**
Each row is 44px tall. Content: label on the left, control on the right, vertically centered.
- Label: `label` (13px/400), `--text-primary`
- Sublabel (optional, below label): `caption` (11px/400), `--text-tertiary`
- Control: right-aligned

**Section divider:** 1px `--border-subtle`, full column width, 24px top margin.

---

### Section 1: Scan paths

**Row 1 — Default scan location:**
Label: "Default scan location"
Control: Radio button group (component 5C), stacked vertically below the label since there are 3 options:

Radio options (each 32px tall, indented 16px from label):
- ○ Home folder (~/) — selected by default
- ○ Custom path — when selected, reveals a text input (see below)
- ○ Entire Mac

When "Custom path" is selected, a text input appears below the radio options (indented to match):
- Height: 28px
- Width: 320px
- Placeholder: "/Users/username/Projects"
- Component 6C style but without the search icon — just a plain input

**Row 2 — Always ask:**
Label: "Ask me before each scan"
Sublabel: "Override the default location at scan time"
Control: Toggle (component 5B), right-aligned

Gap between rows: 8px.

---

### Section 2: Ecosystems

**Section intro:** Below the header, before rows:
"Choose which artifact types to scan for." — `caption` (11px/400), `--text-tertiary`
Bottom margin: 8px.

8 rows, one per ecosystem. Each row:
- Label: ecosystem name + small ecosystem icon (14px) to the left of the label
- Control: Toggle (component 5B)
- All on by default

Ecosystem rows:
| Ecosystem | Default |
|---|---|
| Node.js / npm | On |
| Python | On |
| Rust | On |
| Ruby | On |
| Go | On |
| Java / Kotlin | On |
| Swift / Xcode | On |
| General (logs, .DS_Store, temp) | On |

Below the 8 rows (8px gap):
"Select all · None" — two ghost text links (component 1D), `caption` (12px/400), separated by `·`. Right-aligned within the column.

---

### Section 3: Activity thresholds

**Section intro:**
"Customize how Roomy classifies project activity." — `caption` (11px/400), `--text-tertiary`
Bottom margin: 8px.

**Row 1 — "Dormant" threshold:**
Label: "Mark as dormant after"
Sublabel: "Projects older than this are shown in red and recommended for deletion"
Control: Dropdown (component 6B style, 28px height, 140px wide):
Options: 1 year · 2 years (default) · 3 years · 5 years

**Row 2 — "Inactive" threshold:**
Label: "Mark as inactive after"
Sublabel: "Projects in this range are shown in amber"
Control: Dropdown:
Options: 3 months · 6 months (default) · 1 year

Note: the dropdown in settings uses a slightly larger style than the compact 6B component in the list view — 28px height, full label visible, no truncation. It is a select/dropdown control, not a filter chip.

---

### Section 4: Deletion behavior

This section requires the most visual care — it contains the two most consequential preferences in the app.

**Row 1 — Deletion method:**
Label: "How to delete"
Control: Radio button group, stacked vertically below the label:

Radio options:
- ● Move to Trash (default and recommended) — selected
- ○ Permanently delete

The "Permanently delete" option needs a subdued visual treatment:
- Radio button label: `label` (13px/400), `--text-primary` — normal weight
- Sublabel below the radio (indented, 11px/400, `--danger`): "This cannot be undone. Files will not go to Trash."
- The sublabel only appears when "Permanently delete" is selected. In the default state it is hidden.

Show "Move to Trash" selected in the primary design. Show "Permanently delete" selected as a variant annotation.

**Row 2 — Empty Trash automatically:**
Label: "Empty Trash after deletion"
Sublabel: "Immediately empties Trash after Roomy moves files to it"
Control: Toggle (component 5B), off by default

When toggle is on, a sublabel changes to: "This cannot be undone." — `caption` (11px/400), `--danger`, replacing the normal sublabel.

This is the same pattern as the S06 toggle — consistent behavior, consistent visual language.

---

### Section 5: Exclusions

A simple bridge section pointing to S10.

**Row 1 — Exclusions count:**
Label: "Excluded paths"
Sublabel: "Paths and projects that never appear in scan results"
Control: Right side shows: "12 paths excluded" (`caption` 12px/400, `--text-tertiary`) + "Manage →" ghost link (component 1D, 12px/400, `--accent`), separated by a space.

Clicking "Manage →" navigates to S10.

The exclusions count ("12 paths excluded") updates to reflect actual count. If zero: "No exclusions yet".

---

### Section 6: About

Minimal. No decorative elements.

**Row 1 — Version:**
Label: "Version"
Control: "1.0.0 (42)" — `label` (13px/400), `--text-tertiary`, right-aligned. Not a button.

**Row 2 — Updates:**
Label: "Check for updates"
Control: Ghost text link (component 1D), "Check now →", right-aligned.

**Row 3 — License:**
Label: "License"
Control: "Single-user license" — `label` (13px/400), `--text-tertiary`

Below row 3, three ghost text links in a row, centered, separated by `·`:
"Documentation · GitHub · Contact"
`caption` (12px/400), `--text-tertiary` with `--accent` on hover.

---

### States to design

#### State 1 — Default (primary)
All defaults as described. "Move to Trash" selected. All ecosystems on. Custom path input hidden.

#### State 2 — Custom path selected
"Custom path" radio selected. Text input revealed below, with a realistic path entered: "/Users/alex/Projects". Show the text input in filled state.

#### State 3 — Permanent delete selected
"Permanently delete" radio selected. "This cannot be undone." sublabel visible in `--danger`. Empty Trash toggle hidden (irrelevant when permanent delete is on — annotate this conditional logic).

#### State 4 — Scrolled to bottom
Show the About section at the bottom of the window to verify it scrolls correctly and the bottom padding is adequate.

---

### Deliverable frames (S09)

- [ ] S09-primary — All defaults, top of page — 900×600px dark mode
- [ ] S09-primary — Light mode variant — 900×600px
- [ ] S09-custom-path — Custom path selected, input revealed — 900×600px dark mode
- [ ] S09-permanent-delete — Permanent delete selected, danger sublabel — 900×600px dark mode
- [ ] S09-bottom — Scrolled to About section — 900×600px dark mode

---

---

## S10 — Exclusions Manager

### Screen purpose

A focused single-task screen: manage the list of paths and projects that are permanently excluded from scan results. If a user excludes `~/work/company-project` here, it will never appear in any future scan regardless of settings.

This screen is reached from S09 (via "Manage →") or from S05 (via "Add to exclusions").

### Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: "Exclusions" centered, back button "← Settings" (if coming from S09) or "← Project" (if coming from S05), no settings gear
- The back button label adapts to the navigation origin — annotate this

### Layout

Full window. Single column, 640px wide, centered. Two zones:

```
[toolbar — 52px]
──────────────────────────────────────────────
[list header — 48px]
[exclusions list — scrollable, flex-fill]
[add controls — 52px, sticky bottom]
```

---

### List header

Height: 48px. Background: `--bg-elevated`. Bottom border: 1px `--border-subtle`. Padding: 0 24px.

Content left to right, vertically centered:
- **Title:** "Exclusions" — `title-md` (16px/600), `--text-primary`
- **Spacer**
- **Count:** "12 paths excluded" — `label` (13px/400), `--text-tertiary`

No subtitle here — the subtitle lives in S09. On this screen the user already knows what exclusions are.

---

### Exclusions list

Scrollable. Each exclusion is one row.

#### Exclusion row

Height: 52px. Padding: 0 24px. Bottom border: 1px `--border-subtle`.

Content left to right, vertically centered:

**Left side (flex):**
- **Path** — `mono-body` (13px/400), `--text-primary`, middle-truncated if long
- **Type badge** (below path, 4px gap) — component 2B (status badge) style but using neutral colors:
  - "Project" — `--bg-elevated` background, `--border-default` border, `--text-secondary` text
  - "Path" — same style
  - "Pattern" — same style, slightly different to distinguish glob patterns
- **Date added** — `caption` (11px/400), `--text-tertiary`, 8px gap after badge. Example: "Added March 14"

**Right side:**
- **Remove (×) button** — SF Symbol `xmark.circle.fill` (18px, `--text-tertiary`). On hover: `--danger`. On click: row fades out with 150ms ease-out, count in header updates.

The remove button is the only action per row. It is always visible (same rationale as S06 — this is a management screen, controls should not hide).

---

#### Exclusion data to show (primary design)

Show 6 exclusion rows in the primary design (enough to fill the visible area and hint at scrollability):

| Path | Type | Added |
|---|---|---|
| ~/work/company-project | Project | Added Jan 8 |
| ~/dev/client-contracts | Path | Added Jan 8 |
| ~/projects/ios-app | Project | Added Feb 22 |
| */vendor/* | Pattern | Added Feb 22 |
| ~/code/personal-site | Project | Added Mar 1 |
| ~/Desktop/archive | Path | Added Mar 14 |

The pattern row (`*/vendor/*`) is visually distinct — monospace path in `--text-secondary` (slightly dimmer) because it's a glob, not a literal path. The "Pattern" badge distinguishes it.

---

### Empty state

When no exclusions exist (first time, or all removed):

Centered in the list area (component 9B from Step 2.1):
- SF Symbol `shield.slash` (40px, `--text-tertiary`)
- "No exclusions yet" — `title-md` (16px/500), `--text-secondary`
- "Projects you exclude will never appear in scan results" — `body` (14px/400), `--text-tertiary`

Show as a separate variant frame.

---

### Add controls (sticky bottom bar)

Height: 52px. Full column width. Background: `--bg-elevated`. Top border: 1px `--border-subtle`. Padding: 0 24px.

Content left to right, vertically centered:

- **"Add path" button** — secondary button (component 1C, 32px height). SF Symbol `folder.badge.plus` (14px) leading icon. Opens macOS folder picker (NSOpenPanel). On selection, adds a new "Path" type exclusion row to the list with a 150ms fade-in + slight downward slide animation.

- **"Add pattern" button** — secondary button (component 1C, 32px height). SF Symbol `text.magnifyingglass` (14px) leading icon. 8px gap after "Add path". Opens an inline input for entering a glob pattern.

- **Spacer**

- **Small hint text** (right-aligned): "Changes take effect on next scan" — `caption` (11px/400), `--text-tertiary`. This is important — exclusions added here do not retroactively remove items from an open S03/S04 view. The user needs to re-scan. Annotate this behavior.

---

### "Add pattern" inline input state

When "Add pattern" is clicked, the bottom bar transforms:

The two buttons disappear (150ms fade). A text input appears in their place:

- Width: 360px
- Height: 28px
- Placeholder: "e.g. */vendor/* or ~/work/**"
- Font: `mono-body` (13px/400)
- Background: `--bg-inset`
- Border: 1px `--border-strong` (focused state)

Followed by:
- **"Add" button** — primary small (28px), `--accent`. Disabled until text is entered.
- **"Cancel" link** — ghost text link, "Cancel", dismisses input and restores original buttons

On "Add" click: the input dismisses, a new "Pattern" type row appears at the top of the list with a 150ms fade-in, the count in the header increments.

Show this state as a variant frame (S10-add-pattern).

---

### States to design

#### State 1 — Primary (list with 6 exclusions)
As described above. All 6 rows visible, add controls at bottom.

#### State 2 — Empty state
No exclusions. Empty state centered in the list. Add controls still present at bottom (the user needs to be able to add exclusions even from the empty state).

#### State 3 — Add pattern input active
Bottom bar transformed to show inline pattern input. Empty input (pre-fill state) and filled input ("*/vendor/*" entered, "Add" button enabled).

#### State 4 — Row being removed
Show the moment a row is being removed (hover state on the × button of the `~/work/company-project` row — × turns `--danger`, cursor pointer). Demonstrates the remove interaction.

---

### Micro-details

**The "Changes take effect on next scan" hint is non-negotiable.** A developer who adds an exclusion and then wonders why the project is still visible in their current scan results will be confused and possibly think the feature is broken. This single line of text prevents that confusion. It must always be visible in the add controls bar — never hidden or truncated.

**Pattern rows use `--text-secondary` for the path** — slightly dimmer than the `--text-primary` used for literal paths. This subtle distinction signals "this is a rule, not a specific location." It communicates the difference between a glob pattern and a path without requiring an explanation.

**The remove button at 18px** — slightly larger than the 16px used in other screens. On a management screen where every row has only one action, the action should be comfortably tappable. At 16px the hit target is borderline; at 18px it is comfortable.

**No confirmation dialog for remove.** Exclusions are not destructive — removing an exclusion just means the project will show up in the next scan. A confirmation dialog here would be patronizing. The fade-out animation is sufficient acknowledgment.

**No bulk-remove or "Clear all" action.** Exclusion lists are typically small (under 20 items) and rarely cleared entirely. Adding a "Clear all" button would be solving a problem that does not exist while adding visual noise that does.

---

### What these screens must NOT look like

**S09:**
- Not a web-style settings page with big section cards and heavy padding
- Not a dashboard — no charts, no usage statistics, no "you've scanned X times"
- Not alarming about destructive options — "Permanently delete" is demoted, not highlighted
- Not cluttered — 6 sections, each with 1–4 rows. If it feels like too many settings, consider whether each one is truly necessary

**S10:**
- Not a modal — it is a full navigable screen
- Not a data table — the rows are not a spreadsheet with sortable columns
- Not a file browser — it shows the exclusions list, not the contents of excluded paths
- Not over-engineered — there are two actions (add path, add pattern) and one per-row action (remove). That is all.

---

### Connections

| Screen | Action | Destination |
|---|---|---|
| S09 | "Manage →" (Exclusions section) | S10 |
| S09 | Back button | S01 or S03 (origin-dependent) |
| S10 | Back button | S09 (or S05 if navigated from project detail) |
| S10 | "Add path" | macOS NSOpenPanel folder picker |
| S10 | "Add pattern" | Inline input mode (stays on S10) |
| S10 | Remove (×) on row | Removes row, stays on S10 |

---

### Deliverable frames

**S09:**
- [ ] S09-primary — All defaults — 900×600px dark mode
- [ ] S09-primary — Light mode variant — 900×600px
- [ ] S09-custom-path — Custom path input revealed — 900×600px dark mode
- [ ] S09-permanent-delete — Permanent delete selected, danger sublabel — 900×600px dark mode
- [ ] S09-scrolled — About section visible — 900×600px dark mode

**S10:**
- [ ] S10-primary — 6 exclusions visible, add controls — 900×600px dark mode
- [ ] S10-primary — Light mode variant — 900×600px
- [ ] S10-empty — Empty state with add controls — 900×600px dark mode
- [ ] S10-add-pattern — Inline pattern input active — 900×600px dark mode
- [ ] S10-removing — Hover state on remove button — 900×600px dark mode
- [ ] S10-min — Minimum window size 780×520px

---

### Annotation notes for handoff

**S09:**
- Custom path input: revealed on "Custom path" radio select, 150ms ease-out height animation
- "Permanently delete" sublabel: appears only when that radio is selected, 150ms ease-out
- "Empty Trash" toggle: hidden when "Permanently delete" is selected (irrelevant — annotate conditional)
- "Empty Trash" toggle on: sublabel text → "This cannot be undone." in `--danger`
- All settings: auto-save on change, no save button required
- "Manage →" link: navigates to S10

**S10:**
- Remove (×): `--text-tertiary` → `--danger` on hover, 80ms; row fade-out on click, 150ms
- "Add path": opens NSOpenPanel, on selection inserts row at bottom of list with 150ms fade-in
- "Add pattern" input: bottom bar transforms 150ms, input autofocused on appear
- Pattern "Add" button: disabled until ≥3 characters entered
- Row added from S05 "Add to exclusions": appears at top of list with "Project" badge, current date
- "Changes take effect on next scan": always visible, never truncated

---

*This prompt is Step 5.2 of 10 — the final prompt in the Roomy design process. All 10 screens are now fully specified. The complete prompt set is: 1.1 Visual Identity · 1.2 App Icon · 2.1 Components · 3.1 S01 · 3.2 S02 · 4.1 S03 · 4.2 S04 · 4.3 S05 · 4.4 S06 · 5.1 S07+S08 · 5.2 S09+S10.*
