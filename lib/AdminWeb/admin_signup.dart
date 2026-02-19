import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'admin_login.dart'; // <-- Fixed Import

class AdminSignUpPage extends StatefulWidget {
  const AdminSignUpPage({super.key});

  @override
  State<AdminSignUpPage> createState() => _AdminSignUpPageState();
}

class _AdminSignUpPageState extends State<AdminSignUpPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Baseer');

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController permissionController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Password rules
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  void _updatePasswordRules(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpper = RegExp(r'[A-Z]').hasMatch(password);
      _hasLower = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasSpecial =
          RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/~`+=;]').hasMatch(password);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUpper && _hasLower && _hasNumber && _hasSpecial;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final rawPhone = phoneController.text.trim();
    final phone = "+966$rawPhone";  // <-- this is what gets saved

    final permissionKey = permissionController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    _updatePasswordRules(password);

    if (!_isPasswordValid) {
      _showDialog("Weak Password", "Please meet password rules.");
      return;
    }

    if (password != confirm) {
      _showDialog("Mismatch", "Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Permission key stored at Baseer/admins/1/PermissionKey
      final permissionSnap = await _dbRef.child("admins/2/PermissionKey").get();

      if (!permissionSnap.exists || permissionSnap.value == null) {
        _showDialog("Error", "Permission key is not set in the database.");
        return;
      }

      final dbKey = permissionSnap.value.toString().trim();

      if (dbKey != permissionKey) {
        _showDialog("Unauthorized", "Invalid permission key.");
        return;
      }

      // ✅ Load admins (can be List OR Map)
      final adminsSnap = await _dbRef.child("admins").get();

      int maxKey = 0;

      void checkDuplicate(dynamic admin) {
        if (admin == null || admin is! Map) return;

        final aEmail = (admin['Email'] ?? '').toString().trim();
        final aPhone = (admin['Phone'] ?? '').toString().trim();

        if (aEmail == email) {
          throw Exception("Email already registered.");
        }
        if (aPhone == phone) {
          throw Exception("Phone already registered.");
        }
      }

      if (adminsSnap.exists && adminsSnap.value != null) {
        final raw = adminsSnap.value;

        if (raw is List) {
          for (int i = 0; i < raw.length; i++) {
            final admin = raw[i];
            if (admin != null) {
              if (i > maxKey) maxKey = i;
              checkDuplicate(admin);
            }
          }
        } else if (raw is Map) {
          final map = Map<dynamic, dynamic>.from(raw);
          map.forEach((k, v) {
            final keyNum = int.tryParse(k.toString()) ?? 0;
            if (keyNum > maxKey) maxKey = keyNum;
            checkDuplicate(v);
          });
        }
      }

      final nextId = (maxKey == 0) ? 1 : (maxKey + 1);

      // ✅ Save (NO PermissionKey in new admin)
      await _dbRef.child("admins").child(nextId.toString()).set({
        "AdminID": "A$nextId",
        "Email": email,
        "Phone": phone,
        "EmployeePass": _hashPassword(password),
        "Name": name,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      _showDialog("Error", msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              "assets/loginn.png",
              fit: BoxFit.cover,
            ),
          ),

          // Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/logo.png", height: 55),
                        const SizedBox(height: 10),
                        const Text(
                          "Admin Sign Up",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 18),

                        _textFormField(
                          controller: nameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 12),

                        _textFormField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Required";
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone with inline rules: must start 5, 9 digits
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone),
                            labelText: "Phone Number (5XXXXXXXX)",
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            final v = (value ?? "").trim();
                            if (v.isEmpty) return "Phone number required";
                            if (!RegExp(r'^[0-9]+$').hasMatch(v)) return "Only numbers allowed";
                            if (!v.startsWith("5")) return "Phone must start with 5";
                            if (v.length != 9) return "Phone must be 9 digits";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _textFormField(
                          controller: permissionController,
                          label: "Permission Key",
                          icon: Icons.security,
                          validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 12),

                        _textFormField(
                          controller: passwordController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          onChanged: _updatePasswordRules,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 12),

                        _textFormField(
                          controller: confirmController,
                          label: "Confirm Password",
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: 10),

                        // Rules under confirm
                        _buildPasswordRules(),

                        const SizedBox(height: 16),

                        // ✅ Green button + white text
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
                            onPressed: _isLoading ? null : _signUp,
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
                                    "Create Account",
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
                            const Text("Already have an account? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                                );
                              },
                              child: const Text("Login"),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _ruleRow(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, size: 16, color: ok ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: ok ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPasswordRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ruleRow("At least 8 characters", _hasMinLength),
        const SizedBox(height: 4),
        _ruleRow("Uppercase letter", _hasUpper),
        const SizedBox(height: 4),
        _ruleRow("Lowercase letter", _hasLower),
        const SizedBox(height: 4),
        _ruleRow("Number", _hasNumber),
        const SizedBox(height: 4),
        _ruleRow("Special character", _hasSpecial),
      ],
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    permissionController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}
