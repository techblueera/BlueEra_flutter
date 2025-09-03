class UserSession {
  // Private constructor
  UserSession._privateConstructor();

  // Singleton instance
  static final UserSession _instance = UserSession._privateConstructor();

  // Factory constructor
  factory UserSession() {
    return _instance;
  }

  // User data fields
  String? mobileNumber;
  String? userType;
  String? imagePath;

  // Optional: Clear all session data
  void clear() {
    mobileNumber = null;
    userType = null;
    imagePath = null;
  }
}
