# Roomy — macOS App Icon
## Google Stitch Design Prompt · Step 1.2

---

## Context

You are designing the macOS app icon for **Roomy** — a native macOS developer utility that scans for regenerable build artifacts (node_modules, Python venvs, Rust target directories) and helps developers safely reclaim disk space from dormant projects.

This icon will appear in:
- The macOS Dock (various sizes, against dark and light desktops)
- Launchpad
- Finder sidebar (small, monochrome)
- Spotlight search results
- The Mac App Store
- The app's own welcome screen (~80px)
- Notifications

Read the visual identity established in Step 1.1 before proceeding:
- **Aesthetic:** Clean minimal, Raycast/Linear — precision tool for developers
- **Accent color:** Electric blue — precise, slightly desaturated, intentional
- **Personality:** Senior engineer's tool. Confident, not playful. Honest, not alarming.

---

## Icon design requirements

### Shape
Standard macOS superellipse (squircle). Follow Apple's icon grid precisely — use the official macOS app icon template with safe zones, key lines, and optical correction guides. Do not deviate from the superellipse shape.

### Size deliverables

Produce the icon at all required macOS sizes:

| Size | Usage |
|---|---|
| 1024×1024px | App Store, master artwork |
| 512×512px (@2x) | Finder large |
| 256×256px (@1x) | Finder medium |
| 128×128px (@2x) | Dock standard |
| 64×64px (@1x) | Dock small |
| 32×32px (@2x) | Finder list view |
| 16×16px (@1x) | Finder sidebar, menu bar |

Also produce:
- Dark mode variant (if the icon background reads differently against dark desktops)
- Monochrome/template variant for Finder sidebar use (16px, single color)

---

## Concept direction

### The metaphor

The icon should communicate: **space being made** — the act of clearing, opening up, creating room. This is not a trash can (deletion). It is not a hard drive (storage). It is the *result* — open space, breathing room, clarity after cleanup.

Three concept directions are proposed below. Explore all three at sketch level, then develop the strongest one to full fidelity.

---

### Concept A — The expanding room

**Metaphor:** A simple 2D or subtle 3D room — four walls, a floor, seen in isometric or flat perspective — that is visibly spacious. Nearly empty. Clean lines.

**Visual:** A minimal room outline, isometric view, with generous empty floor space. Perhaps a single small object (a tiny stack of boxes or a dot) in the corner — the last thing remaining after cleanup. The emptiness is the point.

**Color:** Deep blue-black background (close to `--bg-base` from the identity). The room lines in the accent electric blue, thin and precise. The empty floor in a very subtle lighter fill.

**Feel:** Architectural. Precise. Like a blueprint or a wireframe model. The sophistication is in the restraint — most of the icon is empty space.

**Risk:** Could read as a home/real estate app at small sizes. The lines must be sharp and technical-looking to stay in developer-tool territory.

---

### Concept B — The receding boxes

**Metaphor:** Stacked boxes (representing bloated project artifacts — node_modules, target/, venv) being compressed, collapsed, or pushed away. The icon captures the *moment of clearing*.

**Visual:** A tight cluster of small cubes or rectangles on one side of the icon — compressed, stacked — with clear, open space on the other side. An arrow or motion blur implies the direction of clearing. The cleared space is larger than the cluttered space.

**Color:** The stacked boxes in a muted, warm gray (dormant, dusty, old). The cleared space in the accent blue. A crisp dividing line between the two zones.

**Feel:** More dynamic than Concept A. The tension between clutter and space tells the story clearly.

**Risk:** Can look too "cleaner app" generic if the boxes aren't styled distinctively. The technical/developer angle needs to come through — consider making the boxes look like directory structures or terminal blocks rather than moving boxes.

---

### Concept C — The negative space arrow

**Metaphor:** Pure abstraction. A form that implies expansion or opening — like an arrow pointing outward, or a shape that opens up — rendered entirely through negative space against the background.

**Visual:** The icon background is the electric blue accent. A clean geometric form — perhaps two chevrons pointing outward, or a stylized "R" (for Roomy) where the interior space of the letterform is the visual message — cut from the background as negative space.

**Color:** Solid electric blue background. The form in white or near-white. No gradients. No shadows.

**Feel:** The most icon-like — abstract, bold, scales perfectly to 16px. Feels closer to Raycast, 1Password, or Notion in the dock. Developer-tool energy without being literal.

**Risk:** May feel too abstract — doesn't communicate "disk cleaning" without prior knowledge of the app. Acceptable for an App Store icon because the name "Roomy" does the explaining, but worth noting.

---

## Design principles for all concepts

### What this icon is NOT

- Not a trash can, recycle bin, or any deletion metaphor — Roomy never permanently deletes, it moves to Trash. The icon should not imply destruction.
- Not a hard drive, SSD, or storage device — too generic, looks like every other disk utility.
- Not a broom, vacuum, or cleaning tool — consumer app territory, wrong audience.
- Not the Roomy wordmark — the icon stands alone without text at most sizes.

### Rendering quality

- **No gradients as decoration.** If a gradient exists, it must serve depth or lighting — not be the visual hook.
- **No lens flare, gloss, or skeuomorphic lighting.** Flat rendering with subtle dimensional quality is acceptable. Think macOS Sonoma icon style — modern, restrained.
- **Crisp at all sizes.** The icon must be individually optimized for 16px and 32px — not just scaled down from 1024px. At 16px, only the essential silhouette remains. Design the small sizes explicitly.
- **Dark desktop readability.** The icon will most often appear against a dark macOS desktop or the dark Dock. Ensure sufficient contrast and visibility in that context.

### Color application

- Primary background: Deep blue-black (close to `#0F1014` from the identity, but may be slightly warmer or richer for icon purposes — icons often benefit from a slightly elevated version of the app's background color)
- Primary form: Electric blue accent (`--accent` from Step 1.1) and/or white/near-white
- Maximum 3 colors in the icon. Fewer is better.

### Geometry

- Use clean geometric primitives — rectangles, lines, circles, simple paths
- Prefer right angles and 45° diagonals over arbitrary curves
- Optical centering: the visual center of mass should sit slightly above the geometric center (standard icon compensation)
- Minimum stroke width at 1024px: 8px (so it remains visible at 16px after scaling)

---

## Small size optimization

At 16px (Finder sidebar), the icon reduces to approximately 12–14 actual pixels of content inside the superellipse. At this size:

- Only the primary silhouette matters — all detail disappears
- The icon must be recognizable as *Roomy specifically*, not just "some blue icon"
- Provide explicit 16px and 32px artwork — do not rely on scaling

Show the 16px version at 400% zoom in the deliverable so it can be evaluated properly.

---

## Deliverable checklist

Produce the following frames in the Figma file:

- [ ] Concept sketches — all three directions at rough level (grayscale acceptable)
- [ ] Developed concept — one direction at full fidelity, 1024×1024px
- [ ] All size variants — 512, 256, 128, 64, 32, 16px
- [ ] Dark desktop preview — icon placed on a dark macOS desktop mockup
- [ ] Light desktop preview — icon placed on a light macOS desktop mockup
- [ ] Dock preview — icon shown in a macOS Dock strip alongside common developer apps (VS Code, Terminal, Xcode, Finder) for size and style comparison
- [ ] Monochrome variant — 16px Finder sidebar template version
- [ ] 16px and 32px at 400% zoom — for small-size evaluation

---

## Reference icons (style and quality bar, not literal inspiration)

Study these for icon craft on macOS:

- **Raycast** — geometric, minimal, confident use of a single strong color
- **Linear** — restrained, the purple is used sparingly, strong at small sizes
- **Proxyman** — technical tool that still has a distinctive, well-crafted icon
- **Kaleidoscope** — developer tool icon that feels premium without being flashy
- **CleanMyMac X** — strong use of space metaphor (note: this is the direct competitor — Roomy should feel more technical and less consumer-friendly than CleanMyMac)

---

## Notes for the designer

The name "Roomy" is the biggest asset — lean into it. The icon's job is to make the concept of *space* and *breathing room* feel precise and technical, not cozy and residential. The same word that sells apartments should, in this context, communicate something closer to: cleared, efficient, optimized.

The best icons in the developer tool space (Instruments, Xcode, Proxyman) are confident enough to be abstract. They don't try to literally depict what the app does — they capture a *feeling*. For Roomy, that feeling is: the quiet satisfaction of a clean, spacious machine.

---

*This prompt is Step 1.2 of 10 in the Roomy design process. The icon's color values, style, and rendering quality will establish the visual anchor for all subsequent screen designs (Steps 2.1 through 5.2).*
