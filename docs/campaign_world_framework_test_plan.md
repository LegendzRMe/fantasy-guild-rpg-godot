# Campaign and World Framework Test Plan

## Scope

This prototype connects the existing Ashwood tutorial to a six-region, three-act campaign from level 2 through level 30. It tests permanent regional maps, story progression, branching exploration, decisions, faction reputation, settlement access, campaign equipment, Trading Post sales, roster growth, support operations, rival presentation, returning consequences, and eight-hero combat.

Ashwood remains Zone 0 and owns the building and guild tutorials. Twilight is an event and final gateway outcome, not a physical world-map region. Ehrejora, Norath, the Living Island, and Elemental Plains remain locked future destinations.

## Normal campaign route

1. Create a normal save and complete Ashwood.
2. Confirm Greyhaven Reach and the Combat Hall unlock. Confirm other campaign regions remain locked.
3. Enter Greyhaven from the World Map. Complete its gold main-path locations in order.
4. Visit discovered side and faction locations between main encounters. Confirm these locations persist after leaving the screen.
5. Make Greyhaven's permanent decision. Confirm the decision appears in the Council Chamber and Kwaad unlocks.
6. Repeat for Kwaad, Consortium, Gallah, Godfall, and Grand.
7. At Grand, configure Support Teams A and B before the Gateway Site operation.
8. Complete the Nazareth waves, make the gateway decision, and review the campaign summary.

Milestone targets are Greyhaven 5, Kwaad 10, Consortium 15, Gallah 20, Godfall 25, and Grand 30. Region completion raises only under-levelled active heroes to the milestone; it never lowers heroes.

## Permanent-location checks

- Undiscovered locations show `???` and cannot be entered.
- Discovered locations are readable and persistent.
- Available main-story locations are gold and playable.
- Completed one-time locations turn green and never offer their original campaign advancement again.
- Completed main locations offer a stable three-entry repeatable pool.
- Side and faction locations offer reusable regional work when discovered.
- Leaving to the Guild Hall, reloading the save, and returning preserves every location status.
- Completing a region leaves its map accessible and reveals remaining locations.

## Reputation and access checks

Reputation is clamped to -100 through 100. Ranks are Hostile (-100 to -50), Unfriendly (-49 to -1), Neutral (0 to 19), Cooperative (20 to 49), and Trusted (50 to 100).

- Neutral and better: faction location access is allowed.
- Unfriendly or Hostile: access is denied with current rank, required Neutral rank, Leave, and Fight Guards actions.
- Guard victories never conquer or permanently open the settlement.
- The first guard victory at a location can award modest Renown and loot; repeated victories do not farm that reward.
- Attacking guards applies a substantial reputation penalty.
- Cooperative reputation is visible in the Council and represents the contract/dialogue threshold.
- Crossing Trusted once grants one named faction-origin recruit. Repeated gains must not duplicate that recruit.

## Economy and item checks

- Campaign battles grant Gold and the existing `guild_renown` resource displayed as Renown.
- Campaign equipment is Common or Uncommon and records slot, rarity, item level, source region, gear power, sell value, and locked state.
- Campaign items enter the existing Guild Vault and use normal equipment ownership.
- Equipped, locked, or favourited items cannot be sold.
- Individual sales add the exact sell value to Gold and remove the item.
- Sell All Common requires confirmation and affects only eligible Common items.
- `prestige_tokens` remain a separate Prestige system resource. The abandoned legacy `tokens` field remains discarded during migration.

## Council and rivals

- The Council Chamber unlocks after the first non-zero Greyhaven reputation change.
- Factions lists all regional factions with value and rank.
- Regional Outcomes lists every saved permanent decision.
- Rival Guilds always includes Gilded Jackals, Crimson Standard, and Wayfarer Accord plus background guilds.
- Completing a major region advances rival standing and adds a saved activity-log entry.

## Support operations

- Assign no more than four heroes each to Support Team A and Support Team B.
- A hero cannot appear on both teams.
- Resolve an operation and verify its saved support score and Strong, Adequate, Weak, or Missing result.
- Support resolution is immediate and does not run an off-screen combat simulation.
- The Grand Gateway Site automatically records the configured support result with the main operation.

## Eight-hero Combat Hall checks

Use a roster with at least eight heroes.

### Raid Test

- Eight controlled heroes appear in non-overlapping formation positions.
- The HUD displays eight health portraits.
- Keys 1 through 8 select the matching controlled hero.
- Click/touch selection, drag movement, targeting, and Q/W/E/R continue to work.
- Multiple waves and a boss spawn and can complete normally.
- Victory and defeat both produce a report containing duration, defeated enemies, hero count, and performance.
- Returning to the Combat Hall works.
- Gold, Renown, item ownership, and campaign progress are unchanged by the test.

### Rival Guild Scrimmage

- Eight controlled heroes face eight class-like rival units simultaneously.
- Units do not overlap at spawn.
- The encounter ends when one side is defeated.
- No campaign rewards or rival standing are awarded.

## Save and regression checks

- Main menu and all four save cards render.
- New save creation, deletion, save, reload, and backup recovery work.
- An old save without `campaign` migrates to save schema version 6 with no loss of heroes or inventory.
- Ashwood progression and four-hero combat remain functional.
- Active Party and saved teams remain capped at four; only Combat Hall tests create eight-hero runtime parties.
- Vault, professions, Tavern, recruitment, equipment, and existing merchant purchases remain functional.
- Run `tests/run_campaign_tests.gd` for focused campaign-state coverage.
- Run `tools/validate.ps1` for parser, full automated regression, startup, export-pack, UTF-8, and whitespace checks.

## Debug route

The testing save exposes Campaign Debug from a regional map. It can unlock all regions, grant Renown, grant a campaign item, open any region, and force region completion. Debug actions are intentionally unavailable in normal saves.

## Intentional placeholders

- Reformation Grounds, Arena Ladder, and Battleground Drills in the Combat Hall.
- Advanced city traversal; settlements are menu-based.
- Full bespoke dialogue trees and cinematics; story presentation is concise text and decision panels.
- Bespoke enemy art and region-specific combat mechanics; campaign encounters reuse the stable enemy roles and arena runtime.
- Advanced faction vendors, titles display, contracts, professions, raids, PvP progression, and endgame regions.
