# Charged cast foundation V1

`charged_cast_system.gd` is a class-neutral state machine. It records active slot, elapsed/max time, aim point, device, configured input mode, instant-full state, and maximum-charge state. Starting, advancing, committing, cancelling, and interrupting are separate operations so class runtimes cannot accidentally spend cooldowns on button-down or manual cancellation.

Maximum charge remains armed until an explicit release or confirmation. PC and mobile input both start charge on button/touch down. Release-style, Cursor, Facing Direction, and area-instant-style selections commit on release; Confirm remains armed after key release and commits at location confirmation. Facing Direction snapshots the authored direction while other modes update the aim during charge. Divine Purpose uses `instant_full` but still requires commit.

The shared interruption contract accepts Stun, Silence, Fear, and forced displacement. Root, Slow, and Blind are intentionally ignored. Paladin owns the three-second Divine Purpose cooldown refund because that is a class rule, not a generic charge rule.
