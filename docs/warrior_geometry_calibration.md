# Warrior geometry calibration

Lifecycle: **calibration note**.

Warrior uses the shared ratio of 185 world pixels per 5.5 source units. Centralized source-space values are: Basic Attack 1.25, Lion's Fang range 12 / half-width 1.25 / speed 18, Charge 4, Colossus Smash 5, Master at Arms radius 2, Taunt 2, banner 10.5, Shattering Throw 8, and Victory Rush death radius 12.

The chassis and attack range/period are directly verified from Heroes Tool Chest build `2.55.17.97771`; its normalized Varian object is identical to `2.55.17.97650`. Q travel geometry and several talent radii were cross-checked against current community-extracted records because public hero JSON does not provide one canonical scalar for every effect. All values live in `WarriorData.SPACE`; visual playtesting should adjust only those constants.

Safe landing searches twelve deterministic positions around the target and rejects blockers through shared combat geometry. Warrior Range includes a permanent movement blocker specifically to verify Charge and Colossus Smash never land inside geometry.
