# Death Knight conversion V1

Lifecycle: **current mechanics-first conversion specification**.

Death Knight is an Arthas-inspired testing-only Melee DPS class with no Mana. It combines an encounter-scaling weapon, a manual self-or-enemy Death Coil, ground-targeted Howling Blast, an unlimited Frozen Tempest toggle, and either Army of the Dead or Summon Sindragosa. It is not added to starter, campaign, recruitment, or ordinary permanent-progression pools.

## Resolution contracts

- Frostmourne Hungers primes D and immediately requests a primary Basic Attack when a valid melee target exists. Its independent bonus packet is 71 plus 3 per encounter stack; ordinary Basic Attacks are 95 plus 0.75 per stack. Its 12-second cooldown starts when the empowered attack is consumed. Standard enemies require a kill; Elite, named, Boss, and enemy-Hero targets grant progress on a successful hit. Summons and temporary-combat targets never grant stacks. Shared Legacy does not multiply weapon stacks.
- Death Coil deals 164 to a hostile target or heals the Death Knight for 275 when manually cast on the hero. Both use a nine-second cooldown. Immortal Coil adds its enemy-cast self-heal/healing reduction and changes only the manual self-cast to 481.25 healing and six seconds.
- Howling Blast deals 68 and Roots for 1.25 seconds in its final area. Frost Presence can add a travel path, range, and Death Coil Slow. A target contacted by both path and final area takes both packets but counts once toward the quest for that cast.
- Frozen Tempest ticks first after one second and every second thereafter for 36. Per-source, per-target movement and attack-speed suppression ramps 10 percentage points per tick to 40%, lingering 1.5 seconds. D/Q/W/R remain locked while active; E turns it off and starts the eight-second cooldown. Eternal Winter removes the lock and ramps 20 points while retaining the cap.
- Army starts with six sequentially recharging charges at 18 seconds each and consumes every available charge in one cast. Each charge creates one independently identified 15-second, 1200-Health Ghoul that acquires, moves toward, and attacks targets for 20 each second; Legion creates two and changes recharge to 13 seconds. Nearby enemy deaths reduce only the active recharge timer by one second. Ghouls expose the generic owner, source, category, Health, collision, original/remaining lifetime, and defeat fields consumed by Warrior anti-summon mechanics.
- Sindragosa deals 230 in a line, Slows 60% for four seconds, Blinds for four seconds, and uses a 100-second cooldown. Absolute Zero doubles line length and applies a 2.5-second Root before the Slow.

## Progression and shared interactions

Frost Presence is an encounter quest with a five-unique-target cap per Howling Blast cast. Shared Legacy can multiply its numeric progress. Rewards occur at 15, 30, and 50; reaching 50 writes member mastery. New encounters and respecs clear encounter progress while mastery persists and supplies the unlocked rewards whenever Frost Presence is selected.

Rime is triggered only by a successfully applied incoming Slow, Root, or Stun and supplies strongest-source 75% incoming damage reduction for five seconds. Shattered Armor extends pre-existing Slow, Root, and Stun durations before Howling applies its own controls. Frostmourne Feeds likewise snapshots control before Frost Strike can apply its Slow. Death's Dominion snapshots pre-cast control for 25% or 40% strongest-source outgoing damage reduction, and Howling refreshes only a still-active Dominion instance from that Death Knight.

Rune Tap's passive +5% healing received is additive with bonuses while duplicate reductions remain strongest-source. Every third successful primary Basic Attack during Tempest adds a 5% nearby-party aura stack to 25%; all stacks end with Tempest. Anti-Magic Shell grants Blind immunity and multiplies incoming Stun, Root, and Slow duration by 0.75 without changing magnitudes.

## Source audit

The latest Heroes Tool Chest normalized data release, `v2.55.17.97771`, confirms the current source anchors: 2750 source Health, 5.7304 regeneration, 95 Basic Attack damage, 1.1-second weapon period, 2 range, six starting/max Army charges, and Ghoul 1200 Health / 20 damage / one-second attack period / 15-second decay. V1 deliberately converts Health to 2100 and proportionally converts regeneration to 4.3752 while retaining the attack anchors.

Blizzard's April 20, 2026 notes still list Death Coil self-healing at 262 and the older Frostmourne +1/+1 progression. The May 11, 2026 balance notes supersede those with 275 healing, +3 empowered damage, +0.75 Basic Attack damage, and the final Frost Presence values. July 20, 2026 notes confirm follow-up fixes to Howling Blast visuals, Frost Strike's baseline Slow interaction, and Ghoul outgoing-damage behavior. Where public structured data does not expose a single canonical geometry scalar, V1 centralizes a documented provisional value.

Audit references: [Heroes Tool Chest release](https://github.com/HeroesToolChest/heroes-data2/releases/tag/v2.55.17.97771), [April 20 official notes](https://news.blizzard.com/en-us/article/24261475/heroes-of-the-storm-live-patch-notes-april-20-2026), [May 11 official notes](https://news.blizzard.com/en-us/article/24276959/heroes-of-the-storm-balance-patch-notes-may-11-2026/), and [July 20 official notes](https://news.blizzard.com/en-us/article/24291432/heroes-of-the-storm-live-patch-notes-july-20-2026).

## Testing Range

Open the Testing save and select **Death Knight Range**. It supplies standard, Elite, named, enemy-Hero, summon, temporary-combat, ordinary Boss, Root-immune Boss, pre-Slowed, healing, and wounded-party fixtures.

- `Shift+1-6` loads baseline, Tempest suppression, Frostmourne weapon, Howling controller, Death Coil suppressor, and mastered Frost Presence builds.
- `Ctrl+C/F/H/M/G` resets cooldowns, adds a Frostmourne stack, changes Health, masters Frost Presence, or restores six Army charges. `E` toggles Tempest.
- `F3` displays weapon stacks/priming, every cooldown, lock state, per-target suppression, Icy Talons, Rune Tap, Rime, Frost Presence/mastery, Army/Ghouls, ramps, modifiers, and telemetry.

Deterministic and live tests cover the chassis, exact tree and gating, progression categories, packet ordering, all baseline casts, toggle timing/locks, every talent, source-aware stacking, mastery persistence, Ghouls, both Heroics and upgrades, Boss/control profiles, Range fixtures, save migration, registration, parsing, startup, and Windows export. The detailed evidence map is in [`death_knight_full_audit_v1.md`](death_knight_full_audit_v1.md).
