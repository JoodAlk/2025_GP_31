import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Password Rule Status
  bool hasUpper = false;
  bool hasLower = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasLength = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    passwordController.addListener(updatePasswordRules);
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- PASSWORD RULE CHECKER ----------------
  void updatePasswordRules() {
    String pass = passwordController.text;

    setState(() {
      hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
      hasLower = RegExp(r'[a-z]').hasMatch(pass);
      hasNumber = RegExp(r'[0-9]').hasMatch(pass);
      hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass);
      hasLength = pass.length >= 8;
    });
  }

  // Show Popup
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
          ),
        ],
      ),
    );
  }

  // Hash Password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Password overall validation
  bool isPasswordValid() {
    return hasUpper && hasLower && hasNumber && hasSpecial && hasLength;
  }

  // Saudi phone validation (+9665XXXXXXXX)
  bool isPhoneValid(String phone) {
    return RegExp(r'^\+9665[0-9]{8}$').hasMatch(phone);
  }

  // --------------------- CREATE ACCOUNT ---------------------
  Future<void> createAccount() async {
    final name = nameController.text.trim();
    String phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      showPopup("Missing Fields", "Please fill all fields.");
      return;
    }

    // Convert to +9665XXXXXXX
    if (phone.startsWith("5")) {
      phone = "+966$phone";
    }

    if (!isPhoneValid(phone)) {
      showPopup("Invalid Phone", "Enter a valid Saudi number: 5XXXXXXXX");
      return;
    }

    if (!isPasswordValid()) {
      showPopup("Weak Password", "Please meet all password requirements.");
      return;
    }

    final ref = FirebaseDatabase.instance.ref("Baseer/drivers");
    final snapshot = await ref.get();

    int nextNumber = snapshot.children.length + 1;
    String driverID = "D$nextNumber";

    String hashedPassword = hashPassword(password);

    await ref.child(nextNumber.toString()).set({
      "DriverID": driverID,
      "Name": name,
      "Phone": phone,
      "EmployeePass": hashedPassword,
      "IsWorking": true,
      "Language": "en",
      "AssignedBinsId": "",
      "AssignedArea": "",
      "CurrentLocation": "",
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Account Created!"),
          content: Text("Your Driver ID is: $driverID"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  // ---------------------- UI -------------------------
  Widget buildRule(bool condition, String text) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/login.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
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
                      child: Image.asset('assets/Logo.png'),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Driver Sign Up",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // NAME
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // PHONE
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "5XXXXXXXX",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // LIVE RULE CHECKMARKS
                    buildRule(hasLength, "At least 8 characters"),
                    buildRule(hasUpper, "Uppercase letter"),
                    buildRule(hasLower, "Lowercase letter"),
                    buildRule(hasNumber, "Number"),
                    buildRule(hasSpecial, "Special character"),

                    const SizedBox(height: 20),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: createAccount,
                        child: const Text(
                          "Create Account",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Log in",
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
