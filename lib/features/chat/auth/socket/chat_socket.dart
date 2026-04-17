import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../environment_config.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  ChatSocketService._internal();

  static IO.Socket? _socket;

  bool _isConnected = false;

  // Exponential backoff for reconnection
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // Buffered listeners registered before socket was connected
  final List<MapEntry<String, Function(dynamic)>> _pendingListeners = [];

  // All registered listeners — kept so they can be re-registered on reconnect
  final List<MapEntry<String, Function(dynamic)>> _registeredListeners = [];

  // ─── Connect ───────────────────────────────────────────────────────────────

  Future<void> connectToSocket() async {
    // If already connected, don't create a new socket
    if (_isConnected && _socket != null && _socket!.connected) {
      return;
    }

    try {
      // Dispose old socket if exists
      _socket?.dispose();

      debugPrint('[SOCKET_DEBUG] 🔌 Connecting to chatSocketUrl=$chatSocketUrl');
      debugPrint('[SOCKET_DEBUG] 🔌 authToken present=${authTokenGlobal != null && authTokenGlobal!.isNotEmpty}');

      _socket = IO.io(chatSocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket')
            .enableForceNew()
            .setAuth({
              'token': '$authTokenGlobal',
            })
            .build(),
      );

      _socket!.connect();

      // Debug: log ALL ride-related events from backend at raw socket level
      _socket!.onAny((event, data) {
        // if (event.toString().startsWith('ride:')) {
          debugPrint('[SOCKET_RAW] ⚡ ride event received → event=$event, data=$data');
        // }
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();

        debugPrint('[SOCKET_DEBUG] ✅ Connected to $chatSocketUrl, socketId=${_socket?.id}');
        debugPrint('[SOCKET_DEBUG] ✅ Re-registering ${_registeredListeners.length} listeners + ${_pendingListeners.length} pending');
        debugPrint('[SOCKET_DEBUG] ✅ Registered events: ${_registeredListeners.map((e) => e.key).toList()}');

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
        debugPrint('[SOCKET_DEBUG] ✅ All listeners registered, total=${_registeredListeners.length}');
        _pendingListeners.clear();
      });

      _socket!.onConnectError((err) {
        debugPrint('[SOCKET_DEBUG] ❌ Connection error to $chatSocketUrl → $err');
      });

      _socket!.onDisconnect((reason) {
        debugPrint('[SOCKET_DEBUG] ⚠️ Disconnected from $chatSocketUrl, reason=$reason, registered listeners=${_registeredListeners.length}');
        _isConnected = false;
        _scheduleReconnect();
      });

    } catch (e) {
print("SOCKET ERROR catch ${e}");
      rethrow;
    }
  }

  // ─── Generic Emit / Listen ─────────────────────────────────────────────────

  void emitEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
      await connectToSocket();
      _socket?.emit(event, data);

    }
  }

  void emitDisposeEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
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
      // if (event.startsWith('ride:')) {
        debugPrint('[SOCKET_DEBUG] 📡 listenEvent registered: $event (socket connected=$_isConnected, socketId=${_socket?.id})');
      // }
    } else {
      _pendingListeners.add(MapEntry(event, callback));
      // if (event.startsWith('ride:')) {
        debugPrint('[SOCKET_DEBUG] ⏳ listenEvent QUEUED (socket is null): $event');
      // }
    }
  }

  // ─── Reconnect ─────────────────────────────────────────────────────────────

  /// Exponential backoff reconnect: 2s, 4s, 8s, 16s, 32s then stops.
  void _scheduleReconnect() {
    if (_socket == null) return;
    if (_isConnected) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts); // 2, 4, 8, 16, 32
    _reconnectAttempts++;


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
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _registeredListeners.clear();
    _pendingListeners.clear();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _isConnected;
}
