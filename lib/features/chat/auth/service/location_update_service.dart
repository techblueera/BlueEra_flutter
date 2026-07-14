import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../repo/make_order_repo.dart';
import 'socket_keep_alive_service.dart';
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

    // Android: hold the foreground service so this timer keeps firing while
    // the app is backgrounded. Without it, pings stop the moment Android
    // freezes the process, the map-service auto-closes the provider after
    // 5 minutes of silence, and "go live" silently turns itself off.
    SocketKeepAliveService.setRiderLiveHold(true);

    // Ping immediately, then every 30s — no 30s gap between going live and
    // the first lastSeen stamp (discovery filters on fresh lastSeen).
    _updateLocation();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateLocation();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    SocketKeepAliveService.setRiderLiveHold(false);
  }

  /// Publish a single live-location ping to the map-service provider
  /// endpoint that feeds the customer's live-tracking SSE
  /// (`/provider/live-stream/$riderId`).
  ///
  /// The ride screens (pickup navigation / passenger destination) stream the
  /// rider's GPS locally for their own map but are not tied to the discovery
  /// "go live" 30s timer above, so during an active ride nothing was pushed to
  /// the server and the customer's map stayed frozen. Those screens call this
  /// per (throttled) GPS tick so the customer's SSE receives fresh coordinates.
  ///
  /// Returns `true` when the server accepted the ping. [RideLocationPublisher]
  /// relies on this so it can resend the last coordinate on failure.
  Future<bool> publishLocation(double lat, double lng) async {
    if (userId.isEmpty) return false;
    try {
      final response = await MakeOrderRepo().updateLiveLocationRep({
        ApiKeys.userId: userId,
        ApiKeys.lat: lat,
        ApiKeys.lng: lng,
      });
      return response.isSuccess;
    } catch (_) {
      // Best-effort — a dropped ping is corrected by the next heartbeat/tick.
      return false;
    }
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
