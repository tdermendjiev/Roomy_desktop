# Roomy — S05 Project Detail
## Google Stitch Design Prompt · Step 4.3

---

## Context

You are designing the **Project Detail screen** (S05) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This screen is the drill-down view for a single project. The user arrives here by clicking a project row in S04. It answers the question every careful developer asks before deleting: **"Do I actually understand what I'm about to remove?"**

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 3C artifact sub-rows, 4A tooltip, 5A checkboxes, 10A path pill)

---

## Screen purpose

Two types of users reach this screen:

1. **The verifier** — arrived from S04, wants to understand one specific project before including it in their deletion set. Will read the "What is this?" disclosures, look at the git date, then go back to S04 with more confidence.

2. **The precise surgeon** — wants to delete only specific artifacts from a project, not everything. Will individually check/uncheck artifact rows, then delete just from this project.

Both need the same screen. The design must support per-artifact control without making the simple verification flow feel heavy.

---

## Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: project name centered (truncated if needed), back button "← Results" returning to S04, settings gear right

---

## Layout

Full window. Single column with three distinct zones stacked vertically:

```
[toolbar — 52px]
──────────────────────────────────────────────
[project header — ~100px]
[divider]
[artifact list — scrollable, flex-fill]
[divider]
[project metadata — ~80px]
[divider]
[actions bar — 52px, sticky]
```

No right panel — unlike S04, this screen is focused on one project. The selection summary is simplified into the sticky actions bar at the bottom.

Content padding: 32px left/right throughout all zones.

---

## Elements

### Project header

Height: ~100px. Background: `--bg-base`. Bottom border: 1px `--border-subtle`. Padding: 20px 32px.

This zone establishes the project's identity and current state at a glance.

**Left side (flex):**

**Project name:**
Large, confident. `title-lg` (20px/600), `--text-primary`.
Example: "startup-2021"

**Full path** (below name, 4px gap):
Component 10A (path pill) from Step 2.1 — but rendered inline here, not as a pill. Just the monospace path text, `mono-body` (13px/400), `--text-secondary`, with a leading SF Symbol `folder` (12px, `--text-tertiary`).
Example: `~/projects/startup-2021`
Clicking the path reveals it in Finder (annotate this behavior).

**Activity status badge** (below path, 6px gap):
Component 2B (status badge) from Step 2.1.
Example: red "Dormant" pill + "Last git commit: March 12, 2021" — `label` (13px/400), `--status-dormant-text`, 8px gap after the pill.

**Right side (fixed width ~200px, vertically centered):**

Two icon buttons (component 1E from Step 2.1) side by side:

- SF Symbol `folder` + label "Open in Finder" — 13px/400, `--text-secondary`
- SF Symbol `terminal` + label "Open in Terminal" — 13px/400, `--text-secondary`

Style: each as a small secondary button (component 1C, 28px height) with icon + label. Not just icon-only — the labels matter because these are infrequent actions and the user should know what they do without hovering.

Gap between the two buttons: 8px.

---

### Artifact list

Scrollable. Fills the remaining vertical space between the project header and the project metadata section.

This is the core of the screen. Each artifact is one row.

#### Artifact row

Height: auto — the row expands when the "What is this?" disclosure is open. Collapsed height: 48px. Expanded height: approximately 120px (48px header + 72px disclosure content).

**Collapsed row layout (left to right):**

1. **Checkbox** (component 5A, 16px) — 16px from left edge, vertically centered
2. **Artifact icon** (SF Symbol, 16px, `--text-tertiary`) — 12px gap. Use contextually appropriate symbols:
   - `node_modules` → `shippingbox`
   - `.venv` / `venv` → `flask`
   - `target/` → `gearshape`
   - `__pycache__` → `bolt`
   - `.next/` → `chevron.right.2`
   - `DerivedData/` → `hammer`
   - General/other → `folder`
3. **Artifact info (flex):**
   - Line 1: Artifact name — `label-medium` (13px/500), `--text-primary`. Example: "node_modules"
   - Line 2: Full path — `mono-sm` (11px/400), `--text-tertiary`, middle-truncated. Example: `~/projects/startup-2021/node_modules`
4. **"What is this?" link** — `--accent` 12px/400, right-aligned before size. Always visible (not hover-only — this is a key affordance).
5. **Size** — `label-medium` (13px/500), `--text-primary`, right-aligned, 60px fixed width

**Expanded row layout (when "What is this?" is clicked):**

The row expands below the collapsed content to reveal a disclosure panel. The disclosure panel is inset — slightly different background from the row to distinguish it visually.

Disclosure panel specs:
- Background: `--bg-inset`
- Border-top: 1px `--border-subtle`
- Border-left: 3px `--accent` (left accent bar — matches the app's disclosure convention)
- Padding: 12px 16px 12px 44px (left padding accounts for the checkbox + icon indent)
- Border-radius: 0 (it's a panel within the row, not a card)

Disclosure panel content (three elements stacked):

**Title:** Artifact name repeated — `label-medium` (13px/500), `--text-primary`. (Repeated here because the panel stands alone when scrolled into view.)

**Explanation text:** 2–3 sentences in plain language. `label` (13px/400), `--text-secondary`, line-height 1.6.

**Regenerate command:** A monospace inline code pill showing the command to restore the artifact.
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Border-radius: 4px
- Padding: 3px 8px
- Font: `mono-sm` (11px/400), `--text-primary`
- Leading icon: SF Symbol `terminal` (11px, `--text-tertiary`)

Show one expanded artifact row and two collapsed rows in the primary design. The expanded row should be the `node_modules` row with this content:

> **node_modules**
> npm dependency cache. Contains all installed packages from package.json. Nothing permanent lives here — your source code, package.json, and package-lock.json are all that matter.
> Restore with: `npm install`

---

#### Artifact rows to show (primary design — startup-2021 project)

Three artifact rows:

| # | Artifact | Path | Size | Selected | State |
|---|---|---|---|---|---|
| 1 | node_modules | ~/projects/startup-2021/node_modules | 3.9 GB | ✓ | Expanded (showing disclosure) |
| 2 | .next/ | ~/projects/startup-2021/.next | 340 MB | ✓ | Collapsed |
| 3 | .eslintcache | ~/projects/startup-2021/.eslintcache | 2.1 MB | ✓ | Collapsed |

All three selected (this project is dormant — all artifacts are confidently deletable).

Total for this project: 4.2 GB (shown in the actions bar below).

Rows are separated by 1px `--border-subtle` dividers.

---

### Project metadata

Height: ~80px. Background: `--bg-elevated`. Top and bottom border: 1px `--border-subtle`. Padding: 16px 32px.

This zone shows the technical context that justifies the deletion recommendation. It answers: "Why does Roomy think this project is dormant?"

Layout: two columns, 2 rows each.

| Left column | Right column |
|---|---|
| **Last git commit** | **Git status** |
| March 12, 2021 · "fix: login redirect bug" | Clean (no uncommitted changes) |
| **Total project size** | **Recoverable from this project** |
| 4.8 GB (including source) | 4.2 GB (87% of total) |

Each cell:
- Label: `caption` (11px/400), `--text-tertiary`, uppercase, letter-spacing 0.06em
- Value: `label` (13px/400), `--text-primary`, 4px below label

The commit message is truncated if long — max ~40 characters, then `…`.

The "Git status: Clean" value uses `--status-active` color (green) — clean is good. If the status were "Uncommitted changes", it would use `--status-inactive` (amber) as a soft warning.

The "Recoverable: 4.2 GB (87%)" value is in `--accent` color — this is the number that matters.

---

### Actions bar (sticky)

Height: 52px. Pinned to the bottom of the window. Background: `--bg-elevated`. Top border: 1px `--border-subtle`. Padding: 0 32px.

Content left to right, vertically centered:

**Left side:**
- **"Select all" checkbox** (component 5A) with label "Select all artifacts in this project" — 13px/400, `--text-secondary`, 8px gap after checkbox. Indeterminate when some artifacts selected, checked when all selected.

**Right side:**
- **"Add to exclusions" link** — ghost text link (component 1D), 13px/400, `--text-tertiary`. SF Symbol `minus.circle` (12px) leading. This is a low-emphasis action — it should not compete visually with the delete button.
- **8px gap**
- **"Delete selected from this project →" button** — Primary button (component 1A), large variant (36px), `--danger` color. Label updates with the selected size: "Delete 4.2 GB from this project". Disabled when nothing selected.

The "Add to exclusions" link and delete button sit together on the right. The select-all checkbox sits on the left. This matches the convention from S04 — checkboxes left, actions right.

---

## States to design

### State 1 — All selected, dormant project (primary design)
startup-2021. All 3 artifacts selected. Row 1 expanded with disclosure. Git metadata visible. "Delete 4.2 GB from this project" button active.

### State 2 — Partial selection
Same project, only `node_modules` selected (3.9 GB). The other two rows unselected. "Select all" checkbox in indeterminate state. Button label: "Delete 3.9 GB from this project".

### State 3 — Active project
A different project: `current-project` from S04 row 8. Status badge: green "Active · Last commit 2 days ago". All artifacts unselected by default (the user arrived here curious, not committed to deleting).

Show:
- Green "Active" status badge in the header
- Git status: "Clean · 2 days ago" in `--status-active` green
- The "What is this?" disclosure open on one artifact row — because an active-project user is more likely to want to understand what they're looking at before deciding
- "Select all" checkbox unchecked

This state tests whether the design works as a read-only inspection view, not just a delete-preparation view.

### State 4 — Non-git project
A project with no `.git` directory.

In the metadata section:
- "Last git commit" → replaced with "Last modified" + the file modification date
- "Git status" → replaced with "Not a git repo" in `--text-tertiary`

Annotate this fallback behavior.

---

## Micro-details to get right

**The "What is this?" link must always be visible** — not hover-only. This is a deliberate departure from a pure minimalist approach. On this screen, the user is in careful-review mode. The affordance to learn more about each artifact should be obvious, not hidden. If it were hover-only, users who need it most (those unfamiliar with some artifact types) would never find it.

**The disclosure panel left accent bar** (3px `--accent`) connects this pattern visually to other disclosure patterns in the app (the expanded row in S04 uses a status-color left bar). Using `--accent` here instead of a status color signals: "this is informational, not a warning."

**The commit message in the metadata.** Real commit messages are messy: "fix: login redirect bug", "wip", "asdfg", "final FINAL". Show a realistic one, truncated at ~40 chars. Do not show "Initial commit" — that's too on-the-nose and too common as a placeholder.

**The "87% recoverable" framing.** Showing the percentage alongside the absolute GB value in the metadata reinforces the insight: almost everything in this project folder is regenerable. The source code is 0.6 GB; the rest is cache. That framing is the entire value proposition of Roomy made concrete.

**The actions bar button label is dynamic.** "Delete 4.2 GB from this project" — the GB amount updates as artifact checkboxes are toggled. This is the same live-update behavior as the right panel in S04. Annotate it.

**Scrolling.** The artifact list is the only scrollable zone. If a project has 8+ artifacts (possible for a large monorepo), the list scrolls while the header, metadata, and actions bar all remain fixed. Show this scroll behavior annotated even in the static design.

---

## What this screen must NOT look like

- **Not a file browser.** The artifact list is not a Finder-style file listing. It is a curated, opinionated list of regenerable artifacts with context. It does not show all files in the project — only the things Roomy found.
- **Not a settings panel.** The metadata section is read-only context, not controls. The only interactive elements are the checkboxes, "What is this?" links, and the actions bar.
- **Not a modal or sheet.** This is a full screen, navigated to from S04. The back button in the toolbar is the return path. There is no close button, no overlay, no dimmed background.
- **Not overwhelming.** A project with 3 artifacts should feel simple and clear. The design must not add visual weight to compensate for the small amount of content. Generous whitespace in the disclosure panel is correct.

---

## Connections

| Action | Destination |
|---|---|
| "Delete selected from this project →" | S06 — Selection Review (this project's artifacts only) |
| "Add to exclusions" | Marks project excluded, returns to S04 (project disappears from list) |
| "Open in Finder" | macOS Finder — reveals project folder |
| "Open in Terminal" | macOS Terminal / default terminal — opens at project path |
| Back button (toolbar) | S04 — Project List (selections preserved) |
| Settings gear | S09 — Settings |

---

## Deliverable frames

- [ ] S05-primary — All selected, dormant project, row 1 expanded — 900×600px dark mode
- [ ] S05-primary — Light mode variant — 900×600px
- [ ] S05-partial — Partial selection (node_modules only) — 900×600px dark mode
- [ ] S05-active — Active project, unselected, one disclosure open — 900×600px dark mode
- [ ] S05-nogit — Non-git project, metadata fallback — 900×600px dark mode
- [ ] S05-min — Minimum window size 780×520px

---

## Annotation notes for handoff

- "What is this?" disclosure: click to expand/collapse, 150ms ease-out, row height animates
- Disclosure panel left bar: 3px `--accent`, full height of expanded panel
- Actions bar: sticky, always visible, does not scroll
- "Delete X GB from this project" label: updates live as checkboxes toggle, 80ms count animation
- Artifact list: independently scrollable, header + metadata + actions bar all fixed
- Path in header: clickable → reveals in Finder (annotate as `NSWorkspace.shared.activateFileViewerSelecting`)
- "Add to exclusions": after confirming, navigates back to S04 with this project removed from the list — no confirmation dialog needed (exclusions are reversible in S10)
- Non-git fallback (State 4): "Last modified" replaces "Last git commit", "Not a git repo" replaces git status

---

*This prompt is Step 4.3 of 10 in the Roomy design process. The next screen (S06 Selection Review) is the final checkpoint before deletion — the mood shifts from exploration to commitment.*
