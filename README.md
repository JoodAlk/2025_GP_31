# Baseer | بصير

## Smart Waste Monitoring and Collection System

Baseer is a smart waste monitoring and collection system designed to improve waste collection efficiency in Riyadh. The system uses IoT sensors connected to an ESP32 microcontroller to monitor trash bin fill levels and detect possible fire or gas hazards. The collected data is sent to Firebase Realtime Database and displayed through a Flutter application for drivers and administrators.

---

## Installation and Run Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/JoodAlk/2025_GP_31.git
cd 2025_GP_31
```

---

## Hardware Setup

The hardware prototype uses the following components:

- ESP32 microcontroller
- HC-SR04 ultrasonic sensor
- MQ-2 gas sensor
- Breadboard
- Jumper wires
- USB cable
- External power source / battery holder

### HC-SR04 Ultrasonic Sensor Connections

| HC-SR04 Pin | ESP32 Pin |
|---|---|
| VCC | 5V |
| GND | GND |
| Trig | GPIO 12 |
| Echo | GPIO 13 |

### MQ-2 Gas Sensor Connections

| MQ-2 Pin | ESP32 Pin |
|---|---|
| VCC | 5V / VIN |
| GND | GND |
| D0 | GPIO 14 |

Note: The MQ-2 sensor is used through its digital output only. The analog output was not included in the final prototype because it requires additional analog calibration and resistor-based wiring.

---

## ESP32 Setup and Run Instructions

1. Open the Arduino IDE.
2. Install the ESP32 board package.
3. Install the required libraries:
   - `WiFi.h`
   - `Firebase_ESP_Client.h`
4. Open the ESP32 Arduino code from the repository.
5. Update the following values in the code:
   - Wi-Fi SSID
   - Wi-Fi password
   - Firebase API key
   - Firebase Realtime Database URL
6. Connect the ESP32 to the laptop using a USB cable.
7. Select the correct ESP32 board and port from Arduino IDE.
8. Upload the code.
9. Open the Serial Monitor to verify that sensor readings are displayed and sent to Firebase.

Expected output example:

```text
Distance: 10 cm
Fill Level: 65%
FireDetected: false
Firebase update successful
```

---

## Flutter Application Setup and Run Instructions

1. Make sure Flutter is installed.

```bash
flutter doctor
```

2. Navigate to the Flutter application folder.

```bash
cd baseer_app
```

3. Install the required dependencies.

```bash
flutter pub get
```

4. Run the application.

```bash
flutter run
```

5. Make sure Firebase configuration is correctly added to the Flutter project.

The application connects to Firebase Realtime Database and displays real-time bin information for drivers and administrators.

---

## Additional Testing Information

### Tested Features

The final prototype was tested for the following:

- Ultrasonic sensor fill-level reading.
- MQ-2 digital fire/gas hazard detection.
- ESP32 connection to Wi-Fi.
- ESP32 data upload to Firebase.
- Firebase real-time data updates.
- Flutter app reading live bin data from Firebase.
- Driver sign-up and login.
- Bin list display.
- Bin filtering by area.
- Map visualization with bin markers.
- Color-coded bin status indicators.
- Admin monitoring of bin data.

### Test Results Summary

| Test Case | Expected Result | Status |
|---|---|---|
| Empty bin detection | Fill level displays 0% | Passed |
| Full bin detection | Fill level displays 100% | Passed |
| MQ-2 safe status | Hazard status displays Safe | Passed |
| MQ-2 hazard status | HazardDetected becomes true | Passed |
| Firebase upload | Data appears in Firebase within a few seconds | Passed |
| Flutter live update | App displays updated bin data | Passed |
| Driver login | Driver can access the app using valid credentials | Passed |
| Map display | Bin markers appear on the map | Passed |

---

## Login Credentials

Use the following sample credentials for testing the driver application:

```text
Driver ID: DRIVER-001
Password: 123456
```

If these credentials are changed in Firebase, use the updated driver ID and password stored under the `drivers` node.

---

## URLs

### Firebase Realtime Database

```text
https://baseer-40cf2-default-rtdb.asia-southeast1.firebasedatabase.app/
```

### GitHub Repository

```text
https://github.com/JoodAlk/2025_GP_31
```

---


