# Hardware-to-Software Connection & Troubleshooting Guide

This document outlines the networking and architectural strategies for connecting the Android Application to the ESP32-CAM hardware hub in a 100% local, offline-capable environment. It also details common complications that arise when linking mobile apps to local embedded hardware and provides concrete solutions.

---

## 1. How the Software Connects to the Hardware

Because this system relies entirely on the Local Area Network (LAN) without cloud brokers (like MQTT or Firebase), the connection must be established point-to-point over your home Wi-Fi.

### The Three Connection Methods

The Android App and ESP32 must implement three connection strategies to ensure the system is always accessible:

#### A. The Automatic Method: mDNS (Multicast DNS)
*   **How it works:** The ESP32 broadcasts a hostname on the network (e.g., `smarthome.local`). The Android app uses a network discovery library to ask the router, "What is the IP address for smarthome.local?".
*   **User Experience:** Seamless. The user opens the app, and it connects instantly without needing to know IP addresses.

#### B. The Reliable Method: Static IP (Manual Override)
*   **How it works:** The user logs into their home Wi-Fi router's admin panel and assigns a permanent, unchanging IP address to the ESP32's MAC address (e.g., `192.168.1.50`). 
*   **User Experience:** The user types this IP address into the Android App's "Settings" screen once. The app saves it and uses it permanently.

#### C. The Fallback Method: SoftAP (No-Router Mode)
*   **How it works:** If the ESP32 fails to connect to the home Wi-Fi (e.g., internet is down, or first-time setup), it automatically creates its own Wi-Fi hotspot named `SmartHome_Local_Hub`. 
*   **User Experience:** The user connects their phone directly to this Wi-Fi network and the app talks to the ESP32 on its default gateway IP (usually `192.168.4.1`).

---

## 2. Complications & Solutions in Hardware-Software Communication

Connecting a mobile app directly to a local microcontroller introduces specific challenges that you wouldn't face if you were using a cloud server. 

### Complication A: mDNS Discovery Failures
*   **The Problem:** Many Android devices and strict home Wi-Fi routers block multicast traffic (UDP port 5353) to save battery or improve network security. If this happens, the app will never resolve `smarthome.local`, and the connection will fail silently.
*   **The Solution:** 
    1. **Never rely solely on mDNS.** 
    2. Build a robust "Fallback Flow" in the app: Try mDNS for 3 seconds -> If it fails, attempt to use the last known saved IP address -> If that fails, prompt the user to enter the IP manually or scan the subnet.

### Complication B: Android "Doze Mode" Killing WebSockets
*   **The Problem:** The system uses WebSockets for instant intrusion alerts. However, when the Android app is put in the background or the screen is locked, Android's battery optimizer ("Doze Mode") will sever the WebSocket connection to the ESP32. If an intruder breaks in while your phone is in your pocket, you won't get the alert.
*   **The Solution:** 
    1. Implement a **Foreground Service** in the Android app. This runs the network listener as a high-priority background task and displays a persistent notification (e.g., "Smart Home System Active").
    2. Implement **Exponential Backoff Reconnection:** If the WebSocket disconnects, the app should automatically try to reconnect after 1s, then 2s, 4s, 8s, up to a maximum interval, so it gracefully handles momentary Wi-Fi drops.

### Complication C: MJPEG Stream Parsing on Mobile
*   **The Problem:** The ESP32-CAM streams video as MJPEG (`multipart/x-mixed-replace`). Standard Android video player components do not support this format out-of-the-box, meaning you can't just plug the URL into a standard video widget.
*   **The Solution:** 
    1. In Flutter, use a specific community package like `flutter_mjpeg`.
    2. If writing native Kotlin/Java, you must write a custom HTTP client that reads the raw byte stream, splits the bytes every time it sees the boundary marker (e.g., `--frame`), decodes the bytes into a Bitmap, and updates an ImageView at ~15-20 frames per second.

### Complication D: Concurrent Blocking on the ESP32
*   **The Problem:** The ESP32 is a microcontroller, not a full computer. If the ESP32 is busy reading the DHT11 sensor (which takes a few milliseconds of blocking time) or saving an image to the SD card, it cannot simultaneously serve the video stream or answer HTTP requests. If not handled correctly, the video will stutter, and the app will experience "Request Timeouts".
*   **The Solution:** 
    1. **No `delay()`:** Never use `delay()` in the ESP32 `loop()`. Use `millis()`-based timer checks.
    2. **Asynchronous Web Server:** Use the `ESPAsyncWebServer` library instead of the standard `WebServer`. This handles HTTP and WebSocket requests in the background (often on Core 0) without stopping your main loop.
    3. **Task Delegation (FreeRTOS):** If possible, pin the video streaming task to Core 1 and the sensor/networking tasks to Core 0 using `xTaskCreatePinnedToCore`.

### Complication E: Local Network Security & CORS
*   **The Problem:** Anyone on the local Wi-Fi can send an HTTP POST request to `/api/security/arm` and disable the alarm if they find the IP address.
*   **The Solution:** 
    1. Implement a lightweight authentication token. When configuring the ESP32, hardcode a secret key (e.g., `LAN_SECRET=12345`). 
    2. The Android App must send this secret in the headers of every HTTP and WebSocket request (`Authorization: Bearer 12345`). 
    3. The ESP32 firmware must check this header and return a `401 Unauthorized` error if it is missing or incorrect.

---

## 3. ESP32 Firmware Implementation (C++)

To complete the connection, you must flash the ESP32 with C++ firmware that exposes the exact API endpoints and WebSockets that the Flutter app expects.

### File Structure
If you are using **PlatformIO** (Recommended), the code should be stored here:
`firmware/src/main.cpp`

If you are using the **Arduino IDE**, the code should be stored here:
`firmware/firmware.ino`

### C++ Code Skeleton
Below is the boilerplate code utilizing `ESPAsyncWebServer`, `ArduinoJson`, and `AsyncTCP` to connect with the Flutter app.

```cpp
#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// API Server on port 80
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

// Global State
bool isArmed = false;
bool relay1 = false;
bool relay2 = false;
bool buzzer = false;
float temp = 24.5;
float humidity = 45.0;

// Function to send live updates to the Flutter app via WebSockets
void notifyClients() {
  StaticJsonDocument<256> doc;
  doc["type"] = "TELEMETRY_UPDATE";
  doc["temperature"] = temp;
  doc["humidity"] = humidity;
  doc["pir"] = false; // Real PIR logic here
  doc["light"] = relay1;
  doc["fan"] = relay2;
  doc["armed"] = isArmed;
  
  String output;
  serializeJson(doc, output);
  ws.textAll(output);
}

void setup() {
  Serial.begin(115200);
  
  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println(WiFi.localIP());

  // Setup WebSocket
  ws.onEvent([](AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len) {
    if(type == WS_EVT_CONNECT) {
      Serial.println("Flutter App Connected to WebSocket!");
      notifyClients(); // Send initial state on connect
    }
  });
  server.addHandler(&ws);

  // Endpoint: GET /api/status (Matches ApiService.getStatus)
  server.on("/api/status", HTTP_GET, [](AsyncWebServerRequest *request){
    StaticJsonDocument<256> doc;
    doc["system"]["uptime"] = millis() / 1000;
    doc["system"]["armed"] = isArmed;
    doc["sensors"]["temperature"] = temp;
    doc["sensors"]["humidity"] = humidity;
    doc["sensors"]["pir_motion"] = false;
    doc["actuators"]["relay_light"] = relay1;
    doc["actuators"]["relay_fan"] = relay2;
    doc["actuators"]["buzzer"] = buzzer;

    String response;
    serializeJson(doc, response);
    request->send(200, "application/json", response);
  });

  // Endpoint: POST /api/relay (Matches ApiService.setRelay)
  server.on("/api/relay", HTTP_POST, [](AsyncWebServerRequest *request){}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      StaticJsonDocument<200> doc;
      deserializeJson(doc, data);
      
      int channel = doc["channel"];
      bool state = doc["state"];
      
      if(channel == 1) relay1 = state;
      if(channel == 2) relay2 = state;
      
      notifyClients(); // Broadcast to UI
      request->send(200, "application/json", "{\"status\":\"ok\"}");
  });

  // Start server
  server.begin();
}

void loop() {
  // Never use delay() here!
  // Handle non-blocking sensor reads, MJPEG streams, etc.
  ws.cleanupClients();
}
```
