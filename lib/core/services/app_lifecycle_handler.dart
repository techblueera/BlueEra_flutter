import 'dart:developer';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/chat/auth/controller/call_controller.dart';
import '../../features/chat/auth/controller/chat_view_controller.dart';
import '../../features/chat/auth/socket/chat_socket.dart';
import '../constants/app_constant.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {

    // Track foreground/background for incoming-call routing decisions.
    // _handleIncomingCall (socket, main isolate) reads this to decide
    // whether to also fire CallKit's IncomingCallActivity in addition to
    // navigating — navigation alone is invisible while the activity is
    // paused (background), so we need the full-screen intent to show UI.
    CallController.isAppInForeground = state == AppLifecycleState.resumed;

    // Handle floating call overlay on app lifecycle changes
    _handleCallOverlayLifecycle(state);

    if (state == AppLifecycleState.resumed) {
      // Reconnect chat socket if it was disconnected (e.g. after returning from CallActivity)
      _reconnectChatSocketIfNeeded();

      if (await LocationService().isLocationAvailable()) {
        log("Permission granted after returning from settings.");
        await LocationService.fetchLocation();
      }
    }
  }

  /// Reconnect the chat socket when the app resumes.
  /// On iOS, timers are paused while backgrounded, so the socket's own
  /// exponential backoff won't fire. This forces an immediate reconnect
  /// with backoff reset, which is critical for iOS returning from background.
  void _reconnectChatSocketIfNeeded() {
    // Skip reconnect entirely when the user isn't authenticated — the
    // app may be sitting on the login/onboarding screens, and we don't
    // want to open a socket against an empty token just because the user
    // backgrounded and resumed.
    if (!isLoggedIn()) return;

    // Force immediate reconnect on the raw socket (resets backoff)
    final chatSocket = ChatSocketService();
    if (!chatSocket.isConnected) {
      log("Chat socket not connected on resume — forcing immediate reconnect");
      chatSocket.reconnectNow();
    }

    // Also re-register listeners if controller exists and was disconnected
    if (!Get.isRegistered<ChatViewController>()) return;
    final chatViewController = Get.find<ChatViewController>();
    if (!chatViewController.socketConnected.value) {
      chatViewController.connectSocket();
    }

    // Re-register call socket listeners — disposeSocket() may have cleared
    // _registeredListeners while CallActivity was active, so call:incoming
    // and other call events would be lost on the new socket connection.
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().ensureCallSocketListeners();
    }
  }

  /// Show floating overlay when app goes to background during an active call,
  /// and hide it when the app returns to foreground.
  void _handleCallOverlayLifecycle(AppLifecycleState state) {
    if (!Get.isRegistered<CallController>()) return;
    final callController = Get.find<CallController>();

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background — show floating overlay if call is active
        callController.showFloatingOverlay();
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground — hide floating overlay
        callController.hideFloatingOverlay();
        // Reset CallActivity flag (activity may have finished)
        CallController.isCallActivityActive = false;
        break;
      case AppLifecycleState.detached:
        // App being killed — end call gracefully.
        // BUT: on Android, when we launch CallActivity (a second Flutter engine
        // that owns the live call), the main engine's MainActivity can transition
        // to `detached`. Ending the call here would kill the call that the
        // CallActivity engine is actively running. Skip if CallActivity is active.
        if (CallController.isCallActivityActive) {
          log("detached but CallActivity is active — skipping endCall");
          break;
        }
        final isActive = callController.callStatus.value == CallStatus.connected ||
            callController.callStatus.value == CallStatus.connecting;
        if (isActive) {
          callController.endCall();
        }
        break;
      default:
        break;
    }
  }
}
