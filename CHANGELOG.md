# SwimTrack App — Changelog

All notable changes to the SwimTrack Flutter companion app are documented here.  
Format: [Semantic Versioning](https://semver.org) · Dates: YYYY-MM

---

## [1.1.0] — 2026-04 — Real-Device Fix + Icon + Layout

### Fixed
- **Critical — simulator mode desync on startup:** `DeviceApiService.instance`
  is now initialised with the persisted `simulatorMode` value in `main()` before
  any provider or widget builds. Previously the singleton defaulted to `false`
  (real mode) for the first frame even if the user had simulator ON from the
  last session, causing unexpected HTTP calls on startup.
- **Layout overflow — Settings tab:** `ConnectionStatusWidget` wrapped in
  `Expanded` inside its parent `Row`. Caused a 24 px overflow on devices with
  a screen width ≤ 360 dp (confirmed on Samsung Galaxy A54 / SM A546E).
- **Dart errors in `main.dart`:** Added missing import
  `providers/settings_provider.dart`. Typed `ref.listen<AppSettings>` callback
  with explicit `(AppSettings? prev, AppSettings next)` signature to fix
  `undefined_identifier` and three `unchecked_use_of_nullable_value` errors.
- **iOS icon alpha warning:** Added `remove_alpha_ios: true` to
  `flutter_launcher_icons` config — removes App Store submission warning.

### Added
- **App icon:** Custom SwimTrack icon (swimmer + wave) applied via
  `flutter_launcher_icons ^0.13.1`. Replaces default Flutter icon on Android
  home screen and app drawer.
- **`ref.listen` in `SwimTrackApp.build`:** Watches `settingsProvider` and
  calls `DeviceApiService.instance.setSimulatorMode()` on every toggle change,
  keeping the singleton in sync for the lifetime of the app — not just startup.

### Changed
- `pubspec.yaml`: added `flutter_launcher_icons ^0.13.1` to `dev_dependencies`
  and new `flutter_launcher_icons` configuration block.
- `assets/icon/app_icon.png` added to project (1024×1024, no alpha on iOS build).

---

## [1.0.0] — 2026-03 — First Complete Release

### Stack
- Flutter ≥ 3.0.0 / Dart ≥ 3.0.0
- State management: `flutter_riverpod ^2.4.0`
- Navigation: `go_router ^13.2.0`
- HTTP client: `dio ^5.4.0`
- Local database: `sqflite ^2.3.0`
- Charts: `fl_chart ^0.66.2`
- Fonts: `google_fonts ^6.2.1` (Poppins + Inter)
- WiFi verify: `wifi_iot ^0.3.19+1`
- Screen-on: `wakelock_plus ^1.1.4`

---

### Stage 1 — Foundation (2026-02)

#### Added
- Theme system: `SwimTrackColors` (deep navy `#03045E`, ocean blue `#0077B6`,
  cyan `#00B4D8`), `SwimTrackTextStyles`, `swimTrackTheme()`
- App constants: API base URL `http://192.168.4.1`, device SSID / password,
  default pool length, SharedPreferences key names
- Data models with `fromJson` / `toJson` / `toMap` / `fromMap`:
  - `Session` — id, startTime, duration, pool, laps, strokes, dist, SWOLF, SPM
  - `Lap` — number, time, strokes, SWOLF, stroke rate, DPS
  - `RestInterval` — start ms, duration
  - `UserProfile` — name, age, height, weight, gender
  - `DeviceStatus` — mode, battery, firmware version, session active flag
  - `LiveData` — all `/api/live` fields; float-as-string parsing via `_d()`
- `MockDataService` — deterministic fake sessions, laps, live data, device status
  for use when `simulatorMode == true`
- GoRouter with auth redirect: null profile → `/` · has profile → `/main`
- `main.dart` with `ProviderScope` + `MaterialApp.router`

---

### Stage 2 — Login + Profile Setup (2026-02)

#### Added
- `ProfileProvider` (`StateNotifier<UserProfile?>`) — loads / saves `UserProfile`
  to `SharedPreferences`; `isFirstRun` getter
- `SettingsProvider` (`StateNotifier<AppSettings>`) — pool length + simulator
  mode toggle; persisted in `SharedPreferences`
- **Login screen** — ocean-blue gradient header, credential form (SSID +
  password with eye toggle), Connect button with loading state and error SnackBar,
  simulator mode note at bottom
- **Profile Setup screen** — name, age, height, weight, gender fields with
  validation; segmented gender selector; "Save & Continue" → `/main`;
  reused for editing from Settings with back button + "Save Changes" label
- Router redirect logic wired to `profileProvider`

---

### Stage 3 — Main Shell + History + Session Detail (2026-02)

#### Added
- `DatabaseService` — SQLite via `sqflite`; tables: `sessions`, `laps`, `rests`;
  `insertSession`, `getAllSessions`, `getSession`, `deleteSession`
- `SessionProvider` (`StateNotifier<SessionState>`) — loads from SQLite on init,
  exposes `sync()` → `SyncService`, `deleteSession(id)`
- **Main screen** — `IndexedStack` with custom `BottomNavigationBar` (3 tabs:
  Home, History, Settings); bottom nav uses ocean-blue active color
- **History tab** — session list with pull-to-refresh; shimmer loading state
  (3 `ShimmerCard` placeholders); empty state illustration; error card with Retry
- **Session Detail screen** — header metrics grid (duration, distance, laps,
  SWOLF, avg SPM, avg DPS); SWOLF trend chart (`fl_chart` `LineChart`); full lap
  table with colour-coded SWOLF cells (green < 35, amber 35–50, red > 50)
- Widgets: `SessionCard`, `MetricCard`, `SwolfChart`, `LapTable`, `ShimmerCard`

---

### Stage 4 — Home Tab + Live Data (2026-02)

#### Added
- `DeviceProvider` (`StateNotifier<DeviceState>`) — connection state machine:
  `disconnected → connecting → connected → error`; `connect()`, `disconnect()`,
  `refreshStatus()`, `markSessionStarted()`, `markSessionStopped()`
- `LiveProvider` (`StreamProvider<LiveData?>`) — polls `GET /api/live` every
  1 second while `deviceProvider.isSessionActive == true`; emits `null` when idle;
  uses `MockDataService.generateLiveData(elapsedSec)` in simulator mode
- `ConnectionStatusWidget` — animated pulsing amber dot while connecting;
  solid green when connected; grey when disconnected; firmware version in label
- `PoolLengthSelector` — chip group (15 m / 25 m / 33 m / 50 m)
- `StrokeSelector` — chip group (Freestyle / Backstroke / Breaststroke / Butterfly)
- **Home tab — idle state:** greeting, connection status, weekly stats card,
  pool + stroke selectors, last session card (or first-session empty state prompt),
  START SESSION button
- **Home tab — recording state:** dark navy background, 500 ms `AnimatedSwitcher`
  fade, live metrics grid (elapsed time, strokes, laps, SWOLF est., rate, resting
  indicator), STOP SESSION button
- `WakelockPlus.toggle(on: true)` during active session to keep screen awake

---

### Stage 5 — Settings + Device API + Sync (2026-03)

#### Added
- `WiFiService` — pings `GET /api/status` to verify device reachability;
  simulator: instant success; real: 5 s timeout with `DioException` handling
- `DeviceApiService` (singleton) — all HTTP calls to ESP32 REST API:
  `getStatus`, `getLiveData`, `getSessions`, `getSession`, `startSession`,
  `stopSession`, `deleteSession`; simulator fallback on every method;
  `setSimulatorMode(bool)` method
- `SyncService` — compares device session list with local SQLite IDs; fetches
  and inserts only new sessions; returns `SyncResult(newSessions, errors)`
- **Settings tab** sections: PROFILE · TRAINING · DEVICE · APP
  - PROFILE: avatar circle, name + stats, edit pencil → profile setup
  - TRAINING: pool length bottom sheet, default stroke bottom sheet
  - DEVICE: connection status row, battery progress bar, firmware version,
    Sync Sessions button + result SnackBar, Disconnect / Connect button
  - APP: Simulator Mode toggle, App Version label
- Login screen wired to real `DeviceProvider.connect(ssid, password)`
- History tab sync icon + pull-to-refresh both call `SyncService.sync()`

---

### Stage 6 — Polish + Error Handling (2026-03)

#### Added
- `ShimmerCard` — gradient shimmer animation (1.5 s repeat) for History loading
  placeholder; shown while `sessionProvider.isLoading == true`
- First-session empty state in Home tab: dashed-outline card with wave emoji
  and "Start your first session!" prompt
- Error card in History tab: red-tinted container with error text and Retry button
- Empty laps state in Session Detail: centred message when `session.laps.isEmpty`
- `DeviceProvider.markSessionStarted()` creates a minimal `DeviceStatus` stub
  when not connected — allows START SESSION without prior `connect()` call

#### Fixed
- `withOpacity()` calls throughout replaced with `withValues(alpha:)` to resolve
  Flutter deprecation warnings
- Stop session flow now calls `DeviceApiService.stopSession()` then
  `DeviceApiService.getSession(savedId)` in sequence — ensures the saved session
  (with full lap data) is fetched and stored correctly
- `AndroidManifest.xml` `android:usesCleartextTraffic="true"` confirmed present
  in `<application>` tag — required for plain HTTP to `192.168.4.1` on Android 9+

---

### Stage 7 — Documentation (2026-03)

#### Added
- `docs/README.md` — full app documentation: overview, architecture diagram,
  Flutter setup, simulator mode guide, device connection guide, REST API
  reference, build & release instructions, troubleshooting
- `docs/CHANGELOG.md` — this file
- `docs/API_REFERENCE.md` — quick API cheat sheet
- Doc comments (`///`) on all public classes and methods in every source file

### Known Limitations at v1.0.0
- Android 10+ blocks programmatic WiFi switching — user must connect to
  `SwimTrack` network manually in phone WiFi settings before using the app
- Google Fonts requires internet access on first run to download Poppins / Inter;
  fonts are cached after the first successful download
- Session timestamps use `millis()` since device boot — not real Unix time;
  displayed times are relative until RTC / NTP is added to firmware
- `stroke_type` always shows `FREESTYLE` (firmware limitation)
- Battery always shows `100%` (firmware stub — ADC not yet implemented)

---

## Roadmap

- [ ] Multi-device support — allow connecting to named devices (not just `SwimTrack`)
- [ ] Progress screen — weekly/monthly SWOLF trend, distance bar chart, stroke pie chart
- [ ] Export session — share as CSV or PDF from Session Detail
- [ ] Notifications — post-session summary push notification
- [ ] Dark mode — respect system `Brightness` in `swimTrackTheme()`
- [ ] iOS build — resolve `wifi_iot` platform channel on iOS; add Info.plist entries
- [ ] Offline maps / pool database — auto-suggest pool length by GPS location

---

*App repo: https://github.com/AbdelRahman-Madboly/SwimTrack-app.git*