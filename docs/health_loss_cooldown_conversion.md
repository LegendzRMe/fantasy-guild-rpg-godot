# Health-Loss Cooldown Conversion

Life Tap is a Health cost, not damage. It bypasses Armor and Shields, cannot be lethal, cannot trigger damage reactions, and never feeds the passive conversion loop.

Direct Life Tap uses the exact internal cost `maximum_health * (222 / 1700)`. A normal successful tap subtracts 25 percent of each eligible modified base cooldown from its remaining cooldown; Improved Life Tap uses 40 percent. Reduction is simultaneous, floors at zero, and never stores overflow. The 0.5-second D lockout begins only after a valid payment or an armed free Darkness Within use.

Other actual Health loss converts proportionally:

```text
tap_equivalent = actual_health_lost / (maximum_health * life_tap_health_cost_ratio)
reduction = modified_base_cooldown * 0.25 * tap_equivalent
```

`actual_health_lost` is measured after immunity, Armor, damage reduction, and Shields. Fully absorbed or Demonic-Circle-prevented damage produces no conversion. Heroics are excluded except that a direct successful Life Tap with Dark Ritual reduces the selected Heroic by five percent of its modified base cooldown.

Internal cooldown records opt in independently with `life_tap_reducible`, `health_loss_reducible`, and `chaotic_energy_reducible`. Consume Soul opts in; Demonic Circle does not.
