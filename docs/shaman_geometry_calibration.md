# Shaman Geometry Calibration

All Shaman source distances are converted in `shaman_data.gd` through one `SOURCE_TO_WORLD` scale. Runtime code consumes the resulting world-space constants and does not embed independent range numbers.

The Shaman Range is the calibration scene:

- Chain Lightning uses a deterministic nearest-target bounce radius.
- Feral Spirit advances as a swept segment each frame, tests target combat radii, extends remaining travel after contact, and stops at authored battle bounds.
- Sundering uses a swept corridor for hits and a temporary movement blocker for Worldbreaker.
- Earthquake uses a fixed circular pulse radius.

Recalibrate by changing the conversion scale or the named geometry constants, then verify at both 30 and 60 FPS. Do not tune the presentation effect dimensions as a substitute for combat geometry.
