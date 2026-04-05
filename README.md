# SwimTrack

> Wrist-worn ESP32 swim training computer with Flutter companion app.  
> Counts strokes, detects laps, calculates SWOLF — all from a single IMU sensor.

---

## Table of Contents

1. [What It Does](#what-it-does)
2. [System Architecture](#system-architecture)
3. [Hardware](#hardware)
4. [Firmware](#firmware)
5. [Mobile App](#mobile-app)
6. [WiFi REST API](#wifi-rest-api)
7. [Algorithm Reference](#algorithm-reference)
8. [Firmware Quick Start](#firmware-quick-start)
9. [App Quick Start](#app-quick-start)
10. [Configuration Reference](#configuration-reference)
11. [Serial Commands](#serial-commands)
12. [Troubleshooting](#troubleshooting)
13. [Migration to Final Hardware](#migration-to-final-hardware)
14. [Build Status](#build-status)

---

## What It Does

SwimTrack is a two-part system: a firmware running on an ESP32 wristband device, and a Flutter Android app that connects to it over WiFi.

The device straps to the wrist and runs continuously during a swim session. It uses a 6-axis IMU to detect every stroke and every lap turn, calculates SWOLF efficiency in real time, and saves the full lap-by-lap breakdown to onboard flash storage. When the swimmer finishes, the phone app connects over the device's WiFi hotspot and syncs all session data.

**SWOLF** (stroke count + lap time in seconds) is the primary metric. Lower is better. It captures both speed and efficiency in a single number, making it the standard measure of swimming technique improvement.

---

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                  ESP32 Wristband                    │
│                                                     │
│  MPU-6050/6500 IMU (50 Hz)                          │
│       │                                             │
│       ▼                                             │
│  EMA Filter (α=0.3) → accel magnitude               │
│       │                                             │
│       ├──▶  Stroke Detector ──▶ stroke count, SPM  │
│       │        (FSM: BELOW/ABOVE, 0.4g threshold)   │
│       │                                             │
│       └──▶  Lap Counter ──▶ lap count, SWOLF       │
│                (FSM: IDLE/SPIKE/GLIDE, gyro Z)      │
│                │                                    │
│                ▼                                    │
│          Session Manager                            │
│          LittleFS JSON storage                      │
│                │                                    │
│                ▼                                    │
│          WiFi SoftAP + REST API                     │
│          http://192.168.4.1                         │
└───────────────────┬─────────────────────────────────┘
                    │  HTTP/JSON over WiFi
┌───────────────────▼─────────────────────────────────┐
│               Flutter Android App                   │
│                                                     │
│  DeviceApiService (Dio HTTP client)                 │
│       │                                             │
│       ├──▶  DeviceProvider  (connection state)      │
│       ├──▶  LiveProvider    (1Hz polling /api/live) │
│       └──▶  SessionProvider (SQLite local store)    │
│                                                     │
│  Screens: Login → Profile Setup → Main (3 tabs)     │
│           Home · History · Settings                 │
│                                                     │
│  Simulator Mode: full app without physical device   │
└─────────────────────────────────────────────────────┘
```

---

## Hardware

### Components

| Component | Dev / Testing | Final Product |
|-----------|--------------|---------------|
| MCU | ESP32 30-pin dev board | ESP32-S2 WEMOS S2 Mini |
| IMU | MPU-6050 (GY-521 module) | MPU-6500 (GY-6500 module) |
| I2C SCL | GPIO 22 | GPIO 33 |
| I2C SDA | GPIO 21 | GPIO 34 |
| LED | GPIO 2 | GPIO 15 |
| WHO_AM_I | `0x68` | `0x70` |
| Battery ADC | GPIO 34 | GPIO 34 |
| Button | GPIO 0 (BOOT) | GPIO 0 (BOOT) |

### IMU Configuration

| Parameter | Setting |
|-----------|---------|
| Accelerometer range | ±8g (AFS_SEL = 2) |
| Gyroscope range | ±1000 dps (FS_SEL = 2) |
| Sample rate | 50 Hz |
| DLPF | CFG = 3 (44 Hz BW) |
| Accel sensitivity | 4096 LSB/g |
| Gyro sensitivity | 32.8 LSB/dps |
| I2C clock | 400 kHz |
| Register burst read | 14 bytes from 0x3B |

### Wiring (Dev Kit)

```
ESP32 GPIO 21 (SDA) ──── GY-521 SDA
ESP32 GPIO 22 (SCL) ──── GY-521 SCL
ESP32 3.3V          ──── GY-521 VCC
ESP32 GND           ──── GY-521 GND
```

---

## Firmware

### File Structure

```
SwimTrack_app/
├── include/
│   ├── config.h              ← All tunable constants (edit here, not in .cpp)
│   ├── mpu6500.h             ← IMU driver class
│   ├── imu_filters.h         ← EMAFilter class
│   ├── stroke_detector.h     ← StrokeDetector class
│   ├── lap_counter.h         ← LapCounter + rest detection
│   ├── session_manager.h     ← Session lifecycle + LittleFS
│   └── wifi_server.h         ← WiFi AP + REST API declarations
├── src/
│   ├── main.cpp              ← Setup, state machine, main loop
│   ├── mpu6500.cpp/.._part2  ← IMU driver implementation
│   ├── imu_filters.cpp       ← EMA filter implementation
│   ├── stroke_detector.cpp/part2  ← Stroke FSM
│   ├── lap_counter.cpp/part2 ← Lap FSM + rest detection
│   ├── session_manager.cpp/part2/part3  ← Session save/load
│   ├── wifi_server.cpp       ← SoftAP setup
│   ├── wifi_api.cpp          ← /api/sessions + start/stop handlers
│   └── wifi_live.cpp         ← /api/live handler
└── platformio.ini
```

### Build Modules

| # | Module | Status | Notes |
|---|--------|--------|-------|
| 1 | IMU Driver | ✅ | WHO_AM_I=0x68, 50.00 Hz confirmed |
| 2 | IMU Filters | ✅ | EMA α=0.3, Serial Plotter verified |
| 3 | Stroke Detector | ✅ | Manual count matches ±1 over 10 strokes |
| 4 | Lap Counter + Rest Detection | ✅ | Turn + rest confirmed |
| 5 | Session Manager + LittleFS | ✅ | JSON saved / listed / printed / deleted |
| 6 | WiFi SoftAP + REST API | ✅ | All endpoints, clients=1 confirmed |
| 7 | Web Dashboard | ✅ | Live tiles + start/stop on phone browser |
| 8 | Power Manager | ⏭ Skipped | Deferred to ESP32-S2 hardware |
| 9 | Full Integration + State Machine | ✅ | Self-test, button, 50Hz stable |
| 10 | Documentation | ✅ | docs/ complete |

### Device State Machine

```
          ┌──────────────────────┐
  Boot    │                      │ Button long press (3s)
 ──────▶  │   SELF-TEST          │ ──────────────────────▶  FULL RESET
          │   WHO_AM_I + LittleFS│
          └──────────┬───────────┘
                     │ PASS
                     ▼
          ┌──────────────────────┐  Button short press
          │                      │  or POST /api/session/start
          │   IDLE               │ ─────────────────────────────▶┐
          │   IMU running 50Hz   │                               │
          │   API available      │◀────────────────────────────┐│
          └──────────────────────┘  Button short press          ││
                                    or POST /api/session/stop   ││
                                                                ▼│
          ┌──────────────────────┐                              ││
          │                      │◀────────────────────────────┘│
          │   RECORDING          │                               │
          │   Full pipeline on   │───────────────────────────────┘
          │   Laps + strokes     │
          └──────────────────────┘
```

---

## Mobile App

### Screens

```
App Launch
    │
    ▼
LOGIN SCREEN
    Enter device WiFi credentials → tap Connect → HTTP ping to verify
    │
    ├── First time ──▶  PROFILE SETUP (name, age, height, weight, gender)
    │                        │
    │                        ▼
    └── Returning  ──▶  MAIN SCREEN (3 tabs)
                             │
                 ┌───────────┼───────────┐
                 ▼           ▼           ▼
             HOME TAB   HISTORY TAB  SETTINGS TAB
             Idle state  Session list  Profile
             Recording   Tap → Detail  Pool length
             Live metrics Lap table    Device conn.
             START/STOP  SWOLF chart   Simulator on/off
                                       Sync sessions
```

### App Architecture

```
lib/
├── config/
│   ├── theme.dart          ← SwimTrackColors, SwimTrackTextStyles
│   ├── routes.dart         ← GoRouter with auth redirect
│   └── constants.dart      ← API URL, SSID, pool defaults
├── models/
│   ├── session.dart        ← Session, Lap, RestInterval
│   ├── user_profile.dart   ← UserProfile
│   ├── device_status.dart  ← DeviceStatus
│   └── live_data.dart      ← LiveData (float-as-string parsing)
├── services/
│   ├── device_api_service.dart  ← All HTTP calls + simulator fallback
│   ├── database_service.dart    ← SQLite sessions/laps/rests
│   ├── wifi_service.dart        ← HTTP ping to verify device
│   ├── sync_service.dart        ← Device → local session sync
│   └── mock_data_service.dart   ← Fake data for simulator mode
├── providers/
│   ├── device_provider.dart     ← Connection state machine
│   ├── live_provider.dart       ← StreamProvider, 1Hz poll
│   ├── session_provider.dart    ← Load/save/delete sessions
│   ├── profile_provider.dart    ← SharedPreferences user profile
│   └── settings_provider.dart   ← Pool length + simulator toggle
├── screens/
│   ├── login_screen.dart
│   ├── profile_setup_screen.dart
│   ├── main_screen.dart         ← 3-tab shell + bottom nav
│   ├── home_tab.dart            ← Idle + recording states
│   ├── history_tab.dart         ← Session list
│   ├── session_detail_screen.dart
│   └── settings_tab.dart
└── widgets/
    ├── metric_card.dart
    ├── session_card.dart
    ├── lap_table.dart
    ├── swolf_chart.dart
    ├── connection_status.dart
    ├── stroke_selector.dart
    ├── pool_length_selector.dart
    └── shimmer_card.dart
```

### Dependencies

```yaml
flutter_riverpod: ^2.4.0    # state management
go_router: ^13.0.0           # navigation + auth redirect
dio: ^5.4.0                  # HTTP client
sqflite: ^2.3.0              # local session storage
shared_preferences: ^2.2.0   # profile + settings persistence
fl_chart: ^0.66.0            # SWOLF trend chart
google_fonts: ^6.1.0         # Poppins + Inter
intl: ^0.19.0                # date formatting
wakelock_plus: ^1.1.0        # keep screen on during session
```

### Design System

| Token | Value |
|-------|-------|
| Primary | `#0077B6` (deep ocean blue) |
| Secondary | `#00B4D8` (cyan) |
| Background | `#03045E` (deep navy) |
| Surface | `#0096C7` |
| Heading font | Poppins |
| Body font | Inter |
| Frame size | 390 × 844 (iPhone 14 equivalent) |

### Simulator Mode

Enable in Settings tab. When on, all API calls use `MockDataService` — no physical device needed. The entire app flow (start session, live metrics, stop, sync, history) works with fake data. Useful for development and demos.

---

## WiFi REST API

**SSID:** `SwimTrack`  
**Password:** `swim1234`  
**Base URL:** `http://192.168.4.1`  
**Protocol:** Plain HTTP, JSON bodies, no auth  

> Android note: `android:usesCleartextTraffic="true"` is required in `AndroidManifest.xml`.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Web dashboard (HTML) |
| GET | `/api/status` | Device state, battery, uptime |
| GET | `/api/live` | Real-time swim metrics (poll ≤ 1s) |
| GET | `/api/sessions` | Session list (summaries) |
| GET | `/api/sessions/{id}` | Full session with lap data |
| POST | `/api/session/start` | Start recording |
| POST | `/api/session/stop` | Stop and save session |
| POST | `/api/config` | Update pool length |
| DELETE | `/api/sessions/{id}` | Delete session from device |

### GET /api/status

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

### GET /api/live

```json
{
  "strokes":        14,
  "rate_spm":       "32.5",
  "stroke_type":    "FREESTYLE",
  "lap_strokes":    5,
  "laps":           2,
  "session_laps":   2,
  "resting":        false,
  "lap_elapsed_s":  "8.3",
  "swolf_est":      "21.8",
  "session_active": true
}
```

> Float fields arrive as strings from firmware (`serialized(String(value, 1))`).  
> The app parses them with `double.tryParse(v.toString())`.

### GET /api/sessions/{id}

```json
{
  "id":            12010,
  "duration_s":    "86.1",
  "pool_m":        25,
  "laps":          4,
  "total_strokes": 47,
  "total_dist_m":  100,
  "avg_swolf":     "9.7",
  "avg_spm":       "38.4",
  "lap_data": [
    { "n": 1, "t_s": "21.3", "strokes": 5, "swolf": "26.3", "spm": "14.1" }
  ],
  "rests": [
    { "start_ms": 45000, "dur_s": "12.3" }
  ]
}
```

### POST /api/session/start

```json
// Request (body optional — defaults to current device pool length)
{"pool_length_m": 25}

// Response
{"ok": true, "pool_m": 25, "id": 1234567}
```

`id` = `millis()` at start time (temporary). Use `saved_id` from the stop response to fetch the saved session.

### POST /api/session/stop

```json
// Response
{"ok": true, "saved_id": 12010}
```

---

## Algorithm Reference

### Stroke Detection

The stroke detector runs a two-state FSM on the EMA-filtered accelerometer magnitude.

```
State: BELOW
  If magnitude > baseline + STROKE_THRESHOLD_G (0.4g):
    If time since last stroke > STROKE_MIN_GAP_MS (500ms):
      → State: ABOVE, start timing

State: ABOVE
  If magnitude ≤ baseline + STROKE_THRESHOLD_G:
    → State: BELOW
    → COUNT STROKE (falling edge)
    → Update SPM circular buffer (last 5 intervals)

Baseline update:
  In BELOW state only: baseline = EMA(baseline, magnitude, α=0.02)
  Slow EMA tracks gravity, allowing threshold to adapt to wrist angle.
```

**SWOLF:** `stroke_count + lap_duration_seconds`  
Lower is better. A value of 30 means 10 strokes in 20 seconds for a 25m lap.

### Lap / Turn Detection

```
State: IDLE
  If |gyroZ| > TURN_GYRO_Z_THRESH_DPS (150 dps) for > 30ms:
    → State: SPIKE, record peak

State: SPIKE
  If gyroZ drops below threshold:
    → State: GLIDE_WAIT, start window timer

State: GLIDE_WAIT (2 second window)
  If filtered magnitude < GLIDE_ACCEL_THRESH_G (1.2g) for > 100ms:
    If time since last lap > LAP_MIN_DURATION_MS:
      → State: IDLE
      → COUNT LAP, calculate SWOLF, reset stroke counter
  If window expires without glide:
    → State: IDLE (false trigger, discard)
```

### Rest Detection

```
Every sample:
  variance = rolling 1-second variance of filtered magnitude

If variance < REST_VARIANCE_THRESH (0.05 g²) for > REST_CONFIRM_MS (5000ms):
  → resting = true

If variance > REST_VARIANCE_THRESH:
  → resting = false
```

### EMA Filter

```
filtered[n] = α × raw[n] + (1 - α) × filtered[n-1]
α = 0.3 (stroke/lap filter)
α = 0.02 (baseline tracker)
```

First sample is seeded with the raw value to avoid startup transients.

---

## Firmware Quick Start

### Prerequisites

- [VS Code](https://code.visualstudio.com/) + [PlatformIO extension](https://platformio.org/install/ide?install=vscode)
- ESP32 dev board connected via USB
- CP2102 USB driver (Windows only)

### platformio.ini

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
lib_deps =
    bblanchon/ArduinoJson@^7.0.0
board_build.filesystem = littlefs
monitor_speed = 115200
```

### Flash & Run

```bash
# First time only — upload LittleFS partition
pio run --target uploadfs

# Upload firmware
pio run --target upload

# Open serial monitor
pio device monitor
```

### Expected Boot Output

```
[SELF-TEST] SwimTrack FW v1.0.0
[SELF-TEST] IMU ... PASS (WHO_AM_I=0x68)
[SELF-TEST] LittleFS ... PASS
[SELF-TEST] ALL PASS ✓
[WIFI] AP started. SSID=SwimTrack  IP=192.168.4.1
[RATE] 50.0Hz | state=IDLE | clients=0 | heap=236088
```

---

## App Quick Start

### Prerequisites

```bash
flutter --version   # 3.x or higher
flutter doctor      # must show ✓ for Android toolchain
```

### Setup

```bash
cd C:\Dan_WS\SwimTrack_app
flutter pub get
flutter run
```

### Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

Also required on the `<application>` tag:

```xml
android:usesCleartextTraffic="true"
```

### Connecting to the Device

1. Power on the ESP32 wristband
2. On the phone: **Settings → WiFi → SwimTrack** (password: `swim1234`)
3. Open the SwimTrack app → tap **Connect**
4. App pings `/api/status` to confirm the connection
5. Navigate to **Settings → Sync Sessions** to pull sessions from the device

### Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuration Reference

All constants live in `include/config.h`. Never hardcode these in algorithm files.

### Algorithm Thresholds

| Constant | Default | Effect |
|----------|---------|--------|
| `STROKE_THRESHOLD_G` | `0.4f` | g above baseline = stroke peak |
| `STROKE_MIN_GAP_MS` | `500` | minimum ms between strokes |
| `TURN_GYRO_Z_THRESH_DPS` | `150.0f` | minimum gyro Z spike for turn |
| `TURN_SPIKE_MIN_MS` | `30` | minimum spike duration (noise rejection) |
| `TURN_GLIDE_WINDOW_MS` | `2000` | window after spike to detect glide |
| `GLIDE_ACCEL_THRESH_G` | `1.2f` | max accel during glide phase |
| `GLIDE_MIN_MS` | `100` | minimum glide duration to confirm lap |
| `LAP_MIN_DURATION_MS` | `5000` bench / `15000` pool | minimum lap time |
| `REST_VARIANCE_THRESH` | `0.05f` | g² threshold for rest detection |
| `REST_CONFIRM_MS` | `5000` | sustained low variance before rest declared |
| `EMA_ALPHA` | `0.3f` | stroke/lap filter smoothing |

> **Before pool use:** change `LAP_MIN_DURATION_MS` from `5000` (bench) to `15000` (25m pool) or `25000` (50m pool).

### Tuning Guide

| Symptom | Fix |
|---------|-----|
| Missing strokes | Decrease `STROKE_THRESHOLD_G`: `0.4` → `0.3` |
| False strokes at rest | Increase `STROKE_THRESHOLD_G`: `0.4` → `0.5` |
| Double-counting one pull | Increase `STROKE_MIN_GAP_MS`: `500` → `600` |
| False laps from arm rotation | Increase `TURN_GYRO_Z_THRESH_DPS`: `150` → `180` |
| Wall turns not detected | Decrease `TURN_GYRO_Z_THRESH_DPS`: `150` → `120` |
| Glide not confirming | Increase `GLIDE_ACCEL_THRESH_G`: `1.2` → `1.3` |

---

## Serial Commands

Connect at 115200 baud. Send single characters:

| Key | Action |
|-----|--------|
| `s` | Start session |
| `x` | Stop + save session |
| `l` | List all sessions |
| `p` | Print last session JSON |
| `d` | Delete last session |
| `r` | Reset stroke/lap counters |
| `f` | Print flash (LittleFS) info |
| `i` | Print live IMU stats |

**Button (GPIO 0):** Short press = toggle IDLE/RECORDING · Long press 3s = full reset

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|---------|
| All API calls fail silently | `usesCleartextTraffic` missing | Add `android:usesCleartextTraffic="true"` to `<application>` in `AndroidManifest.xml` |
| App shows no sessions after sync | Not connected to device WiFi | Phone WiFi → SwimTrack → then sync |
| Connection refused | Device not powered or out of range | Check ESP32 power + serial monitor for AP started message |
| Login spins forever (simulator off) | Phone not on SwimTrack network | Connect phone WiFi to SwimTrack first |
| Strokes counted when stationary | `STROKE_THRESHOLD_G` too low | Increase to `0.5` or `0.6` in `config.h` |
| False laps detected | `TURN_GYRO_Z_THRESH_DPS` too low | Increase to `180` or `200` |
| I2C Error 263 in serial | Loose wiring on GY-521 | Auto-recovers; check physical connection |
| SQLite crash on emulator | Emulator SQLite limitation | Use a physical Android device |
| Google Fonts not loading | No internet on first run | App needs internet to download fonts once |
| `multiple definition` compile error | Old main file still in src/ | Delete any `main_pX_*.cpp` files from `src/` |
| ESP32-S2 won't enter flash mode | Native USB needs manual entry | Hold BOOT, press RESET, release BOOT, then upload |

---

## Migration to Final Hardware

Five changes to move from dev kit (ESP32 + MPU-6050) to production hardware (ESP32-S2 + MPU-6500):

**`include/config.h`** — 3 changes:
```diff
- #define PIN_I2C_SCL       22
+ #define PIN_I2C_SCL       33

- #define PIN_I2C_SDA       21
+ #define PIN_I2C_SDA       34

- #define MPU_WHO_AM_I_VAL  0x68
+ #define MPU_WHO_AM_I_VAL  0x70

- #define PIN_LED            2
+ #define PIN_LED           15
```

**`src/mpu6500.cpp`** — temperature formula:
```diff
- sample.temp_c = rawTemp / 340.0f + 36.53f;   // MPU-6050
+ sample.temp_c = rawTemp / 333.87f + 21.0f;   // MPU-6500
```

**`platformio.ini`** — board target:
```diff
- board = esp32dev
+ board = wemos_s2_mini
```

All algorithm code, WiFi, LittleFS, session format, and REST API are identical between the two hardware revisions.

---

## Build Status

### Firmware

| Module | Status |
|--------|--------|
| IMU Driver (MPU-6050/6500) | ✅ |
| IMU Filters (EMA) | ✅ |
| Stroke Detector | ✅ |
| Lap Counter + Rest Detection | ✅ |
| Session Manager + LittleFS | ✅ |
| WiFi SoftAP + REST API | ✅ |
| Web Dashboard | ✅ |
| Power Manager | ⏭ Skipped (hardware v2) |
| Full Integration + State Machine | ✅ |
| Documentation | ✅ |

### App

| Stage | Module | Status |
|-------|--------|--------|
| 1 | Foundation (theme, models, mock data) | ✅ |
| 2 | Login + Profile Setup | ✅ |
| 3 | Main Shell + History + Session Detail | ✅ |
| 4 | Home Tab + Live Data | ✅ |
| 5 | Settings + Device API + Sync | ✅ |
| 6 | Polish + Fixes | ✅ |
| 7 | Documentation | ✅ |

---

## Known Limitations

- `_classifyStroke()` always returns `FREESTYLE` — gyro-based style classification not yet implemented
- Battery ADC not implemented — firmware returns stub values (100%, 4.20V)
- Session ID uses `millis()` (ms since boot) instead of a real-time clock — timestamps are relative to device boot
- `LAP_MIN_DURATION_MS` must be manually changed between bench testing and pool use
- Android 10+ blocks programmatic WiFi switching — user must connect to SwimTrack network manually before using the app

---

## Repository

**GitHub:** https://github.com/AbdelRahman-Madboly/SwimTrack_app  
**Firmware version:** v1.0.0-dev  
**App version:** v1.0.0  
**Last updated:** March 2026