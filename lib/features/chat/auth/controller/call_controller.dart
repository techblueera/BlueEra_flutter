import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../model/call_models.dart';
import '../repo/call_repo.dart';
import '../socket/chat_socket.dart';

enum CallType { audio, video }

enum CallStatus { idle, ringing, connecting, connected, ended }

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

  // Remote user media state
  var remoteAudioEnabled = true.obs;
  var remoteVideoEnabled = true.obs;

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

    // Media toggle from remote
    _socket.listenEvent('call:media-toggle', (data) {
      if (_disposed) return;
      remoteAudioEnabled.value = data['is_audio_enabled'] ?? true;
      remoteVideoEnabled.value = data['is_video_enabled'] ?? true;
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
    // Request permissions
    final permissions = [Permission.microphone];
    if (type == CallType.video) permissions.add(Permission.camera);
    final statuses = await permissions.request();
    if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      commonSnackBar(message: 'Camera/Microphone permission required');
      return false;
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
    callStatus.value = CallStatus.ringing;
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
    await _setupLocalMedia();
    await _createPeerConnection(otherUserId ?? '');
    _remoteUserId = otherUserId;

    // Start 60-second ring timeout
    _startRingTimer();

    // Keep screen on
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
    callStatus.value = CallStatus.ringing;

    // Show incoming call screen via GetX navigation
    Get.toNamed('/IncomingCallScreen');
  }

  /// Accept an incoming call
  Future<bool> acceptCall() async {
    // Request permissions
    final permissions = [Permission.microphone];
    if (callType.value == CallType.video) permissions.add(Permission.camera);
    await permissions.request();

    ResponseModel response = await _callRepo.acceptCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });

    if (!response.isSuccess) {
      final statusCode = response.response?.statusCode;
      if (statusCode == 404) {
        commonSnackBar(message: 'Call is no longer available');
      } else {
        commonSnackBar(message: response.message ?? 'Failed to accept call');
      }
      _resetState();
      return false;
    }

    final data = response.response?.data;
    _iceConfig = IceServerConfig.fromJson(data?['ice_servers'] ?? {});

    callStatus.value = CallStatus.connecting;

    // Join socket room
    _socket.emitEvent('call:join-room', {'room_id': roomId.value});

    // Setup local media
    await _setupLocalMedia();

    // Keep screen on
    WakelockPlus.enable();

    return true;
  }

  /// Decline an incoming call
  Future<void> declineCall() async {
    await _callRepo.declineCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });
    _cleanup();
    Get.back();
  }

  /// Cancel an outgoing call (before anyone answers)
  Future<void> cancelCall() async {
    _ringTimer?.cancel();
    await _callRepo.cancelCall({
      'call_id': callId.value,
      'room_id': roomId.value,
    });
    _cleanup();
    Get.back();
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
    Get.back();
  }

  // ==================== SOCKET EVENT HANDLERS ====================

  void _handleCallAccepted(dynamic data) async {
    _ringTimer?.cancel();
    callStatus.value = CallStatus.connecting;
    final acceptedBy = data['accepted_by'] ?? '';
    _remoteUserId = acceptedBy;

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
    _ringTimer?.cancel();
    commonSnackBar(message: 'Call declined');
    _cleanup();
    Get.back();
  }

  void _handleCallCancelled(dynamic data) {
    FlutterCallkitIncoming.endCall(callId.value);
    _cleanup();
    Get.back();
  }

  void _handleCallEnded(dynamic data) {
    _cleanup();
    if (Get.currentRoute == '/ActiveCallScreen' ||
        Get.currentRoute == '/OutgoingCallScreen' ||
        Get.currentRoute == '/IncomingCallScreen') {
      Get.back();
    }
  }

  void _handleAnsweredElsewhere(dynamic data) {
    FlutterCallkitIncoming.endCall(callId.value);
    _cleanup();
    if (Get.currentRoute == '/IncomingCallScreen') {
      Get.back();
    }
  }

  // ==================== WEBRTC SIGNALING ====================

  void _handleRemoteOffer(dynamic data) async {
    final fromUserId = data['from_user_id'] ?? '';
    _remoteUserId = fromUserId;

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
    await _closePeerConnection(leftUserId);
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
  }

  void _startRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: 60), () {
      if (callStatus.value == CallStatus.ringing && isCaller.value) {
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

  void _cleanup() {
    _callTimer?.cancel();
    _ringTimer?.cancel();

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
  }

  // ==================== CALLKIT ====================

  void _setupCallKitListeners() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          acceptCall();
          break;
        case Event.actionCallDecline:
          declineCall();
          break;
        case Event.actionCallEnded:
          endCall();
          break;
        default:
          break;
      }
    });
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
  final params = CallKitParams(
    id: callSessionId,
    nameCaller: callerName,
    appName: 'BlueEra',
    avatar: callerImage ?? '',
    handle: 'Call From $callerName',
    type: callType == 'video_call' ? 1 : 0,
    duration: 60000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      subtitle: 'Missed call',
    ),
    extra: extra ?? {},
    android: const AndroidParams(
      isShowLogo: true,
      isShowFullLockedScreen: true,
      isImportant: true,
    ),
    ios: const IOSParams(
      supportsVideo: true,
      supportsDTMF: true,
      supportsHolding: true,
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}
