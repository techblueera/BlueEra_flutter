import 'dart:async';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
        liveTrackSocket, // ex: https://map.beapp.in
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .setAuth({
          ApiKeys.token: authTokenGlobal, // JWT
        })
            .build(),
      );
      _socket.connect();
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
      });

      _socket.onDisconnect((_) {
        _isConnected = false;
      });
    } catch (e) {
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
