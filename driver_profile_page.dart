import 'package:flutter/material.dart';
import 'app_frame.dart'hide LoginPage; 
import 'login_page.dart'; 
import 'user_session.dart'; 

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  // Function to handle logout
  void _handleLogout(BuildContext context) {
    // 1. Clear the session data
    UserSession.clearSession();

    // 2. Navigate back to Login Page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (Route<dynamic> route) => false, 
    );
  }

  IconData getIconForField(String field) {
    switch (field) {
      case 'DriverID': return Icons.fingerprint;
      case 'Phone': return Icons.phone;
      case 'Employee No': return Icons.work;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PREPARE DATA FROM SESSION ---
    final Map<String, String> driverData = {
      'Name': UserSession.name.isNotEmpty ? UserSession.name : 'Guest',
      'DriverID': UserSession.driverId.isNotEmpty ? UserSession.driverId : 'N/A',
      'Phone': UserSession.phone.isNotEmpty ? UserSession.phone : 'N/A',
    };

    return AppFrame(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Welcome, ${driverData['Name']}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 40, thickness: 1),
            
            // Driver Information List
            ...driverData.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(getIconForField(entry.key), color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    '${entry.key}:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )).toList(),

            const SizedBox(height: 40),
            
            // Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context), 
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}