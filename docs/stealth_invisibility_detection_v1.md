# Stealth, Invisibility, and Detection V1

`stealth_detection_system.gd` keeps Stealthed, Invisible, Revealed, and Unrevealable separate. Stealthed and Invisible block ordinary direct acquisition. Revealed temporarily permits it. Unrevealable always blocks direct acquisition, including detector and Boss profiles, but never prevents area damage or collision.

Detection profiles are authored data: `detect_stealthed`, `detect_invisible`, `detection_radius`, `reveal_duration`, `acquisition_chance`, and `acquisition_interval`. V1 has no random per-frame acquisition roll. Smoke Bomb is a source-scoped Invisible/Unrevealable benefit that turns on when its Rogue is inside and turns off on exit.

Vanish's first second is Unrevealable. Remaining stationary for 1.5 seconds grants Invisible; movement returns it to Stealthed without ending Vanish. Offensive openers end Vanish. Smoke Bomb and Cloak do not. Direct enemy assignments invalidate through the shared target-validation contract while accumulated threat remains available for later reacquisition.
