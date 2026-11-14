# Sputnik Moment

A cold-war flavoured 2D orbital flight sandbox for Android, built with Godot 4.
All builds happen in GitHub Actions — nothing is compiled locally.

## Build

Push to `main`. The workflow downloads Godot 4.4 with its export templates,
sets up JDK 17 + Android SDK 34, installs the Android build template, and
exports a debug APK. The APK is attached to the rolling `nightly` release.

## Modes

- **Freedom Flight** — implemented (test article).
- **Story Archive** — sealed, arrives later.

## Cheats and assists

Cheats are freedom-mode only and are toggled per session:

| Cheat | Effect |
| --- | --- |
| Infinite propellant | fuel never drains |
| Null gravity | gravity disabled |
| Overdrive thrust | 72 m/s² instead of 26 m/s² |
| Hull integrity | no crash on impact |

Automation assists are always available:

| Assist | Effect |
| --- | --- |
| Gyro stabilizer | damps rotation when no input |
| Landing telemetry | predicted impact velocity on the HUD |
| Trajectory plot | projected ballistic path |

## Layout

```
scenes/           single entry scene
scripts/          game state, input, screens, flight simulation
shaders/          CRT mask, grain, planet surface, star field
```
