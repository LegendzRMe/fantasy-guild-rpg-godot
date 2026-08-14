# Monk (Kharazim) conversion V1

Lifecycle: conversion specification and implementation audit. Implemented on `feature/monk-kharazim-conversion-v1`.

## Outcome and source audit

Monk is a resource-free Support based on Kharazim. The source baseline was rechecked against HeroesToolChest `heroes-data2` build `2.55.17.97771`. The chassis preserves 2,080 level-one Health, 4.3333 regeneration, 64 Basic Attack damage, a 0.5-second interval, 1.75 source range, 4.8398 movement speed, and 0.625 radius. The project prompt is authoritative where it removes Mana, chooses the Support role, makes Breath and Reach passive cooldowns, and reworks Earth/Air Ally.

## Runtime contract

Radiant Dash is the only baseline manually activated Q/W/E action. It owns two sequential 12-second charges and a 0.25-second intercast gate. Other allied Heroes, Misha-equivalent permanent companions, the Monk's own selected Ally, and qualifying enemies are valid anchors; self and disposable summons are not. A blocker-safe landing preserves the requested interaction order: allied relocation, optional Stun/Root cleanse, optional Protected, then ready Breath; enemy relocation, ready Reach activation, then the immediate Basic Attack.

Breath and Reach remain visible passive slots and reject manual presses. Breath heals eligible ordinary recipients around the landing position and applies movement speed. Reach changes Basic Attack speed and range before the Dash attack. All successful qualifying Basic Attacks—including the Dash attack and six Way of the Hundred Fists attacks—advance the chosen third-hit Trait.

The selected Spirit, Earth, or Air Ally occupies D after Guild level 12. It is targetable, destructible, blocker-safe, Dash-valid only for its owner, lasts ten seconds, and uses a 45-second cooldown. Spirit heals 2% recipient maximum Health per second; Earth grants level-scaled Universal Armor from 50; Air grants 10% Ability Power. Ally state is encounter-only and is never serialized.

## Talents and Heroics

- Transcendence, Iron Fists, and Insight trigger on every third successful qualifying Basic Attack and grant 25% movement speed for 2.5 seconds. Insight completes at 100; only later third hits reduce active Q/W/E cooldowns by 1.75 seconds.
- Blinding Speed changes Q to three charges and ten-second recharge. Heavenly Zeal adds 50% healing to the allied Dash target and raises Breath speed to 30%. Blazing Fists doubles Reach duration and removes 0.75 seconds from Reach cooldown on third hits.
- Quicksilver removes Stun and Root before Breath without control immunity. Breath Armor gives the primary Breath 50 level-one Universal Armor for three seconds. Controlled Assault grants 25% Monk-owned normal damage to currently Stunned or Rooted targets while Reach is active; percentage-health packets retain their shared exclusion.
- Sanctified Dash grants Protected for one second without control immunity. Hundred Fists performs six 45% Basic Attacks that qualify for the Trait. Echo heals snapshotted primary recipients for 75% immediately and 75% after three seconds; the secondary heal does not repeat primary extras.
- Divine Palm protects an eligible Hero-equivalent ally from lethal damage for four seconds and heals 1,200. Peaceful Repose adds 75% healing and leaves five seconds of cooldown if Palm expires unused. Seven-Sided Strike makes Monk Invulnerable and selects the highest-current-Health eligible target for seven strikes over two seconds, using 7% maximum Health normally and the authored 0.5% Boss override. Transgression adds four strikes.
- Fists of Legend retains the chosen Trait and adds half of both unchosen effects; unchosen Insight is immediately considered complete, while selected Insight still requires its quest. Storm Shield applies 20% recipient-maximum-Health Shields for three seconds from primary Breath on a 45-second internal cooldown. Epiphany refills the current Q maximum only when a spend reaches zero and has an independent 70-second cooldown.

## Persistence and presentation

Monk is registered in the class, ability, target, talent, roster, save-discovery, and testing catalogs without entering campaign recruitment. Monk Range provides allied, companion, disposable, controlled, Boss, clustered, blocker, Palm, and percentage-health fixtures. Builds `1..5` and Ctrl testing controls expose charges, quest state, Allies, controls, cooldowns, and target ordering. F3 reports Q/W/E, Trait, Insight, Ally/aura, Heroic, capstone, and telemetry state. Monk-specific Dash, Breath, Palm, Seven-Sided, and Ally effects are rendered in combat.
