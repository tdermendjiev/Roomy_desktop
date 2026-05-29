# Roomy — Visual Identity & Design Language
## Google Stitch Design Prompt · Step 1.1

---

## What you are designing

A complete visual identity system for **Roomy** — a native macOS utility app for developers.

Roomy scans your machine for regenerable developer artifacts (node_modules, Python venvs, Rust target directories, build caches) and helps you safely reclaim disk space. It understands which projects are dormant vs active, and lets you delete with confidence.

**One-time purchase. No subscription. No cloud. No telemetry. Does one thing exceptionally well.**

Produce the following deliverables as a single Figma file:
- Color system (dark + light mode tokens)
- Typography scale
- Iconography style guide
- Spacing & layout grid
- Component states reference (interactive states)
- Brand voice & personality reference card

---

## App name & tagline

**Name:** Roomy

**Tagline options (pick the strongest or propose a better one):**
- "Reclaim disk space from dormant projects."
- "Make room. Delete nothing permanent."
- "Your projects are hoarding. Roomy helps."

The name should feel confident and slightly playful — not clinical. It implies space, breathing room, and cleanliness without being precious about it.

---

## Personality

Roomy is a **precision tool for developers**. Its personality lives at the intersection of:

- **Raycast** — clean, keyboard-friendly, dark-first, instantly feels native to macOS power users
- **Linear** — opinionated minimalism, sharp typography, data-dense without feeling cluttered
- **A quality CLI tool** — honest, no-nonsense, respects the user's intelligence

Roomy is NOT:
- A consumer app (no playful gradients, no celebration confetti)
- A security/antivirus tool (no red warning theatrics)
- A general disk cleaner (no pie charts of your entire drive)

**In one sentence:** Roomy feels like the macOS app that a senior engineer at Stripe would build for their own use, then decided to sell.

---

## Aesthetic Direction

**Clean minimal — dark first.**

The canonical experience is macOS dark mode. Light mode is fully supported but secondary.

Key aesthetic principles:
- **Density without clutter.** Developers are comfortable with information-dense UIs. Don't over-pad. Rows should be compact but breathable — think Finder list view, not iOS settings.
- **Restraint over decoration.** No gradients on surfaces. No soft glows. No blurred frosted panels as a design statement. Blur is only acceptable as a macOS vibrancy material (NSVisualEffectView) used natively.
- **Monospace is meaningful.** File paths, sizes, git commit hashes, and code references use a monospace font. It's not decoration — it signals "this is technical data."
- **Motion is functional.** Transitions exist to maintain spatial context (where did this panel come from?) or show real progress (this number is live). No animation purely for delight.
- **macOS-native first.** The app should feel like it was built by Apple's own developer tools team. Uses macOS conventions: traffic lights, standard toolbar, correct scrollbar behavior, correct focus ring style.

---

## Color System

### Design philosophy
Two surface levels. One accent. Semantic status colors. That's it.

Do not introduce additional brand colors. The accent color does the heavy lifting. Status colors (green/blue/amber/red) are reserved for project activity classification — they must not be used decoratively.

### Accent Color

**Electric blue — precision and technical confidence.**

The accent communicates: "this is the action, this is the important number, this is what the app found."

Reference: not a browser-link blue, not a neon blue. A precise, slightly desaturated blue that looks intentional in both dark and light mode. Think closer to Linear's blue or GitHub's action blue than to Twitter blue.

Provide:
- `--accent`: Primary accent (buttons, active states, interactive highlights)
- `--accent-hover`: Hover state (slightly lighter in dark mode, slightly darker in light mode)
- `--accent-subtle`: Low-opacity tint for selected row backgrounds, focus rings, chip borders
- `--accent-text`: Text on accent-colored backgrounds (always white or near-white)

### Dark Mode Surfaces

The background must feel premium, not just dark. Avoid pure `#000000` or a direct clone of macOS `#1C1C1E`. Aim for something with a very subtle cool undertone — as if the surface has been slightly blued, like a high-quality matte screen.

Provide:
- `--bg-base`: Main window background. Near-black, cool-leaning. Suggested range: `#0F1014` to `#141418`.
- `--bg-elevated`: Sidebars, panels, toolbar. Slightly lighter. Subtle 1px border between layers.
- `--bg-hover`: Row hover state. Perceptible but not jarring.
- `--bg-selected`: Selected row. Uses `--accent-subtle`.
- `--bg-inset`: Input fields, well areas (like the scan path picker). Slightly darker than `--bg-base`.

### Light Mode Surfaces

Not just the inverse of dark mode — light mode has its own character. Clean, slightly warm white, not clinical.

Provide equivalent tokens:
- `--bg-base`: Off-white, not pure `#FFFFFF`. Something like `#F7F7F5` to `#FAFAF8`.
- `--bg-elevated`: White card surfaces, toolbar.
- `--bg-hover`, `--bg-selected`, `--bg-inset`: Equivalent states.

### Text

Four levels of text hierarchy. Provide hex values for both modes.

- `--text-primary`: Main content — project names, sizes, headings
- `--text-secondary`: Supporting info — paths, dates, ecosystem labels
- `--text-tertiary`: Hints, placeholders, disabled states
- `--text-inverted`: Text on accent backgrounds

### Borders

- `--border-subtle`: Default dividers between rows, panel edges. Barely visible — 6–8% opacity white in dark mode.
- `--border-default`: Visible borders — input fields, cards, toolbar. 12–16% opacity.
- `--border-strong`: Focus rings, active states.

### Status / Activity Colors

These four colors are **semantic** — they map to project activity classification throughout the app and must remain consistent. They are never used decoratively.

| Status | Meaning | Usage |
|---|---|---|
| `--status-active` | Activity within 30 days | Green dot, green row accent |
| `--status-recent` | Activity 1–6 months ago | Blue dot, blue row accent |
| `--status-inactive` | Activity 6 months – 2 years | Amber dot, amber row accent |
| `--status-dormant` | No activity in 2+ years | Red dot, red row accent |

For each status color provide:
- `--status-X`: The dot/icon color
- `--status-X-bg`: The subtle row tint (very low opacity, 6–10%)
- `--status-X-text`: Label text color for that status (e.g. "Dormant · 3 years ago")

Note: `--status-recent` blue must be visually distinct from `--accent` blue. Use a different hue or saturation. They will appear on screen simultaneously.

### Danger / Destructive

For the delete button and destructive confirmation states only.

- `--danger`: Red, used for the "Delete X GB" button
- `--danger-hover`: Hover state
- `--danger-subtle`: Low-opacity tint for destructive row highlights

---

## Typography

### Typeface selection

**Two typefaces only.**

1. **UI font (sans-serif):** The primary interface font. Must feel native to macOS power-user tools. Not Inter (overused). Not SF Pro (reserved for Apple's own UI). Consider: **Geist** (Vercel's typeface — clean, slightly condensed, excellent for dense UIs), **Mona Sans**, or **DM Sans**. Must have excellent rendering at 11–13px sizes (small labels, row metadata).

2. **Monospace font:** For all technical data — file paths, directory names, git commit messages, sizes shown in path context, code references. Consider: **Geist Mono**, **JetBrains Mono** (clean, excellent legibility), or **Berkeley Mono**. Must harmonize with the UI font — ideally from the same family.

### Type Scale

Provide a complete scale with: name, size (px), line height, weight, and usage description.

| Name | Size | Weight | Line height | Usage |
|---|---|---|---|---|
| `display` | 28px | 600 | 1.2 | Hero stats — "47.3 GB reclaimed" |
| `title-lg` | 20px | 600 | 1.3 | Screen titles, section headers |
| `title-md` | 16px | 600 | 1.4 | Card titles, panel headers |
| `body` | 14px | 400 | 1.5 | Primary content — project names, descriptions |
| `body-medium` | 14px | 500 | 1.5 | Emphasized body — selected items, totals |
| `label` | 13px | 400 | 1.4 | Row metadata — paths, dates, labels |
| `label-medium` | 13px | 500 | 1.4 | Emphasized labels — ecosystem tags, status text |
| `caption` | 11px | 400 | 1.4 | Hints, secondary annotations |
| `mono-body` | 13px | 400 | 1.5 | File paths, directory names (monospace) |
| `mono-sm` | 11px | 400 | 1.4 | Inline code, git refs (monospace) |

### Typography rules

- **Path truncation:** Paths are always shown in monospace. Long paths truncate in the middle: `~/projects/old-cli…/node_modules`. Never truncate at the start.
- **Numbers:** File sizes (`47.3 GB`, `1.2 MB`) use tabular numerals if the font supports it. Sizes always render in `display` or `title-lg` when they are the hero content.
- **Hierarchy through weight and color, not size alone.** A project name at 14px/500 in `--text-primary` vs its path at 13px/400 in `--text-secondary` creates clear hierarchy without changing size drastically.

---

## Spacing & Layout

### Base unit: 4px

All spacing is a multiple of 4.

| Token | Value | Usage |
|---|---|---|
| `--space-1` | 4px | Tight internal spacing — icon to label gap |
| `--space-2` | 8px | Component internal padding (chips, badges) |
| `--space-3` | 12px | Row vertical padding |
| `--space-4` | 16px | Section internal padding, panel gutters |
| `--space-5` | 20px | Larger section gaps |
| `--space-6` | 24px | Panel padding, card internal spacing |
| `--space-8` | 32px | Section separation |
| `--space-12` | 48px | Large layout separations |
| `--space-16` | 64px | Hero areas (welcome screen) |

### Window & layout

- **Default window:** 900×600px
- **Minimum window:** 780×520px
- **Toolbar height:** 52px (standard macOS toolbar)
- **Left column (project list):** ~60% of window width
- **Right column (selection summary):** ~40% of window width
- **Row height (project row):** 52px
- **Row height (artifact sub-row):** 40px
- **Row height (settings row):** 44px

---

## Iconography

### Style
**SF Symbols first.** This is a native macOS app — use SF Symbols wherever a symbol exists. Only create custom icons when SF Symbols genuinely cannot cover the use case.

For the few custom icons needed:
- **Line weight:** 1.5px stroke, same as SF Symbols regular weight
- **Style:** Outlined, not filled (except for status dots which are solid circles)
- **Size:** 16×16px at 1x, 32×32px at 2x
- **Color:** Always inherits from context — never hardcoded color on icons

### Ecosystem icons
Each programming ecosystem needs a recognizable icon. Use official logos where they exist and are simple enough to work at 16px. Ecosystems: Node.js (npm), Python, Rust, Ruby, Go, Java/Kotlin, Swift/Xcode, General.

Show each icon at: 16px (row badge), 24px (ecosystem card on overview screen), both in dark and light mode.

### Status dots
The activity status indicator is a filled circle, 8px diameter, using `--status-X` colors. Show all four states: active (green), recent (blue), inactive (amber), dormant (red).

---

## Component States Reference

For each interactive component, show all required states. This will be the reference for all subsequent screen design prompts.

### Button — Primary (accent)
States: default, hover, pressed, disabled, loading (spinner variant)

### Button — Destructive (delete)
States: default, hover, pressed, disabled, countdown (2-second safety delay — show the countdown state)

### Button — Secondary / Ghost
States: default, hover, pressed, disabled

### Row — Project row
States: default, hover, selected (checkbox checked), selected + hover, expanded (showing artifact sub-rows)

### Row — Artifact sub-row
States: default, hover, selected, selected + hover

### Checkbox
States: unchecked, hover, checked, indeterminate (for parent row when only some artifacts selected)

### Input field
States: default, focus, filled, error

### Chip / filter pill
States: default, hover, active/selected

### Tooltip
Show the "What is this?" tooltip style used on artifact rows.

---

## Elevation & Depth

No drop shadows as decoration. Depth is communicated through:

1. **Surface layering:** `--bg-base` → `--bg-elevated` → `--bg-inset` creates a clear z-axis without shadows
2. **Border contrast:** Higher surfaces have a slightly more visible border
3. **macOS native materials:** The toolbar uses NSVisualEffectView (sidebar material in dark mode, titlebar material in light mode)

If a shadow is needed (e.g., a popover or dropdown), use a single, tight shadow: `0 4px 16px rgba(0,0,0,0.4)` in dark mode, `0 4px 16px rgba(0,0,0,0.12)` in light mode.

---

## Motion Principles

All transitions: **ease-out, 150–200ms** unless noted.

| Interaction | Duration | Easing | Notes |
|---|---|---|---|
| Row hover | 80ms | ease-out | Background fade only |
| Panel slide | 200ms | ease-out | Left/right panel transitions |
| Checkbox check | 120ms | ease-out | Checkmark draw animation |
| Progress bar fill | real-time | linear | Mirrors actual scan progress |
| Screen transition | 180ms | ease-in-out | Full screen changes |
| Number count-up | 800ms | ease-out | Hero stats on results screen |
| Delete button countdown | 2000ms | linear | Safety countdown — see S06 |

---

## Brand Voice

**How Roomy talks to the developer:**

- **Confident, not alarmist.** "47.3 GB recoverable" — not "WARNING: 47.3 GB of junk found!"
- **Precise.** Exact numbers, never rounded unless showing an estimate. "31.4 GB" not "about 30 GB".
- **Honest about what it knows.** "Last git commit: March 2021" — the app shows its work.
- **Brief.** Labels are as short as possible. Tooltips explain when needed. No inline essays.
- **Developer-literate.** Can say `node_modules`, `venv`, `cargo build` without explaining what they are. The user knows.

**Example microcopy:**
- Empty state: "Nothing to clean up in ~/projects" (not "Congratulations! You're all clear!")
- Deletion confirmation: "Move 31.4 GB to Trash" (not "Are you absolutely sure you want to delete these files?")
- After deletion: "31.4 GB reclaimed" (not "Great job! You've freed up space!")
- Tooltip for node_modules: "npm dependency cache. Run `npm install` to restore. Safe to delete."

---

## Deliverable Checklist

The Figma file should contain the following frames:

- [ ] Color tokens — dark mode (all tokens with hex values and usage labels)
- [ ] Color tokens — light mode (all tokens with hex values and usage labels)
- [ ] Status color system (all 4 states, dot + bg + text variants)
- [ ] Typography scale (all 10 type styles, rendered as live text)
- [ ] Spacing scale (visual reference)
- [ ] Iconography — ecosystem icons at 16px and 24px, dark + light
- [ ] Iconography — status dots, all 4 states
- [ ] Component states — all components listed above
- [ ] Elevation reference — the 3 surface levels side by side
- [ ] Brand voice reference card — microcopy examples

---

## Reference Apps (aesthetic, not literal copy)

Study these for tone and craft, do not copy their specific UI patterns:

- **Raycast** — dark surface quality, row density, command palette feel
- **Linear** — typography sharpness, data density, sidebar + main panel layout
- **Kaleidoscope 3** — developer tool that feels premium on macOS, monospace use
- **Proxyman** — network inspector, excellent example of technical data displayed cleanly
- **TablePlus** — database client, strong example of dense tabular data in a native macOS app

---

*This prompt is Step 1.1 of 10 in the Roomy design process. The output of this step will be referenced in all subsequent screen design prompts (Steps 2.1 through 5.2).*
