import 'package:flutter/material.dart';
import 'driver_homepage.dart'; // <--- FIX: Import this to find BinDashboardScreen
import 'driver_map.dart'; 
import 'driver_profile.dart'; 
import 'driver_route_loader.dart';


// --- Placeholder for Aljazzi's Login Page (Required for Logout) ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Login')),
      body: const Center(
        child: Text(
          'Successfully Logged Out.\n(Placeholder for Login Page)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------

class AppFrame extends StatelessWidget {
  final Widget child; 
  final int currentIndex; 

  const AppFrame({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  void _navigateAndReplace(BuildContext context, Widget target) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (Route<dynamic> route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    // Color for the Footer (Light Green)
    final Color footerColor = const Color(0xFF81C784); 

    return Scaffold(
      // === Common Header (AppBar) ===
      appBar: AppBar(
        toolbarHeight: 100, 
        backgroundColor: Colors.white, // <--- CHANGED: White background
        elevation: 0, // Removed shadow for a cleaner look
        automaticallyImplyLeading: false,
        titleSpacing: 20, 
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/Logo.png', 
            height: 80, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Changed fallback icon color to Green so it's visible on White
              return const Icon(Icons.remove_red_eye_outlined, color: Colors.green, size: 40);
            },
          ),
        ),
      ),

      // === Unique Page Content ===
      body: child,

      // === Common Footer (BottomAppBar) ===
      bottomNavigationBar: BottomAppBar(
        color: footerColor, // <--- KEPT: Green background
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children: [
            _buildNavButton(
              context,
              icon: Icons.account_circle,
              label: 'Profile',
              target: const DriverProfilePage(),
              isSelected: currentIndex == 0,
            ),
            _buildNavButton(
  context,
  icon: Icons.alt_route,
  label: 'Route',
  target: const DriverRouteLoaderPage(),
  isSelected: currentIndex == 2,
),

            _buildNavButton(
              context,
              icon: Icons.place,
              label: 'Map',
              target: const DriverMapPage(),
              isSelected: currentIndex == 3,
            ),
            _buildNavButton(
              context,
              icon: Icons.home,
              label: 'Home',
              target: const BinDashboardScreen(), 
              isSelected: currentIndex == 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Widget? target,
    required bool isSelected,
  }) {
    // Colors for the Footer Buttons
    final color = isSelected 
        ? Colors.white      // Selected: Pure White
        : Colors.white60;   // Unselected: Faded White

    return InkWell(
      onTap: () {
        if (target != null && !isSelected) {
          _navigateAndReplace(context, target);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
