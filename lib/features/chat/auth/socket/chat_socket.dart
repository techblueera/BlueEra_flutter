import 'dart:async';
import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/services/pending_message_drainer.dart';
import '../../../../environment_config.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  ChatSocketService._internal();

  static IO.Socket? _socket;

  bool _isConnected = false;
  bool _isConnecting = false;

  // Exponential backoff for reconnection
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // Buffered listeners registered before socket was connected
  final List<MapEntry<String, Function(dynamic)>> _pendingListeners = [];

  // All registered listeners — kept so they can be re-registered on reconnect
  final List<MapEntry<String, Function(dynamic)>> _registeredListeners = [];

  /// Invoked on every successful (re)connect, AFTER listeners are re-registered
  /// and the standard `screenRoom` / `ChatList` emits fire. The chat controller
  /// uses this to re-fetch the currently-open conversation's messages: a
  /// `messageReceived` fetch emitted while the socket was still connecting —
  /// e.g. a cold start from a killed-state broadcast-notification tap — would
  /// otherwise be lost, leaving the thread empty until the user reopens it.
  void Function()? onConnected;

  /// Re-binds CallController's call/webrtc listeners after a fresh socket is
  /// built. disposeSocket() (ChatViewController teardown) wipes
  /// `_registeredListeners`, so the replay in onConnect has nothing to replay
  /// for call events — and CallController otherwise only re-registers on app
  /// RESUME. Without this hook an incoming call (`call:incoming`) after a
  /// mid-session socket rebuild is silently ignored: the rider's phone never
  /// rings. Set once by CallController.onInit; survives controller lifetime.
  void Function()? onCallListenersRebind;

  /// Re-binds ChatViewController's chat listeners after a fresh socket is
  /// built. Exactly the same problem as [onCallListenersRebind], which calls
  /// already had a fix for and chat did not:
  ///
  /// disposeSocket() clears `_registeredListeners` outright, so the replay in
  /// onConnect has nothing to replay for `newMessageReceived` / `ChatList` /
  /// `messageReceived`. The bottom-nav host disposes the socket on any root
  /// re-navigation (returning from a call, a notification renav, offAllNamed),
  /// and the ONLY thing that re-ran connectSocket() was an app RESUME. So live
  /// chat stayed dead — new messages appeared only after a manual refresh —
  /// until the user backgrounded and reopened the app.
  ///
  /// Set once by ChatViewController.connectSocket(); survives its lifetime.
  void Function()? onChatListenersRebind;

  // ─── Connect ───────────────────────────────────────────────────────────────

  Future<void> connectToSocket() async {
    // Don't open a socket session before the user has logged in. Without
    // this guard a cold-start (CallController.onInit → connectToSocket)
    // opens a socket with an empty `authTokenGlobal`, which still emits
    // `isOnlineFromChatList` / `ChatList` and the server replies with
    // `isOnLine` events — spamming the SOCKET_RAW log even on the auth
    // screens. Listeners registered before login are buffered in
    // `_pendingListeners` and replayed on the first authenticated
    // connect() (called from AuthController after token is populated).
    if (!isLoggedIn()) {
      return;
    }

    // If already connected, don't create a new socket
    if (_isConnected && _socket != null && _socket!.connected) {
      return;
    }

    // Prevent concurrent connect attempts from disposing an in-flight socket
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      // Dispose old socket if exists
      _socket?.dispose();


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
        //   log('[SOCKET_RAW] ⚡ ride event received → event=$event, data=$data');
        // }
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();

        // Re-register ALL known listeners on the new socket BEFORE emitting
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

        // Call listeners may have been wiped by disposeSocket() — the replay
        // above can't restore what was cleared. Re-bind them so incoming
        // calls ring again immediately, not only after the next app resume.
        try {
          onCallListenersRebind?.call();
        } catch (_) {}

        // Same for chat listeners — see [onChatListenersRebind]. Runs BEFORE
        // the ChatList / screenRoom emits below so the replies have somewhere
        // to land.
        try {
          onChatListenersRebind?.call();
        } catch (_) {}

        _socket!.emit(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
        _socket!.emit(ChatEmitEvents.isOnlineFromChatList, {});
        _socket!.emit(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});

        // Re-fetch the currently-open conversation (if any). Without this, a
        // fetch emitted before the socket finished connecting is dropped, so a
        // chat opened from a killed-state notification tap would stay empty.
        try {
          onConnected?.call();
        } catch (_) {}

        // Socket reconnect is also a strong signal that the network is back —
        // flush any pending chat messages in the background.
        unawaited(PendingMessageDrainer.instance.drainNow());
      });

      _socket!.onConnectError((err) {
        _isConnecting = false;
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        _isConnecting = false;
        _scheduleReconnect();
      });

    } catch (e) {
      _isConnecting = false;
print("SOCKET ERROR catch ${e}");
      rethrow;
    }
  }

  // ─── Generic Emit / Listen ─────────────────────────────────────────────────

  void emitEvent(String event, dynamic data) async {
    if (_socket != null) {
      // Socket exists — emit directly. If still connecting, socket_io
      // buffers the message and flushes it on connect.
      log("ksdjcksjcnksjcscd  88 ${data}");

      _socket!.emit(event, data);
    } else {
      // Skip the lazy-connect when logged out — connectToSocket() will
      // no-op anyway, but bailing here keeps the emit semantics obvious
      // for callers that fire from late teardown paths.
      if (!isLoggedIn()) return;
      await connectToSocket();
      log("ksdjcksjcnksjcscd 99 ${data}");

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
      // }
    } else {
      _pendingListeners.add(MapEntry(event, callback));
      // if (event.startsWith('ride:')) {
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
    _isConnecting = false;
    connectToSocket();
  }

  void disconnectSocket() {
    _socket?.disconnect();
  }

  void disposeSocket() {
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _registeredListeners.clear();
    _pendingListeners.clear();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _isConnected;
}
