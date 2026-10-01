import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  static IO.Socket? _socket;
  bool _isConnected = false;

  /// Who is using the socket: the user sharing their own live location
  /// ([holderSharer]) and/or the one viewing someone else's ([holderViewer]).
  ///
  /// Both used to share one socket with no bookkeeping: every connect built a
  /// NEW socket (forceNew) and dropped the old one still connected and
  /// reconnecting forever, and closing a live-location view disconnected the
  /// socket a running share was still sending on. Now a connect reuses the
  /// live socket, each holder releases only its own claim, and the socket
  /// closes when nobody holds it.
  final Set<String> _holders = {};

  static const String holderSharer = 'sharer';
  static const String holderViewer = 'viewer';

  /// The last position sent as `[lng, lat]`, re-announced on every
  /// (re)connect so the server's view resumes from where the rider actually
  /// is rather than from where they were when the socket was first opened.
  List<double>? _lastCoordinates;

  Future<void> connectToSocket(LatLng? currentPos,
      {required String holder}) async {
    try {
      _holders.add(holder);
      if (currentPos != null) {
        _lastCoordinates = [currentPos.longitude, currentPos.latitude];
      }
      final existing = _socket;
      if (existing != null) {
        // Already open for the other holder: reuse it. A fresh position is
        // announced now if connected, otherwise by onConnect below.
        final coordinates = _lastCoordinates;
        if (currentPos != null && _isConnected && coordinates != null) {
          existing.emit(LiveTrackEmitEvents.updateLocation, {
            ApiKeys.coordinates: coordinates,
            ApiKeys.availabilityStatus: "OPEN",
          });
        }
        return;
      }
      final socket = IO.io(
        liveTrackSocket, // ex: https://map.beapp.in
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            // Reconnect with backoff (1s up to 30s) when the front door drops
            // the socket; pings stay at the socket.io defaults.
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(30000)
            .setAuth({
          ApiKeys.token: authTokenGlobal, // JWT
        })
            .build(),
      );
      _socket = socket;
      socket.connect();
      socket.onConnect((_) {
        _isConnected = true;

        final coordinates = _lastCoordinates;
        if (coordinates != null) {
          socket.emit(
              LiveTrackEmitEvents.updateLocation,
              {
                ApiKeys.coordinates: coordinates,
                ApiKeys.availabilityStatus: "OPEN",
              }
          );
        }

      });
      socket.onConnectError((err) {
      });

      socket.onDisconnect((_) {
        _isConnected = false;
      });
    } catch (e) {
      rethrow;
    }
  }

  // 📤 Emit event (auto-connect if needed)
  Future<void> emitEvent(String event, dynamic data) async {
    if (event == LiveTrackEmitEvents.updateLocation && data is Map) {
      final coordinates = data[ApiKeys.coordinates];
      if (coordinates is List && coordinates.length >= 2) {
        _lastCoordinates = [
          (coordinates[0] as num).toDouble(),
          (coordinates[1] as num).toDouble(),
        ];
      }
    }
    // if (_isConnected) {
      _socket?.emit(event, data);
    // } else {
    //   await connectToSocket(null);
    //   _socket.emit(event, data);
    // }
  }

  // 📤 Emit only if connected (no reconnect)
  void emitDisposeEvent(String event, dynamic data) {
    if (_isConnected) {
      _socket?.emit(event, data);
    } else {
    }
  }

  // 📥 Listen event
  void listenEvent(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // ❌ Remove listener
  void offEvent(String event) {
    _socket?.off(event);
  }

  /// Releases [holder]'s claim; the socket closes once no one holds it.
  void disconnectSocket({required String holder}) {
    _holders.remove(holder);
    if (_holders.isEmpty) disposeSocket();
  }

  /// Closes the socket outright, whoever holds it.
  void disposeSocket() {
    _socket?.dispose();
    _socket = null;
    _holders.clear();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
