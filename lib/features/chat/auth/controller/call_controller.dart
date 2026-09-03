import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/ads/interstitial_ad_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/app_notification.dart';
import '../../../../core/services/notifications/default_ringtone.dart';
import '../model/call_models.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import '../../view/call_screen/call_busy_screen.dart';
import '../repo/call_repo.dart';
import '../repo/make_order_repo.dart';
import '../service/call_audio_route_service.dart';
import '../service/call_window_service.dart';
import '../service/overlay_service.dart';
import '../service/socket_keep_alive_service.dart';
import '../socket/chat_socket.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/getx_utils.dart';
import 'chat_view_controller.dart';
import '../../../common/Discover/controller/discover_controller.dart';

enum CallType { audio, video }

enum CallStatus {
  idle,
  ringing,
  accepting,
  outgoing,
  connecting,
  connected,
  ended
}

/// Audio output destinations a call can be routed to, WhatsApp-style.
/// `bluetooth` and `wiredHeadset` only appear in [CallController.availableAudioRoutes]
/// while such a device is physically connected; the list updates live during a call.
enum AudioRoute { earpiece, speaker, bluetooth, wiredHeadset }

extension AudioRouteUi on AudioRoute {
  /// Label shown in the audio-output picker.
  String get label {
    switch (this) {
      case AudioRoute.earpiece:
        return 'Earpiece';
      case AudioRoute.speaker:
        return 'Speaker';
      case AudioRoute.bluetooth:
        return 'Bluetooth';
      case AudioRoute.wiredHeadset:
        return 'Headset';
    }
  }

  /// The name flutter_webrtc's AudioSwitch uses for this sink. Single source of
  /// truth for both `Helper.selectAudioOutput` and the native read-back.
  String get typeName {
    switch (this) {
      case AudioRoute.earpiece:
        return 'earpiece';
      case AudioRoute.speaker:
        return 'speaker';
      case AudioRoute.bluetooth:
        return 'bluetooth';
      case AudioRoute.wiredHeadset:
        return 'wired-headset';
    }
  }

  /// Inverse of [typeName]. Null for an unrecognised name.
  static AudioRoute? fromTypeName(String? name) {
    switch (name) {
      case 'earpiece':
        return AudioRoute.earpiece;
      case 'speaker':
        return AudioRoute.speaker;
      case 'bluetooth':
        return AudioRoute.bluetooth;
      case 'wired-headset':
        return AudioRoute.wiredHeadset;
      default:
        return null;
    }
  }
}

class CallController extends GetxController with WidgetsBindingObserver {
  final CallRepo _callRepo = CallRepo();
  late ChatSocketService _socket;

  // --- Observable state ---
  var callType = CallType.audio.obs;
  RxBool isIncomingCall=false.obs;
  var callStatus = CallStatus.idle.obs;

  /// Server-pushed outgoing-call state from `call:ringing`.
  /// Used to drive the outgoing-call screen label
  /// (Dialing… / Ringing… / Connecting… / Connected / terminal).
  /// See `lib/docs/call-ringing-event-flutter-integration-guide.md`.
  var ringingState = CallRingingState.dialing.obs;

  /// Per-participant ringing state for group calls (user_id → state).
  /// Replaced wholesale on every `call:ringing` snapshot.
  final ringingParticipantStates = <String, CallRingingState>{}.obs;

  var callerName = ''.obs;
  var callerImage = ''.obs;
  var remoteUserName = ''.obs;
  var remoteUserImage = ''.obs;
  var callId = ''.obs;
  var roomId = ''.obs;
  var conversationId = ''.obs;
  var isCaller = false.obs;
  var isGroupCall = false.obs;

  // --- Fare-call ride state ---
  var isFareCall = false.obs;
  var fareCallOrderId = ''.obs;
  var fareCallOrderMongoId = ''.obs;
  var fareCallRideDetails = Rxn<Map<String, dynamic>>();

  // Media toggles
  var isMicOn = true.obs;
  // True once this engine actually owns a local mic capture. The call UI reads
  // it to disable Mute rather than render a live-looking button that does
  // nothing — which is what the main engine showed while CallActivity owned
  // the call, and before getUserMedia had returned.
  var hasLocalAudio = false.obs;
  var isCameraOn = true.obs;
  var isSpeakerOn = false.obs;
  // Whether call audio is currently routed to a connected Bluetooth headset.
  // Mutually exclusive with isSpeakerOn — turning one on clears the other.
  var isBluetoothOn = false.obs;
  var isFrontCamera = true.obs;

  // ── Audio routing (WhatsApp-style) ──────────────────────────────────────
  // The currently active output sink. Source of truth; isSpeakerOn/isBluetoothOn
  // are kept in sync with it for backward compatibility with existing UI.
  final currentAudioRoute = AudioRoute.earpiece.obs;
  // Output routes the user can pick right now. Earpiece + Speaker are always
  // present on a phone; Bluetooth / wired Headset are added/removed live as the
  // device connects or disconnects (driven by `ondevicechange`).
  final availableAudioRoutes =
      <AudioRoute>[AudioRoute.earpiece, AudioRoute.speaker].obs;

  bool get isBluetoothAvailable =>
      availableAudioRoutes.contains(AudioRoute.bluetooth);
  bool get isWiredHeadsetAvailable =>
      availableAudioRoutes.contains(AudioRoute.wiredHeadset);

  // True once the user has explicitly tapped Speaker, so auto-routing (e.g. a
  // Bluetooth device connecting mid-call) does not override their choice.
  bool _userPickedSpeaker = false;
  // The route the user (or auto-routing) last asked for, as opposed to
  // [currentAudioRoute], which tracks what the platform reports as active.
  // Kept so _reassertAudioRoute() can re-drive the intent after another Flutter
  // engine replaces flutter_webrtc's shared audio manager mid-call.
  AudioRoute? _desiredAudioRoute;
  // Guards the `ondevicechange` subscription so we attach/detach exactly once
  // per call and never leak it across calls.
  bool _audioMonitoringActive = false;

  // ── In-call volume (hardware volume buttons) ────────────────────────────
  // The hardware volume rocker is intercepted natively (see CallActivity /
  // MainActivity dispatchKeyEvent) and routed here. We apply the change as a
  // WebRTC software gain on the remote audio tracks, which works on every
  // output — earpiece, speaker, Bluetooth (SCO), wired and CarPlay — unlike the
  // OS stream volume, which a Bluetooth/CarPlay device can lock via absolute
  // volume. 0.0 = muted, 1.0 = max. Exposed reactively so the call UI can flash
  // a volume indicator.
  static const MethodChannel _volumeChannel =
      MethodChannel('com.bluehr.call/volume');
  static const double _volumeStep = 0.1;
  final callVolumeLevel = 0.7.obs;
  bool _volumeInterceptActive = false;

  // Mirrors the native call-window state so repeated callStatus transitions
  // don't spam the platform channel. See [_setCallWindowActive].
  bool _callWindowActive = false;
  Worker? _callWindowWorker;
  // Retries opening the call room until the navigator exists and splash has
  // finished. See [_openCallRoom].
  Timer? _callRoomOpenTimer;

  // Remote user media state (1-to-1)
  var remoteAudioEnabled = true.obs;
  var remoteVideoEnabled = true.obs;

  // Per-participant media state for group calls { peerId: { audio: bool, video: bool, name: String, image: String } }
  final participantMediaState = <String, Map<String, dynamic>>{}.obs;

  // Call type switch state
  var isSwitchTypePending = false.obs;
  var switchTypeRequestedBy = ''.obs;

  // Call timer
  var callDurationSeconds = 0.obs;
  Timer? _callTimer;
  Timer? _ringTimer;

  // Ringtone player — lives in the controller so it is always reachable
  // regardless of whether the call screen widget is mounted or disposed.
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  // Caller-side ringback player — plays a "phone ringing" tone to the caller
  // while we wait for the receiver to pick up. Kept as a separate instance
  // from `_ringtonePlayer` so caller and receiver tones can never tangle.
  final AudioPlayer _outgoingRingbackPlayer = AudioPlayer();

  /// Start the incoming-call ringtone (loops until stopped).
  // Route the in-app ringtone to the RINGTONE stream. audioplayers defaults
  // to the MEDIA stream, so with media volume at zero the incoming-call ring
  // was silent even though the phone's ringer volume was up.
  bool _ringtoneContextSet = false;

  Future<void> _ensureRingtoneAudioContext() async {
    if (_ringtoneContextSet) return;
    _ringtoneContextSet = true;
    try {
      await _ringtonePlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransient,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (e) {
      // Non-fatal — worst case the ring plays on the media stream as before.
      print('[CALL_DEBUG] ringtone AudioContext setup failed: $e');
    }
  }

  /// True while an incoming ringtone is playing.
  ///
  /// Lets a screen assert "this should be ringing" without having to know
  /// whether some earlier path already started it — see [startRingtone].
  bool get isRingtonePlaying => _ringtonePlaying;
  bool _ringtonePlaying = false;

  /// Bumped by every [stopRingtone]. [startRingtone] captures it and re-checks
  /// after each await: without this, a stop landing while the native-ringer
  /// call is still in flight is followed by the fallback player STARTING, and
  /// nothing is left to stop it — the phone then rings until it is killed.
  int _ringGeneration = 0;

  /// Hard stop for any ring, however it was started and whatever went wrong
  /// with the path that should have stopped it. Longer than every offer window
  /// (ride requests expire in ~45s) so it only ever fires on a leak.
  static const Duration _kMaxRingDuration = Duration(seconds: 75);
  Timer? _ringWatchdog;

  void startRingtone() async {
    // Idempotent on purpose. A broadcast ride request has no VoIP call behind
    // it, so `_handleIncomingCall` never runs and nothing starts the ring —
    // IncomingRiderOrderScreen therefore starts it itself. For a fare-call the
    // call path already did, and restarting would clip the tone back to zero
    // every time the screen rebuilt.
    if (_ringtonePlaying) return;
    _ringtonePlaying = true;
    final generation = _ringGeneration;

    // Nothing may ring forever. Every explicit stop cancels this; if none of
    // them run (screen never disposed, timer starved in the background, push
    // missed) this is what ends it.
    _ringWatchdog?.cancel();
    _ringWatchdog = Timer(_kMaxRingDuration, () {
      print('[CALL_DEBUG] ring watchdog fired — force-stopping ringtone');
      stopRingtone();
    });

    // Native ringer first (Android): plays on the RING stream so it follows
    // the phone's ringer volume and silent/vibrate modes, loops, and VIBRATES
    // — none of which the audioplayers path did (it rode the MEDIA stream:
    // silent whenever media volume was down, and never vibrated).
    try {
      await DefaultRingtone.play();
      // A stop that arrived mid-flight was applied before this play landed.
      if (generation != _ringGeneration) DefaultRingtone.stop().catchError((_) {});
      return;
    } catch (e) {
      // iOS / engines without the channel — fall back to the in-app player.
      print('[CALL_DEBUG] native ringtone unavailable, falling back: $e');
    }
    await _ensureRingtoneAudioContext();
    if (generation != _ringGeneration) return; // stopped while we were setting up
    _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    await _ringtonePlayer.play(AssetSource('sound/hangouts_call.mp3'));
    if (generation != _ringGeneration) _ringtonePlayer.stop();
  }

  /// Start the outgoing-call ringback for the caller (loops until stopped).
  /// Plays from the moment the call is dialed until the receiver accepts,
  /// declines, the caller cancels, or the ring window times out.
  void startOutgoingRingback() {
    try {
      _outgoingRingbackPlayer.setReleaseMode(ReleaseMode.loop);
      _outgoingRingbackPlayer.setVolume(0.3);
      _outgoingRingbackPlayer.play(AssetSource('sound/old_phone_ring.mp3'));
    } catch (e) {
      // if (kDebugMode) print('startOutgoingRingback error: $e');
    }
  }

  /// Stop only the caller-side ringback. Used when the receiver picks up and
  /// the call transitions outgoing → connecting (which does NOT flow through
  /// the cleanup chain, so `stopRingtone` is not invoked otherwise).
  void stopOutgoingRingback() {
    try {
      _outgoingRingbackPlayer.stop();
    } catch (_) {}
  }

  /// Stop all incoming-call ringtones immediately — covers both:
  /// - In-app AudioPlayer ringtone (regular voice/video calls)
  /// - Native system ringtone via DefaultRingtone (rider/fare-call)
  /// Also silences the caller-side outgoing ringback so every existing
  /// teardown path (decline / cancel / end / answered-elsewhere / cleanup)
  /// stops the caller's tone without needing per-site changes.
  void stopRingtone() {
    _ringtonePlaying = false;
    // Invalidates any startRingtone still working through its awaits.
    _ringGeneration++;
    _ringWatchdog?.cancel();
    _ringWatchdog = null;
    _ringtonePlayer.stop();
    stopOutgoingRingback();
    // DefaultRingtone.stop() is async — a sync try/catch misses the
    // MissingPluginException that fires when this engine (e.g. CallActivity
    // before a full Kotlin rebuild) hasn't registered the channel. Without
    // .catchError the rejection escapes to runZonedGuarded and prints as
    // "CALL ENGINE CRASH".
    DefaultRingtone.stop().catchError((_) {});
    // The ride request may also be ringing from its own INSISTENT notification
    // (posted by the background isolate). That sound loops until the
    // notification is cancelled — stopping only the in-app player left the
    // phone ringing on every ROM that ignores `timeoutAfter`.
    cancelRideRingNotification(fareCallOrderId.value).catchError((_) {});
  }

  // WebRTC
  MediaStream? localStream;
  final peerConnections = <String, RTCPeerConnection>{};
  final remoteStreams = <String, MediaStream>{}.obs;
  final remoteRenderers = <String, RTCVideoRenderer>{};
  RTCVideoRenderer? localRenderer;

  IceServerConfig? _iceConfig;
  String? _remoteUserId;

  /// Public read access to the current remote user id (the other party of the
  /// active/last call). Used by downstream screens (e.g. rider pickup nav) to
  /// initiate a fresh audio call back to the customer after a fare-call.
  String? get remoteUserId => _remoteUserId;

  /// True when the app's main activity is in the foreground (resumed).
  /// Updated by AppLifecycleHandler. We use this in `_handleIncomingCall`
  /// (socket main isolate) to decide whether navigation alone is enough
  /// (foreground) or whether we also need to fire CallKit's full-screen
  /// IncomingCallActivity so the UI is actually visible (background).
  static bool isAppInForeground = true;

  /// Public setter so FCM-push fallback paths (foreground Android) can
  /// populate the remote user id before the user accepts. Without this,
  /// acceptCall's WebRTC branch bails out with "no remoteUserId" and the
  /// 30s connection timeout ends the call.
  void setRemoteUserIdFromPush(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      _remoteUserId = userId;
    }
  }

  // ICE candidate buffer for candidates arriving before remote description
  final _pendingCandidates = <String, List<RTCIceCandidate>>{};

  // Pending SDP offer received while still ringing (before user accepts)
  Map<String, dynamic>? _pendingOffer;

  // Completer to signal when local media is ready (for offer race condition)
  Completer<void>? _mediaReadyCompleter;

  // Ongoing call notification
  static const int _ongoingNotificationId = 99001;
  static const String _ongoingChannelId = 'ongoing_call';
  Timer? _notificationTimer;

  /// The route the app is currently showing, as an observable.
  ///
  /// Fed by [onRouteChanged], which is wired into
  /// `GetMaterialApp.routingCallback` in main.dart. This is what tells the top
  /// call strip (OngoingCallStrip) whether a call screen is on top.
  ///
  /// This used to be a mounted-screens COUNTER, incremented in the call
  /// screen's initState and decremented in its dispose. A counter drifts: any
  /// call-screen route replaced or removed without its dispose reaching the
  /// hook leaves it stuck above zero, and since it is process-wide static
  /// state the strip then stays hidden for EVERY later call in that app
  /// session — which is exactly the "picked up the call, went back, no timer
  /// bar" report (and why the same build still showed the bar after a cold
  /// start, where the static reset to zero). A route name cannot drift: the
  /// navigator republishes it on every push, pop and replace.
  static final currentRouteRx = ''.obs;

  /// Every route name that renders a call screen. While one of these is on
  /// top there is nothing for the strip to take the user back to.
  static const Set<String> callRouteNames = {
    '/CallRoomScreen',
    '/IncomingCallScreen',
    '/OutgoingCallScreen',
    '/ActiveCallScreen',
    '/IncomingRiderOrderScreen',
  };

  static bool isCallRoute(String route) => callRouteNames.contains(route);

  /// Wired to `GetMaterialApp.routingCallback` — the one place the app learns
  /// that the visible route changed.
  ///
  /// The write is deferred to after the frame, and that is NOT optional. The
  /// navigator notifies its observers from inside
  /// `NavigatorState._flushHistoryUpdates`, which runs during the build pass
  /// that is pushing or popping the route. Writing an observable there marks
  /// the top strip's `Obx` dirty mid-build — and that is not merely the
  /// "setState() called during build" assert: the rebuild re-parents the app's
  /// Navigator, whose GlobalKey is then claimed by two widgets at once, and the
  /// entire app comes up as a red error screen.
  static void onRouteChanged(Routing? routing) {
    final route = routing?.current ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentRouteRx.value = route;
      if (isCallRoute(route)) callRoomEverShown.value = true;
    });
  }

  /// True once the call screen has been shown at least once for the CURRENT
  /// call. The strip is for RETURNING to a call you have already seen, so
  /// without this it flashes up in every gap before the call screen mounts:
  /// while an outgoing call is still doing its API/ICE setup, between
  /// `accepting` and the accept round-trip finishing, and over the splash
  /// screen during a killed-state accept. Reset in [_resetState].
  ///
  /// Also set the moment the call CONNECTS ([_startCallTimer]), whether or not
  /// a call screen ever mounted — an answered call with no way back to it is
  /// worse than a strip that appears a beat early.
  ///
  /// Set from [onRouteChanged] and [_startCallTimer] only. The call screen used
  /// to set it from its own `initState`, which is inside the build pass and so
  /// hit the same mid-build write described on [onRouteChanged].
  static final callRoomEverShown = false.obs;

  /// Whether the CURRENT call ever reached the connected state (i.e. was
  /// actually picked up). The end-of-call interstitial only fires for answered
  /// calls — never for missed / rejected / unanswered ones. Set on connect
  /// ([_startCallTimer]), consumed when the ad is triggered
  /// ([_showCallEndedInterstitial]), and reset when a new call starts.
  bool _wasCallConnected = false;

  /// True when a killed-state accept has already been triggered from main.dart.
  /// Prevents the CallKit listener from firing acceptCall a second time.
  static bool _killedStateAcceptHandled = false;

  /// True while we are programmatically dismissing the CallKit UI after accepting.
  /// Prevents the resulting actionCallEnded event from killing the active call.
  bool _isDismissingCallKitUI = false;

  static void setKilledStateAcceptHandled() {
    _killedStateAcceptHandled = true;
  }

  /// Retained as a no-op so the three killed-state accept paths in main.dart
  /// read the same as before.
  ///
  /// A cold-start accept used to force the call screen to become the app's
  /// `home`. That made the call the only reachable screen for its whole
  /// duration, gave Back nothing to pop to, and left a dead blank page behind
  /// when the call ended. The app now always boots normally and the call room
  /// is pushed on top like any other screen, so there is nothing to record.
  static void markColdStartCall() {}

  /// Open the call room on top of whatever the app is showing.
  ///
  /// On a cold start the navigator may not exist yet (accept runs during app
  /// init), and splash performs its own `pushNamedAndRemoveUntil` shortly
  /// after — so a push issued too early is either dropped or wiped. Retry on a
  /// short cadence until the route sticks, then stop.
  /// True when a failed call API response means "that call is over", as
  /// opposed to a transient failure worth surfacing as an error.
  ///
  /// The call service splits this across two status codes: **404** is "call not
  /// found", **400** is "call found but no longer active" — the far more likely
  /// answer when the caller hangs up during the 2–5s an accept from a killed
  /// state spends launching the app. Keying on 404 alone showed the user a raw
  /// "Call is no longer active" error toast for what is simply a call that
  /// ended a moment ago.
  ///
  /// The message match is deliberately loose: it only decides which of two
  /// user-facing strings to show, and both paths clean up identically.
  bool _isCallGoneResponse(ResponseModel response) {
    final statusCode = response.response?.statusCode;
    if (statusCode == 404) return true;
    if (statusCode != 400) return false;
    final message = (response.message ?? '').toString().toLowerCase();
    return message.contains('no longer') ||
        message.contains('not active') ||
        message.contains('already ended');
  }

  /// A call is in flight — ringing, being set up, or connected.
  bool get isCallLive =>
      callStatus.value != CallStatus.idle &&
      callStatus.value != CallStatus.ended;

  /// Re-open the call room for a call that is still live. Used by the splash
  /// screen after a killed-state accept: splash installs the home shell with
  /// `pushNamedAndRemoveUntil`, which wipes anything already pushed on top, so
  /// the call room has to be put back once the app has landed.
  void reopenCallRoomIfActive() {
    final status = callStatus.value;
    if (status == CallStatus.idle || status == CallStatus.ended) return;
    _openCallRoom();
  }

  void _openCallRoom() {
    if (isFareCall.value) return;
    _callRoomOpenTimer?.cancel();
    var attempts = 0;

    bool tryOpen() {
      // Call already gone — nothing to open.
      final status = callStatus.value;
      if (status == CallStatus.idle || status == CallStatus.ended) return true;
      if (Get.currentRoute == '/CallRoomScreen') return true;
      if (Get.key.currentState == null) return false;
      // Still booting: pushing now would be wiped by splash's own
      // pushNamedAndRemoveUntil. Wait for the app to land.
      //
      // '/' is part of that test because splash is GetMaterialApp's `home`,
      // and a `home` widget's route is named '/' — never anything containing
      // "Splash". Testing only for the word is why a killed-state accept used
      // to push the call room straight on top of the splash screen, leaving
      // the user on a dead splash page when they backed out of the call.
      final route = Get.currentRoute;
      if (route.isEmpty || route == '/' || route.contains('Splash')) {
        return false;
      }
      if (route == '/IncomingCallScreen') {
        Get.offNamed('/CallRoomScreen');
      } else {
        Get.toNamed('/CallRoomScreen');
      }
      return true;
    }

    if (tryOpen()) return;
    _callRoomOpenTimer =
        Timer.periodic(const Duration(milliseconds: 250), (timer) {
      attempts++;
      // ~30s ceiling — a cold boot waits on the notification-launch check and
      // deep-link resolution before splash lands, which can outlast the old
      // 10s. If the app never lands, the top strip is still there as the way
      // back into the call — better than retrying forever.
      if (tryOpen() || attempts > 120) timer.cancel();
    });
  }

  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _socket = ChatSocketService();
    _setupCallSocketListeners();
    // Re-bind call listeners on every socket (re)connect. disposeSocket()
    // (chat screen teardown) wipes the socket service's stored listeners, and
    // until now they were only restored on app RESUME — any incoming call in
    // between was silently ignored (no ring). The hook fires inside
    // onConnect, after the stored-listener replay.
    _socket.onCallListenersRebind = ensureCallSocketListeners;
    _setupCallKitListeners();
    _setupVolumeKeyChannel();
    WidgetsBinding.instance.addObserver(this);
    // Drive the call window behaviour (show-over-lock-screen, turn-screen-on,
    // keep-screen-on, Home-shrinks-to-PiP) straight off the call state.
    //
    // It used to be switched on in _setupLocalMedia, which only runs once a
    // call is ACCEPTED — far too late for the thing that matters most: an
    // incoming call has to be visible on a locked screen while it is still
    // ringing. Hanging it off callStatus covers every entry path at once —
    // incoming, outgoing, fare-call, rider order and cold-start accept — with
    // no per-path wiring to keep in sync.
    _callWindowWorker = ever(callStatus, (CallStatus status) {
      final live = status != CallStatus.idle && status != CallStatus.ended;
      _setCallWindowActive(live);
      // Connectivity is watched for the WHOLE life of a call, from the first
      // ring. Starting it at _setupLocalMedia (i.e. on accept) would miss the
      // case this was reported for: losing signal while the phone is still
      // ringing, where there is no peer connection yet to notice anything.
      if (live) {
        _startConnectivityWatch();
      } else {
        _cancelNetworkGrace();
        _stopConnectivityWatch();
      }
    });
    // Clear any stale ongoing-call record left behind by a previous session
    // that was force-killed mid-call — on a cold start no call can still be
    // live, so a lingering record would show a phantom "Live call ongoing"
    // banner.
    clearActiveCallSession();
    // Ensure socket is connected so incoming `call:incoming` events are
    // delivered even when the user hasn't opened chat yet. Without this,
    // the server falls back to FCM and CallKit's ring timer can elapse,
    // flipping the call to "missed" before the user sees it.
    //
    // Gate on isLoggedIn(): CallController is registered as permanent in
    // main.dart before we know if the user is authenticated, so cold
    // starts on the auth/onboarding screens would otherwise open a socket
    // with an empty token and spam `isOnLine` events. After login,
    // AuthController triggers connectToSocket() explicitly; the call
    // listeners registered above are buffered in ChatSocketService's
    // `_pendingListeners` and replayed on that first authenticated connect.
    if (isLoggedIn() && !_socket.isConnected) {
      _socket.connectToSocket();
    }
  }

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _callWindowWorker?.dispose();
    _cleanup();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    // The 1s timer may have been throttled or suspended while we were away, so
    // the visible duration can be stale by however long that lasted. Re-derive
    // it from the connect anchor before the user sees the call bar, rather than
    // letting them watch it jump on the next tick.
    _syncCallDuration();
    // Coming back to the foreground is the most likely moment for the audio
    // route to have been silently lost: whatever ran while we were away (an
    // FCM data message, the floating overlay) may have replaced
    // flutter_webrtc's shared AudioSwitchManager. Re-drive the user's choice.
    _reassertAudioRoute();
  }

  // ==================== SOCKET EVENT LISTENERS ====================

  /// Re-register call socket listeners on the current socket.
  /// Called from AppLifecycleHandler after a socket reconnect to ensure
  /// incoming call events are not lost (disposeSocket clears all listeners).
  void ensureCallSocketListeners() {
    if (_disposed) return;
    _setupCallSocketListeners();
  }

  void _setupCallSocketListeners() {
    // Incoming call
    _socket.listenEvent('call:incoming', (data) {
      logs('[CALL_DEBUG] SOCKET EVENT → call:incoming ${data}');
      if (_disposed) return;
      _handleIncomingCall(data);
    });

    // Call accepted by receiver
    _socket.listenEvent('call:accepted', (data) {
      // print('[CALL_DEBUG] SOCKET EVENT → call:accepted, data=$data');
      if (_disposed) return;
      _handleCallAccepted(data);
    });

    // Call declined by receiver
    _socket.listenEvent('call:declined', (data) {
      // print('[CALL_DEBUG] SOCKET EVENT → call:declined');
      if (_disposed) return;
      _handleCallDeclined(data);
    });

    // Call cancelled by caller
    _socket.listenEvent('call:cancelled', (data) {
      // print('[CALL_DEBUG] SOCKET EVENT → call:cancelled');
      if (_disposed) return;
      _handleCallCancelled(data);
    });

    // Call ended
    _socket.listenEvent('call:ended', (data) {
      // print('[CALL_DEBUG] SOCKET EVENT → call:ended');
      if (_disposed) return;
      _handleCallEnded(data);
    });

    // Outgoing-call state stream (caller-only). Drives the Dialing…/Ringing…/
    // Connecting…/Connected label. The server only emits this to the initiator,
    // so receivers will never see it. Additive — does not replace the existing
    // call:incoming/accepted/declined/cancelled/ended events.
    _socket.listenEvent('call:ringing', (data) {
      if (_disposed) return;
      _handleCallRinging(data);
    });

    // Answered elsewhere
    _socket.listenEvent('call:answered-elsewhere', (data) {
      // print('[CALL_DEBUG] SOCKET EVENT → call:answered-elsewhere');
      if (_disposed) return;
      _handleAnsweredElsewhere(data);
    });

    // WebRTC signaling
    _socket.listenEvent('call:offer', (data) {
      if (_disposed) return;
      _handleRemoteOffer(data);
    });

    _socket.listenEvent('call:answer', (data) {
      if (_disposed) return;
      _handleRemoteAnswer(data);
    });

    _socket.listenEvent('call:ice-candidate', (data) {
      if (_disposed) return;
      _handleRemoteIceCandidate(data);
    });

    // Media toggle from remote (may send only the changed field)
    _socket.listenEvent('call:media-toggle', (data) {
      if (_disposed) return;
      final peerId = data['user_id'] ?? '';
      if (data['is_audio_enabled'] != null) {
        remoteAudioEnabled.value = data['is_audio_enabled'];
      }
      if (data['is_video_enabled'] != null) {
        remoteVideoEnabled.value = data['is_video_enabled'];
      }
      // Update per-participant state for group calls
      if (peerId.isNotEmpty) {
        final current = participantMediaState[peerId] ?? {};
        if (data['is_audio_enabled'] != null) {
          current['audio'] = data['is_audio_enabled'];
        }
        if (data['is_video_enabled'] != null) {
          current['video'] = data['is_video_enabled'];
        }
        participantMediaState[peerId] = current;
        participantMediaState.refresh();
      }
    });

    // Group call events
    _socket.listenEvent('call:participant-joined', (data) {
      if (_disposed) return;
      _handleParticipantJoined(data);
    });

    _socket.listenEvent('call:participant-left', (data) {
      if (_disposed) return;
      _handleParticipantLeft(data);
    });

    // User(s) added to call by another participant
    _socket.listenEvent('call:user-added', (data) {
      if (_disposed) return;
      _handleUserAdded(data);
    });

    // Call type switch events
    _socket.listenEvent('call:switch-type-request', (data) {
      if (_disposed) return;
      _handleSwitchTypeRequest(data);
    });

    _socket.listenEvent('call:type-switched', (data) {
      if (_disposed) return;
      _handleTypeSwitched(data);
    });

    _socket.listenEvent('call:switch-type-declined', (data) {
      if (_disposed) return;
      _handleSwitchTypeDeclined(data);
    });
  }

  // ==================== CALL INITIATION ====================

  /// Initiate a 1-to-1 call
  Future<bool> initiateCall({
    required CallType type,
    String? otherUserId,
    String? existingConversationId,
    required String userName,
    required String userImage,
  }) async {
    // Fresh call — clear the "was picked up" marker.
    _wasCallConnected = false;
    // Request permissions (wrapped in try-catch to avoid PlatformException
    // when another permission request is already in progress)
    try {
      final permissions = [Permission.microphone];
      if (type == CallType.video) permissions.add(Permission.camera);
      final statuses = await permissions.request();
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        commonSnackBar(message: AppStrings.cameraMicrophonePermissionRequired.tr);
        return false;
      }
    } catch (e) {
      // if (kDebugMode)
        // print('Permission request error (may already be in progress): $e');
    }

    final params = <String, dynamic>{
      'call_type': type == CallType.video ? 'video_call' : 'audio_call',
    };
    if (existingConversationId != null) {
      params['conversation_id'] = existingConversationId;
    }
    if (otherUserId != null) {
      params['other_user_id'] = otherUserId;
    }

    // Ensure socket is connected BEFORE hitting the API. The server uses the
    // caller's socket presence to bridge the room — if the socket is still
    // connecting when we emit `call:join-room`, the emit races the server's
    // ringing timeout and we get an immediate `call:ended` back (observed:
    // callee in foreground only gets a "missed call" toast).
    if (!_socket.isConnected) {
      // print('[CALL_DEBUG] initiateCall → socket disconnected, reconnecting before API call...');
      _socket.connectToSocket();
      await _waitForSocketConnection();
      // print('[CALL_DEBUG] initiateCall → socket wait done, isConnected=${_socket.isConnected}');
    }

    // The call screen goes up NOW, before the request — t = 0 in rev 3 §7.2.
    //
    // Navigation used to live in all eight call sites as
    // `if (success) Get.toNamed('/CallRoomScreen')`, which meant a busy callee
    // produced no screen at all: the user tapped Call, waited, and got a
    // snackbar. A placed call is owed a call screen whatever the outcome, so
    // this is pushed unconditionally and the outcome is rendered INTO it —
    // replaced by the real call screen on success, turned into the busy screen
    // on a 409, popped on anything else.
    //
    // `ringingState` is reset first so a terminal state left over from the
    // PREVIOUS call cannot be read by the new screen as this call's outcome.
    _attachRingingState();
    Get.to(() => CallBusyScreen(
          peerName: userName,
          peerImage: userImage,
          otherUserId: otherUserId,
          conversationId: existingConversationId,
          callType: type,
        ));

    // print('[CALL_DEBUG] initiateCall → API call starting, type=$type');
    ResponseModel response = await _callRepo.initiateCall(params);

    if (!response.isSuccess) {
      final statusCode = response.response?.statusCode;
      // The attempt screen is ALREADY up (pushed above). Every branch here
      // decides what it becomes, rather than whether it appears.
      if (statusCode == 409) {
        // TWO different 409s, and rev 3 §7.4 is explicit that they must not
        // look alike. `CALLER_ALREADY_IN_CALL` means WE are on a call — showing
        // "user is busy" there blames the person we just tried to ring. The
        // typed `code` is what tells them apart; the message string used to be
        // the only difference and was never read.
        final body = response.response?.data;
        final code =
            (body is Map ? (body['code'] ?? '').toString() : '').toUpperCase();

        if (code == 'CALLER_ALREADY_IN_CALL') {
          // Not a new call at all — there is a live one to go back to. Close
          // the attempt screen; an outgoing UI here would be inventing a second
          // call that does not exist.
          _closeAttemptScreen();
          markRingingFailedLocally(CallRingingState.failed);
          _promptReturnToCall(
            body is Map ? (body['room_id'] ?? '').toString() : '',
          );
        } else {
          // RECEIVER_BUSY, or an older build with no `code` at all. The screen
          // STAYS and turns into the outcome — it is watching `ringingState`
          // and honours the 700 ms dwell from the tap. No snackbar: a busy
          // callee is a call outcome, not a request failure.
          markRingingFailedLocally(CallRingingState.busy);
        }
      } else {
        // A genuine failure. Nothing to show on a call screen, so take it down
        // and say what went wrong.
        _closeAttemptScreen();
        markRingingFailedLocally(CallRingingState.failed);
        commonSnackBar(message: response.message ?? AppStrings.failedToInitiateCall.tr);
      }
      return false;
    }

    final data = response.response?.data;
    if (data == null) {
      _closeAttemptScreen();
      return false;
    }

    // Set state
    callType.value = type;
    callStatus.value = CallStatus.outgoing;
    isCaller.value = true;
    callId.value = data['call_id'] ?? '';
    roomId.value = data['room_id'] ?? '';
    conversationId.value = data['conversation_id'] ?? '';
    remoteUserName.value = userName;
    remoteUserImage.value = userImage;
    isGroupCall.value = false;
    // Reset ringing state once we have a callId — subsequent `call:ringing`
    // events with this callId will drive the outgoing-call label.
    _attachRingingState();

    // The call exists — swap the attempt screen for the real one. `offNamed`
    // rather than `toNamed`: the attempt screen has served its purpose and must
    // not sit behind the call, or ending the call lands the user back on
    // "Calling…".
    _replaceAttemptScreenWithCall();

    // Caller-side ringback: loops until the receiver accepts/declines, the
    // caller cancels, or the 30s ring timer expires. Stopped by either
    // `stopOutgoingRingback()` in `_handleCallAccepted`, or `stopRingtone()`
    // (which also silences the ringback) in every other teardown path.
    startOutgoingRingback();

    // print('[CALL_DEBUG] initiateCall → API SUCCESS, callId=${callId.value}, roomId=${roomId.value}');

    _iceConfig = IceServerConfig.fromJson(data['ice_servers'] ?? {});
    // print('[CALL_DEBUG] initiateCall → ICE servers parsed, socket.isConnected=${_socket.isConnected}');

    // Re-check socket (may have dropped during the API round-trip) — the
    // server must see `call:join-room` before its ringing window expires,
    // otherwise it emits `call:ended` back to the caller.
    if (!_socket.isConnected) {
      _socket.connectToSocket();
      await _waitForSocketConnection();
    }

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': roomId.value});
    // print('[CALL_DEBUG] initiateCall → emitted call:join-room, isConnected=${_socket.isConnected}');

    // Setup local media & peer connection (don't create offer yet)
    _mediaReadyCompleter = Completer<void>();
    await _setupLocalMedia();
    if (!_mediaReadyCompleter!.isCompleted) {
      _mediaReadyCompleter!.complete();
    }
    // print('[CALL_DEBUG] initiateCall → local media ready');
    await _createPeerConnection(otherUserId ?? '');
    // print('[CALL_DEBUG] initiateCall → peer connection created for $otherUserId');
    _remoteUserId = otherUserId;

    // Start 30-second ring timeout
    _startRingTimer();

    // Show notification to keep app in foreground
    _showConnectingNotification();

    // Keep screen on, enable PiP, and keep socket alive during call
    WakelockPlus.enable();
    SocketKeepAliveService.start();

    return true;
  }

  /// Whether the pre-request attempt screen ([CallBusyScreen]) is on top.
  ///
  /// Matched by TYPE rather than by a route name — it is pushed with `Get.to`,
  /// which gives it no name, and popping blind would take down whatever else
  /// happened to be there (a sheet the user opened, a deep link that landed
  /// mid-request).
  bool get _attemptScreenIsUp =>
      Get.currentRoute.contains('CallBusyScreen') ||
      (Get.rawRoute?.settings.name?.contains('CallBusyScreen') ?? false);

  /// Take the attempt screen down, for an outcome that has nothing to show on
  /// a call screen.
  void _closeAttemptScreen() {
    if (_attemptScreenIsUp && Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  /// Swap the attempt screen for the live call screen.
  ///
  /// Falls back to a plain push when the attempt screen is not the current
  /// route — the user may have navigated during the request, and a call that
  /// succeeded must still open.
  void _replaceAttemptScreenWithCall() {
    if (Get.currentRoute == '/CallRoomScreen') return;
    if (_attemptScreenIsUp) {
      Get.offNamed('/CallRoomScreen');
    } else {
      Get.toNamed('/CallRoomScreen');
    }
  }

  /// "You're already on a call" — with a way back to it.
  ///
  /// The 409 for [CALLER_ALREADY_IN_CALL] used to render as "User is busy on
  /// another call", which blames the person we just tried to ring for something
  /// we are doing. It is not a failed call at all: there is a live one, and the
  /// only useful action is returning to it.
  ///
  /// An inline prompt rather than a screen, per rev 3 §7.4 — opening an
  /// outgoing-call UI here would be inventing a second call that does not exist.
  void _promptReturnToCall(String roomId) {
    Get.snackbar(
      '',
      '',
      titleText: CustomText(
        AppStrings.youAreAlreadyOnACall.tr,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      backgroundColor: AppColors.mainTextColor,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          // Only restore what is genuinely still live. The room id is echoed
          // back for exactly this, but a call that ended between the 409 and
          // the tap must not open an empty room.
          if (isCallLive && Get.currentRoute != '/CallRoomScreen') {
            Get.toNamed('/CallRoomScreen');
          }
        },
        child: CustomText(
          AppStrings.returnToCall.tr,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }

  // ==================== INCOMING CALL HANDLING ====================

  void _handleIncomingCall(dynamic data) {
    // log('[FARE_CALL_DEBUG] _handleIncomingCall → raw data=$data');
    if (callStatus.value != CallStatus.idle) {
      // Already on a call. This used to `return` silently, so the SERVER never
      // learned we were busy: the caller kept ringing for the full 30s timer
      // and was then told "no answer", when the truthful answer was available
      // the instant the second call arrived. Tell the server instead — it
      // relays `state: "busy"` on `call:ringing`, which the caller's UI already
      // knows how to render (CallRingingState.busy).
      _rejectAsBusy(data);
      return;
    }
    // Fresh incoming call — clear the "was picked up" marker.
    _wasCallConnected = false;

    callId.value = data['call_id'] ?? '';
    roomId.value = data['room_id'] ?? '';
    conversationId.value = data['conversation_id'] ?? '';
    callType.value =
        data['call_type'] == 'video_call' ? CallType.video : CallType.audio;
    isGroupCall.value = data['is_group_call'] ?? false;
    isCaller.value = false;
    // Resolve caller name from any key the backend may use. NEVER fall back
    // to `initiated_by` — that's the sender's user ID and was showing up in
    // the UI (IncomingCallScreen, rider order screen, CallKit) whenever the
    // socket payload didn't carry `caller_name` verbatim.
    callerName.value = (
            (data['caller_info'] is Map ? data['caller_info']['name'] : null) ??
            (data['caller'] is Map ? data['caller']['name'] : null) ??
            (data['sender'] is Map ? data['sender']['name'] : null) ??
                data['caller_name'] ??
                data['senderName'] ??
                data['sender_name'] ??
                data['name'] ??
            '')
        .toString();
    callerImage.value = (
            (data['caller_info'] is Map ? data['caller_info']['profile_image'] : null) ??
            (data['caller'] is Map ? data['caller']['profile_image'] : null) ??
            (data['sender'] is Map ? data['sender']['profile_image'] : null) ??
                data['caller_image'] ??
                data['senderProfileImage'] ??
                data['sender_profile_image'] ??
                data['profile_image'] ??'')
        .toString();
    remoteUserName.value = callerName.value;
    remoteUserImage.value = callerImage.value;
    _remoteUserId = data['initiated_by'] ?? '';
    callStatus.value = CallStatus.ringing;

    print('[FARE_CALL_DEBUG] _handleIncomingCall → callId=${callId.value}, roomId=${roomId.value}, remoteUserId=$_remoteUserId');

    // Check if this is a fare-call (ride request via call)
    final metadata = data['metadata'];
    print('[FARE_CALL_DEBUG] _handleIncomingCall → metadata=$metadata');
    if (metadata != null && metadata['orderType'] == 'fare-call') {
      isFareCall.value = true;
      fareCallOrderId.value = metadata['orderId'] ?? '';
      fareCallOrderMongoId.value = metadata['orderMongoId'] ?? '';
      fareCallRideDetails.value = metadata['rideDetails'] != null
          ? Map<String, dynamic>.from(metadata['rideDetails'])
          : null;
      print('[FARE_CALL] Incoming fare-call detected, orderId=${fareCallOrderId.value}, rideDetails=${fareCallRideDetails.value}');
      print('[FARE_CALL_DEBUG] _handleIncomingCall → currentRoute=${Get.currentRoute}, navigating to IncomingRiderOrderScreen');
      // Start ringtone for fare-call too
      startRingtone();
      // Navigate to rider order screen instead of regular call screen
      if (Get.currentRoute != '/IncomingRiderOrderScreen') {
        Get.toNamed('/IncomingRiderOrderScreen');
      }
      return;
    }

    isFareCall.value = false;
    fareCallOrderId.value = '';
    fareCallOrderMongoId.value = '';
    fareCallRideDetails.value = null;

    // Foreground: navigating to the in-app IncomingCallScreen is enough —
    // the activity is visible so the screen renders immediately.
    //
    // Background (app alive but activity paused): navigation alone is
    // invisible, and the FCM bg-isolate's `showCallkitIncoming` is unreliable
    // on many OEMs (Xiaomi/Vivo/Realme/OnePlus) — they suppress full-screen
    // intents triggered from a non-foreground isolate. Calling CallKit from
    // the MAIN isolate here is reliable because the plugin's MethodChannel
    // is already initialized and the call comes from the activity's own
    // process context, so the OEM lets the IncomingCallActivity launch via
    // USE_FULL_SCREEN_INTENT and the user actually sees the call UI.
    if (!isAppInForeground && Platform.isAndroid) {
      print('[CALL_DEBUG] _handleIncomingCall → app in background, posting local full-screen-intent notification');
      final ct = callType.value == CallType.video ? 'video_call' : 'audio_call';
      showIncomingCallLocalNotification(
        callId: callId.value,
        roomId: roomId.value,
        callerName: callerName.value.isNotEmpty ? callerName.value : 'Unknown',
        callerImage: callerImage.value,
        callType: ct,
        extra: {
          'callId': callId.value,
          'roomId': roomId.value,
          'conversationId': conversationId.value,
          'callType': ct,
          'callerName': callerName.value,
          'callerImage': callerImage.value,
          'senderId': _remoteUserId ?? '',
          'operation': 'incoming_call',
        },
      );
      return;
    }

    // Start ringtone from controller so it keeps playing even if screen is
    // not yet mounted, and can be reliably stopped on decline/cancel/end.
    startRingtone();

    if (Get.currentRoute != '/IncomingCallScreen') {
      Get.toNamed('/IncomingCallScreen');
    }
  }

  /// Accept an incoming call.
  /// On Android (main engine): does API accept, then launches CallActivity for WebRTC.
  /// On CallActivity engine: does full accept (API + WebRTC).
  Future<bool> acceptCall({String? callIdParams, String? roomIdParams,bool? isVideoCall}) async {
    print('[CALL_DEBUG] acceptCall → START, callIdParams=$callIdParams, roomIdParams=$roomIdParams, isVideoCall=$isVideoCall, currentStatus=${callStatus.value}');

    // Prevent double accept (multiple CallKit listeners may fire)
    stopRingtone();
    // Cancel Android local notification (background/terminated path)
    if (callId.value.isNotEmpty) cancelIncomingCallLocalNotification(callId.value);
    isIncomingCall.value=false;
    if (callStatus.value == CallStatus.accepting ||
        callStatus.value == CallStatus.connecting ||
        callStatus.value == CallStatus.connected) {
      print('[CALL_DEBUG] acceptCall → SKIPPED (already ${callStatus.value})');
      return false;
    }
    // Re-bind call socket listeners in case ChatViewController.disposeSocket()
    // wiped them since the last app resume — without this the accepter never
    // hears call:offer / call:answer / call:ice-candidate and the call sits on
    // "Connecting" until the 30s timeout. Idempotent.
    ensureCallSocketListeners();

    // Immediately transition to accepting so call:answered-elsewhere
    // won't reset our state while we're in the middle of accepting
    final savedCallId = (callIdParams == null||callIdParams.isEmpty) ? callId.value : callIdParams;
    final savedRoomId = (roomIdParams == null||roomIdParams.isEmpty) ? roomId.value : roomIdParams;
    final savedRemoteUserId = _remoteUserId;
    final savedPendingOffer = _pendingOffer;

    // State could have been wiped by _cleanup() (remote hang-up / answered-
    // elsewhere) between the screen opening and the user tapping accept.
    // Sending empty IDs guarantees a 400 "call_id and room_id required" —
    // bail cleanly instead with a user-facing message.
    if (savedCallId.isEmpty || savedRoomId.isEmpty) {
      print('[CALL_DEBUG] acceptCall → ABORT, empty IDs (callId=$savedCallId, roomId=$savedRoomId)');
      commonSnackBar(message: AppStrings.callNoLongerAvailable.tr);
      _cleanup();
      return false;
    }

    callStatus.value = CallStatus.accepting;

    // Make accept feel instant: swap the incoming screen for the active call
    // screen the MOMENT the user taps Accept — before the permission request,
    // socket wait and `/call/accept` round-trip below. Without this the user
    // stares at the incoming screen's "Connecting…" spinner for the full accept
    // handshake. Both '/IncomingCallScreen' and '/CallRoomScreen' resolve to the
    // same CallActivityRoomScreen (route_helper.dart:2135-2142), so this only
    // swaps the route name and hands us a FRESH widget — which clears the
    // screen's stuck local `_isAccepting` spinner and renders the active-call
    // layout straight from callStatus=accepting. Scoped to iOS + foreground:
    // Android main-engine launches a separate CallActivity below, and
    // killed-state accepts (currentRoute != '/IncomingCallScreen') rely on the
    // native CallKit UI. The later same-guarded Get.offNamed at the
    // post-API point is now a no-op fallback (route is already /CallRoomScreen).
    if (Platform.isIOS &&
        !isFareCall.value &&
        Get.currentRoute == '/IncomingCallScreen') {
      Get.offNamed('/CallRoomScreen');
    }

    // Request permissions (wrapped in try-catch to avoid PlatformException
    // when another permission request is already in progress)
    if(isVideoCall!=null){
      callType.value=isVideoCall?CallType.video:CallType.audio;
    }
    try {
      final permissions = [Permission.microphone];
      if (callType.value == CallType.video) permissions.add(Permission.camera);
      await permissions.request();
    } catch (e) {
      if (kDebugMode)
        print('Permission request error (may already be in progress): $e');
    }

    // --- iOS-only early room join (Android→iOS race fix) ---
    // The /call/accept round-trip makes the server emit `call:accepted` to the
    // caller BEFORE iOS reaches the line-752 join-room. The caller's immediate
    // `call:offer` is then broadcast to the room while iOS is not yet a
    // member, so the server's room filter drops it. Joining early puts iOS in
    // the room before the offer dispatches; _handleRemoteOffer buffers into
    // _pendingOffer (status == accepting), and the later branch consumes it
    // once media is ready. Scoped to iOS (+ non-fare) to keep the change
    // zero-risk on Android / CallActivity / fare-call paths.
    if (Platform.isIOS && !isFareCall.value && savedRoomId.isNotEmpty) {
      try {
        if (!_socket.isConnected) {
          _socket.connectToSocket();
          await _waitForSocketConnection();
        }
        _socket.emitEvent('call:join-room', {'room_id': savedRoomId});
        print('[CALL_DEBUG] acceptCall → early iOS join-room emitted pre-API, roomId=$savedRoomId');
      } catch (e) {
        print('[CALL_DEBUG] acceptCall → early join-room error (non-fatal): $e');
      }
    }


    print('[CALL_DEBUG] acceptCall → API call starting, callId=$savedCallId, roomId=$savedRoomId');
    ResponseModel response = await _callRepo.acceptCall({
      'call_id': savedCallId,
      'room_id': savedRoomId,
    });

    if (!response.isSuccess) {
      final statusCode = response.response?.statusCode;
      print('[CALL_DEBUG] acceptCall → API FAILED, statusCode=$statusCode, message=${response.message}');
      if (_isCallGoneResponse(response)) {
        commonSnackBar(message: AppStrings.callNoLongerAvailable.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.failedToAcceptCall.tr);
      }
      _cleanup();
      return false;
    }

    final data = response.response?.data;
    final iceServersJson = data?['ice_servers'] ?? {};
    print('[CALL_DEBUG] acceptCall → API SUCCESS, iceServers=${iceServersJson != null ? "present" : "null"}');

    // Tell CallKit the call is connected as soon as the server accepts.
    // Why: flutter_callkit_incoming has an internal `duration` countdown and will
    // auto-convert a still-"ringing" call into a missed call when it elapses —
    // even if the user already tapped Accept. Marking it connected stops that
    // countdown so an active call cannot flip to "missed" mid-conversation.
    // Skip for fare-calls (no CallKit session was ever shown). Also skip when
    // CallKit was never shown for this call (foreground in-app accept) —
    // calling setCallConnected with an unknown id throws "content null" and
    // wedges plugin state for the NEXT incoming call.
    if (!isFareCall.value && callKitWasShownFor(savedCallId)) {
      try {
        await FlutterCallkitIncoming.setCallConnected(savedCallId);
      } catch (e) {
        print('[CALL_DEBUG] acceptCall → setCallConnected error: $e');
      }
    }

    // Dismiss CallKit incoming call UI after API accept succeeds.
    // On Android: dismiss immediately (CallActivity handles audio).
    // On iOS: dismiss AFTER WebRTC setup so CallKit keeps the audio session
    // active during the handshake — dismissing too early kills the audio path.
    print('[FARE_CALL_DEBUG] acceptCall → isFareCall=${isFareCall.value}, platform=${Platform.isAndroid ? "Android" : "iOS"}');
    if (Platform.isAndroid &&
        !isFareCall.value &&
        callKitWasShownFor(savedCallId)) {
      _isDismissingCallKitUI = true;
      try {
        await FlutterCallkitIncoming.endCall(savedCallId);
        clearCallKitShownFor(savedCallId);
      } catch (e) {
        print('[FARE_CALL_DEBUG] acceptCall → CallKit endCall error: $e');
      } finally {
        _isDismissingCallKitUI = false;
      }
    }

    // Cancel the Android local-notification incoming-call card (the new
    // flutter_local_notifications path used in background/terminated). Safe
    // to call even if no notification was posted — cancel-by-id is a no-op.
    if (Platform.isAndroid && !isFareCall.value) {
      cancelIncomingCallLocalNotification(savedCallId);
    }

    // WebRTC is handled in-process on every platform. Android used to hand off
    // to a separate CallActivity task running its own Flutter engine here; that
    // engine is gone, so this is now the single accept path.
    // ice_servers can be a Map {'iceServers': [...]} or a raw List [...]
    if (iceServersJson is List) {
      _iceConfig = IceServerConfig(
        iceServers: iceServersJson
            .whereType<Map<String, dynamic>>()
            .map((s) => IceServer.fromJson(s))
            .toList(),
      );
    } else if (iceServersJson is Map<String, dynamic>) {
      _iceConfig = IceServerConfig.fromJson(iceServersJson);
    } else {
      _iceConfig = null;
    }

    callStatus.value = CallStatus.connecting;

    // Land on the active call UI. Without this, IncomingCallScreen sits on its
    // "Connecting…" loader forever even after the peer connection reaches
    // Connected — its _isAccepting flag only clears on accept failure.
    //
    // Accepts also arrive from outside any call screen (notification action,
    // CallKit, background, killed-state cold start), so this pushes on top of
    // whatever the app is showing and retries until the navigator is ready.
    _openCallRoom();

    // Ensure socket is connected and wait for it (killed-state accept may
    // start before socket is ready — without waiting, emitEvent is lost)
    // print('[CALL_DEBUG] acceptCall → socket.isConnected=${_socket.isConnected}');
    if (!_socket.isConnected) {
      // print('[CALL_DEBUG] acceptCall → socket disconnected, reconnecting...');
      _socket.connectToSocket();
      await _waitForSocketConnection();
      // print('[CALL_DEBUG] acceptCall → socket wait done, isConnected=${_socket.isConnected}');
    }

    // Show ongoing notification immediately to keep app in foreground
    _showConnectingNotification();

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': savedRoomId});
    // print('[CALL_DEBUG] acceptCall → emitted call:join-room, roomId=$savedRoomId');

    // Setup local media — signal when ready so offer handler can wait
    try {
      print('[FARE_CALL_DEBUG] acceptCall → setting up local media...');
      _mediaReadyCompleter = Completer<void>();
      await _setupLocalMedia();
      if (!_mediaReadyCompleter!.isCompleted) {
        _mediaReadyCompleter!.complete();
      }
      // print('[FARE_CALL_DEBUG] acceptCall → local media ready, localStream=${localStream != null ? "EXISTS (tracks=${localStream!.getTracks().length})" : "NULL"}');

      // If we received an SDP offer while ringing/accepting, process it now
      final offerToProcess = _pendingOffer ?? savedPendingOffer;
      // print('[CALL_DEBUG] acceptCall → pendingOffer=${offerToProcess != null ? "YES" : "NO"}, remoteUserId=$savedRemoteUserId');
      // print('[FARE_CALL_DEBUG] acceptCall → _pendingOffer=${_pendingOffer != null ? "YES" : "NO"}, savedPendingOffer=${savedPendingOffer != null ? "YES" : "NO"}');
      // print('[FARE_CALL_DEBUG] acceptCall → existing peerConnections=${peerConnections.keys.toList()}');
      if (offerToProcess != null && savedRemoteUserId != null) {
        // print('[CALL_DEBUG] acceptCall → processing pending offer, creating answer...');
        final pc = await _createPeerConnection(savedRemoteUserId);
        final sdp = RTCSessionDescription(
          offerToProcess['sdp'],
          offerToProcess['type'],
        );
        await pc.setRemoteDescription(sdp);
        // print('[CALL_DEBUG] acceptCall → remote description set');
        await _flushPendingCandidates(savedRemoteUserId);
        // print('[CALL_DEBUG] acceptCall → pending ICE candidates flushed');

        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        // print('[CALL_DEBUG] acceptCall → answer created, emitting call:answer');
        _socket.emitEvent('call:answer', {
          'room_id': savedRoomId,
          'target_user_id': savedRemoteUserId,
          'sdp': {'sdp': answer.sdp, 'type': answer.type},
          // Required for the server to emit `connected` back to the caller via
          // `call:ringing`. Without it, the caller stays on `connecting`.
          'call_id': callId.value,
        });
        _pendingOffer = null;
        // print('[CALL_DEBUG] acceptCall → call:answer emitted to $savedRemoteUserId');
      } else if (savedRemoteUserId != null) {
        // No pending offer yet — send our own. Glare is resolved by the
        // caller's `_handleRemoteOffer` re-sending its own offer back to us,
        // which we then yield to (close+recreate PC and answer).
        // Fare-calls keep the original "wait silently" behavior (the customer
        // app initiates from its side via _handleCallAccepted).
        if (isFareCall.value) {
          // Fare-call: proactively send an offer instead of waiting silently.
          // The caller's offer may arrive before the rider joins the room and
          // get lost — sending our own offer ensures the WebRTC handshake
          // completes. Glare is handled by _handleRemoteOffer (callee yields).
          // print('[FARE_CALL] acceptCall → no pending offer, sending our own offer (fare-call, glare-safe)');
          final pc = await _createPeerConnection(savedRemoteUserId);
          final offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          _socket.emitEvent('call:offer', {
            'room_id': savedRoomId,
            'target_user_id': savedRemoteUserId,
            'sdp': {'sdp': offer.sdp, 'type': offer.type},
          });
          _scheduleOfferRetry(savedRemoteUserId);
          // print('[FARE_CALL] acceptCall → call:offer emitted to $savedRemoteUserId (rider-initiated)');
        } else {
          // print('[CALL_DEBUG] acceptCall → NO pending offer, sending our own offer (glare-safe)');
          final pc = await _createPeerConnection(savedRemoteUserId);
          final offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          _socket.emitEvent('call:offer', {
            'room_id': savedRoomId,
            'target_user_id': savedRemoteUserId,
            'sdp': {'sdp': offer.sdp, 'type': offer.type},
          });
          _scheduleOfferRetry(savedRemoteUserId);
          // print('[CALL_DEBUG] acceptCall → call:offer emitted to $savedRemoteUserId (receiver-initiated)');
        }
      } else {
        // print('[CALL_DEBUG] acceptCall → WARNING: no remoteUserId, cannot create WebRTC connection');
      }
    } catch (e, stack) {
      print('acceptCall WebRTC error: $e');
      print(stack.toString());
      _cleanup();
      return false;
    }

    // On iOS: now that WebRTC is set up and the audio session is active,
    // dismiss the CallKit UI. The WebRTC audio session takes over.
    // We set _isDismissingCallKitUI so the resulting actionCallEnded event
    // does NOT trigger endCall() and kill the live call.
    // Skip for fare-calls — no CallKit notification was shown for socket-based calls.
    if (Platform.isIOS &&
        !isFareCall.value &&
        callKitWasShownFor(savedCallId)) {
      try {
        _isDismissingCallKitUI = true;
        await FlutterCallkitIncoming.endCall(savedCallId);
        clearCallKitShownFor(savedCallId);
      } catch (_) {}
      // Small delay to ensure the actionCallEnded event is processed
      // before we lower the flag.
      await Future.delayed(const Duration(milliseconds: 300));
      _isDismissingCallKitUI = false;
    }

    // Keep screen on and keep socket alive during call
    WakelockPlus.enable();
    SocketKeepAliveService.start();

    // Start a 30-second connection timeout — if not connected by then, end the call
    _startConnectionTimeout();

    return true;
  }

  Timer? _connectionTimer;
  Timer? _peerDisconnectTimer;

  // ── Network loss during a call ──────────────────────────────────────────
  //
  // A call may survive this long without a working transport before it is torn
  // down on both ends. Previously nothing enforced it:
  // `RTCPeerConnectionStateDisconnected` only printed a log line, and
  // `_peerDisconnectTimer` was declared and cancelled in three places but NEVER
  // STARTED — so when one side lost internet the other sat in a ghost call
  // indefinitely, timer still ticking, with no audio.
  static const Duration _networkGracePeriod = Duration(seconds: 10);
  Timer? _networkGraceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// True while the transport is down and we are inside the grace window. The
  /// call screen shows a "Reconnecting…" state off this instead of freezing.
  final isReconnecting = false.obs;
  Timer? _offerRetryTimer;

  void _startConnectionTimeout() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(const Duration(seconds: 30), () {
      if (callStatus.value == CallStatus.connecting ||
          callStatus.value == CallStatus.accepting) {
        if (kDebugMode) print('Call connection timeout — ending call');
        // GlobalMessageService isn't registered in the CallActivity engine,
        // so guard the snackbar to avoid "GlobalMessageService not found".
        if (Get.isRegistered<GlobalMessageService>()) {
          commonSnackBar(message: AppStrings.callConnectionTimedOut.tr);
        }
        endCall();
      }
    });
  }

  /// Re-send the SDP offer while the handshake hasn't progressed. Heals the
  /// lost-offer race: the caller emits `call:offer` the moment `call:accepted`
  /// arrives, but the receiver only joins the socket room after its accept
  /// API returns — an offer broadcast before that join is dropped and both
  /// sides sit on "Connecting" until the 30s timeout. The SAME local
  /// description is re-emitted (never a fresh createOffer), so a duplicate is
  /// harmless: the receiver just sets it and answers again — which also heals
  /// a lost `call:answer` in the opposite direction.
  void _scheduleOfferRetry(String peerId) {
    _offerRetryTimer?.cancel();
    int attempts = 0;
    _offerRetryTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      final pc = peerConnections[peerId];
      if (_disposed ||
          pc == null ||
          attempts >= 2 ||
          callStatus.value != CallStatus.connecting ||
          pc.signalingState !=
              RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        t.cancel();
        return;
      }
      attempts++;
      try {
        final local = await pc.getLocalDescription();
        if (local == null || local.sdp == null) return;
        print(
            '[CALL_DEBUG] offer retry #$attempts → re-emitting call:offer to $peerId');
        _socket.emitEvent('call:offer', {
          'room_id': roomId.value,
          'target_user_id': peerId,
          'sdp': {'sdp': local.sdp, 'type': local.type},
        });
      } catch (e) {
        print('[CALL_DEBUG] offer retry failed: $e');
      }
    });
  }

  /// Called from CallActivity engine to set up an already-accepted incoming call.
  /// The API accept was done by the main engine; this engine handles WebRTC/socket.
  Future<bool> setupAcceptedCall({
    required String iceServersJson,
    required String remoteUserId,
  }) async {
    // Request permissions
    try {
      final permissions = [Permission.microphone];
      if (callType.value == CallType.video) permissions.add(Permission.camera);
      await permissions.request();
    } catch (e) {
      if (kDebugMode) print('Permission request error: $e');
    }

    // Parse ICE servers
    try {
      _iceConfig = IceServerConfig.fromJson(jsonDecode(iceServersJson));
    } catch (_) {}
    _remoteUserId = remoteUserId;

    callStatus.value = CallStatus.connecting;

    // Connect socket for this engine and wait for connection
    if (!_socket.isConnected) {
      _socket.connectToSocket();
      // Wait for socket to actually connect before joining room
      await _waitForSocketConnection();
    }

    // Show ongoing notification
    _showConnectingNotification();

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': roomId.value});

    // Setup local media
    try {
      _mediaReadyCompleter = Completer<void>();
      await _setupLocalMedia();
      if (!_mediaReadyCompleter!.isCompleted) {
        _mediaReadyCompleter!.complete();
      }

      // Create peer connection and send our offer to the caller. Glare is
      // expected (the caller is also creating an offer). With the caller-side
      // re-send fix in `_handleRemoteOffer`, the caller will re-send its
      // offer to us when it sees ours, so we receive it, yield (close+recreate
      // PC), accept the caller's offer, and answer. Without sending our own
      // offer here, the caller may never know we joined the room, depending
      // on whether the server delivers `call:participant-joined` reliably.
      if (remoteUserId.isNotEmpty) {
        final pc = await _createPeerConnection(remoteUserId);
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);

        _socket.emitEvent('call:offer', {
          'room_id': roomId.value,
          'target_user_id': remoteUserId,
          'sdp': {'sdp': offer.sdp, 'type': offer.type},
        });
        print('[CALL_DEBUG] setupAcceptedCall → emitted call:offer to $remoteUserId');
      }
    } catch (e, stack) {
      print('setupAcceptedCall WebRTC error: $e');
      print(stack.toString());
      _cleanup();
      return false;
    }

    // Keep screen on and keep socket alive during call
    WakelockPlus.enable();
    SocketKeepAliveService.start();

    // Connection timeout
    _startConnectionTimeout();

    return true;
  }

  /// Wait for the socket to connect (up to 10 seconds)
  Future<void> _waitForSocketConnection() async {
    for (int i = 0; i < 100; i++) {
      if (_socket.isConnected) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (kDebugMode) print('Socket connection timed out after 10s');
  }

  /// Decline the ringing call.
  ///
  /// [callIdParams] / [roomIdParams] let a caller that KNOWS the ids — a
  /// notification action, a CallKit event — decline a call this controller was
  /// never told about. Without them the notification's Decline button was a
  /// no-op whenever the socket had not hydrated us first (backgrounded app,
  /// socket still reconnecting): `callStatus` was `idle`, the guard below
  /// returned, and the server never heard a thing.
  Future<void> declineCall({
    String? callIdParams,
    String? roomIdParams,
  }) async {
    stopRingtone();

    // Prefer what the caller handed us; fall back to our own state.
    final targetCallId =
        (callIdParams ?? '').trim().isNotEmpty ? callIdParams!.trim() : callId.value;
    final targetRoomId =
        (roomIdParams ?? '').trim().isNotEmpty ? roomIdParams!.trim() : roomId.value;

    // Cancel Android local notification (background/terminated path)
    if (targetCallId.isNotEmpty) cancelIncomingCallLocalNotification(targetCallId);
    isIncomingCall.value = false;

    // Idle AND nothing was handed in — there is genuinely nothing to decline.
    // With ids in hand we carry on regardless of local status: the ring may be
    // owned by the notification, not by this engine's state.
    if (callStatus.value == CallStatus.idle && targetCallId.isEmpty) return;

    // Notify the server first, then cleanup.
    //
    // WRAPPED, and cleanup moved to `finally`. This used to be a bare `await`:
    // any throw — a timeout, no connectivity, the 400 an already-ended call
    // returns — skipped `_cleanup()` and left `callStatus` stuck at `ringing`
    // FOREVER. From then on every incoming call hit the "already on a call"
    // branch in [_handleIncomingCall] and was auto-declined as busy, so the
    // caller's phone reported an instant reject and this device never rang
    // again until the app was restarted. That is the auto-reject loop.
    try {
      if (targetCallId.isNotEmpty && targetRoomId.isNotEmpty) {
        await _callRepo.declineCall({
          'call_id': targetCallId,
          'room_id': targetRoomId,
        });
      }
    } catch (e) {
      if (kDebugMode) print('declineCall: server decline failed: $e');
      // Swallowed on purpose. The ring must stop and the state must reset
      // whether or not the server heard us — the server's own 20s ring timeout
      // is the backstop for a decline that never landed.
    } finally {
      _cleanup();
      _navigateBackFromCallScreen();
    }
  }

  /// Decline the call AND send [message] to the caller as a chat message —
  /// the "Message" quick action on the incoming-call screen.
  ///
  /// The message is sent BEFORE the decline: [declineCall] runs `_cleanup()`,
  /// which wipes conversationId / remote user id, so sending afterwards would
  /// have nothing left to address the message to.
  Future<void> declineWithMessage(String message) async {
    final text = message.trim();
    if (text.isEmpty) {
      await declineCall();
      return;
    }

    final conversation = conversationId.value;
    final otherUserId = _remoteUserId ?? '';

    try {
      if (conversation.isNotEmpty || otherUserId.isNotEmpty) {
        final chatController = getOrPut(() => ChatViewController());
        final data = <String, dynamic>{
          if (conversation.isNotEmpty)
            ApiKeys.conversation_id: conversation
          else
            ApiKeys.other_user_id: otherUserId,
          ApiKeys.message: text,
          ApiKeys.message_type: 'text',
        };
        // No conversation yet (first contact / incoming call from someone the
        // user has never chatted with) — the initial-message endpoint creates
        // the thread, the normal one requires it to exist.
        if (conversation.isEmpty) {
          await chatController.sendInitialMessage(data);
        } else {
          await chatController.sendMessage(data);
        }
      }
    } catch (e) {
      if (kDebugMode) print('declineWithMessage: send failed: $e');
      // Fall through — failing to deliver the note must never leave the call
      // ringing.
    }

    await declineCall();
  }

  /// Turn away an incoming call that arrived while we are already on one.
  ///
  /// Declines the SECOND call with `reason: "busy"` so the server can tell the
  /// new caller immediately, and deliberately touches NONE of our own call
  /// state — the ids belong to the incoming call, not the live one, and
  /// [declineCall] would tear the live call down with them.
  ///
  /// Also clears any ring the second call already started: the FCM background
  /// isolate has its own CallController state and may have posted a
  /// notification / CallKit UI before this engine saw the socket event, which
  /// would otherwise leave the phone ringing on top of a call in progress.
  Future<void> _rejectAsBusy(dynamic data) async {
    if (data is! Map) return;
    final incomingCallId = (data['call_id'] ?? '').toString();
    final incomingRoomId = (data['room_id'] ?? '').toString();
    // Same call re-delivered (socket echo + FCM) — not a second caller.
    if (incomingCallId.isEmpty || incomingCallId == callId.value) return;

    print('[CALL_DEBUG] busy → declining incoming call $incomingCallId');

    if (incomingCallId.isNotEmpty) {
      cancelIncomingCallLocalNotification(incomingCallId);
      try {
        if (callKitWasShownFor(incomingCallId)) {
          await FlutterCallkitIncoming.endCall(incomingCallId);
          clearCallKitShownFor(incomingCallId);
        }
      } catch (_) {}
    }

    if (incomingRoomId.isEmpty) return;
    try {
      await _callRepo.declineCall({
        'call_id': incomingCallId,
        'room_id': incomingRoomId,
        // Additive: the server already models `busy` as a ringing state
        // (CallRingingState.fromServer), so this asks it to report that rather
        // than a plain decline. Harmless if the field is ignored — the caller
        // then sees "declined" instead of "no answer", still better than a
        // 30-second wait.
        'reason': 'busy',
      });
    } catch (e) {
      if (kDebugMode) print('_rejectAsBusy failed: $e');
    }
  }

  // ==================== NETWORK LOSS HANDLING ====================

  /// Watch the device's connectivity for the lifetime of a call.
  ///
  /// The WebRTC ICE state covers the REMOTE side going away, but not our own
  /// radio dropping while the peer connection has not noticed yet — and on an
  /// incoming call there is no peer connection at all, which is why losing
  /// signal while the phone was ringing left the call screen up with nothing
  /// behind it.
  void _startConnectivityWatch() {
    _connectivitySub ??=
        Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        _onTransportLost('device offline');
      } else {
        _onTransportRestored();
      }
    });
  }

  void _stopConnectivityWatch() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// The transport is down — either our radio or the peer's.
  ///
  /// A call that has not been answered yet cannot survive this: there is no
  /// media path to resume and no way to reach the server to accept, so the
  /// incoming UI is dismissed immediately with an explanation rather than left
  /// on screen over a dead connection.
  ///
  /// A live call gets [_networkGracePeriod] to recover before both ends are
  /// torn down.
  void _onTransportLost(String reason) {
    final status = callStatus.value;
    if (status == CallStatus.idle || status == CallStatus.ended) return;

    if (status == CallStatus.ringing || status == CallStatus.outgoing) {
      print('[CALL_DEBUG] transport lost while $status ($reason) → abandon');
      _abandonCallForNetwork();
      return;
    }

    if (_networkGraceTimer?.isActive == true) return;
    print('[CALL_DEBUG] transport lost ($reason) → '
        '${_networkGracePeriod.inSeconds}s grace');
    isReconnecting.value = true;
    _networkGraceTimer = Timer(_networkGracePeriod, () {
      if (callStatus.value == CallStatus.idle ||
          callStatus.value == CallStatus.ended) {
        return;
      }
      print('[CALL_DEBUG] grace expired → terminating call (network)');
      _abandonCallForNetwork();
    });
  }

  /// Transport came back inside the grace window — keep the call.
  void _onTransportRestored() {
    if (_networkGraceTimer == null && !isReconnecting.value) return;
    print('[CALL_DEBUG] transport restored → cancelling grace timer');
    _networkGraceTimer?.cancel();
    _networkGraceTimer = null;
    isReconnecting.value = false;
    // The socket may have dropped with the radio; getting it back is what lets
    // the teardown signalling below actually reach the other side next time.
    if (!_socket.isConnected) _socket.connectToSocket();
  }

  void _cancelNetworkGrace() {
    _networkGraceTimer?.cancel();
    _networkGraceTimer = null;
    isReconnecting.value = false;
  }

  /// Tear the call down because the connection could not be recovered.
  ///
  /// Best-effort on the wire: we are very likely still offline, so the REST
  /// end-call and the socket emit will fail. That is expected and is why the
  /// server needs its own participant-drop timeout — see
  /// docs/backend/CALL_BACKEND_REQUIREMENTS.md. Locally we always finish the
  /// teardown so this device never sits in a ghost call.
  Future<void> _abandonCallForNetwork() async {
    _cancelNetworkGrace();
    if (callStatus.value == CallStatus.idle ||
        callStatus.value == CallStatus.ended) {
      return;
    }

    final savedCallId = callId.value;
    final savedRoomId = roomId.value;
    final wasUnanswered = callStatus.value == CallStatus.ringing ||
        callStatus.value == CallStatus.outgoing;

    stopRingtone();
    if (savedCallId.isNotEmpty) {
      cancelIncomingCallLocalNotification(savedCallId);
    }

    if (savedCallId.isNotEmpty && savedRoomId.isNotEmpty) {
      try {
        // `end_reason` lets the backend log this as a dropped call rather than
        // a normal hang-up. Unknown fields are ignored server-side, so this is
        // safe to send before the backend work lands.
        // Bounded: we are probably still offline, and an un-timed-out request
        // would hold teardown open behind a connection that is not coming back.
        await _callRepo.endCall({
          'call_id': savedCallId,
          'room_id': savedRoomId,
          'end_reason': 'network_error',
        }).timeout(const Duration(seconds: 4));
      } catch (_) {}
      try {
        _socket.emitEvent('call:leave-room', {
          'room_id': savedRoomId,
          'call_id': savedCallId,
          'reason': 'network_error',
        });
      } catch (_) {}
    }

    if (callStatus.value != CallStatus.idle) {
      _cleanup();
      _navigateBackFromCallScreen();
    }

    commonSnackBar(
      message: wasUnanswered
          ? AppStrings.callFailedNoConnection.tr
          : AppStrings.callEndedNoConnection.tr,
    );
  }

  /// Cancel an outgoing call (before anyone answers)
  Future<void> cancelCall() async {
    if (callStatus.value == CallStatus.idle) return;

    final savedCallId = callId.value;
    final savedRoomId = roomId.value;

    // Notify server first, then cleanup
    if (savedCallId.isNotEmpty && savedRoomId.isNotEmpty) {
      await _callRepo.cancelCall({
        'call_id': savedCallId,
        'room_id': savedRoomId,
      });
      _socket.emitEvent('call:leave-room', {
        'room_id': savedRoomId,
        'call_id': savedCallId,
      });
    }

    _cleanup();
    _navigateBackFromCallScreen();
  }

  /// End an active call
  Future<void> endCall() async {
    print('[CALL_DEBUG] endCall → called, currentStatus=${callStatus.value}, caller stack: ${StackTrace.current.toString().split('\n').take(6).join(' | ')}');
    // Guard: skip if already idle (prevents re-entrant calls from CallKit events)
    isIncomingCall.value=false;
    if (callStatus.value == CallStatus.idle) return;

    // Capture IDs before cleanup clears them
    final savedCallId = callId.value;
    final savedRoomId = roomId.value;

    // Notify server first so remote side gets proper signaling teardown.
    // IMPORTANT: during this await, the server will emit `call:ended` back to
    // us, which `_handleCallEnded` will pick up and run `_cleanup` already.
    // If we also run `_cleanup` below, we double-dispose local media/renderers
    // and stop SocketKeepAliveService twice — which breaks every *subsequent*
    // call (peer connection closes immediately with onConnectionChangeCLOSED).
    // So: re-check status after the await and skip the second cleanup if the
    // socket handler already brought us back to idle.
    if (savedCallId.isNotEmpty && savedRoomId.isNotEmpty) {
      await _callRepo.endCall({
        'call_id': savedCallId,
        'room_id': savedRoomId,
      });
      if (callStatus.value != CallStatus.idle) {
        _socket.emitEvent('call:leave-room', {
          'room_id': savedRoomId,
          'call_id': savedCallId,
        });
      }
    }

    // Only cleanup if the socket `call:ended` handler hasn't already done it.
    if (callStatus.value != CallStatus.idle) {
      _cleanup();
      _navigateBackFromCallScreen();
    } else {
      print('[CALL_DEBUG] endCall → skipping second _cleanup (already cleaned by call:ended handler)');
    }
  }

  // ==================== SOCKET EVENT HANDLERS ====================

  void _handleCallAccepted(dynamic data) async {
    print('[CALL_DEBUG] _handleCallAccepted → received, currentStatus=${callStatus.value}, data=$data');

    // Fare-call fallback: if ride:queue:calling was missed (race condition or
    // server skipped it for single-rider orders), the customer's callStatus is
    // still idle when call:accepted arrives. Detect this via metadata and
    // bootstrap the call state so the WebRTC handshake can proceed.
    if (callStatus.value == CallStatus.idle) {
      final metadata = data['metadata'];
      if (metadata is Map && metadata['orderType'] == 'fare-call') {
        print('[FARE_CALL] _handleCallAccepted → idle + fare-call metadata, bootstrapping call state');
        final acceptedCallId = (data['call_id'] ?? '').toString();
        // Backend sends snake_case `room_id`; keep the old `room_Id` read as a
        // fallback (this branch previously never fired because of that typo).
        final acceptedRoomId =
            (data['room_id'] ?? data['room_Id'] ?? '').toString();
        final acceptedBy = (data['accepted_by'] ?? '').toString();
        if (acceptedCallId.isNotEmpty && acceptedRoomId.isNotEmpty && acceptedBy.isNotEmpty) {
          // Also set fareCallCurrentRiderId on DiscoverController so the
          // fallback path on FareCallQueueScreen has it when
          // ride:queue:calling was skipped by the server.
          try {
            final dc = Get.find<DiscoverController>();
            if (dc.fareCallCurrentRiderId.value.isEmpty) {
              dc.fareCallCurrentRiderId.value = acceptedBy;
            }
          } catch (_) {}
          await joinFareCallAsCustomer(
            fareCallId: acceptedCallId,
            fareRoomId: acceptedRoomId,
            riderId: acceptedBy,
            fareConversationId: '',
            iceServers: [],
          );
          // joinFareCallAsCustomer sets callStatus=outgoing — fall through
          // to the normal outgoing handling below.
        } else {
          print('[FARE_CALL] _handleCallAccepted → missing call data, cannot bootstrap');
          return;
        }
      }
    }

    if (callStatus.value != CallStatus.outgoing) {
      print('[CALL_DEBUG] _handleCallAccepted → SKIPPED (not outgoing)');
      return;
    }

    _ringTimer?.cancel();
    // Receiver picked up — silence the caller-side ringback. This path does
    // NOT go through `_cleanup` (that runs only on terminal states), so the
    // ringback would otherwise keep looping until the call ends.
    stopOutgoingRingback();
    callStatus.value = CallStatus.connecting;
    final acceptedBy = data['accepted_by'] ?? '';
    _remoteUserId = acceptedBy;
    print('[CALL_DEBUG] _handleCallAccepted → acceptedBy=$acceptedBy, creating offer...');

    // For fare-calls: customer stays on FareCallQueueScreen — audio connects in background.
    // For regular calls: navigate to CallRoomScreen.
    print('[FARE_CALL_DEBUG] _handleCallAccepted → isFareCall=${isFareCall.value}');
    _openCallRoom();

    // Caller creates and sends the SDP offer
    print('[FARE_CALL_DEBUG] _handleCallAccepted → existing peerConnections=${peerConnections.keys.toList()}, localStream=${localStream != null ? "EXISTS" : "NULL"}, _remoteUserId=$_remoteUserId');
    final pc = peerConnections[_remoteUserId] ??
        await _createPeerConnection(_remoteUserId!);

    print('[FARE_CALL_DEBUG] _handleCallAccepted → peerConnection signalingState=${pc.signalingState}, connectionState=${pc.connectionState}');

    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      print('[CALL_DEBUG] _handleCallAccepted → offer created, emitting call:offer');
      print('[FARE_CALL_DEBUG] _handleCallAccepted → offer SDP type=${offer.type}, SDP length=${offer.sdp?.length}');

      _socket.emitEvent('call:offer', {
        'room_id': roomId.value,
        'target_user_id': _remoteUserId,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
      print('[CALL_DEBUG] _handleCallAccepted → call:offer emitted to $_remoteUserId');
      // The receiver may not have joined the socket room yet (its accept API
      // is still in flight) — retry the offer until the handshake progresses.
      _scheduleOfferRetry(_remoteUserId!);
    } catch (e, stack) {
      print('[FARE_CALL_DEBUG] _handleCallAccepted → OFFER CREATION FAILED: $e');
      print('[FARE_CALL_DEBUG] _handleCallAccepted → stack: $stack');
    }
  }

  void _handleCallDeclined(dynamic data) {
    stopRingtone();
    final callEnded = data['call_ended'] ?? true;
    _ringTimer?.cancel();

    // Fare-call: rider declined this call, but the queue continues.
    // Just cleanup WebRTC state — don't pop screen or show snackbar.
    // The server will send ride:queue:calling for the next rider.
    if (isFareCall.value) {
      print('[FARE_CALL] _handleCallDeclined → rider declined, cleaning up for next rider');
      _leaveRoomAndCleanup();
      return;
    }

    if (callEnded == true) {
      try { commonSnackBar(message: AppStrings.callDeclined.tr); } catch (_) {}
      _leaveRoomAndCleanup();
      Get.back();
    } else {
      // Group call: some users declined but others may still answer
      if (kDebugMode) print('User ${data['declined_by']} declined group call');
    }
  }

  void _handleCallCancelled(dynamic data) {
    stopRingtone();
    print('[CALL_DEBUG] _handleCallCancelled → isFareCall=${isFareCall.value}, callStatus=${callStatus.value}, data=$data');

    // Always cancel the Android local notification for this call — it may have
    // been posted by the FCM background isolate and keeps ringing independently
    // of any in-app AudioPlayer.
    final cancelledCallId = (data is Map ? (data['call_id'] ?? '').toString() : '');
    if (cancelledCallId.isNotEmpty) {
      cancelIncomingCallLocalNotification(cancelledCallId);
    }

    // Even if main isolate's CallController state is idle, CallKit may have
    // been shown by the FCM background isolate (different isolate, different
    // GetX state) — in that case the lingering CallKit notification blocks
    // the NEXT incoming call's UI from appearing on the same device. Always
    // dismiss the cancelled call's id at the plugin level before bailing.
    if (callStatus.value == CallStatus.idle) {
      try {
        if (cancelledCallId.isNotEmpty && callKitWasShownFor(cancelledCallId)) {
          FlutterCallkitIncoming.endCall(cancelledCallId);
          clearCallKitShownFor(cancelledCallId);
          print('[CALL_DEBUG] _handleCallCancelled → dismissed lingering CallKit id=$cancelledCallId (state was idle)');
        }
      } catch (_) {}
      return;
    }

    // Fare-call: don't dismiss CallKit (none shown) and don't pop fare-call screens
    if (isFareCall.value) {
      print('[FARE_CALL] _handleCallCancelled → cleaning up without navigating');
      _leaveRoomAndCleanup();
      return;
    }

    if (callKitWasShownFor(callId.value)) {
      try {
        FlutterCallkitIncoming.endCall(callId.value);
        clearCallKitShownFor(callId.value);
      } catch (_) {}
    }
    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
  }

  void _handleCallEnded(dynamic data) {
    stopRingtone();
    // Cancel any lingering Android local notification for this call
    final endedId = data is Map ? (data['call_id'] ?? '').toString() : '';
    if (endedId.isNotEmpty) cancelIncomingCallLocalNotification(endedId);
    if (callId.value.isNotEmpty) cancelIncomingCallLocalNotification(callId.value);

    print('[CALL_DEBUG] _handleCallEnded → isFareCall=${isFareCall.value}, callStatus=${callStatus.value}, data=$data');
    // The post-call interstitial used to be shown from here for CallActivity
    // calls, because that engine had no Ads SDK. The call now ends in this
    // engine, so the normal teardown path (_showCallEndedInterstitial) handles
    // it and this special case is gone.
    if (callStatus.value == CallStatus.idle) return;

    // Ignore self-originated `call:ended` echoes: if the server is just
    // telling us about an event WE triggered (e.g. after our own endCall
    // hit the API), don't re-run cleanup. Some backends also broadcast
    // `call:ended` when only ONE peer leaves a multi-party room — we
    // should only tear down if the call actually ended for us, which we
    // detect via a `call_id` match AND the call actually being live.
    final endedCallId = data is Map ? (data['call_id'] ?? '').toString() : '';
    if (endedCallId.isNotEmpty && callId.value.isNotEmpty && endedCallId != callId.value) {
      print('[CALL_DEBUG] _handleCallEnded → IGNORED stale event, endedCallId=$endedCallId vs active=${callId.value}');
      return;
    }

    // Fare-call: don't pop fare-call screens — the queue/map handles its own
    // lifecycle. Still fire the interstitial (fare/rider calls get ads too),
    // since this branch returns before _navigateBackFromCallScreen.
    if (isFareCall.value) {
      print('[FARE_CALL] _handleCallEnded → cleaning up without navigating');
      _showCallEndedInterstitial();
      _leaveRoomAndCleanup();
      return;
    }

    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
  }

  void _handleAnsweredElsewhere(dynamic data) {
    stopRingtone();
    // Only dismiss if still ringing - do NOT reset if accepting or active
    if (callStatus.value != CallStatus.ringing) return;
    if (callKitWasShownFor(callId.value)) {
      try {
        FlutterCallkitIncoming.endCall(callId.value);
        clearCallKitShownFor(callId.value);
      } catch (_) {}
    }
    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
  }

  // ==================== OUTGOING-CALL RINGING STATE ====================

  /// Reset ringing state when starting a new outgoing call. Call right after
  /// `POST /call/initiate` succeeds.
  void _attachRingingState() {
    ringingState.value = CallRingingState.dialing;
    ringingParticipantStates.clear();
  }

  /// Locally derive a terminal state when the server cannot emit `call:ringing`
  /// (REST 409 = busy, REST 5xx = failed). The outgoing screen reads this and
  /// auto-dismisses ~2s later via its terminal-state handler.
  void markRingingFailedLocally(CallRingingState state) {
    if (!state.isTerminal) return;
    ringingState.value = state;
  }

  /// Handle server-pushed `call:ringing` event. Updates ringingState (1-to-1)
  /// or aggregates participant states (group). Stale events for other calls
  /// are ignored via the call_id filter.
  void _handleCallRinging(dynamic raw) {
    if (raw is! Map) return;
    final data = raw.cast<String, dynamic>();
    final eventCallId = (data['call_id'] ?? '').toString();
    // Filter stale events: ignore if not for the current outgoing call.
    if (callId.value.isEmpty || eventCallId != callId.value) {
      print('[CALL_DEBUG] call:ringing → IGNORED (callId mismatch: event=$eventCallId active=${callId.value})');
      return;
    }

    final isGroup = data['is_group_call'] == true;
    if (isGroup && data['participants'] is List) {
      ringingParticipantStates.clear();
      for (final p in (data['participants'] as List)) {
        if (p is! Map) continue;
        final userId = (p['user_id'] ?? '').toString();
        if (userId.isEmpty) continue;
        ringingParticipantStates[userId] =
            CallRingingState.fromServer(p['state']?.toString());
      }
      ringingState.value = _aggregateGroupRingingState();
    } else {
      ringingState.value =
          CallRingingState.fromServer(data['state']?.toString());
    }

    print('[CALL_DEBUG] call:ringing → state=${ringingState.value.name}, group=$isGroup');
  }

  /// Aggregate group participant states into a single label state.
  /// Priority: connected > connecting > ringing > dialing > terminal.
  CallRingingState _aggregateGroupRingingState() {
    final values = ringingParticipantStates.values;
    if (values.isEmpty) return CallRingingState.dialing;
    if (values.any((s) => s == CallRingingState.connected)) {
      return CallRingingState.connected;
    }
    if (values.any((s) => s == CallRingingState.connecting)) {
      return CallRingingState.connecting;
    }
    if (values.any((s) => s == CallRingingState.ringing)) {
      return CallRingingState.ringing;
    }
    if (values.any((s) => s == CallRingingState.dialing)) {
      return CallRingingState.dialing;
    }
    // All remaining participants are in terminal states → call effectively over.
    return CallRingingState.noAnswer;
  }

  /// Reset ringing state on call:ended / cleanup so the next outgoing call
  /// starts from a clean slate.
  void _resetRingingState() {
    ringingState.value = CallRingingState.dialing;
    ringingParticipantStates.clear();
  }

  /// Leave socket room and cleanup — ensures server knows we left
  void _leaveRoomAndCleanup() {
    if (roomId.value.isNotEmpty) {
      _socket.emitEvent('call:leave-room', {
        'room_id': roomId.value,
        'call_id': callId.value,
      });
    }
    _cleanup();
  }

  /// Safely navigate back from any call screen if currently on one
  void _navigateBackFromCallScreen() {
    _showCallEndedInterstitial();

    final route = Get.currentRoute;
    if (kDebugMode) print('_navigateBackFromCallScreen: currentRoute=$route');
    if (route == '/CallRoomScreen' ||
        route == '/ActiveCallScreen' ||
        route == '/OutgoingCallScreen' ||
        route == '/IncomingCallScreen' ||
        route == '/IncomingRiderOrderScreen') {
      Get.back();
    }
    // Note: FareCallQueueScreen manages its own lifecycle via DiscoverController
  }

  /// Show a full-screen interstitial ad once a call tears down — every call
  /// type (regular, fare and rider). Both the caller and the callee reach the
  /// call-teardown path —
  /// `endCall` for whoever hangs up, `_handleCallEnded` / `_handleAnsweredElsewhere`
  /// for the other side — so the ad shows on both ends, on Android and iOS.
  /// Best-effort: deferred a beat so it overlays the post-call screen (chat /
  /// home) instead of the call UI mid-dismiss, and never blocks teardown.
  void _showCallEndedInterstitial() {
    // Only fire for calls that were actually PICKED UP (connected) — never for
    // missed / rejected / unanswered calls. Consume the flag so it fires once
    // per call however many teardown paths reach here.
    final wasConnected = _wasCallConnected;
    _wasCallConnected = false;
    if (!wasConnected) return;

    Future.delayed(const Duration(milliseconds: 400), () {
      InterstitialAdManager.instance.showInterstitial();
    });
  }

  // ==================== ACTIVE CALL SESSION ====================
  //
  // A small on-disk record of the currently-connected call, used by the chat
  // screens and the Connect banner to show "Live call ongoing".
  //
  // This began as a cross-isolate channel (the call used to run in a second
  // Flutter engine that the chat screens could not read state from). The call
  // now runs in this engine, but the record is kept because it also survives a
  // process restart and is written/read by the FCM background isolate paths.
  // Uses secure storage rather than Hive: Hive caches boxes per-isolate, so a
  // background-isolate write would not be visible here.
  static const String _activeCallKey = 'active_call_session';

  /// Persist the currently-connected call so the chat screens can surface an
  /// "ongoing call" banner. Called on connect from [_startCallTimer].
  static Future<void> saveActiveCallSession({
    required String conversationId,
    required String callId,
    required String roomId,
    required bool isVideo,
    required String remoteName,
    required int startedAtMs,
    String remoteUserId = '',
  }) async {
    try {
      await SharedPreferenceUtils.setSecureValue(
        _activeCallKey,
        jsonEncode({
          'conversationId': conversationId,
          'callId': callId,
          'roomId': roomId,
          'isVideo': isVideo,
          'remoteName': remoteName,
          'startedAtMs': startedAtMs,
          // The other party's user id. Lets the chat screen match an ongoing
          // call even when conversationId is missing on the receiver side (the
          // incoming-call payload doesn't always carry it).
          'remoteUserId': remoteUserId,
        }),
      );
    } catch (_) {}
  }

  /// Clear the ongoing-call record. Called on teardown from [_cleanupInternal].
  static Future<void> clearActiveCallSession() async {
    try {
      await SharedPreferenceUtils.setSecureValue(_activeCallKey, '');
    } catch (_) {}
  }

  /// Read the ongoing-call record, or null if no call is currently active.
  static Future<Map<String, dynamic>?> readActiveCallSession() async {
    try {
      final raw = await SharedPreferenceUtils.getSecureValue(_activeCallKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ==================== WEBRTC SIGNALING ====================

  void _handleRemoteOffer(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    _remoteUserId = fromUserId;
    // print('[CALL_DEBUG] _handleRemoteOffer → from=$fromUserId, currentStatus=${callStatus.value}');
    // print('[FARE_CALL_DEBUG] _handleRemoteOffer → isFareCall=${isFareCall.value}, isCaller=${isCaller.value}, roomId=${roomId.value}');

    // If still ringing or in the middle of accepting, store the offer
    if (callStatus.value == CallStatus.ringing ||
        callStatus.value == CallStatus.accepting) {
      _pendingOffer = data['sdp'];
      print('[CALL_DEBUG] _handleRemoteOffer → stored as pendingOffer (still ${callStatus.value})');
      return;
    }

    // Fare-call customer still `outgoing`: the rider's offer arriving IS the
    // acceptance — the rider only offers after its /call/accept succeeded.
    // Normally call:accepted flips us to connecting first, but that event can
    // be missed (listener re-bind race, event ordering). Dropping the offer
    // here deadlocked the call: rider retried 3×, customer ignored all of
    // them, ring timer expired at 30s. Treat it as the accept instead.
    if (isFareCall.value && callStatus.value == CallStatus.outgoing) {
      print('[FARE_CALL] _handleRemoteOffer → offer while outgoing: treating as implicit call:accepted');
      _ringTimer?.cancel();
      stopOutgoingRingback();
      callStatus.value = CallStatus.connecting;
      // Fall through to normal offer processing below (sets remote
      // description and answers). _handleCallAccepted arriving later is a
      // no-op — its `!= outgoing` guard skips it.
    }

    // Only process if we're in connecting/connected state
    if (callStatus.value != CallStatus.connecting &&
        callStatus.value != CallStatus.connected) {
      // print('[CALL_DEBUG] _handleRemoteOffer → SKIPPED (status=${callStatus.value})');
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → ⚠️ OFFER DROPPED! This may cause fare-call connection failure');
      return;
    }

    // Wait for local media to be ready before creating peer connection
    // (offer can arrive while _setupLocalMedia is still running)
    if (_mediaReadyCompleter != null && !_mediaReadyCompleter!.isCompleted) {
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → waiting for media to be ready...');
      try {
        await _mediaReadyCompleter!.future;
        // print('[FARE_CALL_DEBUG] _handleRemoteOffer → media ready, proceeding');
      } catch (e) {
        // print('[FARE_CALL_DEBUG] _handleRemoteOffer → media setup failed: $e');
        return;
      }
    }

    // print('[FARE_CALL_DEBUG] _handleRemoteOffer → existing peerConnections=${peerConnections.keys.toList()}, localStream=${localStream != null ? "EXISTS" : "NULL"}');
    var pc =
        peerConnections[fromUserId] ?? await _createPeerConnection(fromUserId);

    final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);

    // Handle offer glare: if we already sent an offer (have-local-offer),
    // we have a conflict. Android native WebRTC does NOT support rollback
    // (setLocalDescription with null SDP causes a native crash).
    // Use caller/callee rule: caller keeps their offer, callee yields.
    // print('[FARE_CALL_DEBUG] _handleRemoteOffer → signalingState=${pc.signalingState} before setRemoteDescription');
    if (pc.signalingState ==
        RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      if (isCaller.value) {
        // We're the caller — our offer takes priority. Ignore the remote
        // offer, but RE-SEND our own. The remote side likely sent its offer
        // because it never received ours (its socket joined the room after
        // we emitted). Without re-sending, both sides deadlock waiting for
        // an answer that never comes — call stays in `connecting` until
        // the 30s timeout fires.
        // print('[FARE_CALL_DEBUG] _handleRemoteOffer → OFFER GLARE: we are caller, ignoring remote offer and re-sending ours');
        try {
          final localDesc = await pc.getLocalDescription();
          if (localDesc != null) {
            _socket.emitEvent('call:offer', {
              'room_id': roomId.value,
              'target_user_id': fromUserId,
              'sdp': {'sdp': localDesc.sdp, 'type': localDesc.type},
            });
            // print('[FARE_CALL_DEBUG] _handleRemoteOffer → re-sent our offer to $fromUserId');
          }
        } catch (e) {
          // print('[FARE_CALL_DEBUG] _handleRemoteOffer → re-send error: $e');
        }
        return;
      }
      // We're the callee — drop our offer by closing and recreating the peer connection.
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → OFFER GLARE: we are callee, recreating peer to accept remote offer');
      await _closePeerConnection(fromUserId);
      pc = await _createPeerConnection(fromUserId);
    }

    try {
      await pc.setRemoteDescription(sdp);
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → remote description SET successfully');
    } catch (e) {
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → ❌ setRemoteDescription FAILED: $e');
      return;
    }

    // Flush buffered ICE candidates
    // print('[FARE_CALL_DEBUG] _handleRemoteOffer → flushing $pendingCount pending ICE candidates');
    await _flushPendingCandidates(fromUserId);

    // Create and send answer
    try {
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → answer created, SDP length=${answer.sdp?.length}');

      _socket.emitEvent('call:answer', {
        'room_id': roomId.value,
        'target_user_id': fromUserId,
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
        // Required for the server to emit `connected` back to the caller via
        // `call:ringing`. Without it, the caller stays on `connecting`.
        'call_id': callId.value,
      });
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → answer emitted to $fromUserId');
    } catch (e) {
      // print('[FARE_CALL_DEBUG] _handleRemoteOffer → ❌ ANSWER CREATION FAILED: $e');
    }
  }

  void _handleRemoteAnswer(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    print('[CALL_DEBUG] _handleRemoteAnswer → from=$fromUserId');
    print('[FARE_CALL_DEBUG] _handleRemoteAnswer → isFareCall=${isFareCall.value}, callStatus=${callStatus.value}');
    final pc = peerConnections[fromUserId];
    if (pc == null) {
      print('[CALL_DEBUG] _handleRemoteAnswer → NO peer connection for $fromUserId, SKIPPED');
      print('[FARE_CALL_DEBUG] _handleRemoteAnswer → available peerConnections=${peerConnections.keys.toList()}');
      return;
    }

    print('[CALL_DEBUG] _handleRemoteAnswer → signalingState=${pc.signalingState}');
    // Only set remote description if we're in 'have-local-offer' state
    if (pc.signalingState !=
        RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      print('[CALL_DEBUG] _handleRemoteAnswer → SKIPPED (not in have-local-offer state)');
      print('[FARE_CALL_DEBUG] _handleRemoteAnswer → ⚠️ ANSWER DROPPED for fare-call! signalingState=${pc.signalingState}');
      return;
    }

    try {
      final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
      await pc.setRemoteDescription(sdp);
      print('[CALL_DEBUG] _handleRemoteAnswer → remote description set');
      print('[FARE_CALL_DEBUG] _handleRemoteAnswer → remote description SET successfully, connectionState=${pc.connectionState}');
    } catch (e) {
      print('[FARE_CALL_DEBUG] _handleRemoteAnswer → ❌ setRemoteDescription FAILED: $e');
      return;
    }

    // Flush buffered ICE candidates
    final pendingCount = _pendingCandidates[fromUserId]?.length ?? 0;
    print('[FARE_CALL_DEBUG] _handleRemoteAnswer → flushing $pendingCount pending ICE candidates');
    await _flushPendingCandidates(fromUserId);
    print('[CALL_DEBUG] _handleRemoteAnswer → ICE candidates flushed, waiting for connection...');
  }

  void _handleRemoteIceCandidate(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    final candidateMap = data['candidate'];
    if (candidateMap == null) {
      // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → candidateMap is NULL, skipping');
      return;
    }

    // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → from=$fromUserId, candidate=${candidateStr.toString().substring(0, candidateStr.toString().length > 60 ? 60 : candidateStr.toString().length)}...');

    final candidate = RTCIceCandidate(
      candidateMap['candidate'],
      candidateMap['sdpMid'],
      candidateMap['sdpMLineIndex'],
    );

    final pc = peerConnections[fromUserId];
    if (pc != null) {
      // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → pc found, signalingState=${pc.signalingState}, connectionState=${pc.connectionState}');
      try {
        await pc.addCandidate(candidate);
        // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → candidate added successfully');
      } catch (e) {
        // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → addCandidate failed ($e), buffering. Buffered count=${(_pendingCandidates[fromUserId]?.length ?? 0) + 1}');
        // Buffer until remote description is set
        _pendingCandidates.putIfAbsent(fromUserId, () => []);
        _pendingCandidates[fromUserId]!.add(candidate);
        return;
      }
    } else {
      // print('[FARE_CALL_DEBUG] _handleRemoteIceCandidate → NO peer connection for $fromUserId, buffering. Available peers=${peerConnections.keys.toList()}');
      // Buffer until remote description is set
      _pendingCandidates.putIfAbsent(fromUserId, () => []);
      _pendingCandidates[fromUserId]!.add(candidate);
    }
  }

  Future<void> _flushPendingCandidates(String peerId) async {
    final candidates = _pendingCandidates.remove(peerId);
    if (candidates == null) return;
    final pc = peerConnections[peerId];
    if (pc == null) return;
    for (final c in candidates) {
      await pc.addCandidate(c);
    }
  }

  // ==================== GROUP CALL HANDLERS ====================

  void _handleParticipantJoined(dynamic data) async {
    final newUserId = data['user_id'] ?? '';
    if (newUserId.isEmpty || newUserId == userId) return;

    final pc = await _createPeerConnection(newUserId);

    // Existing participant creates offer for new participant
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _socket.emitEvent('call:offer', {
      'room_id': roomId.value,
      'target_user_id': newUserId,
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  void _handleParticipantLeft(dynamic data) async {
    final leftUserId = data['user_id'] ?? '';
    participantMediaState.remove(leftUserId);
    participantMediaState.refresh();
    await _closePeerConnection(leftUserId);
  }

  void _handleUserAdded(dynamic data) {
    // Informational: another participant added user(s) to the call
    final addedUsers = List<String>.from(data['added_users'] ?? []);
    if (addedUsers.isNotEmpty) {
      isGroupCall.value = true;
    }
  }

  /// Add user(s) to the current active call
  Future<Map<String, dynamic>?> addUsersToCall(List<String> userIds) async {
    if (callId.value.isEmpty || roomId.value.isEmpty) return null;

    ResponseModel response = await _callRepo.addUserToCall({
      'call_id': callId.value,
      'room_id': roomId.value,
      'user_ids': userIds,
    });

    if (!response.isSuccess) {
      commonSnackBar(message: response.message ?? AppStrings.failedToAddUsers.tr);
      return null;
    }

    final data = response.response?.data;
    if (data == null) return null;

    // Upgrade local state to group call
    isGroupCall.value = true;

    final addedUsers = List<String>.from(data['added_users'] ?? []);
    final busyUsers = List<String>.from(data['busy_users'] ?? []);
    final alreadyInCall = List<String>.from(data['already_in_call'] ?? []);

    if (busyUsers.isNotEmpty) {
      commonSnackBar(
          message: '${busyUsers.length} ${AppStrings.usersOnAnotherCall.tr}');
    }
    if (addedUsers.isNotEmpty) {
      commonSnackBar(message: '${addedUsers.length} ${AppStrings.usersAddedToCall.tr}');
    }
    if (addedUsers.isEmpty && busyUsers.isEmpty && alreadyInCall.isNotEmpty) {
      commonSnackBar(message: AppStrings.usersAlreadyInCall.tr);
    }

    return data;
  }

  // ==================== CALL TYPE SWITCH (Audio ↔ Video) ====================

  /// Request to switch call type (audio ↔ video)
  Future<void> switchCallType() async {
    if (callId.value.isEmpty || roomId.value.isEmpty) return;

    final currentType =
        callType.value == CallType.video ? 'video_call' : 'audio_call';
    final newType = currentType == 'audio_call' ? 'video_call' : 'audio_call';

    // If switching to video, request camera permission first
    if (newType == 'video_call') {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        commonSnackBar(
            message: AppStrings.cameraPermissionRequiredToSwitch.tr);
        return;
      }
    }

    ResponseModel response = await _callRepo.switchCallType({
      'call_id': callId.value,
      'room_id': roomId.value,
      'new_call_type': newType,
    });

    if (!response.isSuccess) {
      commonSnackBar(message: response.message ?? AppStrings.failedToSwitchCallType.tr);
      return;
    }

    final data = response.response?.data;
    if (data?['pending_approval'] == true) {
      // Audio → video: waiting for other participants to accept
      isSwitchTypePending.value = true;
      commonSnackBar(message: AppStrings.waitingForApprovalToSwitchVideo.tr);
    }
    // Video → audio: call:type-switched will fire immediately from server
  }

  /// Respond to a switch type request (accept/decline)
  Future<void> respondToSwitchType(bool accepted) async {
    if (callId.value.isEmpty || roomId.value.isEmpty) return;

    // If accepting, request camera permission first
    if (accepted) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        // Auto-decline if can't get camera permission
        accepted = false;
      }
    }

    await _callRepo.respondToSwitchType({
      'call_id': callId.value,
      'room_id': roomId.value,
      'accepted': accepted,
    });

    switchTypeRequestedBy.value = '';
  }

  void _handleSwitchTypeRequest(dynamic data) {
    final requestedBy = data['requested_by'] ?? '';
    switchTypeRequestedBy.value = requestedBy;

    // Show dialog to accept/decline (handled by UI via observable)
    // The ActiveCallScreen watches switchTypeRequestedBy
  }

  void _handleTypeSwitched(dynamic data) {
    final newType = data['new_call_type'] ?? '';
    final isVideo = newType == 'video_call';

    isSwitchTypePending.value = false;
    switchTypeRequestedBy.value = '';

    callType.value = isVideo ? CallType.video : CallType.audio;

    // A type switch renegotiates and can hand the peer connection a fresh set
    // of senders; without this, a muted mic came back live on the far end.
    if (!isMicOn.value) _applyMicEnabled(false);

    if (isVideo) {
      // Enable local video - add video track if not present
      _enableLocalVideo();
      // Switching to video moves to speaker — unless a headset is connected,
      // in which case keep audio on that device (native behaviour).
      if (!isBluetoothAvailable && !isWiredHeadsetAvailable) {
        selectAudioRoute(AudioRoute.speaker);
      }
    } else {
      // Disable camera
      localStream?.getVideoTracks().forEach((track) => track.enabled = false);
      isCameraOn.value = false;
      // Drop back to the earpiece on audio, unless a headset is in use.
      if (currentAudioRoute.value == AudioRoute.speaker) {
        selectAudioRoute(
            isBluetoothAvailable ? AudioRoute.bluetooth : AudioRoute.earpiece);
      }
    }
  }

  void _handleSwitchTypeDeclined(dynamic data) {
    isSwitchTypePending.value = false;
    commonSnackBar(message: AppStrings.switchToVideoDeclined.tr);
  }

  /// Make sure a local video renderer exists and is initialised.
  ///
  /// [_setupLocalMedia] only builds one when the call STARTS as video, so on an
  /// audio → video switch `localRenderer` was still null. `_enableLocalVideo`
  /// then did `localRenderer?.srcObject = ...` — a null-safe no-op — so the
  /// camera was capturing and sending, but nothing rendered it: the local
  /// preview stayed black after the switch was approved.
  Future<void> _ensureLocalRenderer() async {
    if (localRenderer != null) return;
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    localRenderer = renderer;
  }

  /// Enable local video track (for audio → video switch)
  Future<void> _enableLocalVideo() async {
    await _ensureLocalRenderer();

    // Check if we already have a video track
    final existingVideoTracks = localStream?.getVideoTracks() ?? [];
    if (existingVideoTracks.isNotEmpty) {
      // Just enable the existing track
      for (var track in existingVideoTracks) {
        track.enabled = true;
      }
      localRenderer?.srcObject = localStream;
      isCameraOn.value = true;
      return;
    }

    // No video track exists - get a new stream with video
    try {
      final videoStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {'facingMode': 'user', 'width': 640, 'height': 480},
      });

      final videoTrack = videoStream.getVideoTracks().first;

      // Add track to local stream
      localStream?.addTrack(videoTrack);
      localRenderer?.srcObject = localStream;

      // Add track to all peer connections
      for (final pc in peerConnections.values) {
        await pc.addTrack(videoTrack, localStream!);
      }

      isCameraOn.value = true;
      // addTrack changes the sender set — re-assert mute over it.
      if (!isMicOn.value) await _applyMicEnabled(false);

      // Adding a track to an established peer connection needs a NEW
      // offer/answer round before the far end will receive it. Nothing did
      // that: there is no onRenegotiationNeeded handler anywhere in this
      // controller, so after an approved audio → video switch the camera was
      // capturing locally but the remote peer never got a video m-line — both
      // sides sat on a black screen.
      await _renegotiateAfterMediaChange();
    } catch (e) {
      if (kDebugMode) print('Failed to enable video: $e');
      commonSnackBar(message: AppStrings.failedToEnableCamera.tr);
    }
  }

  /// Re-offer after the local track set changed mid-call (audio → video).
  ///
  /// Only ONE side may re-offer or the two offers collide (glare). The original
  /// caller is the deterministic choice — both ends already know who that is
  /// from `isCaller`, so no extra signalling is needed to agree on it. The
  /// callee's newly added video track still reaches the caller, because it is
  /// included in the ANSWER it sends back to this offer.
  ///
  /// The short delay lets both sides finish adding their track before the offer
  /// is built — both run `_enableLocalVideo` off the same `call:type-switched`
  /// event, so an immediate offer can race the callee's addTrack and produce a
  /// one-way video call.
  Future<void> _renegotiateAfterMediaChange() async {
    if (!isCaller.value) return;
    final peerId = _remoteUserId;
    if (peerId == null || peerId.isEmpty) return;
    final pc = peerConnections[peerId];
    if (pc == null) return;

    await Future.delayed(const Duration(milliseconds: 600));
    if (callStatus.value != CallStatus.connected) return;

    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _socket.emitEvent('call:offer', {
        'room_id': roomId.value,
        'target_user_id': peerId,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
      if (kDebugMode) print('_renegotiateAfterMediaChange: re-offer sent');
    } catch (e) {
      if (kDebugMode) print('_renegotiateAfterMediaChange failed: $e');
    }
  }

  /// Join an ongoing group call
  Future<bool> joinGroupCall({
    required String existingCallId,
    required String existingRoomId,
  }) async {
    await [Permission.microphone, Permission.camera].request();

    ResponseModel response = await _callRepo.joinCall({
      'call_id': existingCallId,
      'room_id': existingRoomId,
    });

    if (!response.isSuccess) {
      commonSnackBar(message: response.message ?? AppStrings.failedToJoinCall.tr);
      return false;
    }

    final data = response.response?.data;
    _iceConfig = IceServerConfig.fromJson(data?['ice_servers'] ?? {});
    callId.value = existingCallId;
    roomId.value = existingRoomId;
    isGroupCall.value = true;
    callStatus.value = CallStatus.connecting;

    _socket.emitEvent('call:join-room', {'room_id': roomId.value});
    await _setupLocalMedia();
    WakelockPlus.enable();

    return true;
  }

  // ==================== WEBRTC SETUP ====================

  Future<void> _setupLocalMedia() async {
    final isVideo = callType.value == CallType.video;
    print('[FARE_CALL_DEBUG] _setupLocalMedia → START, isVideo=$isVideo, isFareCall=${isFareCall.value}');

    // Sync isCameraOn with actual media state (fixes video:true on audio calls)
    isCameraOn.value = isVideo;

    // Put Android into voice-communication audio mode (MODE_IN_COMMUNICATION,
    // STREAM_VOICE_CALL). Without this the OS leaves the call in the normal
    // media mode, so the hardware volume up/down buttons adjust the media/ring
    // stream instead of the live call audio — i.e. they appear "dead" on
    // earpiece, speaker and Bluetooth alike. Setting it routes the volume
    // rocker to the in-call voice stream so users can raise/lower call volume.
    await _enableCommunicationAudioMode();

    // Start intercepting the hardware volume buttons so they drive the WebRTC
    // software gain. This is what makes volume adjustable on Bluetooth/CarPlay,
    // where the OS call-stream volume is locked by the accessory.
    await _setVolumeInterceptActive(true);

    try {
      // Only create video renderer for video calls
      if (isVideo) {
        localRenderer = RTCVideoRenderer();
        await localRenderer!.initialize();
      }

      print('[FARE_CALL_DEBUG] _setupLocalMedia → calling getUserMedia...');
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });
      print('[FARE_CALL_DEBUG] _setupLocalMedia → getUserMedia SUCCESS, tracks=${localStream?.getTracks().length}, audioTracks=${localStream?.getAudioTracks().length}');
      hasLocalAudio.value =
          (localStream?.getAudioTracks().isNotEmpty ?? false);

      if (isVideo && localRenderer != null) {
        localRenderer!.srcObject = localStream;
      }
    } catch (e, stack) {
      print('[FARE_CALL_DEBUG] _setupLocalMedia → ❌ getUserMedia FAILED: $e');
      print('_setupLocalMedia error: $e');
      print(stack.toString());
      if (_mediaReadyCompleter != null && !_mediaReadyCompleter!.isCompleted) {
        _mediaReadyCompleter!.completeError(e);
      }
      rethrow;
    }

    // Start live audio-device monitoring and apply the initial route
    // (prefers a connected Bluetooth/wired headset, else speaker for video /
    // earpiece for voice — same defaults as before).
    await _startAudioRouteMonitoring(isVideo: isVideo);
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    if (peerConnections.containsKey(peerId)) {
      print('[FARE_CALL_DEBUG] _createPeerConnection → reusing existing PC for $peerId');
      return peerConnections[peerId]!;
    }

    final config = _iceConfig?.toWebRTCConfig() ??
        {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'}
          ]
        };
    print('[FARE_CALL_DEBUG] _createPeerConnection → creating NEW PC for $peerId, iceServers count=${(config['iceServers'] as List?)?.length ?? 0}, localStream=${localStream != null ? "EXISTS (tracks=${localStream!.getTracks().length})" : "NULL"}');

    final pc = await createPeerConnection(config, {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
    });

    // Add local tracks
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        await pc.addTrack(track, localStream!);
      }
    }

    // ICE candidate handler
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      print('[CALL_DEBUG] onIceCandidate → sending to $peerId');
      _socket.emitEvent('call:ice-candidate', {
        'room_id': roomId.value,
        'target_user_id': peerId,
        'candidate': candidate.toMap(),
      });
    };

    // Remote stream handler
    pc.onTrack = (RTCTrackEvent event) {
      print('[CALL_DEBUG] onTrack → received from $peerId, streams=${event.streams.length}, track=${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _handleRemoteStream(peerId, event.streams[0]);
      }
    };

    // ICE connection state (more granular than connection state)
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      print('[CALL_DEBUG] onIceConnectionState → $state (peer=$peerId)');
      if (_disposed) return;
      // Fallback for ALL platforms: flutter_webrtc's `onConnectionState` is
      // unreliable on iOS (often never reports Connected) and has been seen
      // missing on some Android devices too — either way the UI stays stuck
      // on "Connecting" even though ICE has succeeded and audio is flowing.
      // ICE Connected/Completed means the transport is genuinely up, so
      // drive the connected transition off ICE state as well. Idempotent
      // where onConnectionState already fired first.
      if ((state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
              state == RTCIceConnectionState.RTCIceConnectionStateCompleted) &&
          callStatus.value != CallStatus.connected) {
        print('[CALL_DEBUG] ✅ promoting to connected via ICE state (peer=$peerId)');
        _connectionTimer?.cancel();
        _peerDisconnectTimer?.cancel();
        _ringTimer?.cancel();
        _offerRetryTimer?.cancel();
        callStatus.value = CallStatus.connected;
        _startCallTimer();
        _cancelNetworkGrace();
      }
    };

    // Signaling state
    pc.onSignalingState = (RTCSignalingState state) {
      print('[CALL_DEBUG] onSignalingState → $state (peer=$peerId)');
    };

    // Connection state
    pc.onConnectionState = (RTCPeerConnectionState state) {
      print('[CALL_DEBUG] onConnectionState → $state (peer=$peerId)');
      if (_disposed) return;
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('[CALL_DEBUG] ✅ CALL CONNECTED! peer=$peerId');
          _connectionTimer?.cancel();
          _peerDisconnectTimer?.cancel();
          _ringTimer?.cancel();
          _offerRetryTimer?.cancel();
          callStatus.value = CallStatus.connected;
          _startCallTimer();
          _cancelNetworkGrace();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print('[CALL_DEBUG] ❌ CALL FAILED! peer=$peerId');
          endCall();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          // ICE `disconnected` is recoverable, so this does NOT end the call
          // outright — but it used to do nothing at all, which is how the far
          // end was left in a ghost call when the other side lost internet:
          // no audio, timer still counting, no way to know. Give it the same
          // grace window as a local drop, then tear down.
          print('[CALL_DEBUG] ⚠️ PEER DISCONNECTED (may reconnect), peer=$peerId');
          _onTransportLost('peer disconnected');
          break;
        default:
          break;
      }
    };

    peerConnections[peerId] = pc;
    return pc;
  }

  Future<void> _handleRemoteStream(String peerId, MediaStream stream) async {
    if (!remoteRenderers.containsKey(peerId)) {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      remoteRenderers[peerId] = renderer;
    }
    remoteRenderers[peerId]!.srcObject = stream;
    remoteStreams[peerId] = stream;
    // The track may arrive after the route was already chosen — re-apply the
    // gain so the speaker/earpiece volume matches the current route, and
    // re-assert the route itself in case an engine swap dropped it.
    _applyRouteVolume(currentAudioRoute.value);
    _reassertAudioRoute();
  }

  // ==================== MEDIA CONTROLS ====================

  /// Every local audio track that is actually reaching the far end: the capture
  /// track on [localStream] plus whatever each peer connection's senders hold.
  ///
  /// The old code only touched `localStream.getAudioTracks().first`. That is
  /// the same object as the sender's track in the common case, but not after a
  /// renegotiation or a replaceTrack — and it is null entirely in the main
  /// engine while CallActivity owns the call, which made Mute a silent no-op
  /// that did not even move the button.
  Future<List<MediaStreamTrack>> _localAudioTracks() async {
    final tracks = <MediaStreamTrack>[];
    final seen = <String>{};

    void add(MediaStreamTrack? track) {
      if (track == null || track.kind != 'audio') return;
      final id = track.id ?? '';
      if (id.isNotEmpty && !seen.add(id)) return;
      tracks.add(track);
    }

    for (final track in localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      add(track);
    }
    for (final pc in peerConnections.values) {
      try {
        for (final sender in await pc.getSenders()) {
          add(sender.track);
        }
      } catch (e) {
        if (kDebugMode) print('_localAudioTracks: getSenders failed: $e');
      }
    }
    return tracks;
  }

  /// Force every outgoing audio track to [enabled] and tell the peer. Used by
  /// [toggleMic] and re-run whenever the track set can have changed underneath
  /// us (connect, audio↔video switch), so mute survives renegotiation.
  Future<void> _applyMicEnabled(bool enabled) async {
    final tracks = await _localAudioTracks();
    if (tracks.isEmpty) return;
    for (final track in tracks) {
      track.enabled = enabled;
    }
    isMicOn.value = enabled;
    hasLocalAudio.value = true;

    _socket.emitEvent('call:media-toggle', {
      'room_id': roomId.value,
      'is_audio_enabled': enabled,
      'is_video_enabled': isCameraOn.value,
    });
  }

  Future<void> toggleMic() => _applyMicEnabled(!isMicOn.value);

  void toggleCamera() {
    final videoTrack = localStream?.getVideoTracks().firstOrNull;
    if (videoTrack == null) return;
    videoTrack.enabled = !videoTrack.enabled;
    isCameraOn.value = videoTrack.enabled;

    _socket.emitEvent('call:media-toggle', {
      'room_id': roomId.value,
      'is_video_enabled': isCameraOn.value,
      'is_audio_enabled': isMicOn.value,
    });
  }

  void switchCamera() {
    final videoTrack = localStream?.getVideoTracks().firstOrNull;
    if (videoTrack == null) return;
    Helper.switchCamera(videoTrack);
    isFrontCamera.value = !isFrontCamera.value;
  }

  /// Speaker button (round control in the call pill). Toggles between Speaker
  /// and the "natural" sink — a connected Bluetooth headset if there is one,
  /// otherwise the earpiece. Kept for the existing single-button UI.
  void toggleSpeaker() {
    if (currentAudioRoute.value == AudioRoute.speaker) {
      selectAudioRoute(
          isBluetoothAvailable ? AudioRoute.bluetooth : AudioRoute.earpiece);
    } else {
      selectAudioRoute(AudioRoute.speaker);
    }
  }

  /// Bluetooth toggle (legacy entry point, e.g. the "More" sheet switch).
  /// Routes to Bluetooth when available, else falls back to the earpiece.
  Future<void> toggleBluetooth() async {
    if (currentAudioRoute.value == AudioRoute.bluetooth) {
      await selectAudioRoute(AudioRoute.earpiece);
    } else if (isBluetoothAvailable) {
      await selectAudioRoute(AudioRoute.bluetooth);
    } else {
      // No Bluetooth device connected — keep the UI honest.
      isBluetoothOn.value = false;
    }
  }

  /// Route active-call audio to [route] and reflect it in the reactive state.
  /// Works on both Android (Twilio AudioSwitch via the native bridge) and iOS
  /// (AVAudioSession override + category options). Safe to call any time during
  /// a call; ignored for routes that aren't currently available.
  ///
  /// The reactive flags are updated from what the platform reports as ACTIVE,
  /// not from what was requested — see [_applyAudioRoute]. A speaker button
  /// that stays dark is a true "the switch didn't take", which is far better
  /// than one that lights up over earpiece audio.
  Future<void> selectAudioRoute(AudioRoute route) async {
    // Don't let callers pick a device that isn't plugged in.
    if (!availableAudioRoutes.contains(route)) {
      if ((route == AudioRoute.bluetooth && !isBluetoothAvailable) ||
          (route == AudioRoute.wiredHeadset && !isWiredHeadsetAvailable)) {
        return;
      }
    }

    // Remember the intent even if the platform refuses it, so a later
    // re-assert (on connect / resume / remote track) can try again.
    _desiredAudioRoute = route;
    _userPickedSpeaker = route == AudioRoute.speaker;

    final active = await _applyAudioRoute(route);

    currentAudioRoute.value = active;
    // Keep legacy flags in sync so existing UI bindings stay correct.
    isSpeakerOn.value = active == AudioRoute.speaker;
    isBluetoothOn.value = active == AudioRoute.bluetooth;

    // Boost the remote playback gain on the loudspeaker (phone held away from
    // the ear) and keep it low on the earpiece / headsets (held close to the
    // ear) so neither is uncomfortable.
    _applyRouteVolume(active);
  }

  /// Push [route] down to the platform and report which route is genuinely
  /// active afterwards.
  ///
  /// On Android this goes through [CallAudioRouteService], which re-activates
  /// flutter_webrtc's shared AudioSwitchManager before selecting and then reads
  /// the selection back. That re-activation is the whole point: another engine
  /// attaching mid-call (FCM background isolate, overlay window, MainActivity
  /// restart) replaces the singleton with one that was never activated, and
  /// every subsequent `selectAudioOutput` is silently dropped.
  ///
  /// Falls back to [Helper.selectAudioOutput] and optimism when the bridge
  /// can't report a route, so behaviour never regresses below the old code.
  Future<AudioRoute> _applyAudioRoute(AudioRoute route) async {
    try {
      if (Platform.isAndroid) {
        final activeName = await CallAudioRouteService.selectOutput(
          route.typeName,
        );
        final active = AudioRouteUi.fromTypeName(activeName);
        if (active != null) {
          if (active != route && kDebugMode) {
            print('_applyAudioRoute: asked for $route, got $active');
          }
          return active;
        }
        // Bridge unavailable (older build / plugin internals moved) — fall back
        // to the plugin's own path and assume it landed.
        await Helper.selectAudioOutput(route.typeName);
      } else if (Platform.isIOS) {
        await _applyIosRoute(route);
      }
    } catch (e) {
      if (kDebugMode) print('_applyAudioRoute($route) failed: $e');
    }
    return route;
  }

  /// Re-push the user's chosen route to the platform without changing their
  /// intent. Cheap and idempotent, so it can be fired at every point where
  /// another Flutter engine may have swapped the audio manager out from under
  /// the live call: connect, remote track arrival, and app resume.
  Future<void> _reassertAudioRoute() async {
    if (!Platform.isAndroid) return;
    final status = callStatus.value;
    if (status == CallStatus.idle || status == CallStatus.ended) return;
    final route = _desiredAudioRoute ?? currentAudioRoute.value;
    final active = await _applyAudioRoute(route);
    if (active != currentAudioRoute.value) {
      currentAudioRoute.value = active;
      isSpeakerOn.value = active == AudioRoute.speaker;
      isBluetoothOn.value = active == AudioRoute.bluetooth;
      _applyRouteVolume(active);
    }
  }

  /// Switch the Android audio session into voice-communication mode so the
  /// hardware volume buttons control the live call (STREAM_VOICE_CALL) instead
  /// of the media stream. No-op on iOS, where AVAudioSession already maps the
  /// volume rocker to the call while the playAndRecord category is active.
  Future<void> _enableCommunicationAudioMode() async {
    if (!Platform.isAndroid) return;
    try {
      await Helper.setAndroidAudioConfiguration(
        AndroidAudioConfiguration.communication,
      );
    } catch (e) {
      if (kDebugMode) print('_enableCommunicationAudioMode failed: $e');
    }
  }

  /// Restore the Android audio session to the normal media mode after the call
  /// ends, releasing the in-call volume routing and audio focus.
  Future<void> _restoreMediaAudioMode() async {
    if (!Platform.isAndroid) return;
    try {
      await Helper.setAndroidAudioConfiguration(
        AndroidAudioConfiguration.media,
      );
      await Helper.clearAndroidCommunicationDevice();
    } catch (e) {
      if (kDebugMode) print('_restoreMediaAudioMode failed: $e');
    }
  }

  /// Maximum WebRTC remote-audio gain (0–10, 1.0 = normal) for each route,
  /// reached when [callVolumeLevel] is 1.0. The loudspeaker is across the room
  /// so it gets the biggest headroom; the earpiece sits on the ear so it stays
  /// quiet. Bluetooth / wired headsets land in between. The effective gain is
  /// this value scaled by the user's volume level, so the hardware volume
  /// buttons can raise/lower every route.
  double _routeMaxGain(AudioRoute route) {
    switch (route) {
      case AudioRoute.speaker:
        return 10.0;
      case AudioRoute.bluetooth:
        return 8.0;
      case AudioRoute.wiredHeadset:
        return 6.0;
      case AudioRoute.earpiece:
        return 2.0;
    }
  }

  /// Apply the per-route playback gain (route ceiling × user volume level) to
  /// every remote audio track.
  void _applyRouteVolume(AudioRoute route) {
    final volume =
        (_routeMaxGain(route) * callVolumeLevel.value).clamp(0.0, 10.0);
    for (final stream in remoteStreams.values) {
      for (final track in stream.getAudioTracks()) {
        try {
          Helper.setVolume(volume, track);
        } catch (e) {
          if (kDebugMode) print('_applyRouteVolume failed: $e');
        }
      }
    }
  }

  // ==================== HARDWARE VOLUME BUTTONS ====================

  /// Wire the native volume-key bridge. The host Activity intercepts the
  /// hardware volume rocker during a call and forwards `up`/`down` here; we map
  /// it to a WebRTC software gain so the call volume is adjustable on every
  /// output, including Bluetooth/CarPlay devices that lock the OS stream volume.
  void _setupVolumeKeyChannel() {
    if (!Platform.isAndroid) return;
    _volumeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onVolumeKey') {
        _onHardwareVolumeKey(call.arguments == 'up');
      }
      return null;
    });
  }

  /// Apply (or drop) the window behaviour a call needs from the host Activity:
  /// visible over the lock screen, screen turned on for an incoming ring, no
  /// screen timeout, and Home shrinking the call into PiP.
  ///
  /// The old CallActivity got all of this from its manifest entry. MainActivity
  /// cannot — that would apply it to the whole app — so it is scoped to the
  /// duration of a call. Deduped because callStatus moves through several
  /// states per call and each transition would otherwise hit the channel.
  void _setCallWindowActive(bool active) {
    if (!Platform.isAndroid) return;
    if (_callWindowActive == active) return;
    _callWindowActive = active;
    CallWindowService.setCallWindowActive(active);
  }

  /// Start/stop native interception of the hardware volume rocker. While active
  /// the Activity consumes volume up/down and routes them to [_onHardwareVolumeKey]
  /// instead of letting the OS adjust the (Bluetooth-locked) call stream.
  Future<void> _setVolumeInterceptActive(bool active) async {
    if (!Platform.isAndroid) return;
    if (_volumeInterceptActive == active) return;
    _volumeInterceptActive = active;
    try {
      await _volumeChannel
          .invokeMethod('setCallVolumeActive', {'active': active});
    } catch (e) {
      if (kDebugMode) print('_setVolumeInterceptActive failed: $e');
    }
  }

  /// Handle a hardware volume up/down press: step the level and re-apply gain.
  void _onHardwareVolumeKey(bool up) {
    final next =
        (callVolumeLevel.value + (up ? _volumeStep : -_volumeStep)).clamp(0.0, 1.0);
    if (next == callVolumeLevel.value) return;
    callVolumeLevel.value = next;
    _applyRouteVolume(currentAudioRoute.value);
  }

  /// iOS routing. The AVAudioSession picks the physical port; we only steer it
  /// via the speaker override and the category's Bluetooth options.
  Future<void> _applyIosRoute(AudioRoute route) async {
    switch (route) {
      case AudioRoute.speaker:
        await Helper.setAppleAudioConfiguration(AppleAudioConfiguration(
          appleAudioCategory: AppleAudioCategory.playAndRecord,
          appleAudioCategoryOptions: {
            AppleAudioCategoryOption.allowBluetooth,
            AppleAudioCategoryOption.allowBluetoothA2DP,
            AppleAudioCategoryOption.defaultToSpeaker,
          },
          appleAudioMode: AppleAudioMode.voiceChat,
        ));
        await Helper.setSpeakerphoneOn(true);
        break;
      case AudioRoute.earpiece:
        // No Bluetooth option ⇒ iOS won't auto-route to a BT device, forcing
        // the built-in receiver even when a headset is paired.
        await Helper.setSpeakerphoneOn(false);
        await Helper.setAppleAudioConfiguration(AppleAudioConfiguration(
          appleAudioCategory: AppleAudioCategory.playAndRecord,
          appleAudioCategoryOptions: {},
          appleAudioMode: AppleAudioMode.voiceChat,
        ));
        break;
      case AudioRoute.bluetooth:
      case AudioRoute.wiredHeadset:
        // Clearing the speaker override lets the session route to the connected
        // accessory (allowed via the options below).
        await Helper.setSpeakerphoneOn(false);
        await Helper.setAppleAudioConfiguration(AppleAudioConfiguration(
          appleAudioCategory: AppleAudioCategory.playAndRecord,
          appleAudioCategoryOptions: {
            AppleAudioCategoryOption.allowBluetooth,
            AppleAudioCategoryOption.allowBluetoothA2DP,
          },
          appleAudioMode: AppleAudioMode.voiceChat,
        ));
        break;
    }
  }

  // ── Real-time audio device detection ────────────────────────────────────

  /// Begin watching for audio-device connect/disconnect events for the active
  /// call and apply the initial route. Idempotent — safe to call per call setup.
  Future<void> _startAudioRouteMonitoring({required bool isVideo}) async {
    // Bluetooth routing/detection needs BLUETOOTH_CONNECT at runtime on
    // Android 12+. Request it non-blockingly — the call proceeds regardless
    // (BT is optional), and a grant simply unlocks BT routing.
    await _ensureBluetoothPermission();
    if (!_audioMonitoringActive) {
      _audioMonitoringActive = true;
      // Fired by the native layer on BT/wired/route changes (Android & iOS).
      navigator.mediaDevices.ondevicechange = (_) => _refreshAudioRoutes();
    }
    _userPickedSpeaker = isVideo; // video calls open on speaker by default
    await _refreshAudioRoutes(initial: true, initialIsVideo: isVideo);
  }

  /// Request BLUETOOTH_CONNECT on Android (no-op elsewhere). Never throws and
  /// never blocks the call — a denial just means BT routing stays unavailable.
  Future<void> _ensureBluetoothPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.bluetoothConnect.status;
      if (!status.isGranted && !status.isPermanentlyDenied) {
        await Permission.bluetoothConnect.request();
      }
    } catch (_) {}
  }

  /// Stop watching device changes and reset routing state. Called during call
  /// teardown so the listener never leaks into the next call.
  void _stopAudioRouteMonitoring() {
    if (_audioMonitoringActive) {
      _audioMonitoringActive = false;
      try {
        navigator.mediaDevices.ondevicechange = null;
      } catch (_) {}
    }
    _userPickedSpeaker = false;
    _desiredAudioRoute = null;
    availableAudioRoutes.assignAll([AudioRoute.earpiece, AudioRoute.speaker]);
    currentAudioRoute.value = AudioRoute.earpiece;
    isBluetoothOn.value = false;
  }

  /// Enumerate the current audio outputs, rebuild [availableAudioRoutes], and
  /// (re)apply the appropriate route. Re-runs whenever a device connects or
  /// disconnects so the UI matches native WhatsApp behaviour.
  Future<void> _refreshAudioRoutes(
      {bool initial = false, bool initialIsVideo = false}) async {
    final hadBluetooth = isBluetoothAvailable;
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      bool hasBt = false;
      bool hasWired = false;
      for (final d in devices) {
        // iOS only reports the *current* output via 'audiooutput' but exposes a
        // connected BT/wired headset as an 'audioinput' too — inspect both so
        // detection works on either platform.
        if (d.kind != 'audiooutput' && d.kind != 'audioinput') continue;
        final id = d.deviceId.toLowerCase();
        final label = d.label.toLowerCase();
        if (id == 'bluetooth' || _looksBluetooth(label)) {
          hasBt = true;
        } else if (id == 'wired-headset' || _looksWiredHeadset(label)) {
          hasWired = true;
        }
      }

      final routes = <AudioRoute>[AudioRoute.earpiece, AudioRoute.speaker];
      if (hasBt) routes.add(AudioRoute.bluetooth);
      if (hasWired) routes.add(AudioRoute.wiredHeadset);
      availableAudioRoutes.assignAll(routes);
    } catch (e) {
      if (kDebugMode) print('_refreshAudioRoutes enumerate failed: $e');
    }

    // Decide the route to apply.
    AudioRoute target;
    if (initial) {
      // Prefer an already-connected accessory; otherwise speaker for video,
      // earpiece for voice — matching the previous default behaviour.
      if (isBluetoothAvailable) {
        target = AudioRoute.bluetooth;
      } else if (isWiredHeadsetAvailable) {
        target = AudioRoute.wiredHeadset;
      } else {
        target = initialIsVideo ? AudioRoute.speaker : AudioRoute.earpiece;
      }
    } else {
      final current = currentAudioRoute.value;
      final btJustConnected = !hadBluetooth && isBluetoothAvailable;
      if (btJustConnected && !_userPickedSpeaker) {
        // Auto-route to a newly connected headset, just like native calling.
        target = AudioRoute.bluetooth;
      } else if (!availableAudioRoutes.contains(current)) {
        // The active sink vanished (headset unplugged) — fall back sensibly.
        target = _userPickedSpeaker
            ? AudioRoute.speaker
            : (isBluetoothAvailable
                ? AudioRoute.bluetooth
                : (isWiredHeadsetAvailable
                    ? AudioRoute.wiredHeadset
                    : AudioRoute.earpiece));
      } else {
        // Nothing relevant changed for routing; just refreshed the menu.
        return;
      }
    }
    await selectAudioRoute(target);
  }

  bool _looksBluetooth(String label) {
    if (label.isEmpty) return false;
    return label.contains('bluetooth') ||
        label.contains('airpod') ||
        label.contains('headset') && label.contains('bt') ||
        label.contains('hands-free') ||
        label.contains('handsfree') ||
        label.contains('car');
  }

  bool _looksWiredHeadset(String label) {
    if (label.isEmpty) return false;
    return label.contains('wired') ||
        label.contains('headphone') ||
        label.contains('headphones') ||
        (label.contains('headset') && !_looksBluetooth(label));
  }

  // ==================== CALL HISTORY ====================

  Future<List<CallModel>> getCallHistory({
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    ResponseModel response = await _callRepo.getCallHistory(
      conversationId: conversationId,
      page: page,
      limit: limit,
    );
    if (!response.isSuccess) return [];
    final data = response.response?.data;
    if (data == null || data['calls'] == null) return [];
    return (data['calls'] as List).map((c) => CallModel.fromJson(c)).toList();
  }

  /// GET https://call.beapp.in/call/history?page=$page&limit=$limit
  /// Fetches the global call history (all conversations) for the current user.
  /// Logs the raw response for debugging and returns the parsed list.
  Future<List<CallModel>> fetchCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final ResponseModel response =
        await _callRepo.getCallHistory(page: page, limit: limit);

    print('[CALL_HISTORY] statusCode=${response.statusCode}');
    print('[CALL_HISTORY] response=${response.response?.data}');

    if (!response.isSuccess) return [];
    final dynamic data = response.response?.data;
    if (data is! Map) return [];
    if (data['success'] != true) return [];
    final dynamic calls = data['calls'];
    if (calls is! List) return [];
    return calls
        .whereType<Map>()
        .map((c) => CallModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  // ==================== UTILITY ====================

  String getCallDisplayText(CallModel call, String currentUserId) {
    final bool isOutgoing = call.initiatedBy == currentUserId;
    final String direction = isOutgoing ? 'Outgoing' : 'Incoming';

    // The status values the chat service can now send, per the backend's rev 3
    // §6: the enum gained `network_error` and `busy`. Anything not handled here
    // falls through to a bare "Outgoing call", which is what a dropped call and
    // a busy line both used to read as.
    switch (call.status) {
      case 'ended':
        if (call.endReason == 'missed') {
          return isOutgoing ? 'No answer' : 'Missed call';
        } else if (call.endReason == 'declined') {
          return isOutgoing ? 'Declined' : 'You declined';
        } else if (call.endReason == 'network_error') {
          // The copy we asked for and they shipped — one string on both sides,
          // because a dropped call is nobody's action.
          return 'Call disconnected';
        } else if (call.endReason == 'busy') {
          return isOutgoing ? 'User is busy' : 'You were busy';
        } else {
          return '$direction call - ${_formatDuration(call.durationSeconds)}';
        }
      case 'missed':
        return isOutgoing ? 'No answer' : 'Missed call';
      case 'declined':
        return isOutgoing ? 'Declined' : 'You declined';
      case 'network_error':
        return 'Call disconnected';
      case 'busy':
        return isOutgoing ? 'User is busy' : 'You were busy';
      default:
        return '$direction call';
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedCallDuration =>
      _formatDuration(callDurationSeconds.value);

  /// Wall-clock moment the call connected, in epoch ms. 0 while no call is
  /// connected. The call duration is derived from this rather than counted, so
  /// a throttled or suspended timer cannot lose seconds — see [_startCallTimer].
  int _callConnectedAtMs = 0;

  /// Recompute the visible duration from the connect anchor. Safe to call at
  /// any time; a no-op before the call connects.
  void _syncCallDuration() {
    if (_callConnectedAtMs == 0) return;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - _callConnectedAtMs) ~/ 1000;
    if (elapsed < 0) return; // clock moved backwards — keep the last good value
    if (callDurationSeconds.value != elapsed) {
      callDurationSeconds.value = elapsed;
    }
  }

  void _startCallTimer() {
    // The call is now connected (picked up) — mark it so the end-of-call
    // interstitial fires for this call.
    _wasCallConnected = true;
    // A picked-up call is always reachable from the top strip, even if the
    // call screen never mounted (accepted from the notification / CallKit
    // while the call room push was still racing the app's boot).
    callRoomEverShown.value = true;
    // Setup ran before the peer connection came up; anything that attached a
    // Flutter engine in between could have dropped the route. Re-assert it now
    // that there is actually audio to route, and re-apply the mute state for
    // the same reason (the sender's track may have been swapped in late).
    _reassertAudioRoute();
    if (!isMicOn.value) _applyMicEnabled(false);
    // Preload an interstitial NOW so one is ready by the time the call ends
    // (the call duration gives it ample time to load). initialize() is
    // idempotent + fire-and-forget.
    InterstitialAdManager.instance.initialize();
    _callTimer?.cancel();
    // The duration is derived from a wall-clock anchor, not counted in ticks.
    //
    // A `Timer.periodic` that increments a counter only measures the call
    // correctly while the app is in front of the user: Android throttles (and
    // Doze outright suspends) timers for a backgrounded process, so every
    // skipped tick was a second the call bar, the floating overlay, the ongoing
    // notification and the call-log duration all silently lost. Minimise the
    // call for two minutes and the strip came back reading well under the real
    // elapsed time. Re-deriving from the anchor makes a missed tick cost
    // nothing — the next one that fires shows the true elapsed time.
    _callConnectedAtMs = DateTime.now().millisecondsSinceEpoch;
    callDurationSeconds.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncCallDuration();
      // Update floating overlay timer if active
      OverlayService.updateTimer(formattedCallDuration);
    });
    // Publish an ongoing-call record so the chat screen (a different isolate on
    // Android) can show a "Live call ongoing" banner for this conversation.
    saveActiveCallSession(
      conversationId: conversationId.value,
      callId: callId.value,
      roomId: roomId.value,
      isVideo: callType.value == CallType.video,
      remoteName: remoteUserName.value.isNotEmpty
          ? remoteUserName.value
          : callerName.value,
      // The same anchor the timer runs off, so the chat banner and the call
      // bar can never disagree about when the call started.
      startedAtMs: _callConnectedAtMs,
      remoteUserId: _remoteUserId ?? '',
    );
    // Start the ongoing call notification
    _showOngoingCallNotification();
  }

  void _startRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: 30), () {
      // Only treat this as a no-answer cancel if the call is *still ringing*
      // on the caller side. Any other status (accepting/connecting/connected)
      // means the call is progressing and must NOT be cancelled — otherwise
      // an active call would be flipped into a missed/cancelled state.
      if (callStatus.value == CallStatus.outgoing && isCaller.value) {
        print('[CALL_DEBUG] _startRingTimer → 30s no-answer, cancelling outgoing call');
        cancelCall();
      } else {
        print('[CALL_DEBUG] _startRingTimer → expired but call is ${callStatus.value} (isCaller=${isCaller.value}) — no-op');
      }
    });
  }

  Future<void> _closePeerConnection(String peerId) async {
    try {
      await peerConnections[peerId]?.close();
    } catch (_) {}
    peerConnections.remove(peerId);

    try {
      final renderer = remoteRenderers.remove(peerId);
      if (renderer != null) {
        renderer.srcObject = null;
        await renderer.dispose();
      }
    } catch (_) {}
    remoteStreams.remove(peerId);
    _pendingCandidates.remove(peerId);
  }

  // ==================== ONGOING CALL NOTIFICATION ====================

  /// Get the already-initialized plugin from AppNotificationHandler
  FlutterLocalNotificationsPlugin get _notificationPlugin =>
      AppNotificationHandler.flutterLocalNotificationsPlugin;

  /// Show a notification during connecting phase to keep app in foreground
  Future<void> _showConnectingNotification() async {
    if (Platform.isIOS) return; // CallKit handles the ongoing-call UI natively on iOS
    try {
      final name = callerName.value.isNotEmpty
          ? callerName.value
          : (remoteUserName.value.isNotEmpty
              ? remoteUserName.value
              : 'Connecting');
      final isVideo = callType.value == CallType.video;

      final androidDetails = AndroidNotificationDetails(
        _ongoingChannelId,
        'Ongoing Calls',
        channelDescription: 'Shows when a call is in progress',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        icon: '@drawable/ic_stat',
        category: AndroidNotificationCategory.call,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'hangup_call',
            'Hang Up',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      await _notificationPlugin.show(
        _ongoingNotificationId,
        '${isVideo ? 'Video' : 'Voice'} call with $name',
        'Connecting...',
        NotificationDetails(android: androidDetails),
        payload: '{"action":"open_active_call"}',
      );
    } catch (e) {
      if (kDebugMode) print('Connecting notification error: $e');
    }
  }

  void _showOngoingCallNotification() {
    if (Platform.isIOS) return; // CallKit handles the ongoing-call UI natively on iOS
    _notificationTimer?.cancel();
    // Show immediately, then update every second with call duration
    _updateOngoingNotification();
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateOngoingNotification();
    });
  }

  Future<void> _updateOngoingNotification() async {
    if (Platform.isIOS) return; // CallKit handles the ongoing-call UI natively on iOS
    try {
      final name = callerName.value.isNotEmpty
          ? callerName.value
          : (remoteUserName.value.isNotEmpty
              ? remoteUserName.value
              : 'Unknown');
      final duration = formattedCallDuration;
      final isVideo = callType.value == CallType.video;

      final androidDetails = AndroidNotificationDetails(
        _ongoingChannelId,
        'Ongoing Calls',
        channelDescription: 'Shows when a call is in progress',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        icon: '@drawable/ic_stat',
        category: AndroidNotificationCategory.call,
        usesChronometer: false,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'hangup_call',
            'Hang Up',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      await _notificationPlugin.show(
        _ongoingNotificationId,
        '${isVideo ? 'Video' : 'Voice'} call with $name',
        'Ongoing call · $duration',
        NotificationDetails(android: androidDetails),
        payload: '{"action":"open_active_call"}',
      );
    } catch (e) {
      if (kDebugMode) print('Ongoing notification error: $e');
    }
  }

  Future<void> _cancelOngoingNotification() async {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    try {
      await _notificationPlugin.cancel(_ongoingNotificationId);
    } catch (_) {}
  }

  // ==================== FARE-CALL CUSTOMER WEBRTC ====================

  /// Join the WebRTC call room as the customer for a fare-call.
  /// Mirrors initiateCall() exactly — the only difference is the server
  /// already created the call, so we skip the API call.
  /// Flow: join room → setup media → create peer → wait for call:accepted
  ///       → _handleCallAccepted creates offer → normal SDP exchange.
  Future<bool> joinFareCallAsCustomer({
    required String fareCallId,
    required String fareRoomId,
    required String riderId,
    required String fareConversationId,
    required List<dynamic> iceServers,
  }) async {
    print('[FARE_CALL] joinFareCallAsCustomer → callId=$fareCallId, roomId=$fareRoomId, riderId=$riderId');

    // Call socket listeners can be wiped mid-session by
    // ChatViewController.disposeSocket() (chat screen teardown) and are only
    // re-bound on app RESUME (AppLifecycleHandler). If that happened since the
    // last resume, this call's `call:accepted` / `call:offer` events would be
    // silently ignored — the customer joins the room, never reacts, and the
    // ring timer expires. Re-bind now; idempotent.
    ensureCallSocketListeners();

    // Same room, already set up — skip
    if (roomId.value == fareRoomId && callStatus.value != CallStatus.idle) {
      print('[FARE_CALL] joinFareCallAsCustomer → already in this room, skipping');
      return true;
    }

    // New rider in queue — clean up previous call first
    if (callStatus.value != CallStatus.idle) {
      print('[FARE_CALL] joinFareCallAsCustomer → cleaning up previous call for new rider');
      _leaveRoomAndCleanup();
    }

    // Request microphone permission (same as initiateCall)
    try {
      final statuses = await [Permission.microphone].request();
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        commonSnackBar(message: AppStrings.microphonePermissionRequired.tr);
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Permission request error: $e');
    }

    // ── Set state (mirrors initiateCall after API success) ──
    callType.value = CallType.audio;
    callStatus.value = CallStatus.outgoing;
    isCaller.value = true;
    isFareCall.value = true;
    callId.value = fareCallId;
    roomId.value = fareRoomId;
    conversationId.value = fareConversationId;
    remoteUserName.value = '';
    remoteUserImage.value = '';
    isGroupCall.value = false;

    print('[FARE_CALL] joinFareCallAsCustomer → state set, callStatus=outgoing, isFareCall=true');

    // ── Parse ICE servers (mirrors initiateCall) ──
    _iceConfig = IceServerConfig(
      iceServers: iceServers.map((s) {
        if (s is Map<String, dynamic>) return IceServer.fromJson(s);
        return IceServer(urls: 'stun:stun.l.google.com:19302');
      }).toList(),
    );
    print('[FARE_CALL] joinFareCallAsCustomer → ICE servers parsed, count=${_iceConfig?.iceServers.length}');

    // ── Join socket room (same as initiateCall) ──
    _socket.emitEvent('call:join-room', {'room_id': roomId.value});
    print('[FARE_CALL] joinFareCallAsCustomer → emitted call:join-room');

    // ── Setup local media & peer connection (same as initiateCall) ──
    _mediaReadyCompleter = Completer<void>();
    await _setupLocalMedia();
    if (!_mediaReadyCompleter!.isCompleted) {
      _mediaReadyCompleter!.complete();
    }
    print('[FARE_CALL] joinFareCallAsCustomer → local media ready');

    await _createPeerConnection(riderId);
    _remoteUserId = riderId;
    // print('[FARE_CALL] joinFareCallAsCustomer → peer connection created for $riderId');

    // ── Start ring timeout (same as initiateCall) ──
    _startRingTimer();

    // ── Show notification & keep alive (same as initiateCall) ──
    _showConnectingNotification();
    WakelockPlus.enable();
    SocketKeepAliveService.start();

    // Don't create offer — wait for call:accepted from rider,
    // which triggers _handleCallAccepted → creates offer (same as initiateCall)
    // print('[FARE_CALL] joinFareCallAsCustomer → ready, waiting for call:accepted');

    return true;
  }

  // ==================== FARE-CALL RIDE ACTIONS ====================

  /// Accept the ride from fare-call or broadcast. Call stays active, order
  /// gets assigned.
  ///
  /// For BROADCAST rides this is a race: the server rings every nearby rider
  /// at once and only the first accept wins. Losers get **409** — which is a
  /// normal outcome, not a failure, so it closes the popup quietly instead of
  /// showing an error. See
  /// docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §7.4.
  Future<bool> acceptFareCallRide() async {
    if (fareCallOrderId.value.isEmpty) return false;
    print('[FARE_CALL] acceptFareCallRide → orderId=${fareCallOrderId.value}');
    final repo = MakeOrderRepo();
    final response = await repo.rideActionApi(
      {'action': 'accept'},
      fareCallOrderId.value,
    );
    if (response.isSuccess) {
      print('[FARE_CALL] Ride accepted successfully');
      return true;
    }

    // 409 = another rider got there first. Silent dismissal: no toast, and
    // stop the ring so it doesn't keep going for a ride that's gone.
    if (response.response?.statusCode == 409) {
      print('[FARE_CALL] Ride already taken by another rider — closing quietly');
      await AppNotificationHandler().dismissBroadcastRide({
        'payload': {
          'metadata': {'orderId': fareCallOrderId.value}
        },
      });
      return false;
    }

    commonSnackBar(
        message: response.message ?? AppStrings.failedToAcceptRide.tr);
    return false;
  }

  /// Reject the ride from fare-call. Call ends, next rider gets called.
  Future<bool> rejectFareCallRide() async {
    if (fareCallOrderId.value.isEmpty) return false;
    // print('[FARE_CALL] rejectFareCallRide → orderId=${fareCallOrderId.value}');
    final repo = MakeOrderRepo();
    final response = await repo.rideActionApi(
      {'action': 'reject'},
      fareCallOrderId.value,
    );
    if (response.isSuccess) {
      // print('[FARE_CALL] Ride rejected, next rider will be called');
      declineCall();
      return true;
    } else {
      commonSnackBar(message: response.message ?? AppStrings.failedToRejectRide.tr);
      return false;
    }
  }

  bool _cleaningUp = false;
  void _cleanup() {
    // print('[FARE_CALL_DEBUG] _cleanup → CALLED, callStatus=${callStatus.value}, isFareCall=${isFareCall.value}, callId=${callId.value}, roomId=${roomId.value}, peerConnections=${peerConnections.keys.toList()}');
    // print('[FARE_CALL_DEBUG] _cleanup → stackTrace: ${StackTrace.current.toString().split('\n').take(5).join(' | ')}');
    // Idempotency guard: if we're already mid-cleanup, or the previous cleanup
    // already reset us to idle with no peers/stream, bail out. Double-cleanup
    // double-disposes the local renderer and stops SocketKeepAliveService
    // twice, which breaks the *next* call's peer connection.
    if (_cleaningUp) {
      // print('[CALL_DEBUG] _cleanup → skipped (re-entrant)');
      return;
    }
    if (callStatus.value == CallStatus.idle &&
        peerConnections.isEmpty &&
        localStream == null &&
        localRenderer == null) {
      // print('[CALL_DEBUG] _cleanup → skipped (already fully cleaned)');
      return;
    }
    _cleaningUp = true;
    try {
      _cleanupInternal();
    } finally {
      _cleaningUp = false;
    }
  }

  void _cleanupInternal() {
    // --- 1. Cancel all timers immediately ---
    _callTimer?.cancel();
    _callTimer = null;
    _ringTimer?.cancel();
    _ringTimer = null;
    _connectionTimer?.cancel();
    _connectionTimer = null;
    _peerDisconnectTimer?.cancel();
    _peerDisconnectTimer = null;
    _cancelNetworkGrace();
    _stopConnectivityWatch();
    _offerRetryTimer?.cancel();
    _offerRetryTimer = null;

    // Stop live audio-device monitoring and reset routing state for next call.
    _stopAudioRouteMonitoring();

    // Hand the Android audio session back to normal media mode so the volume
    // buttons stop pointing at STREAM_VOICE_CALL once the call is over, and stop
    // intercepting the hardware volume rocker.
    _restoreMediaAudioMode();
    _setVolumeInterceptActive(false);
    // Belt and braces — the callStatus worker drops this too once _resetState()
    // lands at the end of teardown, but a call must never leave the app itself
    // showing over the lock screen.
    _setCallWindowActive(false);

    // --- 2. Cancel all notifications & overlays ---
    _cancelOngoingNotification();
    OverlayService.closeOverlay();
    // Remove the ongoing-call record so the chat "Live call ongoing" banner
    // disappears once the call ends (mirrors the connect-time write in
    // _startCallTimer).
    clearActiveCallSession();

    // Cancel ALL local notifications (ongoing call, missed call, etc.)
    try {
      _notificationPlugin.cancelAll();
    } catch (_) {}

    // --- 3. Purge ALL CallKit state so no stale call entry lingers ---
    // We used to only end the specific call by id — but that left orphaned
    // ringing/missed entries in the plugin's cache on races (e.g. a superseded
    // call, or a missed-call notification posted by the plugin's internal
    // duration timer). Nuking everything guarantees "no cache after disconnect".
    // `_isDismissingCallKitUI` prevents the resulting actionCallEnded events
    // from re-entering endCall(); the idempotency guard in _cleanup prevents
    // double-run even if one slips through.
    if (!isFareCall.value) {
      _isDismissingCallKitUI = true;
      try {
        final cid = callId.value;
        // Only call per-id endCall if the plugin actually has this id —
        // otherwise it throws "content null" AND wedges the plugin so the
        // NEXT incoming call's UI auto-dismisses after 10–20s.
        if (cid.isNotEmpty && callKitWasShownFor(cid)) {
          FlutterCallkitIncoming.endCall(cid);
          clearCallKitShownFor(cid);
        }
        // endAllCalls clears the native list; it can throw "content null"
        // when the list is already empty — benign, swallow it.
        FlutterCallkitIncoming.endAllCalls();
        // Also cancel any pending Android local incoming-call notification.
        if (Platform.isAndroid && cid.isNotEmpty) {
          cancelIncomingCallLocalNotification(cid);
        }
      } catch (_) {}
      // Reset flag after a micro-task so any synchronous events settle first.
      Future.microtask(() => _isDismissingCallKitUI = false);
    }

    // --- 4. Stop local media tracks ---
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
      localStream = null;
    }

    // --- 5. Dispose local renderer ---
    try {
      localRenderer?.srcObject = null;
      localRenderer?.dispose();
    } catch (_) {}
    localRenderer = null;

    // --- 6. Close all peer connections ---
    for (final entry in peerConnections.entries) {
      try {
        entry.value.close();
      } catch (_) {}
    }
    peerConnections.clear();

    // --- 7. Dispose all remote renderers & streams ---
    for (final entry in remoteRenderers.entries) {
      try {
        entry.value.srcObject = null;
        entry.value.dispose();
      } catch (_) {}
    }
    remoteRenderers.clear();
    remoteStreams.clear();
    _pendingCandidates.clear();

    // --- 8. Release wakelock & stop socket keep-alive ---
    WakelockPlus.disable();
    SocketKeepAliveService.stop();

    // --- 9. Reset static flags so the next call starts with a clean slate ---
    _callRoomOpenTimer?.cancel();
    _callRoomOpenTimer = null;
    _killedStateAcceptHandled = false;

    // --- 10. Reset all observable state ---
    _resetState();
  }

  void _resetState() {
    stopRingtone();
    // print('[FARE_CALL_DEBUG] _resetState → resetting all state, was isFareCall=${isFareCall.value}, fareCallOrderId=${fareCallOrderId.value}');
    callStatus.value = CallStatus.idle;
    callId.value = '';
    roomId.value = '';
    conversationId.value = '';
    isCaller.value = false;
    callerName.value = '';
    callerImage.value = '';
    remoteUserName.value = '';
    remoteUserImage.value = '';
    callDurationSeconds.value = 0;
    _callConnectedAtMs = 0;
    callRoomEverShown.value = false;
    isMicOn.value = true;
    hasLocalAudio.value = false;
    isCameraOn.value = true;
    isSpeakerOn.value = false;
    remoteAudioEnabled.value = true;
    remoteVideoEnabled.value = true;
    _remoteUserId = null;
    _pendingOffer = null;
    _mediaReadyCompleter = null;
    participantMediaState.clear();
    isSwitchTypePending.value = false;
    switchTypeRequestedBy.value = '';
    isFareCall.value = false;
    fareCallOrderId.value = '';
    fareCallOrderMongoId.value = '';
    fareCallRideDetails.value = null;
    _resetRingingState();
  }

  // ==================== FLOATING OVERLAY ====================

  /// Show the floating overlay window (Android) when the user leaves the app
  /// during an active call. Called from AppLifecycleHandler.
  void showFloatingOverlay() {
    final isActive = callStatus.value == CallStatus.connected ||
        callStatus.value == CallStatus.connecting;
    if (!isActive) return;

    final name = callerName.value.isNotEmpty
        ? callerName.value
        : (remoteUserName.value.isNotEmpty ? remoteUserName.value : 'Call');

    OverlayService.showCallOverlay(
      callerName: name,
      isVideo: callType.value == CallType.video,
      callTime: formattedCallDuration,
    );
  }

  /// Hide the floating overlay when the user returns to the app
  void hideFloatingOverlay() {
    OverlayService.closeOverlay();
  }

  // ==================== CALLKIT ====================

  /// Handle ride_order_received CallKit accept — parse payload, populate
  /// state, and navigate to rider order screen.
  void _handleRideOrderFromCallKit(Map<String, dynamic> extra) {
    try {
      final rawData = extra['rideNotificationData'];
      if (rawData == null) {
        // Minimal fallback — just open screen with orderId
        final orderId = extra['orderId'] ?? '';
        if (orderId.isNotEmpty) {
          isFareCall.value = true;
          fareCallOrderId.value = orderId;
          fareCallRideDetails.value = {};
          if (Get.currentRoute != '/IncomingRiderOrderScreen') {
            Get.toNamed('/IncomingRiderOrderScreen');
          }
        }
        return;
      }

      Map<String, dynamic> notifData;
      if (rawData is String) {
        notifData = jsonDecode(rawData);
      } else {
        notifData = Map<String, dynamic>.from(rawData);
      }

      // Parse the payload JSON string (same structure as message.data)
      Map<String, dynamic> payload = {};
      try {
        final rawPayload = notifData['payload'];
        if (rawPayload is String && rawPayload.isNotEmpty) {
          payload = jsonDecode(rawPayload);
        } else if (rawPayload is Map) {
          payload = Map<String, dynamic>.from(rawPayload);
        }
      } catch (_) {}

      final metadata = payload['metadata'] ?? {};
      final pickupInfo = metadata['Pickup address'] ?? {};
      final dropInfo = metadata['Delivered address'] ?? {};

      double _toNum(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }

      final pickupLat = _toNum(pickupInfo['lat']);
      final pickupLng = _toNum(pickupInfo['long']);
      final dropLat = _toNum(dropInfo['lat']);
      final dropLng = _toNum(dropInfo['long']);
      final fare = _toNum(metadata['ridefare']);
      final orderId = payload['orderId'] ?? metadata['Order_id'] ?? extra['orderId'] ?? '';
      final customerName = notifData['senderName'] ?? notifData['title'] ?? 'Customer';
      final customerImage = notifData['senderProfileImage'] ?? '';

      isFareCall.value = true;
      fareCallOrderId.value = orderId;
      fareCallRideDetails.value = {
        'pickup': {
          'address': (pickupInfo['Address'] ?? '').toString().isNotEmpty
              ? pickupInfo['Address']
              : 'Pickup location',
          'lat': pickupLat,
          'lng': pickupLng,
        },
        'drop': {
          'address': (dropInfo['Address'] ?? '').toString().isNotEmpty
              ? dropInfo['Address']
              : 'Drop location',
          'lat': dropLat,
          'lng': dropLng,
        },
        'fare': fare,
        'distance': 0.0,
        'modeOfPayment': 'postpaid',
      };
      callerName.value = customerName;
      callerImage.value = customerImage;

      if (Get.currentRoute != '/IncomingRiderOrderScreen') {
        Get.toNamed('/IncomingRiderOrderScreen');
      }
    } catch (e) {
      // print('[FARE_CALL] _handleRideOrderFromCallKit error: $e');
    }
  }

  void _setupCallKitListeners() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      // print('[CALL_DEBUG] CALLKIT EVENT → ${event.event}, body=${event.body}');
      final extra =
          Map<String, dynamic>.from(event.body['extra'] as Map? ?? {});

      final operation = (extra['operation'] ?? '').toString();

      // Handle ride_order_received — rider taps "View" from CallKit
      if (operation == 'ride_order_received') {
        if (event.event == Event.actionCallAccept) {
          _handleRideOrderFromCallKit(extra);
        }
        return;
      }

      // Only handle incoming_call events for regular calls
      if (operation != 'incoming_call') return;

      switch (event.event) {
        case Event.actionCallAccept:
          // print('[CALL_DEBUG] CALLKIT → actionCallAccept, killedStateHandled=$_killedStateAcceptHandled');
          // Immediately tell CallKit the call is connected so its internal
          // duration-timer cannot later auto-mark it as a missed call while
          // the user is actively on the call.
          try {
            FlutterCallkitIncoming.setCallConnected(event.body['id']?.toString() ?? '');
          } catch (e) {
            print('[CALL_DEBUG] setCallConnected error: $e');
          }
          // Skip if already handled from main.dart killed-state check
          if (_killedStateAcceptHandled) {
            _killedStateAcceptHandled = false;
            break;
          }
          initStateFromCallKitExtra(extra);

          // For fare-calls: navigate to rider order screen instead of normal call
          if (isFareCall.value) {
            if (Get.currentRoute != '/IncomingRiderOrderScreen') {
              Get.toNamed('/IncomingRiderOrderScreen');
            }
          }

          acceptCall(
              callIdParams: extra['callId'], roomIdParams: extra['roomId']);
          // On Android: dismiss CallKit after 1s (CallActivity handles audio).
          // On iOS: do NOT dismiss here — acceptCall() handles it after WebRTC
          // setup so the audio session stays alive during the handshake.
          if (Platform.isAndroid) {
            Future.delayed(Duration(seconds: 1), () {
              FlutterCallkitIncoming.endCall(event.body['id']);
            });
          }
          break;
        case Event.actionCallDecline:
          initStateFromCallKitExtra(extra);
          // Ids from the CallKit payload, not from our own state:
          // [initStateFromCallKitExtra] deliberately bails when a DIFFERENT
          // call is already past ringing, and a decline that silently retargets
          // the live call — or targets nothing — is worse than either.
          declineCall(
            callIdParams: (extra['callId'] ?? '').toString(),
            roomIdParams: (extra['roomId'] ?? '').toString(),
          );
          Future.delayed(Duration(seconds: 1), () {
            FlutterCallkitIncoming.endCall(event.body['id']);
          });
          break;
        case Event.actionCallEnded:
          // iOS: user ended the call from native CallKit UI (lock screen, phone app).
          // Only act if the call is actively connected and we're on iOS.
          // On Android, CallActivity handles its own lifecycle — skip here.
          // Skip if we triggered this endCall ourselves to dismiss the UI after accept.
          if (Platform.isIOS &&
              !_isDismissingCallKitUI &&
              callStatus.value != CallStatus.idle &&
              (callStatus.value == CallStatus.connected ||
               callStatus.value == CallStatus.connecting ||
               callStatus.value == CallStatus.outgoing ||
               callStatus.value == CallStatus.ringing)) {
            endCall();
          }
          break;
        default:
          break;
      }
    });
  }

  /// Initialize call state from CallKit extra data (for push notification calls)
  void initStateFromCallKitExtra(Map<String, dynamic> extra) {
    if (extra.isEmpty) return;

    final incomingCallId = (extra['callId'] ?? '').toString();
    final status = callStatus.value;

    // Only bail when a DIFFERENT call is already past ringing — a stale payload
    // must not disturb a live conversation. This used to bail on ANY non-idle
    // status, including `ringing`, which is exactly the state the socket's
    // `call:incoming` leaves us in. So when the socket payload arrived without
    // a caller name (common) and the richer push payload arrived after it, the
    // name was thrown away and the screen showed "Unknown".
    if (status != CallStatus.idle &&
        status != CallStatus.ringing &&
        incomingCallId.isNotEmpty &&
        callId.value.isNotEmpty &&
        callId.value != incomingCallId) {
      return;
    }

    /// Keep what we already have unless [incoming] actually carries something —
    /// these payloads arrive from several sources of differing richness and a
    /// later, thinner one must never blank a field a earlier one filled.
    String pick(String current, Object? incoming) {
      final next = (incoming ?? '').toString().trim();
      if (next.isEmpty || next.toLowerCase() == 'unknown') return current;
      return next;
    }

    // Identity fields are applied UNCONDITIONALLY. They used to sit inside an
    // `if (senderId.isNotEmpty)` guard, so a payload without `senderId` (a
    // socket `call:incoming` with no `initiated_by`) applied nothing at all —
    // no name, no callId, no roomId — and the screen fell back to "Unknown".
    final senderId = (extra['senderId'] ?? '').toString();
    if (senderId.isNotEmpty) _remoteUserId = senderId;

    final callTypeStr = (extra['callType'] ?? '').toString();
    if (callTypeStr.isNotEmpty) {
      callType.value =
          callTypeStr == 'video_call' ? CallType.video : CallType.audio;
    }

    conversationId.value = pick(conversationId.value, extra['conversationId']);
    callerName.value = pick(callerName.value, extra['callerName']);
    callerImage.value = pick(callerImage.value, extra['callerImage']);
    remoteUserName.value = pick(remoteUserName.value, callerName.value);
    remoteUserImage.value = pick(remoteUserImage.value, callerImage.value);
    callId.value = pick(callId.value, extra['callId']);
    roomId.value = pick(roomId.value, extra['roomId']);

    isCaller.value = false;
    if (callStatus.value == CallStatus.idle) {
      callStatus.value = CallStatus.ringing;
    }

    // Detect fare-call from push notification extra
    if (extra['isFareCall'] == 'true') {
      isFareCall.value = true;
      fareCallOrderId.value = extra['fareCallOrderId'] ?? '';
      try {
        final rideJson = extra['fareCallRideDetails'];
        if (rideJson is String && rideJson.isNotEmpty) {
          fareCallRideDetails.value =
              Map<String, dynamic>.from(jsonDecode(rideJson));
        }
      } catch (_) {}
    } else if (status == CallStatus.idle) {
      // A payload that bootstraps a FRESH call and does not declare itself a
      // fare-call is a plain call. Saying so explicitly matters: fare-calls own
      // their own UI, so a `true` left behind by an earlier fare-call makes
      // _openCallRoom bail and hides the top call strip — the user ends up on
      // a call with no screen and no way back to it. Guarded on `idle` so a
      // thinner follow-up payload can't clear the flag on a live fare-call.
      isFareCall.value = false;
      fareCallOrderId.value = '';
      fareCallOrderMongoId.value = '';
      fareCallRideDetails.value = null;
    }

    // Connect socket if not connected (app may have been in background)
    _socket = ChatSocketService();
    if (!_socket.isConnected) {
      _socket.connectToSocket();
    }
  }
}

/// IDs of calls that have been registered with the CallKit plugin via
/// `showCallkitIncoming`. Foreground calls (handled by the in-app
/// IncomingCallScreen) never enter this set, so subsequent code can skip
/// `setCallConnected` / `endCall` for those — calling those methods with an
/// id the plugin doesn't know about throws `argument "content" is null` AND
/// corrupts the plugin's internal state, which is what wedges the next
/// background-mode incoming call into auto-dismissing after 10–20s.
final Set<String> _callsShownInCallKit = <String>{};

bool callKitWasShownFor(String callId) =>
    callId.isNotEmpty && _callsShownInCallKit.contains(callId);

void clearCallKitShownFor(String callId) {
  _callsShownInCallKit.remove(callId);
}

/// Show native incoming call notification (for Firebase push).
/// Skips if a call is already active so CallKit stays free for the current call.
void showFlutterCallNotification({
  required String callSessionId,
  required String callerName,
  required String desiginations,
  String? callerImage,
  String? callType,
  Map<String, dynamic>? extra,
  int duration = 45000,
}) async {
  // This call is already over — a late or out-of-order push must not resurrect
  // the CallKit UI. Mirrors the same guard on the Android notification path.
  if (await isCallRetired(callSessionId)) {
    print('[CALL_DEBUG] showFlutterCallNotification → skipped, call retired');
    return;
  }

  // Don't show CallKit if a call is already in progress — keeps CallKit free.
  // Only skip when this push is for a DIFFERENT call than the live one;
  // re-delivery of the SAME call_id (common when server retries) must not
  // be dropped, or the CallKit UI never appears on subsequent incoming calls
  // after a previous call cleaned up with a stale status.
  if (Get.isRegistered<CallController>()) {
    final ctrl = Get.find<CallController>();
    final status = ctrl.callStatus.value;
    final activeCallId = ctrl.callId.value;
    final sameCall = activeCallId.isNotEmpty && activeCallId == callSessionId;
    if (!sameCall &&
        (status == CallStatus.accepting ||
            status == CallStatus.connecting ||
            status == CallStatus.connected ||
            status == CallStatus.outgoing)) {
      // print('showFlutterCallNotification: skipped — call already active ($status, activeId=$activeCallId, incomingId=$callSessionId)');
      return;
    }
  }

  // CRITICAL: clear the plugin's native call list before showing a new call.
  // After a previous call ends — especially a FOREGROUND call where no CallKit
  // entry was ever created but the cleanup paths still call setCallConnected/
  // endCall — the plugin's internal state on Android gets wedged. The next
  // `showCallkitIncoming` then returns OK but the IncomingCallActivity either
  // never launches OR launches and auto-dismisses after 10–20s because the
  // plugin's foreground service for the prior (phantom) call is still
  // counting down.
  //
  // `activeCalls()` itself throws `argument "content" is null` once the list
  // is in this state, and so does `endAllCalls()` — but `endAllCalls()`
  // STILL clears the native list before throwing, so we use it and swallow
  // the known-benign error. Then a tiny settle delay lets the plugin commit
  // before we issue the new show.
  try {
    await FlutterCallkitIncoming.endAllCalls();
  } catch (e) {
    // Known plugin bug: throws when its internal call list is empty/null.
    // The native list is still cleared either way — safe to ignore.
    print('[CALL_DEBUG] showFlutterCallNotification → endAllCalls (benign): $e');
  }
  await Future.delayed(const Duration(milliseconds: 80));

  final isVideo = callType == 'video_call';
  final params = CallKitParams(
    id: callSessionId,
    nameCaller: callerName.isNotEmpty?callerName:"N/A",
    appName: 'BlueEra',
    avatar: callerImage ?? '',
    // `handle` renders as the secondary identifier on some OEM CallKit UIs
    // (and as the contact line on iOS). Fall back to the caller name so we
    // never surface a raw designation/user-id string when the name is known.
    handle: (desiginations.isNotEmpty && desiginations != callerName)
        ? desiginations
        : (callerName.isNotEmpty ? callerName : 'BlueEra'),
    type: isVideo ? 1 : 0,
    duration: duration,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: NotificationParams(
      showNotification: false,
      isShowCallback: true,
      subtitle: 'Missed ${isVideo ? 'video' : 'voice'} call',
      callbackText: 'Call Back',
    ),
    extra: extra ?? {},
    android: AndroidParams(
      isCustomSmallExNotification: false,
      isShowLogo: false, // hide logo
      isShowCallID: true,
      isShowFullLockedScreen: true,
      isImportant: true,
      // CRITICAL: keep this FALSE. With `true` the plugin renders only a
      // custom heads-up notification (no full-screen intent activity), and
      // OEM launchers (Xiaomi/Vivo/Realme/OnePlus/Samsung) silently suppress
      // those when the app is in background or killed — `showCallkitIncoming`
      // returns OK but no UI ever appears. With `false` the plugin uses its
      // default IncomingCallActivity launched via USE_FULL_SCREEN_INTENT,
      // which is required to render reliably in background/terminated state.
      isCustomNotification: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      // CRITICAL: must be a STABLE channel name. We previously passed the
      // per-call `desiginations` string, which created a new channel on
      // every incoming call — and runtime-created channels default to
      // IMPORTANCE_DEFAULT (no full-screen intent privilege), so background
      // calls stopped raising the lock-screen UI after the first call.
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
    ),
    ios: IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: isVideo,
      supportsDTMF: true,
      supportsHolding: true,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'voiceChat',
      // Keep the plugin from activating an AVAudioSession while ringing — doing
      // so silences the CallKit ringtone. CallKit's didActivate (after answer)
      // and flutter_webrtc handle the in-call audio session. Must match the
      // kill-mode path in ios/Runner/AppDelegate.swift.
      audioSessionActive: false,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      configureAudioSession: false,
      // iOS: with the patched flutter_callkit_incoming fork (see
      // packages/flutter_callkit_incoming), 'system_ringtone_default' leaves
      // CXProviderConfiguration.ringtoneSound = nil, so CallKit plays the user's
      // chosen iOS default ringtone. Must match AppDelegate.swift's VoIP/kill-mode
      // path. Android also treats 'system_ringtone_default' as the device default.
      ringtonePath: 'system_ringtone_default',
    ),
  );

  // print('[CALL_DEBUG] showFlutterCallNotification → calling showCallkitIncoming, id=$callSessionId, type=$callType');
  try {
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    _callsShownInCallKit.add(callSessionId);
    // print('[CALL_DEBUG] showFlutterCallNotification → showCallkitIncoming returned OK');
  } catch (e) {
    // print('[CALL_DEBUG] showFlutterCallNotification → showCallkitIncoming ERROR: $e\n$st');
  }
}
