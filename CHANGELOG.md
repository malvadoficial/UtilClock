# Changelog

## v1.2.5 - 2026-02-23

- Internationalization pass for `Ver Fotos` UI:
  - Replaced hardcoded visible strings with `L10n` keys.
  - Localized buttons, labels, permission texts, loading state and picker prompt.
- Added new localization keys for Photos mode texts in `L10n.swift`.

## v1.2.4 - 2026-02-23

- Restored and completed `Ver Fotos` mode with integrated slideshow flow.
- Added real Photos app integration:
  - Album list loading from Photos library (regular + smart albums, including `Favoritas`).
  - Album selection with persisted source between app launches.
  - Permission handling and in-app prompt/open settings behavior for Photos access.
- Added folder source support with persisted security-scoped bookmark and path restore.
- Reworked `Ver Fotos` launcher layout into a clearer two-column UI:
  - Source controls (`Album Fotos` / `Carpeta`) and separate rows for `Mostrar reloj` / `Duración`.
  - Selected source display area with album list toggle in-place.
  - Dedicated `START` area and photo count alignment.
- Slideshow behavior improvements:
  - Start directly in bottom fullscreen view.
  - Exit slideshow on click/tap back to launcher.
  - Random image order with non-repeating consecutive picks.
- Overlay clock improvements in slideshow:
  - Optional overlay toggle.
  - Much slower, softer color cycling for better readability.

## v1.2.3 - 2026-02-22

- Game UX and progression improvements:
  - Tetris now shows the next piece preview on the side.
  - Added persistent highscores per game.
  - Added highscore announcement when a run ends with a new record.
  - Added highscores panel in Settings with global reset to `0`.
- Arkanoid updates:
  - Paddle can be controlled with keyboard arrows and mouse wheel.
  - Paddle size option now supports levels `1..9`.
  - Level `1` is now significantly smaller.
  - Removed dynamic paddle-size boost behavior so size stays stable during play.
- Pac-Man:
  - Reworked maze layout to remove dead-end pathing issues.
  - Fixed initial spawn position to a valid walkable cell.
- Frogger:
  - Fixed log transport logic so frog is continuously carried while on green logs.
  - Collision checks now use carried horizontal position for consistent behavior.

## v1.2.2 - 2026-02-22

- Fixed Frogger log transport behavior:
  - The frog now moves correctly with green floating platforms.
  - Improved carry precision to avoid jerky transport and edge desyncs.
- Stopwatch pre-countdown now plays the same `tic` sound on `3`, `2`, `1`.

## v1.2.1 - 2026-02-22

- Improved `Red / Network` mode visual layout:
  - Unified app-style typography and reduced oversized text.
  - Reordered data: public IP first.
  - Grouped interface data by device (WiFi/Ethernet), including speeds + private IP in the same card.
  - Added responsive two-column layout for interfaces when width allows.
  - Tightened spacing to prevent overflow and keep margins stable.

## v1.2.0 - 2026-02-22

- Major refactor:
  - Split oversized `ContentView.swift` into focused files (`TopModes`, `Games`, `Settings`, `SystemLogic`, etc.).
- Top screen upgrades:
  - Added `Calendario` mode with month navigation and quick return to current day.
  - Added `Tiempo` mode with current conditions and 5-day forecast layout.
- Bottom screen mode unification:
  - Games now use a launcher grid with multi-row scroll.
  - Music modes unified into one launcher (tuner/chord finder/chord detector/metronome).
  - Info modes unified (RAE/music thought/today in history).
  - Apps and processes merged in one selectable mode.
  - Audio device + volume merged in one mode.
  - Storage + USB merged into one mode with disk usage visualization.
  - Added `Red` mode (public/private IP and network throughput by interface).
- Game updates:
  - Added games: Tetris, Space Invaders, Asteroids, Tron, Pac-Man, Frogger, Artillery, Jump n' run.
  - Improved controls and gameplay for Pong, Space Invaders, Asteroids, Tron, Pac-Man and Artillery.
  - Artillery now supports variable cannon/target placement, optional wind, improved trajectory physics and speed-wheel controls.
- Cleanup:
  - Removed leftover series/video module code.

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
