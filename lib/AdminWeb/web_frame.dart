import 'package:flutter/material.dart';
import 'admin_homepage.dart';
import 'admin_login.dart';
import 'admin_bin_management.dart';
import 'admin_map.dart';
import 'admin_driver_management.dart';

class WebFrame extends StatefulWidget {
  final Widget body;
  final int activeIndex; 

  const WebFrame({
    super.key, 
    required this.body, 
    this.activeIndex = -1,
  });

  @override
  State<WebFrame> createState() => _WebFrameState();
}

class _WebFrameState extends State<WebFrame> {
  bool _isProfileOpen = false;

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), 
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(),
              Expanded(child: widget.body),
            ],
          ),

          if (_isProfileOpen)
            GestureDetector(
              onTap: () => setState(() => _isProfileOpen = false),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 90, 
                      right: 24, 
                      child: Container(
                        width: 280,
                        height: 450,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF37474F), 
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(4, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Column(
                                children: [
                                  CircleAvatar(radius: 35, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 40, color: Colors.white)),
                                  SizedBox(height: 10),
                                  Text("Admin Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 30),
                            _buildProfileRow("ID", "A1"),
                            _buildProfileRow("Name", "Sarah Khaled"),
                            _buildProfileRow("Role", "System Admin"),
                            _buildProfileRow("Email", "SarahKhaled@gmail.com"),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF81C784), 
                                      side: const BorderSide(color: Color(0xFF81C784), width: 3.0),
                                    ),
                                    child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                                        (route) => false, 
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: const Text("Logout", style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80, 
      decoration: BoxDecoration(
        color: const Color(0xFF81C784), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // LOGO SECTION: White background just for the left side
          Container(
            width: 180,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              'assets/Logo.png', 
              fit: BoxFit.contain,
              errorBuilder: (c, o, s) => const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF81C784), size: 40),
            ),
          ),
          
          // NAVIGATION BUTTONS
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.dashboard, "Dashboard", 0, onTap: () {
                  if (widget.activeIndex != 0) _navigate(context, const AdminHomePage());
                }),
                _buildNavItem(Icons.delete_outline, "Bins", 1, onTap: () {
                  if (widget.activeIndex != 1) _navigate(context, const AdminBinManagement());
                }),
                _buildNavItem(Icons.map_outlined, "Map", 2, onTap: () {
                  if (widget.activeIndex != 2) _navigate(context, const AdminMapPage());
                }),
                _buildNavItem(Icons.drive_eta_outlined, "Drivers", 3, onTap: () {
                  if (widget.activeIndex != 3) _navigate(context, const AdminDriverManagement());
                }),
                _buildNavItem(Icons.person, "Profile", -1, onTap: () {
                  setState(() => _isProfileOpen = !_isProfileOpen);
                }),
              ],
            ),
          ),
          
          // Empty space to balance the logo width on the far right
          const SizedBox(width: 180), 
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {required VoidCallback onTap}) {
    final isActive = widget.activeIndex == index; 
    final color = isActive ? Colors.white : Colors.white60;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}