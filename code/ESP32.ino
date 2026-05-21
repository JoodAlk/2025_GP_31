#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <time.h>

// Wi-Fi
#define WIFI_SSID     "HUAWEI-B525-7260"
#define WIFI_PASSWORD "58658593"

// Firebase
#define API_KEY      "AIzaSyBgzhlooyfDirhNsYww63URZfMhhl2DDhE"
#define DATABASE_URL "https://baseer-40cf2-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Bin info
#define BIN_ID "1"
#define BIN_LABEL "Bin-1"
#define AREA_ID "Riyadh-03"
#define BIN_NAME "1"

// Send interval
#define SEND_INTERVAL 3000UL

// Ultrasonic pins
#define TRIG_PIN 12
#define ECHO_PIN 13

// MQ-2 digital pin
#define MQ2_DO_PIN 14

// Bin calibration
const float EMPTY_DISTANCE_CM = 21.0f;
const float FULL_DISTANCE_CM  = 4.0f;
const int CAPACITY_CM = 400;

// Location
const float LOCATION_LATITUDE = 24.7136;
const float LOCATION_LONGITUDE = 46.6753;

// Riyadh time UTC+3
const long GMT_OFFSET_SEC = 3 * 3600;
const int DAYLIGHT_OFFSET_SEC = 0;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastSend = 0;
bool signupOK = false;

bool ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED) return true;

  Serial.println("WiFi disconnected. Reconnecting...");
  WiFi.disconnect(true);
  delay(100);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 5000) {
    delay(100);
    Serial.print(".");
  }

  Serial.println();
  return WiFi.status() == WL_CONNECTED;
}

bool ensureFirebaseSession() {
  if (!signupOK) {
    Serial.println("Signing in to Firebase...");

    if (Firebase.signUp(&config, &auth, "", "")) {
      signupOK = true;
      Serial.println("Firebase signup OK.");
      return true;
    }

    Serial.println("Firebase signup failed.");
    Serial.println(config.signer.signupError.message.c_str());
    return false;
  }

  return true;
}

bool sendToFirebase(FirebaseJson &j) {
  String path = String("/Baseer/bins/") + BIN_ID;

  if (!ensureWiFi()) {
    Serial.println("WiFi failed. Upload skipped.");
    return false;
  }

  if (!ensureFirebaseSession()) {
    Serial.println("Firebase session failed. Upload skipped.");
    return false;
  }

  if (Firebase.ready()) {
    bool ok = Firebase.RTDB.updateNode(&fbdo, path.c_str(), &j);

    if (!ok) {
      Serial.print("Firebase error: ");
      Serial.println(fbdo.errorReason());
    }

    return ok;
  }

  Serial.println("Firebase not ready.");
  return false;
}

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

int distanceToFillLevel(float distanceCm) {
  if (distanceCm < 0) return 0;

  if (distanceCm >= EMPTY_DISTANCE_CM) return 0;
  if (distanceCm <= FULL_DISTANCE_CM) return 100;

  float span = EMPTY_DISTANCE_CM - FULL_DISTANCE_CM;
  float filled = EMPTY_DISTANCE_CM - distanceCm;
  float percent = (filled / span) * 100.0f;

  if (percent < 0) percent = 0;
  if (percent > 100) percent = 100;

  return (int)roundf(percent);
}

String ordinalSuffix(int d) {
  if (d % 100 >= 11 && d % 100 <= 13) return "th";

  switch (d % 10) {
    case 1: return "st";
    case 2: return "nd";
    case 3: return "rd";
    default: return "th";
  }
}

String getRiyadhDateTimeString() {
  struct tm timeinfo;

  if (!getLocalTime(&timeinfo)) {
    return "Unknown";
  }

  int day = timeinfo.tm_mday;
  String suffix = ordinalSuffix(day);

  char monthYear[32];
  strftime(monthYear, sizeof(monthYear), "%B %Y", &timeinfo);

  char timePart[16];
  strftime(timePart, sizeof(timePart), "%H:%M:%S", &timeinfo);

  return String(day) + suffix + " " + monthYear + " at " + timePart;
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("Starting Baseer ESP32...");

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  pinMode(MQ2_DO_PIN, INPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");
  unsigned long start = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - start < 10000) {
    delay(300);
    Serial.print(".");
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected.");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi not connected yet. Will retry in loop.");
  }

  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC,
             "pool.ntp.org", "time.nist.gov");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Setup complete.");
}

void loop() {
  const unsigned long now = millis();

  if (now - lastSend < SEND_INTERVAL) return;
  lastSend = now;

  static int prevFill = -1;
  static int lastValidFill = 0;

  FirebaseJson j;

  // Fixed bin info
  j.set("AreaId", AREA_ID);
  j.set("BinID", BIN_LABEL);
  j.set("Capacity", CAPACITY_CM);
  j.set("IsAssigned", false);
  j.set("LocationLatitude", LOCATION_LATITUDE);
  j.set("LocationLongitude", LOCATION_LONGITUDE);
  j.set("Name", BIN_NAME);

  // Fire sensor reading
  int mq2Value = digitalRead(MQ2_DO_PIN);

  // LOW/0 = fire/gas detected
  // HIGH/1 = safe
  bool fireDetected = (mq2Value == LOW);

  String fireStatus = fireDetected ? "Detected" : "Safe";

  Serial.println("-----------------------------");
  Serial.print("MQ2 Digital Value: ");
  Serial.println(mq2Value);
  Serial.print("FireDetected: ");
  Serial.println(fireDetected ? "true" : "false");
  Serial.print("FireStatus: ");
  Serial.println(fireStatus);

  j.set("FireDetected", fireDetected);
  j.set("FireStatus", fireStatus);

  // Ultrasonic reading
  int distance = readDistanceCm();
  String nowStr = getRiyadhDateTimeString();

  if (distance < 0) {
    Serial.println("Ultrasonic read failed: No echo.");

    int fill = lastValidFill;
    int free = 100 - fill;
    bool isOverflowing = (fill >= 95);

    j.set("FillLevel", fill);
    j.set("FreeSpace", free);
    j.set("IsOverflowing", isOverflowing);
    j.set("Status", "NoData");

  } else {
    int fill = distanceToFillLevel((float)distance);
    int free = 100 - fill;
    bool isOverflowing = (fill >= 95);

    Serial.print("Distance: ");
    Serial.print(distance);
    Serial.println(" cm");

    Serial.print("FillLevel: ");
    Serial.print(fill);
    Serial.println("%");

    Serial.print("FreeSpace: ");
    Serial.print(free);
    Serial.println("%");

    j.set("DistanceCm", distance);
    j.set("FillLevel", fill);
    j.set("FreeSpace", free);
    j.set("IsOverflowing", isOverflowing);
    j.set("Status", "OK");

    lastValidFill = fill;

    bool justEmptied = (prevFill > 0 && fill == 0);

    if (justEmptied) {
      j.set("LastEmptied", nowStr);
      Serial.println("Bin emptied at: " + nowStr);
    }

    prevFill = fill;
  }

  j.set("LastUpdate", nowStr);

  if (sendToFirebase(j)) {
    Serial.println("Upload successful.");
  } else {
    Serial.println("Upload failed.");
  }
}
