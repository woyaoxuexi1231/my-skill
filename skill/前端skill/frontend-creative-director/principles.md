# Transferable Design Principles

Borrow principles. Never clone a reference site’s exact layout, type, color, imagery, or animation.

## Core principles (from high-taste references like Nothin’-class work)

1. **Concept over content** — philosophy drives every visual choice
2. **Extreme restraint** — show ~70%; omission is identity
3. **Text as sculpture** — typography equals photography as material
4. **Negative space as asset** — emptiness carries weight
5. **Asymmetric tension** — break the grid on purpose
6. **Slow luxury** — motion is deliberate, heavy, not snappy
7. **De-UI-fication** — hide template chrome; build a world
8. **Theatrical sequencing** — reveal in acts (curtain → name → image → detail)
9. **Material over decoration** — paper/film/grade over glossy CSS tricks
10. **Singular focus** — one focal point per viewport
11. **Editorial metadata** — small uppercase tracked labels set magazine rhythm
12. **Non-sales language** — gallery brochure tone, not growth-landing tone

## Composition

- Asymmetric editorial grids; intentional overshoot/bleed/crop
- Side margins often around `4vw` on desktop (adapt per project)
- Large vertical rhythm between sections
- Overlap type and image only when conceptually earned
- Mobile: recompose (“vertical slice”), do not shrink desktop

## Typography

- High contrast pairing: display (editorial) + UI (neutral grotesque)
- Extreme scale contrast (sculptural display vs tiny metadata)
- Tracking on small caps/labels (`~0.2–0.28em` often)
- Visual cropping of display type allowed; accessible text remains complete

## Color

- Restrained palette; composition and type carry identity
- Accents used sparingly (micro-interactions, links), never large fills by default
- Prefer cinematic/gallery grades over pure digital black/white when fitting

## Motion language

- Custom cinematic curves, e.g. `cubic-bezier(0.22, 1, 0.36, 1)`
- Animate only `transform` / `opacity` / `clip-path` when possible
- Entry as sequence with hierarchy, not simultaneous UI fades
- Honor `prefers-reduced-motion` with intentional static final state

## Image language

- Photography/video is primary material
- Off-center subjects, intentional negative space
- No rounded corners / white polaroid frames by default
- Aspect systems: portrait hero (3:4 / 4:5), cinematic works (16:9 / 2.35:1)
- Coherent asset world > random mixed wallpapers

## Interaction

- Quiet nav (colophon energy), not SaaS header
- Hover: color shift / soft scale-in-mask / caption reveal — not gimmicks
- Default cursor unless brief demands otherwise

## Narrative IA (editorial default)

1. Entrance / Hero  
2. Manifesto (short)  
3. Selected Works (image-led chapters)  
4. Practice (minimal list)  
5. Archive / Interlude (optional)  
6. Contact / Colophon  

Cut sections the brief doesn’t need — don’t pad.
