---
name: Makko
description: A calm, focused command center for independent developers.
colors:
  makko-cyan: "#06b6d4"
  cyan-action-light: "#0891b2"
  cyan-action-dark: "#22d3ee"
  cyan-deep: "#0e7490"
  cyan-pale: "#a5f3fc"
  sky-bloom: "#0ea5e9"
  deep-harbor: "#070d18"
  harbor-surface: "#0c1527"
  harbor-elevated: "#101c33"
  harbor-inset: "#080f1d"
  light-canvas: "#f4f7fb"
  paper: "#ffffff"
  neutral-50: "#f8fafc"
  neutral-100: "#f1f5f9"
  neutral-200: "#e2e8f0"
  neutral-300: "#cbd5e1"
  neutral-400: "#94a3b8"
  neutral-500: "#64748b"
  neutral-600: "#475569"
  neutral-700: "#334155"
  neutral-800: "#1e293b"
  neutral-900: "#0f172a"
  neutral-950: "#020617"
  success: "#10b981"
  success-bright: "#34d399"
  warning: "#f59e0b"
  danger: "#f43f5e"
  danger-bright: "#fb7185"
  focus-sky: "#38bdf8"
typography:
  display:
    fontFamily: "Geist, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "60px"
    fontWeight: 700
    lineHeight: "1.15"
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "Geist, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: "1.25"
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Geist, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: "1.333"
    letterSpacing: "-0.025em"
  body:
    fontFamily: "Geist, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "1.5"
  label:
    fontFamily: "Geist, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "1.333"
  scale:
    xs: "10px"
    sm: "12px"
    md: "14px"
    lg: "16px"
    xl: "18px"
    2xl: "20px"
    3xl: "24px"
    4xl: "30px"
    5xl: "36px"
    6xl: "60px"
rounded:
  xs: "2px"
  sm: "4px"
  md: "6px"
  lg: "8px"
  xl: "12px"
  2xl: "16px"
  3xl: "24px"
  pill: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  2xl: "24px"
  3xl: "32px"
  4xl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.cyan-action-light}"
    textColor: "{colors.paper}"
    typography: "{typography.label}"
    rounded: "{rounded.2xl}"
    padding: "10px 20px"
  button-primary-dark:
    backgroundColor: "{colors.cyan-action-dark}"
    textColor: "{colors.neutral-950}"
    typography: "{typography.label}"
    rounded: "{rounded.2xl}"
    padding: "10px 20px"
  button-secondary:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.neutral-700}"
    typography: "{typography.label}"
    rounded: "{rounded.2xl}"
    padding: "8px 16px"
  input-text:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.neutral-900}"
    typography: "{typography.body}"
    rounded: "{rounded.2xl}"
    padding: "12px 16px"
  nav-workspace:
    backgroundColor: "{colors.neutral-100}"
    textColor: "{colors.neutral-600}"
    typography: "{typography.body}"
    rounded: "{rounded.2xl}"
    padding: "4px"
  chip-tag:
    backgroundColor: "{colors.neutral-100}"
    textColor: "{colors.neutral-600}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "2px 10px"
  card-surface:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.neutral-900}"
    rounded: "{rounded.3xl}"
    padding: "24px"
  companion-bubble:
    backgroundColor: "rgba(255, 255, 255, 0.85)"
    textColor: "{colors.neutral-900}"
    rounded: "{rounded.2xl}"
    padding: "18px"
---

# Design System: Makko

## Overview

**Creative North Star: "Makko Tideboard"**

Makko is a personal command center for independent developers. Its visual language keeps the work legible and close at hand: calm surfaces, crisp Geist typography, cyan signals, and a small shark companion that gives the product a human pulse without becoming the task itself.

The voice is **Quiet confidence**: brief, calm, and low-distraction. Light mode sits on a cool canvas; dark mode moves into Deep Harbor with layered blue-black surfaces. Translucent headers, restrained ambient gradients, tactile controls, and clear state colors provide warmth while preserving useful information density.

The system avoids generic admin-dashboard and Jira-clone styling, loud gradients, and excessive effects. Cyan is the product signal, not wallpaper; the shark/ocean identity stays concise and purposeful.

**Key Characteristics:**
- Calm, private workspace language for solo builders.
- Makko Cyan signals action, focus, and active work.
- Deep Harbor dark mode with tonal surface layers.
- Tactile, friendly controls with generous curved corners.
- Dense but readable status, project, issue, and activity groupings.

## Colors

The palette is a cool cyan current moving across paper and Deep Harbor surfaces. The same semantic roles adapt between light and dark themes instead of treating dark mode as an inversion.

### Primary

- **Makko Cyan** (#06b6d4): The core brand signal for caret color, selection, progress, activity, and supporting accents.
- **Cyan Action Light** (#0891b2): The light-theme filled-action color for primary buttons and links.
- **Cyan Action Dark** (#22d3ee): The dark-theme filled-action color, paired with a near-black label color for contrast.
- **Cyan Deep** (#0e7490): The light-theme action hover and deep accent tone.
- **Cyan Pale** (#a5f3fc): The lightest cyan signal used in activity and supporting emphasis.

### Tertiary

- **Sky Bloom** (#0ea5e9): A secondary blue used only in ambient gradients and companion surfaces.

### Neutral

- **Deep Harbor** (#070d18): The dark page ground and primary ocean identity.
- **Harbor Surface** (#0c1527): The dark header, card, and application surface.
- **Harbor Elevated** (#101c33): A raised dark companion or speech-bubble surface.
- **Harbor Inset** (#080f1d): The dark input and inset field surface.
- **Light Canvas** (#f4f7fb): The light page ground.
- **Paper** (#ffffff): The light card, header, and control surface.
- **Neutral 50 / 100 / 200** (#f8fafc / #f1f5f9 / #e2e8f0): Light fills, muted wells, borders, and dividers.
- **Neutral 300 / 400 / 500 / 600** (#cbd5e1 / #94a3b8 / #64748b / #475569): Field borders, secondary copy, labels, and muted metadata.
- **Neutral 700 / 800 / 900 / 950** (#334155 / #1e293b / #0f172a / #020617): Strong copy, dark labels, dark controls, and dark action text.
- **Success** (#10b981) and **Success Bright** (#34d399): Completion, healthy session presence, and positive status.
- **Warning** (#f59e0b): Medium-priority and caution status.
- **Danger** (#f43f5e) and **Danger Bright** (#fb7185): Destructive actions and error status.
- **Focus Sky** (#38bdf8): The global visible focus outline.

### Named Rules

**The One Current Rule.** Use cyan for action, focus, active work, and product identity; reserve emerald, amber, and rose for their semantic statuses.

## Typography

**Display Font:** Geist (with `-apple-system`, BlinkMacSystemFont, `Segoe UI`, and Roboto fallbacks)

**Body Font:** Geist (with system sans-serif fallbacks)

**Character:** Geist keeps the interface modern, compact, and developer-native. Bold display and page headings provide direction; regular body copy stays short, calm, and scannable.

### Hierarchy

- **Display** (700, 60px / 36px compact, 1.15 line-height at the large size): Landing-page statements and the strongest product promise.
- **Headline** (700, 36px, 1.25 line-height): Page headings such as Dashboard and Projects, with a 30px step used where the page needs a smaller heading.
- **Title** (600, 24px, 1.333 line-height): Section headings such as Issues and Activity; 20px is used for compact card titles.
- **Body** (400, 14px, 1.5 line-height): Descriptions, metadata, form copy, and operational detail. Marketing paragraphs step to 16–18px with a looser line-height.
- **Label** (500, 12px, 1.333 line-height): Controls, tags, statuses, and compact metadata. Heatmap labels can step down to 10–11px.

### Named Rules

**The Quiet Hierarchy Rule.** Let weight and size establish hierarchy; do not add decorative all-caps labels or extra display faces to make routine work feel louder.

## Layout

The web application uses a centered `max-w-6xl` content frame (1152px). Page gutters are 20px by default and 32px from the `sm` breakpoint (640px); primary page padding is 32px vertically and grows to 48px on larger screens. Repeated sections use 32px top rhythm, with 24px gaps in card grids and 32px gaps in the project-detail split layout.

Responsive behavior is content-first: project cards become two columns at `md` (768px), dashboard and project-detail groups use two columns at `lg` (1024px), and controls wrap into vertical stacks on compact screens. The app header is sticky at the top with a translucent, blurred surface; workspace navigation stays in a compact rounded pill and the account controls move or hide as space narrows.

Operational surfaces favor small, dense rows inside generous containers: four dashboard metrics collapse to two columns on small screens, issue filters become a responsive grid, and activity heatmaps scroll horizontally when their fixed cell rhythm needs more width. Empty states use centered copy and a clear cyan next action.

## Elevation & Depth

The confirmed elevation philosophy is **tonal layers**. Light mode separates the Light Canvas, translucent Paper, muted neutral wells, and cyan-tinted surfaces; dark mode steps from Deep Harbor through Harbor Surface, Harbor Elevated, and Harbor Inset. Thin low-contrast borders make those layers legible. Shadows remain a restrained tactile support inherited from the implementation: small shadows establish resting controls and cards, while larger shadows appear on raised auth/empty/companion surfaces and hover states.

### Shadow Vocabulary

- **Resting 2xs** (`0 1px rgb(0 0 0 / 0.05)`): Small controls, tags, and compact account surfaces.
- **Resting xs** (`0 1px 2px 0 rgb(0 0 0 / 0.05)`): Default cards, metric strips, and light containers.
- **Support sm** (`0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)`): Empty-state icons and small raised wells.
- **Raised md** (`0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)`): Speech bubbles and active controls.
- **Raised lg** (`0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)`): Companion and prominent light surfaces.
- **Raised xl / 2xl** (`0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)` / `0 25px 50px -12px rgb(0 0 0 / 0.25)`): Auth, configuration, and dark raised surfaces.

### Named Rules

**The Tonal Layer Rule.** Establish depth with the surface step and border first; use a shadow to clarify a raised or interactive state, never as the primary decoration.

## Shapes

Makko uses gently curved, tactile silhouettes. Controls and fields are consistently 2xl (16px); cards, auth panels, and major empty states are 3xl (24px); nav tabs use xl (12px); and status/tag chips use a full pill. Tiny heatmap cells use xs (2px), while compact action rows can use lg (8px).

Borders are generally one pixel and low contrast, with white-alpha borders in dark mode and slate borders in light mode. Dashed borders mark empty states. `overflow-hidden` clips gradient and skeleton treatments cleanly to the enclosing radius. Forms use full-width fields, vertical labels, and resize-y textareas; the repeated 2xl field silhouette is part of the product's friendly, low-friction feel.

## Components

### Buttons

Buttons feel tactile and friendly: filled cyan actions carry the current forward motion, while bordered controls recede into the surface.

- **Shape:** 2xl corners (16px), with 10–14px vertical padding and 16–24px horizontal padding depending on the action label.
- **Primary:** Cyan Action Light on light surfaces and Cyan Action Dark on dark surfaces; white or Neutral 950 text respectively; medium 12px labels and a restrained cyan shadow.
- **Hover / Focus:** Light primary deepens to Cyan Deep and dark primary lifts to Cyan Pale; controls may scale by roughly 1–2% on hover. Every action has a 2px cyan visible focus ring with a 2px offset; destructive actions switch to rose rings.
- **Secondary / Ghost / Tertiary:** White or translucent tonal surfaces with a slate border and copy. Ghost actions have no fill at rest and gain a faint neutral well on hover; Delete stays rose and semantic.

### Chips

- **Style:** Full-pill neutral fills with low-contrast borders, 2px vertical and 10px horizontal padding, and compact medium labels.
- **State:** Tags are quiet metadata. Status, priority, and presence chips inherit the same silhouette but use cyan, emerald, amber, or rose semantic tints; active/selected states use the theme's brighter cyan text.

### Cards / Containers

- **Corner Style:** 3xl (24px) for major cards and panels; 2xl (16px) for nested controls and speech bubbles.
- **Background:** Paper/translucent white in light mode; Harbor Surface or a nearby tonal layer in dark mode. Cyan-to-sky gradients are reserved for companion, create, and empty-state surfaces.
- **Shadow Strategy:** Resting xs or 2xs for most containers; lg/xl/2xl only for prominent raised panels, auth, companion, or hover emphasis.
- **Border:** Slate 200–300 in light mode and white alpha (roughly 6–15%) in dark mode; cyan borders identify create/companion emphasis.
- **Internal Padding:** 20px–32px for dense cards, 24px–32px for major panels, and 16px–24px for nested surfaces.

### Inputs / Fields

- **Style:** Full-width white fields on light surfaces and Harbor Inset fields in dark mode, with a 1px slate/white-alpha border, 2xl radius, 12px vertical and 16px horizontal padding, and a small resting shadow.
- **Focus:** Border shifts to Makko Cyan or Cyan Action Dark and a soft cyan ring appears; the global focus outline remains available for keyboard navigation.
- **Error / Disabled:** Errors use Rose/Danger tint through the shared status message; disabled actions retain their shape and reduce opacity with a not-allowed cursor.

### Navigation

The public and workspace headers are sticky, translucent, and blurred. Workspace navigation is a rounded neutral pill with 4px padding; active tabs use a white or translucent inner surface, cyan text, a tiny ring, and a resting shadow. Inactive tabs use slate copy and gain a quiet neutral/white-alpha hover well. Public navigation pairs a quiet Sign in link with a filled Create account action. On compact screens, controls wrap and secondary account detail can hide.

### Makko Companion

The shark companion is the signature friendly touch: a small floating Makko pet, active-status dot, mood pill, and speech bubble that summarizes the current workload. It uses the same cyan-tinted tonal surfaces, 2xl bubble geometry, and reduced-motion fallback as the rest of the system. The message is contextual; operational metrics remain the page's source of truth.

### Status Messages

Shared status messages are compact 2xl bordered rows with a 16px Lucide icon, semantic tint, and assertive error or polite status live-region behavior. Error is rose, success is emerald, and informational status is cyan. Keep the copy direct and actionable.

## Do's and Don'ts

### Do:

- **Do** use Geist with the documented system fallbacks and let weight/size carry hierarchy.
- **Do** keep light mode on Light Canvas and dark mode on Deep Harbor with distinct tonal surfaces.
- **Do** use Makko Cyan for actions, focus, active work, and product identity; use emerald, amber, and rose semantically.
- **Do** preserve visible keyboard focus with a 2px Focus Sky outline and 2px offset.
- **Do** keep cards at 3xl and controls at 2xl unless a compact heatmap cell or pill specifically calls for another documented radius.
- **Do** honor reduced motion: fade/slide, pet float, pulse, and shimmer animations all stop under `prefers-reduced-motion: reduce`.
- **Do** keep the shark identity subtle and let project, issue, and activity information lead the user's next action.

### Don't:

- **Don't** drift toward a generic admin dashboard or Jira-clone visual language.
- **Don't** turn cyan or the ocean motif into loud gradients, wallpaper, or excessive decoration.
- **Don't** use extra display faces, decorative all-caps labels, or unnecessary visual effects that compete with operational copy.
- **Don't** flatten dark mode into a quick inversion; keep Deep Harbor's layered surfaces and white-alpha borders.
- **Don't** use shadows as the only depth cue when a tonal layer and border can establish the surface relationship.
- **Don't** make status colors decorative: reserve rose, amber, and emerald for their established meanings.
