import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/services.dart';
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

  static const MethodChannel _nativeLocationChannel =
      MethodChannel('ai.bluecs.app/rider_location');

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

    // Android KILL-mode coverage: hand the native foreground-location service
    // the creds so it can POST location every 60s even after the app process
    // is swipe/OS-killed (a Dart Timer dies with the engine). The Dart timer
    // below still covers foreground/background and sends a FRESH GPS fix; the
    // native service is the killed-state fallback (last-known fix).
    _startNativeKillModePinger();

    // Ping immediately, then every 60s while the rider is live — no gap between
    // going live and the first lastSeen stamp (discovery filters on fresh
    // lastSeen; map-service auto-closes after 5 min of silence, so 60s leaves
    // ample margin even if a couple of pings are missed).
    _updateLocation();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _updateLocation();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    SocketKeepAliveService.setRiderLiveHold(false);
    _stopNativeKillModePinger();
  }

  // iOS cannot run a 1-min timer in a killed app (platform limit) — this is an
  // Android-only foreground-location service. No-op elsewhere / on error.
  Future<void> _startNativeKillModePinger() async {
    if (!Platform.isAndroid) return;
    final token = authTokenGlobal ?? '';
    final base = baseUrl ?? '';
    if (userId.isEmpty || token.isEmpty || base.isEmpty) return;
    try {
      await _nativeLocationChannel.invokeMethod('start', {
        'token': token,
        'userId': userId,
        'baseUrl': base,
      });
    } catch (_) {
      // Native side unavailable — the Dart timer still covers fg/bg.
    }
  }

  Future<void> _stopNativeKillModePinger() async {
    if (!Platform.isAndroid) return;
    try {
      await _nativeLocationChannel.invokeMethod('stop');
    } catch (_) {}
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
