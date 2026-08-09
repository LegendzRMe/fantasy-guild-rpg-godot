# Threat System V1

Each enemy owns an independent Threat ledger keyed by party battle index. Positive resolved damage creates damage Threat; effective healing and absorbed source-owned Shields use their existing distributed ratios. Normal target selection compares ledger values using nearby/distant pull thresholds, while authored forced targets and Taunts retain priority.

## Canonical Tank baseline

The stacked history did not contain a later explicit decision making Guardian's old `5.0` the universal standard. The newest Tank conversion, Templar, already used `1.5`. V1 therefore centralizes `CombatBalanceData.TANK_THREAT_MODIFIER = 1.5` and applies it to Guardian, Templar, and Protector. No Tank silently invents a separate ordinary damage-Threat baseline.

Templar Shield Ally remains distinct: if its bearer creates 500 damage Threat, the bearer keeps 500 and the linked Templar receives an additional 500. The copied value is not multiplied by 1.5 again.

## Protector Purge Evil

For each enemy successfully damaged by one Smite cast, Purge Evil:

1. excludes the casting Protector;
2. considers other living allied Heroes only;
3. selects the highest positive Threat, breaking ties by earlier party index;
4. sets only that enemy/Hero ledger entry to zero.

It never transfers Threat, changes Protector's value, clears the whole table, forces target selection, or removes Taunt. Law and Order shares the original cast ID/contact set, preventing duplicate purge. Boss ledgers use the same rule.
