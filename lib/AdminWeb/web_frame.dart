import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'admin_homepage.dart';
import 'admin_login.dart';
import 'admin_bin_management.dart';
import 'admin_map.dart';
import 'admin_driver_management.dart';
import 'admin_user_session.dart'; 

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

  // Session Data
  String _dbKey = "";
  String _adminId = "Loading...";
  String _adminName = "Loading...";
  String _adminEmail = "Loading...";
  String _adminPhone = "Loading...";
  String? _adminPermission;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final session = await AdminUserSession.getSession();
    setState(() {
      _dbKey = session['dbKey'] ?? "";
      _adminId = session['id'] ?? "Unknown";
      _adminName = session['name'] ?? "Unknown";
      _adminEmail = session['email'] ?? "Unknown";
      _adminPhone = session['phone'] ?? "Unknown";
      _adminPermission = session['permissionKey'];
    });
  }

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

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    await AdminUserSession.clearSession(); 
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false, 
    );
  }

  // --- EDIT PROFILE DIALOG LOGIC ---
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _adminName);
    final emailCtrl = TextEditingController(text: _adminEmail);
    final phoneCtrl = TextEditingController(text: _adminPhone);
    final permissionCtrl = TextEditingController(text: _adminPermission ?? "");

    // Check if the admin currently has a permission key
    bool hasPermissionKey = _adminPermission != null && _adminPermission!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email Address")),
              
              // ONLY show this field if the admin already has a Permission Key
              if (hasPermissionKey) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: permissionCtrl, 
                  decoration: const InputDecoration(labelText: "Permission Key")
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
            onPressed: () async {
              
              // 1. Update Firebase
              final updateData = {
                'Name': nameCtrl.text.trim(),
                'Phone': phoneCtrl.text.trim(),
                'Email': emailCtrl.text.trim(),
              };
              
              String? newPermission;
              // Only process permission key update if they are allowed to have it
              if (hasPermissionKey) {
                newPermission = permissionCtrl.text.trim();
                if (newPermission.isNotEmpty) {
                  updateData['PermissionKey'] = newPermission;
                }
              }

              await FirebaseDatabase.instance.ref('Baseer/admins/$_dbKey').update(updateData);

              // 2. Update local session & UI
              await AdminUserSession.saveSession(
                dbKey: _dbKey,
                id: _adminId, 
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                permissionKey: hasPermissionKey ? newPermission : _adminPermission, 
              );
              
              await _loadSessionData(); 

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
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
                        width: 320,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE), 
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(4, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35, 
                                    backgroundColor: Colors.blue.shade200, 
                                    child: const Icon(Icons.person, size: 40, color: Colors.white)
                                  ),
                                  const SizedBox(height: 10),
                                  const Text("Admin Profile", style: TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.black12, height: 30),
                            
                            _buildProfileRow("ID", _adminId),
                            _buildProfileRow("Name", _adminName),
                            _buildProfileRow("Phone", _adminPhone),
                            _buildProfileRow("Email", _adminEmail),
                            
                            if (_adminPermission != null && _adminPermission!.isNotEmpty)
                              _buildProfileRow("Key", _adminPermission!),
                            
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _showEditProfileDialog, 
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
                                    onPressed: _handleLogout, 
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
          Container(
            width: 180,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              'assets/Logo.png', 
              fit: BoxFit.contain,
              errorBuilder: (c, o, s) => const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF81C784), size: 40),
            ),
          ),
          
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
