# Vanguard full audit v1

This is the verification companion to `vanguard_conversion_v1.md`.

## Coverage matrix

- Baseline: current chassis, no resource, 1.5 Threat, Q/W/E damage and cooldowns, safe slide/knockback/flip, control immunity, Rockstar commit semantics, and ability presentation.
- Every talent: all 22 choices across eight tiers have deterministic assertions or live runtime coverage. Cross-tier combinations exercise Wall + Show Stopper, Tour Bus + all Q hooks, Loud Speakers + Dissonance, Echo + Block/party Rockstar, and Overpower charges/lockout.
- Quest/state: Prog Rock encounter scope, qualifying target categories, shared progress multiplier cap, completing-Stun reward, independent overlapping healing areas, no self/summon healing, and combat-ID-owned Pinball/Encore/control effects.
- Heroics: both windups/cooldowns, Mosh interruption and repeated control, boss immunity, Tour Bus Q exception/extension, Lightning cadence/Slow/Unstoppable, five-contact cap, Vanguard-only rotation, party command isolation, Hellstorm duration, and non-cancellation.
- Capstones: post-control forced targeting without Silence, strongest-active party Armor, and Death Metal's unselected baseline Heroic, independent ICD, post-mitigation one-Health floor, normal healing, current-Health check, direct defeat, and recursion prevention.
- Shared regressions: full established-class suite, shared status extension, generic Block consumption, Armor, target categories, safe placement, forced target, item damage/healing, save migration, class registry, roster copy, Testing Range, F3 data, startup, export, and runtime-log scan.

## Interaction audit findings

The audit corrected three ordering hazards before final validation. Death Metal now lets the normal mitigated packet resolve and applies the lethal floor afterward, avoiding pre-Armor damage truncation. Show Stopper schedules from the final Q-owned duration after Wall of Sound's additional sequence and still attempts Root when Stun alone is immune. Mosh creates Encore Performance marks only when its maintained Stun ends, so a large simulation frame cannot Taunt during the channel.

Other intentional outcomes are retained: Pinball is four times baseline W total because “300% more” is additive; Encore's 4% uses selected Heroic maximum cooldown; Amp repeats displacement and cross-tier Dissonance but no damage; weaker Rockstar refreshes use the project's strongest-active source behavior; and Death Metal never receives Tour Bus, Hellstorm, Rockstar, Block Party, Echo, or selected-R cooldown effects.

## Risk review

Pack scaling is intentionally strong: each completed Prog Rock Stun creates its own four-tick area, Mosh/Lightning affect up to five targets, Encore original and Amp each reduce R independently, and Hellstorm can reach 80% raw Slow. Level-1 Armor scaling can reach the shared Armor cap at high level. These were not silently nerfed.

The release gate is two consecutive clean full validation passes covering dependency priming, editor parsing, texture verification, all deterministic and live UI tests, project startup, Windows export-pack creation/startup, runtime-log scanning, UTF-8 hygiene, and whitespace checks. No manual desktop/device pass is claimed; the remaining human checks are geometry feel, mobile rotation, dense effect readability, and longer survival sessions.
