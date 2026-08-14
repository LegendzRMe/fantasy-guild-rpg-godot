# Damage redirection V1

Lifecycle: current reusable mechanic contract.

`DamageRedirectionSystem` produces a pure plan from two recipients, raw hostile damage, eligibility, recursion state, and an optional Health-percentage snapshot. It does not mutate Health or apply mitigation.

Protective Bond is the first consumer. If Beastmaster or living Misha is at a lower Health percentage than the other, half the incoming pre-mitigation packet remains on the original target and half becomes a redirected packet to the healthier partner. Each packet then independently resolves Armor, Block, Shields, damage-taken modifiers, defeat, threat, events, and telemetry. Equal Health percentages, dead partners, ineligible damage, and packets tagged as already redirected never split.

Area attacks evaluate each original contact independently from its event-time Health state. The recursion tag is carried in the trigger chain so the original contact can retain its normal primary-attack identity while the redirected half cannot produce a second primary proc.
