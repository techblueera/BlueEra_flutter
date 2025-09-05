import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/shared_preference_utils.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  ChatSocketService._internal();

  late IO.Socket _socket;


  bool _isConnected = false;

  Future<void> connectToSocket() async {
    try {
      print("Attempting to connect to socket...");
      _socket = IO.io('http://13.203.208.120:3000/',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket')
            .enableForceNew()
            .setAuth({'token': '$authTokenGlobal'})
            .build(),
      );

      _socket.connect();
      _socket.onConnect((_) {
        print("Socket connected!");
        _isConnected = true;
        _socket.emit("screenRoom", {ApiKeys.conversation_id: "online"});
        _socket.emit("ChatList", {ApiKeys.type: "personal"});
          print("Socket connected!");

      });

      _socket.onConnectError((err) {
        print('Connect error: $err');

      });

      _socket.onDisconnect((_) => print('Disconnected'));


    } catch (e) {
      print("Socket connection failed: $e");
      rethrow;
    }
  }

  void emitEvent(String event, dynamic data) async{

    if (_isConnected) {
      _socket.emit(event, data);
    } else {
     await connectToSocket();
      _socket.emit(event, data);
      print("⚠ Cannot emit, socket not connected");
    }
  }
  void emitDisposeEvent(String event, dynamic data) async{

    if (_isConnected) {
      _socket.emit(event, data);
    } else {
      print("⚠ Cannot emit, socket not connected");
    }
  }

  void listenEvent(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  void disconnectSocket() {
    _socket.disconnect();
  }
  void disposeSocket() {
    _socket.dispose();
  }

  bool get isConnected => _isConnected;
}
