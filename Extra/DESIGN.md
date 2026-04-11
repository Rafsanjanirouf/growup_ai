# Design System Specification: Hyper-Growth Kineticism

## 1. Overview & Creative North Star: "The Kinetic Nebula"
This design system is built to move. It rejects the static, boxy nature of traditional SaaS and instead embraces a "Kinetic Nebula" aesthetic—a philosophy where growth is visualized through depth, energy, and momentum. 

We are moving away from "template-style" layouts. Instead, we use **Plus Jakarta Sans** in high-contrast scales to create an editorial feel. The layout should feel like a premium fitness app crossed with a high-end digital magazine: intentional asymmetry, overlapping containers that break the grid, and a focus on "Progress as Art." Our goal is to make the user feel like they are entering a high-performance cockpit, not a spreadsheet.

---

## 2. Colors & Surface Philosophy
The palette is rooted in deep space and electric pulses. We use high-energy accents against a sophisticated, multi-layered dark foundation.

### Palette Strategy
*   **Primary (`#a8a4ff`):** The "Pulse." Used for active growth paths and core actions.
*   **Secondary (`#43f3d9`):** The "Mint Momentum." Used to highlight success, AI-driven insights, and completion states.
*   **Tertiary (`#ffd709` / Coin Gold):** The "Reward Tier." Reserved exclusively for gamified wins, badges, and premium milestones.
*   **Neutral Surfaces:** Utilizing `surface-container-low` to `surface-container-highest` to build depth without lines.

### The "No-Line" Rule
**Explicit Instruction:** You are prohibited from using 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example:
*   A card (`surface-container-high`) sitting on a section background (`surface-container-low`).
*   A sidebar (`surface-container-lowest`) contrasting against the main viewport (`surface`).

### Signature Textures & Gradients
To provide "soul" to the UI, use the **Kinetic Gradient**: A linear-diagonal transition from `primary` (#6C63FF) to `secondary` (#00D9C0). This gradient should be applied to:
1.  Primary Action Buttons.
2.  Progress Bar fills.
3.  Hero typography masks (for key conversion headlines).

---

## 3. Typography: Editorial Momentum
We use **Plus Jakarta Sans** for its modern, geometric clarity. The hierarchy is designed to feel authoritative yet breathable.

*   **The Display Scale:** Use `display-lg` and `display-md` for progress metrics and "Big Wins." These should be set with tight letter-spacing (-0.02em) to feel aggressive and modern.
*   **Headline & Title:** Use `headline-lg` for page titles. Pair these with asymmetrical layouts—don't always center them. Align them to the left with significant white space to the right.
*   **Body & Labels:** `body-lg` is your workhorse. Use `on-surface-variant` (the muted navy-grey) for secondary metadata to ensure the user’s eye is always drawn to the most important "kinetic" information.

---

## 4. Elevation & Depth: Tonal Layering
In this design system, depth is physical. We do not use traditional "drop shadows" which can look muddy in dark mode.

*   **The Layering Principle:** Stacking containers creates hierarchy. Place a `surface-container-highest` card on top of a `surface-container` background to create a natural "lift."
*   **Ambient Shadows:** If an element must float (like a Modal or FAB), use a large, diffused shadow (Blur: 40px+) with low opacity (4-8%). The shadow color must be a tinted version of `on-surface` (a deep navy tint), never pure black.
*   **The "Ghost Border" Fallback:** If a container lacks contrast against its background, use a "Ghost Border": the `outline-variant` token at **15% opacity**. This provides a whisper of a boundary without the "boxed-in" feel.
*   **Glassmorphism:** For top navigation bars and floating chips, use `surface-bright` with a **24px Backdrop Blur**. This allows the vibrant gradients of the content below to bleed through, creating a sense of environmental light.

---

## 5. Components

### Buttons: The Power Units
*   **Primary:** Kinetic Gradient (Violet to Cyan) with `on-primary-fixed` text. Radius: `xl` (3rem/48px). These should feel like "pills" that are ready to be pressed.
*   **Secondary:** `surface-container-highest` background with a `primary` Ghost Border. 
*   **States:** On hover, primary buttons should scale 1.02x and increase the shadow diffusion.

### Cards: Content Vessels
*   **Rule:** Forbid divider lines within cards.
*   **Structure:** Use vertical white space (32px+) to separate the header from the body. Use a `surface-container-high` background for the card and a `surface-container-lowest` for any nested input fields or sub-actions within that card.
*   **Corner Radius:** Use `md` (1.5rem) for standard cards and `lg` (2rem) for hero sections.

### Gamified Progress & Rewards
*   **Progress Bars:** Use a `surface-container-lowest` track with a Kinetic Gradient fill. 
*   **Reward Chips:** Small, high-contrast pills using `tertiary` (Coin Gold) backgrounds. These are the only elements allowed to use high-contrast dark text (`on-tertiary-fixed`) to signify a "Level Up."

### Inputs: The Interaction Hub
*   **Style:** Minimalist. No bottom line. Use `surface-container-lowest` as the fill. 
*   **Focus State:** The border transitions from 0% opacity to a 100% `secondary` (Cyan Mint) Ghost Border.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use asymmetrical spacing. A 64px left margin and 32px right margin can make a page feel more custom and designed.
*   **Do** use the Spacing Scale (1rem, 1.5rem, 2rem) strictly to maintain rhythm.
*   **Do** use "Glass" overlays for tooltips to keep the dark-mode environment feeling "airy."

### Don’t:
*   **Don’t** use pure `#000000` for backgrounds. It kills the depth. Always use `surface` (#0c0c1f).
*   **Don’t** use 1px dividers to separate list items. Use a 4px-8px gap and a slight background tint change instead.
*   **Don’t** use default Material shadows. They are too heavy for this "Kinetic" aesthetic. Use Tonal Layering first.