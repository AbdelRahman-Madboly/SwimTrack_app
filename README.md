# SwimTrack App

> Companion Android app for the SwimTrack wrist-worn swim training device.  
> Part of the SwimTrack open-source project.

---

## Project Links

| Repository | Contents |
|------------|----------|
| **This repo** | Flutter Android app |
| [SwimTrack Firmware](https://github.com/AbdelRahman-Madboly/SwimTrack-Firmware.git) | ESP32 firmware — stroke detection, WiFi REST API |
| [SwimTrack Data Collection](https://github.com/AbdelRahman-Madboly/SwimTrack-Data_Collection.git) | ESP-NOW IMU collector + Python analysis + stroke classifier |

---

## What is SwimTrack?

SwimTrack is a wrist-worn swim training computer built around an ESP32-S2 microcontroller and an MPU-6500 IMU sensor. It detects swim strokes, counts laps, calculates SWOLF efficiency scores, and stores full session data. This app is the phone-side companion — it connects to the device over WiFi, controls sessions, syncs history, and displays real-time metrics while you swim.

**SWOLF** = strokes per lap + seconds per lap. Lower is better. It is the standard measure of swimming efficiency.

---

## What the App Does

- Connects to the SwimTrack device over its local WiFi access point
- Starts and stops recording sessions from the phone
- Displays live metrics during a session: stroke count, lap number, stroke rate, SWOLF estimate, distance per stroke, and lap elapsed time
- Syncs completed sessions from the device to the phone's local SQLite database
- Shows full session history with per-lap breakdown, SWOLF chart, and stroke rate
- Works in **Simulator Mode** without any device — useful for development and testing

---

## App Flow

```
Launch
  │
  ▼
LOGIN SCREEN
  Enter device WiFi credentials → tap Connect
  │
  ├── First launch only → PROFILE SETUP (name · age · height · weight · gender)
  │
  └── Every launch after ──────────────────────────────────────────────────────┐
                                                                               ▼
                                                                   MAIN SCREEN (3 tabs)
                                                                   │
                                                    ┌──────────────┼──────────────┐
                                                    ▼              ▼              ▼
                                                  HOME          HISTORY       SETTINGS
                                                  │              │              │
                                             Idle state:    Session list   Profile edit
                                             pool/stroke    Tap → detail   Pool length
                                             selector                      Device sync
                                             START btn                     Simulator
                                                  │
                                             Recording state:
                                             Live metrics
                                             STOP button
```

---

## Architecture

```
Screens  ──▶  Providers (Riverpod)  ──▶  Services  ──▶  Models
                                              │
                                     ┌────────┴────────┐
                                     ▼                 ▼
                              DeviceApiService    DatabaseService
                              (HTTP → ESP32)      (SQLite → phone)
```

| Layer | Files | Role |
|-------|-------|------|
| Screens | `home_tab`, `history_tab`, `settings_tab`, `session_detail_screen` | UI — what the user sees |
| Providers | `device_provider`, `live_provider`, `session_provider`, `settings_provider` | State — what the app knows |
| Services | `device_api_service`, `database_service`, `sync_service`, `wifi_service` | Data — where data comes from |
| Models | `session.dart`, `live_data.dart`, `device_status.dart` | Shapes — Dart objects with `fromJson` |

---

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.4.0 | State management |
| `go_router` | ^13.0.0 | Navigation |
| `dio` | ^5.4.0 | HTTP client for device API |
| `sqflite` | ^2.3.0 | Local session storage |
| `shared_preferences` | ^2.2.0 | Profile and settings persistence |
| `fl_chart` | ^0.66.0 | SWOLF per-lap chart |
| `wakelock_plus` | ^1.1.0 | Keep screen on during recording |
| `google_fonts` | ^6.1.0 | Poppins + Inter typography |

---

## Flutter Setup

### Prerequisites

```bash
flutter --version   # Flutter 3.x required
flutter doctor      # Android toolchain must show ✓
```

### Install and run

```bash
git clone https://github.com/AbdelRahman-Madboly/SwimTrack-app.git
cd SwimTrack-app
flutter pub get
flutter run
```

### Required Android permissions

In `android/app/src/main/AndroidManifest.xml`, the `<application>` tag must include:

```xml
android:usesCleartextTraffic="true"
```

This is required because the device serves plain HTTP on `192.168.4.1`. Without it all API calls fail silently on Android 9+.

---

## Connecting to the Real Device

1. Power on the SwimTrack device (ESP32-S2)
2. On your phone go to **WiFi Settings** → connect to `SwimTrack` (password: `swim1234`)
3. Open the app → Login screen → tap **Connect**
4. Go to **Settings** tab → tap **Sync Sessions** to pull saved sessions
5. Go to **Home** tab → select pool length and stroke → tap **START SESSION**
6. Swim. Watch the live metrics update every second.
7. Tap **STOP SESSION** → session is saved and you are taken to the detail view

> **Android 10+ note:** Android may block automatic WiFi switching. If Connect fails, manually connect to `SwimTrack` in your phone's system WiFi settings first, then return to the app.

---

## Simulator Mode

Settings tab → APP section → toggle **Simulator Mode ON**.

In simulator mode the app generates realistic fake data — no device required. All API calls use `MockDataService` internally. Live recording increments stroke count and laps over time. Sync adds three mock sessions. This is the recommended way to develop and test UI changes without hardware.

---

## REST API Reference

Base URL: `http://192.168.4.1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/status` | Device mode, battery, uptime |
| GET | `/api/live` | Real-time stroke/lap/SWOLF snapshot — poll at 1 Hz |
| GET | `/api/sessions` | List of saved session summaries |
| GET | `/api/sessions/{id}` | Full session with per-lap data |
| POST | `/api/session/start` | Body: `{"pool_length_m":25}` |
| POST | `/api/session/stop` | Saves session to device flash |
| DELETE | `/api/sessions/{id}` | Deletes a session from device |

Full API documentation is in the [Firmware README](https://github.com/AbdelRahman-Madboly/SwimTrack-Firmware.git).

---

## Battery Display

The app shows a battery icon in the recording view when the device reports `batt_pct` in `/api/live`. The battery level is only available if a **100kΩ + 100kΩ voltage divider** is wired from the LiPo positive terminal to GPIO1 on the ESP32-S2. Without the hardware circuit, the firmware returns 0% and the icon is hidden. See the Firmware README for the wiring diagram.

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| All API calls fail / connection refused | Check `usesCleartextTraffic="true"` in `AndroidManifest.xml` |
| Connect button spins forever | Phone is not connected to `SwimTrack` WiFi — connect in system settings first |
| No sessions after Sync | Ensure at least one session has been recorded and saved on the device |
| App shows data when device is not moving | Simulator Mode is ON — go to Settings and turn it off |
| DPS shows 0.00 after restart | Install the updated `database_service.dart` (v2 schema with `avg_dps`/`dps` columns) |
| Live stroke count never increases | Ensure device firmware is v2.0.0+ — older firmware left `s_state=IDLE` when started via API |
| Battery always shows 0% | Hardware voltage divider not connected — this is expected without the circuit |

---

## Known Limitations

- **No RTC:** Session timestamps are based on `millis()` since device boot, not real wall-clock time. Times shown in the app are approximate. Adding a DS3231 RTC module would fix this.
- **Android only:** The app targets Android. iOS is not supported due to `wifi_iot` plugin limitations.
- **Breaststroke / Butterfly:** The stroke classifier was trained on freestyle and backstroke only. Breaststroke and butterfly return `FREESTYLE` or `BACKSTROKE`. Pool data collection for additional strokes is planned.
- **Battery hardware required:** Battery percentage is only meaningful with the voltage divider circuit soldered.