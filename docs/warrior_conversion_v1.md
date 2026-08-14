# Warrior conversion V1

Lifecycle: **current mechanics-first conversion specification**.

Warrior is a Varian-inspired flexible melee class implemented with original project presentation and IDs. It has no Mana and changes effective role through one of three mutually exclusive level-12 specializations: Taunt Tank, Colossus Smash burst DPS, or passive Twin Blades sustained DPS. Warrior is testing-only in V1; it is not added to starter, campaign, recruitment, or permanent-progression content.

## Architecture and resolution order

- `warrior_data.gd` owns the audited chassis, geometry, values, talent tree, descriptions, and six range builds.
- `warrior_system.gd` owns deterministic specialization, charge, Basic Attack, Heroic Strike, quest, banner, summon, and telemetry rules.
- `warrior_runtime.gd` owns targeting, safe landings, casts, per-contact resolution, forced targeting, auras, and effects.
- `warrior_ability_presenter.gd` owns talent-aware roster text.
- Narrow shared systems own forced targets, positive-Armor effectiveness, source-aware healing received, strongest quest-progress multiplication, and finite summon lifetime.

The primary Basic Attack resolves first. A ready Heroic Strike then emits a separate 125-damage packet. On a successful primary attack, the newly started Heroic Strike cooldown receives 3 seconds of reduction (7 total with Twin Blades). An empowered attack consumed by Blind or Evasion resets Heroic Strike to 18 seconds without success CDR. Shattering Throw's Basic Attack bonus is shield-only and cannot spill into Health.

## Core abilities and specializations

- **Lion's Fang (Q):** 8-second line attack for 150, 35% Slow for 1.5 seconds, and one self-healing event per eligible contact. Boss contacts heal 140; Lionheart changes that to 245 and permits 35 from summons.
- **Parry (W):** two sequential charges, 10-second recharge, and 1.25 seconds of hostile Basic Attack prevention. Contacts still trigger Overpower and Vigilance. Shield Wall replaces it with one 5-second Protected charge.
- **Charge (E):** 12-second, 4-source-unit safe landing for 50 and 75% Slow for one second. Warbringer changes the cooldown to 4 seconds and permits allied targets.
- **Taunt (R):** 16-second cooldown, 1.25-second forced target plus Silence, including Bosses. It changes effective role to Tank, threat to 1.5, positive Armor effectiveness to +10%, and healing received to +10%; it adds no Health.
- **Colossus Smash (R):** 20-second safe landing for 185 and scaled -25 Armor for 3 seconds. It doubles Basic Attack damage, reduces maximum Health by 10%, preserves regeneration, and remains DPS. Master at Arms changes the cooldown to 10 seconds and adds a 2-source-unit area.
- **Twin Blades (passive R):** doubles attack speed, reduces Basic Attack damage by 25%, grants 30% movement for 2 seconds after successful attacks, and changes Heroic Strike CDR to 7 total seconds. Frenzy changes the Heroic Strike packet by +25% and movement to 40%.

## Talents, quests, and interactions

The Guild tree has eight tiers at levels 9, 12, 15, 18, 21, 24, 27, and 30. Level 18 intentionally contains exactly Shield Wall and Warbringer. Level-27 upgrades are gated to their matching specialization.

Lion's Maw gains +7 level-one Q damage per qualifying contact, capped at five contacts per cast and 25 total (+175). Completion changes the Slow to 50% for 2 seconds. High King's Quest is encounter-scoped: 50 qualifying primary attacks, 5 defeat participations within five seconds, and 15 Lion's Fang/Victory Rush healing events. Second Wind never progresses Endurance. Each objective gives +10 level-one Basic Attack damage and completing all three adds +30, for +60 total.

Juggernaut adds a separate 4% maximum-Health packet and removes 4% original finite lifetime from summons hit by Q or E; Bosses never qualify. Mortal Strike applies the strongest non-stacking 40% healing-received reduction for four seconds from successful Heroic Strike packets. Victory Rush primes every 30 seconds, heals 350 on the next successful primary attack, and loses 10 seconds per nearby death.

Shattering Throw (D) has a 30-second cooldown, 8-source-unit range, 50 normal damage, and 1400 shield-only damage. Its passive adds shield-only damage equal to up to 200% of the ordinary resolved Basic Attack.

Stormwind, Ironforge, and Dalaran banners activate immediately, repeat every 25 seconds, last 12 seconds, and use a 10.5-source-unit aura. They grant +25% movement, scaled 20 Armor, or +10% Ability Power. Glory adds +50% health regeneration and healing received. Demoralizing Shout snapshots nearby enemies for strongest-source 40% outgoing-damage reduction for five seconds. Shared Legacy doubles numeric combat-talent progress for allies during the first eight seconds; multiple sources use the strongest multiplier.

## Source audit

The binary audit uses the newest Heroes Tool Chest `heroes-data2` release, `v2.55.17.97771`. Its normalized extracted Varian object is identical to `v2.55.17.97650` and confirms 2220 Health, 4.625 regeneration, 74 Basic Attack damage, 0.8-second attack period, 1.25 attack range, and universal 4% scaling. Blizzard's March 29, 2022 notes confirm current 3-second Heroic Strike reduction, +7 Lion's Maw progress, and Colossus Smash at 185 / -25 Armor. Blizzard's current hero page still displays older 2-second, 160, and -20 values, so those page values are deliberately rejected in favor of the newer official patch and current binary data.

Audit references: [Heroes Tool Chest release](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97771), [Blizzard Varian page](https://heroes-site-production-eks-prod-use1-01.heroesofthestorm.blizzard.com/en-us/heroes/varian/), and [March 29, 2022 official notes](https://news.blizzard.com/en-us/article/23787368/heroes-of-the-storm-balance-patch-notes-march-29-2022).

## Testing Range and acceptance

Open the Testing save and select **Warrior Range**. It provides standard, elite, named, summon, temporary, Boss, attacking-defense, shield, high-Armor, and blocked-landing fixtures.

- `Shift+1-6` loads baseline, Taunt, Colossus, Twin Blades, anti-summon, and completed High King builds.
- `Ctrl+C/Q/K/B/H/S` resets cooldowns, completes Lion's Maw, completes High King, readies a banner, changes Health, or applies a target shield.
- `F3` shows specialization/role, Basic Attack amount and cadence, Heroic Strike, W charges, quests, R/D cooldowns, banner state, summon lifetime before/after, telemetry, and enemy threat.

Deterministic tests cover chassis, every registered talent, all specializations, packet/CDR ordering, Q contact caps and healing, Parry/Overpower/Vigilance, Shield Wall, High King, cross-class Shared Legacy, Juggernaut, forced targeting, shield-only damage, banners, persistence, and registration. Live tests cover every baseline ability, separate Heroic Strike damage, Evasion consumption, enemy/allied Charge, summon damage/lifetime, Boss Taunt, Master at Arms, all Banner auras/capstones, and Shattering Throw. See [`warrior_full_audit_v1.md`](warrior_full_audit_v1.md) for the interaction matrix and audit findings.

## Known V1 risks

- Q width/speed and several non-chassis radii come from community/extracted behavior cross-checks where public structured data does not expose one clean scalar. They remain centralized for calibration.
- Four-hero positioning can amplify Glory and Shared Legacy; telemetry should guide balance changes.
- Existing lightweight summons without an authored original lifetime take Juggernaut Health damage but intentionally skip lifetime removal.
