# Fear and Silence

Fear and Silence are reusable controls owned by `status_effect_system.gd`.

- Unstoppable prevents both.
- Silence blocks cast-like enemy behavior but does not prevent ordinary movement or Basic Attacks.
- Fear interrupts casts, channels, and Basic Actions, then moves the affected unit directly away from the stored cast origin using collision-safe movement and arena bounds.
- Default Boss profiles are Fear immune. A custom profile may provide a nonzero `fear_multiplier` for shortened control.
- Horrify applies Silence only after Fear succeeds. Haunt is likewise attached only to a successful Fear and lasts for the resolved Fear duration.

Temporary `FEAR` and `SILENCE` battlefield labels are readability hooks, not final art.
