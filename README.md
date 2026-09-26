# K2 Big Roboport - Vanilla Size

A small quality-of-life mod for [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
(and Krastorio 2 Spaced Out): the big roboport keeps its stats but no longer
needs an 8x8 plot. It is resized to the vanilla roboport footprint.

## What changes

| Property | Krastorio 2 | With this mod |
|---|---|---|
| Selection box | 8x8 | 4x4 (vanilla roboport) |
| Collision box | 7.5x7.5 | 3.4x3.4 (vanilla roboport) |
| Graphics | 8x8-sized | scaled to 4x4 |
| Charging pads | 20, ring at r~3.4 | 20, ring at r~1.7 |
| Death remnant | big K2 pipes remnant | vanilla roboport remnant |

Everything else is untouched: logistics/construction radius (100/200),
charging energy (100MW), robot/material slots, health, resistances, recipe,
technology. The `-logistic-mode` and `-construction-mode` variants K2 creates
for every roboport are resized as well.

The small K2 roboport (2x2) is already smaller than vanilla and is left alone.

Without Krastorio 2 installed, this mod does nothing.

## Why the remnant swap

K2's big roboport uses `kr-big-random-pipes-remnants` as its corpse, which is
sized for ~6.5x6.5 buildings and shared with many other K2 machines (crusher,
greenhouse, warehouses, ...), so it cannot be scaled without affecting them.
The vanilla `roboport-remnants` is built for exactly the footprint this mod
gives the big roboport, so it is used instead.

## Installation

`make install` packages the mod and copies the zip into your Factorio mods
directory, or copy `releases/kr-big-roboport-vanilla-size_*.zip` there manually.

## Testing

```
make test-e2e        # base game only (mod must be a no-op)
make test-e2e-k2     # Krastorio 2
make test-e2e-k2so   # Krastorio 2 + Space Age + Krastorio 2 Spaced Out
make test-e2e-all
```

The tests run a headless Factorio server with an e2e harness mod that verifies,
both at data stage and at runtime: box equality with the vanilla roboport,
sprite scaling, charging pad bounds, remnant swap, and that two big roboports
place side by side at 4-tile spacing.

## Notes

- Existing saves: shrinking a collision box is save-safe; placed roboports
  simply occupy less space afterwards. No migration needed.
- The recharging glow animation is deliberately left at the vanilla size
  (same sprite and scale the vanilla roboport uses for its pads).
