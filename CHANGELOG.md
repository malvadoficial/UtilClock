# Changelog

## v1.1.3 - 2026-02-22

- Added app presentation mode with persisted preference:
  - `Dock` mode (regular behavior).
  - `Menu bar` mode (status-bar icon without Dock icon).
- Added menu-bar control menu with:
  - monitor switcher (list of available displays),
  - fullscreen enable/disable,
  - launch-at-login toggle,
  - quit action with exit icon.
- Added launch-at-login controls in app Settings (`Auto-inicio ON/OFF`).
- Improved menu-bar behavior to avoid fullscreen breakage when toggling presentation modes.
- Standardized menu-bar labels to single-language localization (system language, fallback to English).

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
