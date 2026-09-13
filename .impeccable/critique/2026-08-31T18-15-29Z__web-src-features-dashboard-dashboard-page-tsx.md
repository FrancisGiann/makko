---
target: Makko authenticated dashboard
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
timestamp: 2026-08-31T18-15-29Z
slug: web-src-features-dashboard-dashboard-page-tsx
---
# Makko Dashboard Design Critique

Method: dual-agent (A: researcher_design_review · B: researcher_detector_evidence)

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 3/4 | Dashboard loading, refresh, and error states are clear; GitHub recovery feedback is weaker. |
| 2 | Match system / real world | 3/4 | Core developer vocabulary is clear, but some ocean/motivational language adds translation noise. |
| 3 | User control and freedom | 3/4 | Refresh, Edit/Cancel, navigation, theme, and sign-out controls exist; GitHub failure recovery is incomplete. |
| 4 | Consistency and standards | 3/4 | Components are cohesive, but “Done,” “completed,” and “closed” vary for the same state. |
| 5 | Error prevention | 2/4 | The GitHub username is accepted without visible constraints or validation guidance. |
| 6 | Recognition rather than recall | 3/4 | Counts and labels are clear; some existing destinations and actions are less discoverable. |
| 7 | Flexibility and efficiency | 2/4 | The surface has few accelerators or direct drill-down affordances for frequent users. |
| 8 | Aesthetic and minimalist design | 2/4 | The mascot, repeated gradients, large rounded cards, and duplicated counts compete for attention. |
| 9 | Error recognition and recovery | 2/4 | GitHub failures need specific, actionable, accessible recovery guidance. |
| 10 | Help and documentation | 1/4 | There is little contextual explanation for GitHub setup, graph behavior, or failures. |
| **Total** |  | **25/40** | **Acceptable — a solid base with meaningful UX work remaining.** |

## Design Specificity Verdict

**LLM assessment:** The interface is partially authored for Makko. The shark companion, cyan/ocean palette, calm copy, and clear separation between internal work and GitHub activity create genuine product character. Underneath that identity, the sticky SaaS header, four-metric strip, 2×2 card grid, workload list, and contribution graph remain category-standard. The mascot is prominent enough to compete with the personal command-center purpose, while repeated gradients and oversized rounded surfaces make the ocean identity louder than the brief’s “subtle” direction.

**Deterministic scan:** The detector reported four `gray-on-color` warnings in `web/src/features/dashboard/dashboard-page.tsx` at lines 213, 317 (two findings), and 344. All four are likely false positives caused by the scanner flattening Tailwind hover/dark variants and treating mutually exclusive theme classes as simultaneous. No confirmed target defect came from the deterministic scan.

**Visual overlays:** Mutable script injection succeeded, but the protected dashboard redirected to `/login`, and browser visibility is unavailable from a sub-agent thread. The injected detector therefore evaluated the login page, not the dashboard; its nine console findings were excluded. No reliable user-visible dashboard overlay is available from this run.

## Overall Impression

Makko already feels more personal than a generic project tracker, and its dark-mode foundation is credible. The single biggest opportunity is to reverse the hierarchy: operational status should lead, while the shark becomes a concise companion to the work rather than the page’s hero.

## What’s Working

1. **Recognizable product identity:** the shark asset, cyan/ocean language, and personalized copy make Makko memorable without changing the underlying workflow.
2. **Clear data boundaries:** the dashboard explicitly communicates that its counts are internal Makko issues, keeping GitHub data conceptually separate.
3. **Good baseline state handling:** skeleton loading, refresh feedback, empty-state guidance, focus rings, and reduced-motion handling are already present.

## Cognitive Load

- **Failed — single focus:** the mascot and speech bubble precede the dashboard heading and metrics, competing with the overview task.
- **Passed with a scaling caveat — chunking:** fixed groups remain within four items, but the workload list can become long and undifferentiated.
- **Passed — grouping:** totals, breakdowns, workload, and GitHub content are clearly grouped.
- **Failed — visual hierarchy:** the decorative companion is visually first; operational information begins below it.
- **Passed — one thing at a time:** controls are localized and the page is an overview rather than a multi-step workflow.
- **Passed with a data caveat — minimal choices:** fixed controls are restrained; more than four projects turns the workload list into a larger decision set.
- **Passed — working memory:** counts, labels, and explanations are colocated.
- **Failed — progressive disclosure:** all breakdowns and optional GitHub setup are exposed in one long surface with similar visual weight.

Overall cognitive load is **moderate (3 checklist failures)**. The issue is not too many features; it is insufficient ranking of those features.

## Emotional Journey

- **Arrival:** warm and distinctive, but the mascot delays the answer to “what needs my attention?”
- **Loading:** skeletons and “Checking the waters…” reassure users, though simultaneous animation can feel busy.
- **Success:** large totals and textual values beside bars make the result easy to scan.
- **Action:** project links create a route forward, but motivational copy sometimes promises an action not present in the hero.
- **Empty state:** reassuring tone and a clear route to Projects work well; “Click New project” is misleading because that control is not on this page.
- **Failure/end state:** GitHub errors create the weakest emotional valley because they lack specific reassurance and recovery.

## Priority Issues

### [P1] Core information sits below a decorative hero

- **Why it matters:** users visit the dashboard for immediate work status, but the 80–96px mascot and speech bubble appear before the page heading and metrics. Mobile users may scroll before seeing operational data.
- **Fix:** retain the mascot and every metric, but lead with the page title and metric strip. Recast the companion as a compact contextual summary beside or below the operational header, with a responsive collapsed form.
- **Suggested command:** `$impeccable layout`

### [P1] Companion copy duplicates data and occasionally misleads

- **Why it matters:** project/open/done numbers are repeated in the companion and metric strip, while “Let’s crush them!” and “Click New project” imply actions that are not present there.
- **Fix:** retain the companion and its states, but limit it to one factual insight plus one short state label. Standardize “open/completed/done” terminology and align empty-state copy with the existing Projects route.
- **Suggested command:** `$impeccable clarify`

### [P1] GitHub failures lack an actionable, accessible recovery state

- **Why it matters:** the third-party calendar can end in a bare failure message without a clear retry/edit path, live-region semantics, or guidance.
- **Fix:** retain the GitHub contribution feature and stored username, but add dashboard-level loading/error status, concrete recovery copy, and visible Retry/Edit actions.
- **Suggested command:** `$impeccable harden`

### [P2] Compact interaction and overflow behavior need deliberate adaptation

- **Why it matters:** the shell can wrap unpredictably, some controls are below common touch-target guidance, and the horizontally scrollable contribution graph hides its scrollbar and has no cue.
- **Fix:** retain the same navigation and controls while creating an intentional compact header, enlarging touch targets, and adding a visible horizontal-scroll affordance.
- **Suggested command:** `$impeccable adapt`

## Persona Red Flags

**Alex — power user:** useful metrics are delayed by the companion; repeated counts slow scanning; overview totals do not act as fast navigation; common actions have no keyboard-oriented acceleration.

**Sam — accessibility-dependent user:** the live speech bubble may announce long repeated copy after refresh; GitHub failures lack alert/status semantics; the contribution graph relies heavily on small colored cells and tooltips; compact controls can be difficult for motor users.

**Casey — distracted mobile user:** useful metrics can begin below the first viewport; the sticky header may wrap controls into a second row; the graph scrolls horizontally without a visible cue; top-positioned actions are less thumb-friendly.

## Minor Observations

- `makko-pet.png` is about 418 KB while rendered at only 80–96px.
- “Done,” “completed,” and “closed” are used for closely related state language.
- The existing Account route is not visible in the primary shell navigation.
- The GitHub username uses one browser-wide localStorage key, which can retain a stale handle after switching accounts.
- Geist is loaded from a CDN, so offline or blocked-font rendering falls back to the system stack.

## Questions to Consider

- Could the metric strip become the first anchor while the shark remains a compact contextual companion?
- Should Makko’s ocean voice be strongest in empty/loading/success moments instead of narrating every refresh?
- Can optional GitHub content stay fully present while receiving less visual weight than internal work status?
