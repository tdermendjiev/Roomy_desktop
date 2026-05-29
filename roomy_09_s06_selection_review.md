# Roomy — S06 Selection Review
## Google Stitch Design Prompt · Step 4.4

---

## Context

You are designing the **Selection Review screen** (S06) for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts.

This is the last screen before anything is deleted. It is a checkpoint, not a confirmation dialog. The user reviews exactly what will be moved to Trash, can remove items they've changed their mind about, sees a before/after disk preview, and then commits to the deletion.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 7D disk space bar, 5B toggle)

---

## Screen purpose

The emotional target is **deliberate confidence** — not anxiety, not excitement. The user should feel:

- "I can see exactly what's going to happen."
- "I'm in control — I can still remove things."
- "This is safe — it goes to Trash, not permanent delete."
- "OK, I'm ready."

The design must reinforce all four of those feelings simultaneously. This is achieved through complete transparency (show everything), explicit control (remove buttons on every item), clear safety language (Trash, not delete), and a friction mechanism (the 2-second countdown on first use) that makes the commitment feel intentional rather than accidental.

---

## Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: "Review" label centered, back button "← Results" returning to S04, settings gear right

---

## Layout

Two-column layout, similar to S04 but with a different right panel purpose.

```
[toolbar — 52px]
┌─────────────────────────────┬──────────────────────┐
│  Left column — 65%          │  Right panel — 35%   │
│  (585px at 900px window)    │  (315px)             │
│                             │                       │
│  Review header — 56px       │  After deletion      │
│  ─────────────────          │  preview panel       │
│  Deletion list              │  (sticky)            │
│  grouped by project         │                       │
│  (scrollable)               │                       │
│                             │                       │
├─────────────────────────────┴──────────────────────┤
│  Footer bar — 52px (sticky)                         │
└────────────────────────────────────────────────────┘
```

The right panel and footer bar are both sticky.

---

## Left column

### Review header

Height: 56px. Background: `--bg-elevated`. Bottom border: 1px `--border-subtle`. Padding: 0 24px.

Content left to right, vertically centered:

**Title + subtitle stacked:**
- "Review before deleting" — `title-md` (16px/600), `--text-primary`
- "These folders will be moved to Trash. You can restore them anytime." — `caption` (11px/400), `--text-tertiary`, 2px below title

**Right side — summary counts:**
- "31.4 GB across 67 folders in 41 projects" — `label` (13px/400), `--text-secondary`

The subtitle in the header is the safety statement. It must be present and legible — not hidden in a tooltip, not buried at the bottom. The user sees it the moment they arrive on this screen.

---

### Deletion list

Scrollable. Fills the remaining vertical space between the review header and the footer bar.

The list is **grouped by project**. Each project is a collapsible group. All groups are expanded by default.

#### Project group header

Height: 36px. Background: `--bg-elevated`. Sticky within its scroll context (each group header sticks to the top of the visible area as the user scrolls through its artifacts — standard iOS/macOS grouped list behavior).

Content left to right, vertically centered. Padding: 0 24px.

- **Collapse arrow** — SF Symbol `chevron.down` (10px, `--text-tertiary`), rotates to `chevron.right` when collapsed
- **Project name** — `label-medium` (13px/500), `--text-primary`, 8px gap after arrow. Example: "startup-2021"
- **Path** — `mono-sm` (11px/400), `--text-tertiary`, 8px gap after name. Example: `~/projects/startup-2021`
- **Spacer (flex)**
- **Total being deleted from this project** — `label-medium` (13px/500), `--text-primary`. Example: "4.2 GB"
- **"Remove all" link** — ghost text link (component 1D), 12px/400, `--text-tertiary`, 12px gap after total. Deselects and removes the entire project group from the list. On click: the group disappears with a 150ms fade-out, the summary counts update.

---

#### Artifact rows within group

Height: 40px. Indented 24px from the group header. Padding: 0 24px 0 48px (left padding accounts for group indent).

Content left to right, vertically centered:

- **Artifact type icon** — SF Symbol (14px, `--text-tertiary`), same icon mapping as S05
- **Artifact name** — `label-medium` (13px/500), `--text-primary`, 8px gap. Example: "node_modules"
- **Path** — `mono-sm` (11px/400), `--text-tertiary`, 6px gap, middle-truncated. Example: `~/projects/startup-2021/…/node_modules`
- **Spacer (flex)**
- **Size** — `label` (13px/400), `--text-secondary`, right-aligned, 60px fixed width
- **Remove (×) button** — SF Symbol `xmark.circle.fill` (16px, `--text-tertiary`), 12px gap after size. On hover: `--danger` color. On click: row fades out (150ms), group total and summary counts update immediately.

The remove button is the key control on this screen. Every artifact row has one. It must be clearly visible — not hidden behind a hover. `--text-tertiary` at rest (present but quiet) turning `--danger` on hover (intentional, consequential) is the right calibration.

Rows within a group are separated by 1px `--border-subtle` dividers.

---

#### Data to show in primary design

Show 3 project groups. Groups 1 and 2 fully expanded, group 3 collapsed (to show the collapsed state).

**Group 1: startup-2021** (~/projects/startup-2021)
3 artifact rows:
- `node_modules` · `~/projects/startup-2021/…/node_modules` · 3.9 GB
- `.next/` · `~/projects/startup-2021/…/.next` · 340 MB
- `.eslintcache` · `~/projects/startup-2021/…/.eslintcache` · 2.1 MB
Group total: 4.2 GB

**Group 2: ml-experiments** (~/code/ml-experiments)
2 artifact rows:
- `__pycache__` · `~/code/ml-experiments/…/__pycache__` · 890 MB
- `.venv/` · `~/code/ml-experiments/…/.venv` · 2.9 GB
Group total: 3.8 GB

**Group 3: learning-rust** (~/rust/learning-rust) — collapsed
Shows only the group header. "4.1 GB" total. No artifact rows visible.
The collapsed state implies there are more items below — a scroll indicator or the bottom of the window is sufficient to communicate this. Do not show a "X items hidden" label — the collapse arrow is enough.

Below group 3, a faint scroll indicator or fade at the bottom of the list signals more groups exist beyond the viewport.

---

### Important note: an item was removed

Show a variant frame (S06-item-removed) where the user has just clicked the (×) on the `.eslintcache` row in Group 1. The row has been removed. The group total has updated to "4.2 GB → 4.0 GB" (animate this). The summary in the review header updates to "31.2 GB across 66 folders in 41 projects". The right panel total also updates.

This state demonstrates the live-edit behavior of the review screen.

---

## Right panel — After deletion preview

Sticky. Fills full height of the right column minus toolbar.

Background: `--bg-elevated`. Left border: 1px `--border-subtle`. Padding: 20px.

This panel answers: "What will my disk look like after I do this?"

### After deletion preview — content

**Section label:** "After deletion" — `caption` (11px/500), `--text-tertiary`, uppercase, letter-spacing 0.06em.

**Disk space bar (component 7D from Step 2.1):**
Show the before/after side by side, stacked vertically with labels.

Before bar (labeled "Now"):
- Used (gray fill): 312 GB
- To be freed (accent blue fill): 31.4 GB
- Free (empty track): 156.6 GB
- Total: 500 GB

After bar (labeled "After"):
- Used (gray fill): 280.6 GB
- Free (empty track): 219.4 GB
- No blue segment (it's been freed)

Between the two bars: a small annotation showing the delta — "−31.4 GB" in `--accent` color, 13px/500, centered between the two bars.

Each bar: 240px wide, 12px height, labeled with the used/free amounts in `caption` (11px/400, `--text-tertiary`) below.

Gap between "Now" bar and "After" bar: 16px (plus the "−31.4 GB" annotation in between).

---

**Safety reminder:**

Below the bars (20px gap):

SF Symbol `trash` (14px, `--text-tertiary`) + "Items go to Trash, not permanently deleted" — `caption` (11px/400), `--text-tertiary`), 6px gap after icon.

One line. Low emphasis. It has already been said in the header — here it is a quiet, final reminder.

---

**Empty Trash toggle:**

Below the safety reminder (12px gap):

A toggle row (component 5B):
- Label: "Empty Trash after deletion" — `label` (13px/400), `--text-secondary`
- Toggle: off by default
- Sublabel below (when toggle is off): "Items can be restored from Trash" — `caption` (11px/400), `--text-tertiary`
- Sublabel below (when toggle is on): "This cannot be undone." — `caption` (11px/400), `--danger`, replacing the previous sublabel

The toggle-on sublabel in danger color is the sharpest warning in the entire app. It should feel different — not alarming, but unambiguous. The user who turns this on is making a permanent choice and the design must reflect that without being theatrical.

Show the toggle in off state in the primary design. Show on state as an annotation or variant.

---

## Footer bar (sticky)

Height: 52px. Full window width. Background: `--bg-elevated`. Top border: 1px `--border-subtle`. Padding: 0 32px.

This is the final action bar. It contains exactly two elements:

**Left side:**
"← Back to results" — secondary button (component 1C, 32px), returns to S04 with selections intact.

**Right side:**
**"Delete 31.4 GB" button** — the most consequential button in the app.

Specs:
- Component 1B (destructive button, from Step 2.1)
- Large variant (36px height)
- Label: "Delete 31.4 GB" — updates live as items are removed from the list
- Color: `--danger`

**Countdown state (first use only):**
On first use in a session, the button enters the countdown state for 2 seconds before becoming pressable. Reference component 1B countdown state from Step 2.1 precisely:

- Background: `--danger` at 45% opacity
- A progress fill sweeps left-to-right across the button over exactly 2 seconds (linear easing)
- The fill uses `--danger` at full opacity — so the button visually "loads" from left to right
- Leading icon: SF Symbol `lock.fill` (12px, white) during countdown
- Label: "Delete 31.4 GB" — unchanged, always visible
- At 2 seconds: lock icon disappears, button reaches full opacity, becomes pressable
- Subtle visual: at the exact moment the button unlocks, a very brief (80ms) brightness pulse — the button goes slightly brighter then settles. This micro-moment marks the transition from locked to ready.

Show the button in three sub-states within the footer bar:
1. Countdown at ~50% (lock icon visible, half-filled progress)
2. Countdown at 100% (just unlocked — brightness pulse moment)
3. Active / ready to press (no lock, full opacity, hoverable)

On subsequent uses in the same session: no countdown. Button is immediately active.

---

## States to design

### State 1 — Primary (first use, countdown active at 50%)
Full review list (3 groups), right panel showing disk bars and toggle off, footer button at 50% countdown.

### State 2 — Ready to delete
Same list, countdown complete, button fully active and hoverable. This is the state just before the user clicks.

### State 3 — Item removed
`.eslintcache` row removed from Group 1. Group total updated. Summary counts updated. Button label updated ("Delete 31.2 GB"). Right panel disk bars updated. Demonstrate live-edit behavior.

### State 4 — Empty Trash toggle on
Right panel toggle flipped on. "This cannot be undone." sublabel in `--danger`. Everything else unchanged. Show as variant.

### State 5 — Single project (from S05)
User arrived from S05 "Delete selected from this project" — only one project group in the list (startup-2021, 4.2 GB). Button label: "Delete 4.2 GB". Right panel adjusted. Simpler, cleaner state — tests the design at minimum content.

---

## Micro-details to get right

**The countdown is a design feature, not a bug.** Two seconds feels like a long time when you're looking at a button. That's intentional. The user watches the button fill, their eyes are on it, they are present and ready. When it unlocks, clicking it is an intentional act, not an accidental one. The lock icon during countdown communicates "wait" without words.

**Every remove (×) button is visible at rest.** Not hover-only. This is a review screen — the entire job of this screen is to give the user control. Hiding the controls until hover defeats the purpose. The `--text-tertiary` color keeps them quiet without hiding them.

**The "Remove all" link in group headers is `--text-tertiary`, not `--danger`.** It removes a whole project from the deletion list — but it's a reversible action (user can go back to S04 and re-select). Using danger color here would create false alarm. The real danger is the footer button.

**The right panel disk bars are not decorative.** They answer a specific question: "how much will this actually improve my situation?" 31.4 GB out of a 500 GB drive is 6.3% — that might look small on the bar. That's honest and important. If the number feels less impressive visually, that's correct — the design should not inflate the impact.

**The footer bar is full-width** — it spans both columns. This is different from S04 where the bottom bar was informational. Here it is the action zone. Spanning full width gives the delete button the gravitas it deserves.

**The "After deletion" label on the right panel** — not "Preview" or "Summary". "After deletion" is future tense — it puts the user mentally in the state they're committing to.

---

## What this screen must NOT look like

- **Not a confirmation dialog.** This is a full screen with real content — a scrollable list of exactly what will be deleted. A dialog would compress this into "Are you sure?" which destroys the transparency.
- **Not alarming.** The danger color appears on the footer button and the "cannot be undone" toggle sublabel only. The rest of the screen is calm. Red everywhere would make the user feel like they're about to do something dangerous — they're not.
- **Not passive.** Every element is interactive — remove buttons, collapse arrows, toggle, back button, delete button. The user is in control from top to bottom.
- **Not a wall of text.** The grouped structure with project headers keeps the list scannable even with 67 artifacts across 41 projects. The user should be able to find any project in under 5 seconds.

---

## Connections

| Action | Destination |
|---|---|
| "Delete X GB" (footer, countdown complete) | S07 — Deletion Progress |
| "← Back to results" (footer) | S04 — Project List (selections intact) |
| Remove (×) on artifact row | Removes row, updates totals (stays on S06) |
| "Remove all" on group header | Removes group, updates totals (stays on S06) |
| Settings gear | S09 — Settings |

---

## Deliverable frames

- [ ] S06-primary — Countdown at 50%, 3 groups, right panel showing — 900×600px dark mode
- [ ] S06-primary — Light mode variant — 900×600px
- [ ] S06-ready — Countdown complete, button active — 900×600px dark mode
- [ ] S06-item-removed — .eslintcache removed, live updates demonstrated — 900×600px dark mode
- [ ] S06-toggle-on — Empty Trash toggle on, danger sublabel — 900×600px dark mode
- [ ] S06-single — Single project, minimal content — 900×600px dark mode
- [ ] S06-min — Minimum window size 780×520px

---

## Annotation notes for handoff

- Footer button countdown: 2 seconds, linear fill, `--danger` full opacity fill over `--danger` 45% bg
- Lock icon: SF Symbol `lock.fill`, disappears at countdown end
- Unlock pulse: 80ms brightness flash at countdown completion
- Remove (×) hover: `--text-tertiary` → `--danger`, 80ms transition
- "Remove all" click: group fades out 150ms, counts update immediately
- Group headers: sticky within scroll — each header sticks to top as user scrolls through its artifacts
- Empty Trash toggle on: sublabel text changes to "This cannot be undone." in `--danger`, no animation
- Footer bar: full window width, spans both columns
- Button label "Delete X GB": updates live as items removed, 80ms count animation
- Right panel disk bars: update live as items removed (bar segments resize proportionally)

---

*This prompt is Step 4.4 of 10 in the Roomy design process. The next prompt (Step 5.1) covers S07 Deletion Progress and S08 Summary — the final two screens in the core flow.*
