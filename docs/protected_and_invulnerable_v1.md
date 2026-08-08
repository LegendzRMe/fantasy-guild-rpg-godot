# Protected and Invulnerable V1

**Lifecycle:** Current contract.

Protected and Invulnerable are named status effects, not Armor or Shields.

| Rule | Protected | Invulnerable |
|---|---:|---:|
| Incoming damage | Prevented | Prevented |
| Shield consumed by prevented damage | No | No |
| Ordinary healing | Allowed | Allowed unless another state forbids it |
| Crowd control | Normal profile | Normal profile unless another effect says otherwise |
| Hostile direct targeting | Allowed | Rejected |

Spirit Form reports Invulnerable through the same shared query, is excluded from hostile and automatic ally targeting, and separately blocks normal healing, Shield, and Armor acquisition. Salvation applies Protected with the Priest owner ID; Light of Stormwind applies Invulnerable to other allies. Prevention telemetry is credited to that owner without manufacturing damage events.
