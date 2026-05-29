# Roomy — S07 Deletion Progress + S08 Summary
## Google Stitch Design Prompt · Step 5.1

---

## Context

You are designing two screens for Roomy — a native macOS developer utility for reclaiming disk space from dormant project artifacts:

- **S07 — Deletion Progress:** The brief screen shown while files are being moved to Trash
- **S08 — Summary / Done:** The completion screen — the payoff of the entire flow

These two screens are covered in a single prompt because they form an inseparable sequence. S07 leads directly into S08. They share an emotional arc: **action → resolution**. Design them as a pair.

**Before starting:** Load the outputs from:
- Step 1.1 — Visual identity & color system
- Step 2.1 — Component library (especially 7C deletion progress bar, 7D disk space bar, 8B/8C summary numbers)

---

## S07 — Deletion Progress

### Screen purpose

Moving files to Trash is fast — typically 3–12 seconds for dozens of artifact folders. This screen exists for three reasons:

1. **Transparency** — the user can see exactly what is being moved, folder by folder
2. **Satisfaction** — watching the number tick up is the first taste of the payoff
3. **Preventing panic** — without a progress screen, a 5-second pause after clicking "Delete" feels like a crash

The emotional target: **calm momentum**. Not anxiety. Not celebration yet — that's S08. Just the quiet, satisfying feeling of work being done.

---

### Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: "Deleting…" label centered. No back button — deletion cannot be interrupted mid-way. Settings gear present but disabled (annotate).

---

### Layout

Full window. Single centered column, 480px wide. Generous whitespace above and below the content block — mirrors S01's layout philosophy.

```
[toolbar — 52px]
──────────────────────────────────────────────
[top padding — 60px]
[title]
[gap — 8px]
[current item path]
[gap — 32px]
[deletion progress bar]
[gap — 8px]
[progress label]
[gap — 32px]
[stats block]
[gap — 28px]
[animated disk indicator]
[bottom padding — 60px]
```

---

### Elements

#### Title

"Moving to Trash…"
`title-lg` (20px/600), `--text-primary`, centered.

No subtitle. The title is sufficient.

---

#### Current item path

Below title (8px gap). The path of the artifact folder currently being moved.

`mono-body` (13px/400), `--text-secondary`, centered, middle-truncated.

Example: `~/projects/old-startup/node_modules`

Updates live as each folder is processed. The path flickers through folders quickly — annotate that this updates approximately every 200–500ms during active deletion.

Show the path mid-process: `~/projects/startup-2021/node_modules`

---

#### Deletion progress bar

Component 7C (deletion bar) from Step 2.1. The heavier, more prominent bar — 8px height, `--accent` to lighter-blue gradient fill.

Width: 360px, centered.

Below bar (6px gap, right-aligned to bar width): progress fraction label.
"23 of 67 folders" — `caption` (11px/400), `--text-tertiary`

Show bar at approximately 35% filled in the primary design.

---

#### Stats block

Two stats side by side, centered, 240px total width (120px each).

Each stat:
- Value — `title-md` (20px/600), `--text-primary`
- Label — `caption` (11px/400), `--text-tertiary`, 4px below value

| Left stat | Right stat |
|---|---|
| "23" | "12.4 GB" |
| "Folders moved" | "Space freed so far" |

The "Space freed so far" value is in `--accent` — same as the "Recoverable so far" on S02. It is the hero number. It climbing during deletion is the emotional core of this screen.

Gap between the two stats: a 1px `--border-subtle` vertical divider, 32px tall, vertically centered between the two values.

---

#### Animated disk indicator

A visual representation of disk space being freed in real time. This is the most distinctive element on S07 — it gives the screen character without being decorative.

Design a minimal horizontal bar (similar to 7D but stripped down) showing:
- Total disk: 500 GB
- Used (gray): shrinking in real time from 312 GB toward 280.6 GB
- Freed so far (accent blue, animated): a growing segment between the shrinking used zone and the free zone

Specs:
- Width: 320px, centered
- Height: 6px (thinner than the deletion progress bar above — different visual register)
- Border radius: 3px
- The blue "freed so far" segment visibly grows left-to-right as deletion progresses
- Below bar: "312 GB used → 299.6 GB" — updating live, `caption` (11px/400), `--text-tertiary`

This is the only element on S07 that purely exists for satisfaction. The progress bar above it communicates progress. This communicates consequence — the disk is actually changing. Annotate it as an animation: the freed segment grows smoothly in real time, not in jumps.

Show the indicator with approximately 12.4 GB freed (matching the "Space freed so far" stat above).

---

### States

#### State 1 — Mid-deletion (primary design)
35% progress bar. 23 of 67 folders. 12.4 GB freed. Disk indicator showing the freed segment growing.

#### State 2 — Completion
Progress bar at 100%, fully filled. Stats frozen at final values: "67 folders" · "31.4 GB freed". The current item path disappears (replaced with nothing — the path label simply fades out as there is nothing left to process). The disk indicator shows the full freed amount.

After 1 second pause in this state, the screen auto-transitions to S08.

Annotate: "1-second pause at completion, then auto-transitions to S08 with 180ms ease-in-out fade."

Show the completion state as an annotated variant.

---

### Micro-details

**No cancel button.** Moving files to Trash is nearly instantaneous per folder — even 67 folders takes under 10 seconds. A cancel button would almost never be used, and if clicked mid-process would leave an inconsistent state (some folders moved, some not). The design makes the deliberate choice to not offer a way out. This was decided at the S06 stage — the countdown exists precisely so the user is committed before S07 begins. Annotate this decision.

**The title says "Moving to Trash…" not "Deleting…"** This language choice is deliberate throughout Roomy. "Delete" implies permanence. "Move to Trash" is accurate and less alarming. The title uses the correct verb. Preserve it exactly.

**The current item path must look active.** In a static design it just looks like a label. Annotate that it updates every 200–500ms — the rapid flickering through paths communicates genuine processing activity in a way a spinner cannot.

---

### Deliverable frames (S07)

- [ ] S07-primary — Mid-deletion at 35%, dark mode — 900×600px
- [ ] S07-complete — 100% complete, stats frozen, auto-transition annotated — 900×600px dark mode
- [ ] S07-primary — Light mode variant — 900×600px

---

---

## S08 — Summary / Done

### Screen purpose

This is the last screen in the core flow. The user just freed 31.4 GB. This is the payoff.

The emotional target: **quiet satisfaction**. Not confetti. Not "CONGRATULATIONS!!" Not a party. Roomy is a developer tool — developers find celebration theater embarrassing.

The satisfaction is in the numbers. The number is big. It speaks for itself. The design's job is to present it with confidence and get out of the way.

Secondary purpose: give the user three natural next steps (scan again, inspect the Trash, or just leave).

Tertiary purpose: gentle, non-pushy social sharing. Word of mouth matters for a $20 indie app. But the share prompt should feel like an afterthought, not a campaign.

---

### Window specifications

- 900×600px default, 780×520px minimum
- Toolbar: app icon + "Roomy" centered. No back button. Settings gear right. This is the end of the flow — going "back" from here would be confusing.

---

### Layout

Full window. Single centered column, 520px wide. The layout has three distinct vertical zones.

```
[toolbar — 52px]
──────────────────────────────────────────────
[top padding — 48px]
[hero zone — ~160px]
[gap — 32px]
[breakdown zone — ~100px]
[gap — 32px]
[actions zone — ~80px]
[gap — 24px]
[share prompt — ~52px]
[bottom padding — 48px]
```

---

### Elements

#### Hero zone

The central piece of the screen. The big number. Everything else defers to this.

**The number:**
"31.4 GB" — composed of the number ("31.4") and unit ("GB") as in S03, but even larger:
- Number: **64px/700**, `--text-primary`
- Unit: 32px/400, `--text-secondary`, baseline-aligned, 6px gap

Below (10px gap):
**"reclaimed"** — `title-md` (16px/400, lighter weight than usual), `--text-secondary`

Below (6px gap):
**"Across 41 projects · 67 folders deleted"** — `body` (14px/400), `--text-tertiary`

All three lines centered.

**Animation annotation:** On screen entry (auto-transition from S07), the number counts up from the S07 final value (which is also 31.4 GB — so this is more of a re-entrance animation than a count-up) with a 600ms ease-out. The number briefly scales from 90% to 100% as it enters, giving it a subtle "landing" feel. Annotate this.

**No icon, no checkmark, no celebration graphic** above or around the hero number. The number alone is the celebration. Any graphic would diminish it.

---

#### Before / After comparison

Component 8C from Step 2.1, centered in the 520px column.

Show two numbers side by side with a right-pointing arrow between them:

```
312 GB   →   280.6 GB
Before       After
```

Specs:
- "Before" value: 20px/400, `--text-tertiary` (grayed out — the past)
- Arrow: SF Symbol `arrow.right` (16px, `--text-tertiary`), 16px horizontal margin on each side
- "After" value: 20px/600, `--text-primary` (the present — emphasized)
- "Before" / "After" labels: `caption` (11px/400), `--text-tertiary`, centered below each value

Below the before/after (12px gap):

**Freed highlight pill:**
A pill containing "−31.4 GB freed" — `label-medium` (13px/500), `--accent`, on `--accent-subtle` background.
- Padding: 4px 12px
- Border radius: 12px (full pill)
- Centered below the before/after comparison

---

#### Breakdown

Below the before/after (32px gap from the pill). Two pieces of information in a compact row, centered:

**By ecosystem:**
"Node.js 24.1 GB · Python 7.3 GB" — `label` (13px/400), `--text-secondary`

Small ecosystem icons (12px each) preceding each name.

**Largest single save (below ecosystem line, 6px gap):**
SF Symbol `star` (11px, `--text-tertiary`) + "Biggest save: target/ in ~/rust/learning-rust — 4.1 GB" — `caption` (11px/400), `--text-tertiary`

This "biggest save" line is a small moment of specificity. It makes the abstract total feel real — there's a specific folder in a specific project that accounted for a large chunk. Developers will recognize it and smile.

---

#### Actions zone

Three buttons, stacked vertically, centered, 240px wide each.

**Button 1: "Scan again"**
Primary button (component 1A), large (36px), `--accent` color (not `--danger` — this is a constructive action). Runs a fresh scan to confirm cleanup and find anything remaining.

**Button 2: "View in Trash"**
Secondary button (component 1C), 32px. Opens macOS Trash in Finder. Let the user inspect what was moved before the Trash is emptied. This is the safety valve — even at this final screen, the user can verify before any permanent deletion happens.

**Button 3: "Done"**
Ghost text link (component 1D). Returns to S01 Welcome screen. The most understated action gets the most understated style — the user who is satisfied and just wants to close can do so quietly.

Gap between buttons: 8px.

---

#### Share prompt

Below the actions zone (24px gap). Subtle, non-pushy. The whole section has lower visual weight than everything above it.

A horizontal strip, centered, containing:

- Small text: "Enjoying Roomy? A tweet helps." — `caption` (11px/400), `--text-tertiary`
- **"Share on X →"** — small secondary button (component 1C, 28px height, 12px font). Launches a pre-filled tweet: `"Just reclaimed 31.4 GB of node_modules and Python venvs from dormant projects using Roomy — [URL]"`
- "Not now" — ghost text link (component 1D), `caption` (11px/400), `--text-tertiary`. 8px gap after the share button.

The strip should feel like a PostScript — something added at the bottom of a letter. It should not compete with any element above it. If the user ignores it, that is the correct outcome for most users.

**Do not use the word "please".** Do not show a star rating prompt. Do not use an emoji in the copy. The tone is developer-to-developer, casual and direct.

---

### States to design

#### State 1 — Primary (large results)
31.4 GB reclaimed. As fully described above.

#### State 2 — Modest results
2.4 GB reclaimed, 8 projects. The hero number is smaller. Design must still feel like a payoff — not deflating. The number "2.4 GB" should still be confident at 64px.

Considerations:
- "Across 8 projects · 12 folders deleted"
- Before/after: "312 GB → 309.6 GB" — honestly a small change on the disk bar
- The before/after comparison is honest — 2.4 GB on a 500 GB drive is tiny. That's fine. The ecosystem breakdown and "biggest save" line provide specificity that keeps the screen from feeling empty.

Show as a separate variant frame to verify the design holds at low numbers.

#### State 3 — Re-scan results (second scan after cleanup)
User clicked "Scan again" from S08. The second scan found 8.2 GB remaining (active projects that weren't deleted). S03 Overview shows the smaller number. Eventually returns to S08 again with a smaller reclaim number.

This state is not a new design — it reuses S08 State 2. But annotate that S08 works for both first and subsequent scans.

---

### Micro-details

**64px is the right size for the hero number.** Larger would be trying too hard. Smaller would not land with impact. 64px at 700 weight in the Geist typeface (or equivalent) fills the center of the window with authority without feeling gaudy. Do not compromise on this size.

**"reclaimed" in lowercase** — not "Reclaimed", not "RECLAIMED". Lowercase is quieter and more confident. The number is the celebration. The label is just context.

**The "Scan again" button uses `--accent`, not `--danger`.** This is the only primary button in the app that uses accent color instead of danger. After the deletion is done, there is nothing dangerous left on this screen. "Scan again" is constructive. Give it the constructive color.

**The "Done" ghost link returns to S01.** Not to a blank state, not to an exit dialog. S01 with its "View last scan from today" option (State B) becomes available. The user can always come back to what they just did.

**The share prompt disappears if the user has already shared** (implementation note, not a design concern — but annotate it so the developer knows this state needs handling).

**The "biggest save" line is optional copy** — if a scan only found `__pycache__` folders across 10 projects, there is no single dramatically large save to highlight. In that case the line should be omitted. Show this omission in the modest results variant (State 2) — no "biggest save" line when the amounts are all small.

---

### What these screens must NOT look like

**S07:**
- Not a loading spinner with "Please wait…" — this screen has live data and a growing number
- Not a modal or sheet — it is a full window
- Not cancellable — no cancel button, no back button

**S08:**
- Not a party — no confetti, no animated stars, no "🎉 Amazing!", no applause graphics
- Not a survey — no "How was your experience?", no star ratings
- Not a upsell — no "Upgrade to Roomy Pro", no "Also try our other apps"
- Not deflating for small numbers — 2.4 GB should feel like a legitimate win, not an apology

---

### Connections

| Screen | Action | Destination |
|---|---|---|
| S07 | Auto-transition at completion | S08 (180ms fade) |
| S08 | "Scan again" | S02 — Scanning Progress |
| S08 | "View in Trash" | macOS Trash (Finder) |
| S08 | "Done" | S01 — Welcome (State B) |
| S08 | "Share on X →" | System browser, pre-filled tweet |
| S08 | Settings gear | S09 — Settings |

---

### Deliverable frames

**S07:**
- [ ] S07-mid — 35% progress, mid-deletion — 900×600px dark mode
- [ ] S07-complete — 100% complete, auto-transition annotated — 900×600px dark mode
- [ ] S07-light — Light mode variant — 900×600px

**S08:**
- [ ] S08-primary — 31.4 GB reclaimed, all elements — 900×600px dark mode
- [ ] S08-primary-light — Light mode variant — 900×600px
- [ ] S08-modest — 2.4 GB reclaimed, modest results variant — 900×600px dark mode
- [ ] S08-min — Minimum window size 780×520px

---

### Annotation notes for handoff

**S07:**
- Current item path: updates every 200–500ms during active deletion
- "Space freed so far" value: `--accent` color, increments live
- Disk indicator freed segment: grows smoothly in real time, not in jumps
- Completion → S08: 1-second pause, then 180ms ease-in-out fade transition
- Settings gear: disabled during deletion (annotate cursor: not-allowed)
- No cancel/back button — deliberate, annotate rationale (committed in S06 countdown)

**S08:**
- Hero number entry: 90% → 100% scale, 600ms ease-out, on screen arrival from S07
- "Scan again" → S02: 180ms transition
- "Done" → S01 State B: 180ms transition
- Share button: opens system browser to pre-filled tweet URL
- "Not now": dismisses share prompt (section collapses with 150ms ease-out), does not navigate
- "Biggest save" line: omit if no single artifact is significantly larger than others (threshold: >10% of total)

---

*This prompt is Step 5.1 of 10 in the Roomy design process. One prompt remains: Step 5.2 covering S09 Settings and S10 Exclusions Manager — the utility screens that support the core flow.*
