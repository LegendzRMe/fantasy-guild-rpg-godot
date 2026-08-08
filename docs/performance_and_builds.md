# Performance, Validation, and Builds

Lifecycle: current developer workflow.

## Fast local loop

- Double-click `Launch Game.cmd` or run `.\tools\run.ps1` to start the project with the discovered Godot installation.
- Run `.\tools\validate.ps1` before sharing changes. It uses temporary user data, primes script inheritance, parses the project, runs all tests, performs source and exported-pack startup smoke tests, inspects the runtime log, checks UTF-8 hygiene, and runs `git diff --check`.
- Run `.\tools\audit.ps1` after a substantial feature or refactor. Its numbers are diagnostics, not arbitrary merge gates.
- Run `.\tools\profile.ps1` to record deterministic application-update timings for Guild Hall idle, the four-Hero testing range, and a Level 30 Endless Arena with twelve enemies. The JSON report is written to `build/performance/latest.json` and compared with the checked-in baseline when the machine and Godot version match.
- Run `.\tools\profile-graphics.ps1` for a visible, non-headless render benchmark. It disables VSync for the capture, records 900 frames per scenario, reports frame throughput, renderer setup time, draw calls, primitives, graphics memory, and adapter details, then compares frame-time p95 when the adapter, renderer, and window size match the checked-in graphics baseline.

The audit reports source volume, scripts above the configured size threshold, long-line concentration, the largest methods, assets above the configured size threshold, and counts of a few high-coupling calls. Thresholds can be overridden with parameters such as `-LargeScriptLines 400`.

## Runtime measurement

The testing save's Guild Hall test panel shows the project version, build identifier, frames per second, object count, and draw calls for a quick runtime snapshot. Treat a single snapshot as an alert, not a benchmark. The headless profile isolates deterministic application-update cost, while the graphical profile measures actual rendered-frame throughput through the active display server and adapter. On OpenGL, Godot exposes renderer statistics and CPU frame-setup time but not a hardware GPU timestamp, so the uncapped frame interval is the practical end-to-end rendering measurement.

The checked-in Windows/Godot 4.7 reference capture is `performance/baselines/windows_godot_4_7.json`. The profile command guards median and p95 with a deliberately noise-tolerant relative and absolute allowance; override `-MaxRegressionPercent`, `-AbsoluteAllowanceMs`, or `-BaselinePath` when investigating. Review p99 and maximum values manually because operating-system and occasional persistence spikes should not be merge gates by themselves.

The matching visible-render reference is `performance/baselines/windows_graphics_godot_4_7.json`. It was captured at 1280x720 on an NVIDIA GeForce RTX 4070 Ti using Godot's `gl_compatibility` renderer and OpenGL 3.3 driver. The uncapped mean throughput was 475 FPS in the Guild Hall, 622 FPS in the four-Hero testing range, and 511 FPS in the twelve-enemy Level 30 arena; frame-time p95 remained between 2.05 ms and 2.59 ms with about 21 MB of reported graphics memory.

For a meaningful comparison:

1. Use the same Godot build, display size, save, party, encounter, and input sequence.
2. Capture idle Guild Hall, a representative four-Hero battle, and the busiest available encounter.
3. Use Godot's Profiler to record frame time, physics time, memory, and rendering counters for at least 30 seconds after warm-up.
4. Compare medians and visible spikes before and after a change. Keep the captured scenario with the performance note so another developer can reproduce it.

Routine persistence is debounced through `persistence_coordinator.gd`, which keeps repeated disk writes out of frame-sensitive update paths. Critical transitions still flush immediately. Full-screen backgrounds remain persistent nodes instead of being recreated during screen refreshes.

## Asset guidance

The current audit identifies the world map and Ashwood combat background as the largest source images. Both are 1672x941 2D screen images with mipmaps disabled. Their committed source PNGs remain lossless; Godot imports the detailed, zoomable world map at 0.90 lossy quality and the fixed 1280x720 combat background at 0.85 to reduce shipped texture size. The resulting imports are approximately 0.43 MB and 0.10 MB, with measured PSNR values of 38.45 dB and 40.92 dB. `tools/check_texture_quality.gd` enforces conservative quality floors during validation, while `tools/export_texture_preview.gd` can decode an imported texture back to PNG for visual review. New large images should be authored near their maximum displayed resolution and evaluated with the audit plus an imported-texture preview.

Keep source licenses and provenance in `assets/THIRD_PARTY_ASSETS.md` and `assets/third_party/README.md`. Generated or replaced assets should retain a stable `res://` path whenever possible so scenes and save-facing definitions do not churn.

## Reproducible Windows exports

The project pins the required engine feature to Godot 4.7 and commits `export_presets.cfg`. Install the matching templates once:

```powershell
.\tools\install_export_templates.ps1
```

Then run `.\tools\build.ps1` or double-click `Launch Build.cmd`. The build command validates first, exports the `Windows Desktop` release into `build/windows`, smoke-tests the real executable with isolated user data, and writes `build-info.json`. Because the project's lightweight inheritance layers use script-path declarations that are not export dependency hints, the preset includes project resources and explicitly excludes tests, tools, documentation, profiling captures, build output, and standalone balance-lab tooling. Override `-GodotPath`, `-OutputDirectory`, or `-BuildId` when producing a controlled release.

`build/` is intentionally ignored. Release artifacts should be distributed by a release process rather than committed to source control.

## Continuous integration

`.github/workflows/validate.yml` downloads the pinned Godot build, runs the same local validator on Windows, records the audit even after a failure, and uploads the report. The repository variable `GODOT_VERSION` may override the default version during an intentional engine upgrade; update `project.godot`, local development, CI, templates, and this document together.
