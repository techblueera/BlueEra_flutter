// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/local_strorage_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
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
    print("Get.isRegistered<CallController>()=== ${Get.isRegistered<CallController>()}");
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
        replyText:
            (response.input != null && response.input!.isNotEmpty)
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
  print("NOTI 2 ${response.payload==null}");
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
        final apiUrl = (callBaseUrl ?? 'https://call.blueera.ai/') + 'call/decline';
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
    await storage.write(
        key: _kPendingIncomingCallAcceptKey, value: callId);
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
    const nativeChannel = MethodChannel('com.bluehr.incoming_call_notification');
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
        isVideo?'Video':'Accept',
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
    const nativeChannel = MethodChannel('com.bluehr.incoming_call_notification');
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

  /// True when the app was launched by tapping a notification (from terminated state).
  /// SplashScreen checks this to hold its UI instead of navigating to home.
  static bool launchedFromNotification = false;

  /// Completes when notification-based navigation has finished.
  /// SplashScreen awaits this before deciding its own navigation.
  static Completer<void>? notificationNavigationCompleter;

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
      print(
          "===ios-notification-auth=== ${settings.authorizationStatus}");
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

    ///Get FCM Token..
    await getFcmToken();

    // Re-sync whatever token we have now with the backend. FCM's
    // device_token is only POSTed inside verifyOTP at first login, so any
    // token rotation since then leaves the server routing APNs/FCM pushes
    // to a dead token — which is exactly why iOS bg/terminated chat
    // notifications stopped arriving.
    final cachedToken = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.notificationDeviceToken);
    if (cachedToken is String && cachedToken.isNotEmpty) {
      await _registerDeviceTokenWithBackend(cachedToken);
    }

    // Persist rotated FCM tokens so the backend always has the current one.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("===fcm-token-refresh=== $newToken");
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.notificationDeviceToken, newToken);
      await _registerDeviceTokenWithBackend(newToken);
    });

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
      _syncVoipTokenToBackend();
    }
  }

  /// Poll `flutter_callkit_incoming` for the VoIP token that iOS hands to
  /// PushKit (forwarded in `AppDelegate.swift` via
  /// `setDevicePushTokenVoIP`), then PUT it to the backend's user-update
  /// endpoint. Safe to call multiple times — idempotent on the server side
  /// because the payload is just `{voip_token: ...}`. Silent: no UI side
  /// effects, non-fatal on any failure path.
  static Future<void> _syncVoipTokenToBackend() async {
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

    // Avoid pointless network calls if the token hasn't changed since last
    // session. Stored under a separate key so it can't collide with the FCM
    // token cache.
    const String voipCacheKey = 'voipTokenCache';
    try {
      final cached =
          await SharedPreferenceUtils.getSecureValue(voipCacheKey);
      if (cached is String && cached == voipToken) {
        print("===voip-token-sync=== skipped (unchanged)");
        return;
      }
    } catch (_) {}

    try {
      await ApiBaseHelper().putHTTP(
        'user-service/user/updateUser',
        params: {'voip_token': voipToken},
        showProgress: false,
        onError: (e) {
          print("===voip-token-sync=== error: $e");
        },
        onSuccess: (_) {
          print("===voip-token-sync=== ok");
        },
      );
      await SharedPreferenceUtils.setSecureValue(voipCacheKey, voipToken);
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
      print("===fcm-token-sync=== skipped (no auth token)");
      return;
    }
    try {
      await ApiBaseHelper().putHTTP(
        'user-service/user/updateUser',
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

  ///get fcm token
  static Future<void> getFcmToken() async {
    final fcmToken = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.notificationDeviceToken);
    logs("fcmToken==== $fcmToken");
    if (fcmToken == null || fcmToken.toString().isEmpty) {
      FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      try {
        // On iOS, getToken() fails with apns-token-not-set if APNs has not
        // yet attached a device token. Guard here in case callers invoke
        // getFcmToken() outside the init flow.
        if (Platform.isIOS) {
          final apns = await firebaseMessaging.getAPNSToken();
          if (apns == null || apns.isEmpty) {
            print(
                "=========fcm- skipped: APNS token not ready on iOS");
            return;
          }
        }
        String? newFcmToken = await firebaseMessaging.getToken();
        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.notificationDeviceToken, newFcmToken);
        print("=========fcm-token===$newFcmToken =====END ");
      } catch (e) {
        print("=========fcm- Error :$e");
        return;
      }
    }
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
      final callerName = (data['senderName'] ?? 'Unknown').toString();
      final callerImage = (data['senderProfileImage'] ?? '').toString();

      final payloadRaw = data['payload'];
      final Map<String, dynamic> payload = payloadRaw is String
          ? (jsonDecode(payloadRaw) as Map<String, dynamic>)
          : Map<String, dynamic>.from(payloadRaw ?? {});

      final callerRaw = data['callerData'];
      final Map<String, dynamic> callerData = callerRaw is String
          ? (jsonDecode(callerRaw) as Map<String, dynamic>)
          : Map<String, dynamic>.from(callerRaw ?? {});

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
        final alreadyHandling =
            ctrl.callStatus.value != CallStatus.idle &&
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
              (data['conversationId'] ?? payload['conversation_id'] ?? '').toString();
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
        callerImage: (callerData['profile_image']?.toString().isNotEmpty ?? false)
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
          if (isFareCall) 'fareCallOrderId': (metadata['orderId'] ?? '').toString(),
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
            try { FlutterCallkitIncoming.endCall(cId); } catch (_) {}
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
              dc.fareCallRideStartedData.value = message.data.cast<String, dynamic>();
              debugPrint('[RIDE_DEBUG] foreground FCM ride_started → set isFareCallRideStarted=true');
            }
          }
        } catch (e) {
          debugPrint('[RIDE_DEBUG] foreground ride_started handler error: $e');
        }
      }

      // Ride completed push — same fallback for ride:completed socket event
      if (operation == 'ride_completed' || operation == 'ride_order_completed') {
        try {
          if (Get.isRegistered<DiscoverController>()) {
            final dc = Get.find<DiscoverController>();
            if (!dc.isFareCallRideCompleted.value) {
              dc.isFareCallRideCompleted.value = true;
              dc.fareCallRideCompletedData.value = message.data.cast<String, dynamic>();
              debugPrint('[RIDE_DEBUG] foreground FCM ride_completed → set isFareCallRideCompleted=true');
            }
          }
        } catch (e) {
          debugPrint('[RIDE_DEBUG] foreground ride_completed handler error: $e');
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

    // iOS-only: when the backend sends a notification-type FCM for a call
    // (the only thing the OS can display in terminated state, since data-only
    // pushes don't render a banner on iOS), tapping it from terminated state
    // launches the app WITHOUT going through our local-notification path.
    // `getNotificationAppLaunchDetails()` (Android path) returns null in this
    // case — only `getInitialMessage()` carries the payload. Android keeps
    // using local notifications and is unaffected.
    if (Platform.isIOS) {
      FirebaseMessaging.instance.getInitialMessage().then((initial) {
        if (initial == null) return;
        final operation =
            (initial.data['operation'] ?? '').toString().toLowerCase();
        if (operation == 'incoming_call') {
          _openIncomingCallScreen(Map<String, dynamic>.from(initial.data));
        } else {
          _onTapNotificationFromStatusBar(
              Map<String, dynamic>.from(initial.data),
              fromColdStart: true);
        }
      }).catchError((e) {
        print('[iOS-initial-message] error: $e');
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

    final operation = (data['operation'] ?? '').toString().toLowerCase();
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
      case 'ride_order_rejected':
      case 'ride_order_cancelled':
      case 'ride_cancelled_by_rider':
      case 'ride_payment_confirmed':
      case 'rider_onboarding_complete':
        Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
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
        // Navigate to jobs section
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
        // Navigate to notifications screen
        break;

      // Self-pickup order operations
      case 'selfpickup_order':
      case 'selfpickup_order_ready':
        if (data['senderId'] != null) {
          _openChatWithUser(data['senderId']!);
        }
        break;

      default:
        // Default: open notifications screen or home
        break;
    }

    /// Clear all local notifications
    flutterLocalNotificationsPlugin.cancelAll();
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
        'sender_id':
            (data['senderId'] ?? data['sender_id'] ?? '').toString(),
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
      await LocalStorageHelper().saveSingleMessageToConversationId(
          conversationId, message);
    } catch (e) {
      // Best-effort — navigation must still proceed even if this fails.
      logs('[_persistFcmMessageToLocal] failed: $e');
    }
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
          operation == 'selfpickup_order_ready') {
        playNotificationSound = hello_delivery;
      } else {
        playNotificationSound = notificationSound;
      }
    } on Exception {
      playNotificationSound = notificationSound;
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
      // Show custom GetX dialog to request permission
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            title: CustomText(
              "Notification Permission Required",
              fontSize: 16,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  "Please enable notification permission to use chat features.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PositiveCustomBtn(
                    onTap: () async {
                      Get.back(); // Close dialog if granted

                      // Request permission
                      final newStatus = await Permission.notification.request();
                      if (newStatus.isGranted) {
                        Get.back(); // Close dialog if granted
                      } else {
                        // If still denied, open settings
                        await openAppSettings();
                      }
                    },
                    title: "Grant Permission"),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: CustomText(
                    "Skip",
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
        ),
        barrierDismissible: false,
      );
    }
  }
}
