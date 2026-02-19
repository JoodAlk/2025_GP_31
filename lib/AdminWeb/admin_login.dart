import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'admin_homepage.dart';
import 'admin_signup.dart';
import 'admin_user_session.dart'; // IMPORT THE SESSION CLASS

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Baseer');

  final _formKey = GlobalKey<FormState>();

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();
    final hashed = _hashPassword(password);

    setState(() => _isLoading = true);

    try {
      final adminsSnap = await _dbRef.child("admins").get();

      if (!adminsSnap.exists || adminsSnap.value == null) {
        _showDialog("Error", "No admins found.");
        return;
      }

      final raw = adminsSnap.value;
      bool found = false;
      
      // Variables to temporarily hold the data of the matched admin
      String? matchedDbKey;
      Map<dynamic, dynamic>? matchedAdminData;

      // Notice I added 'key' to this function to track the Firebase Node ID
      void tryLogin(String key, dynamic admin) {
        if (admin == null || admin is! Map) return;

        final email = (admin['Email'] ?? '').toString().trim();
        final phone = (admin['Phone'] ?? '').toString().trim();
        final storedPass = (admin['EmployeePass'] ?? '').toString().trim();

        String normalizedIdentifier = identifier;

        if (RegExp(r'^5\d{8}$').hasMatch(identifier)) {
          normalizedIdentifier = "+966$identifier";
        }

        if ((normalizedIdentifier == email || normalizedIdentifier == phone) &&
            storedPass == hashed) {
          found = true;
          matchedDbKey = key;
          matchedAdminData = admin;
        }
      }

      if (raw is List) {
        for (int i = 0; i < raw.length; i++) {
          tryLogin(i.toString(), raw[i]);
          if (found) break;
        }
      } else if (raw is Map) {
        raw.forEach((k, v) {
          if (!found) tryLogin(k.toString(), v);
        });
      }

      if (!found) {
        _showDialog("Login Failed", "Invalid credentials.");
        return;
      }

      // --- SAVE TO SESSION ---
      await AdminUserSession.saveSession(
        dbKey: matchedDbKey!,
        id: matchedAdminData?['AdminID'] ?? matchedDbKey, // Fallback if AdminID isn't set
        name: matchedAdminData?['Name'] ?? 'Unknown Admin',
        email: matchedAdminData?['Email'] ?? '',
        phone: matchedAdminData?['Phone'] ?? '',
        permissionKey: matchedAdminData?['PermissionKey'],
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    } catch (e) {
      _showDialog("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/loginn.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/logo.png", height: 60),
                      const SizedBox(height: 10),
                      const Text(
                        "Admin Login",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: identifierController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: "Email or Phone Number",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: "Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No admin account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminSignUpPage()),
                              );
                            },
                            child: const Text("Sign up"),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
