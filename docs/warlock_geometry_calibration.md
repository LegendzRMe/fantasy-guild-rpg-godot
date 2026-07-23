# Warlock Geometry Calibration

All uncertain spatial values are centralized in `WarlockData.SPACE`.

| Mechanic | Current model | Confidence | Manual check |
|---|---|---:|---|
| Fel Flame | Moving expanding wedge | Medium | Width at origin/end, travel duration, blockers |
| Drain Life | Targeted cast range plus larger break range | High behavior / medium distance | Edge-of-range start and forced range break |
| Corruption | Three forward circles with delayed centers; optional reverse sequence | Medium | Center spacing, delay, reverse cadence |
| Horrify | Clamped ground circle with 0.5-second warning | High behavior / medium radius | Wall edges, Boss profile, movement origin |
| Rain | Seeded arena positions with warning then impact | Medium | Meteor count, cadence, miss rate, impact radius |

Official Blizzard material confirms ability values and major timings but does not publish every world-space measurement. Provisional geometry is therefore configuration, not hidden fact. Use **Testing → Enter Warlock Range** for walls, multiple targets, a Defense Dummy, and a Fear-immune Boss. F3 retains the shared combat overlay.
