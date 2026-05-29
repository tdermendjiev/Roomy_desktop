# PRD + Screen Flow: Developer Disk Cleaner
## Working title: Depster (or Reclaim / Harvest — TBD)

> A native macOS app that scans your machine for regenerable developer artifacts — node_modules, Python venvs, Rust target dirs, build caches — understands project age and activity, and helps you reclaim disk space without accidentally breaking active projects.

---

## Product Philosophy

- Does one thing exceptionally well. Not a general disk cleaner.
- Developer-aware. Understands project ecosystems, not just file sizes.
- Never deletes without explicit confirmation. Shows you everything before touching anything.
- Fast. Full scan of a 1TB drive in under 60 seconds.
- Local and private. No telemetry, no cloud, no account.
- One-time purchase. No subscription.
- Native macOS. SwiftUI. Feels at home on the platform.

---

## The Core Insight

The tool knows two things that generic disk cleaners don't:

1. **What is safe to delete** — node_modules, .venv, target/, __pycache__ are all regenerable from lockfiles or source code. Deleting them loses nothing permanent.

2. **What is probably safe to delete** — a node_modules folder inside a project last committed 2 years ago is almost certainly dormant. Project age turns a "maybe" into a confident recommendation.

These two signals together — artifact type + project age — let the tool sort results from "delete immediately" to "check before deleting" automatically.

---

## Target Users

- Full-stack developers with large project archives
- Freelancers with client project folders going back years
- Students and bootcamp graduates with dozens of tutorial projects
- Any developer who has run `du -sh ~/` and been shocked
- Developers switching to a new Mac who want to clean up before migrating

---

## What It Scans

### Node / JavaScript / TypeScript
| Path | Description | Safety |
|---|---|---|
| `node_modules/` | npm/yarn/pnpm dependencies | Always safe to delete |
| `.next/` | Next.js build cache | Always safe |
| `.nuxt/` | Nuxt.js build cache | Always safe |
| `.svelte-kit/` | SvelteKit build cache | Always safe |
| `dist/` | Build output | Safe if source exists |
| `.cache/` | Various bundler caches | Always safe |
| `.parcel-cache/` | Parcel cache | Always safe |
| `.turbo/` | Turborepo cache | Always safe |
| `.eslintcache` | ESLint cache file | Always safe |

### Python
| Path | Description | Safety |
|---|---|---|
| `venv/` `.venv/` `env/` `.env/` | Virtual environments | Always safe to delete |
| `__pycache__/` | Python bytecode cache | Always safe |
| `*.pyc` files | Compiled bytecode | Always safe |
| `.mypy_cache/` | Mypy type checker cache | Always safe |
| `.pytest_cache/` | Pytest cache | Always safe |
| `.ruff_cache/` | Ruff linter cache | Always safe |
| `*.egg-info/` | Package build metadata | Safe if not publishing |
| `dist/` `build/` | Package build output | Safe if source exists |
| `.tox/` | Tox test environments | Always safe |
| `site-packages/` inside venv | Installed packages | Always safe |

### Rust
| Path | Description | Safety |
|---|---|---|
| `target/` | Compilation artifacts | Always safe (Cargo rebuilds) |
| `target/debug/` | Debug build output | Always safe |
| `target/release/` | Release build output | Always safe |

### Ruby
| Path | Description | Safety |
|---|---|---|
| `vendor/bundle/` | Bundled gems | Always safe (bundle install) |
| `.bundle/` | Bundler config cache | Usually safe |

### Go
| Path | Description | Safety |
|---|---|---|
| `vendor/` | Vendored dependencies | Safe if go.sum exists |

### Java / Kotlin / Android
| Path | Description | Safety |
|---|---|---|
| `build/` | Gradle build output | Always safe |
| `.gradle/` | Gradle daemon cache | Always safe |
| `target/` | Maven build output | Always safe |
| `.idea/` | IntelliJ project files | Usually safe |

### iOS / macOS / Swift
| Path | Description | Safety |
|---|---|---|
| `DerivedData/` | Xcode build cache | Always safe |
| `.build/` | Swift Package Manager cache | Always safe |
| `*.xcworkspace/xcuserdata/` | Xcode user data | Usually safe |

### General
| Path | Description | Safety |
|---|---|---|
| `.DS_Store` | macOS directory metadata | Always safe |
| `Thumbs.db` | Windows thumbnail cache | Always safe |
| `*.log` files | Log files | Usually safe |
| `coverage/` | Test coverage output | Always safe |
| `tmp/` `temp/` | Temporary files | Usually safe |

---

## Project Age Classification

The app classifies each project's activity level using:
- Last git commit date (via libgit2 or git CLI)
- Last file modification date in project root
- Package.json / pyproject.toml / Cargo.toml last modified date

| Status | Criteria | Color |
|---|---|---|
| Active | Activity within 30 days | Green |
| Recent | Activity 1–6 months ago | Blue |
| Inactive | Activity 6 months – 2 years ago | Amber |
| Dormant | No activity in 2+ years | Red |

---

## Core Features — V1

| Feature | Description |
|---|---|
| Multi-ecosystem scan | Detects Node, Python, Rust, Ruby, Go, Java, Swift artifacts |
| Project age detection | Last git commit + file modification dates |
| Size calculation | Accurate recursive size per artifact folder |
| Activity-sorted results | Dormant projects shown first, active last |
| Batch selection | Select all dormant, select by ecosystem, select individual |
| Safe delete | Moves to Trash (not permanent delete). Trash = undo. |
| Dry run | Preview what would be deleted without touching anything |
| Exclusions | Add projects or paths to a permanent exclusion list |
| Re-scan | Re-scan after cleanup to see updated totals |
| Before/After summary | Shows total space reclaimed in satisfying summary screen |

---

## Out of Scope — V1

- Duplicate file detection (different product)
- General disk usage visualization (different product)
- Automatic scheduled cleaning (too risky, V2 maybe)
- Windows / Linux support
- Cloud backup before deletion

---

## Screen Inventory

| # | Screen | Description |
|---|---|---|
| S01 | Welcome / Empty State | First launch or post-scan cleared state |
| S02 | Scanning Progress | Live progress while scanning the filesystem |
| S03 | Results — Overview | Top-level summary of what was found |
| S04 | Results — Project List | Detailed list of projects with artifacts |
| S05 | Project Detail | Drill-down into a single project's artifacts |
| S06 | Selection Review | Review selected items before deletion |
| S07 | Deletion Progress | Progress during deletion |
| S08 | Summary / Done | Space reclaimed, satisfying completion state |
| S09 | Settings | Exclusions, scan paths, preferences |
| S10 | Exclusions Manager | Manage excluded paths and projects |

---

## Global Layout

Single-window app. No sidebar navigation. Linear flow from scan → review → delete. The window is resizable, minimum 780×520px, default 900×600px.

**Menu bar:**
Standard macOS menu bar. File, Edit, View, Window, Help.
- File → New Scan, Settings
- Help → Documentation, About

**Toolbar (persistent across all post-scan screens):**
- Back button (when applicable)
- App title / current view label (center)
- Settings gear (right)

---

## S01 — Welcome / Empty State

**Purpose:** First screen on launch before any scan has been run, or when user wants to start a fresh scan.

**Layout:** Full window. Centered content. Generous whitespace. Sets tone — confident, minimal, developer-friendly.

**Elements:**

**App icon + title (top center):**
- App icon (large, ~80px)
- App name
- Tagline: "Reclaim disk space from dormant projects"

**Scan path selector (center):**
- Heading: "Where should I look?"
- Three quick-select buttons:
  - "Home folder (~)" — most common choice, pre-selected
  - "Custom folder…" → macOS folder picker
  - "Entire Mac" — scans all user-accessible paths
- Currently selected path shown as a pill below buttons
- Note below: "Scans only regenerable files — nothing permanent will be found"

**Ecosystem filter (optional, collapsed by default):**
- "Advanced: choose ecosystems" disclosure triangle
- When expanded: checkbox grid — Node, Python, Rust, Ruby, Go, Java, Swift, General
- All checked by default
- "Select all / None" link

**CTA:**
- Large primary button: "Start scan →"
- Estimated time hint below button: "Usually under 60 seconds"

**If previous scan results exist:**
- Secondary option below CTA: "View last scan from [date]" → S03

**Connections:**
- "Start scan" → S02
- "View last scan" → S03

---

## S02 — Scanning Progress

**Purpose:** Shows live progress while the filesystem scan is running. Keeps the user informed, sets expectations, shows the tool is working.

**Layout:** Full window. Centered progress area.

**Elements:**

**Header:**
- "Scanning your projects…"
- Scanning path shown: "~/Projects and subfolders"

**Animated progress section:**
- Circular or linear progress indicator (indeterminate until file count is known, then determinate)
- Current directory being scanned (updates live, truncated path): "~/projects/old-client/node_modules…"
- Stats updating in real time:
  - Folders scanned: 14,203
  - Projects found: 47
  - Artifacts found: 89
  - Recoverable so far: 23.4 GB

**Live findings ticker (below stats):**
- Small scrolling list of finds as they're discovered:
  - "node_modules — ~/projects/startup-2021 — 1.2 GB"
  - "__pycache__ — ~/code/ml-experiments — 340 MB"
  - "target/ — ~/rust/learning-project — 4.1 GB"
- Newest item at top, fades out after ~5 items

**Cancel:**
- Small "Cancel scan" link at bottom
- Cancelling shows partial results with a banner: "Partial scan — not all folders were checked"

**When complete:**
- Stats freeze, progress indicator fills/completes
- Auto-transitions to S03 after 800ms pause (feels satisfying, not jarring)

**Connections:**
- Auto → S03 on completion
- "Cancel" → S03 with partial results banner

---

## S03 — Results: Overview

**Purpose:** High-level summary of what was found. The "wow" screen. Big numbers, clear breakdown. Makes the user want to keep going.

**Layout:** Full window. Dashboard-style overview.

**Elements:**

**Hero stat (top center):**
- Large number: "47.3 GB"
- Label: "recoverable across 84 projects"
- Subtext: "Safely deletable — all regenerable from source"

**Breakdown by ecosystem (horizontal cards row):**
Each ecosystem card shows:
- Ecosystem icon (npm logo, Python snake, Rust gear, etc)
- Ecosystem name
- Total size
- Project count
- Example: "Node.js · 31.2 GB · 54 projects"

Cards are scrollable horizontally if more than 4 ecosystems found.

**Breakdown by project age (donut chart or bar):**
- Dormant (2y+): 28.4 GB — shown in red
- Inactive (6m–2y): 14.1 GB — shown in amber
- Recent (1–6m): 4.2 GB — shown in blue
- Active (< 1m): 0.6 GB — shown in green

Small legend below chart.

**Quick action buttons:**
- "Select all dormant projects" button → pre-selects all red items and goes to S04
- "Review all findings →" button → S04 with no pre-selection
- "Delete dormant only (28.4 GB)" primary button → pre-selects dormant, goes to S06

**Re-scan / settings links (bottom):**
- "Re-scan" link — runs scan again
- "Change scan settings" link → S09

**Connections:**
- "Select all dormant" → S04 with dormant items pre-selected
- "Review all" → S04
- "Delete dormant only" → S06 (with dormant pre-selected)
- "Re-scan" → S02
- Settings → S09

---

## S04 — Results: Project List

**Purpose:** The main working view. Full list of all found projects with their artifacts. User browses, selects, and decides what to delete.

**Layout:** Full window. Two-column layout.

**Left column (~60%) — Project list:**

**List controls (top of column):**
- Sort dropdown: "Sort by size (largest first)" / Date (oldest first) / Ecosystem / Project name
- Filter chips: All | Dormant | Inactive | Recent | Active
- Ecosystem filter dropdown: All ecosystems / Node / Python / Rust / etc
- Search input: "Filter projects…" (filters by project name/path)
- Selection count + "Select all visible" checkbox

**Project rows:**
Each row shows:
- Activity status dot (red/amber/blue/green)
- Project name (inferred from package.json name or folder name)
- Short path (truncated: ~/projects/client-name/…)
- Age label: "Dormant · Last active 3 years ago"
- Total recoverable size for this project (bold)
- Ecosystem badges: small icons for detected ecosystems
- Expand arrow (→) to see artifact breakdown
- Checkbox for selection

**Expanded project row (when expand arrow clicked):**
Shows artifact sub-rows indented below the project:
- Artifact type icon + name (node_modules, .venv, target/, etc)
- Full path
- Size
- Individual checkbox
- "What is this?" link → tooltip explaining what the folder is and that it's safe to delete

**Right column (~40%) — Selection summary (sticky):**
- Heading: "Selected for deletion"
- Total selected size (large, updates live): "31.4 GB"
- Breakdown by ecosystem: "Node: 24.1 GB · Python: 7.3 GB"
- Item count: "67 artifact folders across 41 projects"
- "Review and delete →" primary button (disabled until something selected)
- "Clear selection" link

**Bottom bar:**
- Total found: "84 projects · 47.3 GB total"
- Total selected: "41 projects · 31.4 GB selected"

**Connections:**
- Project row click → S05 Project Detail (right panel updates, or navigate)
- "Review and delete" → S06
- Back → S03

---

## S05 — Project Detail

**Purpose:** Drill into a single project. See all its artifacts, full paths, exact sizes, git history, and make per-artifact decisions.

**Layout:** Full window. Replaces the project list view or opens as a detail panel.

**Header:**
- Project name (large)
- Full path (smaller, monospace font, clickable → reveals in Finder)
- Activity status badge: "Dormant · Last git commit: March 2021"
- "Open in Finder" button
- "Open in Terminal" button (opens Terminal at this path)
- Back link → S04

**Artifact list (main content):**
Each artifact row:
- Artifact type icon
- Artifact name (node_modules, .venv, etc)
- Full path (monospace, smaller)
- Size
- "What is this?" disclosure → expands to show one-paragraph explanation:
  - What the folder is
  - Why it's safe to delete
  - How to regenerate it (e.g. "Run `npm install` to restore")
- Individual checkbox

**Project metadata section (bottom):**
- Last git commit: [date] — [commit message truncated]
- Total project size (including source): [size]
- Recoverable from this project: [size]
- Git status: "Clean" / "Uncommitted changes" (if git repo)

**Actions bar (sticky bottom):**
- "Select all artifacts in this project" checkbox
- "Add project to exclusions" link → adds to exclusion list, never shows again
- "Delete selected from this project" primary button → goes to S06 with just this project's selection

**Connections:**
- "Delete selected" → S06
- "Add to exclusions" → marks project as excluded, returns to S04
- Back → S04
- "Open in Finder" → macOS Finder
- "Open in Terminal" → macOS Terminal / iTerm

---

## S06 — Selection Review

**Purpose:** Final review before any deletion happens. Clear, explicit, no ambiguity. User sees exactly what will be deleted. Last chance to remove items.

**Layout:** Full window. Review-focused layout.

**Header:**
- Title: "Review before deleting"
- Subtitle: "These folders will be moved to Trash. You can restore them from Trash if needed."
- Important note (subtle but visible): "All selected items are regenerable. Nothing permanent will be lost."

**Summary bar (top):**
- Total: "31.4 GB across 67 folders in 41 projects"
- Ecosystem breakdown: "Node 24.1 GB · Python 7.3 GB"

**Deletion list (main content, scrollable):**
Grouped by project:

**Project group header:**
- Project name
- Path
- Total being deleted from this project
- "Remove all from [project]" link — deselects entire project

**Artifact rows within group:**
- Artifact name and path
- Size
- Remove (×) button — removes just this item from the deletion list

**Side panel (right, ~30%):**
- "After deletion" preview:
  - Current disk space used: [X GB]
  - Space to be freed: [31.4 GB]
  - Estimated disk space after: [Y GB]
  - Visual disk space bar showing before/after
- Reminder: "Items go to Trash, not permanently deleted"
- "Empty Trash after deletion" toggle (off by default — give user control)

**Footer (sticky):**
- "Back to results" link
- "Delete [31.4 GB]" primary button (red, large, counts down 2 seconds before enabling on first use as safety)

**Connections:**
- "Delete [X GB]" → S07
- "Back to results" → S04
- Remove (×) on individual item → removes from list, updates total

---

## S07 — Deletion Progress

**Purpose:** Shows progress while files are being moved to Trash.

**Layout:** Full window. Centered progress.

**Elements:**
- Title: "Moving to Trash…"
- Progress bar (determinate — folder count is known)
- Current item: "~/projects/old-startup/node_modules"
- Stats:
  - Folders moved: 23 of 67
  - Space freed so far: 12.4 GB
- Animated disk space indicator (fills as space is freed)

**Cannot be cancelled mid-way** — deletion is fast enough (move to Trash is instant, not actual deletion) that a cancel button would rarely be needed. If user force-quits, partially moved items are still in Trash.

**When complete:**
- Auto-transitions to S08 after 1 second pause

**Connections:**
- Auto → S08 on completion

---

## S08 — Summary / Done

**Purpose:** Completion screen. The satisfying payoff. Shows what was reclaimed. Encourages sharing.

**Layout:** Full window. Celebration-adjacent but understated — developer aesthetic, not confetti.

**Elements:**

**Hero result (center, large):**
- "31.4 GB reclaimed"
- Subtext: "Across 41 projects · 67 folders deleted"

**Before / After visualization:**
- Simple horizontal bar or two numbers side by side:
  - Before: [X GB used]
  - After: [Y GB used]  
  - Freed: 31.4 GB (highlighted)

**Breakdown (smaller, below hero):**
- By ecosystem: Node 24.1 GB · Python 7.3 GB
- Largest single save: "target/ in ~/rust/learning — 8.2 GB"

**Actions:**
- "Scan again" button — runs fresh scan to verify and find anything missed → S02
- "View in Trash" button — opens macOS Trash in Finder (so user can inspect before permanently deleting)
- "Done" button — closes or returns to S01

**Share prompt (subtle, not pushy):**
- Small text: "Enjoying the app? A tweet goes a long way 🙏"
- "Share on X" button → pre-filled tweet:
  "Just reclaimed 31.4 GB of node_modules and Python venvs from dormant projects using [AppName] — free download at [URL]"
- "Not now" link

**Connections:**
- "Scan again" → S02
- "View in Trash" → macOS Trash
- "Done" → S01

---

## S09 — Settings

**Purpose:** App preferences. Simple, one screen.

**Layout:** Full window. Single-column settings layout, macOS Settings style.

**Sections:**

**Scan paths:**
- Default scan location: Home folder / Custom path / Entire Mac (radio buttons)
- Custom path input (shown when Custom is selected)
- "Always ask before scanning" toggle

**Ecosystems:**
- Which ecosystems to scan:
  - Node.js / npm (checked)
  - Python (checked)
  - Rust (checked)
  - Ruby (checked)
  - Go (checked)
  - Java / Kotlin (checked)
  - Swift / Xcode (checked)
  - General (DS_Store, logs, etc) (checked)
- "Select all / None" link

**Activity thresholds:**
- "Dormant" threshold: dropdown — 1 year / 2 years / 3 years (default: 2 years)
- "Inactive" threshold: dropdown — 3 months / 6 months / 1 year (default: 6 months)

**Deletion behavior:**
- "Move to Trash" vs "Permanent delete" radio (Trash is default, permanent requires toggle)
- "Empty Trash automatically after deletion" toggle (off by default)

**Exclusions:**
- "Manage exclusions" → S10
- Quick view: shows count of excluded paths "12 paths excluded"

**About:**
- App version
- "Check for updates"
- License info
- Links: Documentation, GitHub, Contact

**Connections:**
- "Manage exclusions" → S10
- All settings auto-save on change

---

## S10 — Exclusions Manager

**Purpose:** Manage paths and projects that should never be shown in scan results.

**Layout:** Full window or sheet. List-based.

**Header:**
- Title: "Exclusions"
- Subtitle: "These paths and projects will never appear in scan results"

**Exclusion list:**
Each row:
- Path (full path, monospace)
- Type badge: "Project" / "Path" / "Pattern"
- Date added
- Remove (×) button

**Empty state:**
- "No exclusions yet"
- "Projects you exclude from results will appear here"

**Add exclusion:**
- "Add path" button → macOS folder/path picker
- "Add pattern" button → text input for glob patterns (e.g. `*/vendor/*`, `~/work/**`)

**Connections:**
- Remove (×) → removes exclusion immediately
- Back → S09

---

## Key User Flows

### Flow 1: First time use — clean dormant projects

```
S01 Welcome
  → Select "Home folder (~)"
  → "Start scan"
  → S02 Scanning Progress
    → Watch live discoveries
    → Scan completes in 45 seconds
  → S03 Overview
    → Sees "47.3 GB recoverable"
    → Impressed by the number
    → Clicks "Delete dormant only (28.4 GB)"
  → S06 Selection Review
    → Scans the list of projects
    → Removes two active-looking projects from list
    → Clicks "Delete 26.1 GB"
  → S07 Deletion Progress
    → 8 seconds to move everything to Trash
  → S08 Summary
    → "26.1 GB reclaimed"
    → Tweets about it
```

### Flow 2: Careful review before deleting

```
S03 Overview
  → "Review all findings"
  → S04 Project List
    → Sorts by "oldest first"
    → Sees 2019-era projects at top
    → Checks checkboxes on all dormant projects
    → Clicks one project to inspect
  → S05 Project Detail
    → Reads "What is this?" for node_modules
    → Sees last git commit was 2020
    → Adds project to selection
    → Back to S04
  → "Review and delete" in right panel
  → S06 Selection Review
    → Removes one project they want to keep
    → "Delete 18.3 GB"
  → S07 → S08
```

### Flow 3: Excluding work projects

```
S04 Project List
  → Sees ~/work/company-project in list
  → Clicks into S05 Project Detail
  → "Add project to exclusions"
  → Returns to S04
  → Project no longer visible
  → This project never appears in future scans
```

### Flow 4: Quick node_modules cleanup only

```
S01 Welcome
  → "Advanced: choose ecosystems"
  → Unchecks everything except Node.js
  → "Start scan"
  → S02 → S03
    → Results show only npm artifacts
    → "Select all dormant projects"
  → S06 → S07 → S08
```

### Flow 5: Verify after deletion

```
S08 Summary
  → "Scan again"
  → S02 Scanning Progress
  → S03 Overview
    → Remaining recoverable: 8.2 GB (active projects, not deleted)
    → Confirms cleanup was successful
    → "Done" → S01
```

---

## Emotional Arc

The product is designed with a specific emotional journey in mind:

**Discovery** (S02→S03): "I had no idea I had this much junk."
The scan revelations are genuinely surprising. 40+ GB is common for developers with a few years of project history. The overview screen leans into this moment — big number, clear breakdown.

**Confidence** (S04→S05): "I understand what I'm deleting."
The project age classification and the "What is this?" explanations give users enough context to feel safe. They're not blindly deleting — they understand that node_modules is always regenerable.

**Control** (S06): "I'm in charge of this."
The review screen explicitly hands control back to the user. Nothing is automatic. The 2-second delay on the delete button on first use adds a small friction that reinforces: this is intentional, not accidental.

**Satisfaction** (S08): "That felt good."
The completion screen is designed to be pleasantly satisfying without being over-the-top. The before/after numbers, the option to share — this is the moment that drives word of mouth.

---

## Architectural Notes for Developers

**Filesystem scanning:**
Use FileManager + URLResourceKey for recursive traversal. Key resource keys: `fileSizeKey`, `contentModificationDateKey`, `isDirectoryKey`. Avoid stat() calls where possible — URLResourceKey is faster in batch.

**Pattern matching:**
Match on exact folder names first (node_modules, .venv, target) before glob patterns. Exact matches are O(1) per directory entry. Build the pattern set as a Set<String> for instant lookup.

**Size calculation:**
Calculate folder sizes asynchronously after initial discovery. Show the project list immediately with "calculating…" placeholders, then fill in sizes as they resolve. This makes the app feel faster — the list appears quickly even if sizes aren't ready.

**Git date detection:**
Use `git log -1 --format=%ci` via Process/subprocess per project. Cache results in SQLite. Run in parallel with size calculation. Fall back to file modification date if not a git repo.

**Deletion:**
Use `NSWorkspace.shared.recycle()` — this is the proper macOS API for "move to Trash" that preserves undo and appears correctly in Trash. Never use `FileManager.removeItem()` — that permanently deletes.

**SQLite schema:**
- `scan_runs` — one row per scan with timestamp and root path
- `projects` — discovered projects with path, ecosystem flags, last_activity date
- `artifacts` — discovered artifact folders with project_id, path, size, type
- `exclusions` — user-added exclusion paths and patterns

**Performance targets:**
- Scan 100,000 directories in under 60 seconds on M1
- UI never blocks — all filesystem work on background threads
- Results appear progressively (stream into list as found, don't wait for full scan)
- Size calculations update live without UI jank

**Safety invariants (never violate):**
- Never delete using FileManager.removeItem(). Always NSWorkspace.recycle().
- Never scan or suggest deleting paths outside the user-selected root.
- Never auto-delete. User must explicitly confirm every deletion.
- Exclusion list is checked before every result is shown, not just at scan time.
