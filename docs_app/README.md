# SwimTrack — Flutter Mobile App

> Companion app for the SwimTrack ESP32 wrist-worn swim training device.
> Connects over WiFi, syncs sessions, displays SWOLF metrics, and controls live recording.

---

## Table of Contents

1. [What It Does](#what-it-does)
2. [App Flow](#app-flow)
3. [Architecture](#architecture)
4. [Tech Stack](#tech-stack)
5. [File Structure](#file-structure)
6. [Flutter Setup](#flutter-setup)
7. [Connecting to the Real Device](#connecting-to-the-real-device)
8. [Simulator Mode](#simulator-mode)
9. [REST API Reference](#rest-api-reference)
10. [Data Models](#data-models)
11. [How to Extend the App](#how-to-extend-the-app)
12. [Build & Release](#build--release)
13. [Troubleshooting](#troubleshooting)
14. [SWOLF Explained](#swolf-explained)

---

## What It Does

SwimTrack is the Android companion app for a wrist-worn ESP32 swim training device.

- **Connects** to the device over a local WiFi access point (`SwimTrack` / `swim1234`)
- **Syncs** completed swim sessions from the device's LittleFS storage to the phone's SQLite database
- **Displays** session history with SWOLF charts and per-lap breakdowns
- **Controls** live recording — START / STOP session from the phone
- **Shows** real-time metrics during a swim (stroke count, rate, SWOLF estimate, lap time)
- **Stores** all data locally so it survives WiFi disconnection

---

## App Flow

```
┌─────────────────┐
│   1. LOGIN      │  Connect to SwimTrack WiFi → tap Connect
└────────┬────────┘
         │ First time only
         ▼
┌─────────────────┐
│  2. PROFILE     │  Name · Age · Height · Weight · Gender
└────────┬────────┘
         │ Every launch after first
         ▼
┌─────────────────────────────────────────────┐
│              3. MAIN SCREEN                 │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   HOME   │  │ HISTORY  │  │SETTINGS  │  │
│  │          │  │          │  │          │  │
│  │ Device   │  │ Session  │  │ Profile  │  │
│  │ status   │  │ list     │  │ Pool len │  │
│  │ Pool/    │  │ Tap →    │  │ Device   │  │
│  │ stroke   │  │ detail   │  │ Sync     │  │
│  │ START /  │  │          │  │ Simul.   │  │
│  │ STOP     │  │          │  │ mode     │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ SESSION DETAIL  │  SWOLF chart · Lap table · Metrics
└─────────────────┘
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        SCREENS                           │
│  LoginScreen  ProfileSetup  MainScreen  SessionDetail    │
│  HomeTab      HistoryTab    SettingsTab                  │
└─────────────────────┬────────────────────────────────────┘
                      │ watch / read
┌─────────────────────▼────────────────────────────────────┐
│                      PROVIDERS  (Riverpod)               │
│  profileProvider    settingsProvider   deviceProvider    │
│  sessionProvider    liveProvider                         │
└──────────┬──────────────────────┬────────────────────────┘
           │ call                 │ call
┌──────────▼──────────┐  ┌───────▼────────────────────────┐
│      SERVICES       │  │           SERVICES             │
│  DatabaseService    │  │  DeviceApiService  WiFiService │
│  SyncService        │  │  MockDataService               │
└──────────┬──────────┘  └───────┬────────────────────────┘
           │ returns              │ returns
┌──────────▼──────────────────────▼────────────────────────┐
│                        MODELS                            │
│  Session   Lap   RestInterval   UserProfile              │
│  DeviceStatus    LiveData       AppSettings              │
└──────────────────────────┬───────────────────────────────┘
                           │ HTTP JSON
┌──────────────────────────▼───────────────────────────────┐
│              ESP32 DEVICE  (192.168.4.1)                 │
│  GET /api/status    GET /api/live    GET /api/sessions   │
│  GET /api/sessions/{id}              POST /api/session/start│
│  POST /api/session/stop              DELETE /api/sessions/{id}│
└──────────────────────────────────────────────────────────┘
```

**Layer responsibilities:**
- **Screens** — UI only. Read from providers, call provider methods. Never call Dio directly.
- **Providers** — State management (Riverpod). Hold app state, call services.
- **Services** — All I/O (HTTP, SQLite, WiFi). Return typed models. Throw `DeviceException` on failure.
- **Models** — Pure data classes with `fromJson` / `toJson`. No business logic.

---

## Tech Stack

| Role | Package | Version |
|------|---------|---------|
| State management | `flutter_riverpod` | ^2.4.0 |
| Navigation | `go_router` | ^13.2.0 |
| HTTP client | `dio` | ^5.4.0 |
| Local database | `sqflite` | ^2.3.0 |
| Path helper | `path` | ^1.9.0 |
| Preferences | `shared_preferences` | ^2.2.3 |
| Charts | `fl_chart` | ^0.66.2 |
| Fonts | `google_fonts` | ^6.2.1 |
| Date formatting | `intl` | ^0.19.0 |
| Screen-on lock | `wakelock_plus` | ^1.1.4 |

---

## File Structure

```
lib/
├── main.dart                        App entry — ProviderScope + theme + router
│
├── config/
│   ├── theme.dart                   SwimTrackColors + SwimTrackTextStyles + swimTrackTheme()
│   ├── constants.dart               kApiBaseUrl · kDeviceSsid · kDevicePassword · kDefaultPoolLength
│   └── routes.dart                  GoRouter — all routes + redirect logic
│
├── models/
│   ├── user_profile.dart            UserProfile {name,age,heightCm,weightKg,gender} + fromJson/toJson/copyWith
│   ├── session.dart                 Session + Lap + RestInterval — matches ESP32 JSON field names exactly
│   ├── device_status.dart           DeviceStatus {mode,batteryPct,batteryV,sessionActive} + fromJson
│   └── live_data.dart               LiveData {strokeCount,lapCount,swolf_est,rate_spm,...} + fromJson
│
├── providers/
│   ├── profile_provider.dart        UserProfile? state — loadProfile / saveProfile / isFirstRun
│   ├── settings_provider.dart       AppSettings {poolLengthM, simulatorMode} — persisted in SharedPreferences
│   ├── device_provider.dart         DeviceState {status,deviceStatus} — connect/disconnect/markStarted/Stopped
│   ├── session_provider.dart        List<Session> from SQLite — loadFromDatabase/saveSession/deleteSession/sync
│   └── live_provider.dart           StreamProvider<LiveData?> — polls /api/live every 1s while recording
│
├── services/
│   ├── device_api_service.dart      All HTTP calls to ESP32 — getStatus/getLiveData/getSessions/startSession/stopSession
│   ├── database_service.dart        SQLite CRUD — sessions + laps + rests tables
│   ├── wifi_service.dart            Pings /api/status to verify device reachable (user connects WiFi manually)
│   ├── sync_service.dart            Fetch device sessions → compare with local → insert new ones
│   └── mock_data_service.dart       Generates fake sessions/liveData/status for simulator mode
│
├── screens/
│   ├── login_screen.dart            WiFi credentials form + Connect button → profile or main
│   ├── profile_setup_screen.dart    Name/age/height/weight/gender form — first run or edit
│   ├── main_screen.dart             IndexedStack with 3 tabs + custom BottomNavigationBar
│   ├── home_tab.dart                Idle state (selectors + START) / Recording state (live metrics + STOP)
│   ├── history_tab.dart             Session list with pull-to-refresh + shimmer loading + empty state
│   ├── settings_tab.dart            Profile · Training · Device · App sections
│   └── session_detail_screen.dart   SWOLF chart + metrics grid + lap table + delete dialog
│
└── widgets/
    ├── session_card.dart            Tappable session summary card (date · distance · laps · SWOLF)
    ├── metric_card.dart             Value + label card with optional trend arrow
    ├── swolf_chart.dart             fl_chart line chart — SWOLF per lap
    ├── lap_table.dart               Per-lap breakdown table with colour-coded SWOLF cells
    ├── connection_status.dart       Animated dot + connection label (grey/amber/green)
    ├── pool_length_selector.dart    25m · 50m · Custom chip row
    ├── stroke_selector.dart         Freestyle · Backstroke · Breaststroke · Butterfly chip row
    └── shimmer_card.dart            Animated loading placeholder for session list
```

---

## Flutter Setup

### Prerequisites

```bash
flutter --version   # must be 3.x
flutter doctor      # must show ✓ for Android toolchain
```

### Create project

```bash
cd C:\Dan_WS
mkdir SwimTrack_app
cd SwimTrack_app
flutter create . --project-name swimtrack --org com.swimtrack
```

### Replace pubspec.yaml

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
  go_router: ^13.2.0
  dio: ^5.4.0
  wifi_iot: ^0.3.19+1
  sqflite: ^2.3.0
  path: ^1.9.0
  shared_preferences: ^2.2.3
  fl_chart: ^0.66.2
  google_fonts: ^6.2.1
  intl: ^0.19.0
  wakelock_plus: ^1.1.4
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

### Android permissions (AndroidManifest.xml)

In `android/app/src/main/AndroidManifest.xml`, the `<application>` tag **must** have:

```xml
android:usesCleartextTraffic="true"
```

This is required because the ESP32 serves plain HTTP (not HTTPS).
Without this, all API calls fail silently on Android API 28+.

The full permissions block:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
```

### Install and run

```bash
flutter pub get
flutter run
```

---

## Connecting to the Real Device

### Step-by-step

1. **Power on** the ESP32 dev board via USB
2. On Android phone: **Settings → WiFi** → connect to `SwimTrack` (password: `swim1234`)
3. Android will warn "No internet" — tap **Stay connected** or **Use anyway**
4. Open the SwimTrack app
5. Login screen: fields are pre-filled — tap **Connect**
   - The app pings `http://192.168.4.1/api/status` to verify the device is reachable
6. You're connected — green dot shows in Settings tab and Home tab
7. Go to **Settings tab** → tap **Sync Sessions** to pull saved sessions
8. Go to **Home tab** → select pool length and stroke → tap **START SESSION**
9. Swim, then tap **STOP SESSION** → session is saved locally and appears in History

### Notes

- The device IP `192.168.4.1` is fixed and never changes
- No internet connection is needed — everything is local WiFi
- The phone may drop the SwimTrack WiFi after a few minutes if it has no internet
  → reconnect in phone WiFi settings, then re-sync

---

## Simulator Mode

Simulator mode lets you develop and test the app without the physical device.

### How to enable

1. Open the app → **Settings tab** → **APP section**
2. Toggle **Simulator Mode** ON
3. All API calls now return mock data instantly

### What it simulates

| Feature | Simulator behaviour |
|---------|-------------------|
| Connect | Instant success (no WiFi needed) |
| Sync Sessions | Generates 3 realistic fake sessions |
| START SESSION | Starts a fake session |
| STOP SESSION | Generates a fake session with realistic laps |
| Live data | Incrementing stroke count every second |
| Device status | Battery 80–95%, IDLE mode |

### Testing the full flow in simulator

1. Settings → Simulator Mode ON
2. Go to History → tap sync icon → "3 new sessions synced!"
3. Tap any session → Session Detail with SWOLF chart
4. Go to Home → tap START SESSION → recording state with counting data
5. Tap STOP SESSION → fake session saved → navigates to detail

---

## REST API Reference

All endpoints are at `http://192.168.4.1`. No authentication required.

### GET /api/status

Returns current device state.

**Response:**
```json
{
  "mode":           "IDLE",
  "session_active": false,
  "wifi_clients":   1,
  "uptime_s":       607,
  "battery_pct":    100,
  "battery_v":      4.2,
  "pool_m":         25,
  "free_heap":      235400
}
```

`mode` is `"IDLE"` or `"RECORDING"`.

---

### GET /api/live

Returns real-time swim metrics. Poll every 1 second during recording.

**Response:**
```json
{
  "strokes":        14,
  "rate_spm":       "32.5",
  "stroke_type":    "FREESTYLE",
  "lap_strokes":    5,
  "laps":           2,
  "resting":        false,
  "lap_elapsed_s":  "8.3",
  "swolf_est":      "21.8",
  "session_active": true,
  "session_laps":   2,
  "ax": "0.012", "ay": "-0.003", "az": "1.001",
  "gx": "0.01",  "gy": "0.02",   "gz": "-0.01"
}
```

> **Note:** Float values are serialized as strings by the ESP32 firmware
> (e.g. `"rate_spm": "32.5"` not `32.5`). The `LiveData.fromJson()` method
> handles both types.

---

### GET /api/sessions

Returns list of session summaries (no lap data).

**Response:**
```json
[
  {
    "id":            12010,
    "duration_s":    86.1,
    "laps":          4,
    "total_strokes": 47,
    "pool_m":        25,
    "total_dist_m":  100,
    "avg_swolf":     "9.7"
  }
]
```

---

### GET /api/sessions/{id}

Returns one full session with lap data.

**Response:**
```json
{
  "id":            12010,
  "start_ms":      1234567890,
  "end_ms":        1234567976,
  "duration_s":    "86.1",
  "pool_m":        25,
  "laps":          4,
  "total_strokes": 47,
  "total_dist_m":  100,
  "avg_swolf":     "9.7",
  "avg_spm":       "38.4",
  "lap_data": [
    {"n":1, "t_s":"21.3", "strokes":5, "swolf":"26.3", "spm":"14.1"},
    {"n":2, "t_s":"20.1", "strokes":4, "swolf":"24.1", "spm":"12.0"}
  ],
  "rests": [
    {"start_ms":45000, "dur_s":"12.3"}
  ]
}
```

> **Note:** `start_ms` is milliseconds since device boot (not Unix epoch).
> The app converts it using `DateTime.fromMillisecondsSinceEpoch(startMs)`.

---

### POST /api/session/start

Starts a new session. Resets stroke and lap counters on device.

**Request body (optional):**
```json
{"pool_length_m": 25}
```

**Response:**
```json
{"ok": true, "pool_m": 25, "id": 1234567}
```

`id` is `millis()` on device at start time. Used to fetch the session later.

---

### POST /api/session/stop

Stops the active session and saves it to LittleFS.

**Response:**
```json
{"ok": true, "saved_id": 12010}
```

`saved_id` is the permanent session ID assigned during save.

---

### DELETE /api/sessions/{id}

Deletes a session from the device's LittleFS.

**Response:**
```json
{"ok": true}
```

or

```json
{"error": "session not found"}
```

---

### POST /api/config

Updates device runtime configuration.

**Request body:**
```json
{"pool_length_m": 50}
```

**Response:**
```json
{"ok": true, "pool_m": 50}
```

---

## Data Models

### Session JSON field mapping

| App field | Device JSON field | Notes |
|-----------|-------------------|-------|
| `id` | `id` | Int on device, stored as String in app |
| `startTime` | `start_ms` | Milliseconds since device boot |
| `poolLengthM` | `pool_m` | Metres |
| `durationSec` | `duration_s` | Float string on device |
| `totalDistanceM` | `total_dist_m` | Int |
| `avgSwolf` | `avg_swolf` | Float string on device |
| `avgStrokeRate` | `avg_spm` | Float string on device |
| `laps[].lapNumber` | `lap_data[].n` | 1-based |
| `laps[].strokeCount` | `lap_data[].strokes` | Int |
| `laps[].timeSeconds` | `lap_data[].t_s` | Float string |
| `laps[].swolf` | `lap_data[].swolf` | Float string |
| `laps[].strokeRate` | `lap_data[].spm` | Float string |
| `rests[].startMs` | `rests[].start_ms` | Int |
| `rests[].durationSec` | `rests[].dur_s` | Float string |

### LiveData JSON field mapping

| App field | Device JSON field | Notes |
|-----------|-------------------|-------|
| `strokeCount` | `strokes` | Int |
| `lapCount` | `session_laps` | Int |
| `currentSwolf` | `swolf_est` | Float string |
| `strokeRate` | `rate_spm` | Float string |
| `isResting` | `resting` | Bool |
| `lapStrokes` | `lap_strokes` | Int |
| `strokeType` | `stroke_type` | String |
| `lapElapsedS` | `lap_elapsed_s` | Float string |

---

## How to Extend the App

### Adding a new API endpoint

1. Add the HTTP call in `lib/services/device_api_service.dart`
2. Add the corresponding method to the appropriate provider
3. Call from the screen

Example — adding GET /api/config:
```dart
// In device_api_service.dart
Future<Map<String, dynamic>> getConfig() async {
  if (_simulatorMode) return {'pool_length_m': 25};
  try {
    final resp = await _dio.get('/api/config');
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) { throw DeviceException(_msg(e)); }
}
```

### Adding a new screen

1. Create `lib/screens/my_new_screen.dart`
2. Add a route in `lib/config/routes.dart`
3. Navigate with `context.push('/my-new-screen')`

### Adding a new data field from firmware

1. Update the corresponding model's `fromJson()` in `lib/models/`
2. The `_d()` helper handles both numeric and string-serialized floats:
   ```dart
   static double _d(dynamic v) {
     if (v == null) return 0.0;
     if (v is num)  return v.toDouble();
     return double.tryParse(v.toString()) ?? 0.0;
   }
   ```
3. Update the SQLite schema in `database_service.dart` if persisting it

### Adding a new firmware feature to the app

The firmware sends all metrics in `/api/live` and `/api/status`. To add a new metric:

1. Check what field the firmware sends (see `wifi_live.cpp` and `wifi_server.cpp`)
2. Add the field to the appropriate model (`live_data.dart` or `device_status.dart`)
3. Display it in the UI (home_tab recording state or session detail)

### Improving stroke type detection display

The firmware sends `stroke_type` as a string in `/api/live`. Current values from `strokeTypeName()`:
- `"FREESTYLE"`, `"BACKSTROKE"`, `"BREASTSTROKE"`, `"BUTTERFLY"`, `"UNKNOWN"`

To show the stroke type in session detail, add it to the `Lap` model and save it to SQLite.

### Adding push notifications for session completion

Use `flutter_local_notifications` package. In `home_tab.dart`, after `_stopSession()` succeeds, call:
```dart
await notificationsPlugin.show(0, 'Session Complete',
  'SWOLF: ${session.avgSwolf.toStringAsFixed(1)} · ${session.totalDistanceM}m', details);
```

---

## Build & Release

### Debug build (for development)

```bash
flutter run
```

### Release APK

```bash
flutter build apk --release
```

Find the APK at:
```
build\app\outputs\flutter-apk\app-release.apk
```

Transfer to phone or install via:
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| **All API calls fail** | Add `android:usesCleartextTraffic="true"` to `<application>` in AndroidManifest.xml. Required for plain HTTP on Android API 28+. |
| **Connect shows error immediately** | Phone is not connected to SwimTrack WiFi. Go to phone Settings → WiFi → connect to SwimTrack first. |
| **"No internet" warning on phone** | Normal — tap "Stay connected". The device has no internet, only local WiFi. |
| **Google Fonts not loading** | App needs internet on first run to download Poppins/Inter fonts. After first run, fonts are cached offline. |
| **App shows 0 sessions after connect** | You haven't synced. Go to Settings tab → tap Sync Sessions. |
| **Phone drops SwimTrack WiFi** | Android auto-switches to internet WiFi. Reconnect manually in phone Settings. |
| **Live data shows strokes when stationary** | The IMU picks up small vibrations at rest. This is firmware sensitivity. Adjust `TURN_GYRO_Z_THRESH_DPS` and `GLIDE_ACCEL_THRESH_G` in `config.h`. |
| **Session start fails** | Make sure phone is still on SwimTrack WiFi. The app calls `/api/session/start` directly. |
| **SQLite crash on Android emulator** | Use a physical Android device. SQLite can have issues on some emulators. |
| **App crashes on launch** | Run `flutter clean && flutter pub get && flutter run` to clear cached builds. |
| **Sessions not appearing after sync** | Pull down to refresh in History tab, or navigate away and back. |
| **Chart shows no data** | The session has no lap data. This can happen if STOP was called before any laps completed. |

---

## SWOLF Explained

**SWOLF** = **S**troke count + time in seconds per length.

Example: 14 strokes to swim 25m in 21 seconds → SWOLF = 14 + 21 = **35**

**Lower SWOLF = more efficient swimming.**

| SWOLF range | Interpretation |
|-------------|---------------|
| < 30 | Elite level |
| 30–40 | Competitive / trained |
| 40–55 | Recreational / learning |
| > 55 | Beginner |

SWOLF is useful because it combines both speed and efficiency — you can improve SWOLF by:
- Swimming faster (fewer seconds) without adding strokes
- Using fewer strokes without slowing down
- Both at once

The app shows:
- **Avg SWOLF** per session (lower = better overall session)
- **SWOLF per lap** chart (see if you're tiring across the session)
- **SWOLF cell colour** in the lap table: 🟢 green = below session average (good lap), 🔴 red = above average (tiring lap)

---

## Design System

All colours and text styles are defined in `lib/config/theme.dart`.
**Never hardcode hex values or font sizes in widget files.**

### Colours

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#0077B6` | Buttons, active nav, app bar |
| `secondary` | `#00B4D8` | Live session accent |
| `background` | `#F8FAFE` | Screen backgrounds |
| `card` | `#FFFFFF` | Card surfaces |
| `dark` | `#1A1A2E` | Recording screen bg, headings |
| `textSecondary` | `#4A4A68` | Body text |
| `textHint` | `#8E8EA0` | Timestamps, units |
| `good` | `#2ECC71` | Improving SWOLF, success |
| `bad` | `#E74C3C` | Stop button, declining SWOLF |
| `neutral` | `#F39C12` | Warning, connecting state |
| `divider` | `#E8EDF2` | Separators |

### Text Styles

| Style | Font | Size | Weight |
|-------|------|------|--------|
| `hugeNumber` | Poppins | 64px | Bold |
| `bigNumber` | Poppins | 48px | Bold |
| `logoTitle` | Poppins | 32px | Bold |
| `screenTitle` | Poppins | 24px | SemiBold |
| `sectionHeader` | Poppins | 18px | SemiBold |
| `cardTitle` | Inter | 16px | SemiBold |
| `body` | Inter | 14px | Regular |
| `label` | Inter | 12px | Regular |
| `tiny` | Inter | 10px | Regular |

---

## Code Standards

These rules are enforced throughout the codebase:

1. **Colors from theme only** — never write `Color(0xFF...)` in widget files
2. **Text styles from theme only** — never write `fontSize:` in widget files  
3. **All API calls through `DeviceApiService`** — never call Dio directly from screens
4. **try-catch on every async call** — show user-visible error messages
5. **Three states on every screen** — loading / error / data
6. **Empty states on every list** — never show a blank screen
7. **`debugPrint` not `print`** — for development logs
8. **`const` constructors everywhere** — improves performance
9. **`withValues(alpha:)` not `withOpacity()`** — newer Flutter API

---

*SwimTrack App — built with Flutter · Riverpod · Dio · SQLite*
*Device firmware: ESP32 + MPU-6050 IMU + LittleFS + ArduinoJson*
