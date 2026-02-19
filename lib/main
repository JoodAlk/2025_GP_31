import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'firebase_options.dart'; 
import 'DriverApp/driver_login.dart'; // Matches your screenshot
import 'AdminWeb/admin_login.dart';   // Matches your screenshot

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BaseerApp());
}

class BaseerApp extends StatelessWidget {
  const BaseerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baseer System',
      theme: ThemeData(
        primaryColor: const Color(0xFF66BB6A), // Baseer Green
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
          primary: const Color(0xFF66BB6A),
        ),
      ),
      // Platform Check Logic:
      // If Web -> Admin Login. If Mobile -> Driver Login.
      home: kIsWeb ? const AdminLoginPage() : const LoginPage(),
    );
  }
}
