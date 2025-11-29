import 'dart:developer';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/constants/shared_preference_utils.dart';

class AiSocketService {
  static final AiSocketService _instance = AiSocketService._internal();
  factory AiSocketService() => _instance;
  AiSocketService._internal();

  IO.Socket? socket;

  // SOCKET URL (Your Backend)
  final String aiSocketUrl = "http://prod-be-alb-blueera-1403294632.ap-south-1.elb.amazonaws.com:1029";
  Future<void> disposeSocket()async{
    socket?.disconnect();
    socket?.dispose();
  }
  // CONNECT SOCKET
  Future<void> connect() async {

    if (socket != null && socket!.connected) return;

    socket = IO.io(
      aiSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': authTokenGlobal}) // IMPORTANT FIX
          .build(),
    );

    // Connect
    await socket!.connect();

    // GLOBAL LISTENERS
    socket!.onConnect((_) {
    });

    socket!.onDisconnect((_) {
    });

    socket!.onConnectError((data) {
    });

    socket!.onError((data) {
    });
  }

  // JOIN ROOM
  void joinConversation(String conversationId) {
    socket?.emit('join_conversation', {"conversationId": conversationId});
  }

  // GET HISTORY
  void getHistory(String conversationId) {
    socket?.emit('get_history', {"conversationId": conversationId});
  }

  // LISTEN HISTORY RESPONSE
  void onHistory(void Function(dynamic messages) callback) {
    socket?.on('history_data', (data) {
      callback(data);
    });
  }

  // LISTEN AI STATUS
  void onAIStatus(void Function(String status) callback) {
    socket?.on('ai_status', (data) {
      callback(data["status"]);
    });
  }

  // SEND MESSAGE
  void sendMessage({
    String? conversationId,
    String? message,
    Uint8List? imageBytes,
    String? mimeType,
  }) {
    socket?.emit('send_message', {
      "message": message,
      if(conversationId!=null)
      "conversationId": conversationId,
      "fileData": imageBytes,
      "mimeType": mimeType
    });
  }

  // LISTEN REPLY MESSAGE
  void onMessage(void Function(dynamic data) callback) {
    socket?.on('receive_message', (data) {
      callback(data);
    });
  }

  // LISTEN ERRORS
  void onError(void Function(String error) callback) {
    socket?.on('error', (data) {
      callback(data["message"]);
    });
  }

}
