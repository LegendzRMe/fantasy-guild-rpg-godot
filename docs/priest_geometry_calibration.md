# Priest geometry calibration

**Lifecycle:** Calibration note.

All provisional Priest geometry lives in `scripts/data/priest_data.gd` under `PriestData.SPACE`. Source units use `185 / 5.5 = 33.636` project-world units.

| Geometry | Project value | Status |
|---|---:|---|
| Basic Attack range | 185 | Source-derived |
| Pursued radius | 218.64 | Provisional conversion |
| Flash Heal radius | 269.09 | Provisional conversion |
| Divine Star distance | 294.32 | Provisional conversion |
| Divine Star outbound width | 30.27 | Provisional |
| Divine Star return width | 53.82 | Provisional |
| Divine Star speed | 520/sec | Provisional |
| Chastise range | 353.18 | Source-derived conversion |
| Chastise width | 21.86 | Provisional |
| Chastise speed | 680/sec | Provisional |
| Salvation radius | 151.36 | Provisional conversion |
| Lightbomb selection range | 269.09 | Provisional conversion |
| Lightbomb radius | 151.36 | Provisional conversion |
| Blessed Champion radius | 151.36 | Provisional conversion |

Use Testing > Priest Range to calibrate movement-sensitive Q decisions, Divine Star contact/return behavior, Chastise collision, Lightbomb recipient swaps, and one/five/six-target caps. `Shift+1..3` loads baseline, Salvation, and Lightbomb builds. Dense final geometry labels belong behind the existing F3 testing overlay rather than on normal battlefields.
