import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'socket_keep_alive_service.dart';

/// What [LiveLocationService.verifyKillModeCoverage] should do about the
/// native killed-state location service's current state.
enum KillModeAction {
  /// The platform still refuses to promote it — tell the rider.
  warn,

  /// It is allowed again but isn't running; start it without saying anything.
  restart,

  /// Coverage is fine; drop any recorded failure so a later one can warn again.
  clear,
}

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

  /// Twin of [_warnedUnavailable] for killed-state coverage. Separate flag on
  /// purpose: the two failures are independent (location can be perfectly
  /// usable while the app is open and still be refused to the background
  /// service), and one recovering must not silence the other.
  bool _warnedKillModeDegraded = false;

  /// Guards against overlapping ticks: a slow GPS fix + retries can outlast the
  /// interval, and two publishes racing would send positions out of order.
  bool _tickInFlight = false;

  /// [userInitiated] distinguishes a rider tapping Go Live from the restore /
  /// scheduler / backend-confirmation paths that also call this. It only
  /// affects how a missing background-location grant is handled: a tap earns
  /// the permission flow, a silent restore gets the notice without having
  /// Settings thrown at it on app launch. See [verifyKillModeCoverage].
  Future<void> start({bool userInitiated = false}) async {
    if (_isRunning) return;
    _isRunning = true;
    _warnedUnavailable = false;
    _warnedKillModeDegraded = false;

    // iOS-only, despite the name. `setRiderLiveHold` starts the 10s
    // socket-health timer (alive under CallKit's VoIP entitlement) and makes a
    // later call-end `stop()` a no-op there, so ending a call while still live
    // does not tear down the provider's socket.
    //
    // It deliberately does NOT touch the Android call keep-alive
    // (`CallKeepAliveService`, a `phoneCall` foreground service): that posts a
    // "Call in progress" notification, which a rider who is merely online is
    // not on. Backgrounded pings on Android are covered instead by
    // [_startNativeKillModePinger] below, which drives
    // `RiderLocationForegroundService` — a `location` foreground service that
    // reads GPS and POSTs without the Flutter engine, so it survives the
    // process being frozen or killed. That is what actually keeps the provider
    // from being auto-closed after 5 minutes of silence.
    SocketKeepAliveService.setRiderLiveHold(true);

    // Android KILL-mode coverage: hand the native foreground-location service
    // the creds so it can POST location on its own schedule even after the app
    // process is swipe/OS-killed (a Dart Timer dies with the engine). The Dart
    // timer below still covers foreground/background and sends a FRESH GPS fix;
    // the native service is the killed-state fallback (last-known fix).
    //
    // ...then confirm it actually took. A refusal is a silent no-op by design
    // (the service must not crash over it), so "we asked" is not the same as
    // "the rider is covered" — [verifyKillModeCoverage] is what turns a refusal
    // into something the rider is told about. It decides on the live permission
    // flags rather than the native breadcrumb, which matters here: the channel
    // returns long before the service has tried to promote itself, so the
    // breadcrumb for THIS attempt may not be written yet. `allowRestart: false`
    // for the same reason — a second start would race the one in flight.
    unawaited(_startNativeKillModePinger().then(
      (_) => verifyKillModeCoverage(
        promptToFix: userInitiated,
        allowRestart: false,
      ),
    ));

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

    // Gate on the runtime grant BEFORE asking the platform to start a
    // `location` foreground service.
    //
    // Declaring ACCESS_BACKGROUND_LOCATION in the manifest is not the same as
    // holding it: it is a runtime permission that, on Android 11+, the user can
    // only grant from the system Settings page ("Allow all the time"). Without
    // it, Android 14+ refuses to promote the service to the foreground from a
    // background state and throws SecurityException inside the service — which
    // is the production crash. The native side now defends itself, but asking
    // for something we know will be refused just burns a process start and
    // leaves the rider thinking they are live.
    if (!await GoLivePermissionService.isBackgroundLocationGranted()) {
      _nativeKillModeUnavailableReason =
          'Background location ("Allow all the time") is not granted';
      return;
    }

    try {
      await _nativeLocationChannel.invokeMethod('start', {
        'token': token,
        'userId': userId,
        'baseUrl': base,
      });
      _nativeKillModeUnavailableReason = null;
    } on PlatformException catch (e) {
      // FGS_NOT_ELIGIBLE / FGS_START_REFUSED — the native pre-check or the
      // platform refused. Recorded rather than swallowed so the rider can be
      // told, instead of silently losing killed-state coverage.
      _nativeKillModeUnavailableReason = e.message ?? e.code;
    } catch (_) {
      // Native side unavailable — the Dart timer still covers fg/bg.
      _nativeKillModeUnavailableReason = 'native location service unavailable';
    }
  }

  /// Why killed-state location coverage is not running, or null when it is.
  ///
  /// The Dart timer still covers foreground and (briefly) background, so this
  /// is a degradation rather than a failure — but it is one the rider needs to
  /// know about, because the map service closes them five minutes after the
  /// process is killed.
  String? get nativeKillModeUnavailableReason =>
      _nativeKillModeUnavailableReason;
  String? _nativeKillModeUnavailableReason;

  /// Whether a previous start was refused by the platform, and why.
  ///
  /// Call on resume: a non-null `lastBlockedReason` means the service was
  /// refused while the app was away, so the rider has been invisible to
  /// customers since then without any signal in the UI.
  Future<Map<String, dynamic>?> nativeLocationEligibility() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _nativeLocationChannel.invokeMethod('eligibility');
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Repairs or reports killed-state location coverage. No-op unless this
  /// rider is live on Android.
  ///
  /// ## Why this has to exist
  ///
  /// `RiderLocationForegroundService` is not allowed to crash when Android
  /// refuses to promote it (that WAS the crash — a `SecurityException` out of
  /// `onStartCommand`), so every refusal is now a silent no-op that leaves a
  /// breadcrumb in SharedPreferences. Silent is the right behaviour for the
  /// process and the wrong behaviour for the rider: the pill still says LIVE,
  /// the Dart timer keeps publishing while the app is open, and the moment the
  /// app is killed the map-service closes them after five minutes of silence.
  /// They find out by not getting orders.
  ///
  /// ## Repair before complaint
  ///
  /// `lastBlockedReason` says coverage WAS lost; it does not say it still is.
  /// A rider who granted "Allow all the time" from Settings has fixed the
  /// cause, but nothing has restarted the service — the breadcrumb is stale and
  /// warning them about a permission they just granted is worse than useless.
  /// So the live flags decide:
  ///
  ///  * `canRunInBackground == false` → still broken, and only the rider can
  ///    fix it. Tell them, once per live session.
  ///  * a breadcrumb but `canRunInBackground == true` → allowed again, just not
  ///    running. Restart it silently; a successful promotion clears the
  ///    breadcrumb natively.
  ///
  /// [promptToFix] additionally escalates to the permission request (and, when
  /// permanently denied, app settings). Pass it from a path the rider just
  /// tapped — being sent to Settings is expected there and startling on a
  /// resume they didn't ask for.
  ///
  /// [allowRestart] exists only for the call immediately after [start], where a
  /// second start would race the one still in flight.
  Future<void> verifyKillModeCoverage({
    bool promptToFix = false,
    bool allowRestart = true,
  }) async {
    if (!Platform.isAndroid) return;
    // Not live — there is nothing to cover, and nothing to complain about.
    if (!_isRunning) return;

    final status = await nativeLocationEligibility();
    // Channel unavailable (older build, non-standard engine): leave whatever
    // the start path already recorded and say nothing.
    if (status == null) return;

    final lastBlockedReason =
        (status['lastBlockedReason'] as String?)?.trim() ?? '';

    switch (killModeActionFor(
      canRunInBackground: status['canRunInBackground'] == true,
      hasBreadcrumb: lastBlockedReason.isNotEmpty,
      allowRestart: allowRestart,
    )) {
      case KillModeAction.warn:
        // Prefer the native reason for the RECORD — it distinguishes "rider
        // downgraded to While using the app" from "FOREGROUND_SERVICE_LOCATION
        // not held", which is a build problem. It is never what the rider is
        // shown; that text is for logs and bug reports.
        _nativeKillModeUnavailableReason = lastBlockedReason.isNotEmpty
            ? lastBlockedReason
            : 'Background location ("Allow all the time") is not granted';
        await _warnKillModeOnce(promptToFix: promptToFix);
      case KillModeAction.restart:
        // `_startNativeKillModePinger` sets/clears the reason itself.
        await _startNativeKillModePinger();
      case KillModeAction.clear:
        // Covered. Allow a later regression to warn again.
        _nativeKillModeUnavailableReason = null;
        _warnedKillModeDegraded = false;
    }
  }

  /// The decision behind [verifyKillModeCoverage], split out because getting it
  /// backwards is silent in both directions: warn when the rider has already
  /// fixed the permission and the notice is noise they can do nothing about;
  /// stay quiet when they haven't and they lose a shift's orders.
  ///
  /// [hasBreadcrumb] is the native `lastBlockedReason` — evidence that a
  /// promotion WAS refused, which says nothing about whether it still would be.
  @visibleForTesting
  static KillModeAction killModeActionFor({
    required bool canRunInBackground,
    required bool hasBreadcrumb,
    required bool allowRestart,
  }) {
    // Still refused, and only the rider can lift it.
    if (!canRunInBackground) return KillModeAction.warn;
    // Allowed again, but a past refusal means nothing is running right now.
    if (hasBreadcrumb && allowRestart) return KillModeAction.restart;
    // Either never broken, or broken-but-already-being-restarted by the caller.
    return KillModeAction.clear;
  }

  Future<void> _warnKillModeOnce({required bool promptToFix}) async {
    if (_warnedKillModeDegraded) return;
    _warnedKillModeDegraded = true;
    commonSnackBar(
      message: 'You\'ll stop receiving orders when the app is closed. '
          'Set location to "Allow all the time" to stay live.',
    );
    if (!promptToFix) return;
    // [_ensureLocationUsable] runs on the same go-live and escalates the same
    // way when foreground location is missing. Both firing would stack two
    // permission flows on one tap, so whichever got there first owns it — and
    // the foreground grant is the prerequisite anyway, so its prompt subsumes
    // this one.
    if (_warnedUnavailable) return;
    // Same escalation the foreground path uses: request, then app settings if
    // it has been permanently denied. Only from a rider-initiated path.
    final granted = await GoLivePermissionService.requestBackgroundLocation();
    if (granted) {
      // They fixed it there and then — start the service they were just told
      // about rather than making them toggle off and on again.
      await _startNativeKillModePinger();
      _nativeKillModeUnavailableReason = null;
      _warnedKillModeDegraded = false;
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
