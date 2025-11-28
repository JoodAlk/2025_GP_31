# **Baseer | بصير**
### **Smart Waste Monitoring and Collection System**

Baseer (بصير) is a smart waste monitoring and collection system designed to improve the efficiency of urban waste management in Riyadh.  
The system uses IoT-enabled ultrasonic sensors to measure bin fill levels in real time, with data transmitted to a cloud platform and displayed in a Flutter mobile application used by drivers and administrators.

---

## **Overview**

### **Goal**
Increase efficiency of waste collection by reducing unnecessary trips, lowering operational costs, and ensuring cleaner streets.

### **Key Benefits**
- Faster and more responsive waste collection  
- Reduced bin overflow  
- Less odor and fewer pests  
- Lower fuel and labor costs  
- Improved decision-making through real-time data  

---

## **System Architecture**
Baseer consists of three integrated components:

1. **IoT Hardware** – ESP32 + JSN-SR04T ultrasonic sensor  
2. **Cloud Backend** – Firebase Realtime Database  
3. **Mobile Application** – Flutter app for drivers and administrators  

---

## **Technology Stack**

### **Programming**
- Arduino IDE (ESP32 firmware)  
- Flutter (cross-platform mobile application)

### **Hardware**
- ESP32 Development Board  
- **JSN-SR04T Ultrasonic Sensor** (waterproof)  
- Breadboard  
- Jumper Wires  
- USB Power Module (for prototyping)

### **Cloud & Database**
- **Firebase Realtime Database** for live sensor data synchronization

### **APIs**
- **Google Maps API** for mapping and navigation

---

## **Launching Instructions**

### **1. Hardware Setup**
- Connect the **ESP32** to the **JSN-SR04T** sensor using a breadboard and jumper wires.  
- Verify correct VCC, GND, Trig, and Echo wiring.  
- Upload the Arduino code using the **Arduino IDE**.  
- Confirm sensor readings via the Serial Monitor.

### **2. Cloud Integration**
- Create a Firebase project and enable **Realtime Database**.  
- Add Firebase API key + DB URL to the ESP32 code.  
- Check that readings appear in Firebase under `/bins`.

### **3. Mobile App Setup**
Clone the repository:
```bash
git clone <repo-link>
