# Rogue Geometry Calibration

Source-space geometry is centralized in `RogueData.SPACE`. V1 uses the project's established `185 / 5.5` source-to-world ratio where relevant, then applies collision-friendly values for a compact 1,280 by 720 arena.

Provisional values: Basic Attack range 1.2 source units; Sinister Strike range 4.0, width 0.8, and speed 900 world units per second; Blade Flurry radius 2.25; opener range 1.5; Smoke Bomb radius 2.75; Assassinate isolation radius 180 world units. Mutilate removes one source range from Sinister Strike.

These values are centralized because public Blizzard pages do not expose complete live geometry. They require visual calibration in the Rogue Range and should not be copied into runtime code.
