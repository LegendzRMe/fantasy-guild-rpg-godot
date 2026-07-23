# Armor Reduction V1

Armor reduction uses `armor_reduction_system.gd`. Every source has a stable source ID, amount, and remaining duration. Sources never add together: only the strongest unexpired value applies, with Armor clamped at zero. Refreshing the same source replaces its amount and duration. When a stronger source expires, the next strongest source becomes effective.

Ambush applies its reduction after its own damage, so that hit cannot benefit from the newly created source. Assassinate changes duration, not reduction amount. Temporary positive Armor still uses the shared strongest-positive-source rule after the reduced base Armor is determined.
