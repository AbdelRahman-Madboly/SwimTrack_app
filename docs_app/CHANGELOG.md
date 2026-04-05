# SwimTrack App — Changelog

## v1.0.0 (2026-03)

### Stage 1 — Foundation
- Theme system: `SwimTrackColors`, `SwimTrackTextStyles`, `swimTrackTheme()`
- Constants: API URL, device SSID/password, default pool length
- Data models: `Session`, `Lap`, `RestInterval`, `UserProfile`, `DeviceStatus`, `LiveData`
- GoRouter navigation with redirect logic
- `MockDataService` for simulator mode
- `main.dart` with `ProviderScope` + `MaterialApp.router`

### Stage 2 — Login + Profile
- `ProfileProvider` — loads/saves `UserProfile` from `SharedPreferences`
- `SettingsProvider` — pool length + simulator mode toggle
- Full Login screen — gradient header, credential form, Connect button, error state
- Full Profile Setup screen — form with validation, gender segmented selector
- Router redirect: has profile → `/main`, no profile → `/`

### Stage 3 — Main Shell + History
- `DatabaseService` — SQLite sessions/laps/rests tables
- `SessionProvider` — loads sessions from SQLite, save/delete operations
- Main screen with custom bottom navigation bar (3 tabs, IndexedStack)
- History tab — session list, pull-to-refresh, empty state, error state
- Session Detail screen — metrics grid, SWOLF chart (fl_chart), lap table with colour-coded SWOLF
- `SessionCard`, `MetricCard`, `SwolfChart`, `LapTable` widgets

### Stage 4 — Home Tab + Live Data
- `DeviceProvider` — connection state machine (disconnected/connecting/connected/error)
- `LiveProvider` — StreamProvider polling `/api/live` every 1 second
- `ConnectionStatusWidget` — animated pulsing dot
- `PoolLengthSelector` and `StrokeSelector` chip widgets
- Home tab — idle state with weekly stats, selectors, START button
- Home tab — recording state with dark theme, live metrics, STOP button
- `AnimatedSwitcher` 500ms fade between idle and recording states
- Wakelock during active session

### Stage 5 — Settings + Device API + Sync
- `WiFiService` — pings `/api/status` to verify device reachability
- `DeviceApiService` — all HTTP calls with simulator fallback, exact ESP32 JSON parsing
- `SyncService` — fetches device sessions, compares with local, inserts new ones
- Settings tab — profile/training/device/app sections, sync button, connect/disconnect
- Login screen wired to real `DeviceProvider.connect()`
- History tab sync shows result toast

### Stage 6 — Polish + Fixes
- `ShimmerCard` — animated loading placeholder for History tab
- Home tab "first session" empty state prompt
- START SESSION fixed — works without prior `connect()` call
- `DeviceProvider.markSessionStarted()` creates minimal status if disconnected
- Stop session uses real `DeviceApiService.stopSession()` + `getSession()`
- All `withOpacity()` → `withValues(alpha:)` (Flutter deprecation fix)

### Stage 7 — Documentation
- `docs/README.md` — complete app documentation
- `docs/CHANGELOG.md` — this file
- `docs/API_REFERENCE.md` — quick API cheat sheet
- All source files collected in `lib/` with doc comments
