import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'login_page.dart'; // Import Login Page

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyBgzhlooyfDirhNsYww63URZfMhhl2DDhE',
    appId: '1:1080961954717:web:b681c3466cac60d704f574',
    messagingSenderId: '1080961954717',
    projectId: 'baseer-40cf2',
    databaseURL:
        'https://baseer-40cf2-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    developer.log('Firebase initialized.', name: 'APP');
    await addThreeBins();

  } catch (e) {
    developer.log('Error initializing Firebase: $e', name: 'ERROR');
    runApp(const MaterialApp(
        home: Scaffold(body: Center(child: Text('Firebase Init Failed.')))));
    return;
  }

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseer Driver Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF66BB6A),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginPage(), // Starts at Login
    );
  }
}
// TEMP FUNCTION: Adds 3 bins matching the screenshot structure
Future<void> addThreeBins() async {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('Baseer/bins');

  // Helper to format date like the screenshot (Optional, or just use toString)
  String nowStr = DateTime.now().toString(); 
  
  // --- BIN 6: Medium (Half) ---
  await dbRef.child('BIN-002').set({
    'AreaId': 'Riyadh-03',
    'AssignedDriverId': 'N/A',
    'Capacity': 200,
    'FillLevel': 45,
    'FreeSpace': 55,
    'IsAssigned': false,
    'IsOverflowing': false,
    'LastEmptied': nowStr,
    'Location': {
      'Latitude': 24.7100,
      'Longitude': 46.6500,
    },
    'Name': 'Bin-002',
    'Sensor': {
      'BatteryPct': 90,
      'Id': 'esp-66BC'
    },
    'Status': 'OK',
    'lastUpdate': nowStr,
  });
print("bin002");

}