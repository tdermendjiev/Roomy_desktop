# Roomy — Marketing Landing Page
## Google Stitch Design Prompt · Landing Page

---

## Context

You are designing the **marketing landing page** for **Roomy** — a native macOS utility that scans for regenerable developer artifacts (node_modules, Python venvs, Rust target directories) and helps developers safely reclaim disk space from dormant projects.

This is a web page, not a macOS app screen. It lives at `roomy.app` (or equivalent). Its job is to convert a developer who has heard about Roomy — from a tweet, a blog post, a Hacker News comment — into a download or purchase.

**Before starting:** Load the visual identity from Step 1.1 and the app icon from Step 1.2. The landing page is a direct extension of the app's design language — same typeface, same color system, same personality. It should feel like the app opened in a browser.

**Reference:** Study the structure and aesthetic of [cindori.com/sensei](https://cindori.com/sensei) carefully. That page is the closest existing example of the style, density, and scroll rhythm this landing page should achieve. Do not copy it — understand what makes it work and apply those principles to Roomy.

---

## What makes the Sensei page work (and what to adopt)

- **Dark, near-black background throughout** — the whole page is one continuous dark surface. Sections are not separated by alternating white/gray backgrounds. The dark background makes the app screenshots float.
- **App screenshots as the hero content** — real product UI, not illustrations or icons. The screenshots do the selling. The copy supports them.
- **Section headers are large and declarative** — "The All-in-One Mac System Performance Monitoring Tool." Full stops. Confident.
- **Feature sections alternate layout** — screenshot left / copy right, then screenshot right / copy left. Creates rhythm without monotony.
- **Minimal navigation** — logo left, a few links, two CTAs. Nothing fights for attention with the product.
- **Social proof is restrained** — press logos and a few testimonials, not walls of reviews.
- **CTA appears multiple times** — hero, mid-page, and bottom. Never more than one scroll away.

---

## What to do differently from Sensei

- **Roomy is more focused** — one feature, not a feature-packed suite. The page should be shorter and tighter. No need for 8 feature sections.
- **Developer-specific copy** — Sensei talks to general Mac users. Roomy talks to developers. The copy can be more technical, more direct, and slightly more irreverent.
- **The emotional hook is different** — Sensei sells "performance". Roomy sells "you had no idea you had this much junk". The first scroll should create that feeling.
- **No subscription** — this is a one-time purchase indie app. That should be clear from the first CTA area and celebrated, not hidden.

---

## Page structure

The page is a single-page scroll. No sub-pages, no tabs. Sections flow top to bottom.

```
01  Navigation bar
02  Hero section
03  Social proof bar (press logos)
04  Feature section 1 — The scan
05  Feature section 2 — Project age intelligence
06  Feature section 3 — Review and control
07  Feature section 4 — The result
08  Philosophy strip
09  Testimonials
10  Pricing / CTA
11  Footer
```

---

## Design system (web adaptation)

### Color

All values from Step 1.1, adapted for web:

- **Page background:** `#0F1014` (or the exact `--bg-base` value from Step 1.1). The entire page is this color. No white sections. No alternating backgrounds.
- **Elevated surfaces** (cards, nav, pricing box): `--bg-elevated` from Step 1.1
- **Text:** `--text-primary`, `--text-secondary`, `--text-tertiary` from Step 1.1
- **Accent:** `--accent` from Step 1.1 (electric blue) — used for CTAs, links, and accent text
- **Status colors:** Used contextually in feature sections that show the project age classification

### Typography

Same typeface as the app (Geist or equivalent). Web font loaded via CDN.

Scale for landing page (different from app scale — larger display sizes):

| Style | Size | Weight | Usage |
|---|---|---|---|
| `hero-title` | 64px | 700 | Main hero headline |
| `section-title` | 44px | 700 | Section header headlines |
| `feature-title` | 24px | 600 | Feature sub-headlines |
| `body-lg` | 18px | 400 | Hero supporting text, feature descriptions |
| `body` | 16px | 400 | General body text |
| `caption` | 13px | 400 | Labels, captions, fine print |
| `nav` | 14px | 500 | Navigation items |
| `cta` | 15px | 600 | Button labels |
| `mono` | 13px | 400 | Inline code, terminal references |

### Layout grid

- Max content width: **1120px**, centered
- Side padding: 40px (desktop), 24px (tablet), 16px (mobile)
- Section vertical padding: 96px top/bottom (desktop), 64px (mobile)

### Responsive breakpoints

Design at three widths:
- **Desktop:** 1280px viewport
- **Tablet:** 768px viewport  
- **Mobile:** 390px viewport (iPhone 15 Pro width)

---

## 01 — Navigation bar

Position: fixed, top of page. Full viewport width.
Background: `#0F1014` at 85% opacity + `backdrop-filter: blur(20px)`. On scroll past 60px: opacity increases to 95%. Transition 200ms.
Bottom border: 1px border `--border-subtle`.
Height: 60px.
Max content width: 1120px, centered.

**Left:** App icon (24×24px) + "Roomy" wordmark — `nav` style, `--text-primary`. 8px gap between icon and wordmark.

**Center (desktop only):** Navigation links — Features · Pricing · FAQ (if applicable). `nav` style, `--text-secondary`. Hover: `--text-primary`. 32px gap between links.

**Right:** Two CTAs side by side:
- "Download free" — secondary button style: no background, 1px `--border-default` border, `--text-primary`, 13px/500, 32px height, 16px horizontal padding
- "Buy now — $19" — primary button: `--accent` background, white text, 13px/600, 32px height, 16px horizontal padding

The price "$19" in the buy button is important — it sets expectations immediately. Developers notice when pricing is hidden. Show it in the nav.

**Mobile:** Hide center links. Keep both CTAs but shrink to icon-only on very small screens if needed.

---

## 02 — Hero section

The most important section. Sets everything.

**Vertical padding:** 120px top (accounts for fixed nav), 80px bottom.

### Layout: centered, single column

Everything center-aligned in this section. Max width 720px for text content.

### Eyebrow label

Small pill above the headline:
- Background: `--accent-subtle`
- Border: 1px `--accent` at 40% opacity
- Text: "Native macOS · One-time purchase · No subscription" — `caption` (13px/500), `--accent`
- Padding: 4px 12px, border-radius: full pill

### Headline

"Make room."

`hero-title` (64px/700), `--text-primary`, centered.

Below (8px gap): a second line in a slightly different treatment:
"Delete nothing permanent."

Same size and weight, but `--text-secondary`. The contrast between the confident first line and the reassuring second line captures the entire value proposition in two lines.

Alternative headline if the above feels too abstract:
"47 GB of node_modules.
You had no idea."

The alternative is more provocative and developer-specific. Present both options in the deliverable and flag them for A/B testing.

### Subheadline

Below the headline (20px gap):

"Roomy scans your projects for regenerable artifacts — node_modules, Python venvs, Rust target directories — and helps you reclaim disk space from projects you abandoned years ago. Nothing permanent. Everything safe."

`body-lg` (18px/400), `--text-secondary`, centered, max width 560px.

### CTA buttons

Below the subheadline (32px gap). Two buttons side by side, centered, 12px gap between them:

**"Download free"** — secondary button: `--bg-elevated` background, 1px `--border-default` border, `--text-primary` text, `cta` style, 40px height, 20px horizontal padding. SF Symbol `arrow.down.circle` leading icon (16px).

**"Buy now — $19"** — primary button: `--accent` background, white text, `cta` style, 40px height, 20px horizontal padding.

Below buttons (12px gap):
"macOS 13+ · Apple Silicon & Intel · One-time purchase" — `caption` (13px/400), `--text-tertiary`, centered.

### Hero screenshot

Below the CTA (48px gap):

A large, floating screenshot of the app's S03 Results Overview or S04 Project List screen. This is the single most persuasive element on the page — a developer scrolling past will stop when they see a real, well-designed macOS app.

Screenshot presentation:
- The screenshot sits inside a subtle macOS window frame (the traffic lights, toolbar, window chrome) — a thin, realistic window chrome, not an exaggerated illustration
- The window frame background: slightly lighter than the page background (`--bg-elevated`) so the window floats
- Subtle shadow below the window: `0 32px 80px rgba(0,0,0,0.6)` — deep shadow that grounds the floating window
- Border: 1px `--border-subtle` around the window frame
- Border-radius: 12px (macOS window corners)
- Width: 900px at desktop (the default app width), scales down proportionally on smaller screens
- The screenshot shows the S03 Results Overview screen — the "47.3 GB" hero stat, the ecosystem breakdown, the activity age bar. This is the most visually striking screen in the app.

**Animation annotation:** On page load, the window fades in (0 → 1 opacity) and slides up slightly (20px → 0 translate-y) over 600ms ease-out, with a 200ms delay (after the text has appeared). Annotate this. The window should feel like it gently settles into place.

---

## 03 — Social proof bar

A horizontal strip between the hero and first feature section. Subtle. Not a big deal. Just enough to establish legitimacy.

**Height:** 72px. Full width. Border-top and border-bottom: 1px `--border-subtle`.
**Background:** slightly different shade from page — `--bg-elevated` at 50% opacity.

Content: a centered row of 3–4 press logo SVGs (placeholders for MacRumors, MacStories, 9to5Mac, MacWorld). Each logo in `--text-tertiary` (not full white — muted). 48px gap between logos.

Before the logos, left-aligned: "As seen in" — `caption` (13px/400), `--text-tertiary`.

On mobile: logos wrap to two rows or scroll horizontally.

---

## 04 — Feature section 1: The scan

**Headline (section-title, 44px/700):**
"Scan your entire project history in under 60 seconds."

**Body (body-lg, 18px/400, `--text-secondary`, max 480px):**
"Roomy traverses your filesystem at full speed, identifying regenerable artifacts across every project — regardless of how deep they're buried. Node.js, Python, Rust, Ruby, Go, Java, Swift. All of it."

**Layout:** Screenshot left (60%), copy right (40%). Desktop only. Mobile: stacked, copy above screenshot.

**Screenshot:** S02 Scanning Progress screen — mid-scan state with live findings ticker and stats updating. Shows `node_modules`, `target/`, `venv/` rows appearing in the ticker.

**Feature bullets (below body text):**
Three short lines with a leading accent-colored dash or checkmark:
- "Scans 100,000 directories in under 60 seconds on M1"
- "Streams results live — see findings appear as they're discovered"
- "Detects 8 ecosystems and 30+ artifact types"

Each bullet: `body` (16px/400), `--text-secondary`. Accent `·` or `—` leading in `--accent`.

---

## 05 — Feature section 2: Project age intelligence

**Headline:**
"Knows which projects you abandoned in 2021."

**Body:**
"Roomy reads your git history and file modification dates to classify every project by activity. Dormant projects rise to the top. Active projects stay protected. You never have to guess what's safe."

**Layout:** Copy left (40%), screenshot right (60%). Alternating from section 04.

**Screenshot:** S04 Project List — showing the full list with red dormant rows at the top, green active row at the bottom. The status dots and the color contrast between dormant/active rows are the key visual.

**Feature bullets:**
- "Four activity levels: Active · Recent · Inactive · Dormant"
- "Based on last git commit date and file modification time"
- "Dormant projects pre-selected — delete with one click"

**Visual accent:** Above the headline, show the four status dots in a horizontal row with their labels — the mini legend from the app. This is a decorative use of the status color system that double-functions as a feature explanation.

```
● Active    ● Recent    ● Inactive    ● Dormant
```

Each dot in its status color, label in `--text-secondary`, `caption` style. Centered above the headline or inline as part of the section design.

---

## 06 — Feature section 3: Review and control

**Headline:**
"Nothing gets deleted without your say."

**Body:**
"Browse every project, understand every artifact, deselect anything you're not sure about. Roomy shows you exactly what will move to Trash before you commit — and it always goes to Trash, never permanently deleted."

**Layout:** Screenshot left (60%), copy right (40%).

**Screenshot:** S06 Selection Review — showing the grouped deletion list with the before/after disk bars visible in the right panel. The "Delete X GB" button with its countdown state visible.

**Feature bullets:**
- "Every artifact explained in plain language"
- "Remove individual items from the deletion list at any time"
- "Moves to Trash — restoreable anytime before you empty it"

**Trust detail:** Below the bullets, a small inline callout box:

```
[shield icon]  Safe by design
Roomy uses NSWorkspace.recycle() — the macOS
API for moving to Trash. It never calls
FileManager.removeItem(). Your files are not
permanently deleted.
```

Background: `--bg-elevated`. Border: 1px `--border-subtle`. Border-left: 3px `--accent`. Padding: 12px 16px. Border-radius: 6px. Text: `caption` (13px/400), `--text-secondary`. The API name in `mono` style.

This callout is aimed directly at developers. A developer who sees `NSWorkspace.recycle()` in a marketing page knows immediately that the developer knows what they're doing. It's a trust signal that only lands with the target audience — exactly who should be converting.

---

## 07 — Feature section 4: The result

**This section has a different layout — full-width, centered, impactful.**

**Background:** A subtle change — this section uses a very slight `--accent` tint at 4% opacity as a background wash. Barely perceptible, just enough to signal this section is different.

**Headline (centered):**
"31.4 GB reclaimed."
"In under 5 minutes."

Two separate lines. First line: `section-title` (44px/700), `--text-primary`. Second line: same size, `--text-secondary`.

**Body (centered, max 520px):**
"That's what a developer with 3 years of project history typically recovers on their first scan. node_modules alone accounts for ~65% of it. The rest is Python venvs, Rust build artifacts, and Xcode caches you forgot existed."

**Screenshot:** S08 Summary screen — the "31.4 GB reclaimed" hero state. The full before/after comparison, ecosystem breakdown. The completion screen.

Screenshot presentation: same floating window treatment as the hero. Width: 720px, centered.

**Below screenshot:** Three stats in a horizontal row, centered, 48px gap between them:

| Stat | Value | Label |
|---|---|---|
| 1 | "~40 GB" | Average first-scan recovery |
| 2 | "<60s" | Time to full scan on M1 |
| 3 | "$19" | One-time. No subscription. |

Each stat:
- Value: 36px/700, `--text-primary`
- Label: `body` (16px/400), `--text-secondary`, centered, max 160px

Thin vertical `--border-subtle` dividers between the three stats.

The "$19 · One-time. No subscription." stat is not a product spec — it's a value statement. A developer who has been burned by subscription pricing for every tool they use will notice this. Emphasize it.

---

## 08 — Philosophy strip

A narrow, full-width strip. Dark, minimal. No screenshot.

**Vertical padding:** 80px.
**Max content width:** 720px, centered.

A single centered quote — Roomy's product philosophy distilled:

> "One-time purchase. No subscription. No telemetry. No cloud. No account.
> Roomy does one thing, and it does it exceptionally well."

Style: 22px/400, `--text-secondary`, centered, line-height 1.6. The quote marks in `--accent`.

Below (24px gap): four small property pills in a horizontal row, centered, 8px gap between them:

Each pill:
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Text: `caption` (13px/500), `--text-secondary`
- Padding: 6px 14px
- Border-radius: full pill
- Leading SF Symbol icon (12px, `--text-tertiary`)

Pills:
- `checkmark` "One-time purchase"
- `lock` "Private — no telemetry"
- `wifi.slash` "Fully offline"
- `arrow.down.app` "Native macOS"

---

## 09 — Testimonials

**Headline (centered):** "Trusted by developers who ran `du -sh ~/` and were shocked."

The backticks around `du -sh ~/` are intentional and rendered in `mono` style. This headline will get a laugh from the right audience.

**Layout:** Three testimonial cards in a row (desktop), stacked on mobile.

Each card:
- Background: `--bg-elevated`
- Border: 1px `--border-subtle`
- Border-radius: 12px
- Padding: 24px
- Width: ~340px

Card content:
- Stars (5 filled dots in `--accent`, 10px each) — top
- Quote — `body` (16px/400), `--text-secondary`, line-height 1.6
- Separator: 1px `--border-subtle`, 16px vertical margin
- Author avatar (32px circle) + name (`label-medium` 13px/500, `--text-primary`) + role (`caption` 13px/400, `--text-tertiary`)

**Three placeholder testimonials (replace with real ones):**

1. "I had 47 GB of node_modules across projects I haven't touched since 2020. Took 3 minutes to clean up. The project age classification is exactly what I needed — I never would have known which ones were safe to delete."
   — **Alex M.**, Senior Full-Stack Engineer

2. "Finally an app that understands what a developer's disk actually looks like. Not photos, not downloads — node_modules and Rust build caches. Recovered 38 GB on first run."
   — **Sarah K.**, Freelance Developer

3. "The 2-second countdown on the delete button is a nice touch. Made me feel like the developer actually thought about what could go wrong. Bought it immediately after the free scan."
   — **David L.**, iOS & macOS Developer

---

## 10 — Pricing / CTA

The final conversion section. Clean. Confident. No dark patterns.

**Headline (centered):** "One price. Yours forever."

**Pricing card (centered, max 440px):**
- Background: `--bg-elevated`
- Border: 1.5px `--border-default`
- Border-radius: 16px
- Padding: 32px
- Optional subtle `--accent` glow on the border: `box-shadow: 0 0 0 1px --accent at 20% opacity` — very subtle

Card content (centered):

**App icon** (48×48px) centered at top.

**Price:**
"$19" — 48px/700, `--text-primary`
"One-time purchase" — `body` (16px/400), `--text-tertiary`, 4px below

**Feature list (left-aligned within card, 24px top margin):**
Six lines, each with a `checkmark` (12px, `--accent`) + text (`body` 16px/400, `--text-secondary`):
- Unlimited scans
- Scans 8 ecosystems + 30 artifact types
- Project age intelligence
- Safe delete — always moves to Trash
- macOS 13+ · Apple Silicon & Intel
- Free updates for life

**CTA buttons (full width, centered, 24px top margin):**
- "Buy now — $19" — primary button, `--accent`, full width (minus 32px padding), 44px height
- "Download free trial" — secondary button, full width, 44px height, 8px gap below primary

Below buttons: "Try before you buy. No account required." — `caption` (13px/400), `--text-tertiary`, centered.

**Below the pricing card (24px gap):**
A FAQ strip — three Q&As in a single row (desktop), stacked on mobile:

| Q | A |
|---|---|
| "What does 'free' mean?" | "Free download scans and shows results. Purchase required to delete." |
| "Does it work on Apple Silicon?" | "Yes. Native support for M1, M2, M3, and M4 Macs." |
| "Can I try before buying?" | "Yes — scan runs fully for free. Purchase unlocks deletion." |

Each Q&A: `caption` (13px/500, `--text-primary`) question + `caption` (13px/400, `--text-tertiary`) answer. 24px gap between Q&As. Optional thin vertical dividers between them.

---

## 11 — Footer

Simple. Not elaborate.

**Top border:** 1px `--border-subtle`. **Padding:** 48px top/bottom.

Three columns:

**Left:** App icon (24px) + "Roomy" wordmark + tagline "Reclaim disk space from dormant projects." + copyright "© 2025 [Developer name]. All rights reserved."

**Center:** Links in two groups:
- Product: Download · Pricing · Changelog
- Support: Documentation · Contact · Privacy Policy

**Right:** "Made with care for developers." + macOS badge (SF Symbol `apple.logo` + "macOS") in a pill. + Social link: X/Twitter icon.

All footer text: `caption` (13px/400), `--text-tertiary`. Links hover to `--text-secondary`. Logo/wordmark: `--text-primary`.

---

## Scroll behavior and animation principles

### Entrance animations (apply to all sections)

Every section's content (headline + body + screenshot) fades in and slides up as it enters the viewport:
- Opacity: 0 → 1
- Transform: translateY(24px) → translateY(0)
- Duration: 500ms
- Easing: ease-out
- Delay: stagger — headline first (0ms), body (80ms), bullets (160ms), screenshot (120ms)

Screenshots get a slightly more pronounced entrance — they travel further (36px → 0) and take longer (700ms).

### Screenshot parallax (subtle)

On scroll, the floating screenshots move at 85% of the scroll speed — a very subtle parallax that makes them feel like they're floating. Maximum offset: ±40px. Do not apply to mobile (performance).

### No scroll-hijacking, no section-snap. Standard web scroll only.

---

## Responsive notes

### Tablet (768px)
- Feature sections stack: screenshot above, copy below (or copy above, screenshot below, alternating)
- Hero screenshot scales to 100% viewport width minus 48px padding
- Three stat row in section 07 becomes a 3-column grid (same row, smaller)
- Testimonials: single column scroll or 2-up grid

### Mobile (390px)
- Nav: logo left, "Buy" button right only (no "Download free" — space constraint)
- Hero headline: 44px (down from 64px)
- All screenshots: full width minus 32px, no window chrome (just the app UI, rounded corners 8px)
- Feature sections: all stacked, copy then screenshot
- Stats row: stacked vertically, centered
- Pricing card: full width minus 32px padding
- Footer: single column

---

## Copy tone reference

The page talks to developers directly. Calibrate every headline and body paragraph against these principles:

**Do:**
- Be specific: "node_modules, Python venvs, Rust target/" — not "unnecessary files"
- Be honest about what's free vs paid
- Reference real commands: `npm install`, `cargo build`, `du -sh ~/`
- Trust the reader's technical literacy
- Use full stops on declarative statements

**Don't:**
- Use exclamation marks (ever)
- Say "blazing fast" or "powerful" or "easy to use"
- Use the word "cleaner" — Roomy is not CleanMyMac. It is a developer tool.
- Show fake before/after disk space animations
- Add urgency language ("Limited time!", "Act now!")

---

## Deliverable checklist

- [ ] Full-page desktop design at 1280px viewport — all 11 sections
- [ ] Mobile design at 390px — all 11 sections
- [ ] Tablet design at 768px — key sections (hero, 1–2 feature sections, pricing)
- [ ] Navigation bar — default + scrolled (increased opacity) states
- [ ] Hero section — both headline variants flagged for A/B
- [ ] Feature sections — all 4, desktop layout showing screenshot + copy alternation
- [ ] Pricing card — detailed, full card with all elements
- [ ] Hover states on nav links, CTA buttons, testimonial cards
- [ ] Animation annotations on key elements (hero window entrance, section fade-ins)

---

## Reference aesthetics (web, not the app references)

Study these marketing pages for tone and craft:

- **[cindori.com/sensei](https://cindori.com/sensei)** — the primary reference. Dark background, floating screenshots, section rhythm.
- **[raycast.com](https://raycast.com)** — how a developer tool markets itself with confidence and restraint
- **[linear.app](https://linear.app)** — dark, sharp, product-forward. The screenshots sell themselves.
- **[vercel.com](https://vercel.com)** — how Geist typeface looks in a dark marketing context

---

*This is the Landing Page prompt in the Roomy design process. It uses the visual identity from Step 1.1, the app icon from Step 1.2, and the app screenshots established in Steps 3.1–5.2 as its raw material.*
