import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mappls_gl/mappls_gl.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../environment_config.dart';

class LiveTrackingSocketService {
  static final LiveTrackingSocketService _instance =
  LiveTrackingSocketService._internal();

  factory LiveTrackingSocketService() => _instance;

  LiveTrackingSocketService._internal();

  static late IO.Socket _socket;
  bool _isConnected = false;

  Future<void> connectToSocket(LatLng? currentPos) async {
    try {
      _socket = IO.io(
        liveTrackSocket, // ex: https://map.blueera.ai
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .setAuth({
          ApiKeys.token: authTokenGlobal, // JWT
        })
            .build(),
      );
      _socket.connect();
      print("✅ LiveTracking socket connected jjj");
      _socket.onConnect((_) {
        _isConnected = true;

        if(currentPos!=null){
          _socket.emit(
              LiveTrackEmitEvents.updateLocation,
              {
                ApiKeys.coordinates: [currentPos.longitude,currentPos.latitude],
                ApiKeys.availabilityStatus: "OPEN",
              }
          );
        }

      });
      _isConnected = true;
      _socket.onConnectError((err) {
        print("❌ LiveTracking socket connect error: $err");
      });

      _socket.onDisconnect((_) {
        _isConnected = false;
        print("🔌 LiveTracking socket disconnected");
      });
    } catch (e) {
      print("🔥 LiveTracking socket connection failed: $e");
      rethrow;
    }
  }

  // 📤 Emit event (auto-connect if needed)
  Future<void> emitEvent(String event, dynamic data) async {
    // if (_isConnected) {
      _socket.emit(event, data);
    // } else {
    //   await connectToSocket(null);
    //   _socket.emit(event, data);
    // }
  }

  // 📤 Emit only if connected (no reconnect)
  void emitDisposeEvent(String event, dynamic data) {
    if (_isConnected) {
      _socket.emit(event, data);
    } else {
      print("⚠ LiveTracking socket not connected");
    }
  }

  // 📥 Listen event
  void listenEvent(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  // ❌ Remove listener
  void offEvent(String event) {
    _socket.off(event);
  }

  // 🔌 Disconnect
  void disconnectSocket() {
    _socket.disconnect();
  }

  // 🧹 Dispose
  void disposeSocket() {
    _socket.dispose();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
