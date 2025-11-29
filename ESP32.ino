#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <time.h>

// ===== Wi-Fi =====
#define WIFI_SSID     "Name"
#define WIFI_PASSWORD "Password"

// ===== Firebase (RTDB) =====
#define API_KEY      "AIzaSyBgzhlooyfDirhNsYww63URZfMhhl2DDhE"
#define DATABASE_URL "https://baseer-40cf2-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Project config =====
#define BIN_ID         "BIN-001"
#define SEND_INTERVAL  3000UL   // 3 seconds

// ===== Ultrasonic Pins =====
#define TRIG_PIN 12
#define ECHO_PIN 13

// ===== Calibration (Updated) =====
// Empty distance = 21 cm
// Full distance ≈ 4 cm (your final measured value)
const float EMPTY_DISTANCE_CM = 21.0f;
const float FULL_DISTANCE_CM  = 4.0f;

// Capacity expressed in cm (usable height)
const int CAPACITY_CM = 21;

// Riyadh Time (UTC+3)
const long GMT_OFFSET_SEC      = 3 * 3600;
const int  DAYLIGHT_OFFSET_SEC = 0;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastSend = 0;
bool signupOK = false;

// ========= Utility Functions =========

bool ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED) return true;

  WiFi.disconnect(true);
  delay(100);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 5000) {
    delay(100);
  }

  return WiFi.status() == WL_CONNECTED;
}

bool ensureFirebaseSession() {
  if (!signupOK) {
    if (Firebase.signUp(&config, &auth, "", "")) {
      signupOK = true;
      return true;
    }
    return false;
  }
  return true;
}

bool sendToFirebase(FirebaseJson &j) {
  String path = String("/Baseer/bins/") + BIN_ID;

  if (!ensureWiFi()) return false;
  if (!ensureFirebaseSession()) return false;

  if (Firebase.ready()) {
    return Firebase.RTDB.updateNode(&fbdo, path.c_str(), &j);
  }
  return false;
}

// ===== Ultrasonic Distance =====

int readDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duration == 0) return -1;

  return (int)(duration * 0.034f / 2.0f);
}

// ===== Linear fill-level mapping =====

int distanceToFillLevel(float distanceCm) {
  if (distanceCm < 0) return 0;

  if (distanceCm >= EMPTY_DISTANCE_CM) return 0;
  if (distanceCm <= FULL_DISTANCE_CM)  return 100;

  float span    = EMPTY_DISTANCE_CM - FULL_DISTANCE_CM;   // 17 cm
  float filled  = EMPTY_DISTANCE_CM - distanceCm;
  float percent = (filled / span) * 100.0f;

  if (percent < 0) percent = 0;
  if (percent > 100) percent = 100;

  return (int)roundf(percent);
}

// ===== Timestamp Formatting =====

String ordinalSuffix(int d) {
  if (d % 100 >= 11 && d % 100 <= 13) return "th";
  switch (d % 10) {
    case 1: return "st";
    case 2: return "nd";
    case 3: return "rd";
    default: return "th";
  }
}

// Same format for LastEmptied and lastUpdate
String getRiyadhDateTimeString() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "Unknown";

  int day = timeinfo.tm_mday;
  String suffix = ordinalSuffix(day);

  char monthYear[32];
  strftime(monthYear, sizeof(monthYear), "%B %Y", &timeinfo); // "November 2025"

  char timePart[16];
  strftime(timePart, sizeof(timePart), "%H:%M:%S", &timeinfo); // "03:41:22"

  return String(day) + suffix + " " + monthYear + " at " + timePart;
}

// ====================== SETUP =========================

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC,
             "pool.ntp.org", "time.nist.gov");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

// ======================= LOOP =========================

void loop() {
  const unsigned long now = millis();
  if (now - lastSend < SEND_INTERVAL) return;
  lastSend = now;

  static int prevFill      = -1; // for LastEmptied transition
  static int lastValidFill = 0;  // last good reading for NoData

  int distance = readDistanceCm();
  FirebaseJson j;

  // Capacity always sent
  j.set("Capacity", CAPACITY_CM);

  // Current human-readable timestamp (for lastUpdate and maybe LastEmptied)
  String nowStr = getRiyadhDateTimeString();

  if (distance < 0) {
    // ===== NO DATA CASE =====
    Serial.println("Sensor read failed (no echo) -> NoData");

    int fill = lastValidFill;
    int free = 100 - fill;
    bool isOverflowing = (fill >= 95);

    j.set("FillLevel", fill);
    j.set("FreeSpace", free);
    j.set("IsOverflowing", isOverflowing);
    j.set("Status", "NoData");

    // Do NOT touch LastEmptied or prevFill here

  } else {
    // ===== NORMAL CASE =====
    int fill = distanceToFillLevel((float)distance);
    int free = 100 - fill;
    bool isOverflowing = (fill >= 95);

    Serial.printf("Distance=%d cm, FillLevel=%d%%, FreeSpace=%d%%\n",
                  distance, fill, free);

    j.set("FillLevel", fill);
    j.set("FreeSpace", free);
    j.set("IsOverflowing", isOverflowing);
    j.set("Status", "OK");

    // Update last valid reading
    lastValidFill = fill;

    // LastEmptied: when bin goes from non-empty to empty (0 %)
    bool justEmptied = (prevFill > 0 && fill == 0);

    if (justEmptied) {
      j.set("LastEmptied", nowStr);
      Serial.println("Bin emptied at: " + nowStr);
    }

    prevFill = fill;
  }

  // lastUpdate = current timestamp string
  j.set("lastUpdate", nowStr);

  if (!sendToFirebase(j)) {
    Serial.println("Upload failed.");
  }
}
