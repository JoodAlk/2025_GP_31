import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math'; 
import 'package:http/http.dart' as http;
import 'web_frame.dart';

class AdminDriverManagement extends StatefulWidget {
  const AdminDriverManagement({super.key});

  @override
  State<AdminDriverManagement> createState() => _AdminDriverManagementState();
}

class _AdminDriverManagementState extends State<AdminDriverManagement> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Baseer/drivers');
  final List<String> _areas = ['Riyadh-01', 'Riyadh-02', 'Riyadh-03', 'Riyadh-04'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); 

  // --- HASHING & VALIDATION ---
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  bool isPhoneValid(String phone) {
    return RegExp(r'^\+9665[0-9]{8}$').hasMatch(phone);
  }

  bool isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String generateSecurePassword() {
    const uppers = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowers = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const specials = '!@#\$%^&*';
    final rnd = Random();

    String pass = '';
    pass += uppers[rnd.nextInt(uppers.length)];
    pass += lowers[rnd.nextInt(lowers.length)];
    pass += numbers[rnd.nextInt(numbers.length)];
    pass += specials[rnd.nextInt(specials.length)];

    const all = uppers + lowers + numbers + specials;
    for (int i = 0; i < 4; i++) {
      pass += all[rnd.nextInt(all.length)];
    }

    List<String> chars = pass.split('');
    chars.shuffle(rnd);
    return chars.join('');
  }

  // --- REAL EMAILJS API ---
  Future<void> _sendEmailToDriver(String email, String name, String id, String password) async {
    // ⚠️ KEEP YOUR SERVICE ID AND PUBLIC KEY UPDATED HERE ⚠️
    const serviceId = 'service_k6q1xr4'; // From your screenshot
    const templateId = 'template_b3erohc'; // From your screenshot
    const publicKey = 'YOUR_PUBLIC_KEY'; // Replace with your key from the Account tab

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email,
            'to_name': name,
            'driver_id': id,
            'driver_password': password,
          }
        }),
      );

      if (response.statusCode == 200) {
        print("📧 [EMAIL SENT SUCCESSFULLY TO $email]");
      } else {
        print("❌ [EMAIL FAILED]: ${response.body}");
      }
    } catch (e) {
      print("❌ [EMAIL ERROR]: $e");
    }
  }

  // --- ADD DRIVER DIALOG ---
  void _showAddDriverDialog() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear(); 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {

          Future<void> createDriverAccount() async {
            final name = _nameController.text.trim();
            String phone = _phoneController.text.trim();
            final email = _emailController.text.trim();

            if (name.isEmpty || phone.isEmpty || email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red));
              return;
            }

            if (!isEmailValid(email)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid email address (e.g., name@domain.com)"), backgroundColor: Colors.red));
              return;
            }

            if (phone.startsWith("5")) phone = "+966$phone";

            if (!isPhoneValid(phone)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid Saudi number: 5XXXXXXXX"), backgroundColor: Colors.red));
              return;
            }

            final snapshot = await _dbRef.get();
            int nextNumber = 1;
            
            if (snapshot.exists) {
               if (snapshot.value is List) {
                 nextNumber = (snapshot.value as List).length;
               } else if (snapshot.value is Map) {
                 nextNumber = (snapshot.value as Map).length + 1;
               }
            }
            
            String driverID = "D$nextNumber";
            String rawPassword = generateSecurePassword(); 
            String hashedPassword = hashPassword(rawPassword); 

            await _dbRef.child(nextNumber.toString()).set({
              "DriverID": driverID,
              "Name": name,
              "Phone": phone,
              "Email": email, 
              "EmployeePass": hashedPassword,
              "IsWorking": false, 
              "Language": "en",
              "AssignedBinsId": "",
              "CurrentLocation": "",
              "AssignedArea": "None",
            });

            // TRIGGER EMAIL API
            await _sendEmailToDriver(email, name, driverID, rawPassword);

            if (!context.mounted) return;
            Navigator.pop(context); 
            
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Success", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                content: const Text("Driver added successfully. An email containing the login credentials has been sent to the driver."),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                ],
              )
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Add New Driver", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("A secure ID and password will be automatically generated and sent via email to the driver.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 14),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 14),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone Number (e.g., 5XXXXXXXX)", prefixIcon: Icon(Icons.phone))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: createDriverAccount,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
                child: const Text("Generate & Send Email", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- EDIT DRIVER DIALOG ---
  void _showEditDriverDialog(String driverKey, dynamic currentData) {
    final TextEditingController editNameController = TextEditingController(text: currentData['Name']);
    final TextEditingController editPhoneController = TextEditingController(text: currentData['Phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Driver: ${currentData['DriverID'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editNameController, 
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))
              ),
              const SizedBox(height: 14),
              TextField(
                controller: editPhoneController, 
                keyboardType: TextInputType.phone, 
                decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone))
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              String updatedPhone = editPhoneController.text.trim();
              if (updatedPhone.startsWith("5")) updatedPhone = "+966$updatedPhone";

              _dbRef.child(driverKey).update({
                'Name': editNameController.text.trim(),
                'Phone': updatedPhone,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver updated successfully!"), backgroundColor: Colors.blue));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateDriverArea(String driverKey, String newArea) {
    _dbRef.child(driverKey).update({'AssignedArea': newArea});
  }

  void _deleteDriver(String driverKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to remove this driver from the system?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _dbRef.child(driverKey).remove();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebFrame(
      activeIndex: 3, 
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Driver Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddDriverDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add New Driver", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: StreamBuilder(
                  stream: _dbRef.onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No drivers found."));

                    final rawValue = snapshot.data!.snapshot.value;
                    List<DataRow> rows = [];

                    if (rawValue is Map) {
                      rawValue.forEach((key, value) {
                        rows.add(_buildDriverRow(key.toString(), value));
                      });
                    } else if (rawValue is List) {
                      for (int i = 0; i < rawValue.length; i++) {
                        if (rawValue[i] != null) {
                          rows.add(_buildDriverRow(i.toString(), rawValue[i]));
                        }
                      }
                    }

                    // THE NEW LAYOUT BUILDER FIX
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 30, 
                                columns: const [
                                  DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Work Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Assigned Area", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: rows,
                              ),
                            ),
                          ),
                        );
                      }
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDriverRow(String key, dynamic value) {
    return DataRow(cells: [
      DataCell(Text(value['DriverID'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
      DataCell(Text(value['Name'] ?? 'N/A')),
      DataCell(Text(value['Email'] ?? 'N/A')), 
      DataCell(Text(value['Phone'] ?? 'N/A')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: value['IsWorking'] == true ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value['IsWorking'] == true ? "On Route" : "Idle", 
            style: TextStyle(color: value['IsWorking'] == true ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
      DataCell(
        DropdownButton<String>(
          value: _areas.contains(value['AssignedArea']) ? value['AssignedArea'] : null,
          hint: const Text("Assign Area"),
          underline: const SizedBox(), 
          items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (newVal) => _updateDriverArea(key, newVal!),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue), 
              onPressed: () => _showEditDriverDialog(key, value),
              tooltip: "Edit Driver",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
              onPressed: () => _deleteDriver(key),
              tooltip: "Delete Driver",
            ),
          ],
        ),
      ),
    ]);
  }
}
