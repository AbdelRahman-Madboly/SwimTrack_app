# SwimTrack App — Claude Project Instructions

---

## Project Identity

**App Name:** SwimTrack
**Type:** Flutter mobile app (Android)
**Version:** 1.0.0
**Your folder:** `C:\Dan_WS\SwimTrack\app`

**What this app does:**
SwimTrack is the companion app for a wrist-worn ESP32 swim training device. The device measures stroke count, lap count, and SWOLF score using an IMU sensor. The app connects to the device over WiFi, pulls session data, stores it locally, and lets the swimmer track their progress over time. The app also allows starting and stopping a session remotely and shows live metrics while swimming.

---

## Three Screens — Keep It Simple

The app has exactly **3 main screens** in this order:

```
[1] LOGIN SCREEN
    ↓ (first time only)
[2] PROFILE SETUP SCREEN
    ↓ (every time after login)
[3] MAIN SCREEN  ←→  three tabs inside:
         Home tab      — device status, start/stop session, live view
         History tab   — list of past sessions, tap to see details
         Settings tab  — profile, pool length, device, simulator toggle
```

There is also one sub-screen:
- **Session Detail Screen** — opened from History when you tap a session card

---

## Hardware Context

The SwimTrack device (ESP32 dev board + MPU-6050 IMU) has already been built and tested. It creates a WiFi access point and serves a REST API.

**WiFi:** SSID = `SwimTrack` · Password = `swim1234`
**Device IP:** `http://192.168.4.1`
**Protocol:** Plain HTTP, JSON bodies

### REST API (fully working on the device)

| Method | Endpoint | What it returns |
|--------|----------|-----------------|
| GET | `/api/status` | `{"mode":"IDLE","battery_pct":85,"battery_v":3.92,"session_active":false,"firmware_version":"1.0.0"}` |
| GET | `/api/live` | `{"stroke_count":14,"lap_count":2,"current_swolf":42,"stroke_rate":32.5,"elapsed_sec":145,"is_resting":false}` |
| GET | `/api/sessions` | `[{"id":"12010","lap_count":4,"distance_m":100,"avg_swolf":9.7,"duration_sec":22,"start_time":"2026-03-25T10:30:00Z"}]` |
| GET | `/api/sessions/{id}` | Full session with `lap_data` array (see Data Models below) |
| POST | `/api/session/start` | Body: `{"pool_length_m":25}` → `{"status":"ok","session_id":"12345"}` |
| POST | `/api/session/stop` | → `{"status":"ok","session_id":"12345"}` |
| DELETE | `/api/sessions/{id}` | → `{"status":"ok"}` |

Full `/api/sessions/{id}` response:
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

**Important:** Android blocks plain HTTP by default. The `<application>` tag in `AndroidManifest.xml` must have `android:usesCleartextTraffic="true"`.

---

## Tech Stack

| What | Package | Version |
|------|---------|---------|
| State management | `flutter_riverpod` | ^2.4.0 |
| Navigation | `go_router` | ^13.0.0 |
| HTTP client | `dio` | ^5.4.0 |
| WiFi connect | `wifi_iot` | ^0.3.19 |
| Local database | `sqflite` | ^2.3.0 |
| Path helper | `path` | ^1.8.0 |
| Preferences | `shared_preferences` | ^2.2.0 |
| Charts | `fl_chart` | ^0.66.0 |
| Fonts | `google_fonts` | ^6.1.0 |
| Date formatting | `intl` | ^0.19.0 |
| Screen-on lock | `wakelock_plus` | ^1.1.0 |

---

## Design System

**Never hardcode colors or text styles in widgets. Always use `SwimTrackColors` and `SwimTrackTextStyles` from `config/theme.dart`.**

### Colors

| Name | Hex | Used for |
|------|-----|---------|
| `primary` | `#0077B6` | Buttons, active nav, app bar, links |
| `secondary` | `#00B4D8` | Charts accent, live session highlights |
| `background` | `#F8FAFE` | All screen backgrounds |
| `card` | `#FFFFFF` | Card backgrounds |
| `dark` | `#1A1A2E` | Live session screen background, text primary |
| `textSecondary` | `#4A4A68` | Labels, body text |
| `textHint` | `#8E8EA0` | Timestamps, units, placeholders |
| `good` | `#2ECC71` | Improving SWOLF, success states |
| `bad` | `#E74C3C` | Declining SWOLF, Stop button, errors |
| `neutral` | `#F39C12` | Unchanged metrics, warnings |
| `divider` | `#E8EDF2` | Section separators |

### Text Styles

| Name | Font | Size | Weight | Used for |
|------|------|------|--------|---------|
| `bigNumber` | Poppins | 48sp | Bold | Live stroke count, timer |
| `screenTitle` | Poppins | 24sp | SemiBold | Screen headings |
| `sectionHeader` | Poppins | 18sp | SemiBold | Section titles |
| `cardTitle` | Inter | 16sp | SemiBold | Card headings |
| `body` | Inter | 14sp | Regular | Body text |
| `label` | Inter | 12sp | Regular | Labels, units |
| `tiny` | Inter | 10sp | Regular | Timestamps, hints |

### Spacing and Shape

- Screen padding: `24px`
- Card padding: `16px`
- Gap between cards: `12px`
- Card border radius: `16px`
- Card elevation: `2`
- Card shadow: `0 2px 8px rgba(0,0,0,0.08)`
- Button height: `56px` (primary actions), `48px` (secondary)
- Button border radius: `12px`

---

## Data Models

```dart
// User profile — stored in shared_preferences
class UserProfile {
  String name;
  int age;
  int heightCm;
  int weightKg;
  String gender; // 'male', 'female', 'other'
}

// One completed swim session
class Session {
  String id;
  DateTime startTime;
  int poolLengthM;
  int durationSec;
  int totalDistanceM;
  double avgSwolf;
  double avgStrokeRate;
  List<Lap> laps;
  List<RestInterval> rests;
}

// One lap within a session
class Lap {
  int lapNumber;
  int strokeCount;
  double timeSeconds;
  double swolf;
  double strokeRate; // spm
}

// A rest period within a session
class RestInterval {
  int startMs;
  double durationSec;
}

// Device status from /api/status
class DeviceStatus {
  String mode;       // 'IDLE', 'RECORDING'
  int batteryPct;
  double batteryV;
  bool sessionActive;
  String firmwareVersion;
}

// Live data from /api/live
class LiveData {
  int strokeCount;
  int lapCount;
  double currentSwolf;
  double strokeRate;
  int elapsedSec;
  bool isResting;
}
```

---

## File Structure

```
lib/
├── main.dart                       App entry, Riverpod scope, theme, router
│
├── config/
│   ├── theme.dart                  SwimTrackColors, SwimTrackTextStyles, ThemeData
│   ├── routes.dart                 GoRouter — all routes and redirect logic
│   └── constants.dart              API_BASE_URL, DEVICE_SSID, DEVICE_PASSWORD, DEFAULT_POOL
│
├── models/
│   ├── user_profile.dart           UserProfile + fromJson/toJson/copyWith
│   ├── session.dart                Session, Lap, RestInterval + fromJson/toJson
│   ├── device_status.dart          DeviceStatus + fromJson
│   └── live_data.dart              LiveData + fromJson
│
├── services/
│   ├── device_api_service.dart     All HTTP calls — typed returns, error handling
│   ├── database_service.dart       SQLite CRUD for sessions and laps
│   ├── wifi_service.dart           wifi_iot connect/disconnect/isConnected
│   ├── sync_service.dart           WiFi → fetch → save → result
│   └── mock_data_service.dart      Fake sessions for simulator mode
│
├── providers/
│   ├── profile_provider.dart       UserProfile state + load/save from prefs
│   ├── device_provider.dart        Connection state + DeviceStatus
│   ├── session_provider.dart       Session list from SQLite + sync + delete
│   ├── live_provider.dart          Polls /api/live every 1s during session
│   └── settings_provider.dart      Pool length + simulator toggle (prefs)
│
├── screens/
│   ├── login_screen.dart           WiFi credentials + Connect button
│   ├── profile_setup_screen.dart   Name/age/height/weight/gender form
│   ├── main_screen.dart            BottomNavigationBar scaffold with 3 tabs
│   ├── home_tab.dart               Idle state + live recording state
│   ├── history_tab.dart            Session list + pull-to-refresh
│   ├── settings_tab.dart           Profile, pool, device, simulator
│   └── session_detail_screen.dart  Charts + lap table for one session
│
└── widgets/
    ├── metric_card.dart            Value + label + optional trend arrow
    ├── session_card.dart           History list item card
    ├── lap_table.dart              Per-lap data table with color-coded SWOLF
    ├── swolf_chart.dart            fl_chart line chart
    ├── connection_status.dart      Dot + status text
    ├── stroke_selector.dart        4 stroke type chip buttons
    └── pool_length_selector.dart   25m / 50m / Custom chip buttons
```

---

## Navigation and Routing

```
Route /              → LoginScreen
Route /profile-setup → ProfileSetupScreen
Route /main          → MainScreen (with bottom nav)
Route /session/:id   → SessionDetailScreen
```

**Redirect logic in GoRouter:**
- If profile has never been saved → `/` (login)
- After successful login:
  - First time (no profile) → `/profile-setup`
  - Returning user (has profile) → `/main`
- `/profile-setup` after editing profile from Settings → `/main`

---

## Providers Reference

```dart
// profileProvider — UserProfile? state
// Methods: loadProfile(), saveProfile(UserProfile), bool isFirstRun
final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>

// deviceProvider — connection + device status
// States: disconnected / connecting / connected / error
// Methods: connect(ssid, password), disconnect(), refreshStatus()
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>

// sessionProvider — List<Session> from SQLite
// Methods: loadFromDatabase(), sync(), deleteSession(id)
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>

// liveProvider — streams LiveData while recording
// Active only when deviceProvider.sessionActive == true
final liveProvider = StreamProvider<LiveData>

// settingsProvider — pool length + simulator toggle
// Methods: setPoolLength(int), setSimulatorMode(bool)
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>
```

---

## Simulator Mode

When `settingsProvider.simulatorMode == true`:
- `wifi_service.connect()` returns success immediately (no real WiFi needed)
- `device_api_service` all methods return data from `mock_data_service`
- `liveProvider` generates incrementing fake live data
- `sync_service` generates 3–5 new fake sessions and inserts them into SQLite

This lets the entire app be developed and tested without a physical device.

---

## Screen Details

### Screen 1 — Login

**Background:** Ocean blue gradient top half, white rounded card bottom half.

**Content:**
- SwimTrack logo/wordmark + "Your swim, perfected." tagline (white, top area)
- "Device Connection" section header
- TextField: Device Name (pre-filled `SwimTrack`)
- TextField: Password (pre-filled `swim1234`, obscure with eye toggle)
- "Connect" button — full width, primary color, 56px
  - Loading state: spinner inside button + "Connecting…"
  - Success: navigates to profile-setup or main
  - Error: red SnackBar + button resets to enabled
- Hint text below button: "Make sure your phone is near the SwimTrack device"

### Screen 2 — Profile Setup

**Content:**
- Title: "About You"
- Subtitle: "We use this to calculate your swim efficiency accurately."
- Fields (label above, input below, 16px gap):
  - Full Name (keyboard: name)
  - Age (keyboard: number, suffix "years", valid: 10–100)
  - Height (keyboard: number, suffix "cm", valid: 100–250)
  - Weight (keyboard: number, suffix "kg", valid: 30–200)
  - Gender: 3 segmented buttons — Male / Female / Other
- "Save & Continue" button — full width, primary, 56px
- Validation on submit: red border + helper text for empty fields
- No back button (can't go back from here on first run)
- When editing from Settings: show back button, "Save Changes" button text

### Screen 3a — Home Tab (Idle)

**Content:**
- Connection status widget (dot + text) at top
- Greeting: "Good morning, [name]! 🏊"
- Last session summary card (white card, tap does nothing here — history is for that)
- Weekly stats row: 3 equal metric_card widgets
  - Sessions this week | Distance this week | Best SWOLF this week
- "Ready to Swim" section header
- Pool length selector: chips — 25m · 50m · Custom
- Stroke type selector: chips — Freestyle 🏊 · Backstroke · Breaststroke 🤸 · Butterfly 🦋
- "START SESSION" button — full width, primary, 56px

### Screen 3a — Home Tab (Recording)

**Full dark background `#1A1A2E`. Smooth animated transition from idle.**

**Content:**
- Red pulsing dot + "RECORDING" label + timer MM:SS at top
- Huge stroke count — Poppins 64sp bold, white
- Stroke type icon + name below in `#00B4D8`
- Two side-by-side glass cards (white 10% opacity):
  - Left: Lap number + strokes this lap
  - Right: Stroke rate (spm) + current SWOLF
- "STOP SESSION" button — full width, red `#E74C3C`, 64px height
  - On tap: POST /api/session/stop → fetch full session → save to SQLite
  - Navigate to Session Detail
  - Screen transitions back to idle

### Screen 3b — History Tab

**Content:**
- AppBar: "History" title + sync icon button (top right)
- RefreshIndicator wrapping a ListView
- Each item: `session_card` widget
- Empty state: 🏊 emoji + "No sessions yet" + "Sync from your device in Settings"
- Tapping any card → Session Detail screen

### Session Detail Screen

**Content:**
- AppBar: back arrow + date as title + delete icon
- Header: distance | duration | pool length (small metric row)
- 2×2 grid: Avg SWOLF | Avg SPM | Total Strokes | Rest Time
- Section "SWOLF per Lap": `swolf_chart` (line chart, 200px height)
- Section "Lap Breakdown": `lap_table`
  - Columns: # | Strokes | Time | SWOLF
  - SWOLF cell: green background if below session avg, red if above

### Screen 3c — Settings Tab

Grouped list sections:

**PROFILE**
- Shows name, age, height, weight in a summary card
- Edit button → opens profile setup screen (update mode)

**TRAINING**
- Pool Length → bottom sheet with pool_length_selector
- Default Stroke → bottom sheet with stroke_selector

**DEVICE**
- If connected: green dot + "SwimTrack · 192.168.4.1" + battery % + firmware
  + "Sync Sessions" button + "Disconnect" button (red outline)
- If disconnected: grey dot + "Not Connected" + "Connect" button

**APP**
- Simulator Mode toggle
- App version: v1.0.0

---

## Code Standards

Follow these rules in every file without exception:

1. **Doc comment on every file** — what it does, one line at the top
2. **Doc comment on every public method** — what it does, `@param`, `@return`
3. **`const` everywhere** — use `const` constructors on every widget that allows it
4. **Colors from theme only** — never write a hex value inside a widget file
5. **Text styles from theme only** — never write fontSize or fontWeight in a widget
6. **All API calls through `device_api_service`** — never call `dio` directly from a screen
7. **try-catch on every async call** — show user-friendly messages, never crash
8. **Three states on every screen** — loading, error, and data (never skip any)
9. **Empty states everywhere** — every list screen has a proper empty state
10. **`debugPrint()` not `print()`** — for development logs only

---

## Build Prompts

Send one prompt at a time. Run `flutter run` after each. Fix all errors before the next.

---

### PROMPT 1 — Foundation: Theme, Models, Router, Mock Data

```
Set up the SwimTrack Flutter app foundation. Build all of these files completely.

config/theme.dart:
  Class SwimTrackColors with static const Color fields:
  primary=#0077B6, secondary=#00B4D8, background=#F8FAFE, card=#FFFFFF,
  dark=#1A1A2E, textSecondary=#4A4A68, textHint=#8E8EA0,
  good=#2ECC71, bad=#E74C3C, neutral=#F39C12, divider=#E8EDF2.

  Class SwimTrackTextStyles with static TextStyle fields using google_fonts:
  bigNumber (Poppins 48 bold), screenTitle (Poppins 24 semibold),
  sectionHeader (Poppins 18 semibold), cardTitle (Inter 16 semibold),
  body (Inter 14 regular), label (Inter 12 regular), tiny (Inter 10 regular).

  Function swimTrackTheme() returns ThemeData using these colors:
  scaffoldBackgroundColor=background, primary=primary, card background=card,
  AppBar: background=primary, foreground=white, elevation=0,
  ElevatedButton: primary fill, white text, height=56, radius=12.

config/constants.dart:
  const String kApiBaseUrl = 'http://192.168.4.1';
  const String kDeviceSsid = 'SwimTrack';
  const String kDevicePassword = 'swim1234';
  const int kDefaultPoolLength = 25;

config/routes.dart:
  GoRouter with named routes:
  / → LoginScreen
  /profile-setup → ProfileSetupScreen
  /main → MainScreen
  /session/:id → SessionDetailScreen
  Redirect: if profileProvider has no profile → /
  (full redirect logic added in Prompt 2 once profile_provider exists)

models/user_profile.dart: UserProfile {name, age, heightCm, weightKg, gender}
  + fromJson, toJson, copyWith.

models/session.dart: Session {id, startTime, poolLengthM, durationSec,
  totalDistanceM, avgSwolf, avgStrokeRate, List<Lap> laps, List<RestInterval> rests}
  Lap {lapNumber, strokeCount, timeSeconds, swolf, strokeRate}
  RestInterval {startMs, durationSec}
  All with fromJson/toJson.

models/device_status.dart: DeviceStatus {mode, batteryPct, batteryV,
  sessionActive, firmwareVersion} + fromJson.

models/live_data.dart: LiveData {strokeCount, lapCount, currentSwolf,
  strokeRate, elapsedSec, isResting} + fromJson.

services/mock_data_service.dart:
  generateSessions(int count) → List<Session>
  Generate realistic sessions: 4–10 laps, SWOLF 35–55, strokes 10–20 per lap,
  times 20–35s per lap, pool 25m, start times spread over last 30 days.
  generateLiveData(int elapsedSec) → LiveData with incrementing values.
  generateDeviceStatus() → DeviceStatus {mode:'IDLE', battery 75–95%.}

main.dart:
  ProviderScope → MaterialApp.router(theme: swimTrackTheme(), routerConfig: router)
  Import all config files.

TEST: flutter run. App launches. No red errors. Shows a blank LoginScreen (or placeholder).
```

---

### PROMPT 2 — Login Screen + Profile Setup + Providers

```
Build Login, Profile Setup, and the core providers.

providers/profile_provider.dart:
  State: UserProfile? (null = not set up yet)
  loadProfile(): reads JSON from shared_preferences key 'user_profile'
  saveProfile(UserProfile): serialises to JSON → shared_preferences
  bool get isFirstRun → state == null
  Auto-loads on creation. Expose as StateNotifierProvider<ProfileNotifier, UserProfile?>.

providers/settings_provider.dart:
  State: AppSettings {int poolLengthM, bool simulatorMode}
  Load from shared_preferences on create. Save on every change.
  setPoolLength(int), setSimulatorMode(bool).

Update config/routes.dart redirect:
  ref.watch(profileProvider) → if null && path != '/' → redirect '/'
  After login (handled in LoginScreen) the screen calls router.go('/profile-setup')
  or router.go('/main') based on isFirstRun.

screens/login_screen.dart:
  Background: gradient from #0077B6 (top) to #005A8E (30% down), then white.
  Top section (40% of screen height):
    SwimTrack wordmark — white, Poppins 32 bold, centered
    🌊 emoji or simple wave shape above text
    "Your swim, perfected." — white, Inter 14, 70% opacity, centered

  Bottom section (white, borderRadius 32 on top corners only, padding 28):
    Text "Connect to Device" — SwimTrackTextStyles.cardTitle, colorDark
    SizedBox 20px
    TextField: label "Device Name", controller pre-filled "SwimTrack"
      Decoration: filled=true, fillColor=#F8FAFE, radius=12, border=#E8EDF2
    SizedBox 12px
    TextField: label "Password", controller pre-filled "swim1234"
      obscureText toggle with eye icon suffix
      Same decoration as above
    SizedBox 8px
    Text "Make sure you're near your SwimTrack device" — tiny, colorHint, centered
    SizedBox 24px
    ElevatedButton "Connect": full width
      Normal: "Connect"
      Loading: CircularProgressIndicator (white, size 20) + "  Connecting…"
      Disabled while loading
    SizedBox 12px
    If error: red Container with error message text

  On Connect tap:
    Set loading=true.
    In simulator mode (watch settingsProvider): await Future.delayed(1s) → success.
    Else: attempt wifi_service.connect (added in Prompt 5 — for now just fake success).
    On success: if profileProvider.isFirstRun → router.go('/profile-setup')
                else → router.go('/main')
    On error: set errorMessage, loading=false.

screens/profile_setup_screen.dart:
  AppBar: no leading (first run) OR back arrow (edit mode from Settings).
  Title: "About You"
  Body (scrollable, padding 24):
    Text "We use this to calculate your swimming efficiency accurately."
      Inter 14, colorTextSecondary
    SizedBox 28px
    Form with GlobalKey<FormState>:

    _buildField("Full Name", nameController, TextInputType.name)
    _buildField("Age", ageController, TextInputType.number, suffix: "years")
    _buildField("Height", heightController, TextInputType.number, suffix: "cm")
    _buildField("Weight", weightController, TextInputType.number, suffix: "kg")

    SizedBox 16px
    Text "Gender" — SwimTrackTextStyles.label, colorTextSecondary
    SizedBox 8px
    SegmentedButton<String> with 3 options: Male / Female / Other
      Selected: primary fill, white text. Unselected: background, primary text.

    SizedBox 32px
    ElevatedButton "Save & Continue" (or "Save Changes"): full width
      On tap: validate form → create UserProfile → profileProvider.saveProfile()
               → router.go('/main')

  _buildField helper: Column(label Text, SizedBox 6, TextFormField with validator)
  Validators: name not empty, age 10-100, height 100-250, weight 30-200.

TEST: Launch. Login screen appears with gradient and white card. Connect button
shows loading. After "connect": profile setup appears. Fill form → saves → main.
On second launch: login → skips profile → goes straight to main.
```

---

### PROMPT 3 — Main Screen Shell + History Tab + Session Detail

```
Build the main screen structure and history flow.

screens/main_screen.dart:
  Scaffold with body: IndexedStack (keeps tabs alive):
    index 0 → HomeTab()
    index 1 → HistoryTab()
    index 2 → SettingsTab()
  BottomNavigationBar:
    type: BottomNavigationBarType.fixed
    backgroundColor: white, selectedItemColor: primary, unselectedItemColor: colorHint
    Items: Home (Icons.pool), History (Icons.history), Settings (Icons.settings_outlined)
  State: int _currentIndex. setState on tap.

providers/session_provider.dart:
  State: SessionState {List<Session> sessions, bool isLoading, bool isSyncing}
  loadFromDatabase(): database_service.getAllSessions() → update sessions, isLoading=false
  deleteSession(String id): database_service.deleteSession(id) → remove from list
  Auto-loads on creation.

services/database_service.dart:
  initDatabase(): opens swimtrack.db, creates tables:
    sessions: id TEXT PK, start_time TEXT, pool_length_m INT, duration_sec INT,
              total_distance_m INT, avg_swolf REAL, avg_stroke_rate REAL
    laps: id INTEGER PK AUTOINCREMENT, session_id TEXT, lap_number INT,
          stroke_count INT, time_seconds REAL, swolf REAL, stroke_rate REAL
    rests: id INTEGER PK AUTOINCREMENT, session_id TEXT, start_ms INT, duration_sec REAL
  insertSession(Session): upsert session row, delete+insert all laps, delete+insert all rests
  getAllSessions(): query sessions, for each load laps and rests → List<Session> sorted by date desc
  getSession(String id): single session with laps and rests
  deleteSession(String id): delete laps, rests, then session

widgets/session_card.dart:
  Card (white, radius 16, elevation 2, padding 16):
  Row:
    Left: 🏊 emoji in colored circle (primary bg, size 48)
    SizedBox 12
    Expanded column:
      Row: date formatted "Wed, Mar 20" — cardTitle, colorDark
           Spacer
           duration formatted "8:02" — label, colorHint
      SizedBox 4
      Text "${session.totalDistanceM}m · ${session.laps.length} laps" — body, colorTextSecondary
    SizedBox 12
    Column right-aligned:
      Text "${session.avgSwolf.toStringAsFixed(1)}" — sectionHeader, primary
      Text "SWOLF" — tiny, colorHint
  onTap: router.push('/session/${session.id}')

screens/history_tab.dart:
  AppBar: "History" title. Actions: IconButton(Icons.sync) → (sync, added Prompt 5)
  RefreshIndicator onRefresh: sessionProvider.sync() (added Prompt 5, for now no-op)
  Watch sessionProvider.
  If isLoading: show 3 shimmer placeholder cards (grey animated containers, same size as session_card)
  If sessions empty: Center column:
    Text "🏊" fontSize 48
    SizedBox 16
    Text "No sessions yet" — screenTitle, colorDark
    SizedBox 8
    Text "Connect your device and sync to see your sessions here." — body, colorTextSecondary
  Else: ListView.separated(
    itemCount: sessions.length, separatorBuilder: SizedBox(height:12),
    itemBuilder: SessionCard(session))

screens/session_detail_screen.dart:
  Get session id from GoRouterState. Load from sessionProvider or database.
  If loading: CircularProgressIndicator centered.

  AppBar: back arrow + formatted date title + IconButton(Icons.delete) with confirm dialog.

  Body (SingleChildScrollView, padding 24):
    Header info row (4 items in Row, each: value + label):
      Distance "${s.totalDistanceM}m" | Duration "MM:SS" | Pool "${s.poolLengthM}m" | Laps "${s.laps.length}"
    SizedBox 20

    2×2 GridView.count(crossAxisCount:2, childAspectRatio:1.8, gap:12):
      MetricCard(value: s.avgSwolf.toStringAsFixed(1), label:"Avg SWOLF")
      MetricCard(value: "${s.avgStrokeRate.toStringAsFixed(0)} spm", label:"Stroke Rate")
      MetricCard(value: "${s.totalDistanceM/25} laps", label:"Laps") // or total laps
      MetricCard(value: restTimeFormatted, label:"Rest Time")
    SizedBox 24

    If laps not empty:
      Text "SWOLF per Lap" — sectionHeader
      SizedBox 12
      SwolfChart(laps: s.laps, height: 200)
      SizedBox 24
      Text "Lap Breakdown" — sectionHeader
      SizedBox 12
      LapTable(laps: s.laps, avgSwolf: s.avgSwolf)

widgets/metric_card.dart:
  Container (white, radius 12, elevation 1, padding 12):
  Column mainAxisAlignment=center:
    Text value — SwimTrackTextStyles.sectionHeader, primary
    SizedBox 4
    Text label — SwimTrackTextStyles.tiny, colorHint

widgets/swolf_chart.dart:
  LineChart from fl_chart. Height from parameter.
  x: lap numbers 1..n. y: swolf values.
  Line: primary color, barWidth 2.5, dotData visible (white fill, primary border).
  BelowAreaData: gradient primary→secondary at 0.15 opacity.
  Left axis: swolf values. Bottom axis: "1", "2", "3" etc.
  gridData: grey dashes.

widgets/lap_table.dart:
  Column: header row + divider + data rows.
  Header: # | Strokes | Time | SWOLF — all Inter 12 semibold, colorHint.
  Each row: alternating background (white / colorBackground).
  SWOLF cell: green container if lap.swolf < avgSwolf, red if above.
  Values: Inter 12 regular.
  Divider between each row: colorDivider, 0.5px.

TEST: Bottom nav switches tabs. History shows empty state or sessions.
Tap session → detail screen. Back works. Delete with confirm works. Charts render.
```

---

### PROMPT 4 — Home Tab: Idle + Live Recording

```
Build the complete Home tab with both idle and recording states.

providers/device_provider.dart:
  DeviceState { ConnectionStatus status, DeviceStatus? deviceStatus, String? error }
  ConnectionStatus enum: disconnected, connecting, connected, error
  connect(String ssid, String password): set connecting → attempt wifi → getStatus → connected or error
  disconnect(): wifi off → set disconnected
  bool get isSessionActive → deviceStatus?.sessionActive ?? false
  void startSession(): sets deviceStatus.sessionActive = true (optimistic)
  void stopSession(): sets deviceStatus.sessionActive = false

providers/live_provider.dart:
  StreamProvider<LiveData?>:
  If simulator mode: generate fake live data every 1s using mock_data_service.generateLiveData(elapsed)
  If connected: poll GET /api/live every 1s
  If not active: emit null (stream emits empty)
  Cancel when recording stops.

widgets/connection_status.dart:
  Row: AnimatedContainer dot (8px circle) + Text
  disconnected: grey dot, "Not Connected"
  connecting: amber pulsing dot (AnimationController 0.8s repeat), "Connecting…"
  connected: green dot, "SwimTrack · 192.168.4.1"

widgets/pool_length_selector.dart:
  Row of 3 chips: "25m" | "50m" | "Custom"
  Selected: primary background, white text, radius 20.
  Unselected: colorBackground, primary text, border primary.
  "Custom" taps → AlertDialog with TextField (int input, 10-100m).
  onChanged: updates settingsProvider.poolLength.

widgets/stroke_selector.dart:
  Row of 4 chips: "🏊 Free" | "↩ Back" | "🤸 Breast" | "🦋 Fly"
  Same chip style as pool_length_selector.
  onChanged: updates local state String _selectedStroke.

screens/home_tab.dart:
  Watch deviceProvider and liveProvider.
  bool _isRecording = deviceProvider.isSessionActive.

  AnimatedSwitcher (duration 500ms):
    If !_isRecording → _buildIdleState()
    If _isRecording → _buildRecordingState()

  _buildIdleState():
    Scaffold background: colorBackground
    SingleChildScrollView padding 24:
      ConnectionStatus widget
      SizedBox 16
      Text "Good morning, ${profile?.name ?? 'Swimmer'}! 🏊" — cardTitle, colorDark
      SizedBox 20
      If sessions not empty: last session card (condensed session_card, no tap)
      SizedBox 20
      Text "This Week" — sectionHeader
      SizedBox 12
      Row of 3 MetricCards: sessions count | total distance | best SWOLF
      SizedBox 28
      Text "Start a Session" — sectionHeader
      SizedBox 12
      PoolLengthSelector
      SizedBox 12
      StrokeSelector
      SizedBox 20
      ElevatedButton "START SESSION" full width 56px:
        On tap: show loading in button → device_api_service.startSession(poolLength)
        On success: deviceProvider.startSession() → start liveProvider
        On error: SnackBar error message

  _buildRecordingState():
    Scaffold background: colorDark (animated)
    SafeArea padding 24:
      Row: red pulsing dot (8px) + SizedBox 8 + Text "RECORDING" (label, red) + Spacer + _timer
      SizedBox 40
      Center: Text "${liveData?.strokeCount ?? 0}" — 64sp Poppins bold, white
      SizedBox 8
      Center: Text "🏊 $_selectedStroke" — cardTitle, secondary color
      SizedBox 40
      Row of 2 glass cards (Container white 10% opacity, radius 16, padding 16):
        Left: Text "Lap ${liveData?.lapCount ?? 1}" — cardTitle, white
              Text "${_lapStrokes(liveData)} strokes" — label, colorHint
        Right: Text "${liveData?.strokeRate.toStringAsFixed(1) ?? '--'} spm" — cardTitle, secondary
               Text "SWOLF ${liveData?.currentSwolf.toStringAsFixed(1) ?? '--'}" — label, colorHint
      Spacer
      ElevatedButton "STOP SESSION" full width 64px, colorBad:
        On tap: loading state → device_api_service.stopSession()
        On success: save result session to SQLite via sessionProvider
                   → deviceProvider.stopSession()
                   → router.push('/session/${sessionId}')
        On error: SnackBar "Could not stop session. Try again."

  _timer: stateful countdown/countup widget using Timer.periodic every 1s.
  Starts from liveData.elapsedSec if available, else counts from 0.
  Formats as MM:SS.

  wakelock_plus: enable WakelockPlus.enable() when recording starts,
                WakelockPlus.disable() when recording stops.

TEST: Home idle shows all sections. Selectors work. Start Session button loads.
In simulator mode: recording state appears with counting data. Stop saves and navigates.
```

---

### PROMPT 5 — Settings Tab + Device Connection + Sync

```
Build Settings tab and wire real device connectivity.

services/wifi_service.dart:
  connect(String ssid, String password) → Future<bool>
    In simulator: await Future.delayed(Duration(seconds:1)), return true.
    Else: wifi_iot WifiForIoT.connect(ssid, password:password, security:NetworkSecurity.WPA)
    Return result.
  disconnect() → Future<void>: WifiForIoT.disconnect()
  isConnected() → Future<bool>: WifiForIoT.isConnected()

services/device_api_service.dart:
  Dio with baseUrl=kApiBaseUrl, connectTimeout=5s, receiveTimeout=5s.
  If simulatorMode: all methods return mock data.
  getStatus() → DeviceStatus: GET /api/status
  getLiveData() → LiveData: GET /api/live
  getSessions() → List<Session>: GET /api/sessions (summary only, no laps)
  getSession(String id) → Session: GET /api/sessions/{id} (full with laps)
  startSession(int poolLengthM) → String sessionId: POST /api/session/start
  stopSession() → String sessionId: POST /api/session/stop
  deleteSession(String id) → void: DELETE /api/sessions/{id}
  All throw DeviceException(message) on error.
  class DeviceException implements Exception { String message; }

services/sync_service.dart:
  sync() → SyncResult { int newSessions, List<String> errors }
  1. If not connected: try wifi_service.connect(kDeviceSsid, kDevicePassword)
  2. device_api_service.getSessions() → List<Session> device summaries
  3. database_service.getAllSessions() → local ids set
  4. For each device session not in local: getSession(id) → insertSession
  5. Return SyncResult(newSessions: count, errors: [])
  In simulator: generateSessions(3) and insert them.

Update deviceProvider:
  connect() now calls wifi_service.connect() then device_api_service.getStatus()

screens/settings_tab.dart:
  Scrollable SingleChildScrollView padding 24.
  Sections separated by SizedBox 24:

  _sectionHeader(String text): Padding(bottom:8, child: Text(text, style:label, color:colorHint))

  PROFILE section — white card radius 16 padding 16:
    Row: CircleAvatar (initials, primary bg, radius 24)
         SizedBox 12
         Column: Text profile.name — cardTitle
                 Text "${profile.age}yr · ${profile.heightCm}cm · ${profile.weightKg}kg" — label, hint
         Spacer
         IconButton pencil → router.push('/profile-setup') with editMode=true

  TRAINING section — white card radius 16:
    ListTile "Pool Length" + trailing "${settings.poolLengthM}m" + chevron
      → bottom sheet with PoolLengthSelector
    Divider colorDivider height 1
    ListTile "Default Stroke" + trailing "Freestyle 🏊" + chevron
      → bottom sheet with StrokeSelector

  DEVICE section — white card radius 16:
    ConnectionStatus widget (full width padding 16)
    If connected:
      Divider
      ListTile leading battery icon, title "Battery ${status.batteryPct}%",
        subtitle LinearProgressIndicator value=batteryPct/100, color by level
      Divider
      ListTile "Firmware" trailing Text status.firmwareVersion — label, hint
      Divider
      Padding 16: ElevatedButton "Sync Sessions" full width outlined style primary
        onTap: show CircularProgressIndicator overlay → sync_service.sync()
               → SnackBar "${result.newSessions} new sessions synced"
      SizedBox 8
      Padding horizontal 16: OutlinedButton "Disconnect" full width
        style: border=colorBad, foreground=colorBad
        onTap: deviceProvider.disconnect()
    If not connected:
      Padding 16: ElevatedButton "Connect to SwimTrack" full width
        onTap: deviceProvider.connect(kDeviceSsid, kDevicePassword)

  APP section — white card radius 16:
    SwitchListTile "Simulator Mode"
      value: settingsProvider.simulatorMode
      onChanged: settingsProvider.setSimulatorMode(v)
    Divider
    ListTile "App Version" trailing Text "v1.0.0" — label, hint

Wire history_tab sync icon and RefreshIndicator to sync_service.sync().

TEST: Settings all sections visible. Edit profile navigates and saves.
Pool/stroke bottom sheets work. Connect/disconnect works (simulator mode).
Sync in simulator mode adds sessions to History.
```

---

### PROMPT 6 — Empty States, Error Handling, and Polish

```
Add polish to every screen.

Empty states (add these to every screen that lists data):
  history_tab when empty:
    Column centered: "🏊" 56sp, SizedBox 16,
    "No sessions yet" screenTitle colorDark, SizedBox 8,
    "Connect your SwimTrack device and sync to get started." body colorTextSecondary, SizedBox 20,
    OutlinedButton "Go to Settings" → router.go('/main/2')  (tab index 2)

  home_tab when no sessions (no last session card):
    Card (dashed border primary, radius 16, padding 24, center):
    "🌊" 40sp, SizedBox 12,
    "Start your first session!" cardTitle primary, SizedBox 8,
    "Select your pool and stroke above, then tap Start." body colorTextSecondary

  session_detail if laps empty:
    Center Text "No lap data for this session." body colorTextSecondary

Loading shimmer (for history_tab while loading):
  Create widget shimmer_card.dart: Card same size as session_card, all content
  replaced with AnimatedContainer that cycles from colorDivider to colorBackground.
  Use in history_tab when sessionProvider.isLoading == true.

Error handling throughout:
  Create widget error_card.dart: Card red-tinted background, icon, message, retry button.
  Use in history_tab if sessionProvider has an error state.
  Login screen: show inline error Container below Connect button.
  Settings sync: SnackBar with red background on failure.

Animations:
  Login screen: FadeTransition on the white card (opacity 0→1, 300ms on build).
  Home idle→recording: AnimatedSwitcher with FadeTransition 500ms.
  Session card: InkWell + add Theme.of(context).splashColor.
  Bottom nav: already has built-in animation.

HTTP fix — add to AndroidManifest.xml <application> tag:
  android:usesCleartextTraffic="true"
  (Required for plain HTTP to 192.168.4.1. Without this, all API calls fail on Android API 28+.)

Edge cases:
  Session with 1 lap: chart shows single point with large dot.
  Session SWOLF 0.0: display "--"
  Very long name in profile: truncate with ellipsis in greeting and profile card.
  Duration formatting: always show MM:SS, show HH:MM:SS if over 1 hour.
  Large lap count (50+): LapTable scrollable horizontally if needed.

TEST: Force each empty state by clearing data. Check all error messages appear correctly.
Verify usesCleartextTraffic is set (test with real device if available).
Confirm animations run at 60fps (no jank in recording transition).
```

---

### PROMPT 7 — Final Documentation

```
Generate complete app documentation.

docs/README.md with these sections:
1. Overview: what SwimTrack is, what the app does, screenshot placeholder notes
2. Architecture: ASCII diagram showing screens → providers → services → models → device
3. Flutter setup: prerequisites, create project, pubspec.yaml, android permissions,
   flutter pub get, flutter run
4. Simulator mode: how to use it, what it simulates, toggle in settings
5. Device connection: step-by-step (power ESP32 → phone WiFi → connect in app → sync)
6. REST API reference: table of all endpoints with request/response
7. File structure: the full folder tree with one-line description of each file
8. Build & release: flutter build apk --release, where to find the APK
9. Troubleshooting:
   - All API calls fail (usesCleartextTraffic missing)
   - wifi_iot permission denied (add permissions to AndroidManifest)
   - Google Fonts not loading (needs internet on first run)
   - sqflite crash (use physical device, not iOS simulator)
   - Connection refused error (device not powered on or not in range)
   - App shows no sessions (sync not done yet)

Add doc comments to all public classes and methods in:
  All provider files (what state they manage, what methods do)
  All service files (what each method calls, what it returns, what throws)
  All screen files (what screen this is, what data it needs)
  All widget files (what props it takes, how it renders)

DELIVERABLE: Complete docs/README.md. Doc comments added to all files.
```

---

## Testing After Every Prompt

| Prompt | What must work before moving on |
|--------|----------------------------------|
| 1 | App launches, no errors, blank login screen |
| 2 | Login → profile setup → main. Second launch skips profile. |
| 3 | Bottom nav works, history empty state, tap session → detail |
| 4 | Home idle renders, selectors work, recording state shows live data, stop saves |
| 5 | Settings sections visible, connect/disconnect, sync adds sessions |
| 6 | Empty states correct, errors show, animations smooth |
| 7 | README readable, doc comments on all files |

---

## Connecting to Real Device

When the ESP32 firmware is running:

1. Power on the ESP32
2. On Android phone: Settings → WiFi → connect to **SwimTrack** (password: `swim1234`)
3. Open SwimTrack app
4. Login screen: tap **Connect** (fields already pre-filled)
5. Settings tab → **Sync Sessions** to pull saved sessions
6. Home tab → **START SESSION** → swim → **STOP SESSION**

The app communicates entirely over the local WiFi network — no internet needed.
