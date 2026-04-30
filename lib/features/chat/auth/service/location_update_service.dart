import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../repo/make_order_repo.dart';
class LiveLocationService {
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
