import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/services/e2e/e2e_key_service.dart';
import '../../../../environment_config.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  ChatSocketService._internal();

  static IO.Socket? _socket;

  bool _isConnected = false;

  // Resolved protocol version after handshake ('e2e' | 'plain')
  String _resolvedProtocol = 'plain';
  String get resolvedProtocol => _resolvedProtocol;
  bool   get isE2EEnabled    => _resolvedProtocol == 'e2e';

  // Exponential backoff for reconnection
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // Buffered listeners registered before socket was connected
  final List<MapEntry<String, Function(dynamic)>> _pendingListeners = [];

  // All registered listeners — kept so they can be re-registered on reconnect
  final List<MapEntry<String, Function(dynamic)>> _registeredListeners = [];

  // Callbacks for E2E events (set by ChatViewController after socket connects)
  Function(Map<String, dynamic>)? _onE2EMessageNew;
  Function(Map<String, dynamic>)? _onE2EMessageStatus;
  Function(Map<String, dynamic>)? _onE2ESyncComplete;
  Function(int remainingCount)?    _onPrekeyLow;
  Function(String protocol)?       _onProtocolResolved;

  // ─── Connect ───────────────────────────────────────────────────────────────

  Future<void> connectToSocket() async {
    // If already connected, don't create a new socket
    if (_isConnected && _socket != null && _socket!.connected) {
      return;
    }

    try {
      // Dispose old socket if exists
      _socket?.dispose();

      // Fetch device ID for E2E capability handshake
      final deviceId = await E2EKeyService().getOrCreateDeviceId();

      _socket = IO.io(chatSocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket')
            .enableForceNew()
            .setAuth({
              'token':        '$authTokenGlobal',
              // Phase 1: signal E2E capability to server
              'capabilities': {'e2e': true},
              'deviceId':     deviceId,
            })
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        _isConnected = true;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();

        _socket!.emit(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
        _socket!.emit(ChatEmitEvents.isOnlineFromChatList, {});
        _socket!.emit(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});

        // Re-register ALL known listeners on the new socket
        for (final entry in _registeredListeners) {
          _socket!.off(entry.key);
          _socket!.on(entry.key, entry.value);
        }

        // Replay pending listeners
        for (final entry in _pendingListeners) {
          _socket!.off(entry.key);
          _socket!.on(entry.key, entry.value);
          _registeredListeners.add(entry);
        }
        _pendingListeners.clear();

        // Attach E2E protocol + message events
        _attachE2EListeners();
      });

      _socket!.onConnectError((err) {
        if (kDebugMode) print('Chat Socket Connect error: $err');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _resolvedProtocol = 'plain';
        if (kDebugMode) print('Chat socket disconnected');
        _scheduleReconnect();
      });

    } catch (e) {
      if (kDebugMode) print("Socket connection failed: $e");
      rethrow;
    }
  }

  // ─── E2E Event Listeners ───────────────────────────────────────────────────

  void _attachE2EListeners() {
    // Phase 1: Protocol resolved after connection
    _socket!.off(ChatEmitEvents.e2eProtocolResolved);
    _socket!.on(ChatEmitEvents.e2eProtocolResolved, (data) {
      final d = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      _resolvedProtocol = (d['version'] as String?) ?? 'plain';
      if (kDebugMode) print('[E2E] Protocol resolved: $_resolvedProtocol');
      _onProtocolResolved?.call(_resolvedProtocol);
    });

    // Phase 1: Upgrade nudge for plain clients (informational only)
    _socket!.off(ChatEmitEvents.e2eProtocolUpgrade);
    _socket!.on(ChatEmitEvents.e2eProtocolUpgrade, (data) {
      final d = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      if (kDebugMode) print('[E2E] Upgrade available: ${d['message']}');
    });

    // Phase 2: OPK pool running low — replenish
    _socket!.off(ChatEmitEvents.e2ePrekeyLow);
    _socket!.on(ChatEmitEvents.e2ePrekeyLow, (data) {
      final d = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final remaining = (d['remainingCount'] as int?) ?? 0;
      if (kDebugMode) print('[E2E] prekey:low — remaining: $remaining');
      _onPrekeyLow?.call(remaining);
    });

    // Phase 3: New encrypted message received
    _socket!.off(ChatEmitEvents.e2eMessageNew);
    _socket!.on(ChatEmitEvents.e2eMessageNew, (data) {
      if (kDebugMode) print('[E2E] message:new received');
      if (data is Map) {
        _onE2EMessageNew?.call(Map<String, dynamic>.from(data));
      }
    });

    // Phase 3: Message delivery status
    _socket!.off(ChatEmitEvents.e2eMessageStatus);
    _socket!.on(ChatEmitEvents.e2eMessageStatus, (data) {
      if (kDebugMode) print('[E2E] message:status: ${data['status']}');
      if (data is Map) {
        _onE2EMessageStatus?.call(Map<String, dynamic>.from(data));
      }
    });

    // Phase 4: Server confirms sync cursor persisted
    _socket!.off(ChatEmitEvents.e2eSyncComplete);
    _socket!.on(ChatEmitEvents.e2eSyncComplete, (data) {
      if (kDebugMode) {
        print('[E2E] sync:complete — conversation ${data['conversation_id']} at seq ${data['seq_num']}');
      }
      if (data is Map) {
        _onE2ESyncComplete?.call(Map<String, dynamic>.from(data));
      }
    });
  }

  // ─── Register E2E Callbacks ────────────────────────────────────────────────

  /// Register callback for new E2E messages (message:new).
  void onE2EMessageNew(Function(Map<String, dynamic>) callback) {
    _onE2EMessageNew = callback;
  }

  /// Register callback for message status updates (message:status).
  void onE2EMessageStatus(Function(Map<String, dynamic>) callback) {
    _onE2EMessageStatus = callback;
  }

  /// Register callback for sync:complete acknowledgements.
  void onE2ESyncComplete(Function(Map<String, dynamic>) callback) {
    _onE2ESyncComplete = callback;
  }

  /// Register callback for prekey:low events (replenish OPKs).
  void onPrekeyLow(Function(int remainingCount) callback) {
    _onPrekeyLow = callback;
  }

  /// Register callback for protocol:resolved (to know if E2E is active).
  void onProtocolResolved(Function(String protocol) callback) {
    _onProtocolResolved = callback;
  }

  // ─── E2E Emit Methods ──────────────────────────────────────────────────────

  /// Phase 3: Send an encrypted message via `message:send`.
  ///
  /// [ciphertextEntries] — list of {deviceId, body} per recipient device.
  /// [encryptedMediaRefs] — optional list of {s3_key, mime_type, size}.
  void sendEncryptedMessage({
    required String conversationId,
    required List<Map<String, String>> ciphertextEntries,
    List<Map<String, dynamic>>? encryptedMediaRefs,
  }) {
    final payload = <String, dynamic>{
      'conversation_id': conversationId,
      'type':            'e2e',
      'ciphertext':      ciphertextEntries,
    };
    if (encryptedMediaRefs != null && encryptedMediaRefs.isNotEmpty) {
      payload['encrypted_media'] = encryptedMediaRefs;
    }
    emitEvent(ChatEmitEvents.e2eMessageSend, payload);
  }

  /// Phase 3: Send delivery acknowledgement (`message:ack`).
  void sendMessageAck(String messageId) {
    emitEvent(ChatEmitEvents.e2eMessageAck, {'message_id': messageId});
  }

  /// Phase 4: Notify server that sync is complete — persists the cursor.
  void sendSyncComplete({
    required String conversationId,
    required int seqNum,
    required String deviceId,
  }) {
    emitEvent(ChatEmitEvents.e2eMessageSyncComplete, {
      'conversation_id': conversationId,
      'seq_num':         seqNum,
      'deviceId':        deviceId,
    });
  }

  // ─── Generic Emit / Listen ─────────────────────────────────────────────────

  void emitEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
      await connectToSocket();
      _socket?.emit(event, data);
      if (kDebugMode) print("⚠ Cannot emit, socket not connected");
    }
  }

  void emitDisposeEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
      if (kDebugMode) print("⚠ Cannot emit, socket not connected");
    }
  }

  void listenEvent(String event, Function(dynamic) callback) {
    // Remove any existing listener for this event to prevent duplicates
    _registeredListeners.removeWhere((entry) => entry.key == event);
    _pendingListeners.removeWhere((entry) => entry.key == event);

    _socket?.off(event);

    _registeredListeners.add(MapEntry(event, callback));

    if (_socket != null) {
      _socket!.on(event, callback);
    } else {
      _pendingListeners.add(MapEntry(event, callback));
    }
  }

  // ─── Reconnect ─────────────────────────────────────────────────────────────

  /// Exponential backoff reconnect: 2s, 4s, 8s, 16s, 32s then stops.
  void _scheduleReconnect() {
    if (_socket == null) return;
    if (_isConnected) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) print('Chat socket max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts); // 2, 4, 8, 16, 32
    _reconnectAttempts++;

    if (kDebugMode) {
      print('Chat socket reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    }
    _reconnectTimer = Timer(delay, () {
      if (_socket != null && !_isConnected) {
        connectToSocket();
      }
    });
  }

  /// Force an immediate reconnect — called from AppLifecycleHandler on resume.
  void reconnectNow() {
    if (_isConnected) return;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    connectToSocket();
  }

  void disconnectSocket() {
    _socket?.disconnect();
  }

  void disposeSocket() {
    _isConnected = false;
    _resolvedProtocol = 'plain';
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _registeredListeners.clear();
    _pendingListeners.clear();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _isConnected;
}
