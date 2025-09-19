class StringUtils {
  /// Case-insensitive string comparison
  static bool equalsIgnoreCase(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }

  /// Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Capitalize first letter
  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
