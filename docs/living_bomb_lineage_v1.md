# Living Bomb Lineage V1

`living_bomb_lineage_system.gd` gives every direct Living Bomb a stable bomb ID and new lineage ID. A target may own only one active bomb. Directly casting on an already-bombed target detonates that bomb and completes its spread before creating the replacement with a new lineage.

Each lineage owns a visited-target set and active-bomb count. A base direct bomb may create first-generation spreads. Those children normally cannot spread again; Master of Flames permits later generations. No generation may infect a target already visited by its lineage, and no target with any active bomb accepts another spread. These two gates guarantee termination even in a two-target formation.

The parent lineage remains alive while its explosion chooses and creates child bombs. It is deleted only when the last active bomb has been removed. Host death detonates at the host's last valid position. Spread bombs retain Mage ownership, lineage, and generation; Sun King's Fury marks their periodic and explosion damage. Presence of Mind responds only to newly created infections, while Pyromaniac responds only to a periodic tick that resolves positive Shield or Health damage.

Ignite creates one new direct bomb on the hit, currently living, unbombed enemy nearest the exact Flamestrike center. Fission Bomb changes the shared explosion/spread radius. Debug telemetry records concurrent bomb count, infections, explosions, ticks, and cooldown reduction without changing lineage decisions.
