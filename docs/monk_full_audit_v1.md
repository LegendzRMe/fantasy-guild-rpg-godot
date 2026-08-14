# Monk V1 full audit

Lifecycle: **implementation audit and acceptance record**.

## Coverage matrix

| Area | Audited intent | Automated evidence |
| --- | --- | --- |
| Chassis and slots | Support role, no resource, exact baseline, Q active, W/E passive, D gated | class/default, presenter, pure, and live tests |
| Dash anchors/order | Heroes, Misha, own Ally, enemies; self/disposable rejection; safe landing; Reach/Breath order | pure predicates and live candidate/cast tests |
| Trait engine | success gating, modulo-three state, speed, healing/damage, encounter Insight, post-completion CDR | deterministic proc and cooldown tests |
| Allies | all Health values, ten-second duration, 45-second cooldown, registry/targetability, Spirit/Earth/Air auras | pure construction and live aura tests |
| Defensive interactions | Stun/Root-only cleanse, Protected without control immunity, universal Armor, Shields | live shared status, Armor, and Shield pipelines |
| Offensive interactions | Reach speed/range, Controlled Assault, Hundred Fists qualifying attacks, raw-versus-resolved Iron damage | pure and live resolver tests |
| Heroics | Palm lethal interception/expiry and self/major-companion eligibility; SSS targeting, timing, Invulnerability, Boss override | pure state plus live lethal/strike tests |
| Capstones | Fists half-effects, Storm primary-only/ICD, Epiphany current-max refill/ICD | deterministic and live cooldown tests |
| Cross-class/runtime | ordinary attacks, healing eligibility, target registry, target categories, existing class regressions | full automated suite and startup/export validation |
| Persistence/UI | testing-only fixture, legacy-save migration, talent/ability presentation, Range controls, F3 telemetry, visuals | save/UI smoke and parser tests |

## Findings resolved during audit

1. Dash self-targeting was removed while Palm self-targeting was retained; they use separate eligibility contracts.
2. Palm now intercepts a lethal shared damage result before defeat hooks, clears defeat/overkill, and restores Health without recursively issuing damage.
3. Ordinary Monk Basic Attacks were connected to the same Trait resolver used by Dash and Hundred Fists. Generated packets are explicitly tagged to prevent double counting.
4. Iron Fists now derives its bonus from pre-mitigation raw Basic Attack amount, avoiding a second Armor application to a value that had already been mitigated.
5. The Insight quest-completing hit no longer receives retroactive cooldown reduction; only subsequent third hits do.
6. Fists of Legend grants immediate half Insight cooldown reduction only when Insight is unchosen. Selected Insight keeps its encounter quest requirement.
7. Controlled Assault excludes percentage-health packets in accordance with the shared percentage-health contract, while applying to normal Monk damage during active Reach.
8. Selected Allies were added to combat-ID lookup, player summon targeting, timed effects, destructible Health, owner-only Dash anchors, and combat rendering without becoming ordinary healing recipients.
9. Echo snapshots recipients and amounts at primary Breath, then resolves one delayed secondary heal without Storm Shield, Breath Armor, speed, cleanse, or recursive Echo.
10. The clean-cache dependency checker now primes the complete application inheritance chain, preventing a newly inserted runtime layer from hiding parser errors behind unresolved-parent noise.

## Acceptance status

Acceptance requires two consecutive complete `tools/validate.ps1` passes after the final edit. Each pass covers dependency loading, editor parsing, texture quality, all deterministic and live UI tests, startup, Windows export-pack creation and startup, runtime-log inspection, UTF-8 hygiene, and Git whitespace hygiene.

The remaining V1 risk is visual/world-space calibration. Mechanics, source values, targeting categories, ordering, cooldown ownership, encounter reset, and cross-class resolver behavior have no known unresolved defect after the audit.
