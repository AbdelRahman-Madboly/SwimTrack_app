# SwimTrack Device API — Quick Reference

Base URL: `http://192.168.4.1`  
Protocol: Plain HTTP (no auth, no HTTPS)  
All responses: `Content-Type: application/json`

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/status` | Device state, battery, mode |
| GET | `/api/live` | Real-time swim metrics (poll ≤1s) |
| GET | `/api/sessions` | List all session summaries |
| GET | `/api/sessions/{id}` | Full session with lap data |
| POST | `/api/session/start` | Start recording |
| POST | `/api/session/stop` | Stop recording and save |
| POST | `/api/config` | Update pool length |
| DELETE | `/api/sessions/{id}` | Delete session from device |

---

## GET /api/status

```json
{
  "mode":           "IDLE",        // "IDLE" | "RECORDING"
  "session_active": false,         // bool
  "wifi_clients":   1,             // int — connected phones
  "uptime_s":       607,           // int — seconds since boot
  "battery_pct":    100,           // int 0-100
  "battery_v":      4.2,           // float
  "pool_m":         25,            // int — current pool length
  "free_heap":      235400         // int — free SRAM bytes
}
```

---

## GET /api/live

```json
{
  "strokes":        14,            // int — total strokes this session
  "rate_spm":       "32.5",        // STRING float — strokes per minute
  "stroke_type":    "FREESTYLE",   // string enum
  "lap_strokes":    5,             // int — strokes in current lap
  "laps":           2,             // int — from LapCounter
  "session_laps":   2,             // int — from SessionManager (use this)
  "resting":        false,         // bool
  "lap_elapsed_s":  "8.3",         // STRING float — current lap time
  "swolf_est":      "21.8",        // STRING float — lap_strokes + lap_elapsed_s
  "variance":       "0.0012",      // STRING float — accel variance (rest detection)
  "session_active": true,          // bool
  "ax": "0.012", "ay": "-0.003", "az": "1.001",   // IMU accel (g)
  "gx": "0.01",  "gy": "0.02",   "gz": "-0.01",   // IMU gyro (deg/s)
  "temp_c": "24.5"                 // IMU temperature
}
```

> ⚠️ Float fields sent as strings due to `serialized(String(value, 1))` in firmware.
> The app's `LiveData.fromJson()` handles this with `double.tryParse(v.toString())`.

---

## GET /api/sessions

```json
[
  {
    "id":            12010,        // int
    "duration_s":    86.1,        // float
    "laps":          4,           // int — lap count
    "total_strokes": 47,          // int
    "pool_m":        25,          // int
    "total_dist_m":  100,         // int (or float)
    "avg_swolf":     "9.7"        // STRING float
  }
]
```

---

## GET /api/sessions/{id}

```json
{
  "id":            12010,
  "start_ms":      1234567890,    // int — millis() since device boot (NOT Unix epoch)
  "end_ms":        1234567976,    // int
  "duration_s":    "86.1",        // STRING float
  "pool_m":        25,
  "laps":          4,
  "total_strokes": 47,
  "total_dist_m":  100,
  "avg_swolf":     "9.7",         // STRING float
  "avg_spm":       "38.4",        // STRING float
  "lap_data": [
    {
      "n":       1,               // int — lap number (1-based)
      "t_s":     "21.3",          // STRING float — lap duration seconds
      "strokes": 5,               // int
      "swolf":   "26.3",          // STRING float
      "spm":     "14.1"           // STRING float
    }
  ],
  "rests": [
    {
      "start_ms": 45000,          // int — ms from session start
      "dur_s":    "12.3"          // STRING float
    }
  ]
}
```

---

## POST /api/session/start

**Request:**
```json
{"pool_length_m": 25}
```
(Body is optional — defaults to current device pool length)

**Response:**
```json
{"ok": true, "pool_m": 25, "id": 1234567}
```
`id` = `millis()` at start time. Use this to fetch the session after stopping.

---

## POST /api/session/stop

**Request:** No body required.

**Response:**
```json
{"ok": true, "saved_id": 12010}
```
`saved_id` = permanent ID assigned when saved to LittleFS. Use this to fetch full session.

---

## POST /api/config

**Request:**
```json
{"pool_length_m": 50}
```

**Response:**
```json
{"ok": true, "pool_m": 50}
```

---

## DELETE /api/sessions/{id}

**Response (success):**
```json
{"ok": true}
```

**Response (not found):**
```json
{"error": "session not found"}
```

---

## Error Responses

All errors follow this format:
```json
{"error": "description of error"}
```

Common HTTP status codes:
- `200` — Success
- `400` — Bad request (e.g. "no active session" on stop)
- `404` — Session not found
- `500` — Internal error (file system issue)

---

## Stroke Type Values

The `stroke_type` field in `/api/live` returns:

| Value | Description |
|-------|-------------|
| `"FREESTYLE"` | Front crawl |
| `"BACKSTROKE"` | Back crawl |
| `"BREASTSTROKE"` | Breaststroke |
| `"BUTTERFLY"` | Butterfly |
| `"UNKNOWN"` | Not yet classified |

Source: `strokeTypeName()` function in firmware.

---

## Important Implementation Notes

### Float-as-string parsing
Many float fields arrive as strings from the firmware because it uses
`serialized(String(value, decimals))` in ArduinoJson. The app handles this with:

```dart
static double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
```

### start_ms is NOT Unix timestamp
`start_ms` in session JSON is `millis()` since device boot, not a Unix epoch.
The app converts it with `DateTime.fromMillisecondsSinceEpoch(startMs)`.
For accurate timestamps, the firmware would need NTP or RTC sync.

### Pool length sync
When the app calls `POST /api/session/start` with `pool_length_m`, the device
updates its global `poolLengthM` variable. The Settings tab also has a
`POST /api/config` endpoint for changing it without starting a session.

### Session IDs
- Start response `id` = `millis()` → temporary, used to track the in-progress session
- Stop response `saved_id` = LittleFS numeric ID → permanent, used to fetch full data
- Always use `saved_id` to call `GET /api/sessions/{id}` after stopping

---

## Firmware File Reference

| File | What it does |
|------|-------------|
| `wifi_server.cpp` | WiFi AP setup, route registration, `/api/status` handler |
| `wifi_live.cpp` | `/api/live` handler — assembles real-time JSON |
| `wifi_api.cpp` | `/api/sessions`, `/api/session/start`, `/api/session/stop`, DELETE handler |
| `session_manager_part3.cpp` | `_buildJson()` — serializes full session to JSON for LittleFS |
| `config.h` | Tuning constants: gyro thresholds, glide detection, rest detection |
| `lap_counter.h/.cpp` | Turn detection FSM, rest detection, variance computation |
| `stroke_detector.h/.cpp` | Stroke counting, rate calculation, stroke type classification |

---

## Firmware Tuning Parameters (config.h)

These affect what the app receives in `/api/live`:

| Constant | Default | Effect |
|----------|---------|--------|
| `TURN_GYRO_Z_THRESH_DPS` | ~150 | Minimum gyro Z for turn detection |
| `TURN_SPIKE_MIN_MS` | ~100 | Minimum spike duration to count as turn |
| `TURN_GLIDE_MIN_MS` | ~200 | Minimum glide time to confirm lap |
| `GLIDE_ACCEL_THRESH_G` | ~0.3 | Maximum accel magnitude during glide |
| `REST_VAR_THRESH` | ~0.01 | Variance threshold for rest detection |
| `REST_CONFIRM_MS` | ~2000 | Time of low variance before rest declared |

Increase `TURN_GYRO_Z_THRESH_DPS` if getting false laps.
Decrease if missing real turns.
