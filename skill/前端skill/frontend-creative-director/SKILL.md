---
name: frontend-creative-director
description: >-
  Taste and art-direction layer for premium websites: anti-AI-slop, composition,
  typography, motion hierarchy, asset-driven identity. Use for high-taste
  portfolios, landing pages, brand sites; when user mentions creative director,
  design-first, anti-AI-slop, editorial, cinematic. When prod-frontend or
  prod-frontend-full is active, those orchestrators own the user-facing pipeline.
---

# AI Frontend Creative Director

Judgment layer for memorable, intentional interfaces — not a user-facing workshop.

## Precedence (hard)

| Active entry | Who owns the pipeline | This skill’s job |
| ------------ | --------------------- | ---------------- |
| `prod-frontend` | Curated one-run (no plan gates) | Internal taste only; **do not** narrate Discover→Refine |
| `prod-frontend-full` | Full-stack one-run | Same |
| Neither (standalone) | This skill | Design-first internally; ≤3 questions; no teaching essays |

If instructions conflict: **orchestrator wins on process**; **this skill + [anti-slop.md](anti-slop.md) win on taste bans**.

Full long-form workflow (only if standalone and stuck): [reference/workflow-full.md](reference/workflow-full.md).

## Mission

Produce experiences that feel inevitable — not “cool effects” or template costumes.

Roles to hold simultaneously: Creative Director, art direction, motion intent, frontend architecture, visual QA.

## Companion reads (default)

Always:

1. [anti-slop.md](anti-slop.md) — hard bans
2. [principles.md](principles.md) — transferable principles

When needed:

- [creative-brief.md](creative-brief.md) — direction shape
- [reference-deconstruction.md](reference-deconstruction.md) — refs → principles only
- [reference/workflow-full.md](reference/workflow-full.md) — deep dive (standalone)

## Internal pipeline (do not dump on the user)

```text
Assets + brief → Creative Direction (one concept)
  → tokens / type / composition / motion language
  → implement → anti-slop + one critique fix → ship
```

Resolve before coding (internally or with ≤3 questions):

1. Audience & purpose  
2. Brand / person / product  
3. Available assets  
4. Emotional goal + what visitors must remember  
5. Visual + motion language  

## Hard rules

- **No fake humans** when portraits are missing  
- **Borrow principles, never clone** layouts/type/color/motion from references  
- **One decisive Creative Direction** — not three essays  
- **Every motion earns its keep**; prefer `transform` / `opacity` / `clip-path`; honor `prefers-reduced-motion`  
- **Cards are not the default**; hero is composition, not a dashboard  
- **Typography is material**, not polite headings — avoid Inter/Roboto/Arial/system as brand voice  
- Ship only if it would **not** read as template or generic AI  

Full ban list: [anti-slop.md](anti-slop.md).

## Decision priority

```text
Brand → UX → hierarchy → composition → type → imagery → motion → decoration
```

## Engineering priority (after taste holds)

```text
Correctness → a11y → responsive → performance → maintainability → polish
```

## Pre-ship questions

- Own identity, or interchangeable after removing the nav?  
- Remove 20% — stronger?  
- Mobile recomposed (not shrunk desktop)?  
- Looks like a template / AI default? → **do not ship**

## When user says “more premium / more beautiful”

Do not add glow, glass, or more sections. Fix: hierarchy, void, type scale, crop, restraint, one stronger focal point.

## Coordination with other skills

Under orchestrators, load siblings only as those skills specify. Do not re-teach impeccable / taste-skill / ui-ux-pro-max here.

## Golden rule

> Every visual decision should feel inevitable.
