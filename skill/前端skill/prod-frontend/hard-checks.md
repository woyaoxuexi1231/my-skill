# Hard checks — before deliver

Run once after the visual fix pass. Fail = fix or list as residual risk in the delivery report.

## Build

- [ ] Project install/build command succeeds (`npm run build` or repo equivalent)
- [ ] No obvious console/runtime blocker on the primary route

## Responsive

- [ ] Mobile is **recomposed**, not a shrunk desktop
- [ ] First viewport readable without horizontal scroll at ~375px
- [ ] Tap targets usable; critical CTA reachable

## Accessibility (floor)

- [ ] Semantic landmarks / headings in order
- [ ] Images that convey meaning have `alt` (decorative = empty alt)
- [ ] Text contrast usable on real backgrounds (not gray-on-gray)
- [ ] Focus visible on interactive controls
- [ ] `prefers-reduced-motion` respected for non-essential motion

## Performance (floor)

- [ ] Hero media not absurdly oversized without compression/srcset when easy
- [ ] No autoplaying muted video stacks that crush LCP without need
- [ ] Motion limited to transform/opacity/clip-path where practical

## Taste (must also clear anti-slop)

- [ ] Brand/product still identifiable if nav removed (branded surfaces)
- [ ] One job per section; hero not a dashboard
- [ ] No fake humans; asset worlds coherent
- [ ] Does **not** read as generic AI template

## Abort / residual

If a check cannot pass without new assets or product decisions: **do not silently invent**. Note it under Assumptions / residual risks and stop after one fix pass.
