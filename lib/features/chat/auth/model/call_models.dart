/// State pushed by the server via `call:ringing` to drive the outgoing-call
/// label on the caller side. See `lib/docs/call-ringing-event-flutter-integration-guide.md`.
enum CallRingingState {
  dialing,
  ringing,
  connecting,
  connected,
  noAnswer,
  declined,
  busy,
  failed,
  cancelled;

  static CallRingingState fromServer(String? raw) {
    switch (raw) {
      case 'dialing':
        return CallRingingState.dialing;
      case 'ringing':
        return CallRingingState.ringing;
      case 'connecting':
        return CallRingingState.connecting;
      case 'connected':
        return CallRingingState.connected;
      case 'no_answer':
        return CallRingingState.noAnswer;
      case 'declined':
        return CallRingingState.declined;
      case 'busy':
        return CallRingingState.busy;
      case 'cancelled':
        return CallRingingState.cancelled;
      case 'failed':
        return CallRingingState.failed;
      default:
        return CallRingingState.dialing;
    }
  }

  bool get isTerminal {
    switch (this) {
      case CallRingingState.noAnswer:
      case CallRingingState.declined:
      case CallRingingState.busy:
      case CallRingingState.failed:
      case CallRingingState.cancelled:
        return true;
      default:
        return false;
    }
  }

  String get label {
    switch (this) {
      case CallRingingState.dialing:
        return 'Dialing…';
      case CallRingingState.ringing:
        return 'Ringing…';
      case CallRingingState.connecting:
        return 'Connecting…';
      case CallRingingState.connected:
        return 'Connected';
      case CallRingingState.noAnswer:
        return 'No answer';
      case CallRingingState.declined:
        return 'Call declined';
      case CallRingingState.busy:
        return 'User is busy';
      case CallRingingState.failed:
        return 'Call failed';
      case CallRingingState.cancelled:
        return 'Cancelled';
    }
  }
}

class CallModel {
  final String id;
  final String conversationId;
  final String initiatedBy;
  final String callType; // "audio_call" or "video_call"
  final String status; // "ringing", "connecting", "connected", "ended", "missed", "declined"
  final String? endReason; // "completed", "missed", "declined", "failed", "busy"
  final String roomId;
  final String? messageId;
  final bool isGroupCall;
  final int maxParticipants;
  final bool screenSharingEnabled;
  final bool recordingEnabled;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final DateTime createdAt;
  final List<CallParticipant>? participants;

  CallModel({
    required this.id,
    required this.conversationId,
    required this.initiatedBy,
    required this.callType,
    required this.status,
    this.endReason,
    required this.roomId,
    this.messageId,
    this.isGroupCall = false,
    this.maxParticipants = 2,
    this.screenSharingEnabled = false,
    this.recordingEnabled = false,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    required this.createdAt,
    this.participants,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['_id'] ?? json['call_id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      initiatedBy: json['initiated_by'] ?? '',
      callType: json['call_type'] ?? '',
      status: json['status'] ?? '',
      endReason: json['end_reason'],
      roomId: json['room_id'] ?? '',
      messageId: json['message_id'],
      isGroupCall: json['is_group_call'] ?? false,
      maxParticipants: json['max_participants'] ?? 2,
      screenSharingEnabled: json['screen_sharing_enabled'] ?? false,
      recordingEnabled: json['recording_enabled'] ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => CallParticipant.fromJson(p))
              .toList()
          : null,
    );
  }
}

class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final String role; // "initiator", "receiver", "joiner"
  final String status; // "ringing", "connecting", "connected", "left", "declined", "missed", "failed"
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int durationSeconds;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;

  CallParticipant({
    required this.id,
    required this.callId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.durationSeconds = 0,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.isScreenSharing = false,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['_id'] ?? '',
      callId: json['call_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
      leftAt:
          json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      isVideoEnabled: json['is_video_enabled'] ?? true,
      isAudioEnabled: json['is_audio_enabled'] ?? true,
      isScreenSharing: json['is_screen_sharing'] ?? false,
    );
  }
}

class IceServerConfig {
  final List<IceServer> iceServers;

  IceServerConfig({required this.iceServers});

  factory IceServerConfig.fromJson(Map<String, dynamic> json) {
    final servers = json['iceServers'] as List? ?? [];
    return IceServerConfig(
      iceServers: servers.map((s) => IceServer.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toWebRTCConfig() {
    return {
      'iceServers': iceServers.map((s) => s.toMap()).toList(),
    };
  }
}

class IceServer {
  final String urls;
  final String? username;
  final String? credential;

  IceServer({required this.urls, this.username, this.credential});

  factory IceServer.fromJson(Map<String, dynamic> json) {
    return IceServer(
      urls: json['urls'] ?? '',
      username: json['username'],
      credential: json['credential'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'urls': urls};
    if (username != null) map['username'] = username;
    if (credential != null) map['credential'] = credential;
    return map;
  }
}
