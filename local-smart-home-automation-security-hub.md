# Local Smart Home Automation & Security Hub

## System Overview

A fully local, offline-capable IoT Smart Home Automation and Security System built on an **ESP32-CAM AI-Thinker** board with an accompanying Android client application. All communication runs strictly over the Local Area Network (LAN) using HTTP REST endpoints and WebSockets for real-time telemetry, live MJPEG video streaming, and intrusion alerting. No external cloud infrastructure, accounts, or third-party brokers are required.

---

## Hardware Bill of Materials (BOM) & Pinout Assignment

| Component | Function / Subsystem | Interfacing Pin / Spec | Power Domain |
|---|---|---|---|
| **ESP32-CAM (AI-Thinker)** | Main MCU & Video Streamer | OV2640 Camera module, MicroSD slot | 5V DC via Programmer / Buck |
| **FTDI / ESP32-CAM-MB** | Flashing & Serial Monitor | TXD (GPIO 1), RXD (GPIO 3), IO0 to GND for flash | 5V DC |
| **MicroSD Card** | Intrusion Snapshot Storage | 1-bit SD Mode (GPIO 2, 4, 12, 13, 14, 15) | 3.3V (Internal regulator) |
| **PIR Sensor (HC-SR501)** | Motion Detection (Security) | GPIO 13 (Digital Input, Interrupt enabled) | 5V VCC, 3.3V Logic OUT |
| **DHT11 Sensor** | Ambient Temp & Humidity | GPIO 12 (Single-bus Digital I/O, 10kΩ pullup) | 3.3V or 5V VCC |
| **Relay Module (Dual-ch)** | Switching 12V Loads (Fan & Light) | IN1 -> GPIO 14, IN2 -> GPIO 15 (Active LOW) | 5V VCC (Opto-isolated) |
| **Active Buzzer** | Security Alarm / Intrusion Alert | GPIO 2 (Digital Output via 2N2222 or direct logic) | 5V or 3.3V |
| **12V LED Strip/Bulb** | Automation Load #1 (Lighting) | Switched via Relay 1 COM/NO | 12V DC Adapter |
| **12V DC Fan** | Automation Load #2 (Climate) | Switched via Relay 2 COM/NO | 12V DC Adapter |
| **5V 2A Adapter** | ESP32-CAM & Sensor Logic Power | 5V pin, common GND with 12V adapter | 5V DC Rail |
| **Electrolytic Capacitor** | Power rail smoothing (anti-brownout) | 470µF – 1000µF across 5V and GND close to ESP32 | Parallel to DC input |

> **Critical Hardware Notice for ESP32-CAM:**  
> Avoid using **GPIO 4** (onboard high-brightness flash LED) or **GPIO 0** for general I/O. If SD-MMC mode is active in 1-bit mode, ensure pins `GPIO 12`, `GPIO 13`, `GPIO 14`, and `GPIO 15` are shared cleanly or initialize SD in 1-bit mode (`SD_MMC.begin("/sdcard", true)`).

---

## Complete Wiring & Electrical Circuit Guide

### Common Ground

Tie the Ground (GND) of the 5V power supply and 12V power supply together. Failure to share GND will cause floating logic signals and erratic switching.

### 5V Power Rail

- 5V Adapter `+` -> ESP32-CAM `5V` pin, Relay VCC, PIR VCC.
- Electrolytic Capacitor (470µF - 1000µF):
  - `+` leg -> 5V rail
  - `-` leg -> GND rail
  - Place it as close as possible to the ESP32-CAM headers.

### Sensors

- PIR OUT -> ESP32-CAM `GPIO 13`.
- DHT11 DATA -> ESP32-CAM `GPIO 12`.
- Add a 4.7kΩ–10kΩ pull-up resistor between DATA and VCC if the DHT11 breakout module lacks one.
- Buzzer `+` -> ESP32-CAM `GPIO 2`.
- Buzzer `-` -> GND.

### 12V Actuator Circuits

- 12V Adapter `+` -> Relay 1 `COM` and Relay 2 `COM`.
- Relay 1 `NO` (Normally Open) -> 12V LED `+` line.
- 12V LED `-` line -> 12V Adapter `-` (GND).
- Relay 2 `NO` -> 12V Fan `+` line.
- 12V Fan `-` line -> 12V Adapter `-` (GND).
- Relay IN1 -> ESP32-CAM `GPIO 14`.
- Relay IN2 -> ESP32-CAM `GPIO 15`.

---

## Network & Communication Architecture

- **Network Mode:** Station (STA) Mode on local Wi-Fi router, or Fallback SoftAP (`SSID: SmartHome_Local_Hub`, `Pass: 12345678`).
- **Service Discovery:** mDNS broadcasting as `http://smarthome.local`.
- **Transport Protocols:**
  - **HTTP GET / POST:** Device control, manual capture, configuration.
  - **MJPEG Streamer:** Dedicated HTTP stream on port `81` or path `/stream`.
  - **WebSocket Server:** Bi-directional pipe on port `80` (path `/ws`) for telemetry broadcast (DHT11, PIR state) and sub-second control commands.

---

## Local API & Protocol Specification

### 1. REST Endpoints

#### `GET /api/status`

Returns live state of all actuators and sensors.

**Response `200 OK` (`application/json`):**

```json
{
  "system": {
    "uptime": 14205,
    "armed": true,
    "ip": "192.168.1.50"
  },
  "sensors": {
    "temperature": 27.4,
    "humidity": 65.0,
    "pir_motion": false
  },
  "actuators": {
    "relay_light": false,
    "relay_fan": true,
    "buzzer": false
  }
}
```

#### `POST /api/relay`

Controls individual relays.

**Payload (`application/json`):**

```json
{
  "channel": 1,
  "state": true
}
```

**Response `200 OK`:**

```json
{
  "success": true,
  "relay_light": true
}
```

#### `POST /api/security/arm`

Arms or disarms the intrusion alarm.

**Payload (`application/json`):**

```json
{
  "armed": true
}
```

#### `POST /api/buzzer`

Manual override for the security siren.

**Payload (`application/json`):**

```json
{
  "state": true
}
```

#### `GET /api/capture`

Takes a high-resolution still snapshot and saves it directly to the onboard SD card.

**Response `200 OK`:**

```json
{
  "saved": true,
  "filename": "/captures/intrusions/img_20260912_2130.jpg"
}
```

---

### 2. Video Streaming Endpoint

**URL:**

```text
http://<ESP32_IP>:81/stream
```

or:

```text
http://<ESP32_IP>/stream
```

**Format:**

```text
multipart/x-mixed-replace; boundary=frame
```

**Recommended Resolution:**

- QVGA: `320x240`
- CIF: `400x296`

Use lower resolutions when necessary for stable Wi-Fi throughput and reduced power/brownout risk.

---

### 3. WebSocket Real-Time Channel

**URL:**

```text
ws://<ESP32_IP>/ws
```

#### Outbound Telemetry Broadcast

ESP32 -> Android App every 2 seconds or upon an interrupt:

```json
{
  "type": "TELEMETRY_UPDATE",
  "temperature": 28.1,
  "humidity": 64.0,
  "pir": false,
  "light": false,
  "fan": true,
  "armed": true
}
```

#### Security Interrupt Event

ESP32 -> Android App immediately when motion is detected:

```json
{
  "type": "ALARM_TRIGGERED",
  "source": "PIR_MOTION",
  "timestamp": 1726155012,
  "snapshot_url": "/captures/intrusions/alert_last.jpg"
}
```

#### Inbound Command

Android App -> ESP32:

```json
{
  "action": "SET_RELAY",
  "target": "fan",
  "value": false
}
```

---

## ESP32-CAM Firmware Implementation Guide

### Required Libraries

- `esp_camera.h` — ESP-IDF camera driver
- `WiFi.h`
- `ESPmDNS.h`
- `AsyncTCP.h`
- `ESPAsyncWebServer.h`
- `ArduinoJson.h` — v6 or v7
- `DHT.h` — Adafruit DHT sensor library
- `FS.h`
- `SD_MMC.h`

### Firmware Architecture Patterns

#### 1. Camera Configuration — AI-Thinker

Configure camera pins according to `CAMERA_MODEL_AI_THINKER`.

Recommended starting configuration:

```cpp
config.frame_size = FRAMESIZE_QVGA;
config.jpeg_quality = 12;
config.fb_count = 2;
```

Allocate frame buffers in PSRAM when available.

#### 2. SD Card in 1-Bit Mode

Initialize the SD card in 1-bit mode:

```cpp
SD_MMC.begin("/sdcard", true);
```

This releases D1 and D2 lines for GPIO usage.

#### 3. PIR Interrupt Handling

Attach a hardware interrupt to PIR GPIO 13:

```cpp
attachInterrupt(digitalPinToInterrupt(13), isr_pir_motion, RISING);
```

The ISR should only set a `volatile` flag.

Perform the following operations inside the primary `loop()` instead of the ISR:

- Capture the camera frame.
- Save the snapshot to SD.
- Activate or maintain the buzzer.
- Broadcast the WebSocket alarm event.

This avoids excessive ISR execution time and stack-related issues.

#### 4. Relay Logic

The relay module is active LOW:

```cpp
digitalWrite(pin, LOW);   // Relay ON
digitalWrite(pin, HIGH);  // Relay OFF
```

Initialize relay GPIOs to the safe OFF state during startup.

---

## Android App Architecture & Implementation Plan

### Recommended Tech Stack

- **Framework:** Flutter (Dart) or Native Android (Kotlin + Jetpack Compose).
- **Networking Engine:** Dio / Retrofit + OkHttp.
- **WebSocket Engine:** `web_socket_channel` (Flutter) or OkHttp WebSocket client (Kotlin).
- **Local Discovery:** `multicast_dns` or Android `NsdManager`.
- **Video Player:** Native `MjpegView` or custom HTTP byte-chunk reader parsing `multipart/x-mixed-replace`.
- **Local State Management:** Riverpod / Bloc (Flutter) or ViewModel + StateFlow (Kotlin).

---

## Application Screen Hierarchy

```text
App Root
│
├── Dashboard (Home)
│   ├── Connection Indicator (mDNS Status / IP auto-detect)
│   ├── Environment Card (Live Temp °C & Humidity % from DHT11)
│   ├── Quick Toggles (12V Light Toggle, 12V Fan Toggle)
│   └── System Security Mode (ARM / DISARM Toggle Switch)
│
├── Surveillance Screen
│   ├── Live Camera MJPEG View (Low-latency stream)
│   ├── Manual Capture Button (Trigger snapshot to SD)
│   └── Siren Trigger Button (Manual override)
│
├── Security & Logs
│   ├── Intrusion History (PIR triggers with timestamps)
│   └── SD Card Image Browser (Fetch recent snapshots over HTTP)
│
└── Settings
    ├── Manual ESP32 IP Override (Fallback if mDNS fails)
    ├── Refresh Interval & Stream Quality Options
    └── Sensor Calibration Offsets
```

---

## Operational Logic & Fail-Safes

### 1. Anti-Brownout Protection

The ESP32-CAM can experience significant current demand during Wi-Fi packet bursts and camera initialization.

Use a **470µF–1000µF electrolytic capacitor** directly across the 5V and GND headers, physically close to the ESP32-CAM.

Also ensure the 5V supply has adequate current capacity and short, low-resistance wiring.

### 2. Autonomous Offline Resilience

If the local Wi-Fi router goes offline, the ESP32 security routine must continue operating independently:

- PIR motion detection remains active.
- Buzzer can be triggered locally.
- Intrusion images can be captured.
- Images are stored directly on the SD card.
- Network-dependent Android notifications are unavailable until connectivity returns.

### 3. App Connection Reconnect Policy

The Android WebSocket client should implement exponential-backoff reconnection:

```text
1s -> 2s -> 4s -> 8s -> 10s maximum
```

Reset the backoff after a successful connection.

### 4. Intrusion Workflow

When the security system is armed:

```text
System armed
      │
      ▼
PIR detects motion
      │
      ▼
Hardware interrupt triggered
      │
      ▼
Set volatile motion flag
      │
      ▼
Main loop detects flag
      │
      ├──────────────► Activate buzzer
      │
      ├──────────────► Capture OV2640 frame
      │
      ├──────────────► Save image to SD
      │
      └──────────────► Broadcast WebSocket ALARM_TRIGGERED event
                              │
                              ▼
                       Android app receives event
                              │
                              ├── Sound alert
                              ├── Vibration alert
                              └── Display intrusion snapshot
```

---

## Suggested Project Structure

### ESP32-CAM Firmware

```text
esp32-smart-home/
├── src/
│   ├── main.cpp
│   ├── camera.cpp
│   ├── camera.h
│   ├── sensors.cpp
│   ├── sensors.h
│   ├── relays.cpp
│   ├── relays.h
│   ├── security.cpp
│   ├── security.h
│   ├── api.cpp
│   ├── api.h
│   ├── websocket.cpp
│   ├── websocket.h
│   ├── storage.cpp
│   └── storage.h
├── include/
│   └── config.h
└── platformio.ini
```

### Android / Flutter Client

```text
smart_home_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── network/
│   │   ├── discovery/
│   │   └── constants/
│   ├── models/
│   │   ├── sensor_data.dart
│   │   ├── actuator_state.dart
│   │   └── alarm_event.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── websocket_service.dart
│   │   └── discovery_service.dart
│   ├── providers/
│   │   └── smart_home_provider.dart
│   └── screens/
│       ├── dashboard/
│       ├── surveillance/
│       ├── security_logs/
│       └── settings/
└── pubspec.yaml
```

---

## Security & Reliability Considerations

Because this system is designed to operate locally without cloud authentication, LAN access should still be treated as trusted-but-not-fully-secure.

Recommended protections:

1. Keep the ESP32 and Android client on a trusted LAN.
2. Change the default SoftAP password before deployment.
3. Validate all JSON request fields and reject malformed payloads.
4. Restrict relay channel values to valid channels.
5. Rate-limit sensitive endpoints such as `/api/buzzer` and `/api/capture`.
6. Prevent path traversal when serving SD-card files.
7. Sanitize filenames generated for intrusion snapshots.
8. Add a maximum snapshot retention policy to prevent SD-card exhaustion.
9. Use watchdog recovery for firmware hangs.
10. Set all actuator outputs to a known safe state during boot.
11. Consider authentication for HTTP/WebSocket control if the device will be accessible to untrusted LAN clients.
12. Never expose the ESP32 HTTP server directly to the public internet.

---

## End-to-End System Flow

```text
                   ┌───────────────────────────┐
                   │       Android App         │
                   │                           │
                   │ Dashboard / Camera / Logs │
                   └─────────────┬─────────────┘
                                 │
                       Local Wi-Fi / LAN
                                 │
              ┌──────────────────┴──────────────────┐
              │                                     │
        HTTP REST API                         WebSocket /ws
              │                                     │
              └──────────────────┬──────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │      ESP32-CAM          │
                    │                          │
                    │  Wi-Fi + Web Server      │
                    │  OV2640 Camera           │
                    │  Security Logic          │
                    │  Sensor Processing       │
                    └───────┬──────┬──────────┘
                            │      │
              ┌─────────────┘      └─────────────┐
              │                                  │
       ┌──────▼──────┐                    ┌──────▼──────┐
       │   Sensors   │                    │ Actuators   │
       │             │                    │             │
       │ PIR         │                    │ Relay 1     │
       │ DHT11       │                    │ Relay 2     │
       └─────────────┘                    │ Buzzer      │
                                          └──────┬──────┘
                                                 │
                                      ┌──────────▼──────────┐
                                      │ 12V Light + Fan     │
                                      └─────────────────────┘

                    ┌────────────────────────────┐
                    │       MicroSD Card         │
                    │                            │
                    │ /captures/intrusions/      │
                    │   └── snapshots            │
                    └────────────────────────────┘
```

---

## Core Design Goals

- **100% Local Operation:** No mandatory cloud dependency.
- **Offline Security:** PIR, buzzer, camera capture, and SD storage continue without the router.
- **Real-Time Monitoring:** WebSockets provide low-latency telemetry and intrusion events.
- **Live Surveillance:** MJPEG provides a simple local camera stream.
- **Remote Local Control:** Android app controls lighting, fan, and alarm functions.
- **Expandable Architecture:** Additional sensors and actuators can be integrated through the REST/WebSocket API.
- **Resilient Networking:** mDNS discovery, manual IP fallback, and WebSocket reconnect logic.
- **Local Evidence Storage:** Intrusion snapshots are stored directly on the ESP32-CAM's MicroSD card.
