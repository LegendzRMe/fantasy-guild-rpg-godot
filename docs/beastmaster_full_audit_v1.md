# Beastmaster V1 full audit

Lifecycle: **implementation audit and acceptance record**.

## Coverage matrix

| Area | Audited intent | Automated evidence |
| --- | --- | --- |
| Chassis and commands | Rexxar and permanent Misha identities, target selection, focus/retreat, death lockout, 15-second respawn, cooldown preservation | deterministic and live Range tests |
| Spirit Swoop | line contacts, Slow, independent charges, blocker-safe endpoint, Lesser Beast creation, Army of Hell doubling/recharge | deterministic and live cast tests |
| Misha, Charge! | living-Misha requirement, line contacts, Stun, primary-target ordering, Dire Beast consumption, Pack Commander ordering | deterministic and live interaction tests |
| Greater Beast | living-Misha requirement, safe spawn, health decay, attacks, rally and Chain of Command | deterministic and live summon tests |
| Fury and Hunted | four valid primary sources, 225 cap, encounter scope, exclusions, independent one-use Hunted strikes | deterministic source/cap/scope tests |
| Defensive talents | independent Block, Fresh ordering, Unhindered control profile, Primal source refresh and Boss profile, Protective Bond split/recursion rules | deterministic and live resolver tests |
| Heroics | Bestial Wrath/Spirit Bond duration and healing recipients; Boars line, five-target cap, Reveal/Slow/Root and upgrade damage | deterministic and live Heroic tests |
| Capstones | Apex living-combat growth and same-target ramp, Pack Commander arrival attacks, per-beast Wildfire overlap without Fury | deterministic and live capstone tests |
| Shared controls | Stun/Fear/Root/Slow/Blind/attack-speed behavior and timed expiry on Misha, Lesser, and Greater entities | live autonomous-AI tests plus shared control suites |
| Cross-class combat | all 17 registered classes can damage targetable disposable beasts, heal Misha, and cannot ordinarily heal disposable beasts | class-by-class live resolver matrix and full regression suite |
| Summon interoperability | combat IDs, threat targeting, healing eligibility, health decay versus hard lifetime, Warrior anti-summon and Death Knight Ghoul preservation | shared-system, Warrior, Death Knight, and live registry tests |
| Persistence and UI | class discovery, testing fixture, action locks, Q charges, Misha targeting/drag preview, telemetry and save compatibility | save, UI smoke, parser, startup, and export validation |

## Interaction findings resolved

1. Autonomous Beast AI now consumes shared Stun, Fear, Root, Slow, Blind, and attack-speed suppression instead of merely storing those effects.
2. Misha and disposable beasts now advance the same timed combat-effect lifecycle as heroes and enemies, so controls, Shields, reductions, and other timed effects expire normally.
3. Blind consumes an autonomous Beast's attack cadence but produces no damage, Fury, Hunted, Aspect, Spirit Bond, or telemetry hit proc.
4. Attack-speed suppression lengthens the next autonomous attack interval; Slow affects pursuit, follow, leash return, and Misha retreat movement.
5. Cleric and Druid manual ally selection now recognizes living Misha through both click-aim and drag targeting. Disposable beasts remain excluded from ordinary healing.
6. Misha's defeat locks Charge, Greater Beast, Bestial Wrath, and commands while leaving Spirit Swoop and Unleash the Boars independent of her state.
7. Primal Intimidation triggers on hostile Basic Attack contact with Rexxar, Misha, Lesser, or Greater before Fresh/Block prevention, uses Boss control profiles, and refreshes one owner-keyed suppression rather than stacking it.
8. Protective Bond preserves the original raw packet, selects by pre-hit Health percentage, and resolves each half independently through Armor, Block, Shield, prevention, and defeat handling. Self and redirected damage cannot recurse.
9. Pack Commander gives each living disposable Beast exactly one immediate arrival Basic Attack and retains deterministic target priority afterward.
10. Wildfire is one aura per living disposable Beast: distinct sources overlap exactly once per tick, retain owner attribution, and never progress Fury.
11. Beastmaster audit tests are dependency-primed directly so parser failures fail fast instead of surfacing later as a missing test entry point.

## Acceptance status

Acceptance requires clean dependency loading, full editor parsing, imported-texture quality checks, every deterministic and live UI regression test, startup smoke, Windows export-pack creation, exported-pack startup, a clean runtime log, UTF-8 hygiene, and Git whitespace hygiene. Release evidence is recorded after two consecutive complete `tools/validate.ps1` passes with no intervening edits.

Remaining V1 risk is presentation and world-space calibration under unusually large packs. The audited mechanics, state ownership, target categories, interaction ordering, and cross-class resolver contracts have no known unresolved defect.
