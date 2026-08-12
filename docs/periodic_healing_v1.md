# Periodic healing V1

`PeriodicStatusSystem` now supports beneficial periodic instances without changing existing damage-over-time behavior.

## Contract

- Healing instances carry `beneficial`, `healing`, and `periodic_healing` identity plus caller-provided source tags such as `healing_over_time`, `regrowth`, or `druid_basic_hot`.
- Ownership is explicit: effect ID, source combat ID, and target combat ID define source-aware lookup and refresh behavior.
- `refresh_owned` replaces only the matching owner's instance and restarts that refreshed effect's normal tick schedule.
- Independent applications remain independent. This is required for one mini-HoT per successful Basic Attack and permits overlap on one target.
- `remaining_tick_count` and `remaining_scheduled_amount` expose the actual scheduled future healing used by Nature's Communion.
- Bonus-tick snapshots emit a due tick without mutating the original timer, duration, or next regular tick.

Periodic healing is an amount-request layer. Resolution still passes through `deal_healing`, which applies outgoing healing, effective-healing and overhealing accounting, threat, combat presentation, item hooks, and source telemetry. The generic `healing_over_time_multiplier` is applied to HoT requests only, before that normal resolution pipeline.

Generated secondary healing must declare whether it is direct or periodic. Nature's Swiftness is direct healing and cannot chain from its own overhealing. Rejuvenation and Basic Attack mini-HoTs are periodic but are distinct from Regrowth for Moonfire and Heroic checks.
