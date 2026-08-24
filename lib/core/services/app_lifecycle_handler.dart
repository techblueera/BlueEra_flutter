import 'dart:developer';

import 'package:BlueEra/core/services/app_notification.dart';
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

      // Consume a pending Accept/Decline from the native call notification.
      // CallActionReceiver stashes the action and launches the app; when the
      // app was merely BACKGROUNDED (not killed) main() never re-runs, so the
      // cold-start consumer never fires — the app just opened on top of a
      // still-ringing call and nothing happened. Consuming here also prevents
      // the stale action from replaying on the NEXT cold start and hitting a
      // long-dead call ("call no longer available").
      _consumePendingNativeCallAction();

      // Re-sync FCM token on resume — Google may rotate the token while the
      // app is backgrounded, and onTokenRefresh doesn't fire on a cold
      // foreground. Without this the backend keeps routing pushes to a dead
      // token, which is exactly why iOS notifications go silent after a long
      // background. Only attempt while authenticated.
      if (isLoggedIn()) {
        AppNotificationHandler.getFcmToken().then((t) {
          if (t != null && t.isNotEmpty) {
            AppNotificationHandler.syncCurrentToken(t);
          }
        });
        // iOS: re-register the VoIP/PushKit token too. Without a current VoIP
        // token on the server, incoming calls reach iOS only as plain FCM
        // banners that can't trigger CallKit in background/terminated state.
        AppNotificationHandler.syncVoipToken();
      }

      if (await LocationService().isLocationAvailable()) {
        log("Permission granted after returning from settings.");
        await LocationService.fetchLocation();
      }
    }
  }

  /// Warm-resume twin of main()'s cold-start pending-action consumer: run the
  /// Accept/Decline the user tapped on the native call notification while the
  /// app was backgrounded-but-alive.
  Future<void> _consumePendingNativeCallAction() async {
    try {
      final nativeAction = await readAndClearPendingNativeCallAction();
      if (nativeAction == null) return;

      final action = (nativeAction['action'] ?? '').toString();
      final callId = (nativeAction['callId'] ?? '').toString();
      final roomId = (nativeAction['roomId'] ?? '').toString();
      final isVideo = (nativeAction['callType'] ?? '') == 'video_call';
      if (callId.isEmpty) return;

      final pending = await readAndClearPendingIncomingCallExtras();
      final callController = Get.isRegistered<CallController>()
          ? Get.find<CallController>()
          : Get.put(CallController(), permanent: true);

      if (action == 'accept') {
        log('[RESUME_CALL] native notification accept → callId=$callId');
        // Seed caller name/image/context from the stashed extras when the
        // controller has no live state for this call (e.g. listeners were
        // down when call:incoming fired) — without this the call screen
        // shows "Unknown".
        if (pending != null && callController.callId.value != callId) {
          callController.initStateFromCallKitExtra(pending);
        }
        await callController.acceptCall(
          callIdParams: callId,
          roomIdParams: roomId,
          isVideoCall: isVideo,
        );
      } else if (action == 'decline') {
        log('[RESUME_CALL] native notification decline → callId=$callId');
        callController.declineCall();
      }
    } catch (e) {
      log('[RESUME_CALL] pending native action consume error: $e');
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
        break;
      case AppLifecycleState.detached:
        // App being killed — end call gracefully. This used to be guarded
        // against CallActivity's separate task (the main engine could go
        // `detached` while that engine held the live call); the call now runs
        // in this engine, so a detach really does mean the call is over.
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
