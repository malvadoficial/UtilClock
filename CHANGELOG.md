# Changelog

## v1.1.2 - 2026-02-22

- Fixed accidental fullscreen toggles caused by fast/double click interactions.
- Added settings toggle to switch between fullscreen/window mode and remember the last selected mode on launch.
- Countdown controls updated:
  - Main button now toggles `start/pausa`.
  - `stop` now returns to the originally introduced countdown value.
  - `reset` now clears countdown to `00:00:00`.
- Added audible beeps for the final three countdown seconds (`3`, `2`, `1`).
- README now documents installation via downloadable DMG from GitHub Releases.

## v1.1.1 - 2026-02-21

- Startup display selection is now remembered between launches.
- Added settings option to forget saved startup display selection (applies on next launch).
- Fixed startup display picker showing on every launch despite a saved selection.
- Fixed audio capture staying active outside tuner/chord-detect modes.

## v1.1.0 - 2026-02-21

- Added top stopwatch mode before countdown.
- Stopwatch now displays `mm:ss:cc` (centiseconds).
- Added single dynamic `start/stop` button in stopwatch.
- Added small clickable `pre on/off` button for pre-countdown.
- Added 3-second visual pre-countdown overlay (`3`, `2`, `1`) with flash before stopwatch starts.
- Updated project versioning and release documentation for GitHub releases.
