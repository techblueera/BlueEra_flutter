# Flutter WhatsApp-Style Calling Integration

> A complete guide to implementing seamless audio/video calling in Flutter with native call UI, system-level notifications, overlay caller windows, and in-app call headers — just like WhatsApp.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Core Dependencies](#2-core-dependencies)
3. [Platform Setup](#3-platform-setup)
4. [CallKit & ConnectionService Integration](#4-callkit--connectionservice-integration)
5. [WebRTC Signaling & Media](#5-webrtc-signaling--media)
6. [Incoming Call — Full-Screen Caller UI](#6-incoming-call--full-screen-caller-ui)
7. [Ongoing Call Notification with Timer & Hangup](#7-ongoing-call-notification-with-timer--hangup)
8. [Floating Overlay / PiP Caller Window](#8-floating-overlay--pip-caller-window)
9. [In-App Call Header Banner](#9-in-app-call-header-banner)
10. [Call State Management](#10-call-state-management)
11. [Background & Lifecycle Handling](#11-background--lifecycle-handling)
12. [Push Notifications for Incoming Calls](#12-push-notifications-for-incoming-calls)
13. [Permissions](#13-permissions)
14. [Folder Structure](#14-folder-structure)
15. [Testing Checklist](#15-testing-checklist)
16. [Common Pitfalls](#16-common-pitfalls)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Your Flutter App                  │
│  ┌───────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Call UI   │  │ In-App   │  │  Overlay / PiP   │  │
│  │  Screens   │  │ Banner   │  │  Caller Window   │  │
│  └─────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│        │              │                 │             │
│  ┌─────▼──────────────▼─────────────────▼──────────┐ │
│  │            CallController (Riverpod/Bloc)        │ │
│  │     Manages state, timers, audio/video toggle    │ │
│  └─────────────────────┬───────────────────────────┘ │
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐ │
│  │              WebRTC Service Layer                │ │
│  │    flutter_webrtc + Signaling (WebSocket/FCM)   │ │
│  └─────────────────────┬───────────────────────────┘ │
└────────────────────────┼─────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │     Native Platform Layer   │
          │  iOS: CallKit (VoIP Push)   │
          │  Android: ConnectionService │
          │  + Foreground Service        │
          │  + System Overlay Window     │
          └─────────────────────────────┘
```

**Key Principles:**

- The native OS handles the initial incoming call screen (lockscreen ring UI).
- Your Flutter code manages the active-call experience: in-app banner, overlay window, and call controls.
- WebRTC handles the actual media (audio/video streams).
- A single `CallController` drives all UI surfaces from one source of truth.

---

## 2. Core Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # WebRTC for audio/video
  flutter_webrtc: ^0.12.4
  # Native call integration (CallKit on iOS, ConnectionService on Android)
  flutter_callkit_incoming: ^2.0.4+1
  # Push notifications
  firebase_messaging: ^15.1.6
  firebase_core: ^3.8.1
  # State management (pick one)
  flutter_riverpod: ^2.6.1
  # Local notifications (ongoing call notification)
  flutter_local_notifications: ^18.0.1
  # Overlay/floating window (Android)
  flutter_overlay_window: ^0.5.0
  # Wakelock to keep screen alive during calls
  wakelock_plus: ^1.2.8
  # Audio session management
  flutter_audio_session: ^0.1.21  # or audio_session: ^0.1.21
  # Permissions
  permission_handler: ^11.3.1
  # UUID generation for call IDs
  uuid: ^4.5.1
```

---

## 3. Platform Setup

### Android — `AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />
    <uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name="${applicationName}"
        android:usesCleartextTraffic="true"
        ...>

        <activity
            android:name=".MainActivity"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:launchMode="singleTask"
            ...>
        </activity>

        <!-- Foreground service for ongoing calls -->
        <service
            android:name="com.example.app.CallForegroundService"
            android:foregroundServiceType="phoneCall"
            android:exported="false" />

        <!-- Overlay entry point for floating caller window -->
        <service
            android:name="com.example.app.OverlayService"
            android:foregroundServiceType="phoneCall"
            android:exported="false" />

    </application>
</manifest>
```

### Android — `build.gradle` (app-level)

```groovy
android {
    compileSdk 35
    defaultConfig {
        minSdk 24  // Minimum for ConnectionService
        targetSdk 35
    }
}
```

### iOS — `Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for audio and video calls</string>
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

### iOS — `Podfile`

```ruby
platform :ios, '14.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

---

## 4. CallKit & ConnectionService Integration

`flutter_callkit_incoming` gives you the native incoming call screen on both platforms without loading your Flutter engine.

### `lib/services/callkit_service.dart`

```dart
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  String? _currentCallId;

  /// Show the native incoming call screen (works from killed/background state)
  Future<void> showIncomingCall({
    required String callerName,
    required String callerAvatar,
    required String callerId,
    bool isVideo = false,
  }) async {
    _currentCallId = const Uuid().v4();

    final params = CallKitParams(
      id: _currentCallId!,
      nameCaller: callerName,
      appName: 'YourApp',
      avatar: callerAvatar,
      handle: callerId,
      type: isVideo ? 1 : 0, // 0 = audio, 1 = video
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
      ),
      duration: 45000, // Ring timeout in ms
      extra: <String, dynamic>{
        'callerId': callerId,
        'isVideo': isVideo,
      },
      headers: <String, dynamic>{
        'apiKey': 'your_server_api_key',
        'platform': 'flutter',
      },
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1a1a2e',
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: null, // Uses default
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Start an outgoing call (registers with OS telecom)
  Future<void> startOutgoingCall({
    required String callerName,
    required String callerId,
    bool isVideo = false,
  }) async {
    _currentCallId = const Uuid().v4();

    final params = CallKitParams(
      id: _currentCallId!,
      nameCaller: callerName,
      handle: callerId,
      type: isVideo ? 1 : 0,
      extra: <String, dynamic>{
        'callerId': callerId,
        'isVideo': isVideo,
      },
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentCallId != null) {
      await FlutterCallkitIncoming.endCall(_currentCallId!);
      _currentCallId = null;
    }
  }

  /// End all active calls
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    _currentCallId = null;
  }

  /// Listen to CallKit events globally
  static void listenToCallEvents({
    required Function(CallEvent) onEvent,
  }) {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event != null) onEvent(event);
    });
  }

  String? get currentCallId => _currentCallId;
}
```

### Handling CallKit Events in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Handle CallKit events globally
  CallKitService.listenToCallEvents(onEvent: _handleCallEvent);

  runApp(const MyApp());
}

void _handleCallEvent(CallEvent event) {
  switch (event.event) {
    case Event.actionCallIncoming:
      // Call is ringing — you can preload WebRTC here
      debugPrint('Incoming call: ${event.body}');
      break;

    case Event.actionCallAccept:
      // User accepted — navigate to call screen & connect WebRTC
      final callData = event.body;
      final bool isVideo = callData['extra']?['isVideo'] ?? false;
      _navigateToCallScreen(
        callerId: callData['extra']?['callerId'],
        isVideo: isVideo,
      );
      break;

    case Event.actionCallDecline:
      // User declined — notify server
      _sendCallDeclinedToServer(event.body);
      break;

    case Event.actionCallEnded:
      // Call ended (either side hung up)
      _cleanupCall();
      break;

    case Event.actionCallTimeout:
      // Ring timed out — treat as missed call
      _handleMissedCall(event.body);
      break;

    case Event.actionCallCallback:
      // User tapped "call back" from missed call notification
      _initiateCallback(event.body);
      break;

    default:
      break;
  }
}
```

---

## 5. WebRTC Signaling & Media

### `lib/services/webrtc_service.dart`

```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Callbacks
  Function(MediaStream)? onRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;
  Function()? onConnectionClosed;

  /// ICE server configuration
  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:your-turn-server.com:3478',
        'username': 'turnuser',
        'credential': 'turnpassword',
      },
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Acquire local media (camera + mic)
  Future<void> openUserMedia({bool video = true}) async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = _localStream;
  }

  /// Create the peer connection & attach streams
  Future<void> createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceConfig, _constraints);

    // Add local tracks to connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Listen for remote tracks
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // Gather ICE candidates to send via signaling
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      onIceCandidate?.call(candidate);
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onConnectionClosed?.call();
      }
    };
  }

  /// Create an offer (caller side)
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// Create an answer (callee side)
  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  /// Set remote description (from signaling)
  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _peerConnection!.setRemoteDescription(desc);
  }

  /// Add ICE candidate received from remote peer
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  /// Toggle microphone
  void toggleMute(bool muted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !muted;
    });
  }

  /// Toggle camera
  void toggleCamera(bool off) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !off;
    });
  }

  /// Switch front/back camera
  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  /// Toggle speakerphone
  void toggleSpeaker(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enableSpeakerphone(enabled);
    });
  }

  /// Clean up all resources
  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
  }
}
```

### `lib/services/signaling_service.dart`

Signaling connects two peers via your backend. Use WebSockets for real-time exchange:

```dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  WebSocketChannel? _channel;
  Function(RTCSessionDescription)? onRemoteOffer;
  Function(RTCSessionDescription)? onRemoteAnswer;
  Function(RTCIceCandidate)? onRemoteCandidate;
  Function()? onRemoteHangup;

  void connect(String signalingServerUrl, String roomId) {
    _channel = WebSocketChannel.connect(
      Uri.parse('$signalingServerUrl?room=$roomId'),
    );

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);

      switch (data['type']) {
        case 'offer':
          onRemoteOffer?.call(RTCSessionDescription(
            data['sdp'],
            data['type'],
          ));
          break;
        case 'answer':
          onRemoteAnswer?.call(RTCSessionDescription(
            data['sdp'],
            data['type'],
          ));
          break;
        case 'candidate':
          onRemoteCandidate?.call(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
          break;
        case 'hangup':
          onRemoteHangup?.call();
          break;
      }
    });
  }

  void sendOffer(RTCSessionDescription offer) {
    _send({'type': 'offer', 'sdp': offer.sdp});
  }

  void sendAnswer(RTCSessionDescription answer) {
    _send({'type': 'answer', 'sdp': answer.sdp});
  }

  void sendCandidate(RTCIceCandidate candidate) {
    _send({
      'type': 'candidate',
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  void sendHangup() {
    _send({'type': 'hangup'});
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void dispose() {
    _channel?.sink.close();
  }
}
```

---

## 6. Incoming Call — Full-Screen Caller UI

When `flutter_callkit_incoming` handles the initial ring on the lock screen, and the user accepts, your app opens a full-screen call UI.

### `lib/screens/call_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    this.isVideo = false,
    this.isIncoming = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRTCService _webrtc;
  late final SignalingService _signaling;
  late final CallKitService _callkit;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;

  Duration _callDuration = Duration.zero;
  late final Stopwatch _stopwatch;
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _webrtc = WebRTCService();
    _signaling = SignalingService();
    _callkit = CallKitService();
    _stopwatch = Stopwatch();

    _initializeCall();
  }

  Future<void> _initializeCall() async {
    await _webrtc.initialize();
    await _webrtc.openUserMedia(video: widget.isVideo);
    await _webrtc.createPeerConnection();

    // Wire up signaling ↔ WebRTC
    _webrtc.onIceCandidate = (candidate) {
      _signaling.sendCandidate(candidate);
    };

    _signaling.onRemoteCandidate = (candidate) {
      _webrtc.addIceCandidate(candidate);
    };

    _signaling.onRemoteOffer = (offer) async {
      await _webrtc.setRemoteDescription(offer);
      final answer = await _webrtc.createAnswer();
      _signaling.sendAnswer(answer);
    };

    _signaling.onRemoteAnswer = (answer) {
      _webrtc.setRemoteDescription(answer);
    };

    _webrtc.onRemoteStream = (_) {
      setState(() => _isConnected = true);
      _startTimer();
    };

    _signaling.onRemoteHangup = () => _endCall();

    // Connect to signaling server
    _signaling.connect('wss://your-server.com/ws', widget.callerId);

    // If outgoing, create and send offer
    if (!widget.isIncoming) {
      final offer = await _webrtc.createOffer();
      _signaling.sendOffer(offer);
    }
  }

  void _startTimer() {
    _stopwatch.start();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
    _timerStream.listen((_) {
      if (mounted) {
        setState(() => _callDuration = _stopwatch.elapsed);
      }
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _endCall() async {
    _stopwatch.stop();
    _signaling.sendHangup();
    await _callkit.endCall();
    await _webrtc.dispose();
    _signaling.dispose();
    WakelockPlus.disable();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        children: [
          // Remote video (full screen background)
          if (widget.isVideo && _isConnected)
            Positioned.fill(
              child: RTCVideoView(
                _webrtc.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),

          // Gradient overlay for controls visibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Local video (small PiP in corner)
          if (widget.isVideo)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _webrtc.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // Caller info (centered top)
          if (!widget.isVideo || !_isConnected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.callerAvatar != null
                        ? NetworkImage(widget.callerAvatar!)
                        : null,
                    child: widget.callerAvatar == null
                        ? Text(
                            widget.callerName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConnected
                        ? _formatDuration(_callDuration)
                        : 'Connecting...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Call controls (bottom)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    _webrtc.toggleMute(_isMuted);
                  },
                ),
                if (widget.isVideo)
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    label: _isCameraOff ? 'Camera On' : 'Camera Off',
                    onPressed: () {
                      setState(() => _isCameraOff = !_isCameraOff);
                      _webrtc.toggleCamera(_isCameraOff);
                    },
                  ),
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'End',
                  backgroundColor: Colors.red,
                  onPressed: _endCall,
                ),
                _buildControlButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  label: 'Speaker',
                  onPressed: () {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                    _webrtc.toggleSpeaker(_isSpeakerOn);
                  },
                ),
                if (widget.isVideo)
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    label: 'Flip',
                    onPressed: () => _webrtc.switchCamera(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color backgroundColor = Colors.white24,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: backgroundColor,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }
}
```

---

## 7. Ongoing Call Notification with Timer & Hangup

When the user navigates away from the call screen, show a persistent notification with call duration and a "Hang Up" button — just like WhatsApp.

### `lib/services/call_notification_service.dart`

```dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CallNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _callNotificationId = 9999;
  static Timer? _timer;
  static final Stopwatch _stopwatch = Stopwatch();

  /// Initialize the notification plugin (call once in main)
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'hangup') {
          // Trigger call end via your CallController
          CallController.instance.endCall();
        }
      },
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'call_channel',
      'Ongoing Calls',
      description: 'Shows active call status',
      importance: Importance.low, // Low so it doesn't pop up intrusively
      playSound: false,
      enableVibration: false,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show ongoing call notification with live timer
  static void showOngoingCallNotification({
    required String callerName,
    bool isVideo = false,
  }) {
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNotification(callerName: callerName, isVideo: isVideo);
    });

    _updateNotification(callerName: callerName, isVideo: isVideo);
  }

  static Future<void> _updateNotification({
    required String callerName,
    required bool isVideo,
  }) async {
    final elapsed = _stopwatch.elapsed;
    final timeStr = _formatDuration(elapsed);
    final callType = isVideo ? 'Video call' : 'Voice call';

    final androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Ongoing Calls',
      channelDescription: 'Shows active call status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,        // Cannot be swiped away
      autoCancel: false,
      showWhen: false,
      usesChronometer: true,
      chronometerCountDown: false,
      when: DateTime.now()
          .subtract(elapsed)
          .millisecondsSinceEpoch, // Syncs system chronometer
      category: AndroidNotificationCategory.call,
      actions: const [
        AndroidNotificationAction(
          'hangup',
          'Hang up',
          titleColor: Color.fromARGB(255, 255, 0, 0),
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
      // Tapping the notification opens the call screen
      fullScreenIntent: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentSound: false,
    );

    await _plugin.show(
      _callNotificationId,
      '$callType · $callerName',
      timeStr,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Remove the notification and stop the timer
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    _stopwatch.reset();
    _plugin.cancel(_callNotificationId);
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
```

---

## 8. Floating Overlay / PiP Caller Window

This is the **standalone floating window** that appears over other apps — so the user can browse their phone while on a call, without loading the full app UI.

### Android: System Overlay with `flutter_overlay_window`

#### `lib/services/overlay_service.dart`

```dart
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  /// Check and request overlay permission
  static Future<bool> requestPermission() async {
    final isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
      return await FlutterOverlayWindow.isPermissionGranted();
    }
    return true;
  }

  /// Show the floating caller overlay
  static Future<void> showCallOverlay({
    required String callerName,
    required bool isVideo,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'Ongoing Call',
      overlayContent: callerName,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: isVideo ? 250 : 80,
      width: isVideo ? 180 : 280,
      startPosition: const OverlayPosition(0, -200),
    );

    // Send initial data to overlay
    await FlutterOverlayWindow.shareData({
      'callerName': callerName,
      'isVideo': isVideo,
      'action': 'start',
    });
  }

  /// Update the overlay timer
  static Future<void> updateTimer(String timeString) async {
    await FlutterOverlayWindow.shareData({
      'action': 'updateTimer',
      'time': timeString,
    });
  }

  /// Close the overlay
  static Future<void> closeOverlay() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }
}
```

#### `lib/overlay/overlay_caller_widget.dart`

This widget runs as a **separate Flutter engine** — it does NOT load your main app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Entry point for the overlay — registered in main.dart
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CallerOverlayWidget(),
  ));
}

class CallerOverlayWidget extends StatefulWidget {
  const CallerOverlayWidget({super.key});

  @override
  State<CallerOverlayWidget> createState() => _CallerOverlayWidgetState();
}

class _CallerOverlayWidgetState extends State<CallerOverlayWidget> {
  String _callerName = '';
  String _callTime = '00:00';
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          if (data['action'] == 'start') {
            _callerName = data['callerName'] ?? '';
            _isVideo = data['isVideo'] ?? false;
          } else if (data['action'] == 'updateTimer') {
            _callTime = data['time'] ?? '00:00';
          }
        });
      }
    });
  }

  void _onHangUp() {
    // Send hangup message back to main app isolate
    FlutterOverlayWindow.shareData({'action': 'hangup'});
    FlutterOverlayWindow.closeOverlay();
  }

  void _onTapExpand() {
    // Reopen the main app's call screen
    FlutterOverlayWindow.shareData({'action': 'expand'});
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return _buildVideoOverlay();
    }
    return _buildAudioOverlay();
  }

  /// Compact audio-only floating bar
  Widget _buildAudioOverlay() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapExpand,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF128C7E), // WhatsApp-style green
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _callTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _onHangUp,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.call_end, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Video PiP overlay (shows remote video feed placeholder)
  Widget _buildVideoOverlay() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapExpand,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // In a real implementation, you'd use a texture or platform view
              // to render the remote video feed here.
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white54, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      _callerName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      _callTime,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // Hangup button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _onHangUp,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Register in `main.dart`

```dart
@pragma("vm:entry-point")
void overlayMain() {
  // This is defined in overlay_caller_widget.dart
  // It runs as a separate isolate / Flutter engine
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CallerOverlayWidget(),
  ));
}
```

### iOS: Native Picture-in-Picture

iOS doesn't allow system overlays. Use `AVPictureInPictureController` for video calls or rely on the CallKit active-call banner (green bar at top):

```dart
// iOS automatically shows the green "Touch to return" banner
// when a CallKit call is active and the user navigates away.
// For video PiP, use a platform channel:

// In your iOS AppDelegate.swift:
/*
import AVKit

class CallPiPManager: NSObject {
    var pipController: AVPictureInPictureController?

    func enablePiP(with sampleBufferLayer: AVSampleBufferDisplayLayer) {
        let source = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleBufferLayer,
            playbackDelegate: self
        )
        pipController = AVPictureInPictureController(contentSource: source)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
}
*/
```

---

## 9. In-App Call Header Banner

When the user is inside the app during an active call, show a tappable green banner at the top (just like WhatsApp's in-app header).

### `lib/widgets/call_banner.dart`

```dart
import 'package:flutter/material.dart';

class CallBanner extends StatelessWidget {
  final String callerName;
  final Duration callDuration;
  final bool isVideo;
  final VoidCallback onTap;
  final VoidCallback onHangUp;

  const CallBanner({
    super.key,
    required this.callerName,
    required this.callDuration,
    required this.isVideo,
    required this.onTap,
    required this.onHangUp,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          bottom: 8,
          left: 16,
          right: 8,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF128C7E), // WhatsApp green
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isVideo ? Icons.videocam : Icons.phone_in_talk,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${isVideo ? "Video" : "Voice"} call · ${_formatDuration(callDuration)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Tap to return',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onHangUp,
              icon: const Icon(Icons.call_end, color: Colors.red, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Wrap Your App's Scaffold

```dart
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Listen to your call state (Riverpod/Bloc/etc.)
    final callState = ref.watch(callControllerProvider);

    return Column(
      children: [
        // Show banner only when call is active and user is NOT on call screen
        if (callState.isActive && !callState.isOnCallScreen)
          CallBanner(
            callerName: callState.callerName,
            callDuration: callState.duration,
            isVideo: callState.isVideo,
            onTap: () => Navigator.pushNamed(context, '/call'),
            onHangUp: () => ref.read(callControllerProvider.notifier).endCall(),
          ),
        Expanded(child: child),
      ],
    );
  }
}
```

---

## 10. Call State Management

A single state controller that drives every UI surface.

### `lib/controllers/call_controller.dart`

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CallStatus { idle, ringing, connecting, connected, ended }
enum CallType { audio, video }

class CallState {
  final CallStatus status;
  final CallType type;
  final String callerName;
  final String callerId;
  final String? callerAvatar;
  final Duration duration;
  final bool isMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final bool isOnCallScreen;

  const CallState({
    this.status = CallStatus.idle,
    this.type = CallType.audio,
    this.callerName = '',
    this.callerId = '',
    this.callerAvatar,
    this.duration = Duration.zero,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = false,
    this.isOnCallScreen = false,
  });

  bool get isActive =>
      status == CallStatus.connecting || status == CallStatus.connected;
  bool get isVideo => type == CallType.video;

  CallState copyWith({
    CallStatus? status,
    CallType? type,
    String? callerName,
    String? callerId,
    String? callerAvatar,
    Duration? duration,
    bool? isMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    bool? isOnCallScreen,
  }) {
    return CallState(
      status: status ?? this.status,
      type: type ?? this.type,
      callerName: callerName ?? this.callerName,
      callerId: callerId ?? this.callerId,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isOnCallScreen: isOnCallScreen ?? this.isOnCallScreen,
    );
  }
}

class CallController extends StateNotifier<CallState> {
  static CallController? instance;

  Timer? _durationTimer;
  final WebRTCService _webrtc;
  final SignalingService _signaling;
  final CallKitService _callkit;

  CallController({
    required WebRTCService webrtc,
    required SignalingService signaling,
    required CallKitService callkit,
  })  : _webrtc = webrtc,
        _signaling = signaling,
        _callkit = callkit,
        super(const CallState()) {
    instance = this;
  }

  /// Start an outgoing call
  Future<void> startCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    CallType type = CallType.audio,
  }) async {
    state = state.copyWith(
      status: CallStatus.ringing,
      type: type,
      callerName: callerName,
      callerId: callerId,
      callerAvatar: callerAvatar,
    );

    await _callkit.startOutgoingCall(
      callerName: callerName,
      callerId: callerId,
      isVideo: type == CallType.video,
    );

    // Show notification immediately
    CallNotificationService.showOngoingCallNotification(
      callerName: callerName,
      isVideo: type == CallType.video,
    );
  }

  /// Handle incoming call accepted
  Future<void> acceptIncomingCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    CallType type = CallType.audio,
  }) async {
    state = state.copyWith(
      status: CallStatus.connecting,
      type: type,
      callerName: callerName,
      callerId: callerId,
      callerAvatar: callerAvatar,
    );

    CallNotificationService.showOngoingCallNotification(
      callerName: callerName,
      isVideo: type == CallType.video,
    );
  }

  /// Mark call as connected (WebRTC media flowing)
  void onCallConnected() {
    state = state.copyWith(status: CallStatus.connected);
    _startDurationTimer();
  }

  /// End the call and clean everything up
  Future<void> endCall() async {
    _durationTimer?.cancel();
    _signaling.sendHangup();
    await _callkit.endCall();
    await _webrtc.dispose();
    _signaling.dispose();

    CallNotificationService.dismiss();
    await OverlayService.closeOverlay();

    state = const CallState(); // Reset to idle
  }

  /// User left the call screen (show overlay / notification)
  void onLeaveCallScreen() {
    state = state.copyWith(isOnCallScreen: false);
    if (state.isActive) {
      OverlayService.showCallOverlay(
        callerName: state.callerName,
        isVideo: state.isVideo,
      );
    }
  }

  /// User returned to the call screen (hide overlay)
  void onEnterCallScreen() {
    state = state.copyWith(isOnCallScreen: true);
    OverlayService.closeOverlay();
  }

  void toggleMute() {
    final newMuted = !state.isMuted;
    _webrtc.toggleMute(newMuted);
    state = state.copyWith(isMuted: newMuted);
  }

  void toggleCamera() {
    final newOff = !state.isCameraOff;
    _webrtc.toggleCamera(newOff);
    state = state.copyWith(isCameraOff: newOff);
  }

  void toggleSpeaker() {
    final newOn = !state.isSpeakerOn;
    _webrtc.toggleSpeaker(newOn);
    state = state.copyWith(isSpeakerOn: newOn);
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newDuration = state.duration + const Duration(seconds: 1);
      state = state.copyWith(duration: newDuration);

      // Update overlay timer
      OverlayService.updateTimer(_formatDuration(newDuration));
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    instance = null;
    super.dispose();
  }
}

/// Riverpod provider
final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) {
  return CallController(
    webrtc: WebRTCService(),
    signaling: SignalingService(),
    callkit: CallKitService(),
  );
});
```

---

## 11. Background & Lifecycle Handling

### `lib/services/lifecycle_handler.dart`

```dart
import 'package:flutter/widgets.dart';

class CallLifecycleHandler extends WidgetsBindingObserver {
  final CallController callController;

  CallLifecycleHandler(this.callController) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background — show overlay if call active
        if (callController.state.isActive) {
          OverlayService.showCallOverlay(
            callerName: callController.state.callerName,
            isVideo: callController.state.isVideo,
          );
        }
        break;

      case AppLifecycleState.resumed:
        // App returned to foreground — hide overlay, show banner
        OverlayService.closeOverlay();
        break;

      case AppLifecycleState.detached:
        // App being killed — end call gracefully
        if (callController.state.isActive) {
          callController.endCall();
        }
        break;

      default:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
```

---

## 12. Push Notifications for Incoming Calls

### Firebase Cloud Messaging (Android) + VoIP Push (iOS)

```dart
// lib/services/push_notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> init() async {
    // Request permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      criticalAlert: true,  // For call notifications
    );

    // Get FCM token for your backend
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    // Send token to your server: api.registerDevice(token)

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/killed state messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'incoming_call') {
      CallKitService().showIncomingCall(
        callerName: message.data['callerName'] ?? 'Unknown',
        callerAvatar: message.data['callerAvatar'] ?? '',
        callerId: message.data['callerId'] ?? '',
        isVideo: message.data['isVideo'] == 'true',
      );
    }
  }
}

// MUST be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();

  if (message.data['type'] == 'incoming_call') {
    await CallKitService().showIncomingCall(
      callerName: message.data['callerName'] ?? 'Unknown',
      callerAvatar: message.data['callerAvatar'] ?? '',
      callerId: message.data['callerId'] ?? '',
      isVideo: message.data['isVideo'] == 'true',
    );
  }
}
```

### Backend Push Payload Format

Your Node.js backend should send this structure:

```json
{
  "to": "<device_fcm_token>",
  "priority": "high",
  "data": {
    "type": "incoming_call",
    "callerId": "user_123",
    "callerName": "John Doe",
    "callerAvatar": "https://example.com/avatar.jpg",
    "isVideo": "true",
    "roomId": "room_abc_123"
  }
}
```

> **Important:** Use `data` only (no `notification` block) so the message always reaches your handler — even when the app is killed. The `flutter_callkit_incoming` plugin will display the native call UI.

### iOS VoIP Push (Required for Reliable Delivery)

For iOS, regular FCM push is **not reliable enough** for calls. You must use APNs VoIP pushes:

1. Enable "VoIP Services" in your Apple Developer certificate.
2. Use the `voip` background mode in `Info.plist` (already added above).
3. Your server sends VoIP pushes via APNs (`apns-topic: your.bundle.id.voip`).
4. `flutter_callkit_incoming` handles the rest on iOS automatically when configured with VoIP push.

---

## 13. Permissions

### `lib/services/permission_service.dart`

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions needed before a call
  static Future<bool> requestCallPermissions({bool isVideo = false}) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideo) Permission.camera,
      Permission.notification,
      Permission.phone,          // Android: ConnectionService
      Permission.bluetoothConnect,
    ];

    final statuses = await permissions.request();

    // Check critical permissions
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted =
        !isVideo || (statuses[Permission.camera]?.isGranted ?? false);

    return micGranted && camGranted;
  }

  /// Request overlay permission (Android only, for floating window)
  static Future<bool> requestOverlayPermission() async {
    if (await Permission.systemAlertWindow.isGranted) return true;
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }
}
```

---

## 14. Folder Structure

```
lib/
├── main.dart                           # App entry + overlayMain entry
├── controllers/
│   └── call_controller.dart            # Riverpod call state management
├── screens/
│   ├── call_screen.dart                # Full-screen call UI
│   └── home_screen.dart                # Your main app screen
├── widgets/
│   ├── call_banner.dart                # In-app green header banner
│   └── app_shell.dart                  # Wraps scaffold with banner
├── overlay/
│   └── overlay_caller_widget.dart      # Floating window (separate engine)
├── services/
│   ├── callkit_service.dart            # Native call UI (CallKit/ConnectionService)
│   ├── webrtc_service.dart             # WebRTC peer connection & media
│   ├── signaling_service.dart          # WebSocket signaling
│   ├── call_notification_service.dart  # Ongoing call notification with timer
│   ├── overlay_service.dart            # System overlay management
│   ├── push_notification_service.dart  # FCM / VoIP push handling
│   ├── permission_service.dart         # Runtime permission requests
│   └── lifecycle_handler.dart          # App lifecycle ↔ call state bridge
└── models/
    └── call_models.dart                # Data classes for call info
```

---

## 15. Testing Checklist

### Functional Tests

- [ ] **Incoming call while app is killed** → Native call screen appears (CallKit/ConnectionService)
- [ ] **Incoming call while app is in background** → Native call screen appears
- [ ] **Incoming call while app is in foreground** → Native call screen or custom UI appears
- [ ] **Accept call** → Navigates to full-screen call UI, WebRTC connects
- [ ] **Decline call** → Call dismissed, server notified
- [ ] **Missed call (timeout)** → Missed call notification appears
- [ ] **End call (local)** → All resources cleaned up, notification dismissed
- [ ] **End call (remote)** → Same cleanup happens automatically
- [ ] **Navigate away during call** → Floating overlay appears (Android) / green banner (iOS)
- [ ] **Return to app during call** → Overlay dismissed, in-app banner shows
- [ ] **Tap banner** → Returns to full-screen call UI
- [ ] **Hang up from notification** → Call ends without opening app
- [ ] **Hang up from overlay** → Call ends, overlay closes
- [ ] **Audio ↔ Video toggle** → Streams update correctly
- [ ] **Mute/Unmute** → Audio track toggled
- [ ] **Speaker toggle** → Audio route changes
- [ ] **Camera flip** → Front/back camera switches
- [ ] **Call timer accuracy** → Timer matches across notification, banner, and call screen

### Edge Cases

- [ ] Multiple rapid calls (debounce)
- [ ] Network drop during call (ICE reconnection)
- [ ] Bluetooth headset connect/disconnect during call
- [ ] Another phone call comes in during VoIP call
- [ ] Low memory / app killed by OS during call
- [ ] Screen rotation during video call

---

## 16. Common Pitfalls

**"Overlay not showing on Android 12+"**
→ `SYSTEM_ALERT_WINDOW` requires explicit user grant on Android 12+. Always call `requestPermission()` before showing the overlay and handle the rejection gracefully.

**"Call UI doesn't appear when app is killed"**
→ Ensure you use `data`-only FCM payloads (no `notification` key). For iOS, you must use VoIP push via APNs — standard FCM push will not reliably wake the app.

**"Audio doesn't route to earpiece"**
→ Configure `audio_session` properly. Set category to `.playAndRecord` with `.defaultToSpeaker` only when speaker is toggled on. Default should be earpiece for phone calls.

**"Video freezes when app goes to background"**
→ WebRTC tracks are paused by the OS when the app backgrounds. For Android, use a foreground service with `phoneCall` type to keep media alive. On iOS, the `voip` background mode handles this.

**"Timer is inconsistent across surfaces"**
→ Use a single source of truth for duration (in `CallController`). All UI surfaces — notification, overlay, banner, and call screen — should read from the same state.

**"Overlay crashes on iOS"**
→ iOS does not support system overlays. Use CallKit's native green banner (automatic) and `AVPictureInPictureController` for video PiP.

**"Multiple calls ring simultaneously"**
→ Set `maximumCallGroups: 1` and `maximumCallsPerCallGroup: 1` in iOS CallKit params. On Android, reject new calls if one is already active.

**"Call notification won't dismiss"**
→ Always call `CallNotificationService.dismiss()` in your `endCall()` flow. Use `ongoing: true` only while the call is active, never for missed calls.

---

## Further Reading

- [flutter_webrtc docs](https://pub.dev/packages/flutter_webrtc)
- [flutter_callkit_incoming docs](https://pub.dev/packages/flutter_callkit_incoming)
- [flutter_overlay_window docs](https://pub.dev/packages/flutter_overlay_window)
- [Apple CallKit documentation](https://developer.apple.com/documentation/callkit)
- [Android ConnectionService](https://developer.android.com/reference/android/telecom/ConnectionService)
- [WebRTC.org](https://webrtc.org/)

---

> **Version:** 1.0  
> **Compatibility:** Flutter 3.22+, Dart 3.4+, iOS 14+, Android API 24+  
> **Last Updated:** March 2026
