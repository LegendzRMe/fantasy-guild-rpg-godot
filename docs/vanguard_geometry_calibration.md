# Vanguard geometry calibration

Lifecycle: **calibration note**.

Vanguard uses the shared ratio of 185 world pixels per 5.5 source units. Direct source chassis values are radius 0.9375 and Basic Attack range 1.5. Centralized ability-space choices are Powerslide range 8.5 / half-width 1.25 / travel speed 14, Face Melt radius 4 / displacement 2.5, Overpower range 2 / behind offset 1.25, support and Mosh radius 4, Lightning Breath range 7.5 / 35-degree half-angle, and Echo Pedal radius 4.

HeroesToolChest build `2.55.17.97771` exposes current values and localized mechanics but not one authoritative scalar for every effect polygon or displacement speed. Non-chassis geometry is therefore an explicit source-calibrated V1 estimate isolated in `VanguardData.SPACE`. Loud Speakers multiplies W radius and displacement by 1.5. Collision tests add each target's combat radius rather than baking it into spell dimensions. Crowd Surfer ignores crossed blockers but samples backward from the requested endpoint until the final circle is valid. Wall of Sound collision compares the intended target-circle endpoint with the shared safe endpoint.

Manual calibration priorities are Q blocker-edge travel, W outward/inward feel at different target radii, Overpower behind-offset safety, Mosh readability while Tour Bus moves its center, Lightning Breath mouse/touch turning, and dense cone readability over 12-second Hellstorm.
