# Temporary Pathing Blockers V1

`CombatGeometry` supports two reusable blocker representations:

- axis-aligned rectangles, retained for authored terrain and Shaman Worldbreaker;
- oriented segment/capsules, added for Protector Force Wall.

Every blocker advertises independent `blocks_movement`, `blocks_line_of_sight`, and `blocks_projectiles` flags. Movement queries use the unit radius plus blocker thickness. Attack, projectile, and visibility queries consult only their matching flag. Force Wall sets movement true and line of sight/projectiles false; Worldbreaker retains its existing movement-only contract.

Segment blockers include endpoints, thickness, a broad-phase rectangle, owner combat ID, cast ID, remaining duration, and temporary state. Collision uses deterministic segment distance. If a blocker activates while overlapping a unit, the unit is moved by the minimum radial distance to the nearest valid side, clamped to battle bounds, with no damage.

Ordinary walking, enemy pursuit, Boss movement/charge, displacement, and hero movement share `move_toward_safe`. A special ability may filter an explicitly authorized owned blocker—for Protector Q/Judgment crossing its own wall—but does not bypass permanent or unrelated terrain. Blockers do not encode class talents; ownership-sensitive behavior remains in the owning class system.
