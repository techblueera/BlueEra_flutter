import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/shared_preference_utils.dart';

class SecChatSocketService {
  static final SecChatSocketService _instance = SecChatSocketService._internal();
  factory SecChatSocketService() => _instance;
  SecChatSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  Future<void> connectToSocket() async {
    try {
      print("Attempting to connect to socket...");

      // 🔑 Use correct wss:// URL and add token if needed
      final uri = Uri.parse(
        "wss://0oyj2o7af8.execute-api.ap-south-1.amazonaws.com/\$default?token=$authTokenGlobal",
      );

      _channel = WebSocketChannel.connect(uri);

      _isConnected = true;

      // Example: send initial messages after connection
      emitEvent("screenRoom", {ApiKeys.conversation_id: "online"});
      emitEvent("ChatList", {ApiKeys.type: "personal"});

      // Listen for messages
      _channel?.stream.listen(
            (message) {
          print("📩 Message received: $message");
        },
        onError: (err) {
          print("⚠️ Socket error: $err");
          _isConnected = false;
        },
        onDone: () {
          print("🔌 Socket closed");
          _isConnected = false;
        },
      );

      print("✅ WebSocket connected!");
    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      rethrow;
    }
  }

  void emitEvent(String event, dynamic data) {
    if (_isConnected && _channel != null) {
      final payload = jsonEncode({"event": event, "data": data});
      _channel?.sink.add(payload);
      print("📤 Sent: $payload");
    } else {
      print("⚠ Cannot emit, socket not connected");
    }
  }

  void listenEvent(Function(dynamic) callback) {
    _channel?.stream.listen(callback);
  }

  void disconnectSocket() {
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
