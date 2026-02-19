// lib/user_session.dart

class UserSession {
  // Static variables to hold the current user's data globally
  static String driverId = '';
  static String name = '';
  static String phone = '';
  static String assignedArea = 'Riyadh-D1'; // Default or fetched from DB
  static String employeeNo = '';
  static String selectedAreaFilter = 'All';

  // Function to clear data on Logout
  static void clearSession() {
    driverId = '';
    name = '';
    phone = '';
    assignedArea = '';
    employeeNo = '';
    selectedAreaFilter = 'All';
  }
}