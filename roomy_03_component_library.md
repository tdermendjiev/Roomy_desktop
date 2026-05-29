# Roomy — Component Library
## Google Stitch Design Prompt · Step 2.1

---

## Context

You are designing the complete UI component library for **Roomy** — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This is the component reference that all screen designs (Steps 3.1 through 5.2) will be built from. Every component here will appear in at least one screen. Design them with that reuse in mind — they must work in isolation and in composition.

**Before starting:** Load the visual identity established in Step 1.1:
- Dark-first, clean minimal, Raycast/Linear aesthetic
- Electric blue accent (`--accent`)
- Two typefaces: UI sans (Geist or equivalent) + monospace (Geist Mono or equivalent)
- 4px spacing grid
- macOS-native conventions throughout

Produce all components in both **dark mode** and **light mode**. Organize as a Figma component library with properly named variants and auto-layout.

---

## Component inventory

---

### 1. Buttons

#### 1A. Primary button (accent)
The main CTA. Used for "Start scan", "Review and delete", "Scan again".

Specs:
- Height: 32px
- Horizontal padding: 16px
- Border radius: 6px
- Background: `--accent`
- Text: `--text-inverted`, 13px/500 (label-medium)
- Icon: optional leading icon (SF Symbol, 14px, same color as text)

States: `default` · `hover` · `pressed` · `disabled` · `loading`

Loading state: replace label with a spinning indicator (SF Symbol `arrow.2.circlepath`, animating). Keep button width fixed — no layout jump.

Disabled state: `--accent` at 35% opacity. Cursor: not-allowed.

Size variants: `sm` (28px height) · `md` (32px, default) · `lg` (36px)

---

#### 1B. Destructive button
Used exclusively for "Delete X GB" — the final deletion confirmation.

Specs:
- Same geometry as Primary
- Background: `--danger`
- Text: white

States: `default` · `hover` · `pressed` · `disabled` · `countdown`

**Countdown state (critical):** On first use, the button is locked for 2 seconds before becoming pressable. During this state:
- Background: `--danger` at 45% opacity
- A progress fill sweeps left-to-right across the button background over exactly 2 seconds (linear)
- Label shows: "Delete 31.4 GB" with a small lock icon (SF Symbol `lock.fill`) to the left
- At 2 seconds: lock icon disappears, full opacity restored, button becomes pressable
- On subsequent uses in the same session: no countdown, button is immediately active

Show all five states including the countdown at 0%, 50%, and 100% progress.

---

#### 1C. Secondary button
Ghost-style. Used for "View last scan", "Back to results", "Clear selection", "Cancel".

Specs:
- Height: 32px (same as primary)
- Horizontal padding: 16px
- Border radius: 6px
- Background: transparent
- Border: 1px `--border-default`
- Text: `--text-primary`, 13px/500

States: `default` · `hover` · `pressed` · `disabled`

Hover: background fills with `--bg-hover`.

---

#### 1D. Ghost / text button
Minimal. Used for inline actions — "Select all", "None", "View in Trash", "Not now", "Re-scan".

Specs:
- No background, no border
- Text: `--accent`, 13px/400
- Padding: 4px 8px

States: `default` · `hover` · `pressed` · `disabled`

Hover: subtle `--accent-subtle` background pill behind the text.

---

#### 1E. Icon button
Square button for icon-only actions — toolbar settings gear, close panels, "Open in Finder", "Open in Terminal".

Specs:
- Size: 28×28px
- Border radius: 6px
- Background: transparent
- Icon: SF Symbol, 16px, `--text-secondary`

States: `default` · `hover` · `pressed`

Hover: `--bg-hover` background.

---

### 2. Status indicators

#### 2A. Activity dot
The core visual signal for project age classification. Used in every project row.

Specs:
- Size: 8px diameter, filled circle
- Four variants strictly using status colors:

| Variant | Color token | Label |
|---|---|---|
| `active` | `--status-active` | Active |
| `recent` | `--status-recent` | Recent |
| `inactive` | `--status-inactive` | Inactive |
| `dormant` | `--status-dormant` | Dormant |

Show each dot both standalone and paired with its label text (13px/500, matching `--status-X-text` color).

Example: `● Dormant · Last active 3 years ago`

The dot and label are always shown together in context. The dot alone is only used at very small sizes (16px row height or smaller).

---

#### 2B. Status badge (pill)
Used in the Project Detail screen header and in filter chips.

Specs:
- Height: 20px
- Horizontal padding: 8px
- Border radius: 10px (full pill)
- Background: `--status-X-bg`
- Border: 1px `--status-X` at 30% opacity
- Text: `--status-X-text`, 11px/500

Four variants matching 2A.

Example: a red pill reading "Dormant" in the project detail header.

---

#### 2C. Ecosystem badge
Small icon+label badge identifying the programming ecosystem of a project. Used in project rows and the overview screen.

Specs:
- Height: 20px
- Horizontal padding: 6px (icon) + 4px gap + label
- Border radius: 4px
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Icon: ecosystem icon at 12px
- Text: `--text-secondary`, 11px/400

Variants: `node` · `python` · `rust` · `ruby` · `go` · `java` · `swift` · `general`

Show all 8 variants in a row. Also show a "stacked" state for when a project has multiple ecosystems (show first 2 badges + "+2 more" overflow indicator).

---

### 3. Project row

The most important component in the app. Used in S04 (Project List) and S06 (Selection Review). Must be pixel-perfect — the entire results experience is a list of these.

#### 3A. Project row — collapsed (default)

Height: 52px
Full width of the left column.

Left to right layout:
1. **Checkbox** (16px) — left edge, vertically centered. 12px from left edge.
2. **Activity dot** (8px) — 8px gap after checkbox
3. **Project info block** (flex, fills remaining width):
   - Line 1: Project name — 14px/500 `--text-primary` · Ecosystem badges (up to 2, then overflow) — right-aligned on the same line
   - Line 2: Path — 13px/400 `--text-secondary` monospace, truncated middle · Age label — `--status-X-text` 13px/400
4. **Size** — right-aligned, 14px/500 `--text-primary`, 60px fixed width
5. **Expand arrow** (SF Symbol `chevron.right`, 12px, `--text-tertiary`) — rightmost, 12px from right edge

Vertical rhythm:
- Project name baseline at ~20px from top
- Path/age baseline at ~36px from top

States to show:
- `default` — unselected, collapsed
- `hover` — `--bg-hover` background, expand arrow slightly more visible
- `selected` — checkbox checked, `--bg-selected` background tint
- `selected-hover` — selected + hover combined
- `indeterminate` — some artifacts selected, not all (checkbox in indeterminate state)

---

#### 3B. Project row — expanded

When the expand arrow is clicked, the row expands to show artifact sub-rows below it.

The project row itself stays at 52px, but:
- `chevron.right` rotates 90° to `chevron.down`
- A subtle left border accent (2px, `--status-X` color) appears on the left edge of the expanded group
- Artifact sub-rows appear below, indented

The expanded group (project row + all its sub-rows) has a subtly differentiated background to show grouping: `--bg-elevated` at very low opacity behind the entire group.

---

#### 3C. Artifact sub-row

Height: 40px
Indented 32px from the left edge of the project row.

Left to right layout:
1. **Checkbox** (16px) — at the indent position
2. **Artifact type icon** (14px SF Symbol or custom — e.g. `folder.fill` for node_modules) — `--text-tertiary`
3. **Artifact info:**
   - Artifact name — 13px/500 `--text-primary` (e.g. "node_modules")
   - Path — 11px/400 `--text-tertiary` monospace (truncated middle)
4. **"What is this?" link** — `--accent` 11px/400, aligned right of the artifact name · shows tooltip on hover
5. **Size** — right-aligned, 13px/500 `--text-secondary`, same 60px column as parent

States: `default` · `hover` · `selected`

---

### 4. Tooltips & disclosures

#### 4A. "What is this?" tooltip
Appears when hovering the "What is this?" link on an artifact sub-row. Explains the artifact type in plain language.

Specs:
- Max width: 280px
- Padding: 12px 14px
- Border radius: 8px
- Background: `--bg-elevated` (slightly higher elevation than base)
- Border: 1px `--border-default`
- Shadow: `0 4px 16px rgba(0,0,0,0.4)` in dark / `0 4px 16px rgba(0,0,0,0.12)` in light

Content structure:
- **Title:** Artifact name — 13px/500 `--text-primary` (e.g. "node_modules")
- **Body:** 2–3 sentence explanation — 12px/400 `--text-secondary`, line-height 1.5
- **Regenerate hint:** Monospace command — 11px/400, background `--bg-inset`, border-radius 4px, inline code pill style

Example content for `node_modules`:
> **node_modules**
> npm dependency cache. Contains all packages listed in package.json. Completely safe to delete — nothing permanent is stored here.
> Restore with: `npm install`

Show the tooltip in context — appearing above an artifact sub-row, with the "What is this?" link visible below it.

---

#### 4B. Disclosure triangle (ecosystem filter)
Used on the Welcome screen for "Advanced: choose ecosystems". A standard macOS-style disclosure row.

Specs:
- Height: 32px
- SF Symbol `chevron.right` (12px) that rotates to `chevron.down` when expanded
- Label: 13px/400 `--text-secondary`

Show: collapsed state and expanded state (with the checkbox grid visible below).

---

### 5. Checkboxes and selection controls

#### 5A. Checkbox
Standard macOS-style checkbox, slightly refined.

Specs:
- Size: 16×16px
- Border radius: 4px
- Border: 1.5px `--border-default` in unchecked state
- Background (checked): `--accent`
- Checkmark: white SF Symbol `checkmark`, 10px

States: `unchecked` · `unchecked-hover` · `checked` · `checked-hover` · `indeterminate` · `disabled`

Indeterminate state: horizontal dash instead of checkmark. Background: `--accent`. Used on project rows when only some artifacts are selected.

---

#### 5B. Toggle switch
Used in Settings and the Selection Review screen ("Empty Trash after deletion").

Follow macOS toggle style exactly — this is an NSSwitch. Show on and off states. The active color is `--accent`.

---

#### 5C. Radio button
Used in Settings for scan path selection and deletion behavior.

Follow macOS radio button style. Active color `--accent`.

---

### 6. Filter and sort controls

#### 6A. Filter chips (activity filter)
The horizontal row of filter pills at the top of the Project List. Single-select.

Specs:
- Height: 26px
- Horizontal padding: 10px
- Border radius: 6px
- Default state: `--bg-elevated` background, `--border-subtle` border, `--text-secondary` text, 12px/500
- Active state: `--accent-subtle` background, `--accent` border (1px), `--accent` text

Variants: `All` · `Dormant` · `Inactive` · `Recent` · `Active`

The "Dormant" and "Inactive" chips in active state should use their respective status colors (`--status-dormant`, `--status-inactive`) rather than the accent — to reinforce the color coding. "All" uses accent. "Recent" and "Active" use their status colors too.

Show the full row of 5 chips with "Dormant" selected.

---

#### 6B. Sort / filter dropdown
The sort control ("Sort by size (largest first)") and ecosystem filter at the top of the Project List.

Specs:
- Height: 26px
- Horizontal padding: 10px
- Border radius: 6px
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Text: 12px/400 `--text-secondary`
- Trailing: SF Symbol `chevron.up.chevron.down` (10px, `--text-tertiary`)

States: `default` · `hover` · `open` (dropdown visible)

Dropdown menu (open state):
- Background: `--bg-elevated`
- Border: 1px `--border-default`
- Shadow: standard popover shadow
- Row height: 28px, 12px/400 `--text-primary`
- Selected option: `--accent-subtle` background, `--accent` checkmark leading

---

#### 6C. Search / filter input
"Filter projects…" input at the top of the Project List.

Specs:
- Height: 26px
- Horizontal padding: 8px
- Border radius: 6px
- Background: `--bg-inset`
- Border: 1px `--border-subtle`
- Leading: SF Symbol `magnifyingglass` (12px, `--text-tertiary`)
- Placeholder text: `--text-tertiary`, 12px/400
- Active text: `--text-primary`, 12px/400
- Clear button (×): appears when text is present, SF Symbol `xmark.circle.fill`, `--text-tertiary`

States: `empty` · `focused` · `filled`

Focused: border becomes `--border-strong` (or `--accent` at 50% opacity). No glow effect.

---

### 7. Progress indicators

#### 7A. Scan progress — indeterminate
Used at the start of a scan before file count is known.

A horizontal line progress indicator (not a spinning wheel — the scan is a filesystem traversal, a line communicates "moving through something"). The line pulses or slides — a subtle shimmer moving left to right.

Specs:
- Height: 2px
- Width: full container width (typically 320px in the centered scan screen)
- Color: `--accent`
- Animation: sliding shimmer, 1.5s loop

---

#### 7B. Scan progress — determinate
Once file count is known, switches to a filled progress bar.

Specs:
- Height: 4px
- Border radius: 2px
- Track: `--border-subtle` (low opacity background)
- Fill: `--accent`
- Animation: real-time fill, linear easing

Show at: 0%, 35%, 75%, 100% (complete — full fill).

---

#### 7C. Deletion progress bar
Used in S07. Heavier than the scan bar — the deletion is the main event.

Specs:
- Height: 8px
- Border radius: 4px
- Track: `--border-subtle`
- Fill: gradient from `--accent` (left) to a slightly lighter blue (right) — the only gradient in the app, used here to give the bar visual weight
- Show at 0%, 50%, 100%

---

#### 7D. Disk space bar
Used in S06 (Selection Review side panel) and S08 (Summary). Shows used/free disk space before and after deletion.

Specs:
- Height: 12px
- Width: 240px
- Border radius: 6px
- Track: `--bg-inset`
- Used space fill: `--text-tertiary` (neutral gray — disk usage is not good or bad)
- To-be-freed fill: `--accent` (the space Roomy will reclaim — highlighted)
- Free space: empty track

Show two versions side by side:
- "Before" — used (gray) + to-be-freed (accent blue) + free (empty)
- "After" — used (gray, smaller) + free (empty, larger)

Label the three zones with small callout text.

---

### 8. Data display components

#### 8A. Stat card
Used in S03 (Overview) for the ecosystem breakdown.

Specs:
- Width: ~160px (4 fit in a row with gaps)
- Padding: 14px
- Border radius: 8px
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`

Content:
- Ecosystem icon (24px, top left)
- Ecosystem name (13px/500 `--text-primary`)
- Total size (20px/600 `--text-primary`) — this is the hero number
- Project count (12px/400 `--text-secondary`) — "54 projects"

States: `default` · `hover` (border becomes `--border-default`, slight background lift)

Show all 8 ecosystem variants in a 4-column grid.

---

#### 8B. Summary number row
Used in S03 and S08 for the hero stat display ("47.3 GB recoverable").

Specs:
- The number itself: 48px/600 `--text-primary`
- The unit (GB): 28px/400 `--text-secondary`, baseline aligned with the number
- The label below: 14px/400 `--text-secondary`

Example:
```
47.3 GB
recoverable across 84 projects
```

Show with a subtle count-up animation hint — indicate in the spec that this number should animate from 0 to its final value over 800ms (ease-out) when the screen first appears.

---

#### 8C. Before / after comparison
Used in S08 (Summary). Two numbers side-by-side showing disk state change.

Layout:
- "Before" label + number (grayed out)
- Arrow right (SF Symbol `arrow.right`, `--text-tertiary`)
- "After" label + number (`--text-primary`)
- "Freed" highlight: the difference, shown below in `--accent` color with a `--accent-subtle` background pill

---

#### 8D. Live findings ticker
Used in S02 (Scanning Progress). A scrolling log of artifacts being discovered in real time.

Specs:
- Container: 360px wide, 5 rows visible (5 × 22px = 110px height)
- Each row: artifact type + path + size
  - Artifact name: 12px/500 `--text-primary`
  - Path: 12px/400 `--text-secondary` monospace, truncated middle
  - Size: 12px/400 `--accent`, right-aligned
- New items appear at top with a subtle fade-in
- Oldest items fade out at the bottom
- The whole ticker has a fade-to-transparent mask at top and bottom edges

Show a static mock with 5 rows of realistic data:
```
node_modules    ~/projects/startup-2021/…    1.2 GB
__pycache__     ~/code/ml-experiments/…     340 MB
target/         ~/rust/learning-project/…    4.1 GB
.next/          ~/projects/portfolio-2020/…  890 MB
venv/           ~/code/data-analysis/…       2.3 GB
```

---

### 9. Empty states

#### 9A. Empty list state
When filters result in zero visible projects.

Specs:
- Centered in the list column
- SF Symbol icon (48px, `--text-tertiary`) — use `magnifyingglass` or `tray`
- Title: 14px/500 `--text-primary` — "No projects match this filter"
- Subtitle: 13px/400 `--text-secondary` — "Try removing a filter or changing the ecosystem selection"
- Optional: ghost button to clear filters

---

#### 9B. Exclusion list empty state
For S10 when no exclusions have been added yet.

- SF Symbol `shield.slash` (48px, `--text-tertiary`)
- Title: "No exclusions yet"
- Subtitle: "Projects you exclude will never appear in scan results"

---

### 10. Miscellaneous

#### 10A. Path display pill
Anywhere a filesystem path is shown prominently (not inline in a row).

Specs:
- Background: `--bg-inset`
- Border: 1px `--border-subtle`
- Border radius: 6px
- Padding: 6px 10px
- Text: 13px/400 monospace `--text-secondary`
- Truncation: middle truncation with `…`
- Optional: SF Symbol `folder` (12px, `--text-tertiary`) as leading icon
- Optional: SF Symbol `doc.on.doc` (copy) as trailing action

Show: `~/projects/old-client-project/frontend/node_modules`
And truncated: `~/projects/old-client-proj…/node_modules`

---

#### 10B. Section divider
Between sections in lists, settings, and panels.

Specs:
- Height: 1px
- Color: `--border-subtle`
- Optional label variant: divider with a centered label (13px/400 `--text-tertiary`, background matches parent — used in S06 grouped deletion list to separate projects)

---

#### 10C. Toolbar
The persistent toolbar that appears across all post-scan screens.

Specs:
- Height: 52px
- Background: macOS toolbar material (NSVisualEffectView, .titlebar material)
- Bottom border: 1px `--border-subtle`

Content (left to right):
- Traffic lights (standard macOS, do not restyle)
- Back button: SF Symbol `chevron.left` + label "Back" — only shown when applicable. 13px/400 `--text-secondary`. Disabled when on the top-level screen.
- Center: current view label — 13px/500 `--text-primary`
- Right: settings icon button (SF Symbol `gear`, 16px) — uses 1E icon button component

Show: toolbar in the context of a scan results screen (label: "Results") with back button visible and settings gear.

---

## Figma file organization

Structure the component library as follows:

```
Roomy / Components
├── 01 Buttons
│   ├── Primary
│   ├── Destructive
│   ├── Secondary
│   ├── Ghost
│   └── Icon button
├── 02 Status
│   ├── Activity dot
│   ├── Status badge
│   └── Ecosystem badge
├── 03 Project row
│   ├── Collapsed
│   ├── Expanded
│   └── Artifact sub-row
├── 04 Tooltips
│   ├── What is this
│   └── Disclosure triangle
├── 05 Selection controls
│   ├── Checkbox
│   ├── Toggle
│   └── Radio
├── 06 Filter controls
│   ├── Filter chips
│   ├── Dropdown
│   └── Search input
├── 07 Progress
│   ├── Indeterminate bar
│   ├── Determinate bar
│   ├── Deletion bar
│   └── Disk space bar
├── 08 Data display
│   ├── Stat card
│   ├── Summary number
│   ├── Before/after
│   └── Findings ticker
├── 09 Empty states
│   ├── Empty list
│   └── Exclusions empty
└── 10 Misc
    ├── Path pill
    ├── Section divider
    └── Toolbar
```

Each component must:
- Use Figma variables mapped to the Step 1.1 color tokens
- Have properly named variants (using Figma variant properties, not separate frames)
- Use auto-layout throughout — no fixed-position components
- Be documented with a usage note in the component description field

---

## Quality bar

Before considering any component complete, verify:

- [ ] Works in dark mode and light mode with zero hardcoded colors
- [ ] All text uses the type scale from Step 1.1 — no ad-hoc font sizes
- [ ] All spacing is a multiple of 4px
- [ ] All states are present (at minimum: default, hover, active/selected, disabled)
- [ ] Monospace font is used for all paths, sizes in path context, and code references
- [ ] No gradients except the deletion progress bar (7C) and only as specified
- [ ] Scales legibly — nothing breaks if the window is resized to 780px minimum

---

*This prompt is Step 2.1 of 10 in the Roomy design process. Every subsequent screen prompt (Steps 3.1–5.2) will reference these components by name. Build them to production quality — the screen designs are assembled from this library.*
