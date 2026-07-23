# Combo Points V1

Combo Points are stored on the owning unit. Baseline maximum is three; Vigor raises storage to five. A successful generation hit requires positive Health or Shield damage. Misses, immunity, invalid targets, Blinded zero-damage releases, scenery, and harmless objects do not qualify.

`combo_point_system.gd` reports gained and wasted points. Eviscerate snapshots up to three points and reports `combo_points_used_for_scaling` separately from `combo_points_consumed`; Adrenaline Rush can therefore scale from three while consuming zero. Points reset on defeat and encounter end, and are not restored by revival.
