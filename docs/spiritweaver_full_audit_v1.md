# Spirit Weaver V1 full audit

## Requirement assessment

| Area | Result | Evidence |
| --- | --- | --- |
| Stack/base/clean branch | PASS | Branch created from exact completed Vitalist head `ce922e5b8e515f3d263bc5b3fc61a9485d65d58e`; original dirty workspace untouched. |
| Source search/reconciliation | PASS | Local normalized `2.55.17.97771` hero/unit/game strings plus Blizzard 2022 and 2024 notes recorded in the conversion document. |
| Chassis/scaling/no Mana | PASS | Centralized 1900/3.957/110/0.9/1.5 chassis; representative Level 1/15/30 automated scaling checks. |
| Contextual Basic Action | PASS | Shared attack/heal assignment, movement, one cadence/recovery clock, 60 heal, 50% lowest-percentage bounce, ownership/threat hooks. |
| Automatic Ghost Wolf | PASS | Three-second personal-inactivity timer, movement multiplier, safe lunge, 60% bonus, action exit/reset, incoming-effect independence, controlled entry, HUD/F3. |
| Q / relay architecture | PASS | Per-cast ID, unique Hero recipients, normal bounce budget, Totem and Spirit free relays, anti-loop histories, Wellspring untalented mode. |
| W / source ownership | PASS | Per-owner/per-instance state, live bearer lookup, all in-radius contacts, Rising/Stormcaller/Electric/Earth Shield/G30 interactions, clean bearer death. |
| E deployable | PASS | One targetable/destroyable temporary unit, Health/lifetime/position, safe placement, replacement, one Colossal reposition, W attachment, initial-only Earthgrasp. |
| Purge | PASS | Dual targeting, cleanse then Unstoppable, metadata-limited positive dispel, decaying profile-aware Slow, Purification, 1.5x recharge, self-Stun exception, Basic-Attack retaliation. |
| Heroics | PASS | Delayed Ancestral/Farseer scheduling and generic Bloodlust movement/cadence/primary-attack-healing paths with summon exclusion. |
| All 22 talents/G30 | PASS | Central tier data, matching Heroic upgrades, four cross-talent builds, system and live integration coverage. |
| Control/interruption | PASS | Stun/Silence/Fear locks; only G30 self-Purge bypasses Stun; Root preserves in-range casting; defeat uses shared cleanup. |
| Target categories/Bosses | PASS | Immediate PvE categories supported, progression trash excluded, shared Boss Slow profiles retained. |
| PC/touch/input/UI | PASS | Ally/enemy drag assignment, normal Q/W/E/R targeting, PC/mobile D confirm, no extra buttons, D Wolf sub-indicator, presenter, normal visuals, F3. |
| AI compatibility | PASS | Class definition exposes Healer/support/melee/deployable tags and shared assignment/runtime APIs; no Shaman-specific runtime reuse. |
| Save/Testing Range | PASS | Testing-only Kael Runebraid fixture, migration to 28 heroes, dedicated range with party/category/Boss/training/blocker fixtures and four resettable builds. |
| Ownership/reset | PASS | Runtime is initialized per encounter; multi-caster system test confirms isolated W/Totem state. |
| Regression roster | PASS | Complete automated suite covers every registered class and all existing UI/system suites. |
| Geometry | DEVIATION | Gameplay values are centralized, but the stack's `185 / 5.5` pixel scalar and portable engine search order remain project calibration rather than canonical Blizzard geometry. |
| Final art/audio/manual feel | DEVIATION | Functional project shapes/text are implemented; no final identity art/audio was requested, and no human interactive playtest is claimed. |
| External blockers | PASS | None. |

## Automated coverage

`test_spiritweaver_system.gd` covers class schema, 22 talents/eight tiers/four builds, Heroic gates, Level 1/15/30 scaling, exact Wolf transition and Feral speeds, W duration/damage stacks, Stormcaller cap/current-Health rule/trash exclusion, Colossal/Healing/Grounded/Wellspring composition, W-on-Totem exclusion, Purge recharge math, metadata-limited dispel/cleanse behavior (including uncleansable and scripted controls), and multi-caster ownership.

`test_ui_spiritweaver_runtime.gd` runs a four-Hero live Range and covers Basic Heal bounce, Q distinct recipients, W damage plus Stormcaller/Earth Shield, blocked-ground rejection, E placement/reposition/W bearer, ally Purge/Purification, self-Purge while Stunned, mobile dual-target enemy Purge and decay metadata, Stun versus Root action locks, both Heroics, automatic Wolf, and the raw-damage/one-Armor-pass Wolf bonus attack, plus Range fixtures.

The unchanged full suite exercises shared Basic Action phases, healing threat and ownership, Shields/Armor/control/Unstoppable, summon behavior, all established class runtimes, save migration, campaign and storage UI, startup, and export behavior. The final handoff requires two consecutive `tools/validate.ps1` runs with no intervening tree changes; each run includes dependency priming, Godot 4.7 editor parsing, texture-quality checks, every automated GDScript test, source startup, Windows pack export, exported startup, runtime-log scan, UTF-8 hygiene, and `git diff --check`.

## Balance and manual risks

Approved high-output risks remain intentionally unnerfed: repeatable Basic Heal plus bounce, +400 encounter maximum Health per eligible bearer, fast Rising Storm stacks in packs, self Electric Charge, 40% Earth Shield, Healing Totem plus Wellspring, dual relay Q, 40-second effective G30 Purge recharge, and Rising Storm's five-second-rate Wolf burst. The principal support risk is breadth rather than a single throughput mechanic. The principal overlap risk with Shaman is visual vocabulary; mechanically, Shaman retains its charge-based Chain Lightning/spirit identity while Spirit Weaver owns contextual Basic Actions, W bearers, E networking, and Purge. Druid/Vitalist remain HoT/infection timing specialists.

Manual follow-up should focus on feel/readability rather than missing logic: attack/heal reassignment cadence, Ghost Wolf timing and lunge, relay lines, W-on-Totem/Colossal controls, Healing Totem readiness, dual-target and self-Purge on mouse/touch, Heroic timing, and party-wide Bloodlust feedback.
