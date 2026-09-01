# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users
Solo/indie developers managing multiple side projects.

## Product Purpose
A cross-platform personal command center combining manually tracked projects, internal tasks and bugs, activity logs, dashboard statistics, and read-only GitHub repository activity in a single unified view.

## Positioning
A focused, portfolio-quality personal productivity tool designed exclusively for solo developers. It provides high information density and integrated code context without the bloat of generic team or enterprise issue trackers.

## Operating Context
Used by independent developers tracking side-project progress, managing internal to-dos, and reviewing recent synchronized GitHub activity, primarily on desktop web and Android mobile devices.

## Capabilities and Constraints
**Capabilities:**
- Email/password authentication and RLS data isolation per user.
- Full CRUD for projects and internal issues (tasks and bugs with status/priority).
- Automated server-side generation of project and issue activity logs.
- Dashboard statistics reflecting internal issues.
- Read-only GitHub repository synchronization (recent commits and open issues) via a secure Supabase Edge Function without requiring a personal GitHub token.

**Constraints:**
- No collaboration, team features, invites, or shared projects.
- No file attachments, deadlines, time tracking, billing, or complex project-management views like kanban boards.
- External GitHub data is strictly read-only and kept separate from internal dashboard statistics.
- Relies on a fixed backend stack (Supabase, PostgreSQL).

## Brand Commitments
- Must feel like a modern personal developer tool.
- Strong emphasis on clean interfaces, modern typography, responsive design, and useful information density.
- Subtle "Makko/shark/ocean" identity.
- Must include a refined dark mode.
- Explicitly avoid generic admin dashboard layouts, Jira clone appearances, and excessive visual effects.

## Evidence on Hand
- A complete Supabase backend with transactional pgTAP testing and an Edge Function for GitHub sync.
- Phase 6 (Quality) web application UI built on React, Vite, and Tailwind CSS.

## Product Principles
1. **Developer First:** Prioritize high information density, correct technical execution, and sharp typography.
2. **Solo Focus:** Build exclusively for the individual; reject any team or enterprise-oriented feature creep.
3. **Clean Architecture:** Maintain strict separation between data access and the UI layer.
4. **Strong Identity:** Embrace the subtle Makko shark theme without resorting to loud gradients or generic SaaS aesthetics.
