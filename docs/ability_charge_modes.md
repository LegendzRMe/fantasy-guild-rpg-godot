# Ability charge modes

`AbilitySlotSystem` supports three class-neutral recharge policies:

- `SEQUENTIAL`: one active timer restores one charge and begins the next timer if charges are still missing.
- `INDEPENDENT`: every spent charge owns its own timer.
- `FULL_REFILL`: spending starts one timer if none exists; its completion restores all charges simultaneously.

Cooldown reduction affects the active timer. Inter-cast and lockout timers remain independent. Light of Elune uses `FULL_REFILL`; Commander of Sentinels uses `INDEPENDENT`. This distinction is part of the reusable system contract and is covered by automated tests.
