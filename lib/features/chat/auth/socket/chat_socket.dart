import 'dart:async';

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

  // Buffered listeners registered before socket was connected
  final List<MapEntry<String, Function(dynamic)>> _pendingListeners = [];

  Future<void> connectToSocket() async {
    try {
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
        _socket!.emit(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
        _socket!.emit(ChatEmitEvents.isOnlineFromChatList, {});
        _socket!.emit(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});

        // Replay any listeners that were registered before socket was ready
        for (final entry in _pendingListeners) {
          _socket!.on(entry.key, entry.value);
        }
        _pendingListeners.clear();
      });

      _socket!.onConnectError((err) {
        print('Chat Socket Connect error: $err');
      });

      _socket!.onDisconnect((_) => print('Disconnected'));

    } catch (e) {
      print("Socket connection failed: $e");
      rethrow;
    }
  }

  void emitEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
      await connectToSocket();
      _socket?.emit(event, data);
      print("⚠ Cannot emit, socket not connected");
    }
  }

  void emitDisposeEvent(String event, dynamic data) async {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
    } else {
      print("⚠ Cannot emit, socket not connected");
    }
  }

  void listenEvent(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    } else {
      // Buffer until socket connects
      _pendingListeners.add(MapEntry(event, callback));
    }
  }

  void disconnectSocket() {
    _socket?.disconnect();
  }

  void disposeSocket() {
    _socket?.dispose();
  }

  bool get isConnected => _isConnected;
}
