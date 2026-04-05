# SwimTrack App — Project Instructions

You are building the **SwimTrack** Flutter mobile app (Android). Read this entire file before writing any code. Every rule here applies to every file in the project.

---

## What You Are Building

SwimTrack is a companion app for a wrist-worn ESP32 swimming device. The device tracks swim strokes, lap count, and SWOLF score using an IMU sensor. It creates a WiFi hotspot. The phone connects to it and exchanges data over HTTP.

The app does four things:
1. Connects to the SwimTrack device over WiFi
2. Lets the swimmer start and stop a recording session
3. Shows live metrics (stroke count, laps, SWOLF) during a session
4. Stores session history locally and displays it with lap-by-lap breakdown

**Keep it simple.** Big numbers. Minimal text. Fast interactions. Built for use poolside.

---

## App Structure — 3 Screens Only

```
Launch
  │
  ▼
LOGIN SCREEN
  Enters device WiFi name + password → taps Connect
  │
  ├── First time → PROFILE SETUP SCREEN
  │                 Name, age, height, weight, gender → Save
  │                   │
  │                   ▼
  └── Returning  → MAIN SCREEN (3 tabs)
                     │
                     ├── HOME TAB
                     │     Idle:      device status · pool/stroke selector · START button
                     │     Recording: timer · stroke count · laps · SWOLF · STOP button
                     │
                     ├── HISTORY TAB
                     │     List of past sessions → tap → SESSION DETAIL SCREEN
                     │
                     └── SETTINGS TAB
                           Profile · Pool length · Device connection · Simulator toggle
```

That is the entire app. No dashboard screen. No progress screen. No extra screens.

---

## Device Communication

**WiFi SSID:** `SwimTrack`  
**WiFi Password:** `swim1234`  
**Device IP:** `http://192.168.4.1`  
**Protocol:** Plain HTTP, JSON bodies, no authentication

> **Android HTTP fix required:** Add `android:usesCleartextTraffic="true"` to the `<application>` tag in `AndroidManifest.xml`. Without this, all API calls fail silently on Android API 28+.

### REST API — All Endpoints

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/api/status` | — | `{"mode":"IDLE","battery_pct":85,"battery_v":3.92,"session_active":false,"firmware_version":"1.0.0"}` |
| GET | `/api/live` | — | `{"stroke_count":14,"lap_count":2,"current_swolf":42.0,"stroke_rate":32.5,"elapsed_sec":145,"is_resting":false}` |
| GET | `/api/sessions` | — | `[{"id":"12010","lap_count":4,"distance_m":100,"avg_swolf":9.7,"duration_sec":86,"start_time":"2026-03-25T10:30:00Z"}]` |
| GET | `/api/sessions/{id}` | — | Full session (see below) |
| POST | `/api/session/start` | `{"pool_length_m":25}` | `{"status":"ok","session_id":"12010"}` |
| POST | `/api/session/stop` | — | `{"status":"ok","session_id":"12010"}` |
| DELETE | `/api/sessions/{id}` | — | `{"status":"ok"}` |

**Full session JSON from `/api/sessions/{id}`:**
```json
{
  "id": "12010",
  "start_time": "2026-03-25T10:30:00Z",
  "pool_length_m": 25,
  "duration_sec": 86,
  "total_distance_m": 100,
  "avg_swolf": 9.7,
  "avg_stroke_rate": 38.4,
  "lap_data": [
    {"n":1,"t_s":21.3,"strokes":5,"swolf":26.3,"spm":14.1},
    {"n":2,"t_s":20.1,"strokes":4,"swolf":24.1,"spm":12.0}
  ],
  "rests": [
    {"start_ms":45000,"dur_s":12.3}
  ]
}
```

---

## Tech Stack

| Role | Package | Version |
|------|---------|---------|
| State management | `flutter_riverpod` | ^2.4.0 |
| Navigation | `go_router` | ^13.0.0 |
| HTTP client | `dio` | ^5.4.0 |
| WiFi connection | `wifi_iot` | ^0.3.19 |
| Local database | `sqflite` | ^2.3.0 |
| Path helper | `path` | ^1.8.0 |
| Preferences | `shared_preferences` | ^2.2.0 |
| Charts | `fl_chart` | ^0.66.0 |
| Fonts | `google_fonts` | ^6.1.0 |
| Date formatting | `intl` | ^0.19.0 |
| Screen-on lock | `wakelock_plus` | ^1.1.0 |

---

## Design System

**Rule: Never write a hex color or font size directly in a widget. Always use `SwimTrackColors` and `SwimTrackTextStyles` from `config/theme.dart`.**

### Colors — `SwimTrackColors`

| Constant name | Hex | Used for |
|---------------|-----|---------|
| `primary` | `#0077B6` | Buttons, active nav tab, app bar |
| `secondary` | `#00B4D8` | Charts, live session accent, highlights |
| `background` | `#F8FAFE` | All screen backgrounds |
| `card` | `#FFFFFF` | Card backgrounds |
| `dark` | `#1A1A2E` | Recording screen background, text primary |
| `textSecondary` | `#4A4A68` | Body text, labels |
| `textHint` | `#8E8EA0` | Timestamps, units, placeholder text |
| `good` | `#2ECC71` | Improving SWOLF, success |
| `bad` | `#E74C3C` | Declining SWOLF, Stop button, errors |
| `neutral` | `#F39C12` | Unchanged metrics |
| `divider` | `#E8EDF2` | Section separators |

### Text Styles — `SwimTrackTextStyles`

| Constant name | Font | Size | Weight | Used for |
|---------------|------|------|--------|---------|
| `bigNumber` | Poppins | 48 | Bold | Timer, live stroke count |
| `hugeNumber` | Poppins | 64 | Bold | The main live stroke count display |
| `screenTitle` | Poppins | 24 | SemiBold | Screen headings |
| `sectionHeader` | Poppins | 18 | SemiBold | Section titles |
| `cardTitle` | Inter | 16 | SemiBold | Card headings |
| `body` | Inter | 14 | Regular | Body text |
| `label` | Inter | 12 | Regular | Labels, units |
| `tiny` | Inter | 10 | Regular | Timestamps, hints |

### Spacing and Shape

| Property | Value |
|----------|-------|
| Screen padding | 24px |
| Card padding | 16px |
| Gap between cards | 12px |
| Card border radius | 16px |
| Card elevation | 2 |
| Card shadow | `0 2px 8px rgba(0,0,0,0.08)` |
| Primary button height | 56px |
| Stop button height | 64px |
| Button border radius | 12px |

---

## Data Models

All models live in `lib/models/`. All have `fromJson()` factory and `toJson()` method.

```dart
class UserProfile {
  final String name;
  final int age;
  final int heightCm;
  final int weightKg;
  final String gender; // 'male', 'female', 'other'
}

class Session {
  final String id;
  final DateTime startTime;
  final int poolLengthM;
  final int durationSec;
  final int totalDistanceM;
  final double avgSwolf;
  final double avgStrokeRate;
  final List<Lap> laps;
  final List<RestInterval> rests;
}

class Lap {
  final int lapNumber;
  final int strokeCount;
  final double timeSeconds;
  final double swolf;
  final double strokeRate; // strokes per minute
}

class RestInterval {
  final int startMs;
  final double durationSec;
}

class DeviceStatus {
  final String mode;           // 'IDLE' or 'RECORDING'
  final int batteryPct;
  final double batteryV;
  final bool sessionActive;
  final String firmwareVersion;
}

class LiveData {
  final int strokeCount;
  final int lapCount;
  final double currentSwolf;
  final double strokeRate;
  final int elapsedSec;
  final bool isResting;
}

class AppSettings {
  final int poolLengthM;       // default 25
  final bool simulatorMode;    // default false
}
```

---

## File Structure

Every file listed here must be created. Each has a specific purpose — do not merge them.

```
lib/
├── main.dart                       ← App entry, ProviderScope, theme, GoRouter
│
├── config/
│   ├── theme.dart                  ← SwimTrackColors, SwimTrackTextStyles, ThemeData
│   ├── routes.dart                 ← GoRouter definition, all routes, redirect logic
│   └── constants.dart              ← kApiBaseUrl, kDeviceSsid, kDevicePassword, kDefaultPool
│
├── models/
│   ├── user_profile.dart           ← UserProfile + fromJson/toJson/copyWith
│   ├── session.dart                ← Session, Lap, RestInterval + fromJson/toJson
│   ├── device_status.dart          ← DeviceStatus + fromJson
│   └── live_data.dart              ← LiveData + fromJson
│
├── services/
│   ├── device_api_service.dart     ← All HTTP calls via Dio, returns typed models
│   ├── database_service.dart       ← SQLite: sessions + laps + rests tables
│   ├── wifi_service.dart           ← wifi_iot connect/disconnect/isConnected
│   ├── sync_service.dart           ← WiFi → fetch device sessions → save to SQLite
│   └── mock_data_service.dart      ← Fake data for simulator mode
│
├── providers/
│   ├── profile_provider.dart       ← UserProfile? state, load/save shared_preferences
│   ├── device_provider.dart        ← Connection state + DeviceStatus
│   ├── session_provider.dart       ← List<Session> from SQLite + sync + delete
│   ├── live_provider.dart          ← Polls /api/live every 1s during recording
│   └── settings_provider.dart      ← AppSettings (pool length + simulator toggle)
│
├── screens/
│   ├── login_screen.dart           ← WiFi credentials + Connect button
│   ├── profile_setup_screen.dart   ← Name/age/height/weight/gender form
│   ├── main_screen.dart            ← BottomNavigationBar with 3 tabs
│   ├── home_tab.dart               ← Idle state + live recording state
│   ├── history_tab.dart            ← Session list, pull to refresh
│   ├── settings_tab.dart           ← Profile, training, device, app sections
│   └── session_detail_screen.dart  ← Charts + lap table for one session
│
└── widgets/
    ├── metric_card.dart            ← value + label, optional trend arrow
    ├── session_card.dart           ← History list item
    ├── lap_table.dart              ← Per-lap data table
    ├── swolf_chart.dart            ← fl_chart line chart
    ├── connection_status.dart      ← Animated dot + status text
    ├── pool_length_selector.dart   ← 25m / 50m / Custom chip selector
    └── stroke_selector.dart        ← Freestyle / Backstroke / Breaststroke / Butterfly chips
```

---

## Providers — Interfaces

```dart
// profileProvider
// State: UserProfile?  (null = first run, no profile saved yet)
// loadProfile()  → reads from shared_preferences
// saveProfile(UserProfile)  → writes to shared_preferences
// bool get isFirstRun  → state == null

// deviceProvider
// State: DeviceState { ConnectionStatus status, DeviceStatus? info, String? error }
// ConnectionStatus: disconnected | connecting | connected | error
// connect(ssid, password)  → wifi → getStatus → update state
// disconnect()  → wifi off → state = disconnected
// bool get isSessionActive  → info?.sessionActive ?? false

// sessionProvider
// State: SessionState { List<Session> sessions, bool isLoading }
// loadFromDatabase()  → called on init
// sync()  → sync_service.sync() → reload from db
// deleteSession(String id)

// liveProvider  (StreamProvider<LiveData?>)
// Polls /api/live every 1s when isSessionActive
// Emits null when not recording
// Simulator: generates fake incrementing data

// settingsProvider
// State: AppSettings { int poolLengthM, bool simulatorMode }
// setPoolLength(int), setSimulatorMode(bool)
// Persists in shared_preferences
```

---

## Navigation

```
/              → LoginScreen
/profile-setup → ProfileSetupScreen
/main          → MainScreen
/session/:id   → SessionDetailScreen
```

**Redirect logic in GoRouter:**
- Watch `profileProvider`
- If profile is null (not set up) and not already on `/` → redirect to `/`
- `LoginScreen` calls `router.go('/profile-setup')` on first connect
- `LoginScreen` calls `router.go('/main')` on returning connect
- `ProfileSetupScreen` calls `router.go('/main')` after saving

---

## Simulator Mode

When `settingsProvider.simulatorMode == true`:
- `wifi_service.connect()` returns `true` instantly, no real WiFi needed
- `device_api_service` returns data from `mock_data_service` instead of HTTP calls
- `liveProvider` generates incrementing fake data every 1s
- `sync_service.sync()` inserts 3 fake sessions into SQLite

This allows building and testing the entire app without the physical device.

---

## Code Rules — Enforced on Every File

1. **File doc comment** — first line of every `.dart` file is a comment describing what it does
2. **Method doc comments** — every public method has a comment: what it does, params, return
3. **`const` everywhere** — use `const` on every widget constructor that allows it
4. **Colors from theme** — never write `Color(0xFF...)` or `Colors.blue` in widget files
5. **Text styles from theme** — never write `fontSize:` or `fontWeight:` in widget files
6. **API calls through service** — never call `Dio` directly from a screen or provider
7. **`try-catch` on every async** — every `await` that can fail has error handling
8. **Three states always** — every screen that loads data shows: loading / error / data
9. **Empty state always** — every list screen shows a proper empty state widget
10. **`debugPrint` not `print`** — for development logs only, never in production paths

---

## Screen Specifications

### Login Screen

**Background:** gradient top 40% (`#0077B6` → `#005A8E`), white card bottom 60% (rounded top corners radius 32)

**Top area (white text):**
- 🌊 wave emoji or simple SVG wave, centered
- "SwimTrack" — Poppins 32 Bold, white
- "Your swim, perfected." — Inter 14, white 70% opacity

**White card:**
- Label: "Connect to Device" — `cardTitle`
- `TextField` Device Name — pre-filled `SwimTrack`, style: filled, radius 12, background `#F8FAFE`
- `TextField` Password — pre-filled `swim1234`, `obscureText: true` with eye icon toggle, same style
- Hint: "Make sure your phone is near your SwimTrack device" — `tiny`, `colorHint`, centered
- `ElevatedButton` **Connect** — full width, 56px height
  - Normal state: "Connect"
  - Loading state: `CircularProgressIndicator` (white, size 20) + "  Connecting…"
  - Disabled during loading
- Error display: `Container` red-tinted below button, shows error message

**On Connect tap:**
- Simulator ON → `Future.delayed(1s)` → success
- Simulator OFF → `wifi_service.connect()` → on success `device_api_service.getStatus()`
- Success: if `isFirstRun` → `router.go('/profile-setup')` else `router.go('/main')`
- Failure: show error message, reset button

---

### Profile Setup Screen

**AppBar:** no back button on first run. Back arrow when editing from Settings.  
**Title:** "About You"  
**Subtitle:** "We use this to calculate your swimming efficiency accurately."

**Form fields** (label above, `TextFormField` below, 16px gap between):
- Full Name — `TextInputType.name`, validator: not empty
- Age — `TextInputType.number`, suffix "years", validator: 10–100
- Height — `TextInputType.number`, suffix "cm", validator: 100–250
- Weight — `TextInputType.number`, suffix "kg", validator: 30–200
- Gender — `SegmentedButton<String>` with 3 segments: Male / Female / Other

**Button:** "Save & Continue" (first run) or "Save Changes" (edit mode) — full width, 56px  
**On save:** validate → `profileProvider.saveProfile()` → `router.go('/main')`

---

### Main Screen

`Scaffold` with `BottomNavigationBar` (3 items):
- Home — `Icons.pool` 
- History — `Icons.history`
- Settings — `Icons.settings_outlined`

Nav bar: `backgroundColor: white`, `selectedItemColor: primary`, `unselectedItemColor: colorHint`

Body: `IndexedStack` with index tracked by `_currentIndex`. All three tabs stay alive.

---

### Home Tab — Idle State

`Scaffold` background: `colorBackground`  
`SingleChildScrollView` padding 24:

1. `ConnectionStatus` widget (shows device state)
2. Greeting — "Good morning, [name]! 🏊" — `cardTitle`, `colorDark`
3. Last session card — condensed `SessionCard`, shows last session, not tappable
4. Weekly stats row — 3 equal `MetricCard` widgets:
   - Sessions this week | Distance this week | Best SWOLF this week
5. Section header "Ready to Swim" — `sectionHeader`
6. `PoolLengthSelector` widget
7. `StrokeSelector` widget
8. `ElevatedButton` **START SESSION** — full width, 56px, `colorPrimary`
   - On tap: loading spinner in button → `device_api_service.startSession(poolLength)` → `deviceProvider.startSession()`
   - On error: `SnackBar` with error message

---

### Home Tab — Recording State

`Scaffold` background: `colorDark` (animated transition 500ms from idle)  
`WakelockPlus.enable()` on enter, `WakelockPlus.disable()` on stop

Layout `SafeArea` padding 24:

1. Row: red pulsing dot + "RECORDING" text + `Spacer` + timer "MM:SS"
2. Centered: stroke count — Poppins **64sp Bold**, white
3. Centered: "🏊 Freestyle" (selected stroke) — `cardTitle`, `colorSecondary`
4. Two side-by-side glass cards (`Container` white 10% opacity, radius 16, padding 16):
   - Left: "Lap X" + "X strokes" 
   - Right: "XX.X spm" + "SWOLF: XX.X"
5. `ElevatedButton` **STOP SESSION** — full width, 64px, `colorBad`
   - On tap: `device_api_service.stopSession()` → save to SQLite → `router.push('/session/$id')`

`AnimatedSwitcher` between idle and recording with `FadeTransition` 500ms.

---

### History Tab

`AppBar`: "History" + sync `IconButton` (calls `sessionProvider.sync()`)  
`RefreshIndicator` wrapping `ListView`

**Loading state:** 3 shimmer placeholder cards (grey animated containers)  
**Empty state:** centered column — "🏊" large, "No sessions yet", "Sync from your device in Settings", `OutlinedButton` "Go to Settings"  
**Data state:** `ListView.separated` of `SessionCard` widgets, gap 12px

**SessionCard:**
- Left: 🏊 emoji in colored circle (primary bg, 48px)
- Center: date formatted "Wed, Mar 20" + "Xm · X laps"
- Right: SWOLF value (sectionHeader, primary) + "SWOLF" label (tiny, hint)
- `onTap`: `router.push('/session/${session.id}')`

---

### Session Detail Screen

Load session by ID from `sessionProvider`.

`AppBar`: back arrow + date as title + delete `IconButton` (shows confirm dialog)

Body `SingleChildScrollView` padding 24:

1. Header info row: Distance | Duration | Pool | Laps — 4 small items in a row
2. 2×2 `GridView`: Avg SWOLF | Avg SPM | Total Strokes | Rest Time
3. Section "SWOLF per Lap" → `SwolfChart` (height 200px)
4. Section "Lap Breakdown" → `LapTable`

**SwolfChart:** `LineChart` from fl_chart. x = lap numbers. y = SWOLF.  
Line: `colorPrimary`, width 2.5. Dots: white fill, primary border.  
Gradient fill below: primary → secondary at 15% opacity.

**LapTable:** Table with columns: # | Strokes | Time | SWOLF  
SWOLF cell: `colorGood` background if below session avg, `colorBad` if above.  
Alternating row backgrounds: white / `colorBackground`.

---

### Settings Tab

`SingleChildScrollView` padding 24. Four grouped sections:

**PROFILE** (white card radius 16):
- `CircleAvatar` with initials + name + age/height/weight summary
- Edit `IconButton` → `router.push('/profile-setup')` with `editMode: true`

**TRAINING** (white card radius 16):
- "Pool Length" `ListTile` + current value + chevron → bottom sheet with `PoolLengthSelector`
- "Default Stroke" `ListTile` + stroke name + chevron → bottom sheet with `StrokeSelector`

**DEVICE** (white card radius 16):
- `ConnectionStatus` widget
- If connected: battery `ListTile` + firmware `ListTile` + Sync button + Disconnect button
- If disconnected: Connect button

**APP** (white card radius 16):
- `SwitchListTile` "Simulator Mode"
- `ListTile` "App Version" trailing "v1.0.0"

---

## pubspec.yaml

Use exactly this:

```yaml
name: swimtrack
description: SwimTrack — Smart Swimming Training Companion
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  dio: ^5.4.0
  wifi_iot: ^0.3.19
  sqflite: ^2.3.0
  path: ^1.8.0
  shared_preferences: ^2.2.0
  fl_chart: ^0.66.0
  google_fonts: ^6.1.0
  intl: ^0.19.0
  wakelock_plus: ^1.1.0
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

---

## AndroidManifest.xml Required Changes

In `android/app/src/main/AndroidManifest.xml`:

**Inside `<manifest>` tag** — add all permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**On the `<application>` tag** — add this attribute:
```xml
android:usesCleartextTraffic="true"
```

---

## Build Stages

The project is built in 7 stages. Each stage is a separate message you send in this project. **After each stage: run `flutter run`, verify it works, then ask for the next stage.**

Do not skip stages. Do not combine stages. Each one must pass before the next begins.

| Stage | What gets built | Test to pass |
|-------|----------------|--------------|
| 1 | Theme · Constants · Models · Router · Mock data · main.dart | App launches, no errors |
| 2 | Login screen · Profile setup · Profile provider · Settings provider | Login → profile → main works |
| 3 | Main screen shell · History tab · Session detail · SessionCard widget | Bottom nav + history + detail |
| 4 | Home tab (idle + recording) · Live provider · Device provider | Start/stop session in simulator |
| 5 | Settings tab · WiFi service · Device API service · Sync service | Settings visible, sync in simulator |
| 6 | Empty states · Loading shimmer · Error handling · Animations · HTTP fix | All edge cases covered |
| 7 | Documentation · Doc comments on all files | README complete |

---

## Stage Prompts — Send These One at a Time

---

### STAGE 1 — Foundation

```
Build Stage 1 of the SwimTrack app. Create all of these files completely.

config/theme.dart:
  Class SwimTrackColors — all static const Color fields:
    primary=#0077B6, secondary=#00B4D8, background=#F8FAFE, card=#FFFFFF,
    dark=#1A1A2E, textSecondary=#4A4A68, textHint=#8E8EA0,
    good=#2ECC71, bad=#E74C3C, neutral=#F39C12, divider=#E8EDF2.

  Class SwimTrackTextStyles — all static TextStyle fields using google_fonts:
    bigNumber (Poppins 48 Bold), hugeNumber (Poppins 64 Bold),
    screenTitle (Poppins 24 SemiBold), sectionHeader (Poppins 18 SemiBold),
    cardTitle (Inter 16 SemiBold), body (Inter 14 Regular),
    label (Inter 12 Regular), tiny (Inter 10 Regular).

  Function swimTrackTheme() returns ThemeData:
    scaffoldBackground=background, colorScheme primary=primary,
    AppBar: background=primary, foreground=white, elevation=0, centerTitle=false,
    ElevatedButton: background=primary, foreground=white, height=56, radius=12,
    Card: color=card, elevation=2.

config/constants.dart:
  const String kApiBaseUrl = 'http://192.168.4.1';
  const String kDeviceSsid = 'SwimTrack';
  const String kDevicePassword = 'swim1234';
  const int kDefaultPoolLength = 25;

config/routes.dart:
  GoRouter with routes: /(LoginScreen), /profile-setup(ProfileSetupScreen),
  /main(MainScreen), /session/:id(SessionDetailScreen).
  Redirect: watch profileProvider — if profile is null and not on '/' → '/'
  (full redirect logic after profile_provider is built in Stage 2)

models/user_profile.dart:
  UserProfile {String name, int age, int heightCm, int weightKg, String gender}
  fromJson factory, toJson method, copyWith method.

models/session.dart:
  Session {String id, DateTime startTime, int poolLengthM, int durationSec,
           int totalDistanceM, double avgSwolf, double avgStrokeRate,
           List<Lap> laps, List<RestInterval> rests}
  Lap {int lapNumber, int strokeCount, double timeSeconds, double swolf, double strokeRate}
  RestInterval {int startMs, double durationSec}
  All with fromJson/toJson.

models/device_status.dart:
  DeviceStatus {String mode, int batteryPct, double batteryV,
               bool sessionActive, String firmwareVersion}
  fromJson factory.

models/live_data.dart:
  LiveData {int strokeCount, int lapCount, double currentSwolf,
            double strokeRate, int elapsedSec, bool isResting}
  fromJson factory.

services/mock_data_service.dart:
  generateSessions(int count) returns List<Session>:
    Realistic sessions: 4-10 laps, SWOLF 35-55, strokes 10-20 per lap,
    times 20-35s per lap, pool 25m, start times spread over last 30 days.
  generateLiveData(int elapsedSec) returns LiveData with incrementing values.
  generateDeviceStatus() returns DeviceStatus (mode: IDLE, battery 80-90%).

main.dart:
  ProviderScope wrapping MaterialApp.router.
  Theme: swimTrackTheme(). Router: the GoRouter from routes.dart.
  No content yet — routes will show placeholder screens.

Create placeholder screens (just a Scaffold with centered text):
  screens/login_screen.dart — "Login Screen"
  screens/profile_setup_screen.dart — "Profile Setup"
  screens/main_screen.dart — "Main Screen"
  screens/session_detail_screen.dart — "Session Detail"

TEST: flutter run → app launches → no errors → shows "Login Screen" placeholder.
```

---

### STAGE 2 — Login + Profile + Routing

```
Build Stage 2 of the SwimTrack app.

providers/profile_provider.dart:
  State: UserProfile? (null = first run)
  On init: loadProfile() reads 'user_profile' JSON from shared_preferences.
  saveProfile(UserProfile): serialise to JSON → shared_preferences → update state.
  bool get isFirstRun → state == null.
  Expose as StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>.

providers/settings_provider.dart:
  State: AppSettings {int poolLengthM, bool simulatorMode}
  Load from shared_preferences on init. Defaults: poolLengthM=25, simulatorMode=false.
  setPoolLength(int v): update state + save to prefs.
  setSimulatorMode(bool v): update state + save to prefs.

Update config/routes.dart redirect:
  watch profileProvider. If AsyncValue is loading → no redirect.
  If loaded and profile is null and path != '/' → redirect to '/'.
  If loaded and profile exists and path == '/' → redirect to '/main'.

Build screens/login_screen.dart fully:
  Background: Stack with blue gradient container top half + white card bottom half.
  Blue gradient (top to bottom: #0077B6 → #004A8F):
    Centered column: 🌊 emoji large, "SwimTrack" (Poppins 32 Bold white),
    "Your swim, perfected." (Inter 14, white 70% opacity).
  White card (top corners radius 32, shadow, padding 28):
    Text "Connect to Device" — SwimTrackTextStyles.cardTitle, SwimTrackColors.dark
    SizedBox 20
    TextField Device Name — controller pre-filled "SwimTrack"
      InputDecoration: labelText, filled=true, fillColor=#F8FAFE,
      border=OutlineInputBorder(radius 12, borderSide colorDivider)
    SizedBox 12
    TextField Password — controller pre-filled "swim1234", obscureText toggle
      suffix: IconButton eye to toggle obscureText. Same decoration.
    SizedBox 8
    Text "Make sure your phone is near your SwimTrack device"
      SwimTrackTextStyles.tiny, SwimTrackColors.textHint, center
    SizedBox 24
    ElevatedButton: full width.
      Normal: Text "Connect"
      Loading (bool _loading=true): Row(CircularProgressIndicator white size 20, "  Connecting…")
      Disable button while loading.
    SizedBox 12
    If _errorMessage != null: Container(
      padding 12, decoration(color bad.withOpacity(0.1), radius 8, border bad),
      Text(_errorMessage, style label, color bad))

  On Connect:
    setState _loading=true, _errorMessage=null.
    If settingsProvider.simulatorMode: await Future.delayed(Duration(seconds:1)).
    Else: (wifi connect added in Stage 5, for now treat as simulator)
    On success: if profileProvider.isFirstRun → router.go('/profile-setup')
                else → router.go('/main')
    On failure: setState _loading=false, _errorMessage='Could not connect. Try again.'

Build screens/profile_setup_screen.dart fully:
  AppBar: automaticallyImplyLeading=false (no back on first run).
  Title "About You" — screenTitle.
  Body SingleChildScrollView padding 24:
    Text "We use this to calculate your swimming efficiency accurately."
      body, colorTextSecondary
    SizedBox 28
    Form(key: _formKey):
      _field("Full Name", _nameCtrl, TextInputType.name, required)
      _field("Age", _ageCtrl, TextInputType.number, "years", validate 10-100)
      _field("Height", _heightCtrl, TextInputType.number, "cm", validate 100-250)
      _field("Weight", _weightCtrl, TextInputType.number, "kg", validate 30-200)
      SizedBox 16
      Text "Gender" — label, colorTextSecondary
      SizedBox 8
      SegmentedButton<String>(segments:[Male,Female,Other])
        selected: {_gender}, onSelectionChanged: setState _gender=val.first
      SizedBox 32
      ElevatedButton "Save & Continue" full width 56px:
        On tap: if _formKey.currentState!.validate():
          profileProvider.saveProfile(UserProfile(...)) → router.go('/main')

  _field helper widget: Column(
    Text(label, style:label, color:colorTextSecondary), SizedBox 6,
    TextFormField(controller, keyboardType, validator,
      decoration: InputDecoration(suffixText, filled, fillColor, border radius 12)))

TEST: App launches → Login screen with gradient. Connect button shows loading.
After "connect" → profile setup. Fill form → validates → saves → main screen placeholder.
Second launch: login → straight to main (profile already saved).
```

---

### STAGE 3 — Main Shell + History + Session Detail

```
Build Stage 3 of the SwimTrack app.

services/database_service.dart:
  Singleton class. initDatabase() opens swimtrack.db, creates tables:
    sessions: id TEXT PK, start_time TEXT, pool_length_m INT, duration_sec INT,
              total_distance_m INT, avg_swolf REAL, avg_stroke_rate REAL
    laps: id INT PK AUTOINCREMENT, session_id TEXT, lap_number INT,
          stroke_count INT, time_seconds REAL, swolf REAL, stroke_rate REAL
    rests: id INT PK AUTOINCREMENT, session_id TEXT, start_ms INT, duration_sec REAL
  insertSession(Session): upsert session + delete/reinsert all laps and rests
  getAllSessions(): join query → List<Session> sorted startTime DESC
  getSession(String id): single session with laps and rests
  deleteSession(String id): delete rests, laps, then session row

providers/session_provider.dart:
  State: SessionState { List<Session> sessions, bool isLoading, String? error }
  On init: loadFromDatabase().
  loadFromDatabase(): set isLoading=true → db.getAllSessions() → update state.
  sync(): (will call sync_service in Stage 5, for now no-op, show SnackBar "Sync in Stage 5")
  deleteSession(String id): db.deleteSession(id) → reload.

screens/main_screen.dart:
  StatefulWidget. _currentIndex = 0.
  Scaffold:
    body: IndexedStack(index: _currentIndex, children: [HomeTab(), HistoryTab(), SettingsTab()])
    bottomNavigationBar: BottomNavigationBar(
      type: fixed, backgroundColor: Colors.white,
      selectedItemColor: SwimTrackColors.primary,
      unselectedItemColor: SwimTrackColors.textHint,
      items: [
        BottomNavigationBarItem(icon: Icons.pool, label: 'Home'),
        BottomNavigationBarItem(icon: Icons.history, label: 'History'),
        BottomNavigationBarItem(icon: Icons.settings_outlined, label: 'Settings'),
      ],
      onTap: setState _currentIndex)

Create screens/home_tab.dart: Scaffold(body: Center(Text('Home Tab — Stage 4')))
Create screens/settings_tab.dart: Scaffold(body: Center(Text('Settings Tab — Stage 5')))

widgets/session_card.dart:
  Card(color: white, radius 16, elevation 2, child: InkWell(onTap, borderRadius 16)):
  Padding 16: Row:
    Container(48x48, radius 24, color primary, child: Text('🏊', fontSize:24)) centered
    SizedBox 12
    Expanded: Column(crossAxisAxisAlignment.start):
      Row: Text(formattedDate, style:cardTitle) + Spacer + Text(formattedDuration, style:label, color:hint)
      SizedBox 4
      Text("${s.totalDistanceM}m · ${s.laps.length} laps", style:body, color:textSecondary)
    SizedBox 12
    Column(crossAxisAlignment.end):
      Text(s.avgSwolf.toStringAsFixed(1), style:sectionHeader, color:primary)
      Text("SWOLF", style:tiny, color:hint)

screens/history_tab.dart:
  AppBar: "History", actions: [IconButton(Icons.sync, onPressed: sessionProvider.sync)]
  Watch sessionProvider.
  If isLoading: ListView of 3 shimmer cards (Stage 6 will make real shimmer,
    for now: Container(height:88, margin:EdgeInsets.symmetric(vertical:6),
    decoration(color:colorDivider, radius:16)))
  If sessions empty: Center column:
    Text('🏊', fontSize:48), SizedBox(16),
    Text('No sessions yet', style:screenTitle, color:dark), SizedBox(8),
    Text('Connect your device and sync to see sessions.', style:body, color:textSecondary, textAlign:center),
    SizedBox(20),
    OutlinedButton('Go to Settings', onPressed: switch main screen to tab 2 via a callback)
  Else: RefreshIndicator(
    onRefresh: sessionProvider.sync,
    child: ListView.separated(
      padding: EdgeInsets.all(24),
      itemCount: sessions.length,
      separatorBuilder: SizedBox(height:12),
      itemBuilder: SessionCard(session: s, onTap: router.push('/session/${s.id}'))))

screens/session_detail_screen.dart:
  Receive session id from GoRouterState.pathParameters['id'].
  Load from sessionProvider.sessions or db if not found.
  If loading: Scaffold(body: Center(CircularProgressIndicator()))
  AppBar: back arrow + Text(formatDate(session.startTime)) + IconButton(Icons.delete_outline,
    onPressed: showDialog confirm → sessionProvider.deleteSession(id) → router.pop())
  Body SingleChildScrollView padding 24:
    Header row — Row of 4 (each: Text value bold primary + Text label hint tiny):
      "${s.totalDistanceM}m" Distance | formatDuration(s.durationSec) Duration |
      "${s.poolLengthM}m" Pool | "${s.laps.length}" Laps
    Divider colorDivider, SizedBox 20
    GridView.count(crossAxisCount:2, childAspectRatio:1.8, mainAxisSpacing:12, crossAxisSpacing:12):
      MetricCard("${s.avgSwolf.toStringAsFixed(1)}", "Avg SWOLF")
      MetricCard("${s.avgStrokeRate.toStringAsFixed(0)} spm", "Stroke Rate")
      MetricCard("${s.laps.fold(0,(a,b)=>a+b.strokeCount)}", "Total Strokes")
      MetricCard(formatRest(s.rests), "Rest Time")
    If laps not empty:
      SizedBox 24, Text("SWOLF per Lap", style:sectionHeader), SizedBox 12
      SwolfChart(laps: s.laps)
      SizedBox 24, Text("Lap Breakdown", style:sectionHeader), SizedBox 12
      LapTable(laps: s.laps, avgSwolf: s.avgSwolf)

widgets/metric_card.dart:
  Container(padding 12, decoration(white, radius 12, elevation 1)):
  Column(mainAxisAlignment.center):
    Text(value, style:sectionHeader, color:primary)
    SizedBox 4
    Text(label, style:tiny, color:hint)

widgets/swolf_chart.dart:
  SizedBox(height:200, child: LineChart(
    LineChartData(
      lineBarsData: [LineChartBarData(
        spots: laps.map((l)=>FlSpot(l.lapNumber.toDouble(), l.swolf)).toList(),
        color: primary, barWidth:2.5,
        dotData: FlDotData(show:true, getDotPainter: white fill primary border),
        belowBarData: BarAreaData(show:true,
          gradient: LinearGradient(colors:[primary.withOpacity(0.3), secondary.withOpacity(0.05)],
          begin:Alignment.topCenter, end:Alignment.bottomCenter)))],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles:true, reservedSize:35)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles:true, getTitlesWidget: lap number)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles:false))),
      gridData: FlGridData(show:true, drawVerticalLine:false,
        getDrawingHorizontalLine: FlLine(color:colorDivider, strokeWidth:1)))))

widgets/lap_table.dart:
  Column:
    Header row (padding 8 horizontal): # | Strokes | Time | SWOLF — each Inter 12 SemiBold colorHint
    Divider
    For each lap, index i:
      Container(color: i.isEven ? Colors.white : colorBackground,
        padding: EdgeInsets.symmetric(vertical:10, horizontal:8)):
        Row: Text(lap.lapNumber) | Text(lap.strokeCount) | Text(formatTime(lap.timeSeconds)) |
             Container(color: lap.swolf<avgSwolf?good:bad, padding 4, radius 4,
               child: Text(lap.swolf.toStringAsFixed(1), style:label, color:white))
      Divider(colorDivider, height:1)

TEST: Bottom nav works, all 3 tabs visible. History shows empty state then
mock sessions (manually insert via db or check provider init).
Tap session card → detail screen. Charts and table render. Delete works.
```

---

### STAGE 4 — Home Tab: Idle + Recording + Live Data

```
Build Stage 4 of the SwimTrack app.

providers/device_provider.dart:
  DeviceState { ConnectionStatus status, DeviceStatus? info, String? error }
  ConnectionStatus enum: disconnected, connecting, connected, error
  connect(String ssid, String password) async:
    set connecting → wifi_service.connect() (Stage 5) →
    device_api_service.getStatus() (Stage 5) → set connected+info or error
    For Stage 4: simulate success after 1s, set fake DeviceStatus.
  disconnect(): set disconnected, clear info.
  void markSessionActive(bool active): update info.sessionActive.
  bool get isSessionActive → info?.sessionActive ?? false.

providers/live_provider.dart:
  StreamProvider<LiveData?>(autoDispose):
  Watch deviceProvider.isSessionActive.
  Watch settingsProvider.simulatorMode.
  If not sessionActive → emit null, cancel timer.
  If sessionActive + simulator: Stream.periodic(1s) → mock_data_service.generateLiveData(elapsed)
  If sessionActive + real: Stream.periodic(1s) → device_api_service.getLiveData()
  On error: emit null (don't crash).

widgets/connection_status.dart:
  Watch deviceProvider.
  Row: AnimatedContainer (8px circle) + SizedBox 8 + Text
  disconnected: grey circle, "Not Connected"
  connecting: amber circle with AnimationController(vsync, 0.8s) opacity pulse, "Connecting…"
  connected: green circle, "SwimTrack · 192.168.4.1"

widgets/pool_length_selector.dart:
  StatefulWidget. Options: [25, 50, 0(custom)].
  Row of chips. Selected: ElevatedButton style primary.
  Unselected: OutlinedButton style primary border.
  "Custom" shows AlertDialog with TextField (validator: 10-100).
  Calls onChanged(int poolLength) callback.

widgets/stroke_selector.dart:
  Options: [('🏊 Free','FREESTYLE'),('↩ Back','BACKSTROKE'),
            ('🤸 Breast','BREASTSTROKE'),('🦋 Fly','BUTTERFLY')]
  Same chip style. Calls onChanged(String strokeType).

Replace screens/home_tab.dart fully:

  State: bool _isRecording (from deviceProvider.isSessionActive)
         String _selectedStroke = 'FREESTYLE'
         int _selectedPool = 25
         bool _startLoading = false
         Timer? _timer
         int _elapsedSec = 0

  Watch deviceProvider, liveProvider, sessionProvider, profileProvider, settingsProvider.

  @override Widget build:
    AnimatedSwitcher(duration:500ms, child: _isRecording ? _buildRecording() : _buildIdle())

  _buildIdle():
    Scaffold(backgroundColor: colorBackground)
    SingleChildScrollView(padding:EdgeInsets.all(24)):
      ConnectionStatus()
      SizedBox 16
      Text("Good morning, ${profile?.name ?? 'Swimmer'}! 🏊", style:cardTitle, color:dark)
      SizedBox 20
      if sessions.isNotEmpty: _buildLastSessionCard(sessions.first)
      SizedBox 20
      Text("This Week", style:sectionHeader)
      SizedBox 12
      Row: 3 MetricCards (sessions this week, distance this week, best SWOLF)
        Filter sessions where startTime is within last 7 days.
      SizedBox 28
      Text("Ready to Swim", style:sectionHeader)
      SizedBox 12
      PoolLengthSelector(selected:_selectedPool, onChanged: setState _selectedPool=v)
      SizedBox 12
      StrokeSelector(selected:_selectedStroke, onChanged: setState _selectedStroke=v)
      SizedBox 20
      ElevatedButton(
        style: full width, height 56,
        onPressed: _startLoading ? null : _startSession,
        child: _startLoading
          ? Row(mainAxisSize.min, [CircularProgressIndicator(white,20), SizedBox(8), Text("Starting…")])
          : Text("START SESSION"))

  _startSession() async:
    setState _startLoading=true.
    try:
      In simulator: await Future.delayed(1s), fakeId = "sim_${DateTime.now().millisecondsSinceEpoch}"
      Else: String id = await device_api_service.startSession(_selectedPool)
      deviceProvider.markSessionActive(true).
      WakelockPlus.enable().
      _elapsedSec = 0.
      _timer = Timer.periodic(1s, (_) => setState _elapsedSec++)
    catch: ScaffoldMessenger.showSnackBar("Could not start session")
    finally: setState _startLoading=false.

  _buildRecording():
    Scaffold(backgroundColor: colorDark)
    SafeArea(padding:24):
      Row:
        Container(8x8 red circle with AnimationController pulse)
        SizedBox 8
        Text("RECORDING", style:label, color:bad)
        Spacer
        Text(formatTimer(_elapsedSec), style:bigNumber, color:Colors.white)
      SizedBox 40
      Center: Text("${liveData?.strokeCount ?? 0}", style:hugeNumber, color:Colors.white)
      SizedBox 8
      Center: Text("$_selectedStroke 🏊", style:cardTitle, color:secondary)
      SizedBox 40
      Row(children: [Expanded(_glassCard("Lap ${liveData?.lapCount ?? 1}",
                                          "${_lapStrokes(liveData)} strokes")),
                      SizedBox(12),
                      Expanded(_glassCard("${liveData?.strokeRate.toStringAsFixed(1) ?? '--'} spm",
                                          "SWOLF: ${liveData?.currentSwolf.toStringAsFixed(1) ?? '--'}"))])
      Spacer
      ElevatedButton(
        style: full width, height 64, background colorBad,
        onPressed: _stopLoading ? null : _stopSession,
        child: _stopLoading ? CircularProgressIndicator(white) : Text("STOP SESSION"))

  _glassCard(String top, String bottom):
    Container(
      padding:16, decoration(color:Colors.white.withOpacity(0.1), radius:16,
        border: Border.all(color:Colors.white.withOpacity(0.15))):
      Column: Text(top, style:cardTitle, color:Colors.white)
               SizedBox 4
               Text(bottom, style:label, color:secondary))

  _stopSession() async:
    setState _stopLoading=true.
    _timer?.cancel().
    try:
      String id.
      In simulator: id = "sim_done_${DateTime.now().ms}", generate a fake session, insertSession.
      Else: id = await device_api_service.stopSession()
            Session full = await device_api_service.getSession(id)
            await db.insertSession(full)
            await sessionProvider.loadFromDatabase()
      deviceProvider.markSessionActive(false).
      WakelockPlus.disable().
      router.push('/session/$id')
    catch: SnackBar "Could not stop session."
    finally: setState _stopLoading=false.

  _lapStrokes(LiveData? d): approximate strokes in current lap
    (d?.strokeCount ?? 0) ~/ max(d?.lapCount ?? 1, 1)

TEST: Home idle shows all sections. Selectors update correctly.
START SESSION button shows loading then switches to recording with dark background.
Live data increments every second (in simulator). STOP saves and goes to session detail.
```

---

### STAGE 5 — Settings + Device API + WiFi + Sync

```
Build Stage 5 of the SwimTrack app.

services/wifi_service.dart:
  connect(String ssid, String password) → Future<bool>:
    If simulator: await Future.delayed(1s), return true.
    Else: WifiForIoT.connect(ssid, password:password, security:NetworkSecurity.WPA)
    Return result.
  disconnect() → Future<void>: WifiForIoT.disconnect().
  isConnected() → Future<bool>: WifiForIoT.isConnected().

services/device_api_service.dart:
  Dio _dio = Dio(BaseOptions(baseUrl:kApiBaseUrl, connectTimeout:5s, receiveTimeout:5s))
  class DeviceException implements Exception { final String message; }

  If simulatorMode → return mock data:
    getStatus() → mock_data_service.generateDeviceStatus()
    getLiveData() → mock_data_service.generateLiveData(0)
    getSessions() → mock_data_service.generateSessions(5).map(toSummary)
    getSession(id) → find in last generated or generate new one
    startSession(n) → 'sim_${DateTime.now().ms}'
    stopSession() → 'sim_done_${DateTime.now().ms}'
    deleteSession(id) → void

  Real implementations:
    getStatus() → GET /api/status → DeviceStatus.fromJson(response.data)
    getLiveData() → GET /api/live → LiveData.fromJson(response.data)
    getSessions() → GET /api/sessions → list.map(Session.fromJson) (summary only)
    getSession(String id) → GET /api/sessions/$id → Session.fromJson(response.data)
    startSession(int poolLengthM) → POST /api/session/start body {pool_length_m:n}
      → response.data['session_id'] as String
    stopSession() → POST /api/session/stop → response.data['session_id'] as String
    deleteSession(String id) → DELETE /api/sessions/$id
  All wrap in try-catch, throw DeviceException(message) on any error.

services/sync_service.dart:
  sync() → Future<SyncResult>:
    class SyncResult { int newSessions; List<String> errors; }
    If simulator: generate 3 sessions → insertSession each → return SyncResult(3, [])
    Else:
      1. device_api_service.getSessions() → List<Session> deviceList (summaries)
      2. database_service.getAllSessions() → local ids Set
      3. For each deviceSession where id not in local:
           full = device_api_service.getSession(deviceSession.id)
           database_service.insertSession(full)
           newCount++
      Return SyncResult(newCount, errors).

Update providers/device_provider.dart connect():
  Real flow: wifi_service.connect(ssid, pass) → if true → device_api_service.getStatus()
  → set state connected + info. On any error → set state error.

Update providers/session_provider.dart sync():
  sync_service.sync() → loadFromDatabase() → return result.

Wire screens:
  history_tab sync button: sessionProvider.sync() → SnackBar "${result.newSessions} new sessions"
  history_tab RefreshIndicator: same.
  login_screen Connect button: now calls wifi_service (not fake delay) when simulator=false.

Build screens/settings_tab.dart fully:
  SingleChildScrollView padding 24:

  _sectionHeader(String text):
    Padding(bottom:8, child: Text(text.toUpperCase(), style:tiny, color:textHint,
    letterSpacing:1.2))

  PROFILE section (white card radius 16 padding 16):
    Row:
      CircleAvatar(radius:24, backgroundColor:primary,
        child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style:TextStyle(color:white, fontSize:18, fontWeight:Bold)))
      SizedBox 12
      Expanded: Column(crossAxisAlignment.start):
        Text(profile.name, style:cardTitle, color:dark)
        Text("${profile.age}yr · ${profile.heightCm}cm · ${profile.weightKg}kg",
          style:label, color:textSecondary)
      IconButton(Icons.edit_outlined, onPressed: router.push('/profile-setup'))

  SizedBox 24

  TRAINING section (white card radius 16):
    ListTile(title: Text("Pool Length", style:body),
      trailing: Row(mainAxisSize.min, [Text("${settings.poolLengthM}m", style:label,color:primary),
                                        Icon(Icons.chevron_right)]),
      onTap: showModalBottomSheet → PoolLengthSelector inside, closes on select)
    Divider(indent:16, endIndent:16, color:colorDivider)
    ListTile(title: Text("Stroke Type", style:body),
      trailing: Row(mainAxisSize.min, [Text(_strokeName, style:label,color:primary),
                                        Icon(Icons.chevron_right)]),
      onTap: showModalBottomSheet → StrokeSelector inside)

  SizedBox 24

  DEVICE section (white card radius 16 padding 16):
    ConnectionStatus widget (full row)
    if connected:
      Divider
      ListTile(leading:Icon(Icons.battery_5_bar, color:primary),
        title:Text("Battery", style:body),
        trailing:Text("${status.batteryPct}%", style:label,color:primary))
      Divider
      ListTile(title:Text("Firmware", style:body),
        trailing:Text(status.firmwareVersion, style:label,color:textHint))
      Divider
      Padding(16): Column:
        ElevatedButton("Sync Sessions", full width,
          onPressed: _syncing ? null : () async {
            setState _syncing=true
            result = await sessionProvider.sync()
            SnackBar("${result.newSessions} new sessions synced")
            setState _syncing=false })
        SizedBox 8
        OutlinedButton("Disconnect",
          style:OutlinedButton.styleFrom(foreground:colorBad, side:BorderSide(colorBad)),
          full width, onPressed: deviceProvider.disconnect())
    if disconnected:
      Padding 16: ElevatedButton("Connect to SwimTrack", full width,
        onPressed: deviceProvider.connect(kDeviceSsid, kDevicePassword))

  SizedBox 24

  APP section (white card radius 16):
    SwitchListTile("Simulator Mode",
      value: settings.simulatorMode,
      onChanged: settingsProvider.setSimulatorMode,
      activeColor: primary)
    Divider(color:colorDivider)
    ListTile(title:Text("App Version",style:body),
      trailing:Text("v1.0.0",style:label,color:textHint))

TEST: Settings all sections visible. Edit profile works (navigates, saves).
Pool/stroke bottom sheets open and update. Connect/disconnect in simulator.
Sync (simulator) → new sessions appear in History immediately.
```

---

### STAGE 6 — Polish + Error States + HTTP Fix

```
Add polish across the entire app.

1. AndroidManifest.xml HTTP fix:
   Add android:usesCleartextTraffic="true" to <application> tag.
   This is required for HTTP connections to 192.168.4.1 on Android API 28+.
   Show where this goes with a comment in the fix.

2. Loading shimmer for history_tab:
   Create widgets/shimmer_card.dart:
     StatefulWidget with AnimationController(vsync, 1.5s repeat).
     Container(height:88, margin:EdgeInsets.symmetric(vertical:6)):
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: [colorDivider, colorBackground, colorDivider],
           stops: [animation.value-0.3, animation.value, animation.value+0.3],
           begin: Alignment.centerLeft, end: Alignment.centerRight),
         borderRadius: radius 16)
   Show 3 ShimmerCard widgets while sessionProvider.isLoading.

3. Empty state for home tab (no sessions yet):
   _buildLastSessionCard when sessions.isEmpty:
     Card(dashed-style: DashedBorder or simple OutlinedBorder primary, radius 16, padding 24):
       Column center: Text('🌊',fontSize:36), SizedBox 8,
       Text("Start your first session!", style:cardTitle, color:primary),
       SizedBox 4,
       Text("Select pool and stroke above, then tap Start.", style:body, color:textSecondary)

4. Error card for session list:
   If sessionProvider.error != null:
     Container(margin:24, padding:16, decoration(red 10% opacity, radius 12)):
       Row: Icon(Icons.error_outline, red) SizedBox 8
            Expanded(Text(error, style:body, color:bad))
       SizedBox 8
       OutlinedButton("Retry", onPressed: sessionProvider.loadFromDatabase())

5. Session detail empty laps state:
   If session.laps.isEmpty:
     Center: Padding 24, Text("No lap data recorded for this session.",
               style:body, color:textHint, textAlign:center)

6. Login screen fade animation:
   Wrap the white card in FadeTransition with CurvedAnimation(300ms, Curves.easeIn).
   Initialize in initState.

7. Home idle → recording transition:
   AnimatedSwitcher already set to 500ms. Add transitionBuilder:
     FadeTransition(opacity: animation, child: child)

8. SWOLF trend direction on session card:
   Compare session.avgSwolf with previous session avgSwolf.
   if lower (improving): show "▼ X.X" in colorGood
   if higher (worse): show "▲ X.X" in colorBad
   if only one session: no arrow

9. Duration formatter helper in a utils file:
   Create lib/utils/formatters.dart:
     String formatDuration(int seconds) → "8:02" or "1:02:00" if over 1hr
     String formatTime(double seconds) → "24.3s"
     String formatDate(DateTime d) → "Wed, Mar 20" using intl DateFormat
     String formatRest(List<RestInterval> rests):
       total = rests.fold(0.0, (a,b)=>a+b.durationSec)
       return total > 0 ? "${total.toStringAsFixed(0)}s" : "—"

10. Haptic feedback on important buttons:
    HapticFeedback.mediumImpact() on START SESSION tap.
    HapticFeedback.heavyImpact() on STOP SESSION tap.
    HapticFeedback.lightImpact() on session card tap.

11. Bottom sheet polish:
    All showModalBottomSheet calls: shape RoundedRectangleBorder(topLeft:20,topRight:20),
    padding 24, header "Done" button at top right.

TEST: Check every screen for empty state. Force error in sessionProvider.
Verify HTTP fix is in place. Check animation doesn't jank.
Verify duration/date formatting everywhere is consistent.
```

---

### STAGE 7 — Documentation

```
Generate complete documentation for the SwimTrack app.

docs/README.md with all sections:

# SwimTrack App

## What It Is
Brief description. App connects to ESP32 device over WiFi.

## App Flow
The 3-screen flow diagram (ASCII, same as project instructions).

## Architecture
ASCII diagram:
  Screens → Providers → Services → Models → Device API
  Explain each layer's role in one sentence.

## Flutter Setup
1. Prerequisites: flutter --version, flutter doctor must show ✓
2. Create project: flutter create . --project-name swimtrack --org com.swimtrack
3. Replace pubspec.yaml (show the full yaml)
4. Install: flutter pub get
5. Android permissions (show the XML block)
6. HTTP fix: android:usesCleartextTraffic (show where it goes)
7. Run: flutter run

## File Structure
Complete tree with one-line description of each file (same as project instructions).

## Simulator Mode
How to enable (Settings tab toggle). What it does (no device needed).
All API calls use mock data. How to test the full flow in simulator.

## Connecting to Real Device
Step by step:
1. Power on ESP32
2. Phone WiFi → SwimTrack / swim1234
3. Open app → Login → Connect
4. Settings → Sync Sessions
5. Home → Start Session → swim → Stop

## REST API Reference
Table of all endpoints (same format as project instructions).

## SWOLF Explained
What SWOLF is: stroke_count + lap_time_seconds. Lower = better.
Why it matters for swimming training.

## Troubleshooting
| Problem | Solution |
|---------|---------|
| All API calls fail | Check usesCleartextTraffic="true" in AndroidManifest.xml |
| wifi_iot permission denied | Add all 7 permissions to AndroidManifest.xml |
| Google Fonts not loading | App needs internet on first run to download fonts |
| App shows no sessions | Open Settings → Sync Sessions |
| Connection refused | Device is not powered on or not in range |
| Login spins forever (simulator off) | Phone is not connected to SwimTrack WiFi first |
| SQLite crash on emulator | Use a physical Android device |

## Building Release APK
flutter build apk --release
Find it at: build/app/outputs/flutter-apk/app-release.apk

---

Also add doc comments to every public class and method in:
  All 5 providers: what state they hold, what each method does
  All 5 services: what each method calls and returns
  All 7 screens: what screen this is, what data it requires
  All 7 widgets: what props it accepts, what it renders

Format: /// triple-slash doc comment, one line for class, @param/@return on methods.

DELIVERABLE: Complete docs/README.md + doc comments on all files above.
```

---

## Testing Checklist After Every Stage

| Stage | Must work before continuing |
|-------|----------------------------|
| 1 | `flutter run` shows login screen placeholder, no red errors |
| 2 | Login → profile setup form → saves → main. Second launch skips profile. |
| 3 | Bottom nav switches tabs. History empty state. Tap session → detail. |
| 4 | Home idle renders. Selectors work. Recording state with live data. Stop → detail. |
| 5 | Settings all sections. Sync adds sessions. Connect/disconnect works. |
| 6 | Empty states on all screens. Error card shows. Animations smooth. |
| 7 | README exists and readable. Doc comments on all files. |

---

## Connecting to the Real ESP32 Device

The SwimTrack firmware is already built and running. When you're ready to test with real hardware:

1. Flash the ESP32 firmware (see firmware project)
2. Power on the ESP32 dev board via USB
3. On your Android phone: Settings → WiFi → connect to **SwimTrack** (password: `swim1234`)
4. Open the SwimTrack app
5. Login screen: tap **Connect** (pre-filled fields are correct)
6. Go to **Settings tab** → **Sync Sessions** to pull any saved sessions
7. Go to **Home tab** → **START SESSION** → select pool and stroke → start swimming
8. Tap **STOP SESSION** when done → session is saved locally

The device IP `192.168.4.1` is fixed and never changes. No internet connection required.
