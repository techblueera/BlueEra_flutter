
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DialogService extends GetxService {
  static const String lastShownKey = "last_dialog_shown";

  Future<DialogService> init() async {
    return this;
  }

  /// returns true if dialog should be shown
  Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(lastShownKey);

    if (lastShown == null) {
      return true; // never shown before
    }

    final lastShownDate = DateTime.fromMillisecondsSinceEpoch(lastShown);
    final now = DateTime.now();

    // Check 24 hours difference
    if (now.difference(lastShownDate).inHours >= 24) {
      return true;
    }

    return false;
  }

  /// save the current time as last shown time
  Future<void> saveDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastShownKey, DateTime.now().millisecondsSinceEpoch);
  }
}