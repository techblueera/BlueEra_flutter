import 'dart:async';

import 'package:BlueEra/core/constants/common_methods.dart';
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

  Future<void> connectToSocket() async {

    // If already connected, don't create a new socket
    if (_isConnected && _socket != null && _socket!.connected) {
      return;
    }

    try {
      // Dispose old socket if exists
      _socket?.dispose();

      _socket = IO.io(chatSocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket')
            .enableForceNew()
            .setAuth({'token': '$authTokenGlobal'})
            .build(),
      );

      _socket!.connect();
      _socket!.onConnect((_) {
        _isConnected = true;
        _reconnectAttempts = 0; // Reset backoff on successful connection
        _reconnectTimer?.cancel();
        _socket!.emit(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
        _socket!.emit(ChatEmitEvents.isOnlineFromChatList, {});
        _socket!.emit(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});

        // Re-register ALL known listeners on the new socket.
        // First off() each event to avoid duplicates — listenEvent() may have
        // already called _socket!.on() between connect() and onConnect().
        for (final entry in _registeredListeners) {
          _socket!.off(entry.key);
          _socket!.on(entry.key, entry.value);
        }

        // Replay any listeners that were registered before socket was ready
        for (final entry in _pendingListeners) {
          _socket!.off(entry.key);
          _socket!.on(entry.key, entry.value);
          _registeredListeners.add(entry);
        }
        _pendingListeners.clear();
      });

      _socket!.onConnectError((err) {
        if (kDebugMode) print('Chat Socket Connect error: $err');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) print('Chat socket disconnected');
        _scheduleReconnect();
      });

    } catch (e) {
      if (kDebugMode) print("Socket connection failed: $e");
      rethrow;
    }
  }

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

    // Also remove from the live socket before re-registering
    _socket?.off(event);

    // Track all listeners so they survive socket reconnections
    _registeredListeners.add(MapEntry(event, callback));

    if (_socket != null) {
      _socket!.on(event, callback);
    } else {
      // Buffer until socket connects
      _pendingListeners.add(MapEntry(event, callback));
    }
  }

  /// Exponential backoff reconnect: 2s, 4s, 8s, 16s, 32s then stops.
  /// Works on both iOS and Android. On iOS, timers pause when backgrounded
  /// but fire immediately on resume — AppLifecycleHandler also triggers
  /// reconnect on resume as a safety net.
  void _scheduleReconnect() {
    if (_socket == null) return; // Intentionally disposed — don't reconnect
    if (_isConnected) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) print('Chat socket max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts); // 2, 4, 8, 16, 32
    _reconnectAttempts++;

    if (kDebugMode) print('Chat socket reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () {
      if (_socket != null && !_isConnected) {
        connectToSocket();
      }
    });
  }

  /// Force an immediate reconnect — called from AppLifecycleHandler on resume.
  /// Resets backoff so the connection is re-established quickly after iOS
  /// returns from background (where timers were paused).
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
