# SwimTrack App — Complete Project Guide
## Design → Build → Ship

---

## Project Identity

**App Name:** SwimTrack  
**Tagline:** Your swim, perfected.  
**Version:** 1.0.0  
**Platform:** Android (Flutter)  
**Backend:** SwimTrack ESP32 device over WiFi (REST API at 192.168.4.1)

**One-line description:**  
> SwimTrack is a mobile companion app for the SwimTrack wrist device — it connects via WiFi to pull swim session data, tracks your performance over time, and shows you live stroke-by-stroke feedback while you train.

**Full description for Claude project:**  
> You are building the SwimTrack Flutter app. It connects to a SwimTrack ESP32 wrist device over WiFi. The device broadcasts a WiFi access point (SSID: SwimTrack, password: swim1234). The app connects, pulls session data, and displays it. All data is stored locally in SQLite. The app has three core screens: Login, Profile Setup (first run), and the Main screen. The Main screen has three tabs: Home (device dashboard + live session control), History (past sessions), and Settings. The app is simple, focused, and built for use by swimmers — big numbers, minimal text, fast interactions.

---

## App Flow (3 Screens Only)

```
┌─────────────────┐
│  1. LOGIN       │  Device SSID + password → connects to device WiFi
└────────┬────────┘
         │ First time only
         ▼
┌─────────────────┐
│  2. PROFILE     │  Name, age, height, weight, gender → saved locally
└────────┬────────┘
         │ Always after login
         ▼
┌─────────────────┐
│  3. MAIN        │  Three tabs: Home · History · Settings
│                 │
│  Home tab:      │  Device status, start/stop session, live metrics
│  History tab:   │  Past sessions list → tap for lap detail
│  Settings tab:  │  Profile, pool length, device info
└─────────────────┘
```

---

## Device API (already built on ESP32)

Connect to **SwimTrack** WiFi / `swim1234` → base URL: `http://192.168.4.1`

| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/status` | `{"mode":"IDLE","battery_pct":85,"battery_v":3.92,"session_active":false,"firmware_version":"1.0.0"}` |
| GET | `/api/live` | `{"stroke_count":14,"lap_count":2,"current_swolf":42,"stroke_rate":32.5,"elapsed_sec":145,"is_resting":false}` |
| GET | `/api/sessions` | `[{"id":"12010","lap_count":4,"distance_m":100,"avg_swolf":9.7,"duration_sec":22}]` |
| GET | `/api/sessions/{id}` | Full session with `lap_data[]` array |
| POST | `/api/session/start` | Body: `{"pool_length_m":25}` |
| POST | `/api/session/stop` | Saves and returns session id |
| DELETE | `/api/sessions/{id}` | Removes from device |

---

## Design System

| Token | Value | Use |
|-------|-------|-----|
| Primary | `#0077B6` | Buttons, active states, app bar |
| Secondary | `#00B4D8` | Live session accent, highlights |
| Background | `#F8FAFE` | Screen background |
| Card | `#FFFFFF` | Card backgrounds |
| Dark | `#1A1A2E` | Live session screen background |
| Text primary | `#1A1A2E` | Headings, numbers |
| Text secondary | `#4A4A68` | Labels, descriptions |
| Text hint | `#8E8EA0` | Timestamps, units |
| Good | `#2ECC71` | Improving SWOLF, battery ok |
| Bad | `#E74C3C` | Declining SWOLF, stop button |
| Neutral | `#F39C12` | Unchanged, warning |
| Divider | `#E8EDF2` | Separators |

| Type | Font | Size | Weight |
|------|------|------|--------|
| Big number | Poppins | 48px | Bold |
| Screen title | Poppins | 24px | SemiBold |
| Section header | Poppins | 18px | SemiBold |
| Card title | Inter | 16px | SemiBold |
| Body | Inter | 14px | Regular |
| Label | Inter | 12px | Regular |
| Tiny | Inter | 10px | Regular |

---

## PART 1 — FIGMA DESIGN (Claude Opus)

Use Claude Opus to generate Figma prompts. Send these prompts to Claude Opus one by one. Ask it to give you detailed Figma instructions — component properties, exact hex values, spacing, and layout. Then execute in Figma.

---

### Opus Prompt 1 — Design Brief and Setup Instructions

Send this to Claude Opus:

```
I am designing a mobile swimming training app called SwimTrack in Figma.
The app connects via WiFi to an ESP32 wrist device that tracks swim strokes,
laps, and SWOLF score. I need you to give me step-by-step Figma instructions
to design all screens.

App flow:
1. Login screen — user enters device WiFi name and password, taps Connect
2. Profile Setup screen — first time only, user enters name, age, height,
   weight, gender
3. Main screen with 3 tabs:
   - Home: shows device connection, battery, start/stop session button,
     live metrics during session (stroke count, laps, SWOLF, rate, timer)
   - History: list of past sessions, tap to see lap-by-lap breakdown
   - Settings: profile info, pool length picker, device info, disconnect

Design system:
- Primary: #0077B6 (ocean blue)
- Secondary: #00B4D8 (cyan)
- Background: #F8FAFE (light blue-gray)
- Cards: white, border-radius 16, shadow 0 2px 8px rgba(0,0,0,0.08)
- Text: #1A1A2E primary, #4A4A68 secondary, #8E8EA0 hint
- Good: #2ECC71, Bad: #E74C3C, Neutral: #F39C12
- Live session screen: dark background #1A1A2E
- Fonts: Poppins (headings/numbers), Inter (body/labels)
- Frame: 390 × 844 (iPhone 14)
- Screen padding: 24px, card padding: 16px, gap between cards: 12px

Start with: What color styles and text styles do I need to create in Figma first?
Then: Give me step-by-step instructions to design the Login screen.
```

---

### Opus Prompt 2 — Login Screen Design Instructions

```
Now give me detailed Figma instructions to design the SwimTrack Login screen.

This screen is the first thing users see. It should feel premium and clean.
Include:
- SwimTrack logo/wordmark at the top (wave icon + "SwimTrack" text)
- Tagline: "Your swim, perfected."
- Two input fields: Device Name (pre-filled with "SwimTrack") and Password
  (pre-filled with "swim1234", masked)
- A large primary "Connect" button
- A subtle "First time? Your device broadcasts SwimTrack WiFi." hint text below
- Status indicator: shows connecting animation after tapping Connect,
  then success (green) or error (red with retry option)

Describe:
- Exact layout with spacing values
- The wave/swimming icon style
- Input field styling (border, background, focus state)
- Button states (normal, loading, disabled)
- The connecting animation
- Error state design
- Background: should it be solid #F8FAFE or have a subtle wave/gradient?

Give me the Figma layers list and build order.
```

---

### Opus Prompt 3 — Profile Setup Screen

```
Give me detailed Figma instructions for the SwimTrack Profile Setup screen.

This appears only on first login. The user enters their swimmer profile.
Fields needed:
- Full name (text input)
- Age (number input or wheel picker)
- Gender (3 button toggle: Male / Female / Other)
- Height (with unit: cm or ft/in toggle)
- Weight (with unit: kg or lbs toggle)

Design requirements:
- Title: "Tell us about yourself" with a small subtitle:
  "We use this to calculate your swimming efficiency accurately."
- Progress indicator (1 step, so just "Step 1 of 1" or a subtle line)
- Clean form layout, one field per row
- "Save Profile" button at the bottom (primary color, full width)
- Validation: show red border + error message below field if empty on submit

Describe:
- Form field styling (label above, input below, helper text below that)
- Gender toggle button group design
- Height/weight unit toggle (pill switcher)
- How validation errors look
- Exact spacing between all elements
- What the keyboard looks like on screen (push fields up or scroll?)

Give me the complete Figma layers list.
```

---

### Opus Prompt 4 — Home Tab (Idle State)

```
Give me Figma design instructions for the Home tab of the SwimTrack main screen,
when the device is connected but NOT recording.

This tab shows:
1. Top bar: device connection status (green dot + "SwimTrack Connected"),
   battery percentage, and device battery icon
2. Swimmer profile greeting: "Good morning, [Name]! 🏊"
3. Last session summary card:
   - Date and time
   - Distance, laps, stroke type icon
   - SWOLF score with trend arrow (green down = improved, red up = declined)
   - Duration
4. Weekly stats row: 3 small cards side by side
   - Sessions this week
   - Total distance this week
   - Best SWOLF this week
5. "Start Session" section:
   - Pool length selector (25m / 50m / Custom buttons)
   - Stroke type selector (4 icons: Freestyle 🏊 Backstroke Breaststroke 🤸 Butterfly 🦋)
   - Large "START SESSION" button (primary color, full width)
6. Bottom navigation: Home (active/primary) · History · Settings

Design the START SESSION button as the most important element on the screen.
Make the pool length and stroke buttons feel like chip/tag selectors.
Show selected state vs unselected state for both selectors.

Give exact measurements, colors, spacing, and layer names.
```

---

### Opus Prompt 5 — Home Tab (Live Recording State)

```
Give me Figma design instructions for the Home tab during an ACTIVE swim session.

The screen transforms when recording starts. Design this as a separate frame.

Layout (dark background #1A1A2E):
1. Top: Back arrow (hidden), red pulsing dot + "RECORDING" label, timer MM:SS
2. MAIN METRIC (center, huge): Stroke count number — Poppins 64px bold, white
   Below it: stroke type icon + name in secondary color (#00B4D8)
3. Two side-by-side info cards (dark glass style):
   Left: Current lap number + strokes this lap
   Right: Stroke rate (spm) + current SWOLF
4. A subtle horizontal progress bar or lap tracker showing lap 2 of estimated laps
5. Full-width STOP button (red #E74C3C, large 64px height, rounded)

The experience should feel like a sports watch face — minimal, high contrast,
numbers you can glance at mid-pool.

Also design the transition animation concept: what happens visually when
the user taps START (the screen darkens, numbers appear one by one).

Describe the glass-card style for the info cards (dark semi-transparent background,
subtle border, no hard shadow).
```

---

### Opus Prompt 6 — History Tab and Session Detail

```
Design two screens:

SCREEN A — History Tab:
- AppBar: "History" title + sync icon (right)
- Pull-to-refresh indicator
- List of session cards, each showing:
  Stroke type icon (left) | Date + time | Distance | Laps | SWOLF | Duration
  Card style: white, rounded 16, subtle shadow
- Empty state: wave illustration + "No sessions yet. Start your first swim!"
- Each card is tappable → navigates to Session Detail

SCREEN B — Session Detail:
- AppBar: back arrow + date as title + delete icon (right)
- Header row: distance, duration, pool length, date
- 4 metric tiles in a 2×2 grid: Avg SWOLF, Avg SPM, Total Strokes, Rest Time
- SWOLF per Lap chart: line chart, x=lap number, y=SWOLF,
  color #0077B6, gradient fill below line to #00B4D8 at 15% opacity
- Lap Breakdown table:
  Columns: #, Style, Strokes, Time, SWOLF
  SWOLF cell: green background if below session avg, red if above
  Alternating row background for readability

Keep the History list very scannable — a swimmer should find their session
in under 3 seconds. Use large SWOLF number, small label below it.

Give exact layout, spacing, and layer structure.
```

---

### Opus Prompt 7 — Settings Tab

```
Design the Settings tab for SwimTrack.

Sections (use section headers like "DEVICE", "PROFILE", "TRAINING", "APP"):

DEVICE section:
- Status: green/grey dot + "SwimTrack" + IP 192.168.4.1
- Battery: X% with battery icon
- Firmware version: v1.0.0
- Disconnect button (outline style, red text)

PROFILE section:
- Shows: Name, Age, Height, Weight, Gender as a read-only summary card
- Edit button (pencil icon, right side) → opens profile edit modal or screen

TRAINING section:
- Pool Length: row with label + current value + chevron → picker modal (25m / 50m / custom)
- Default Stroke: row with label + current stroke icon + chevron

APP section:
- Simulator Mode: row with label + toggle switch
  (When ON, app uses fake data — no device needed)
- App version: v1.0.0

Design the settings list cells using iOS-style grouped table look
(white background, grey section headers, dividers between cells,
chevron on rows that navigate).

Make the Disconnect button look dangerous — clear red, but not the biggest
thing on screen. The user should have to deliberately look for it.
```

---

### Opus Prompt 8 — Export and Handoff Instructions

```
I have designed all SwimTrack screens in Figma. Now help me:

1. What should I name all my Figma frames for a clean handoff?
   (Naming convention for: Login, Profile Setup, Home-Idle, Home-Recording,
   History, Session-Detail, Settings)

2. How do I export each screen at 2x resolution as PNG for use in my
   Flutter project? Give me the exact Figma export steps.

3. What components should I have in my Figma component library
   (not screens, but reusable pieces) that the developer will reference?
   List the component names.

4. Write me a design spec summary I can paste into my Flutter project
   instructions that lists: all hex colors, all font sizes and weights,
   all spacing values, all border-radius values, and all shadow values.

Format the design spec as a clean table for each category.
```

---

## PART 2 — FLUTTER PROJECT SETUP

Do this before creating the Claude app project.

### Step 1 — Create the project folder

Open terminal in VSCode (Ctrl+`):

```bash
cd C:\Dan_WS\SwimTrack
mkdir app
cd app
flutter create . --project-name swimtrack --org com.swimtrack
```

### Step 2 — Create the folder structure inside lib/

```bash
cd lib
mkdir config models services providers screens widgets
```

### Step 3 — Create placeholder files

Create these empty `.dart` files (you'll fill them with Claude's code):

```
lib/
  main.dart
  config/
    theme.dart
    routes.dart
    constants.dart
  models/
    session.dart
    user_profile.dart
    device_status.dart
    live_data.dart
  services/
    device_api_service.dart
    database_service.dart
    wifi_service.dart
    sync_service.dart
    mock_data_service.dart
  providers/
    device_provider.dart
    session_provider.dart
    live_provider.dart
    settings_provider.dart
    profile_provider.dart
  screens/
    login_screen.dart
    profile_setup_screen.dart
    main_screen.dart
    home_tab.dart
    history_tab.dart
    settings_tab.dart
    session_detail_screen.dart
    live_session_screen.dart
  widgets/
    metric_card.dart
    session_card.dart
    lap_table.dart
    swolf_chart.dart
    connection_status.dart
    stroke_selector.dart
    pool_length_selector.dart
```

### Step 4 — Replace pubspec.yaml

Replace the entire contents of `pubspec.yaml` with:

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

### Step 5 — Add Android permissions

Open `android/app/src/main/AndroidManifest.xml`. Add these inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Step 6 — Install dependencies and verify

```bash
flutter pub get
flutter doctor
flutter run
```

The default counter app should appear. That means the project works.

### Step 7 — Create assets folders

```bash
mkdir assets
mkdir assets\icons
mkdir assets\images
```

Copy your Figma PNG exports into `assets/images/`:
- `01_login.png`
- `02_profile.png`
- `03_home_idle.png`
- `04_home_recording.png`
- `05_history.png`
- `06_session_detail.png`
- `07_settings.png`

---

## PART 3 — CLAUDE APP PROJECT INSTRUCTIONS

Create a new Claude project. Name it: **SwimTrack App**.

Paste this entire block as the **Project Instructions**:

---

```
You are building the SwimTrack Flutter app. Read all of this before writing any code.

APP PURPOSE:
Companion mobile app for the SwimTrack ESP32 wrist device. Connects via WiFi,
pulls swim session data, shows live metrics during sessions, stores history locally.

SIMPLICITY FIRST: This app has 3 core screens only:
1. Login screen (connect to device WiFi)
2. Profile Setup screen (first run only: name, age, height, weight, gender)
3. Main screen (3 tabs: Home, History, Settings)

APP FLOW:
  App launch → Login screen
  Login success → if first time: Profile Setup → Main screen
                → if returning: Main screen directly
  Main screen tabs: Home · History · Settings

DEVICE COMMUNICATION:
  Device WiFi: SSID="SwimTrack", password="swim1234"
  Device IP: http://192.168.4.1
  Protocol: HTTP REST, JSON bodies

  GET  /api/status   → {mode, battery_pct, battery_v, session_active, firmware_version}
  GET  /api/live     → {stroke_count, lap_count, current_swolf, stroke_rate, elapsed_sec, is_resting}
  GET  /api/sessions → [{id, lap_count, distance_m, avg_swolf, duration_sec, start_time}]
  GET  /api/sessions/{id} → {id, pool_length_m, lap_data:[{lap_number, stroke_count,
                              time_seconds, swolf, stroke_rate}], total_distance_m,
                              avg_swolf, avg_stroke_rate, duration_sec}
  POST /api/session/start  body: {pool_length_m: 25}
  POST /api/session/stop
  DELETE /api/sessions/{id}

FRAMEWORK AND PACKAGES:
  Flutter + Dart (Android only)
  flutter_riverpod: ^2.4.0  — state management
  go_router: ^13.0.0        — navigation
  dio: ^5.4.0               — HTTP client
  wifi_iot: ^0.3.19         — connect to device WiFi
  sqflite: ^2.3.0           — local session storage
  shared_preferences: ^2.2.0 — user profile + settings persistence
  fl_chart: ^0.66.0         — charts
  google_fonts: ^6.1.0      — Poppins + Inter
  intl: ^0.19.0             — date formatting
  wakelock_plus: ^1.1.0     — keep screen on during live session

DESIGN SYSTEM (enforce these — never hardcode in widgets):
  Colors (defined in config/theme.dart):
    colorPrimary    = #0077B6  (buttons, active nav, app bar)
    colorSecondary  = #00B4D8  (live session accent, highlights)
    colorBackground = #F8FAFE  (screen background)
    colorCard       = #FFFFFF  (card backgrounds)
    colorDark       = #1A1A2E  (live session background, text primary)
    colorTextSec    = #4A4A68  (labels, body text)
    colorTextHint   = #8E8EA0  (timestamps, units)
    colorGood       = #2ECC71  (improving, success)
    colorBad        = #E74C3C  (declining, stop button)
    colorNeutral    = #F39C12  (unchanged metrics)
    colorDivider    = #E8EDF2  (separators)

  Text styles (defined in config/theme.dart):
    textBigNumber:   Poppins 48px bold     — live stroke count, timer
    textScreenTitle: Poppins 24px semibold — screen headings
    textSectionHead: Poppins 18px semibold — section headers
    textCardTitle:   Inter 16px semibold   — card titles
    textBody:        Inter 14px regular    — body text
    textLabel:       Inter 12px regular    — labels, units
    textTiny:        Inter 10px regular    — timestamps, hints

  Spacing: base=8px, screen padding=24px, card padding=16px, gap=12px
  Cards: borderRadius=16, elevation=2, shadow: 0 2px 8px rgba(0,0,0,0.08)

FILE STRUCTURE:
  lib/
    main.dart
    config/
      theme.dart          — ThemeData, colors, text styles (source of truth)
      routes.dart         — GoRouter, all routes
      constants.dart      — API_BASE_URL, DEFAULT_SSID, DEFAULT_PASSWORD, DEFAULT_POOL
    models/
      session.dart        — Session, Lap, StrokeType + fromJson/toJson
      user_profile.dart   — UserProfile + fromJson/toJson
      device_status.dart  — DeviceStatus + fromJson
      live_data.dart      — LiveData + fromJson
    services/
      device_api_service.dart  — All HTTP calls, typed return values
      database_service.dart    — SQLite CRUD: insertSession, getAllSessions, getSession, deleteSession
      wifi_service.dart        — wifi_iot connect/disconnect/isConnected
      sync_service.dart        — Orchestrates WiFi connect → fetch → save → disconnect
      mock_data_service.dart   — Generates fake sessions for simulator mode
    providers/
      device_provider.dart    — Connection state, DeviceStatus, connect/disconnect methods
      session_provider.dart   — Session list from SQLite, sync, delete
      live_provider.dart      — Polls /api/live every 1s during session
      settings_provider.dart  — Pool length, simulator toggle (shared_preferences)
      profile_provider.dart   — UserProfile (shared_preferences), isFirstRun
    screens/
      login_screen.dart          — WiFi credentials form, connect button, status
      profile_setup_screen.dart  — Name, age, height, weight, gender form
      main_screen.dart           — Scaffold with BottomNavigationBar, 3 tabs
      home_tab.dart              — Idle state + live session state
      history_tab.dart           — Session list, pull-to-refresh
      settings_tab.dart          — Profile, pool, device, simulator
      session_detail_screen.dart — Charts + lap table
    widgets/
      metric_card.dart        — icon + big number + label + optional trend arrow
      session_card.dart       — History list item
      lap_table.dart          — Per-lap data table
      swolf_chart.dart        — fl_chart line chart for SWOLF
      connection_status.dart  — Dot + text widget for connection state
      stroke_selector.dart    — 4 stroke type chip buttons
      pool_length_selector.dart — 25m/50m/Custom chip buttons

DATA MODELS:
  UserProfile { String name, int age, int heightCm, int weightKg, String gender }
  Session { String id, DateTime startTime, int poolLengthM, List<Lap> laps,
            int totalDistanceM, double avgSwolf, double avgStrokeRate, int durationSec }
  Lap { int lapNumber, String strokeType, int strokeCount, double timeSeconds,
        double swolf, double strokeRate }
  DeviceStatus { String mode, int batteryPct, double batteryV,
                 bool sessionActive, String firmwareVersion }
  LiveData { int strokeCount, int lapCount, double currentSwolf,
             double strokeRate, int elapsedSec, bool isResting }

KEY PROVIDERS:
  profileProvider (StateNotifierProvider<ProfileNotifier, UserProfile?>):
    - loadProfile() from shared_preferences on app start
    - saveProfile(UserProfile) → persist + update state
    - get isFirstRun → profile == null

  deviceProvider (StateNotifierProvider<DeviceNotifier, DeviceState>):
    - DeviceState: { ConnectionStatus status, DeviceStatus? deviceStatus }
    - ConnectionStatus: disconnected / connecting / connected / error
    - connect() → wifi_service.connect() → device_api_service.getStatus()
    - disconnect() → wifi_service.disconnect()

  sessionProvider (StateNotifierProvider<SessionNotifier, List<Session>>):
    - loadFromDatabase() on app start
    - sync() → sync_service.syncAll()
    - delete(id) → db + device

  liveProvider (StreamProvider<LiveData>):
    - polls /api/live every 1 second
    - only active when session is recording

  settingsProvider (StateNotifierProvider<SettingsNotifier, AppSettings>):
    - AppSettings { int poolLengthM, bool simulatorMode }

NAVIGATION (GoRouter):
  / → LoginScreen
  /profile-setup → ProfileSetupScreen
  /main → MainScreen (with index for which tab)
  /session/:id → SessionDetailScreen

ROUTING LOGIC (in main.dart redirect):
  - Not connected → /
  - Connected + first run → /profile-setup
  - Connected + has profile → /main

SIMULATOR MODE:
  When settingsProvider.simulatorMode == true:
  - device_api_service returns mock data from mock_data_service
  - wifi_service.connect() returns success immediately
  - Useful for development without the physical device

CODE STANDARDS:
  - Every file: doc comment at top with purpose
  - Every public method: doc comment with @param and @return
  - Use const constructors everywhere possible
  - All colors and text styles from theme.dart only
  - All API calls through device_api_service only
  - Handle loading + error + empty states in every screen
  - try-catch on all async calls with user-visible error messages
  - Never use print() — use debugPrint() for development logs
```

---

## PART 4 — BUILD PROMPTS (Use in Claude App Project)

Send one prompt at a time. Run `flutter run` after each. Fix errors before continuing.

---

### PROMPT 1 — Theme, Constants, Models, and Mock Data

```
Implement the SwimTrack app foundation. Create all of these files completely:

config/theme.dart:
  Define SwimTrackColors class with all static const Color fields (colorPrimary,
  colorSecondary, colorBackground, colorCard, colorDark, colorTextSec,
  colorTextHint, colorGood, colorBad, colorNeutral, colorDivider).
  Define SwimTrackTextStyles class with all static TextStyle fields
  (textBigNumber, textScreenTitle, textSectionHead, textCardTitle,
  textBody, textLabel, textTiny) using google_fonts Poppins and Inter.
  Define SwimTrackTheme.light() returning ThemeData using these colors/styles.

config/constants.dart:
  const String API_BASE_URL = 'http://192.168.4.1';
  const String DEVICE_SSID = 'SwimTrack';
  const String DEVICE_PASSWORD = 'swim1234';
  const int DEFAULT_POOL_LENGTH = 25;

config/routes.dart:
  GoRouter with routes: / (login), /profile-setup, /main (with :tab param),
  /session/:id. Add redirect logic: if profile loaded and exists → /main,
  else if profile loaded and null → /.

models/user_profile.dart: UserProfile class with name, age, heightCm,
  weightKg, gender. fromJson/toJson. copyWith method.

models/session.dart: Session, Lap, StrokeType (enum). fromJson/toJson on both.

models/device_status.dart: DeviceStatus. fromJson.

models/live_data.dart: LiveData. fromJson.

services/mock_data_service.dart:
  generateSessions(int count) → List<Session> with realistic swim data.
  Use Random. Vary: laps 4-12, SWOLF 35-55, strokes 12-20 per lap,
  pool 25m, times 20-35s per lap. 3 different stroke types.
  generateLiveData(int elapsedSec) → LiveData with incrementing stroke count.
  generateDeviceStatus() → DeviceStatus with battery 75-95, mode IDLE.

main.dart:
  ProviderScope wrapper. MaterialApp.router with GoRouter and SwimTrackTheme.light().
  Load profile on startup to determine initial route.

TEST: flutter run → app launches with no errors. Route goes to /login.
```

---

### PROMPT 2 — Login Screen + Profile Setup Screen

```
Build the Login screen and Profile Setup screen.

providers/profile_provider.dart:
  UserProfile? state. loadProfile() reads from shared_preferences JSON.
  saveProfile(UserProfile) writes to shared_preferences. isFirstRun getter.
  Expose as StateNotifierProvider.

screens/login_screen.dart:
  Layout (background: colorBackground):
  - Top 40% of screen: Wave SVG or simple blue gradient header with
    "SwimTrack" wordmark (Poppins 32px bold, white) and "Your swim, perfected."
    (Inter 14px, white 80% opacity)
  - Bottom 60%: white card with rounded top corners (borderRadius 32 top only)
    - Section: "Device Connection"
    - TextField: Device Name (pre-filled "SwimTrack")
    - TextField: Password (pre-filled "swim1234", obscureText toggle)
    - Connect button (primary color, full width, 56px height, rounded 12)
    - Status row below button: idle/"Connecting..."/"Connected!"/"Error: try again"
    - Hint text: "Connect your phone to the SwimTrack WiFi first" (textTiny, colorHint)
  Connect button calls deviceProvider.connect(ssid, password).
  On success: if profileProvider.isFirstRun → router.go('/profile-setup')
              else → router.go('/main')
  On error: show error message, button returns to enabled state.
  Show CircularProgressIndicator inside button while connecting.

screens/profile_setup_screen.dart:
  AppBar: no back button (can't go back from here on first run)
  Title: "About You"
  Subtitle: "We use this to calculate your swim efficiency accurately."
  Form fields (label above, TextField below, 16px gap between fields):
    - Full Name (TextFormField, keyboard=name)
    - Age (TextFormField, keyboard=number, suffix "years")
    - Height (TextFormField, keyboard=number, suffix "cm")
    - Weight (TextFormField, keyboard=number, suffix "kg")
    - Gender: 3 segmented buttons (Male / Female / Other)
  Validation: all fields required. Show red border + helper text if empty on submit.
  Bottom: "Save & Continue" button (full width, primary color, 56px height).
  On save: profileProvider.saveProfile(profile) → router.go('/main').

TEST: App shows login screen. Connect button shows loading. Form validation works.
Profile setup appears on first connect. After save → main screen.
```

---

### PROMPT 3 — Main Screen Shell + History Tab + Session Detail

```
Build the main app shell and history tab.

screens/main_screen.dart:
  Scaffold with BottomNavigationBar (3 items):
    Home (Icons.pool or home icon, primary when active)
    History (Icons.list_alt)
    Settings (Icons.settings)
  Uses IndexedStack to keep all tabs alive.
  Shows home_tab, history_tab, or settings_tab based on _currentIndex.
  BottomNavigationBar style: white background, primary selected, hint unselected.

providers/session_provider.dart:
  State: List<Session>, bool isSyncing.
  loadFromDatabase() → reads all sessions from SQLite → update state.
  deleteSession(String id) → delete from db.
  On init: loadFromDatabase().

services/database_service.dart:
  initDatabase() → creates sessions table and laps table.
  insertSession(Session) → upsert (replace if exists by id).
  getAllSessions() → List<Session> sorted by startTime desc.
  getSession(String id) → Session? with laps.
  deleteSession(String id) → removes session and its laps.

widgets/session_card.dart:
  Card (white, borderRadius 16, shadow, padding 16):
  Left: stroke type icon (large emoji in colored circle)
  Center column: date/time (textLabel, colorHint) | "X laps · Xm" (textBody) | duration (textLabel)
  Right column: SWOLF number (textSectionHead, primary) | "SWOLF" label (textTiny, hint)
  Full card is tappable. Slight scale animation on tap.

screens/history_tab.dart:
  AppBar: "History" + sync icon button (calls sync if implemented, else shows coming soon)
  RefreshIndicator wrapping ListView.
  If empty: centered column with 🏊 emoji large, "No sessions yet",
    "Sync from your SwimTrack device in Settings" (textBody, colorHint)
  Else: ListView of session_card widgets, gap 12px between.
  On tap session card → router.push('/session/${session.id}')

screens/session_detail_screen.dart:
  AppBar: back arrow + date as title + delete IconButton (with confirm dialog)
  Scrollable body:
    Header card: distance | duration | pool | date in a 2x2 grid of small metrics
    Section "Per Lap Performance":
      swolf_chart (line chart, x=lap number, y=SWOLF, 200px height)
    Section "Lap Breakdown":
      lap_table widget
    If rest intervals exist: Section "Rest Periods" with duration info

widgets/swolf_chart.dart:
  LineChart from fl_chart. x=lap numbers. y=SWOLF values.
  Line color: colorPrimary. Point dots: primary with white fill.
  Gradient fill below line: primary → secondary at 15% opacity.
  Left axis: SWOLF values. Bottom axis: "Lap 1", "Lap 2" etc.
  Height: 200px.

widgets/lap_table.dart:
  Table with headers: #, Style, Strokes, Time, SWOLF.
  Alternating row backgrounds: white / colorBackground.
  SWOLF cell: colorGood background if below avg, colorBad if above. White text.
  Stroke type: emoji icon + abbreviated name.
  All text: textLabel.

TEST: Main screen shows 3 tabs. History shows empty state or mock sessions.
Tap session → detail with chart and table. Delete works with confirm dialog.
```

---

### PROMPT 4 — Home Tab (Idle + Live Session)

```
Build the Home tab in both states: idle (no session) and recording.

widgets/connection_status.dart:
  Row: animated dot (green/grey/amber) + status text.
  Dot pulses when connecting (use AnimationController).
  States: disconnected (grey, "Not Connected"), connecting (amber pulsing, "Connecting..."),
          connected (green, "SwimTrack · 192.168.4.1")

widgets/metric_card.dart:
  White card (borderRadius 12, padding 12). Flexible width.
  Column: value (textSectionHead, primary) | label (textTiny, hint).
  Optional: trend icon (▲ bad/red, ▼ good/green) next to value.

widgets/stroke_selector.dart:
  Row of 4 chips: Freestyle 🏊 | Backstroke 🔄 | Breaststroke 🤸 | Butterfly 🦋
  Selected: primary background, white text. Unselected: colorBackground, primary text.
  onChanged callback with StrokeType.

widgets/pool_length_selector.dart:
  Row of 3 chips: 25m | 50m | Custom.
  Same styling as stroke_selector.
  Custom shows a dialog with number input.

screens/home_tab.dart — IDLE STATE:
  Scaffold background: colorBackground.
  Top: connection_status widget (shows device state from deviceProvider).
  Greeting: "Good morning, [name]! 🏊" (textCardTitle). Load name from profileProvider.
  If sessions exist: show last session summary card (session_card style, condensed).
  Weekly stats row: 3 metric_cards (sessions this week, distance this week, best SWOLF).
    Calculate from sessionProvider.
  "Ready to swim" section header.
  pool_length_selector (saves to settingsProvider).
  stroke_selector (local state).
  START SESSION button (full width, 56px, primary, rounded 12):
    On tap: call device_api_service.startSession(poolLength) → set recording=true.
    If simulator mode: use mock. Show loading spinner while starting.

screens/home_tab.dart — RECORDING STATE:
  Animated transition: background fades to colorDark.
  Timer widget at top center: "MM:SS" — counts up from liveData.elapsedSec.
  Big stroke count: liveData.strokeCount in textBigNumber style, white.
  Stroke type below: icon + name in colorSecondary.
  Two side-by-side info cards (dark semi-transparent: Colors.white.withOpacity(0.1)):
    Left: "Lap X" + "X strokes this lap" (estimate from total)
    Right: "XX.X spm" stroke rate + "SWOLF: XX" current swolf
  STOP button: full width, 64px height, colorBad, white text "STOP SESSION".
    On tap: call device_api_service.stopSession() → fetch session from device
    → save to SQLite → navigate to session detail → set recording=false.

State toggle: home_tab uses bool _isRecording (from deviceProvider.sessionActive).
Smooth AnimatedSwitcher between idle and recording layouts.

providers/live_provider.dart:
  Stream that polls /api/live every 1 second when _isRecording is true.
  In simulator mode: uses mock_data_service.generateLiveData(elapsedSec).
  Stops polling when recording stops.

TEST: Home tab shows idle state. Pool/stroke selectors work. Start Session button
shows loading. Recording state shows live metrics updating. Stop saves session.
```

---

### PROMPT 5 — Settings Tab + Device Connection + Sync

```
Build the Settings tab, device connection flow, and sync service.

services/wifi_service.dart:
  connect(String ssid, String password) → Future<bool>
    Uses wifi_iot. Returns true on success.
    In simulator mode: await Future.delayed(1s), return true.
  disconnect() → Future<void>
  isConnected() → Future<bool>

services/device_api_service.dart:
  class DeviceApiService with Dio instance, base URL from constants.
  All methods return typed models or throw DeviceException.
  getStatus() → DeviceStatus
  getLiveData() → LiveData
  getSessions() → List<Session> (summary only, no lap data)
  getSession(String id) → Session (full with laps)
  startSession(int poolLengthM) → String sessionId
  stopSession() → String sessionId
  deleteSession(String id) → void
  In simulator mode: all methods return mock data from mock_data_service.
  Timeout: 5 seconds on all calls. Handle: connection refused, timeout, parse error.

services/sync_service.dart:
  sync() → SyncResult { int newSessions, int failed, List<String> errors }
  1. wifi_service.isConnected() or connect()
  2. device_api_service.getSessions() → device session list
  3. database_service.getAllSessions() → local session ids
  4. For each device session not in local: getSession(id) → insertSession()
  5. Return SyncResult
  Expose sync state via StateProvider<SyncStatus> (idle/syncing/done/error)

providers/device_provider.dart:
  State: { ConnectionStatus status, DeviceStatus? deviceStatus, String? errorMessage }
  connect(ssid, password) async → update state through connecting → connected or error
  disconnect() → wifi_service.disconnect() → state = disconnected
  refreshStatus() → device_api_service.getStatus() → update deviceStatus
  Watch for connection drops: if getLiveData throws in live_provider → set disconnected

screens/settings_tab.dart:
  Scrollable list grouped into sections using a helper widget for section headers.

  PROFILE section (white card):
    Row: avatar initial circle + name + "Age Xyr · XcmHeight · Xkg" subtitle
    Edit IconButton (pencil) → router.push('/profile-setup') (reuse the screen,
    profile_provider should handle update vs create)

  TRAINING section (white card):
    ListTile: "Pool Length" + current value (25m) + chevron
      → shows bottom sheet with pool_length_selector
    ListTile: "Default Stroke" + stroke icon + chevron
      → shows bottom sheet with stroke_selector

  DEVICE section (white card):
    If connected:
      connection_status widget (full row)
      battery row: icon + "X%" + progress bar
      "Firmware v1.0.0" subtitle
      Sync button: outlined, primary text, "Sync Sessions" → sync_service.sync()
        Show syncing indicator. Show result toast "X new sessions synced".
      Disconnect button: outlined, colorBad text, "Disconnect"
    If not connected:
      connection_status (disconnected state)
      "Connect to SwimTrack WiFi in your phone's settings, then tap Connect"
      Connect button → deviceProvider.connect(DEVICE_SSID, DEVICE_PASSWORD)

  APP section (white card):
    SwitchListTile: "Simulator Mode" + toggle → settingsProvider.setSimulatorMode()
    ListTile: "App Version" + "v1.0.0" trailing text

  Sync also available from history_tab refresh icon.

TEST: Settings shows all sections. Edit profile works. Connect/disconnect works.
Simulator toggle works. Sync (with simulator) adds mock sessions to History.
```

---

### PROMPT 6 — Polish, Empty States, and Error Handling

```
Add polish across the entire app.

Empty states (add to all screens that can be empty):
  history_tab empty: large 🏊 emoji, "No sessions yet",
    "Connect your SwimTrack device and tap Sync to get started", primary outlined button "Go to Settings"
  No latest session on home tab: card with "Start your first session!" text + wave illustration (unicode art ok)
  Session detail with no laps: "No lap data recorded"

Loading states:
  Session list: show 3 shimmer placeholder cards while loading from DB
    (grey animated rectangles using AnimatedContainer or ColorFiltered)
  Connecting: button shows CircularProgressIndicator + "Connecting..." text
  Syncing: overlay with CircularProgressIndicator + "Syncing X of Y..."

Error handling:
  Connection error on Login: red snackbar + retry button stays visible
  Sync failure: SnackBar "Sync failed: [error message]. Try again."
  API timeout: DeviceException("Connection timed out. Is the device on?")
  Session start failure: dialog "Could not start session. Check device connection."

Animations:
  Login screen: fade-in on the white card when screen loads (300ms)
  Home tab transition IDLE → RECORDING: AnimatedContainer 500ms for background
  Session card: InkWell ripple effect + slight scale (0.98) on press
  Bottom nav: tap feedback with slight icon scale

Validators:
  Profile form: name required, age 10-100, height 100-250cm, weight 30-300kg
  Pool custom input: 10-100m range, integer only

Edge cases:
  Lap table with 0 laps: show empty state
  Single lap session: chart still renders (single point)
  Very long name: truncate with ellipsis in all display places
  Session with no SWOLF (0 strokes): show "--" instead of 0

TEST: Force each empty state. Verify all error messages appear correctly.
Check animations feel smooth (no jank). Long name edge case handled.
```

---

### PROMPT 7 — Documentation

```
Generate complete documentation for the SwimTrack Flutter app.

Create docs/README.md with:
1. Project overview and screenshots (reference the figma PNGs in assets/images/)
2. Tech stack (Flutter, Riverpod, GoRouter, fl_chart, SQLite, dio)
3. Setup: flutter create, pubspec.yaml, Android permissions, flutter pub get
4. Architecture diagram (ASCII): screens → providers → services → models
5. 3-screen flow explained (Login → Profile → Main)
6. Device connection guide (how WiFi pairing works)
7. Simulator mode guide (develop without device)
8. REST API reference (all endpoints with request/response)
9. Build & run: flutter run, flutter build apk --release
10. Troubleshooting: wifi_iot permission, sqflite iOS, google_fonts offline,
    connection refused, ADC timeout

Add doc comments to every public class and method in:
  device_api_service.dart, database_service.dart, sync_service.dart,
  all providers, all screens

DELIVERABLE: Complete docs/README.md with all sections.
```

---

## PART 5 — BUILD ORDER AND TESTING CHECKLIST

| Prompt | What to test |
|--------|-------------|
| 1 | App launches, no errors, theme colors visible, routing works |
| 2 | Login screen renders, profile setup renders, form validation works |
| 3 | Bottom nav works, history shows sessions (or empty state), tap → detail |
| 4 | Home idle state renders, selectors work, Start → recording state, Stop → saves |
| 5 | Settings all sections visible, connect/disconnect, sync works in simulator |
| 6 | Empty states all correct, errors show proper messages, animations smooth |
| 7 | README complete, code has doc comments |

**After all 7 prompts:** Test the full end-to-end flow:
1. Launch app → login screen
2. Connect (simulator mode ON) → profile setup
3. Fill profile → main screen
4. Home tab: Start Session → live data counting → Stop
5. History tab: session appears, tap → detail with chart
6. Settings: edit profile, change pool length
7. Force error: turn simulator OFF → verify error messages

---

## PART 6 — CONNECTING TO REAL DEVICE

When firmware is on the ESP32:
1. Power on the ESP32 dev board
2. Open Android phone WiFi settings
3. Connect to **SwimTrack** / password **swim1234**
4. Open the app
5. On Login screen: Device Name = SwimTrack, Password = swim1234, tap Connect
6. App connects to http://192.168.4.1
7. Go to Settings → tap Sync to pull any saved sessions
8. Go to Home → Start Session → swim → Stop

Note: Android blocks HTTP (non-HTTPS) by default from API 28+.
Add this to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
android:usesCleartextTraffic="true"
```
