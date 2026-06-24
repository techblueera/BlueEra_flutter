import 'dart:convert';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// Lightweight persistence for the customer's ongoing ride/booking so the
/// "Your Ongoing Ride/Booking" card survives an app kill + relaunch.
///
/// Only a small display snapshot is stored (rider name/image/contact, pickup
/// & drop, coords, the order id and the assigned rider id). On relaunch the
/// snapshot rebuilds the card immediately and the order-status API confirms the
/// ride is still active (clearing it otherwise). Cleared by the
/// `ride:completed` / cancel handlers.
class OngoingRideStore {
  static const String _key = 'customer_ongoing_ride';

  static Future<void> save(Map<String, dynamic> data) async {
    try {
      await SharedPreferenceUtils.setSecureValue(_key, jsonEncode(data));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> read() async {
    try {
      final raw = await SharedPreferenceUtils.getSecureValue(_key);
      if (raw is! String || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// secure_storage treats a null write as a no-op, so "clear" writes an empty
  /// string which [read] then treats as absent.
  static Future<void> clear() async {
    try {
      await SharedPreferenceUtils.setSecureValue(_key, '');
    } catch (_) {}
  }
}
