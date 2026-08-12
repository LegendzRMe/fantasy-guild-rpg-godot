# Druid V1 full-system audit

Audit date: 2026-08-12

This audit traced every Druid action and talent from data/presentation through targeting, runtime resolution, the shared damage/healing/control/cooldown pipelines, combat telemetry, Testing Range controls, save registration, automated startup, and Windows export packaging. Current-source anchors were rechecked against Heroes Tool Chest live data release `v2.55.17.97650` and Blizzard's current Malfurion hero page.

## Correctness fixes made during the audit

- Innervate is now reachable through ordinary D input, and Druid world dragging can designate a living non-self ally.
- Innervate now accelerates internal Q/W/E cooldown representations used by Huntsman, Sentinel, Shaman, Protector, Ranger, Slayer, and Cleric Twin Incantation—not only the generic `ability_cds` array. Heroic charge timers remain unaffected.
- Astral Communion now uses the shared one-second interruptible Heroic cast state. Movement or true control interrupts it with the standard interrupted-Heroic cooldown; teleport, free Moonfire, and Twilight resolution occur only after completion.
- Large-frame periodic updates are bounded by effect lifetime, so an update longer than a HoT cannot manufacture post-expiration ticks. Tranquility also catches up every scheduled tick across a large update.
- Nature's Swiftness transfers the exact already-resolved Regrowth overheal without applying outgoing-healing or critical modifiers a second time.
- Rejuvenation no longer replaces a longer direct self-Regrowth with its generated half-duration version.
- Nature's Communion now includes the live Ysera Regrowth source multiplier exactly once before refreshing the HoT.
- Nature's Cure runtime order is validation, cleanse, Lifebloom missing-Health snapshot heal, Regrowth application/refresh, Rejuvenation generation, then cooldown.
- Moonfire creates its Druid-owned reveal marker only when the shared reveal system succeeds; unrevealable targets still take damage but cannot incorrectly enable Celestial Alignment.
- Deep Roots preserves the baseline initial radius and applies its 25% increase to maximum size only. Emerald Dreams is capped at five successful unique primary roots per cast.
- Shan'do's Clarity, Moonlit Harmony, and Serenity count living allies with the casting Druid's active Regrowth rather than stale effects on defeated allies.
- The F3 Druid panel now reports the live ally-aware recharge multiplier and wraps compact nonzero telemetry instead of overflowing the screen.

## Regression coverage added

- Large-delta periodic expiration and exact tick count.
- Direct self-Regrowth versus generated Rejuvenation duration precedence.
- Deep Roots initial/maximum geometry and Emerald Dreams' five-target cap.
- Living-only Regrowth counts, Ysera plus Nature's Communion, and Lunar Shower stack/expiry order.
- Actual D input, ally-drag recognition, exact Nature's Swiftness transfer, unrevealable Moonfire, Astral interrupt/completion/free-W behavior, and Twin Incantation under Innervate.
- Innervate recovery hooks for Huntsman form cooldowns, Sentinel Q/W charges, Shaman Q, Protector E, Ranger E without R, Slayer W, and Cleric Q charges.

## Validation gates

The project validator covers dependency priming, editor parsing, imported texture quality, the complete deterministic and UI suites, ordinary startup, Windows export-pack creation, exported-pack startup, runtime-log scanning, UTF-8 hygiene, and `git diff --check`. The live Windows pass additionally launched the Testing save's Druid Range, loaded a Level 30 build, displayed F3 state, staged Regrowth, observed Shan'do recharge scaling, and completed Astral Communion with its free Moonfire/Twilight sequence.

## Remaining risks

- Treants have source ownership, Health, timed decay/removal, deterministic movement, acquisition, attacks, damage, and telemetry, but remain lightweight summons outside the main hero/enemy target-selection and threat entity graph. Making enemies target and collide with them as full combatants is an engine-level summon-entity follow-up rather than a Druid formula defect.
- Geometry values remain centralized and deterministic, but final feel for growing Roots, Treant acquisition, and Heroic areas still benefits from playtesting at additional resolutions and party layouts.

## Source references

- [Heroes Tool Chest live data release 2.55.17.97650](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97650)
- [Blizzard Malfurion hero page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-us/heroes/malfurion/)
