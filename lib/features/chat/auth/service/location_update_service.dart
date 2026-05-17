import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../repo/make_order_repo.dart';
// Singleton — every `LiveLocationService()` call returns the same
// object so the timer started by [ViewPersonalDetailsController] is
// the same one [LogoutHelper] cancels. Previously each `new` made a
// fresh instance, and `LiveLocationService().stop()` on logout left
// the original timer running forever, hammering /provider/location
// with a stale userId.
class LiveLocationService {
  LiveLocationService._();
  static final LiveLocationService _instance = LiveLocationService._();
  factory LiveLocationService() => _instance;

  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateLocation();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  Future<void> _updateLocation() async {
    // Belt-and-braces: if userId was cleared between ticks (logout
    // racing the periodic callback), bail and stop so the timer
    // doesn't keep posting an empty user.
    if (userId.isEmpty) {
      stop();
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await MakeOrderRepo().updateLiveLocationRep({
        ApiKeys.userId: userId,
        ApiKeys.lat: position.latitude,
        ApiKeys.lng: position.longitude,
      });

      if (response.isSuccess) {
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {

    }
  }
}
