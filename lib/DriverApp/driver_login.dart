import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'driver_signup.dart';   // Corrected name
import 'driver_homepage.dart'; // Corrected name
import 'driver_user_session.dart'; // Corrected name

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // POPUP MESSAGE
  void showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // HASH
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // LOGIN FUNCTION
  Future<void> loginDriver() async {
    final driverID = idController.text.trim();
    final password = passwordController.text.trim();

    if (driverID.isEmpty || password.isEmpty) {
      showPopup("Missing Fields", "Please enter ID and Password.");
      return;
    }

    final ref = FirebaseDatabase.instance.ref("Baseer/drivers");
    final snapshot = await ref.get();

    bool success = false;

    if (snapshot.exists) {
      for (var driver in snapshot.children) {
        final data = driver.value as Map;

        if (data["DriverID"] == driverID) {
          final hashedInput = hashPassword(password);

          if (hashedInput == data["EmployeePass"]) {
            success = true;

            // --- SAVE DATA TO SESSION ---
            UserSession.driverId = data["DriverID"].toString();
            UserSession.name = data["Name"].toString();
            UserSession.phone = data["Phone"].toString();

            // LOGIN SUCCESS → GO TO MAIN PAGE
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BinDashboardScreen()),
              );
            }
            break;
          }
        }
      }
    }

    if (!success) {
      showPopup("Login Failed", "Invalid Driver ID or Password.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/login.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 90,
                      child: Image.asset(
                        'assets/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Driver Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        labelText: "Driver ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: loginDriver,
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Colors.black87), 
                          children: [
                            TextSpan(text: "If you don't have an account, "),
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(
                                color: Colors.blue, 
                                decoration: TextDecoration.underline, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}