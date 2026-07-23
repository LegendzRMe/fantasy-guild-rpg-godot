# Background Channel and Foreground Actions

Channels normally occupy the unit action state: movement and other abilities interrupt or remain unavailable. Soul Conduit is a narrow Warlock exception recorded on Drain Life's active-channel data as `background`.

While that channel remains valid, one foreground Q, E, D, or selected R action may commit. It may target a different enemy without replacing Drain Life's stored target. Basic Actions and movement remain unavailable, and a second W cannot start. Invalid foreground targeting leaves the channel intact.

Movement or true control interrupts both a foreground cast and the background channel. An interrupted Heroic receives the shared ten-second pre-release cooldown. A successfully released Rain of Destruction becomes persistent and continues independently.

This is deliberately not a general permission for every class to cast during channels. Future users must opt in explicitly and add their own acceptance tests.
