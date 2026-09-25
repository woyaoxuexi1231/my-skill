---
name: prod-frontend-full
description: >-
  Full-stack production frontend — one continuous run using all installed
  project skills under .cursor/skills (brand, design systems, redesign,
  image-to-code, soft/brutalist/minimalist, etc.). User provides requirements
  plus assets; no plan-approval gates. Use for 全量技能栈, prod-frontend-full,
  全部 skill 一步做完, when curated prod-frontend is not enough.
---

# Prod Frontend Full（全量栈 · 一步跑完）

**模式 2 / 全量生产栈。**  
给需求 + 素材 → **一路做完**。可调用本项目 `.cursor/skills` 下**已安装的全部** skill。

精选、更轻量 → 用 **`prod-frontend`**。

## Precedence

1. **This skill** owns the one-run process.  
2. **CD + anti-slop** remain the taste veto (if present).  
3. Style packs (`soft-skill`, `brutalist-skill`, `minimalist-skill`, …) apply only when the brief matches — don’t stack conflicting aesthetics.  
4. No workshop narration; no plan-approval waits.

## Stack

Assume **all** skill folders shipped with the `all` pack (or already in `.cursor/skills`) are available. Prioritize:

| Need | Prefer |
| ---- | ------ |
| Taste / anti-slop | `frontend-creative-director`, `taste-skill`, `visual-critique` |
| Craft commands | `impeccable` |
| DS / UI intel | `ui-ux-pro-max`, `design-system`, `ui-styling` |
| Brand | `brand`, `brandkit` |
| Directional looks | `soft-skill` / `brutalist-skill` / `minimalist-skill` / `apple-design` — pick **one** primary |
| Redesign / image | `redesign-skill`, `image-to-code-skill` |
| Motion | `find-animation-opportunities`, `improve-animations`, `review-animations`, `react-bits-guide` |
| Exhaustive output | `output-skill` when generating large complete files |

Do **not** load every skill into context at once. Pick 3–6 that match the brief; keep CD anti-slop as constant.

## One-run pipeline（不要停下来等确认）

```text
1 INGEST requirements + assets
2 If critical assets missing → ask ONCE → then continue
3 Pick matching skills from the full set (silent)
4 Internal direction + implement
5 Anti-slop + critique + hard-checks + build
6 One fix pass
7 Deliver — STOP
```

Same rule as curated: **no** multi-step user confirmation. Max **one** clarifying message (≤3 questions).

## Defaults

Same as `prod-frontend` (React+Vite+CSS variables if greenfield; no fake humans; earned motion only).

## Deliver report

1. How to run  
2. What shipped  
3. Which extra skills were actually used  
4. Asset map / assumptions  
5. Hard-check residuals  

## Templates

- [BRIEF.template.md](BRIEF.template.md)
- [hard-checks.md](hard-checks.md)
