# Sacred Ground geometry V1

Sacred Ground extends shared blocker geometry with a circular ring. The ring blocks movement crossing from inside to outside and outside to inside, but does not block line of sight or projectiles. The Paladin owner bypasses their own ring. Other allied Heroes, enemies, and eligible companions obey it. Existing authored `control_profile.displacement` rules remain authoritative for Bosses; the class does not silently grant universal Boss immunity.

Righteous Hammer has one narrow exception: an enemy that starts outside and is knocked inward may cross the perimeter. The exception is passed only for that outside-to-inside displacement packet. Ordinary movement and other displacement cannot use it. Paladin's own Avenging Wrath endpoint passes owner identity through shared safe-placement checks.

Hallowed Ground records whether E began inside the current circle. On successful landing it removes the old ring on the next runtime synchronization, moves the center to the safe landing point, and resets remaining duration to seven seconds. Relocation does not sweep, teleport, push, or immediately damage units. A unit exactly overlapping the new perimeter is deterministically prevented from crossing on its next movement step by the standard ring-padding rule.

The world presentation uses a filled gold interior and thick double perimeter so it reads as a wall. Periodic damage remains a once-per-second Level-scaled 28 damage packet and projectiles pass through unchanged.
