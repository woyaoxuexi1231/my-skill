---
name: prod-frontend
description: >-
  Curated production frontend — one continuous run. User provides requirements
  plus asset paths; agent builds end-to-end with the curated stack (~10 skills:
  creative-director, visual-critique, impeccable, taste-skill, ui-ux-pro-max,
  motion set). No plan-approval gates. Use for 生产级前端, 精选栈, prod-frontend,
  给素材直接做完, one-shot curated build.
---

# Prod Frontend（精选栈 · 一步跑完）

**模式 1 / 精选生产栈。**  
给需求 + 素材 → **一路做完**，不逐步确认计划。

若要启用仓库里全部 skill，改用 **`prod-frontend-full`**。

## Precedence

1. **This skill** owns process (one continuous run).  
2. **CD + anti-slop** own taste bans.  
3. Do not narrate workshop steps from `workflow-full.md`.

## Curated stack（随 curated 包一起带走）

| Role | Skills |
| ---- | ------ |
| Required | `frontend-creative-director` (+ anti-slop, principles), `visual-critique` |
| Craft / taste | `impeccable`, `taste-skill` |
| Design system assist | `ui-ux-pro-max`（有 Python 再用其脚本） |
| Motion | `find-animation-opportunities`, `improve-animations`, `review-animations`, `react-bits-guide`（按需选用，不全开） |

## One-run pipeline（不要停下来等确认）

```text
1 INGEST requirements + assets from the user message
2 If critical assets missing → ask ONCE for paths (or placeholders OK) → then continue
3 Internal analyze + direction (silent)
4 Implement
5 Anti-slop + visual-critique lenses + hard-checks + build
6 One fix pass
7 Deliver short report — STOP
```

**禁止：** 出 Build Plan 后等待用户 OK；素材齐了还分多轮「下一步做什么」。  
**允许：** 关键信息最多 **1 条消息、≤3 个问题**；答完或用户说占位可接受后继续跑完。

## Defaults

- Stack: existing repo, else React + Vite + CSS variables  
- No fake humans  
- No UI kit / Tailwind unless already present  
- Motion only when earned; `prefers-reduced-motion` safe  

## Read order

1. This skill  
2. `frontend-creative-director/SKILL.md` + `anti-slop.md` + `principles.md`  
3. `impeccable` / `taste-skill` as needed while designing  
4. Motion skills only if motion is in scope  
5. End: `visual-critique` lenses + [hard-checks.md](hard-checks.md)

## Deliver report

1. How to run  
2. What shipped  
3. Asset map  
4. Assumptions / missing assets  
5. Hard-check residuals  

## Anti-patterns

- Plan → wait → assets → wait → code  
- Teaching Discover→Refine to the user  
- Loading every animation from react-bits  
- Inventing portraits  

## Templates

- [BRIEF.template.md](BRIEF.template.md)
- [hard-checks.md](hard-checks.md)
