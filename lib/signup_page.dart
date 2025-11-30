import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'login_page.dart'; // <--- Added to allow navigation back

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
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ----------- HELPERS: Show Popup ----------
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

  // ----------- HASH PASSWORD ----------
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ----------- PASSWORD VALIDATION ----------
  bool isPasswordValid(String password) {
    final upper = RegExp(r'[A-Z]');
    final lower = RegExp(r'[a-z]');
    final number = RegExp(r'[0-9]');
    final special = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');

    return password.length >= 8 &&
        upper.hasMatch(password) &&
        lower.hasMatch(password) &&
        number.hasMatch(password) &&
        special.hasMatch(password);
  }

  // ----------- PHONE VALIDATION (Saudi) ----------
  bool isPhoneValid(String phone) {
    return RegExp(r'^\+9665[0-9]{8}$').hasMatch(phone);
  }

  // ----------- SIGN UP FUNCTION ----------
  Future<void> createAccount() async {
    final name = nameController.text.trim();
    String phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      showPopup("Missing Fields", "Please fill all fields.");
      return;
    }

    if (!phone.startsWith("+966")) {
      if (phone.startsWith("5")) {
        phone = "+966$phone";
      } else {
        showPopup("Invalid Phone", "Phone number must start with 5 or +9665.");
        return;
      }
    }

    if (!isPhoneValid(phone)) {
      showPopup("Invalid Phone Number",
          "Enter a valid Saudi phone number:\n\n+9665XXXXXXXX");
      return;
    }

    if (!isPasswordValid(password)) {
      showPopup(
        "Weak Password",
        "Password must contain:\n"
            "• At least 8 characters\n"
            "• Upper & lower case letters\n"
            "• A number\n"
            "• A special character",
      );
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
      "CurrentLocation": "",
    });

    // SUCCESS POPUP
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Account Created!"),
          content: Text("Your Driver ID is: $driverID"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close popup
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ); // Go to Login Page
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                      "Driver Sign Up",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

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

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+9665XXXXXXXX",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password + Eye icon
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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
                        onPressed: createAccount,
                        child: const Text(
                          "Create Account",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    // --- NEW SECTION: LINK TO LOG IN ---
                    const SizedBox(height: 18),
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
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
                    // -----------------------------------
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