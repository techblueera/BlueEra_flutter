// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/local_strorage_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart' as dio;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:permission_handler/permission_handler.dart';

import '../../features/chat/auth/controller/call_controller.dart';
import '../../features/common/Discover/controller/discover_controller.dart';
import '../../features/chat/view/ai_chat/view/ai_chat_screen.dart';
import '../routes/route_helper.dart';
import '../routes/route_constant.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';

String notificationSound = 'sound/hangouts_call.mp3';
String hello_delivery = 'sound/hello_delivery.mp3';
String chatNotificationSound = 'sound/messenger.mp3';

/// Top-level handler for background notification actions (inline reply, mark as read, etc.)
/// Must be a top-level or static function for flutter_local_notifications
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // Delegate to async handler — use .then() to keep isolate alive until complete
  _handleBackgroundNotificationResponse(response)
      .then((_) {})
      .catchError((_) {});
}

/// Top-level handler for FOREGROUND notification taps. Required as a separate
/// top-level (not a closure) because we register the same callback from multiple
/// initialize() sites — the main isolate's `getInitialMsg`, and the FCM
/// background isolate's `showIncomingCallLocalNotification`. flutter_local_notifications
/// keeps only the LAST registered callback per process; without this top-level
/// fallback, the bg-isolate's initialize() overwrote the closure registered by
/// getInitialMsg(), so tapping "Accept" in foreground/background did nothing
/// (notification was dismissed but acceptCall was never invoked).
@pragma('vm:entry-point')
void onForegroundNotificationResponse(NotificationResponse response) {
  try {
    if (response.payload == null) return;
    final data = json.decode(response.payload!) as Map<String, dynamic>;
    final actionId = response.actionId ?? '';
    print("actionId==== ${actionId}");
    // Incoming call: Accept (Android local-notification path)
    if (actionId.startsWith('incoming_call_accept_')) {
      final callId = (data['callId'] ?? '').toString();
      final roomId = (data['roomId'] ?? '').toString();
      final isVideo = (data['callType'] ?? '') == 'video_call';
      cancelIncomingCallLocalNotification(callId);
      if (Get.isRegistered<CallController>()) {
        final ctrl = Get.find<CallController>();
        ctrl.initStateFromCallKitExtra(data);
        ctrl.acceptCall(
          callIdParams: callId,
          roomIdParams: roomId,
          isVideoCall: isVideo,
        );
      }
      return;
    }

    // Incoming call: Decline
    print(
        "Get.isRegistered<CallController>()=== ${Get.isRegistered<CallController>()}");
    if (actionId.startsWith('incoming_call_decline_')) {
      final callId = (data['callId'] ?? '').toString();
      cancelIncomingCallLocalNotification(callId);
      if (Get.isRegistered<CallController>()) {
        print("CALL END=====");
        Get.find<CallController>().declineCall();
      }
      return;
    }

    // Fare ride: Decline — just dismiss the notification
    if (actionId == 'fare_ride_decline') {
      return;
    }

    // Fare ride: View — open the rider order screen
    if (actionId == 'fare_ride_view') {
      AppNotificationHandler()._showRiderOrderScreen(data);
      return;
    }

    // Ongoing call hangup
    if (actionId == 'hangup_call') {
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().endCall();
      }
      return;
    }

    // Active call notification body tap → return to call screen
    if (data['action'] == 'open_active_call') {
      Get.toNamed('/CallRoomScreen');
      return;
    }

    // Default: existing action-button + tap routing
    if (actionId.isNotEmpty) {
      AppNotificationHandler._handleActionButtonTap(
        actionId,
        data,
        replyText: (response.input != null && response.input!.isNotEmpty)
            ? response.input
            : null,
      );
    } else {
      AppNotificationHandler._onTapNotificationFromStatusBar(data);
    }
  } catch (e, st) {
    print('onForegroundNotificationResponse error: $e\n$st');
  }
}

Future<void> _handleBackgroundNotificationResponse(
    NotificationResponse response) async {
  print("NOTI 1 ");
  print("NOTI 1 ${response}");
  print("NOTI 2 ${response.payload == null}");
  if (response.payload == null) return;
  final data = json.decode(response.payload!) as Map<String, dynamic>;
  logs("NOTIFICATION DATA 1 ${data}");
  final actionId = response.actionId ?? '';

  // Initialize a local plugin instance (background isolate may not have the static one)
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // --- Fare ride: Decline — just cancel the notification ---
  if (actionId == 'fare_ride_decline') {
    await plugin.cancel(response.id ?? 0);
    return;
  }

  // --- Fare ride: View — showsUserInterface: true brings the app to foreground,
  // the default tap handler (_onTapNotificationFromStatusBar) will route it ---
  if (actionId == 'fare_ride_view') {
    // App opens via showsUserInterface: true — tap routing handles navigation
    return;
  }

  // --- Incoming call: Decline (no app open required) ---
  // Cancel the notification, drop the stashed extras, and POST a decline so
  // the caller sees the rejection. We can't navigate or hit GetX from the
  // bg isolate, so use a direct REST call.
  if (actionId.startsWith('incoming_call_decline_')) {
    final callId = (data['callId'] ?? '').toString();
    final roomId = (data['roomId'] ?? '').toString();
    if (callId.isNotEmpty) {
      await plugin.cancel(incomingCallNotificationId(callId));
    }
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: _kPendingIncomingCallExtrasKey);
      final token = await storage.read(key: SharedPreferenceUtils.authToken);
      if (token != null && token.isNotEmpty && callId.isNotEmpty) {
        // Use call service base URL (matches foreground CallRepo).
        // Hardcoded because `callBaseUrl` global isn't initialized in the
        // FCM/notification background isolate.
        final apiUrl =
            (callBaseUrl ?? 'https://call.beapp.in/') + 'call/decline';
        final dioClient = dio.Dio();
        await dioClient.post(
          apiUrl,
          data: {'call_id': callId, 'room_id': roomId},
          options: dio.Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'X-Device-Type': 'mobile',
            },
          ),
        );
      }
    } catch (e) {
      print('Incoming call decline API error: $e');
    }
    // Also end the CallKit/native UI if it's still showing for this call.
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
    return;
  }

  // --- Incoming call: Accept (app opens, CallController auto-accepts) ---
  // The action's `showsUserInterface: true` brings MainActivity to the
  // foreground (or cold-starts it). Mark a "user tapped Accept" flag in
  // secure storage — main()'s cold-start check reads it to decide whether
  // to auto-invoke acceptCall vs. routing the notification body tap (which
  // would open chat). Action-button launches don't reliably surface the
  // actionId via getNotificationAppLaunchDetails on Android, so we have to
  // signal this explicitly from the bg isolate at tap time.
  if (actionId.startsWith('incoming_call_accept_')) {
    final callId = (data['callId'] ?? '').toString();
    if (callId.isNotEmpty) {
      await markPendingIncomingCallAccepted(callId);
    }
    return;
  }

  // --- Inline reply (WhatsApp-style, no app open) ---
  if (actionId.startsWith('reply_message_') &&
      response.input != null &&
      response.input!.isNotEmpty) {
    final conversationId = data['conversationId'] ?? '';
    // Send reply via REST API (works in background isolate without GetX context)
    await _sendReplyViaApi(
        conversationId: conversationId, message: response.input!);
    // Update notification to show sent reply (no sound/vibration)
    await plugin.show(
      response.id ?? 0,
      data['senderName'] ?? data['title'] ?? '',
      'You: ${response.input}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default',
          'General Notifications',
          channelDescription: '',
          importance: Importance.low,
          icon: '@drawable/ic_stat',
          playSound: false,
          enableVibration: false,
        ),
      ),
    );
    return;
  }

  // --- Mark as read — dismiss notification silently ---
  if (actionId.startsWith('mark_read_')) {
    await plugin.cancel(response.id ?? 0);
    return;
  }

  // --- Chat actions (view chat / view conversation) ---
  if (actionId.startsWith('view_chat_') ||
      actionId.startsWith('view_conversation_')) {
    final senderId = data['senderId'] ?? '';
    if (senderId.isNotEmpty) {
      final chatViewController = getOrPut(() => ChatViewController());

      chatViewController.connectSocket();
      Future.delayed(const Duration(milliseconds: 200), () {
        chatViewController.checkChatConnectionAndOpenChat(userId: senderId);
      });
    }
    return;
  }

  // --- Connection actions ---
  if (actionId.startsWith('accept_connection_') ||
      actionId.startsWith('decline_connection_') ||
      actionId.startsWith('view_profile_') ||
      actionId.startsWith('message_')) {
    Get.toNamed(RouteHelper.getNotificationScreenRoute());
    return;
  }

  // --- Route-order claim (ROUTE_ORDER_AVAILABLE) ---
  if (actionId.startsWith('claim_order_')) {
    AppNotificationHandler._handleClaimOrder(
        actionId.substring('claim_order_'.length));
    return;
  }

  // --- Ride actions ---
  if (actionId.startsWith('track_ride_') ||
      actionId.startsWith('view_order_') ||
      actionId.startsWith('accept_order_') ||
      actionId.startsWith('contact_rider_')) {
    Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
    return;
  }

  // --- Post / Reel actions ---
  if (actionId.startsWith('view_post_') ||
      actionId.startsWith('view_comment_') ||
      actionId.startsWith('view_reel_') ||
      actionId.startsWith('view_response_')) {
    Get.toNamed(RouteHelper.getNotificationScreenRoute());
    return;
  }

  // --- Chat-dispatch rider OTP nudge (before AI-greeting open_chat) ---
  if (actionId.startsWith('open_chat_') &&
      (data['type'] ?? data['operation'] ?? '').toString().toLowerCase() ==
          'rider_otp') {
    AppNotificationHandler._openChatFromRiderOtp(data);
    return;
  }

  // --- AI greeting actions ---
  if (actionId.startsWith('open_chat_')) {
    final chat = ChatViewController.personalAiChatModule;
    Get.to(() => AiChatScreen(
          profileImage: chat?.sender?.profileImage,
          name: chat?.sender?.name,
          type: chat?.sender?.accountType,
        ));
    return;
  }

  // --- Default: if no action matched, treat as regular notification tap ---
  if (actionId.isEmpty && response.payload != null) {
    AppNotificationHandler._onTapNotificationFromStatusBar(data);
  }
}

/// Deterministic local-notification id for an incoming call.
/// Same callId → same notification id, so re-deliveries replace cleanly and
/// cancel-by-id always finds the right notification.
int incomingCallNotificationId(String callId) =>
    callId.isEmpty ? 99001 : (callId.hashCode & 0x7FFFFFFF);

/// SharedPreferences-backed stash of the last incoming call's extras so that
/// when the user taps "Accept" while the app is killed/background, the
/// Accept action launches MainActivity and CallController can read these on
/// boot to auto-accept (mirrors the existing CallKit cold-start flow).
const String _kPendingIncomingCallExtrasKey = '__pending_incoming_call_extras';

/// Set at TAP time by the background notification action handler when the
/// user actually pressed "Accept" (vs. tapping the notification body or
/// pressing Decline). main() checks this on cold-start so we know whether
/// to auto-accept — `getNotificationAppLaunchDetails().actionId` is unreliable
/// on Android for action-button launches and often returns empty.
const String _kPendingIncomingCallAcceptKey =
    '__pending_incoming_call_accept_tapped';

Future<void> stashPendingIncomingCallExtras(Map<String, dynamic> extras) async {
  try {
    const storage = FlutterSecureStorage();
    await storage.write(
        key: _kPendingIncomingCallExtrasKey, value: jsonEncode(extras));
  } catch (_) {}
}

Future<void> markPendingIncomingCallAccepted(String callId) async {
  try {
    const storage = FlutterSecureStorage();
    await storage.write(key: _kPendingIncomingCallAcceptKey, value: callId);
  } catch (_) {}
}

Future<Map<String, dynamic>?> readAndClearPendingIncomingCallExtras() async {
  try {
    const storage = FlutterSecureStorage();
    final raw = await storage.read(key: _kPendingIncomingCallExtrasKey);
    if (raw == null || raw.isEmpty) return null;
    await storage.delete(key: _kPendingIncomingCallExtrasKey);
    return Map<String, dynamic>.from(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}

/// Returns the callId the user tapped Accept on, or null/empty if no Accept
/// tap is pending. Always clears the flag after reading.
Future<String?> readAndClearPendingIncomingCallAccept() async {
  try {
    const storage = FlutterSecureStorage();
    final raw = await storage.read(key: _kPendingIncomingCallAcceptKey);
    if (raw == null || raw.isEmpty) return null;
    await storage.delete(key: _kPendingIncomingCallAcceptKey);
    return raw;
  } catch (_) {
    return null;
  }
}

/// Read and clear pending call action set by native CallActionReceiver.
/// Returns a map with 'action' ('accept'/'decline'), 'callId', 'roomId',
/// 'callType', or null if no pending action.
Future<Map<String, dynamic>?> readAndClearPendingNativeCallAction() async {
  try {
    const channel = MethodChannel('com.bluehr.incoming_call_notification');
    final result = await channel.invokeMethod('readPendingAction');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  } catch (_) {
    return null;
  }
}

/// Show an Android full-screen-intent notification for an incoming call.
/// This is the Android replacement for `showFlutterCallNotification` — it's
/// stateless (each call posts a fresh notification, no native call list to
/// corrupt), uses the high-importance `incoming_calls` channel, and includes
/// Accept / Decline action buttons that route back to the app.
///
/// iOS is NOT routed here — Apple requires CallKit for VoIP background calls,
/// so iOS keeps using `showFlutterCallNotification`.
Future<void> showIncomingCallLocalNotification({
  required String callId,
  required String roomId,
  required String callerName,
  required String callerImage,
  required String callType,
  required Map<String, dynamic> extra,
}) async {
  if (!Platform.isAndroid) return;
  if (callId.isEmpty || roomId.isEmpty) return;

  // Stash the extras so a tap on "Accept" — which may launch the app from
  // killed state — can recover the call context and trigger acceptCall.
  await stashPendingIncomingCallExtras(extra);

  final notifId = incomingCallNotificationId(callId);

  // Try native notification with filled green/red buttons (custom RemoteViews).
  // This works when the main FlutterEngine is running (socket-driven calls,
  // foreground FCM). Falls back to flutter_local_notifications for the FCM
  // background isolate where the MethodChannel isn't registered.
  try {
    const nativeChannel =
        MethodChannel('com.bluehr.incoming_call_notification');
    await nativeChannel.invokeMethod('show', {
      'callId': callId,
      'roomId': roomId,
      'callerName': callerName,
      'callerImage': callerImage,
      'callType': callType,
      'notifId': notifId,
    });
    return; // Native notification shown successfully
  } catch (e) {
    print('Native call notification unavailable, using fallback: $e');
  }

  // Fallback: flutter_local_notifications (text-colored buttons)
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: onForegroundNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        onBackgroundNotificationResponse,
  );

  final payload = jsonEncode({
    ...extra,
    'callId': callId,
    'roomId': roomId,
    'callType': callType,
    'operation': 'incoming_call',
  });

  final isVideo = callType == 'video_call';
  final details = AndroidNotificationDetails(
    'incoming_calls_ringtone',
    'Incoming Calls',
    channelDescription: 'Incoming voice and video call alerts',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    visibility: NotificationVisibility.public,
    ongoing: true,
    autoCancel: false,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('hangouts_call'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    icon: '@drawable/ic_stat',
    // Colorize the notification with the brand blue so Android's contrast
    // algorithm renders the title (caller name) in WHITE. Without an
    // explicit `color`, `colorized: true` keeps the default light
    // background and the title falls back to BLACK — which is exactly the
    // black-title bug seen on the kill-mode (FCM background isolate)
    // fallback path. Matches the CallKit `backgroundColor: '#0955fa'`.
    color: const Color(0xFF0955FA),
    colorized: true,
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    // FLAG_INSISTENT (4) makes the sound repeat until user acts
    additionalFlags: Int32List.fromList([4]),
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'incoming_call_decline_$callId',
        'Decline',
        titleColor: Color(0xFFF44336),
        // Stay in background/terminated — bg handler runs REST decline + cancels
        // the notification without foregrounding the app.
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'incoming_call_accept_$callId',
        isVideo ? 'Video' : 'Accept',
        showsUserInterface: true,
        cancelNotification: true,
        titleColor: Color(0xFF4CAF50),
      ),
    ],
  );

  await plugin.show(
    notifId,
    callerName.isNotEmpty ? callerName : 'Incoming Call',
    isVideo ? 'Incoming video call' : 'Incoming voice call',
    NotificationDetails(android: details),
    payload: payload,
  );
}

/// Cancel the incoming-call notification once the call is accepted, declined,
/// cancelled by the caller, or otherwise ended.
Future<void> cancelIncomingCallLocalNotification(String callId) async {
  try {
    // Cancel from native notification (custom filled buttons)
    const nativeChannel =
        MethodChannel('com.bluehr.incoming_call_notification');
    await nativeChannel.invokeMethod('cancel', {
      'notifId': incomingCallNotificationId(callId),
    });
  } catch (_) {}
  try {
    // Also cancel from flutter_local_notifications as fallback
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(incomingCallNotificationId(callId));
  } catch (_) {}
}

/// Send reply message via direct REST API call.
/// Works in both foreground and background isolate contexts.
Future<void> _sendReplyViaApi({
  required String conversationId,
  required String message,
}) async {
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: SharedPreferenceUtils.authToken);
    final storedBaseUrl =
        await storage.read(key: SharedPreferenceUtils.baseURL);
    final apiUrl =
        (storedBaseUrl ?? baseUrl ?? '') + 'chat-service/chat/send-message';

    if (token == null || token.isEmpty) return;

    final dioClient = dio.Dio();
    final formData = dio.FormData.fromMap({
      'conversation_id': conversationId,
      'message': message,
      'message_type': 'text',
    });

    await dioClient.post(
      apiUrl,
      data: formData,
      options: dio.Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  } catch (e) {
    print('Notification reply API error: $e');
  }
}

class AppNotificationHandler {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Secure-storage key for the id of the last launch-notification we've
  /// already routed from. Prevents cold-start re-routing on every launch
  /// while Android keeps the tapped notification's extras in the intent.
  static const String _lastHandledLaunchNotificationIdKey =
      'last_handled_launch_notification_id';

  /// True when the app was launched by tapping a notification (from terminated state).
  /// SplashScreen checks this to hold its UI instead of navigating to home.
  static bool launchedFromNotification = false;

  /// Completes when notification-based navigation has finished.
  /// SplashScreen awaits this before deciding its own navigation.
  static Completer<void>? notificationNavigationCompleter;

  /// Holds an FCM device token that couldn't be POSTed because the user
  /// wasn't authenticated yet (e.g. token fetched during the cold-start
  /// pre-login window). `flushPendingTokenSync()` drains it right after
  /// auth becomes available so the backend never misses the live token.
  static String? _pendingTokenSync;

  /// Call early (before runApp or in _initDeferred before splash navigates)
  /// to detect if the app was launched via a notification tap.
  static Future<void> checkNotificationLaunch() async {
    final details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payLoad = details!.notificationResponse?.payload;
      if (payLoad != null && payLoad.isNotEmpty) {
        launchedFromNotification = true;
        notificationNavigationCompleter = Completer<void>();
        return;
      }
    }

    // iOS-only path: terminated-state FCM notifications are rendered
    // natively by APNs, NOT through flutter_local_notifications, so
    // getNotificationAppLaunchDetails() above returns null even when the
    // user just tapped a push. The tap payload only surfaces via
    // FirebaseMessaging.getInitialMessage(). Without this branch
    // `launchedFromNotification` stays false on iOS, the splash screen
    // navigates straight to home, and the deep-link routing that
    // firebaseNotificationSetup()'s iOS handler tries to do gets clobbered
    // before it can run. Setting the flag + completer here makes splash
    // wait for that routing, matching the Android behaviour.
    if (Platform.isIOS) {
      try {
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null && initial.data.isNotEmpty) {
          launchedFromNotification = true;
          notificationNavigationCompleter = Completer<void>();
        }
      } catch (e) {
        print('[iOS-checkNotificationLaunch] getInitialMessage error: $e');
      }
    }
  }

  /// FIREBASE NOTIFICATION SETUP
  Future<void> firebaseNotificationSetup() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payLoad =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      print("Launch notification payload: $payLoad");
      if (payLoad != null && payLoad.isNotEmpty) {
        try {
          final data = jsonDecode(payLoad) as Map<String, dynamic>;

          // Android's getNotificationAppLaunchDetails() keeps returning the
          // same intent extras on every cold start until new extras arrive.
          // Without this guard, the tapped notification would re-open on
          // every launch. Skip if we've already handled this notificationId.
          final currentId = data['notificationId']?.toString();
          if (currentId != null && currentId.isNotEmpty) {
            final lastHandled = await SharedPreferenceUtils.getSecureValue(
                _lastHandledLaunchNotificationIdKey);
            if (lastHandled == currentId) {
              print(
                  "[COLD_START] notification $currentId already handled — skipping re-open");
              if (notificationNavigationCompleter != null &&
                  !notificationNavigationCompleter!.isCompleted) {
                notificationNavigationCompleter!.complete();
              }
              return;
            }
            await SharedPreferenceUtils.setSecureValue(
                _lastHandledLaunchNotificationIdKey, currentId);
          }
          // Skip incoming-call cold-start routing here — main()'s pre-runApp
          // check (readAndClearPendingIncomingCallAccept) already decided
          // whether to auto-accept. If the user tapped Accept we're already
          // joining the call; if they tapped the body or it was an action
          // launch, we must NOT route to chat (the old behavior of this
          // switch case opened OrderChat for incoming_call payloads, which
          // is what the user reported).
          final op = (data['operation'] ?? '').toString().toLowerCase();
          if (op == 'incoming_call') {
            // Body-tap cold start on an incoming-call notification.
            // main()'s pre-runApp checks already auto-accepted if the user
            // tapped the Accept action button (or the native filled-button
            // notification). If they tapped the BODY, those checks were
            // no-ops and CallController is still idle — open the in-app
            // IncomingCallScreen so the user can accept/decline.
            print(
                "[COLD_START_CALL] launch payload is incoming_call — opening IncomingCallScreen");
            // Wait for the home screen / navigator to settle before pushing
            // the call screen on top of it.
            await Future.delayed(const Duration(milliseconds: 600));
            final ctrl = getOrPut(() => CallController());
            final activeStatus = ctrl.callStatus.value;
            if (activeStatus == CallStatus.idle ||
                activeStatus == CallStatus.ringing) {
              _openIncomingCallScreen(data);
            }
          } else {
            // Wait for navigator to be ready (splash screen signals this)
            await Future.delayed(const Duration(milliseconds: 300));
            _onTapNotificationFromStatusBar(data, fromColdStart: true);
          }
        } catch (e) {
          print("Error parsing launch notification payload: $e");
        } finally {
          // Signal that notification navigation is done (or failed)
          if (notificationNavigationCompleter != null &&
              !notificationNavigationCompleter!.isCompleted) {
            notificationNavigationCompleter!.complete();
          }
        }
      }
    }

    /// Register foreground + background tap callbacks EARLY (was previously
    /// only called from BottomNavigationBar after login). Without this, an
    /// incoming-call notification arriving before the user reaches the home
    /// screen would have no foreground action handler — tapping "Accept"
    /// would dismiss the notification but never invoke acceptCall.
    getInitialMsg();

    /// Android Notification Channels per backend documentation
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
      'default',
      'General Notifications',
      description: 'All standard push notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel incomingCallChannel =
        AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Incoming voice and video call alerts',
      importance: Importance.max,
    );

    const AndroidNotificationChannel missedCallChannel =
        AndroidNotificationChannel(
      'missed_calls',
      'Missed Calls',
      description: 'Missed call notifications',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Chat messages and tagged messages',
      importance: Importance.high,
    );

    const AndroidNotificationChannel ridesChannel = AndroidNotificationChannel(
      'rides',
      'Ride Updates',
      description: 'Ride order status updates',
      importance: Importance.high,
    );

    const AndroidNotificationChannel announcementsChannel =
        AndroidNotificationChannel(
      'announcements',
      'Announcements',
      description: 'Admin and system announcements',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel channelsChannel =
        AndroidNotificationChannel(
      'channels',
      'Channels',
      description: 'Channel and follower updates',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel ongoingCallChannel =
        AndroidNotificationChannel(
      'ongoing_call',
      'Ongoing Calls',
      description: 'Shows when a call is in progress',
      importance: Importance.low,
    );

    ///local notification...
    // NOTE: FCM background handler is now registered in main() right after
    // Firebase init, so it's guaranteed to be set before runApp. Do NOT
    // register it again here — duplicate registration can overwrite the
    // stored Dart callback handle and cause a narrow race on app upgrade.

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(defaultChannel);
    await androidPlugin?.createNotificationChannel(incomingCallChannel);
    await androidPlugin?.createNotificationChannel(missedCallChannel);
    await androidPlugin?.createNotificationChannel(messagesChannel);
    await androidPlugin?.createNotificationChannel(ridesChannel);
    await androidPlugin?.createNotificationChannel(announcementsChannel);
    await androidPlugin?.createNotificationChannel(channelsChannel);
    await androidPlugin?.createNotificationChannel(ongoingCallChannel);

    ///IOS Setup
    DarwinInitializationSettings initializationSettings =
        const DarwinInitializationSettings(
            requestAlertPermission: true,
            requestSoundPermission: true,
            requestBadgePermission: true);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.initialize(
          initializationSettings,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // iOS: explicit Firebase push-notification permission + APNs registration.
    // Without this, Firebase never marks the app as authorized for remote
    // notifications and getToken() returns null on real devices.
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("===ios-notification-auth=== ${settings.authorizationStatus}");
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print(
            "===ios-notification=== user did not grant permission — skipping token fetch");
      } else {
        // Wait for APNs device token before asking FCM for a token.
        // APNs registration is async; calling getToken() before the APNs
        // token is attached fails silently with apns-token-not-set on iOS.
        await _waitForApnsToken();
      }
    }

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Get the CURRENT FCM token (reconciles + updates the cache on rotation)
    /// and re-sync it with the backend on every launch. FCM's device_token is
    /// only POSTed inside verifyOTP at first login, so any token rotation
    /// since then leaves the server routing APNs/FCM pushes to a dead token —
    /// which is exactly why iOS terminated-state notifications worked once and
    /// then went silent until the app was reopened. Syncing the LIVE token
    /// here (not a possibly-stale cached read) heals that on every cold start.
    // Attach the rotation listener BEFORE fetching the current token so a
    // token rotation that lands between getToken() returning and the listener
    // being wired up isn't dropped. Persist rotated FCM tokens so the backend
    // always has the current one.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("===fcm-token-refresh=== $newToken");
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.notificationDeviceToken, newToken);
      await _registerDeviceTokenWithBackend(newToken);
    });

    final liveToken = await getFcmToken();
    if (liveToken != null && liveToken.isNotEmpty) {
      await _registerDeviceTokenWithBackend(liveToken);
    }

    // iOS-only: register VoIP push token with the backend so calls can wake
    // the app in terminated state via PushKit + CallKit. Without this the
    // backend has no VoIP address, FCM pushes are all it has, and iOS
    // terminated calls only ring for the one-shot banner sound without the
    // persistent lock-screen CallKit UI. `AppDelegate.swift` already
    // forwards the raw token to the plugin on launch; this just hands it to
    // the server.
    if (Platform.isIOS) {
      // Fire-and-forget: token retrieval can take a moment after app launch
      // (PushKit delegate is async), so we poll briefly rather than blocking
      // the rest of setupFcmToken().
      //
      // force: true so every cold start makes one idempotent delivery attempt
      // regardless of the local cache. This self-heals installs whose cache
      // was poisoned by the earlier cache-on-failure bug (token cached even
      // though the 404'd PATCH never reached the backend), which otherwise
      // would skip re-sending forever and keep receiving plain FCM banners
      // instead of CallKit VoIP pushes.
      _syncVoipTokenToBackend(force: true);
    }
  }

  /// Secure-storage key for the last VoIP token we successfully delivered to
  /// the backend. Kept separate from the FCM token cache. ONLY written after a
  /// confirmed-success PATCH (see below) — caching on failure was a bug that
  /// permanently suppressed retries once the endpoint 404'd.
  static const String _voipCacheKey = 'voipTokenCache';

  /// Public entry point to (re)register the iOS VoIP push token with the
  /// backend. Call after auth becomes available (login) and on app resume.
  /// `force: true` bypasses the unchanged-token short-circuit — use it when
  /// we can't trust the cache (e.g. right after login, or when a previous
  /// session may have failed to actually deliver the token).
  static Future<void> syncVoipToken({bool force = false}) =>
      _syncVoipTokenToBackend(force: force);

  /// Poll `flutter_callkit_incoming` for the VoIP token that iOS hands to
  /// PushKit (forwarded in `AppDelegate.swift` via `setDevicePushTokenVoIP`),
  /// then PATCH it to the backend so it can send VoIP/PushKit pushes for
  /// incoming calls (the ONLY push type that wakes CallKit in background /
  /// terminated state on iOS). Idempotent on the server side because the
  /// payload is just `{voip_token: ...}`. Silent: no UI side effects.
  static Future<void> _syncVoipTokenToBackend({bool force = false}) async {
    if (!Platform.isIOS) return;

    const Duration timeout = Duration(seconds: 10);
    const Duration interval = Duration(milliseconds: 500);
    final deadline = DateTime.now().add(timeout);

    String voipToken = '';
    try {
      while (DateTime.now().isBefore(deadline)) {
        final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (token.isNotEmpty) {
          voipToken = token;
          break;
        }
        await Future.delayed(interval);
      }
    } catch (e) {
      print("===voip-token-poll=== error: $e");
      return;
    }

    if (voipToken.isEmpty) {
      print("===voip-token=== not available after ${timeout.inSeconds}s");
      return;
    }
    print("===voip-token=== $voipToken");

    if (authTokenGlobal == null || authTokenGlobal!.isEmpty) {
      print("===voip-token-sync=== skipped (no auth token)");
      return;
    }

    // Avoid pointless network calls if the token hasn't changed since the last
    // SUCCESSFUL delivery. Skipped when force is set (post-login / resume),
    // because the cache can't prove the backend actually has the token — a
    // prior session may have cached optimistically then failed.
    if (!force) {
      try {
        final cached =
            await SharedPreferenceUtils.getSecureValue(_voipCacheKey);
        if (cached is String && cached == voipToken) {
          print("===voip-token-sync=== skipped (unchanged)");
          return;
        }
      } catch (_) {}
    }

    try {
      await ApiBaseHelper().patchHTTP(
        'user-service/user/me/voip-token',
        params: {'voip_token': voipToken},
        showProgress: false,
        onError: (e) {
          // Do NOT cache on error — leaving the cache untouched guarantees the
          // next launch / resume / login retries instead of assuming success.
          print("===voip-token-sync=== error: $e");
        },
        onSuccess: (_) {
          // Cache ONLY on confirmed success so the unchanged-short-circuit
          // above can never suppress a delivery that never actually landed.
          SharedPreferenceUtils.setSecureValue(_voipCacheKey, voipToken);
          print("===voip-token-sync=== ok");
        },
      );
    } catch (e) {
      print("===voip-token-sync=== threw: $e");
    }
  }

  /// PUT the current FCM device token to the backend's user-update endpoint
  /// so APNs/FCM pushes target the live token. Silent: no progress dialog,
  /// no snackbar. Skips when the user isn't authenticated yet (login flow
  /// already sends the token via verifyOTP).
  static Future<void> _registerDeviceTokenWithBackend(String token) async {
    if (token.isEmpty) return;
    if (authTokenGlobal == null || authTokenGlobal!.isEmpty) {
      // Not authenticated yet — queue the token so it can be flushed to the
      // backend the moment auth becomes available (see flushPendingTokenSync).
      _pendingTokenSync = token;
      print("===fcm-token-sync=== queued (no auth yet)");
      return;
    }
    try {
      await ApiBaseHelper().patchHTTP(
        'user-service/user/me/device-token',
        params: {ApiKeys.device_token: token},
        showProgress: false,
        onError: (e) {
          print("===fcm-token-sync=== error: $e");
        },
        onSuccess: (_) {
          print("===fcm-token-sync=== ok");
        },
      );
    } catch (e) {
      print("===fcm-token-sync=== threw: $e");
    }
  }

  /// Drain any token that was queued while unauthenticated. Call this right
  /// after auth becomes available (e.g. after OTP verification). If nothing
  /// was queued, re-fetch the live token and POST it anyway in case a
  /// rotation happened during the unauthenticated window.
  static Future<void> flushPendingTokenSync() async {
    final pending = _pendingTokenSync;
    _pendingTokenSync = null;
    if (pending != null && pending.isNotEmpty) {
      await _registerDeviceTokenWithBackend(pending);
    } else {
      final live = await getFcmToken();
      if (live != null && live.isNotEmpty) {
        await _registerDeviceTokenWithBackend(live);
      }
    }
  }

  /// Public wrapper to POST the current FCM device token to the backend.
  /// Used by the app-resume re-sync path.
  static Future<void> syncCurrentToken(String token) =>
      _registerDeviceTokenWithBackend(token);

  /// Polls FirebaseMessaging.getAPNSToken() until it returns a non-null value
  /// or the timeout elapses. Required on iOS real devices before getToken().
  static Future<String?> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    String? apns;
    while (DateTime.now().isBefore(deadline)) {
      apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null && apns.isNotEmpty) break;
      await Future.delayed(interval);
    }
    print("===ios-apns-token=== $apns");
    return apns;
  }

  /// Fetch the CURRENT FCM token, reconcile it with the cached copy, and
  /// return the live token so the caller can re-sync it with the backend.
  ///
  /// BUG FIX: previously this only called getToken() when the cache was
  /// EMPTY — once a token was cached it was never re-fetched. iOS re-binds
  /// the APNs↔FCM token on reinstall, restore-from-backup and OS updates,
  /// and FCM rotates tokens periodically. When that happened the stale
  /// cached token kept being re-sent to the backend, every push routed to a
  /// dead token, and terminated-state notifications silently stopped after
  /// the first one — until the user reopened the app and `onTokenRefresh`
  /// happened to fire. Now we always ask the SDK for the live token and
  /// update the cache when it differs, so the backend gets the current token
  /// on every cold start.
  static Future<String?> getFcmToken() async {
    final firebaseMessaging = FirebaseMessaging.instance;

    Future<String?> cached() async {
      final v = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.notificationDeviceToken);
      return (v is String && v.isNotEmpty) ? v : null;
    }

    try {
      // On iOS, getToken() fails with apns-token-not-set if APNs has not yet
      // attached a device token. Fall back to the cached value so the caller
      // can still re-sync whatever we last had.
      if (Platform.isIOS) {
        final apns = await firebaseMessaging.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          print("=========fcm- skipped: APNS token not ready on iOS");
          return cached();
        }
      }

      final liveToken = await firebaseMessaging.getToken();
      if (liveToken == null || liveToken.isEmpty) {
        return cached();
      }

      final previous = await cached();
      if (previous != liveToken) {
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.notificationDeviceToken, liveToken);
        print("=========fcm-token=== updated (rotated): $liveToken");
      }
      return liveToken;
    } catch (e) {
      print("=========fcm- Error :$e");
      return cached();
    }
  }

  /// Force a fresh FCM token. Use on logout so the device unbinds from
  /// the previous user; Android GMS can briefly hand back the
  /// just-deleted token from getToken(), so retry with short backoff
  /// until we see a different value.
  ///
  /// Fault-tolerant: if GMS is unavailable (SERVICE_NOT_AVAILABLE,
  /// common on emulators without Play Services or on offline devices),
  /// keep the previous cached token rather than clearing it and
  /// returning null. The onTokenRefresh listener in setupFcmToken()
  /// will sync the real new token to the backend once GMS recovers.
  static Future<String?> refreshFcmToken() async {
    final rawOld = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.notificationDeviceToken);
    final String? oldToken =
        (rawOld is String && rawOld.isNotEmpty) ? rawOld : null;

    if (Platform.isIOS) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns == null || apns.isEmpty) {
        await _waitForApnsToken();
      }
    }

    bool deleted = false;
    try {
      await FirebaseMessaging.instance.deleteToken();
      deleted = true;
    } catch (e) {
      print("===fcm-refresh=== deleteToken error: $e");
    }

    // If deleteToken() failed, GMS is already in a bad state — calling
    // getToken() will fail too. Keep the old token as fallback and let
    // onTokenRefresh sync a real new one once GMS recovers.
    if (!deleted) {
      print("===fcm-refresh=== keeping old token (delete failed): $oldToken");
      return oldToken;
    }

    String? newToken;
    const int maxAttempts = 6;
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s — total ~63s
    // worst-case. SERVICE_NOT_AVAILABLE on a real device usually
    // resolves within 30s once GMS finishes re-registering the
    // Firebase Installation after deleteToken().
    for (int i = 0; i < maxAttempts; i++) {
      try {
        newToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print(
            "===fcm-refresh=== getToken error (attempt ${i + 1}/$maxAttempts): $e");
      }
      final hasNewToken = newToken != null && newToken.isNotEmpty;
      final isDifferent = hasNewToken && newToken != oldToken;
      if (hasNewToken && (isDifferent || Platform.isIOS)) break;
      if (i < maxAttempts - 1) {
        final waitMs = 1000 * (1 << i);
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }

    if (newToken != null && newToken.isNotEmpty) {
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.notificationDeviceToken, newToken);
      print("===fcm-refresh=== new token $newToken");
      return newToken;
    }

    // GMS never handed us a new token. Don't revert the cache to oldToken —
    // deleteToken() already invalidated it on FCM, so re-caching guarantees
    // the next sync POSTs a dead token. Clear the cache so the next session
    // triggers a fresh fetch; onTokenRefresh will sync the real new token to
    // the backend once GMS comes back.
    print(
        "===fcm-refresh=== failed to obtain new token, dropping dead old token");
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.notificationDeviceToken, '');
    return null;
  }

  /// handle notification when app in fore ground.. local notification......
  /// Now uses top-level `onForegroundNotificationResponse` so the same callback
  /// can be re-registered safely from the FCM bg-isolate's
  /// `showIncomingCallLocalNotification` without losing functionality.
  void getInitialMsg() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
  }

  /// Handle action button taps from notification
  static void _handleActionButtonTap(String actionId, Map<String, dynamic> data,
      {String? replyText}) {
    // Inline reply from notification (WhatsApp-style)
    if (actionId.startsWith('reply_message_') &&
        replyText != null &&
        replyText.isNotEmpty) {
      final conversationId = data['conversationId'] ?? '';
      final senderId = data['senderId'] ?? '';
      _sendQuickReply(
          conversationId: conversationId,
          senderId: senderId,
          message: replyText);
      return;
    }

    // Chat actions - open chat screen
    if (actionId.startsWith('reply_message_') ||
        actionId.startsWith('view_chat_') ||
        actionId.startsWith('view_conversation_')) {
      final senderId = data['senderId'] ?? '';
      _openChatWithUser(senderId);
      return;
    }

    // Mark as read - dismiss notification silently
    if (actionId.startsWith('mark_read_')) {
      // Cancel the notification from tray
      flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    // Connection actions
    if (actionId.startsWith('accept_connection_') ||
        actionId.startsWith('decline_connection_') ||
        actionId.startsWith('view_profile_') ||
        actionId.startsWith('message_')) {
      Get.toNamed(RouteHelper.getNotificationScreenRoute());
      return;
    }

    // Business go-live action button — deep-link to the business own profile
    // and auto-prompt go-live. Covers foreground, background, and killed taps.
    if (actionId == 'go_live') {
      Get.toNamed(
        RouteConstant.BusinessOwnProfileScreen,
        arguments: {
          'business_id': data['business_id'],
          'open_go_live': true,
        },
      );
      return;
    }

    // Route-order claim (ROUTE_ORDER_AVAILABLE notification → "Claim Order").
    // Must precede the generic ride block so it isn't swallowed by it.
    if (actionId.startsWith('claim_order_')) {
      _handleClaimOrder(actionId.substring('claim_order_'.length));
      return;
    }

    // Ride actions
    if (actionId.startsWith('track_ride_') ||
        actionId.startsWith('view_order_') ||
        actionId.startsWith('accept_order_') ||
        actionId.startsWith('contact_rider_')) {
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
      return;
    }

    // Post/Reel actions
    if (actionId.startsWith('view_post_') ||
        actionId.startsWith('view_comment_') ||
        actionId.startsWith('view_reel_') ||
        actionId.startsWith('view_response_')) {
      Get.toNamed(RouteHelper.getNotificationScreenRoute());
      return;
    }

    // Chat-dispatch rider OTP nudge → open the real chat (NOT the AI
    // assistant). Checked before the AI-greeting open_chat block below, which
    // shares the same id prefix.
    if (actionId.startsWith('open_chat_') &&
        (data['type'] ?? data['operation'] ?? '').toString().toLowerCase() ==
            'rider_otp') {
      _openChatFromRiderOtp(data);
      return;
    }

    // AI greeting actions
    if (actionId.startsWith('open_chat_')) {
      final chat = ChatViewController.personalAiChatModule;
      Get.to(() => AiChatScreen(
            profileImage: chat?.sender?.profileImage,
            name: chat?.sender?.name,
            type: chat?.sender?.accountType,
          ));
      return;
    }

    // Ongoing call: Hang Up action
    if (actionId == 'hangup_call') {
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().endCall();
      }
      return;
    }

    // Incoming call (Android local-notification path): Accept
    if (actionId.startsWith('incoming_call_accept_')) {
      final callId = (data['callId'] ?? '').toString();
      final roomId = (data['roomId'] ?? '').toString();
      final isVideo = (data['callType'] ?? '') == 'video_call';
      cancelIncomingCallLocalNotification(callId);
      if (Get.isRegistered<CallController>()) {
        // Hydrate state so acceptCall has remote user id, room id, etc.
        final ctrl = Get.find<CallController>();
        ctrl.initStateFromCallKitExtra(data);
        ctrl.acceptCall(
          callIdParams: callId,
          roomIdParams: roomId,
          isVideoCall: isVideo,
        );
      }
      return;
    }

    // Incoming call (Android local-notification path): Decline
    if (actionId.startsWith('incoming_call_decline_')) {
      final callId = (data['callId'] ?? '').toString();
      cancelIncomingCallLocalNotification(callId);
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().endCall();
      }
      return;
    }

    // Default: treat as regular notification tap
    _onTapNotificationFromStatusBar(data);
  }

  /// Send a quick reply from the notification inline input via REST API
  static Future<void> _sendQuickReply({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    try {
      await ChatViewRepo().sendMessageToUser({
        'conversation_id': conversationId,
        'message': message,
        'message_type': 'text',
      });
      // Dismiss the notification
      flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      // Fallback: try direct API call
      try {
        await _sendReplyViaApi(
            conversationId: conversationId, message: message);
        flutterLocalNotificationsPlugin.cancelAll();
      } catch (_) {
        // Last resort: open chat screen
        _openChatWithUser(senderId);
      }
    }
  }

  ///show notification msg
  Future<void> showMsg(RemoteMessage message) async {
    final operation =
        (message.data['operation'] ?? '').toString().toLowerCase();
    print("ORDER SCREEN NAME ${operation}");
    print("ORDER SCREEN NAME message.data ${message.data}");
    // Handle fare-call incoming call — show IncomingRiderOrderScreen with ride details.
    // Regular calls are handled by socket `call:incoming` in CallController.
    if (operation == 'fare_ride_incoming_call') {
      try {
        _showRiderOrderScreen(message.data);
      } catch (_) {}
      return;
    }

    // Platform-split to prevent duplicate banners.
    //
    // iOS: when the FCM push carries a `notification` field AND foreground
    // presentation options are set (setForegroundNotificationPresentationOptions
    // with alert: true in main()), iOS auto-shows a system banner even in
    // foreground. Rendering ANOTHER notification here via showFromData would
    // produce a second banner. We defer to the system banner on iOS when a
    // notification field is present; data-only pushes still render here.
    //
    // Android: no system auto-banner in foreground (FCM suppresses it); we
    // must render via showFromData for the user to see anything. Behavior
    // unchanged.
    if (Platform.isIOS && message.notification != null) {
      return;
    }

    // Use the generic data-only renderer for all other notifications.
    // This reads channelId, channelName, channelImportance, style, imageUrl,
    // groupKey, actions, etc. directly from the data payload.
    await showFromData(message.data);
  }

  /// Handle ride_order_received notification — parse payload, populate
  /// CallController with ride details, and navigate to IncomingRiderOrderScreen.
  ///
  /// Actual message.data structure:
  /// ```
  /// { senderName, senderId, payload: "{\"orderId\":\"...\",\"metadata\":{
  ///     \"Order_id\":\"...\",
  ///     \"Delivered address\":{\"Address\":\"...\",\"lat\":...,\"long\":...},
  ///     \"Pickup address\":{\"Address\":\"...\",\"lat\":...,\"long\":...},
  ///     \"owner details\":{\"userid\":\"...\",\"number\":\"...\"},
  ///     \"ridefare\":54.488
  ///   }}" }
  /// ```
  Future<void> _showRiderOrderScreen(Map<String, dynamic> data) async {
    try {
      // Parse the payload JSON string
      Map<String, dynamic> payload = {};
      try {
        final rawPayload = data['payload'];
        if (rawPayload is String && rawPayload.isNotEmpty) {
          payload = jsonDecode(rawPayload);
        } else if (rawPayload is Map) {
          payload = Map<String, dynamic>.from(rawPayload);
        }
      } catch (e) {
        log('_showRiderOrderScreen: payload parse error: $e');
      }

      Map? metadata = payload['metadata'];
      if (metadata == null) {
        return;
      }

      // Support both fare-call guide format (rideDetails) and legacy format
      final rideDetails = metadata['rideDetails'];
      final bool isGuideFormat = rideDetails != null;

      late final double pickupLat, pickupLng, dropLat, dropLng, fare, distance;
      late final String pickupAddress,
          dropAddress,
          orderId,
          customerPhone,
          modeOfPayment,
          orderFor;
      late final double etaDistanceKm, etaDurationMin;

      if (isGuideFormat) {
        // Guide format: metadata.rideDetails.pickup/drop/fare/distance/orderFor/modeOfPayment
        final pickup = rideDetails['pickup'] ?? {};
        final drop = rideDetails['drop'] ?? {};
        pickupLat = _parseDouble(pickup['lat']);
        pickupLng = _parseDouble(pickup['lng']);
        dropLat = _parseDouble(drop['lat']);
        dropLng = _parseDouble(drop['lng']);
        pickupAddress = (pickup['address'] ?? '').toString();
        dropAddress = (drop['address'] ?? '').toString();
        fare = _parseDouble(rideDetails['fare']);
        distance = _parseDouble(rideDetails['distance']);
        orderId = metadata['orderId'] ?? payload['orderId'] ?? '';
        modeOfPayment = (rideDetails['modeOfPayment'] ?? 'postpaid').toString();
        orderFor = (rideDetails['orderFor'] ?? '').toString();
        customerPhone = '';
        final eta = rideDetails['eta'];
        etaDistanceKm = _parseDouble(eta?['distanceKm']);
        etaDurationMin = _parseDouble(eta?['durationMin']);
      } else {
        // Legacy format: metadata['Pickup address'], metadata['Delivered address'], etc.
        final pickupInfo = metadata['Pickup address'] ?? {};
        final dropInfo = metadata['Delivered address'] ?? {};
        final ownerInfo = metadata['owner details'] ?? {};
        pickupLat = _parseDouble(pickupInfo['lat']);
        pickupLng = _parseDouble(pickupInfo['long']);
        dropLat = _parseDouble(dropInfo['lat']);
        dropLng = _parseDouble(dropInfo['long']);
        pickupAddress = (pickupInfo['Address'] ?? '').toString();
        dropAddress = (dropInfo['Address'] ?? '').toString();
        fare = _parseDouble(metadata['ridefare']);
        distance = 0.0;
        orderId = payload['orderId'] ?? metadata['Order_id'] ?? '';
        modeOfPayment = 'postpaid';
        orderFor = '';
        customerPhone = (ownerInfo['number'] ?? '').toString();
        etaDistanceKm = 0.0;
        etaDurationMin = 0.0;
      }

      // Customer info
      final customerName = data['senderName'] ?? data['title'] ?? 'Customer';
      final customerImage = data['senderProfileImage'] ?? '';

      log('[RIDE_ORDER] orderId=$orderId, fare=$fare, pickup=$pickupAddress, drop=$dropAddress, customer=$customerName');

      // Ensure CallController exists and set fare-call state
      if (!Get.isRegistered<CallController>()) {
        Get.put(CallController(), permanent: true);
      }
      final callController = Get.find<CallController>();

      // Extract call connection details from notification data/payload
      final callId =
          payload['call_id'] ?? data['callId'] ?? data['notificationId'] ?? '';
      final roomId = payload['room_id'] ?? data['roomId'] ?? '';
      final ownerDetails = (metadata['owner details'] ?? {});
      final senderId = data['senderId'] ??
          ((ownerDetails is Map ? ownerDetails['userid'] : null) ?? '')
              .toString();
      final conversationId = data['conversationId'] ?? '';

      log('[RIDE_ORDER] callId=$callId, roomId=$roomId, senderId=$senderId');

      // Set call connection state so acceptCall() can establish WebRTC
      callController.initStateFromCallKitExtra({
        'senderId': senderId,
        'conversationId': conversationId,
        'callType': 'audio_call',
        'callerName': customerName,
        'callerImage': customerImage,
        'callId': callId,
        'roomId': roomId,
        'operation': 'incoming_call',
        'isFareCall': 'true',
        'fareCallOrderId': orderId,
      });

      // Set fare-call ride details (initStateFromCallKitExtra doesn't handle these)
      callController.fareCallRideDetails.value = {
        'pickup': {
          'address':
              pickupAddress.isNotEmpty ? pickupAddress : 'Pickup location',
          'lat': pickupLat,
          'lng': pickupLng,
        },
        'drop': {
          'address': dropAddress.isNotEmpty ? dropAddress : 'Drop location',
          'lat': dropLat,
          'lng': dropLng,
        },
        'fare': fare,
        'distance': distance,
        'modeOfPayment': modeOfPayment,
        'orderFor': orderFor,
        if (customerPhone.isNotEmpty) 'customerPhone': customerPhone,
        if (etaDurationMin > 0)
          'eta': {
            'distanceKm': etaDistanceKm,
            'durationMin': etaDurationMin,
          },
      };

      // Navigate to IncomingRiderOrderScreen
      if (Get.currentRoute != '/IncomingRiderOrderScreen') {
        Get.toNamed('/IncomingRiderOrderScreen');
      }
    } catch (e, stack) {
      log('_showRiderOrderScreen ERROR: $e');
      log('Stack: $stack');
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ─── Generic data-only FCM renderer (per backend notification guide) ───

  /// Show notification from a data-only FCM payload.
  /// Reads all fields from the backend: title, body, imageUrl, style,
  /// channelId, channelName, channelImportance, groupKey, notificationId, actions.
  Future<void> showFromData(Map<String, dynamic> data) async {
    final title = (data['title'] ?? 'BlueEra').toString();
    final body = (data['body'] ?? data['message'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final style = (data['style'] ?? 'default').toString();
    final channelId = (data['channelId'] ?? 'default').toString();
    final channelName = (data['channelName'] ?? 'Notifications').toString();
    final channelImportance =
        (data['channelImportance'] ?? 'default').toString();
    final groupKey = (data['groupKey'] ?? '').toString();
    final notificationId =
        (data['notificationId'] ?? '${DateTime.now().millisecondsSinceEpoch}')
            .toString();
    final actionsJson = (data['actions'] ?? '[]').toString();
    final operation = (data['operation'] ?? '').toString().toLowerCase();

    // Suppress AI greeting notifications when the user has muted the AI chat
    // locally (3-dot menu → Mute). AI greetings map to the personal AI chat.
    if (operation.contains('greeting')) {
      final muted = await AiChatProfileStorage.isMuted('personal');
      if (muted) return;
    }

    final isChatMessage = _isChatOperation(operation);

    // Parse action buttons from backend
    List<Map<String, dynamic>> backendActions = [];
    try {
      backendActions = List<Map<String, dynamic>>.from(jsonDecode(actionsJson));
    } catch (_) {}

    // Map importance string to Android importance level
    final importance = _mapImportanceFromString(channelImportance);

    // Download image for BigPictureStyle if needed
    ByteArrayAndroidBitmap? bigPicture;
    if (style == 'bigPicture' && imageUrl.isNotEmpty) {
      bigPicture = await _downloadImageAsBitmap(imageUrl);
    }

    // Build style information
    final styleInformation =
        _buildStyleInformation(style, body, bigPicture, title);

    // Build action buttons: prefer chat-specific actions for chat messages,
    // otherwise use backend-provided actions
    final List<AndroidNotificationAction> androidActions = isChatMessage
        ? _buildChatActions(data)
        : backendActions.isNotEmpty
            ? backendActions.take(3).map((a) {
                return AndroidNotificationAction(
                  (a['id'] ?? '').toString(),
                  (a['text'] ?? '').toString(),
                  showsUserInterface: true,
                );
              }).toList()
            : _parseNotificationActions(data);

    // Generate numeric ID from notification ID string
    final numId = notificationId.hashCode.abs() % 2147483647;

    // Build Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.max || importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_stat',
      groupKey: groupKey.isNotEmpty ? groupKey : null,
      styleInformation: styleInformation,
      category: isChatMessage ? AndroidNotificationCategory.message : null,
      actions: androidActions,
    );

    // Build iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await flutterLocalNotificationsPlugin.show(
      numId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );

    // Show group summary notification on Android (bundles multiple notifications)
    if (groupKey.isNotEmpty && Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.show(
        groupKey.hashCode.abs() % 2147483647,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: importance,
            icon: '@drawable/ic_stat',
            groupKey: groupKey,
            setAsGroupSummary: true,
          ),
        ),
      );
    }
  }

  /// Build style information based on backend-provided style field
  StyleInformation _buildStyleInformation(
    String style,
    String body,
    ByteArrayAndroidBitmap? bigPicture,
    String title,
  ) {
    switch (style) {
      case 'bigPicture':
        if (bigPicture != null) {
          return BigPictureStyleInformation(
            bigPicture,
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          );
        }
        return BigTextStyleInformation(body, contentTitle: title);
      case 'bigText':
        return BigTextStyleInformation(body, contentTitle: title);
      default:
        return DefaultStyleInformation(true, true);
    }
  }

  /// Map importance string from backend to Android Importance level
  Importance _mapImportanceFromString(String level) {
    switch (level) {
      case 'max':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'low':
        return Importance.low;
      case 'min':
        return Importance.min;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Download an image from URL and return as ByteArrayAndroidBitmap for BigPictureStyle
  Future<ByteArrayAndroidBitmap?> _downloadImageAsBitmap(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('[Notification] Failed to download image: $e');
    }
    return null;
  }

  /// Check if operation is a chat/message type
  bool _isChatOperation(String operation) {
    return operation == 'sent_message' ||
        operation == 'message_reminder' ||
        operation == 'tagged_in_message' ||
        operation == 'commented_on_message' ||
        operation == 'liked_message';
  }

  /// Build WhatsApp-style action buttons for chat notifications
  List<AndroidNotificationAction> _buildChatActions(Map<String, dynamic> data) {
    final messageId = data['messageId'] ?? '';
    final conversationId = data['conversationId'] ?? '';
    return [
      // Reply button with inline text input — showsUserInterface: false
      // so user can type and send reply WITHOUT opening the app
      AndroidNotificationAction(
        'reply_message_$messageId',
        'Reply',
        showsUserInterface: false,
        inputs: <AndroidNotificationActionInput>[
          const AndroidNotificationActionInput(
            label: 'Type a message...',
          ),
        ],
      ),
      // Mark as Read button — silently dismisses
      AndroidNotificationAction(
        'mark_read_$conversationId',
        'Mark as Read',
        showsUserInterface: false,
      ),
    ];
  }

  /// Parse action buttons from the FCM data 'actions' field (for non-chat notifications)
  List<AndroidNotificationAction> _parseNotificationActions(
      Map<String, dynamic> data) {
    final List<AndroidNotificationAction> actions = [];
    try {
      final actionsJson = data['actions'] ?? '[]';
      final List<dynamic> parsed = jsonDecode(actionsJson);
      for (final action in parsed) {
        if (action is Map && action['id'] != null && action['text'] != null) {
          actions.add(AndroidNotificationAction(
            action['id'].toString(),
            action['text'].toString(),
            showsUserInterface: true,
          ));
        }
      }
    } catch (_) {}
    return actions;
  }

  /// Handle an `operation: incoming_call` FCM push while the app is in
  /// foreground. Mirrors the background handler in main.dart: parses the
  /// caller payload and shows CallKit. showFlutterCallNotification already
  /// guards against duplicate UI when the socket path has a call in progress.
  void _handleIncomingCallPush(RemoteMessage message) {
    try {
      final data = message.data;
      final callerImage = (data['senderProfileImage'] ?? '').toString();

      final payloadRaw = data['payload'];
      final Map<String, dynamic> payload = payloadRaw is String
          ? (jsonDecode(payloadRaw) as Map<String, dynamic>)
          : Map<String, dynamic>.from(payloadRaw ?? {});

      final callerRaw = data['callerData'];
      final Map<String, dynamic> callerData = callerRaw is String
          ? (jsonDecode(callerRaw) as Map<String, dynamic>)
          : Map<String, dynamic>.from(callerRaw ?? {});

      // Resolve the caller name from the push, then the caller profile, so the
      // notification never displays a raw "Unknown".
      final callerName = resolveCallerName(data, callerData);

      final callType = (payload['call_type'] ?? 'audio_call').toString();
      final callId = (payload['call_id'] ?? '').toString();
      final roomId = (payload['room_id'] ?? '').toString();
      if (callId.isEmpty || roomId.isEmpty) {
        log('[CALL_DEBUG] _handleIncomingCallPush → missing call_id/room_id, skipping');
        return;
      }

      final metadata = payload['metadata'];
      final isFareCall =
          metadata is Map && metadata['orderType'] == 'fare-call';

      String designation = 'Incoming Call';
      final accountType = (callerData['account_type'] ?? '').toString();
      if (accountType == 'BUSINESS') {
        var biz = callerData['businessData'];
        if (biz is String) {
          try {
            biz = jsonDecode(biz);
          } catch (_) {}
        }
        if (biz is Map) {
          final cat = biz['category_of_business'];
          if (cat != null && cat.toString().isNotEmpty) {
            designation = cat.toString();
          } else {
            final subCat = biz['sub_category_of_business'];
            if (subCat is Map) {
              final name = subCat['name'];
              if (name != null && name.toString().isNotEmpty) {
                designation = name.toString();
              }
            }
          }
        }
      } else {
        final d = (callerData['designation'] ?? '').toString();
        if (d.isNotEmpty) designation = d.toLowerCase();
      }
      if (isFareCall) designation = 'Ride Request';

      // If the socket already picked up this call (CallController is not
      // idle and knows this callId), skip — the in-app incoming screen is
      // already showing.
      if (Get.isRegistered<CallController>()) {
        final ctrl = Get.find<CallController>();
        final alreadyHandling = ctrl.callStatus.value != CallStatus.idle &&
            ctrl.callId.value == callId;
        if (alreadyHandling) {
          log('[CALL_DEBUG] _handleIncomingCallPush → already handled by socket, skipping');
          return;
        }

        // Foreground on Android: Android suppresses full-screen CallKit
        // intents while the app is visible, so showCallkitIncoming renders
        // inconsistently (OEM-dependent heads-up only, or nothing). Instead
        // push CallController state and navigate directly to the in-app
        // incoming screen — this is the same path the socket listener uses.
        if (Platform.isAndroid && ctrl.callStatus.value == CallStatus.idle) {
          log('[CALL_DEBUG] _handleIncomingCallPush → foreground Android, navigating to IncomingCallScreen');
          ctrl.callId.value = callId;
          ctrl.roomId.value = roomId;
          ctrl.conversationId.value =
              (data['conversationId'] ?? payload['conversation_id'] ?? '')
                  .toString();
          ctrl.callType.value =
              callType == 'video_call' ? CallType.video : CallType.audio;
          ctrl.isGroupCall.value = payload['is_group'] == true;
          ctrl.isCaller.value = false;
          ctrl.callerName.value = callerName;
          ctrl.callerImage.value = callerImage;
          ctrl.remoteUserName.value = callerName;
          ctrl.remoteUserImage.value = callerImage;
          // CRITICAL: set remote user id so acceptCall can build the peer
          // connection. Without this, WebRTC setup bails and the 30s
          // connection timeout auto-ends the call with ended_by=self.
          final callerUserId = (data['senderId'] ??
                  callerData['id'] ??
                  payload['initiated_by'] ??
                  '')
              .toString();
          ctrl.setRemoteUserIdFromPush(callerUserId);
          ctrl.callStatus.value = CallStatus.ringing;
          if (!isFareCall && Get.currentRoute != '/IncomingCallScreen') {
            Get.toNamed('/IncomingCallScreen');
          } else if (isFareCall &&
              Get.currentRoute != '/IncomingRiderOrderScreen') {
            Get.toNamed('/IncomingRiderOrderScreen');
          }
          return;
        }
      }

      // iOS or foreground-but-idle-not-possible fallback: show CallKit
      showFlutterCallNotification(
        callSessionId: callId,
        callerName: isFareCall
            ? (callerName.isNotEmpty ? callerName : 'Ride Request')
            : callerName,
        desiginations: designation,
        callerImage:
            (callerData['profile_image']?.toString().isNotEmpty ?? false)
                ? callerData['profile_image']
                : (callerImage.isNotEmpty ? callerImage : null),
        callType: callType,
        extra: {
          'senderId': (data['senderId'] ?? '').toString(),
          'conversationId': (data['conversationId'] ?? '').toString(),
          'callType': callType,
          'callerName': callerName,
          'callerImage': callerImage,
          'callId': callId,
          'roomId': roomId,
          'operation': 'incoming_call',
          if (isFareCall) 'isFareCall': 'true',
          if (isFareCall)
            'fareCallOrderId': (metadata['orderId'] ?? '').toString(),
          if (isFareCall)
            'fareCallRideDetails': jsonEncode(metadata['rideDetails'] ?? {}),
        },
      );
    } catch (e, st) {
      log('[CALL_DEBUG] _handleIncomingCallPush → error: $e\n$st');
    }
  }

  ///call when click on notification
  void onMsgOpen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final operation =
          (message.data['operation'] ?? '').toString().toLowerCase();
      log("jhsjhsbajhbdasjdhb  For ${message.data}");

      // Incoming call in foreground: show native CallKit UI immediately.
      // This is also a fallback when the socket `call:incoming` listener did
      // not fire (e.g. socket was disposed after a previous call). Without
      // this, subsequent calls get stuck on the caller side because the
      // callee never joins the room.
      //
      // iOS skip: iOS already receives a VoIP push via PushKit (AppDelegate)
      // which shows CallKit natively. If the backend also sends a parallel
      // APNs data push, this onMessage handler fires and a SECOND CallKit
      // is shown on top of the native one — the user sees two incoming-call
      // triggers. The VoIP path is authoritative on iOS, and the socket
      // `call:incoming` listener covers in-app foreground state, so we
      // intentionally drop the FCM duplicate here on iOS only.
      if (operation == 'incoming_call') {
        if (Platform.isIOS) {
          log('[CALL_DEBUG] onMessage incoming_call → iOS, skipping (VoIP PushKit already handled)');
          return;
        }
        _handleIncomingCallPush(message);
        return;
      }

      // Caller hung up — stop ringing and cancel notification
      if (operation == 'missed_call' || operation == 'call_cancelled') {
        try {
          final data = message.data;
          final payloadRaw = data['payload'];
          Map<String, dynamic> payload = {};
          if (payloadRaw is String && payloadRaw.isNotEmpty) {
            payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
          } else if (payloadRaw is Map) {
            payload = Map<String, dynamic>.from(payloadRaw);
          }
          final cId = (payload['call_id'] ?? data['callId'] ?? '').toString();
          if (cId.isNotEmpty) {
            cancelIncomingCallLocalNotification(cId);
          }
          // Stop in-app ringtone
          if (Get.isRegistered<CallController>()) {
            final ctrl = Get.find<CallController>();
            ctrl.stopRingtone();
            // If controller hasn't received socket cancel yet, clean up
            if (ctrl.callStatus.value == CallStatus.ringing) {
              ctrl.declineCall();
            }
          }
          // Dismiss CallKit on iOS
          if (Platform.isIOS && cId.isNotEmpty) {
            try {
              FlutterCallkitIncoming.endCall(cId);
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('[CALL_DEBUG] foreground missed_call handler error: $e');
        }
        return;
      }

      // Ride started push — update DiscoverController as fallback when the
      // socket ride:started event is missed (socket reconnect, different room, etc.)
      if (operation == 'ride_started') {
        try {
          if (Get.isRegistered<DiscoverController>()) {
            final dc = Get.find<DiscoverController>();
            if (!dc.isFareCallRideStarted.value) {
              dc.isFareCallRideStarted.value = true;
              dc.fareCallRideStartedData.value =
                  message.data.cast<String, dynamic>();
              debugPrint(
                  '[RIDE_DEBUG] foreground FCM ride_started → set isFareCallRideStarted=true');
            }
          }
        } catch (e) {
          debugPrint('[RIDE_DEBUG] foreground ride_started handler error: $e');
        }
      }

      // Ride completed push — same fallback for ride:completed socket event
      if (operation == 'ride_completed' ||
          operation == 'ride_order_completed') {
        try {
          if (Get.isRegistered<DiscoverController>()) {
            final dc = Get.find<DiscoverController>();
            if (!dc.isFareCallRideCompleted.value) {
              dc.isFareCallRideCompleted.value = true;
              dc.fareCallRideCompletedData.value =
                  message.data.cast<String, dynamic>();
              debugPrint(
                  '[RIDE_DEBUG] foreground FCM ride_completed → set isFareCallRideCompleted=true');
            }
          }
        } catch (e) {
          debugPrint(
              '[RIDE_DEBUG] foreground ride_completed handler error: $e');
        }
      }

      // Play custom sound for foreground notifications
      playCustomSound(message);

      // Use the generic data-only renderer for both platforms.
      // Data-only messages are NOT auto-displayed by Firebase,
      // so we must render them ourselves.
      showMsg(message);
    });

    /// when app is in background and user tap on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onTapNotificationFromStatusBar(message.data);
    });

    // iOS-only: when the backend sends a notification-type FCM (the only
    // thing the OS can display in terminated state, since data-only pushes
    // don't render a banner on iOS), tapping it from terminated state
    // launches the app WITHOUT going through our local-notification path.
    // `getNotificationAppLaunchDetails()` (Android path) returns null in
    // this case — only `getInitialMessage()` carries the payload. Android
    // keeps using local notifications and is unaffected.
    if (Platform.isIOS) {
      FirebaseMessaging.instance.getInitialMessage().then((initial) async {
        try {
          if (initial == null || initial.data.isEmpty) return;
          final data = Map<String, dynamic>.from(initial.data);
          final operation =
              (data['operation'] ?? '').toString().toLowerCase();

          // Wait for the navigator to be mounted before pushing. Splash is
          // blocked on `notificationNavigationCompleter` so this delay only
          // ever races with framework startup, not with user-driven nav.
          await Future.delayed(const Duration(milliseconds: 400));

          if (operation == 'incoming_call') {
            _openIncomingCallScreen(data);
          } else {
            await _onTapNotificationFromStatusBar(data, fromColdStart: true);
          }
        } catch (e) {
          print('[iOS-initial-message] error: $e');
        } finally {
          // Always unblock splash, even if routing failed or there was no
          // initial message. Otherwise splash sits on the loader for 5s
          // (the safety timeout) on every iOS cold-start when the flag was
          // set by checkNotificationLaunch().
          if (notificationNavigationCompleter != null &&
              !notificationNavigationCompleter!.isCompleted) {
            notificationNavigationCompleter!.complete();
          }
        }
      }).catchError((e) {
        print('[iOS-initial-message] outer error: $e');
        if (notificationNavigationCompleter != null &&
            !notificationNavigationCompleter!.isCompleted) {
          notificationNavigationCompleter!.complete();
        }
      });
    }
  }

  static Future<void> _onTapNotificationFromStatusBar(
    Map<String, dynamic> data, {
    bool fromColdStart = false,
  }) async {
    // Parse sender_user if it's a JSON string

    if (data['sender_user'] is String) {
      data['sender_user'] = jsonDecode(data['sender_user']);
    }

    // When launched from terminated state, push home screen first so the user
    // has a proper back stack after viewing the notification target screen.
    if (fromColdStart) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {'initialIndex': 0},
      );
      // Small delay for home screen to settle before pushing target
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // New-style notifications key off `type` rather than `operation`
    // (see NEW_NOTIFICATIONS_FRONTEND_GUIDE.md); fall back to it so their
    // body-tap routing works without disturbing the existing operations.
    final operation =
        (data['operation'] ?? data['type'] ?? '').toString().toLowerCase();
    logs("data==== ${data}");
    logs("operation==== ${operation}");
    // logs("operation==== ${data['payload']['post_id']}");
    // logs("operation==== ${data['payload']['post_id'].runtimeType}");
    switch (operation) {
      // Call operations
      case 'incoming_call':
        // Body tap on the incoming-call notification → show the in-app
        // IncomingCallScreen so the user can accept or decline. (The
        // dedicated Accept/Decline action buttons are routed earlier in
        // onForegroundNotificationResponse / _handleBackgroundNotificationResponse
        // and never reach this switch.)
        _openIncomingCallScreen(data);
        break;
      case 'missed_call':
        if (data['senderId'] != null) {
          _openChatWithUser(data['senderId']!);
        }
        break;

      // Chat / Message operations
      case 'sent_message':
      case 'encrypted_message':
      case 'message_reminder':
      case 'tagged_in_message':
      case 'commented_on_message':
      case 'liked_message':
        // Persist the incoming message to Hive BEFORE navigation so the
        // chat screen's local-first load shows it immediately — even on
        // cold-start from a killed app where the socket hasn't reconnected.
        await _persistFcmMessageToLocal(data);
        _openChatWithUser(data['senderId'] ?? '');
        break;

      // Post operations
      case 'created_post':
      case 'liked_post':
      case 'commented_on_post':
      case 'reposted_post':
      case 'tagged_on_post':
      case 'reacted_to_post':
      case 'reacted_to_comment':
      case 'replied_on_comment':
        _handlePostNavigation(data);
        break;
      case 'answered_question':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Reel operations
      case 'liked_reel':
      case 'commented_on_reel':
      case 'reposted_reel':
      case 'tagged_in_reel':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Connection operations
      case 'sent_connection_request':
      case 'received_connection_request':
      case 'accepted_connection_request':
      case 'followed_profile':
      case 'user_enrolled':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Fare ride incoming — open the rider order screen
      case 'fare_ride_incoming_call':
        AppNotificationHandler()._showRiderOrderScreen(data);
        break;

      // Ride operations
      case 'ride_order_created':
      case 'ride_order_received':
      case 'ride_order_accepted':
      case 'ride_order_picked_up':
      case 'ride_started':
      case 'ride_order_completed':
      case 'ride_completed':
      case 'ride_order_rejected':
      case 'ride_order_all_rejected':
      case 'ride_order_cancelled':
      case 'ride_cancelled_by_rider':
      case 'ride_payment_confirmed':
      case 'rider_onboarding_complete':
      // A new order surfaced on the rider's active route — open the rider
      // orders screen so they can view / claim it.
      case 'route_order_available':
        Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
        break;

      // Chat-dispatch OTP handoff nudge → open the chat that holds the card.
      case 'rider_otp':
        _openChatFromRiderOtp(data);
        break;

      // Job operations
      case 'new_application':
      case 'application_status_updated':
      case 'interview_scheduled':
      case 'interview_rescheduled':
      case 'interview_cancelled':
      case 'job_closed':
      case 'new_feedback_submitted':
      case 'applied_for_job':
        // Jobs → NotificationScreen hub. (AppliedJobsScreen requires a non-null
        // headerHeight arg and would crash when launched from a notification.)
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // AI Greetings
      case 'send_morning_greeting':
      case 'send_nightly_greeting':
        final chat = ChatViewController.personalAiChatModule;
        Get.to(() => AiChatScreen(
              profileImage: chat?.sender?.profileImage,
              name: chat?.sender?.name,
              type: chat?.sender?.accountType,
            ));
        break;

      // Admin notifications
      case 'admin_bulk_notification':
      case 'admin_system_announcement':
      case 'admin_urgent_broadcast':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Self-pickup order operations
      case 'selfpickup_order':
      case 'selfpickup_order_ready':
      case 'homemade_food_pickup_order':
      case 'homemade_food_pickup_order_ready':
        if (data['senderId'] != null) {
          _openChatWithUser(data['senderId']!);
        }
        break;

      // Symbol operations
      case 'symbol_created':
      case 'SYMBOL_CREATED':
        _openSymbolFromNotification(data);
        break;
      // Symbol engagement events reference an existing symbol but don't carry
      // the full payload the viewer needs → route to the hub.
      case 'symbol_viewed':
      case 'symbol_liked':
      case 'symbol_commented':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Rider association operations
      case 'rider_association_request':
      case 'rider_association_accepted':
      case 'rider_association_rejected':
      case 'rider_association_dissociated':
      case 'rider_association_expired':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Channel / tag operations
      case 'channel_created':
      case 'channel_claimed':
      case 'channel_updated':
      case 'channel_verified_owner':
      case 'channel_verified_follower':
      case 'channel_deleted_owner':
      case 'channel_deleted_follower':
      case 'channel_followed':
      case 'channel_unfollowed':
      case 'channel_reported':
      case 'channel_report_resolved':
      case 'channel_moderation_action':
      case 'channel_profile_significant_update':
      case 'channel_weekly_summary':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Follower milestones / engagement
      case 'follower_milestone_10':
      case 'follower_milestone_50':
      case 'follower_milestone_100':
      case 'follower_milestone_500':
      case 'follower_milestone_1000':
      case 'follower_milestone_5000':
      case 'follower_milestone_10000':
      case 'follower_milestone_50000':
      case 'follower_milestone_100000':
      case 'engagement_spike':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Social / profile operations
      case 'social_links_added':
      case 'social_links_updated':
      case 'social_links_removed':
      case 'bank_details_updated':
      case 'experience_verification':
      case 'profile_updated':
      case 'profile_completion_reminder':
      case 'new_user':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Reports
      case 'reported_post':
      case 'reported_reel':
      case 'reported_message':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Referrals
      case 'process_referral':
      case 'credit_referral_reward':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Forced-logout signal — NOT a tap target. Intentionally no navigation.
      case 'session_displaced':
        break;

      // Business go-live reminder — deep-link to the business own profile
      // (which hosts the Go Live button) and ask it to auto-prompt go-live.
      case 'business_go_live_reminder':
        Get.toNamed(
          RouteConstant.BusinessOwnProfileScreen,
          arguments: {
            'business_id': data['business_id'],
            'open_go_live': true,
          },
        );
        break;

      default:
        // Any future/unknown operation lands on the notification hub instead
        // of dead-ending.
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;
    }

    /// Clear all local notifications
    flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Build a SymbolDetailsModel from a SYMBOL_CREATED FCM payload and open
  /// the symbol viewer. Falls back to opening the sender's chat if the
  /// payload is malformed (so the tap never becomes a dead-end).
  static void _openSymbolFromNotification(Map<String, dynamic> data) {
    try {
      final rawPayload = data['payload'];
      if (rawPayload == null) return;
      final Map<String, dynamic> payload = rawPayload is String
          ? Map<String, dynamic>.from(jsonDecode(rawPayload) as Map)
          : Map<String, dynamic>.from(rawPayload as Map);

      final symbolId = payload['symbol_id']?.toString();
      if (symbolId == null || symbolId.isEmpty) return;

      final senderId = data['senderId']?.toString();
      final senderName = data['senderName']?.toString();
      final senderImage = data['senderProfileImage']?.toString();

      DateTime? _parseDate(dynamic v) {
        if (v == null) return null;
        return DateTime.tryParse(v.toString());
      }

      final symbol = SymbolDetailsModel(
        id: symbolId,
        userId: senderId,
        type: payload['type']?.toString(),
        content: payload['content']?.toString(),
        caption: payload['caption']?.toString(),
        backgroundColor: payload['backgroundColor']?.toString(),
        fontFamily: payload['fontFamily']?.toString(),
        fontSize: payload['fontSize'] is num
            ? (payload['fontSize'] as num).toDouble()
            : null,
        fontWeight: payload['fontWeight']?.toString(),
        visibility: payload['visibility']?.toString(),
        expiresAt: _parseDate(payload['expires_at']),
        createdAt: _parseDate(payload['created_at']),
        user: UserModel(
          id: senderId,
          name: senderName,
          profileImage: senderImage,
        ),
      );

      Get.to(() => SymbolViewImages(
            initialSymbol: symbol,
            userId: senderId,
            name: senderName,
            profileImage: senderImage,
          ));
    } catch (e) {
      logs('Failed to open symbol from notification: $e');
    }
  }

  static void _handlePostNavigation(Map<String, dynamic> data) {
    if (data['payload'] != null) {
      final payloadMap = jsonDecode(data['payload']);
      final String operation = data['operation'] ?? '';
      final String? repostId = payloadMap['repost_id'];

      Get.to(
        () => PostDeatilPage(),
        arguments: {
          "postId": (operation == 'reposted_post' && repostId != null)
              ? repostId
              : payloadMap['post_id'],
          "operation":operation
        },
      );
    }
  }

  /// Extract a chat message out of an FCM data payload and persist it to the
  /// local Hive cache so the chat screen shows it immediately on open — even
  /// when the socket hasn't reconnected yet (cold-start from killed state).
  /// Accepts either a nested `message` map or flat `message_id`/`message`/etc.
  /// fields. Silently no-ops if required identifiers are missing.
  static Future<void> _persistFcmMessageToLocal(
      Map<String, dynamic> data) async {
    try {
      final String conversationId =
          (data['conversationId'] ?? data['conversation_id'] ?? '').toString();
      if (conversationId.isEmpty) return;

      Map<String, dynamic>? messageJson;

      // Server sometimes nests a fully-formed message map under `message`.
      final nested = data['message'];
      if (nested is Map) {
        messageJson = Map<String, dynamic>.from(nested);
      } else if (nested is String && nested.isNotEmpty) {
        try {
          final decoded = jsonDecode(nested);
          if (decoded is Map) {
            messageJson = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Flat payload — fall through to the synthesized path.
        }
      }

      // Fall back to synthesizing a minimal Messages JSON from flat fields
      // the backend commonly ships (message_id, message_body, message_type).
      messageJson ??= <String, dynamic>{
        '_id': (data['message_id'] ?? data['messageId'] ?? '').toString(),
        'message':
            (data['message_body'] ?? data['body'] ?? data['message'] ?? '')
                .toString(),
        'message_type':
            (data['message_type'] ?? data['messageType'] ?? 'text').toString(),
        'sender_id': (data['senderId'] ?? data['sender_id'] ?? '').toString(),
        'conversation_id': conversationId,
        'createdAt':
            (data['createdAt'] ?? DateTime.now().toUtc().toIso8601String())
                .toString(),
      };

      // Without an id we can't dedupe; skip to avoid polluting the cache.
      final msgId = (messageJson['_id'] ?? messageJson['id'] ?? '').toString();
      if (msgId.isEmpty) return;

      final Messages message = Messages.fromJson(messageJson);
      message.conversationId = conversationId;
      await LocalStorageHelper()
          .saveSingleMessageToConversationId(conversationId, message);
    } catch (e) {
      // Best-effort — navigation must still proceed even if this fails.
      logs('[_persistFcmMessageToLocal] failed: $e');
    }
  }

  /// Claims a route order from the ROUTE_ORDER_AVAILABLE notification's
  /// "Claim Order" button, then opens the rider orders screen on success.
  /// See docs/backend/NEW_NOTIFICATIONS_FRONTEND_GUIDE.md.
  static Future<void> _handleClaimOrder(String orderId) async {
    if (orderId.isEmpty) return;
    final controller = getOrPut(() => DeliverPartnerOrdersController());
    final claimed = await controller.claimRouteOrder(orderId);
    if (claimed) {
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
    }
  }

  /// Opens the chat that received a `rider_otp` handoff card. Chat opens are
  /// keyed on the other party's userId (which resolves the conversation
  /// server-side), so we prefer a user id from the payload and fall back to
  /// the chat contacts list when the push only carries a conversationId.
  static void _openChatFromRiderOtp(Map<String, dynamic> data) {
    final senderUser = data['sender_user'];
    final candidates = <dynamic>[
      data['senderId'],
      data['sender_id'],
      data['otherUserId'],
      data['other_user_id'],
      (senderUser is Map) ? senderUser['id'] : null,
    ];
    final userId = candidates
        .firstWhere(
          (e) => e != null && e.toString().isNotEmpty,
          orElse: () => null,
        )
        ?.toString();
    if (userId != null && userId.isNotEmpty) {
      _openChatWithUser(userId);
      return;
    }
    // Only a conversationId is available — land the user on their chat list
    // so they can open the conversation holding the OTP card.
    Get.toNamed(RouteHelper.getChatContactsRoute());
  }

  /// Helper to open chat with a user by their ID
  static void _openChatWithUser(String userId) {
    if (userId.isEmpty) return;
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.connectSocket();
    Future.delayed(const Duration(milliseconds: 200), () {
      chatViewController.checkChatConnectionAndOpenChat(userId: userId);
    });
  }

  /// Open the incoming-call receiving screen from a notification body tap.
  /// Hydrates CallController state from the notification payload (the same
  /// shape `showIncomingCallLocalNotification` writes) so the screen can
  /// render the caller name/image and so Accept/Decline buttons can fire
  /// the correct API calls. Skips opening if a call for the same id is
  /// already being handled (avoids stomping on auto-accept paths).
  static void _openIncomingCallScreen(Map<String, dynamic> data) {
    final callId = (data['callId'] ?? '').toString();
    if (callId.isEmpty) return;

    cancelIncomingCallLocalNotification(callId);

    final ctrl = getOrPut(() => CallController());

    final activeStatus = ctrl.callStatus.value;
    final activeId = ctrl.callId.value;
    if (activeId == callId &&
        (activeStatus == CallStatus.accepting ||
            activeStatus == CallStatus.connecting ||
            activeStatus == CallStatus.connected)) {
      return;
    }

    ctrl.initStateFromCallKitExtra(data);

    // Start the in-app ringtone as soon as the incoming screen opens.
    // iOS terminated-state banners now play APNs `sound: default` when they
    // arrive (backend change), so the user hears the initial ring. Tapping
    // the banner dismisses it and stops that system sound — without this
    // in-app ringtone, the IncomingCallScreen would be silent while the
    // user decides whether to accept. Safe on Android: its local
    // notification-channel sound stops the moment the notification is
    // tapped/removed, so there's no double-playing.
    ctrl.startRingtone();

    if (Get.currentRoute != '/IncomingCallScreen') {
      Get.toNamed('/IncomingCallScreen');
    }
  }

  ///SET AUDIO SOUND....
  Future<void> playCustomSound(RemoteMessage dataNotificationResponse) async {
    final operation = (dataNotificationResponse.data['operation'] ?? '')
        .toString()
        .toLowerCase();
    String playNotificationSound;

    // Don't play custom sound for incoming calls (CallKit handles its own ringtone)
    if (operation == 'incoming_call') return;

    try {
      if (operation == 'sent_message' ||
          operation == 'message_reminder' ||
          operation == 'tagged_in_message' ||
          operation == 'commented_on_message' ||
          operation == 'liked_message') {
        playNotificationSound = chatNotificationSound;
      } else if (operation == 'ride_order_received' ||
          operation == 'ride_order_accepted' ||
          operation == 'ride_order_created' ||
          operation == 'selfpickup_order' ||
          operation == 'selfpickup_order_ready' ||
          operation == 'homemade_food_pickup_order' ||
          operation == 'homemade_food_pickup_order_ready') {
        playNotificationSound = hello_delivery;
      } else {
        playNotificationSound = chatNotificationSound;
        // playNotificationSound = notificationSound;
      }
    } on Exception {
      playNotificationSound = chatNotificationSound;
      // playNotificationSound = notificationSound;
    }

    try {
      await audioPlayer.play(AssetSource(playNotificationSound));
    } on Exception catch (e) {
      logs("SOUND ERROR====${e.toString()}");
    }
  }

  Future<void> checkNotificationPermission() async {
    // Check current permission
    final status = await Permission.notification.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      // Non-mandatory: user can dismiss via the close icon or "Skip".
      // Both routes funnel through `_showSkipNotificationWarning` so the
      // user is reminded what they'll miss before continuing.
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.notificationPermissionRequired.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () {
                  Get.back();
                  _showSkipNotificationWarning();
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 22, color: Colors.black54),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                AppStrings.enableNotificationForChatHint.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PositiveCustomBtn(
                  onTap: () async {
                    Get.back();

                    // Request permission
                    final newStatus = await Permission.notification.request();
                    if (!newStatus.isGranted) {
                      // If still denied, open settings
                      await openAppSettings();
                    }
                  },
                  title: AppStrings.grantPermission.tr),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Get.back();
                  _showSkipNotificationWarning();
                },
                child: CustomText(
                  AppStrings.skip.tr,
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w600,
                  decorationColor: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: true,
      );
    }
  }

  /// Reminder shown when the user dismisses the notification permission
  /// prompt. Notifications drive order updates, ride alerts and chat
  /// messages — without them those features are silent.
  void _showSkipNotificationWarning() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 30,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            CustomText(
              AppStrings.youllMissImportantAlerts.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: CustomText(
          AppStrings.skipNotificationsHint.tr,
          textAlign: TextAlign.center,
          fontSize: 14,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(
              AppStrings.continueWithout.tr,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          PositiveCustomBtn(
            onTap: () async {
              Get.back();
              final newStatus = await Permission.notification.request();
              if (!newStatus.isGranted) {
                await openAppSettings();
              }
            },
            title: AppStrings.enable.tr,
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      barrierDismissible: true,
    );
  }
}
