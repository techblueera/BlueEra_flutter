import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

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

  /// How often a live provider publishes their position.
  static const Duration _interval = Duration(seconds: 30);

  /// A failed publish is retried inside the same tick rather than waiting a
  /// whole interval — a dropped ping on a flaky connection is the common case,
  /// and the map-service closes a provider after 5 minutes of silence.
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetries = 2;

  Timer? _timer;
  bool _isRunning = false;

  /// True once the rider has been told location is unusable, so the warning is
  /// shown once per live session instead of on every tick.
  bool _warnedUnavailable = false;

  /// Guards against overlapping ticks: a slow GPS fix + retries can outlast the
  /// interval, and two publishes racing would send positions out of order.
  bool _tickInFlight = false;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _warnedUnavailable = false;

    // Android: hold the foreground service so this timer keeps firing while
    // the app is backgrounded. Without it, pings stop the moment Android
    // freezes the process, the map-service auto-closes the provider after
    // 5 minutes of silence, and "go live" silently turns itself off.
    SocketKeepAliveService.setRiderLiveHold(true);

    // Android KILL-mode coverage: hand the native foreground-location service
    // the creds so it can POST location on its own schedule even after the app
    // process is swipe/OS-killed (a Dart Timer dies with the engine). The Dart
    // timer below still covers foreground/background and sends a FRESH GPS fix;
    // the native service is the killed-state fallback (last-known fix).
    _startNativeKillModePinger();

    // Ping immediately, then every [_interval] while live — no gap between
    // going live and the first lastSeen stamp (discovery filters on fresh
    // lastSeen; map-service auto-closes after 5 min of silence, so 30s survives
    // several consecutive failures).
    unawaited(_tick());
    _timer = Timer.periodic(_interval, (_) => _tick());

    // Permission is requested AFTER the first tick is scheduled: if it is
    // already granted (the normal case, since go-live gates on it) nothing is
    // shown, and if it was revoked since the toggle we ask rather than failing
    // silently for the whole session.
    unawaited(_ensureLocationUsable());
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
      final response = await MapServiceRepo()
          .publishProviderLocationRepo(lat: lat, lng: lng);
      return response.isSuccess;
    } catch (_) {
      // Best-effort — a dropped ping is corrected by the next heartbeat/tick.
      return false;
    }
  }

  /// One heartbeat: get a fix, publish it, retry a couple of times if the
  /// publish fails.
  ///
  /// Silent by design. A failed ping used to raise a snackbar, so a rider on a
  /// patchy connection got an error toast every interval for something they
  /// can't act on and that the next tick fixes by itself. The one thing worth
  /// interrupting for — location switched off or permission revoked — is
  /// handled in [_ensureLocationUsable], once per session.
  Future<void> _tick() async {
    // Belt-and-braces: if userId was cleared between ticks (logout
    // racing the periodic callback), bail and stop so the timer
    // doesn't keep posting an empty user.
    if (userId.isEmpty) {
      stop();
      return;
    }
    if (_tickInFlight) return;
    _tickInFlight = true;
    try {
      final position = await _currentPosition();
      if (position == null) {
        // No fix at all — usually services off or permission gone. Check once,
        // and tell the rider if it's something only they can fix.
        await _ensureLocationUsable();
        return;
      }

      for (var attempt = 0; attempt <= _maxRetries; attempt++) {
        if (!_isRunning) return;
        final sent =
            await publishLocation(position.latitude, position.longitude);
        if (sent) return;
        if (attempt < _maxRetries) await Future.delayed(_retryDelay);
      }
    } finally {
      _tickInFlight = false;
    }
  }

  /// Make sure the device can actually produce a location, and say so when it
  /// can't. Runs on go-live and whenever a tick comes back empty.
  ///
  /// Three distinct failures, three different fixes — a single "location error"
  /// would leave the rider guessing which one they're in:
  ///   • location services off  → offer to open the OS location settings;
  ///   • permission not granted → ask for it (foreground, then background);
  ///   • permission denied forever → send them to app settings.
  Future<void> _ensureLocationUsable() async {
    if (!_isRunning) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _warnOnce(
          'Turn on location to keep receiving orders',
          onTap: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Goes through the shared service so the foreground → background
        // escalation matches what the go-live permission screen does.
        await GoLivePermissionService.requestBackgroundLocation();
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _warnOnce(
          'Location permission is blocked. Allow it to stay live.',
          onTap: Geolocator.openAppSettings,
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        _warnOnce('Allow location access to keep receiving orders');
        return;
      }

      // Recovered — a later failure is allowed to warn again.
      _warnedUnavailable = false;
    } catch (_) {
      // Never let a permission probe take the heartbeat down.
    }
  }

  void _warnOnce(String message, {VoidCallback? onTap}) {
    if (_warnedUnavailable) return;
    _warnedUnavailable = true;
    commonSnackBar(message: message);
    // The snackbar is the notice; opening the settings screen is the fix, and
    // doing it right away is what the rider would do next anyway.
    onTap?.call();
  }

  /// A fix for this tick, or null.
  ///
  /// Bounded: `getCurrentPosition` with no time limit can hang for as long as
  /// the GPS takes, which on a 60-second timer means ticks stacking up behind
  /// a request that may never return. If a fresh fix doesn't arrive in 20s the
  /// last known one is published instead — a slightly stale position keeps the
  /// provider's `lastSeen` alive, which is what stops the map-service closing
  /// them; no position at all does not.
  Future<Position?> _currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
