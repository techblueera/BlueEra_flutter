import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

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
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/app_notification.dart';

import '../model/call_models.dart';
import '../repo/call_repo.dart';
import '../socket/chat_socket.dart';

enum CallType { audio, video }

enum CallStatus { idle, ringing, accepting, outgoing, connecting, connected, ended }

class CallController extends GetxController {
  final CallRepo _callRepo = CallRepo();
  late ChatSocketService _socket;

  // --- Observable state ---
  var callType = CallType.audio.obs;
  var callStatus = CallStatus.idle.obs;

  var callerName = ''.obs;
  var callerImage = ''.obs;
  var remoteUserName = ''.obs;
  var remoteUserImage = ''.obs;
  var callId = ''.obs;
  var roomId = ''.obs;
  var conversationId = ''.obs;
  var isCaller = false.obs;
  var isGroupCall = false.obs;

  // Media toggles
  var isMicOn = true.obs;
  var isCameraOn = true.obs;
  var isSpeakerOn = false.obs;
  var isFrontCamera = true.obs;

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

  // WebRTC
  MediaStream? localStream;
  final peerConnections = <String, RTCPeerConnection>{};
  final remoteStreams = <String, MediaStream>{}.obs;
  final remoteRenderers = <String, RTCVideoRenderer>{};
  RTCVideoRenderer? localRenderer;

  IceServerConfig? _iceConfig;
  String? _remoteUserId;

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

  /// Reactive flag: when true, app shows only the call screen (killed-state accept)
  static final launchedForCall = false.obs;

  /// Whether this session was a call-only cold start (used to navigate to home on call end)
  static bool _coldStartCall = false;

  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    _socket = ChatSocketService();
    _setupCallSocketListeners();
    _setupCallKitListeners();

  }

  @override
  void onClose() {
    _disposed = true;

    _cleanup();
    super.onClose();
  }


  // ==================== SOCKET EVENT LISTENERS ====================

  void _setupCallSocketListeners() {
    // Incoming call
    _socket.listenEvent('call:incoming', (data) {
      if (_disposed) return;
      _handleIncomingCall(data);
    });

    // Call accepted by receiver
    _socket.listenEvent('call:accepted', (data) {
      if (_disposed) return;
      _handleCallAccepted(data);
    });

    // Call declined by receiver
    _socket.listenEvent('call:declined', (data) {
      if (_disposed) return;
      _handleCallDeclined(data);
    });

    // Call cancelled by caller
    _socket.listenEvent('call:cancelled', (data) {
      if (_disposed) return;
      _handleCallCancelled(data);
    });

    // Call ended
    _socket.listenEvent('call:ended', (data) {
      if (_disposed) return;
      _handleCallEnded(data);
    });

    // Answered elsewhere
    _socket.listenEvent('call:answered-elsewhere', (data) {
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
    // Request permissions (wrapped in try-catch to avoid PlatformException
    // when another permission request is already in progress)
    try {
      final permissions = [Permission.microphone];
      if (type == CallType.video) permissions.add(Permission.camera);
      final statuses = await permissions.request();
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        commonSnackBar(message: 'Camera/Microphone permission required');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Permission request error (may already be in progress): $e');
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

    ResponseModel response = await _callRepo.initiateCall(params);

    if (!response.isSuccess) {
      final statusCode = response.response?.statusCode;
      if (statusCode == 409) {
        commonSnackBar(message: 'User is busy on another call');
      } else {
        commonSnackBar(message: response.message ?? 'Failed to initiate call');
      }
      return false;
    }

    final data = response.response?.data;
    if (data == null) return false;

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

    _iceConfig = IceServerConfig.fromJson(data['ice_servers'] ?? {});

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': roomId.value});

    // Setup local media & peer connection (don't create offer yet)
    _mediaReadyCompleter = Completer<void>();
    await _setupLocalMedia();
    if (!_mediaReadyCompleter!.isCompleted) {
      _mediaReadyCompleter!.complete();
    }
    await _createPeerConnection(otherUserId ?? '');
    _remoteUserId = otherUserId;

    // Start 60-second ring timeout
    _startRingTimer();

    // Show notification to keep app in foreground
    _showConnectingNotification();

    // Keep screen on & enable PiP
    WakelockPlus.enable();


    return true;
  }

  // ==================== INCOMING CALL HANDLING ====================

  void _handleIncomingCall(dynamic data) {
    if (callStatus.value != CallStatus.idle) return; // already in a call

    callId.value = data['call_id'] ?? '';
    roomId.value = data['room_id'] ?? '';
    conversationId.value = data['conversation_id'] ?? '';
    callType.value =
        data['call_type'] == 'video_call' ? CallType.video : CallType.audio;
    isGroupCall.value = data['is_group_call'] ?? false;
    isCaller.value = false;
    callerName.value = data['caller_name'] ?? data['initiated_by'] ?? '';
    callerImage.value = data['caller_image'] ?? '';
    _remoteUserId = data['initiated_by'] ?? '';
    callStatus.value = CallStatus.ringing;

    // Show incoming call screen via GetX navigation (avoid duplicate if push already opened it)
    if (Get.currentRoute != '/IncomingCallScreen') {
      Get.toNamed('/IncomingCallScreen');
    }
  }

  /// Accept an incoming call
  Future<bool> acceptCall() async {
    // Prevent double accept (multiple CallKit listeners may fire)
    if (callStatus.value == CallStatus.accepting ||
        callStatus.value == CallStatus.connecting ||
        callStatus.value == CallStatus.connected) {
      return false;
    }
    // Immediately transition to accepting so call:answered-elsewhere
    // won't reset our state while we're in the middle of accepting
    final savedCallId = callId.value;
    final savedRoomId = roomId.value;
    final savedRemoteUserId = _remoteUserId;
    final savedPendingOffer = _pendingOffer;
    callStatus.value = CallStatus.accepting;

    // Request permissions (wrapped in try-catch to avoid PlatformException
    // when another permission request is already in progress)
    try {
      final permissions = [Permission.microphone];
      if (callType.value == CallType.video) permissions.add(Permission.camera);
      await permissions.request();
    } catch (e) {
      if (kDebugMode) print('Permission request error (may already be in progress): $e');
    }
log("sdkjcskjlcskjc ${{
  'call_id': savedCallId,
  'room_id': savedRoomId,
}}");
    ResponseModel response = await _callRepo.acceptCall({
      'call_id': savedCallId,
      'room_id': savedRoomId,
    });

    if (!response.isSuccess) {
      final statusCode = response.response?.statusCode;
      if (statusCode == 404) {
        commonSnackBar(message: 'Call is no longer available');
      } else {
        commonSnackBar(message: response.message ?? 'Failed to accept call');
      }
      _cleanup();
      return false;
    }

    final data = response.response?.data;
    _iceConfig = IceServerConfig.fromJson(data?['ice_servers'] ?? {});

    callStatus.value = CallStatus.connecting;

    // Show ongoing notification immediately to keep app in foreground
    _showConnectingNotification();

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': savedRoomId});

    // Setup local media — signal when ready so offer handler can wait
    _mediaReadyCompleter = Completer<void>();
    await _setupLocalMedia();
    if (!_mediaReadyCompleter!.isCompleted) {
      _mediaReadyCompleter!.complete();
    }

    // If we received an SDP offer while ringing/accepting, process it now
    final offerToProcess = _pendingOffer ?? savedPendingOffer;
    if (offerToProcess != null && savedRemoteUserId != null) {
      final pc = await _createPeerConnection(savedRemoteUserId);
      final sdp = RTCSessionDescription(
        offerToProcess['sdp'],
        offerToProcess['type'],
      );
      await pc.setRemoteDescription(sdp);
      await _flushPendingCandidates(savedRemoteUserId);

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _socket.emitEvent('call:answer', {
        'room_id': savedRoomId,
        'target_user_id': savedRemoteUserId,
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });
      _pendingOffer = null;
    }

    // Keep screen on & enable PiP
    WakelockPlus.enable();


    // Start a 30-second connection timeout — if not connected by then, end the call
    _startConnectionTimeout();

    return true;
  }

  Timer? _connectionTimer;

  void _startConnectionTimeout() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(const Duration(seconds: 30), () {
      if (callStatus.value == CallStatus.connecting ||
          callStatus.value == CallStatus.accepting) {
        if (kDebugMode) print('Call connection timeout — ending call');
        commonSnackBar(message: 'Call connection timed out');
        endCall();
      }
    });
  }

  /// Decline an incoming call
  Future<void> declineCall() async {
    if (callStatus.value == CallStatus.idle) return;
    await _callRepo.declineCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });
    _cleanup();
    _navigateBackFromCallScreen();
  }

  /// Cancel an outgoing call (before anyone answers)
  Future<void> cancelCall() async {
    _ringTimer?.cancel();
    await _callRepo.cancelCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });
    _socket.emitEvent('call:leave-room', {
      'room_id': roomId.value,
      'call_id': callId.value,
    });
    _cleanup();
    _navigateBackFromCallScreen();
  }

  /// End an active call
  Future<void> endCall() async {
    await _callRepo.endCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });
    _socket.emitEvent('call:leave-room', {
      'room_id': roomId.value,
      'call_id': callId.value,
    });
    _cleanup();
    _navigateBackFromCallScreen();
  }

  // ==================== SOCKET EVENT HANDLERS ====================

  void _handleCallAccepted(dynamic data) async {
    if (callStatus.value != CallStatus.outgoing) return;

    _ringTimer?.cancel();
    callStatus.value = CallStatus.connecting;
    final acceptedBy = data['accepted_by'] ?? '';
    _remoteUserId = acceptedBy;

    // Navigate to ActiveCallScreen
    Get.offNamed('/ActiveCallScreen');

    // Caller creates and sends the SDP offer
    final pc = peerConnections[_remoteUserId] ??
        await _createPeerConnection(_remoteUserId!);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _socket.emitEvent('call:offer', {
      'room_id': roomId.value,
      'target_user_id': _remoteUserId,
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  void _handleCallDeclined(dynamic data) {
    final callEnded = data['call_ended'] ?? true;
    _ringTimer?.cancel();
    if (callEnded == true) {
      commonSnackBar(message: 'Call declined');
      _leaveRoomAndCleanup();
      Get.back();
    } else {
      // Group call: some users declined but others may still answer
      if (kDebugMode) print('User ${data['declined_by']} declined group call');
    }
  }

  void _handleCallCancelled(dynamic data) {
    FlutterCallkitIncoming.endCall(callId.value);
    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
  }

  void _handleCallEnded(dynamic data) {
    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
  }

  void _handleAnsweredElsewhere(dynamic data) {
    // Only dismiss if still ringing - do NOT reset if accepting or active
    if (callStatus.value != CallStatus.ringing) return;

    FlutterCallkitIncoming.endCall(callId.value);
    _leaveRoomAndCleanup();
    _navigateBackFromCallScreen();
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
    if (_coldStartCall) {
      // App was launched only for this call — go to home screen
      _coldStartCall = false;
      launchedForCall.value = false;
      Get.offAllNamed('/BottomNavigationBarScreen');
      return;
    }
    final route = Get.currentRoute;
    if (route == '/ActiveCallScreen' ||
        route == '/OutgoingCallScreen' ||
        route == '/IncomingCallScreen') {
      Get.back();
    }
  }

  // ==================== WEBRTC SIGNALING ====================

  void _handleRemoteOffer(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    _remoteUserId = fromUserId;

    // If still ringing or in the middle of accepting, store the offer
    if (callStatus.value == CallStatus.ringing ||
        callStatus.value == CallStatus.accepting) {
      _pendingOffer = data['sdp'];
      return;
    }

    // Only process if we're in connecting/connected state
    if (callStatus.value != CallStatus.connecting &&
        callStatus.value != CallStatus.connected) {
      return;
    }

    // Wait for local media to be ready before creating peer connection
    // (offer can arrive while _setupLocalMedia is still running)
    if (_mediaReadyCompleter != null && !_mediaReadyCompleter!.isCompleted) {
      await _mediaReadyCompleter!.future;
    }

    final pc = peerConnections[fromUserId] ??
        await _createPeerConnection(fromUserId);

    final sdp =
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
    await pc.setRemoteDescription(sdp);

    // Flush buffered ICE candidates
    await _flushPendingCandidates(fromUserId);

    // Create and send answer
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _socket.emitEvent('call:answer', {
      'room_id': roomId.value,
      'target_user_id': fromUserId,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  void _handleRemoteAnswer(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    final pc = peerConnections[fromUserId];
    if (pc == null) return;

    // Only set remote description if we're in 'have-local-offer' state
    if (pc.signalingState !=
        RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      return;
    }

    final sdp =
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
    await pc.setRemoteDescription(sdp);

    // Flush buffered ICE candidates
    await _flushPendingCandidates(fromUserId);
  }

  void _handleRemoteIceCandidate(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    final candidateMap = data['candidate'];
    if (candidateMap == null) return;

    final candidate = RTCIceCandidate(
      candidateMap['candidate'],
      candidateMap['sdpMid'],
      candidateMap['sdpMLineIndex'],
    );

    final pc = peerConnections[fromUserId];
    if (pc != null) {
      try {
        await pc.addCandidate(candidate);
      } catch (_) {
        // Buffer until remote description is set
        _pendingCandidates.putIfAbsent(fromUserId, () => []);
        _pendingCandidates[fromUserId]!.add(candidate);
        return;
      }
    } else {
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
      commonSnackBar(message: response.message ?? 'Failed to add users');
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
      commonSnackBar(message: '${busyUsers.length} user(s) are on another call');
    }
    if (addedUsers.isNotEmpty) {
      commonSnackBar(message: '${addedUsers.length} user(s) added to call');
    }
    if (addedUsers.isEmpty && busyUsers.isEmpty && alreadyInCall.isNotEmpty) {
      commonSnackBar(message: 'User(s) already in this call');
    }

    return data;
  }

  // ==================== CALL TYPE SWITCH (Audio ↔ Video) ====================

  /// Request to switch call type (audio ↔ video)
  Future<void> switchCallType() async {
    if (callId.value.isEmpty || roomId.value.isEmpty) return;

    final currentType = callType.value == CallType.video ? 'video_call' : 'audio_call';
    final newType = currentType == 'audio_call' ? 'video_call' : 'audio_call';

    // If switching to video, request camera permission first
    if (newType == 'video_call') {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        commonSnackBar(message: 'Camera permission required to switch to video');
        return;
      }
    }

    ResponseModel response = await _callRepo.switchCallType({
      'call_id': callId.value,
      'room_id': roomId.value,
      'new_call_type': newType,
    });

    if (!response.isSuccess) {
      commonSnackBar(message: response.message ?? 'Failed to switch call type');
      return;
    }

    final data = response.response?.data;
    if (data?['pending_approval'] == true) {
      // Audio → video: waiting for other participants to accept
      isSwitchTypePending.value = true;
      commonSnackBar(message: 'Waiting for approval to switch to video...');
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

    if (isVideo) {
      // Enable local video - add video track if not present
      _enableLocalVideo();
      isSpeakerOn.value = true;
      _setSpeakerphone(true);
    } else {
      // Disable camera
      localStream?.getVideoTracks().forEach((track) => track.enabled = false);
      isCameraOn.value = false;
      isSpeakerOn.value = false;
      _setSpeakerphone(false);
    }
  }

  void _handleSwitchTypeDeclined(dynamic data) {
    isSwitchTypePending.value = false;
    commonSnackBar(message: 'Switch to video was declined');
  }

  /// Enable local video track (for audio → video switch)
  Future<void> _enableLocalVideo() async {
    // Check if we already have a video track
    final existingVideoTracks = localStream?.getVideoTracks() ?? [];
    if (existingVideoTracks.isNotEmpty) {
      // Just enable the existing track
      for (var track in existingVideoTracks) {
        track.enabled = true;
      }
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
    } catch (e) {
      if (kDebugMode) print('Failed to enable video: $e');
      commonSnackBar(message: 'Failed to enable camera');
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
      commonSnackBar(message: response.message ?? 'Failed to join call');
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
    localRenderer = RTCVideoRenderer();
    await localRenderer!.initialize();

    final isVideo = callType.value == CallType.video;
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    });

    localRenderer!.srcObject = localStream;

    // For audio calls, default speaker off
    if (!isVideo) {
      isSpeakerOn.value = false;
      _setSpeakerphone(false);
    } else {
      isSpeakerOn.value = true;
      _setSpeakerphone(true);
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    if (peerConnections.containsKey(peerId)) {
      return peerConnections[peerId]!;
    }

    final config = _iceConfig?.toWebRTCConfig() ??
        {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'}
          ]
        };

    final pc = await createPeerConnection(config, {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': callType.value == CallType.video,
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
      _socket.emitEvent('call:ice-candidate', {
        'room_id': roomId.value,
        'target_user_id': peerId,
        'candidate': candidate.toMap(),
      });
    };

    // Remote stream handler
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _handleRemoteStream(peerId, event.streams[0]);
      }
    };

    // Connection state
    pc.onConnectionState = (RTCPeerConnectionState state) {
      if (_disposed) return;
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectionTimer?.cancel();
          callStatus.value = CallStatus.connected;
          _startCallTimer();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          endCall();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          // Temporary - may reconnect
          if (kDebugMode) print('WebRTC: Peer disconnected (may reconnect)');
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
  }

  // ==================== MEDIA CONTROLS ====================

  void toggleMic() {
    final audioTrack = localStream?.getAudioTracks().firstOrNull;
    if (audioTrack == null) return;
    audioTrack.enabled = !audioTrack.enabled;
    isMicOn.value = audioTrack.enabled;

    _socket.emitEvent('call:media-toggle', {
      'room_id': roomId.value,
      'is_audio_enabled': isMicOn.value,
      'is_video_enabled': isCameraOn.value,
    });
  }

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

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    _setSpeakerphone(isSpeakerOn.value);
  }

  void _setSpeakerphone(bool enabled) {
    try {
      Helper.setSpeakerphoneOn(enabled);
    } catch (e) {
      if (kDebugMode) print('Failed to set speakerphone: $e');
    }
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
    return (data['calls'] as List)
        .map((c) => CallModel.fromJson(c))
        .toList();
  }

  // ==================== UTILITY ====================

  String getCallDisplayText(CallModel call, String currentUserId) {
    final bool isOutgoing = call.initiatedBy == currentUserId;
    final String direction = isOutgoing ? 'Outgoing' : 'Incoming';

    switch (call.status) {
      case 'ended':
        if (call.endReason == 'missed') {
          return isOutgoing ? 'No answer' : 'Missed call';
        } else if (call.endReason == 'declined') {
          return isOutgoing ? 'Declined' : 'You declined';
        } else {
          return '$direction call - ${_formatDuration(call.durationSeconds)}';
        }
      case 'missed':
        return isOutgoing ? 'No answer' : 'Missed call';
      case 'declined':
        return isOutgoing ? 'Declined' : 'You declined';
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

  void _startCallTimer() {
    _callTimer?.cancel();
    callDurationSeconds.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDurationSeconds.value++;
    });
    // Start the ongoing call notification
    _showOngoingCallNotification();
  }

  void _startRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: 60), () {
      if (callStatus.value == CallStatus.outgoing && isCaller.value) {
        cancelCall();
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
    try {
      final name = callerName.value.isNotEmpty
          ? callerName.value
          : (remoteUserName.value.isNotEmpty ? remoteUserName.value : 'Connecting');
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
    _notificationTimer?.cancel();
    // Show immediately, then update every second with call duration
    _updateOngoingNotification();
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateOngoingNotification();
    });
  }

  Future<void> _updateOngoingNotification() async {
    try {
      final name = callerName.value.isNotEmpty
          ? callerName.value
          : (remoteUserName.value.isNotEmpty ? remoteUserName.value : 'Unknown');
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

  void _cleanup() {
    _callTimer?.cancel();
    _ringTimer?.cancel();
    _connectionTimer?.cancel();
    _cancelOngoingNotification();

    // Stop local tracks
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
      localStream = null;
    }

    // Dispose local renderer
    try {
      localRenderer?.srcObject = null;
      localRenderer?.dispose();
    } catch (_) {}
    localRenderer = null;

    // Close all peer connections
    for (final entry in peerConnections.entries) {
      try {
        entry.value.close();
      } catch (_) {}
    }
    peerConnections.clear();

    // Dispose all remote renderers
    for (final entry in remoteRenderers.entries) {
      try {
        entry.value.srcObject = null;
        entry.value.dispose();
      } catch (_) {}
    }
    remoteRenderers.clear();
    remoteStreams.clear();
    _pendingCandidates.clear();

    WakelockPlus.disable();
    _resetState();
  }

  void _resetState() {
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
    isMicOn.value = true;
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
  }

  // ==================== CALLKIT ====================

  void _setupCallKitListeners() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      final extra = Map<String, dynamic>.from(event.body['extra'] as Map? ?? {});


      // Only handle incoming_call events — skip ride orders and other types
      final operation = (extra['operation'] ?? '').toString();
      if (operation != 'incoming_call') return;

      switch (event.event) {
        case Event.actionCallAccept:
          // If state isn't already set (push notification case), populate from extra
          initStateFromCallKitExtra(extra);
          // Signal the app to show only the call screen (skips splash/home)
          launchedForCall.value = true;
          _coldStartCall = true;
          acceptCall().then((accepted) {
            if (!accepted) {
              // Accept failed — reset to normal app flow
              launchedForCall.value = false;
              _coldStartCall = false;
            }
          });
          Future.delayed(Duration(seconds: 1),(){
            FlutterCallkitIncoming.endAllCalls();
          });
          break;
        case Event.actionCallDecline:
          initStateFromCallKitExtra(extra);
          declineCall();
          Future.delayed(Duration(seconds: 1),(){
            FlutterCallkitIncoming.endAllCalls();
          });
          break;
        case Event.actionCallEnded:
          endCall();
          Future.delayed(Duration(seconds: 1),(){
            FlutterCallkitIncoming.endAllCalls();
          });
          break;
        default:
          break;
      }
    });
  }

  /// Initialize call state from CallKit extra data (for push notification calls)
  void initStateFromCallKitExtra(Map<String, dynamic> extra) {
    if (callStatus.value != CallStatus.idle || extra.isEmpty) return;

    // These come from the push notification payload passed via showFlutterCallNotification
    final senderId = extra['senderId'] ?? '';
    final convId = extra['conversationId'] ?? '';
    final callTypeStr = extra['callType'] ?? '';

    if (senderId.isNotEmpty) {
      _remoteUserId = senderId;
      callType.value = callTypeStr == 'video_call' ? CallType.video : CallType.audio;
      conversationId.value = convId;
      isCaller.value = false;
      callStatus.value = CallStatus.ringing;
      callerName.value = extra['callerName'] ?? '';
      callerImage.value = extra['callerImage'] ?? '';

      // Set callId and roomId from push notification data (critical for acceptCall API)
      if (extra['callId'] != null && extra['callId'].toString().isNotEmpty) {
        callId.value = extra['callId'];
      }
      if (extra['roomId'] != null && extra['roomId'].toString().isNotEmpty) {
        roomId.value = extra['roomId'];
      }

      // Connect socket if not connected (app may have been in background)
      _socket = ChatSocketService();
      if (!_socket.isConnected) {
        _socket.connectToSocket();
      }
    }
  }
}

/// Show native incoming call notification (for Firebase push)
void showFlutterCallNotification({
  required String callSessionId,
  required String callerName,
  String? callerImage,
  String? callType,
  Map<String, dynamic>? extra,
}) async {
  final isVideo = callType == 'video_call';
  final params = CallKitParams(
    id: callSessionId,
    nameCaller: callerName,
    appName: 'BlueEra',
    avatar: callerImage ?? '',
    handle: isVideo ? 'Incoming video call' : 'Incoming voice call',
    type: isVideo ? 1 : 0,
    duration: 60000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'Missed ${isVideo ? 'video' : 'voice'} call',
      callbackText: 'Call Back',
    ),
    extra: extra ?? {},
    android: AndroidParams(
      isShowLogo: true,
      isShowFullLockedScreen: true,
      isImportant: true,
      isCustomNotification: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
      isShowCallID: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: true,
      supportsDTMF: true,
      supportsHolding: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}
