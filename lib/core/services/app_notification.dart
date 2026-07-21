// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/session_guard.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/local_strorage_helper.dart';
import 'package:BlueEra/core/services/notification/pending_deep_link.dart';
import 'package:BlueEra/features/chat/auth/controller/add_chat_symbol_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/notification_chat/controller/blueera_notification_controller.dart';
import 'package:BlueEra/features/chat/notification_chat/view/blueera_notification_screen.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/auth/socket/chat_socket.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen_v2.dart';
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
import 'ride_notification_router.dart';
import 'ride_ring_notification.dart';
import '../../features/common/Discover/controller/discover_controller.dart';
import '../../features/chat/view/ai_chat/view/ai_chat_screen.dart';
import '../routes/route_helper.dart';
import '../routes/route_constant.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';

String notificationSound = 'sound/hangouts_call.mp3';
String hello_delivery = 'sound/hello_delivery.mp3';
String chatNotificationSound = 'sound/messenger.mp3';
String foodpanda_order_an = 'sound/new_order_mu.mp3';

/// Dedicated Android channel for order alerts.
///
/// `foodpanda_order_an` above is a Flutter ASSET played via `audioplayers` in
/// [AppNotificationHandler.playCustomSound] — that only works in the
/// FOREGROUND. In background/terminated the OS plays the *notification
/// channel's* sound, so the order chime must also exist as an Android raw
/// resource (android/app/src/main/res/raw/new_order_mu.mp3) attached to a
/// channel. Both point at the same audio file.
///
/// The id is versioned: Android freezes a channel's sound at creation time and
/// resurrects the old settings if the same id is recreated, so changing the
/// sound REQUIRES a new id. v3 = the `new_order_mu` sound (v1/v2 were the older
/// `foodpanda_order_an` chime and are deleted in [firebaseNotificationSetup]).
/// If you change the sound again, bump to v4 — editing this constant's sound
/// alone will NOT take effect on devices that already have the channel.
const String orderNotificationChannelId = 'order_alerts_v3';
const String orderNotificationChannelName = 'Order Alerts';

/// Raw-resource name (no extension) of android/app/src/main/res/raw/new_order_mu.mp3.
const String orderNotificationRawSound = 'new_order_mu';

/// iOS bundle sound for order alerts. Must be added to the Runner target in
/// Xcode to play; iOS falls back to the default alert sound if it's missing.
const String orderNotificationIosSound = 'new_order_mu.mp3';

const Set<String> _orderNotificationOperations = {
  'food_pickup_order',
  'food_pickup_order_ready',
  'selfpickup_order',
  'selfpickup_order_ready',
  'grocery_order',
  'product_pickup_order',
  'product_pickup_order_ready',
  'homemade_food_pickup_order',
  'homemade_food_pickup_order_ready',
  'tiffin_pickup_order',
  'tiffin_pickup_order_ready',
  'medical_pickup_order',
  'medical_pickup_order_ready',
  'broadcast_ride_request'
};

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
    if (actionId.startsWith('incoming_call_decline_')) {
      final callId = (data['callId'] ?? '').toString();
      cancelIncomingCallLocalNotification(callId);
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().declineCall();
      }
      return;
    }

    // Fare ride / broadcast: Decline.
    //
    // Used to only dismiss the banner, which left the server still waiting on
    // this rider — for a broadcast that means the wave holds a slot for someone
    // who has already said no. Now it rejects over the API, without opening the
    // app (`showsUserInterface: false`).
    if (isRideDeclineAction(actionId)) {
      final orderId = orderIdFromRideActionId(
              actionId, kRideDeclineActionPrefixes) ??
          orderIdFromRidePayload(data);
      rideNotifLog('action: DECLINE orderId=${orderId ?? "(none)"}');
      AppNotificationHandler()._declineRideFromNotification(orderId);
      return;
    }

    // Fare ride / broadcast: View — open the rider order screen
    if (isRideViewAction(actionId)) {
      rideNotifLog('action: VIEW → IncomingRiderOrderScreen');
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
  if (response.payload == null) return;
  final data = json.decode(response.payload!) as Map<String, dynamic>;
  final actionId = response.actionId ?? '';

  // Initialize a local plugin instance (background isolate may not have the static one)
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // --- Fare ride / broadcast: Decline ---
  // Cancels the ring AND rejects server-side. Cancelling alone left the wave
  // holding a slot for a rider who had already said no, so the customer waited
  // out the full window for nothing. No GetX/navigation in this isolate — a
  // direct REST call, same shape as the incoming-call decline below.
  if (isRideDeclineAction(actionId)) {
    final orderId =
        orderIdFromRideActionId(actionId, kRideDeclineActionPrefixes) ??
            orderIdFromRidePayload(data);
    rideNotifLog('bg action: DECLINE orderId=${orderId ?? "(none)"}');
    await plugin.cancel(ringNotificationIdFor(orderId));
    if (orderId == null || orderId.isEmpty) {
      rideNotifLog('bg action: DECLINE has no orderId — cancelled ring only');
      return;
    }
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: SharedPreferenceUtils.authToken);
      if (token != null && token.isNotEmpty) {
        // `baseUrl` is not initialised in the FCM background isolate
        // (projectKeys() runs in main()), so fall back to the prod gateway —
        // same reason the call-decline path hardcodes its base.
        final api = (baseUrl ?? 'https://be.beapp.in/api/') +
            'rider-service/fare/orders/$orderId/ride-action';
        await dio.Dio().post(
          api,
          data: {'action': 'reject'},
          options: dio.Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'X-Device-Type': 'mobile',
            },
          ),
        );
        rideNotifLog('bg action: DECLINE posted for $orderId');
      }
    } catch (e) {
      rideNotifLog('bg action: DECLINE API failed for $orderId: $e');
    }
    return;
  }

  // --- Fare ride: View — showsUserInterface: true brings the app to foreground,
  // the default tap handler (_onTapNotificationFromStatusBar) will route it ---
  if (isRideViewAction(actionId)) {
    rideNotifLog('bg action: VIEW — app opening, tap routing takes over');
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
  // The order id is the suffix of the action id, and the router re-checks the
  // order's live status before deciding where to go — a notification tapped
  // hours later must not open a tracking map for a finished ride.
  final rideActionOrderId =
      RideNotificationRouter.orderIdFromActionId(actionId);
  if (rideActionOrderId != null) {
    RideNotificationRouter.open(
      rideActionOrderId,
      data: data,
      fallback: () => Get.toNamed(RouteHelper.getRiderServiceScreenRoute()),
    );
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

/// Non-destructive read of the stashed extras — used to detect that a
/// notification for a call is already showing without consuming the stash.
Future<Map<String, dynamic>?> peekPendingIncomingCallExtras() async {
  try {
    const storage = FlutterSecureStorage();
    final raw = await storage.read(key: _kPendingIncomingCallExtrasKey);
    if (raw == null || raw.isEmpty) return null;
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

  // The same call can be surfaced by BOTH the FCM path (rich payload with the
  // sender's name) and the socket call:incoming path (often nameless) — the
  // second show replaces the first notification, which is why the caller name
  // appeared and then vanished. Never overwrite an already-shown notification
  // for this call with a nameless one.
  if (callerName.isEmpty ||
      callerName == 'Unknown' ||
      callerName == 'Incoming Call') {
    final existing = await peekPendingIncomingCallExtras();
    if (existing != null && (existing['callId'] ?? '').toString() == callId) {
      return;
    }
  }

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
    // v2 — see the channel bootstrap in init(): the old id may be locked
    // silent on devices where it was first created without the ringtone.
    'incoming_calls_ringtone_v2',
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

  /// The in-flight [checkNotificationLaunch] future, set by main()'s
  /// `_initDeferred` the moment it kicks the check off. SplashScreen awaits
  /// this (bounded) before reading [launchedFromNotification] — without it,
  /// the splash timer could race the check, misread a notification launch as
  /// a normal one, and clobber the deep-link routing with home navigation.
  static Future<void>? notificationLaunchCheckFuture;

  /// True while a notification tap is re-navigating the root stack onto a new
  /// [BottomNavigationBarScreen] (currently the `admin_broadcast` broadcast
  /// flow). GetX builds the incoming host and disposes the outgoing one during
  /// the same transition, and BottomNavigationBarScreen.dispose() tears the
  /// chat socket down (clears every listener + nulls the socket). Without this
  /// guard that teardown races the reconnect we just kicked off and drops the
  /// broadcast-history fetch, so the tapped message never renders until the
  /// thread is reopened. dispose() honours this flag and keeps the warmed
  /// socket alive across the transition. Transient — cleared once the target
  /// chat has been opened.
  static bool suppressSocketDisposeForRenav = false;

  /// Completes when notification-based navigation has finished.
  /// SplashScreen awaits this before deciding its own navigation.
  static Completer<void>? notificationNavigationCompleter;

  /// The deep link currently being routed (set the moment a launch / tap
  /// payload is detected, BEFORE the home boot decisions run). main()'s
  /// `_initDeferred` reads this to defer the heavy background batch on a
  /// notification cold-start. See
  /// docs/backend/notification_fast_open_design.md (Phase 1 & 3).
  static PendingDeepLink? pendingDeepLink;

  /// Public, thin entry point onto the existing routing switch. Used by
  /// [NotificationRouter.route] so deep-link routing has a single owner while
  /// the per-type openers keep living in `_onTapNotificationFromStatusBar`.
  static Future<void> routeNotificationData(
    Map<String, dynamic> data, {
    bool fromColdStart = false,
  }) {
    return _onTapNotificationFromStatusBar(data, fromColdStart: fromColdStart);
  }

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
        // Record the deep link as early as possible so main()'s deferred-init
        // can skip the heavy home/background batch on a notification open.
        // Best-effort: a parse failure must not block launch detection.
        try {
          final data = jsonDecode(payLoad) as Map<String, dynamic>;
          pendingDeepLink = PendingDeepLink.fromData(data) ?? pendingDeepLink;
        } catch (_) {}
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
          pendingDeepLink =
              PendingDeepLink.fromData(initial.data) ?? pendingDeepLink;
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

    // ── Ringtone channels (v2) ────────────────────────────────────────────
    // Android RESURRECTS a deleted channel's previous settings when the same
    // id is recreated, so a channel that was ever created without the custom
    // ringtone can never be fixed in place — the id must change. Pre-create
    // the v2 channels here with the full ringtone config so the very first
    // notification on them already rings, and drop the stale legacy ids so
    // the user's channel list doesn't show silent duplicates.
    const AndroidNotificationChannel incomingCallsRingtoneV2 =
        AndroidNotificationChannel(
      'incoming_calls_ringtone_v2',
      'Incoming Calls',
      description: 'Incoming voice and video call alerts',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('hangouts_call'),
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );
    // Ride requests ring with the ORDER chime (`new_order_mu`), not the call
    // tone — see [kRideRingChannelId] for why the id is versioned.
    const AndroidNotificationChannel fareRideRingtone =
        AndroidNotificationChannel(
      kRideRingChannelId,
      kRideRingChannelName,
      description: kRideRingChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(kRideRingSound),
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );
    await androidPlugin?.createNotificationChannel(incomingCallsRingtoneV2);
    await androidPlugin?.createNotificationChannel(fareRideRingtone);
    // Drop the superseded channel so it stops showing as a stale, silent
    // "Ride Requests" entry in Android's per-app notification settings.
    await androidPlugin
        ?.deleteNotificationChannel('fare_ride_incoming_ringtone_v2');

    // Order alerts: dedicated channel carrying the order chime as a raw
    // resource. This is what makes the sound play in BACKGROUND/TERMINATED —
    // the OS plays the channel sound there, and audioplayers (playCustomSound)
    // only runs in the foreground. See the `orderNotification*` constants.
    const AndroidNotificationChannel orderAlertsChannel =
        AndroidNotificationChannel(
      orderNotificationChannelId,
      orderNotificationChannelName,
      description: 'New order alerts for sellers and customers',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(orderNotificationRawSound),
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
    await androidPlugin?.createNotificationChannel(orderAlertsChannel);

    for (final legacyId in [
      'incoming_calls_ringtone',
      'fare_ride_incoming_ringtone',
      'fare_ride_incoming',
      // Older order channels — frozen with the previous chime. Deleted so the
      // v3 channel above is the only one users see in system settings.
      'order_alerts_v1',
      'order_alerts_v2',
    ]) {
      await androidPlugin?.deleteNotificationChannel(legacyId);
    }

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
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
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
      return;
    }

    if (authTokenGlobal == null || authTokenGlobal!.isEmpty) {
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
        },
        onSuccess: (_) {
          // Cache ONLY on confirmed success so the unchanged-short-circuit
          // above can never suppress a delivery that never actually landed.
          SharedPreferenceUtils.setSecureValue(_voipCacheKey, voipToken);
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
        onSuccess: (_) {},
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
      return newToken;
    }

    // GMS never handed us a new token. Don't revert the cache to oldToken —
    // deleteToken() already invalidated it on FCM, so re-caching guarantees
    // the next sync POSTs a dead token. Clear the cache so the next session
    // triggers a fresh fetch; onTokenRefresh will sync the real new token to
    // the backend once GMS comes back.
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

    // Ride actions — status-checked before navigating. See the matching block
    // in the background/launch handler above.
    final rideActionOrderId =
        RideNotificationRouter.orderIdFromActionId(actionId);
    if (rideActionOrderId != null) {
      RideNotificationRouter.open(
        rideActionOrderId,
        data: data,
        fallback: () => Get.toNamed(RouteHelper.getRiderServiceScreenRoute()),
      );
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
    // Handle fare-call / broadcast incoming ride — show IncomingRiderOrderScreen
    // with ride details. Regular calls are handled by socket `call:incoming` in
    // CallController.
    if (kRingingRideOperations.contains(operation)) {
      rideNotifLog('foreground: RING op=$operation → IncomingRiderOrderScreen');
      rideNotifDumpPayload('foreground', message.data);
      try {
        _showRiderOrderScreen(message.data);
      } catch (e, st) {
        // Was swallowed silently, which made a foreground ride request that
        // never opened the screen impossible to diagnose.
        rideNotifLog('foreground: RING FAILED op=$operation: $e\n$st');
      }
      return;
    }

    // A broadcast race we LOST (or that expired). Silent by contract — kill
    // the ring and close the popup, never show a banner. Guide §7.4.
    if (operation == kBroadcastRideClosedOperation) {
      try {
        await dismissBroadcastRide(message.data);
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
        logs('_showRiderOrderScreen: payload parse error: $e');
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

      // Job descriptor (passenger ride / goods pickup / parcel delivery) —
      // fare-call pushes carry it inside rideDetails, standard ride-request
      // pushes carry it at the payload top level. IncomingRiderOrderScreen
      // reads these to label the job correctly instead of assuming "Ride".
      final jobType = ((rideDetails is Map ? rideDetails['jobType'] : null) ??
              payload['jobType'])
          ?.toString();
      final jobLabel = ((rideDetails is Map ? rideDetails['jobLabel'] : null) ??
              payload['jobLabel'])
          ?.toString();
      final callTitle =
          ((rideDetails is Map ? rideDetails['callTitle'] : null) ??
                  payload['callTitle'])
              ?.toString();
      final riderTask =
          ((rideDetails is Map ? rideDetails['riderTask'] : null) ??
                  payload['riderTask'])
              ?.toString();

      // The broadcast push carries the richest copy of the trip at the payload
      // ROOT — `pickup`/`drop` with lat+lng, `distanceKm`, `orderFor`, `fare`,
      // `orderType`, `expiresAt`, `ttl_seconds`. The legacy `metadata` branch
      // above only has `Pickup address` / `ridefare`, so distance came out 0
      // and orderFor empty even though both were sitting in the payload.
      final rootPickup = payload['pickup'];
      final rootDrop = payload['drop'];
      final double rootDistanceKm = _parseDouble(payload['distanceKm']);
      final String orderType = (payload['orderType'] ?? '').toString();
      final int ttlSeconds = _parseDouble(payload['ttl_seconds']).round();

      double pickLat = pickupLat, pickLng = pickupLng;
      double dropLatV = dropLat, dropLngV = dropLng;
      String pickAddr = pickupAddress, dropAddr = dropAddress;
      if (rootPickup is Map) {
        pickLat = _parseDouble(rootPickup['lat']) != 0
            ? _parseDouble(rootPickup['lat'])
            : pickLat;
        pickLng = _parseDouble(rootPickup['lng']) != 0
            ? _parseDouble(rootPickup['lng'])
            : pickLng;
        final a = (rootPickup['address'] ?? '').toString();
        if (a.isNotEmpty) pickAddr = a;
      }
      if (rootDrop is Map) {
        dropLatV = _parseDouble(rootDrop['lat']) != 0
            ? _parseDouble(rootDrop['lat'])
            : dropLatV;
        dropLngV = _parseDouble(rootDrop['lng']) != 0
            ? _parseDouble(rootDrop['lng'])
            : dropLngV;
        final a = (rootDrop['address'] ?? '').toString();
        if (a.isNotEmpty) dropAddr = a;
      }

      // Set fare-call ride details (initStateFromCallKitExtra doesn't handle these)
      callController.fareCallRideDetails.value = {
        'pickup': {
          'address': pickAddr.isNotEmpty ? pickAddr : 'Pickup location',
          'lat': pickLat,
          'lng': pickLng,
        },
        'drop': {
          'address': dropAddr.isNotEmpty ? dropAddr : 'Drop location',
          'lat': dropLatV,
          'lng': dropLngV,
        },
        'fare': fare > 0 ? fare : _parseDouble(payload['fare']),
        'distance': distance > 0 ? distance : rootDistanceKm,
        'modeOfPayment': modeOfPayment.isNotEmpty
            ? modeOfPayment
            : (payload['modeOfPayment'] ?? 'postpaid').toString(),
        'orderFor':
            orderFor.isNotEmpty ? orderFor : (payload['orderFor'] ?? '').toString(),
        // Drives whether Accept opens a call room (fare-call) or confirms the
        // order outright (broadcast — there is no VoIP call behind it).
        if (orderType.isNotEmpty) 'orderType': orderType,
        if (ttlSeconds > 0) 'ttlSeconds': ttlSeconds,
        if (payload['expiresAt'] != null)
          'expiresAt': payload['expiresAt'].toString(),
        if (jobType != null && jobType.isNotEmpty) 'jobType': jobType,
        if (jobLabel != null && jobLabel.isNotEmpty) 'jobLabel': jobLabel,
        if (callTitle != null && callTitle.isNotEmpty) 'callTitle': callTitle,
        if (riderTask != null && riderTask.isNotEmpty) 'riderTask': riderTask,
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
      logs('_showRiderOrderScreen ERROR: $e');
      logs('Stack: $stack');
    }
  }

  /// Another rider won the broadcast race (or it expired): stop the ring and
  /// close the incoming popup — **silently**.
  ///
  /// Losing a race is not an error and not news; a banner or toast here would
  /// interrupt a rider who is very likely already driving. See
  /// docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §7.4.
  Future<void> dismissBroadcastRide(Map<String, dynamic> data) async {
    // The dismissal push carries only the orderId, which is exactly why the
    // ring notification id is derived from it rather than the clock.
    Map<dynamic, dynamic>? metadata;
    final payloadRaw = data['payload'];
    try {
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        final decoded = jsonDecode(payloadRaw);
        if (decoded is Map) metadata = decoded['metadata'] as Map?;
      } else if (payloadRaw is Map) {
        metadata = payloadRaw['metadata'] as Map?;
      }
    } catch (_) {
      // Malformed payload — fall through and try the top-level keys.
    }

    final orderId = orderIdFromRidePayload(data, metadata: metadata);
    final notifId = ringNotificationIdFor(orderId);
    rideNotifLog(
      'dismiss: orderId=${orderId ?? "(none)"} notifId=$notifId '
      'route=${Get.currentRoute}',
    );

    // 1. Kill the ringing notification (FLAG_INSISTENT repeats until cancelled).
    try {
      await flutterLocalNotificationsPlugin.cancel(notifId);
      rideNotifLog('dismiss: ring cancelled (id=$notifId)');
    } catch (e) {
      rideNotifLog('dismiss: ring cancel FAILED (id=$notifId): $e');
    }

    // 2. Close the incoming screen, but ONLY if it's showing this order — a
    //    rider can be re-rung for a different ride while this push lands, and
    //    dismissing that one would cost them the job.
    try {
      if (Get.currentRoute != '/IncomingRiderOrderScreen') {
        rideNotifLog('dismiss: incoming screen not open — nothing to close');
        return;
      }
      if (orderId != null && orderId.isNotEmpty) {
        final openOrderId = Get.isRegistered<CallController>()
            ? Get.find<CallController>().fareCallOrderId.value
            : '';
        if (openOrderId.isNotEmpty && openOrderId != orderId) {
          rideNotifLog(
            'dismiss: screen shows a DIFFERENT order ($openOrderId) — kept open',
          );
          return;
        }
      }
      Get.back();
      rideNotifLog('dismiss: incoming screen closed');
    } catch (e) {
      rideNotifLog('dismiss: close FAILED: $e');
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

    // Mirror broadcast / system notifications (profile updates, admin
    // announcements, etc.) into the in-app "BlueEra" chat thread so they
    // surface as chat messages in the personal chat list. 1:1 chat messages
    // are excluded — they already have their own conversation rows.
    await _captureBlueEraNotification(
      operation: operation,
      title: title,
      body: body,
      isChatMessage: isChatMessage,
      images: extractBroadcastImages(data),
    );

    // Parse action buttons from backend
    List<Map<String, dynamic>> backendActions = [];
    try {
      backendActions = List<Map<String, dynamic>>.from(jsonDecode(actionsJson));
    } catch (_) {}

    // Map importance string to Android importance level
    final importance = _mapImportanceFromString(channelImportance);

    // Order alerts override the backend-provided channel with the dedicated
    // order channel + raw-resource sound, so the chime plays in
    // background/terminated too (the OS plays the channel sound there).
    // Passing `sound` in the details also makes flutter_local_notifications
    // create the channel on demand — important in the background isolate,
    // which never runs firebaseNotificationSetup().
    final bool isOrderNotification =
        _orderNotificationOperations.contains(operation);
    final String effChannelId =
        isOrderNotification ? orderNotificationChannelId : channelId;
    final String effChannelName =
        isOrderNotification ? orderNotificationChannelName : channelName;
    final Importance effImportance =
        isOrderNotification ? Importance.max : importance;
    final AndroidNotificationSound? orderSound = isOrderNotification
        ? const RawResourceAndroidNotificationSound(orderNotificationRawSound)
        : null;

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
      effChannelId,
      effChannelName,
      importance: effImportance,
      priority:
          effImportance == Importance.max || effImportance == Importance.high
              ? Priority.high
              : Priority.defaultPriority,
      playSound: true,
      sound: orderSound,
      enableVibration: true,
      icon: '@drawable/ic_stat',
      groupKey: groupKey.isNotEmpty ? groupKey : null,
      styleInformation: styleInformation,
      category: isChatMessage ? AndroidNotificationCategory.message : null,
      actions: androidActions,
    );

    // Build iOS notification details. Order alerts reference the bundled custom
    // sound (add new_order_mu.mp3 to the Runner target in Xcode for it to play;
    // falls back to the default alert sound if absent).
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: isOrderNotification ? orderNotificationIosSound : null,
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
            effChannelId,
            effChannelName,
            importance: effImportance,
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
  /// Append a broadcast/system push into the in-app "BlueEra" notification
  /// thread. Skips 1:1 chat messages (they have their own rows), AI greetings,
  /// and call/ride operations (handled by their own UI). Best-effort — never
  /// throws into the notification render path.
  Future<void> _captureBlueEraNotification({
    required String operation,
    required String title,
    required String body,
    required bool isChatMessage,
    List<String> images = const [],
  }) async {
    try {
      if (isChatMessage) return;
      if (operation.contains('call') ||
          operation.contains('ride') ||
          operation.contains('greeting')) {
        return;
      }
      if (title.trim().isEmpty && body.trim().isEmpty && images.isEmpty) return;
      // Awaited so the Hive write finishes before the background isolate is
      // torn down — a fire-and-forget put is dropped in background/terminated.
      await BlueEraNotificationController.to.addNotification(
        title: title,
        body: body,
        operation: operation,
        images: images,
      );
      // Mirror into the notification-hub local cache so the hub list reflects
      // this push without an API round-trip. Same guard as above (no chat /
      // call / ride / greeting); ride/call statuses the hub also shows are
      // reconciled on the next server sync instead of inserted here.
      await NotificationCacheService.to.upsertFromPush(
        operation: operation,
        title: title,
        body: body,
        images: images,
      );
    } catch (_) {}
  }

  /// Pull image URLs out of a broadcast payload. Supports a single `imageUrl`
  /// / `image` field and a multi-image `images` field (JSON-array string or a
  /// real List), plus the same keys nested under `payload`.
  static List<String> extractBroadcastImages(Map<String, dynamic> data) {
    final urls = <String>[];

    void addFrom(dynamic value) {
      if (value == null) return;
      if (value is String) {
        final s = value.trim();
        if (s.isEmpty) return;
        // A JSON array encoded as a string, e.g. '["https://a","https://b"]'.
        if (s.startsWith('[')) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is List) {
              for (final e in decoded) {
                final u = e.toString().trim();
                if (u.isNotEmpty) urls.add(u);
              }
              return;
            }
          } catch (_) {}
        }
        urls.add(s);
      } else if (value is List) {
        for (final e in value) {
          final u = e.toString().trim();
          if (u.isNotEmpty) urls.add(u);
        }
      }
    }

    addFrom(data['imageUrl']);
    addFrom(data['image']);
    addFrom(data['images']);

    // Nested payload object (may itself be a JSON string).
    final rawPayload = data['payload'];
    if (rawPayload != null) {
      try {
        final Map<String, dynamic> payload = rawPayload is String
            ? Map<String, dynamic>.from(jsonDecode(rawPayload) as Map)
            : Map<String, dynamic>.from(rawPayload as Map);
        addFrom(payload['imageUrl']);
        addFrom(payload['image']);
        addFrom(payload['images']);
      } catch (_) {}
    }

    // De-dup while preserving order.
    final seen = <String>{};
    return urls.where((u) => seen.add(u)).toList();
  }

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
          return;
        }

        // Foreground on Android: Android suppresses full-screen CallKit
        // intents while the app is visible, so showCallkitIncoming renders
        // inconsistently (OEM-dependent heads-up only, or nothing). Instead
        // push CallController state and navigate directly to the in-app
        // incoming screen — this is the same path the socket listener uses.
        if (Platform.isAndroid && ctrl.callStatus.value == CallStatus.idle) {
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
      logs('[CALL_DEBUG] _handleIncomingCallPush → error: $e\n$st');
    }
  }

  ///call when click on notification
  void onMsgOpen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final operation =
          (message.data['operation'] ?? '').toString().toLowerCase();

      // Single-session: the account was signed in on another device, so this
      // session was displaced server-side. logs out immediately (full teardown
      // + route to login) instead of waiting for the next request's 401 — but
      // ONLY if the displaced session is our own. SessionGuard filters out the
      // self-login echo (re-login on the same device displaces its own stale
      // session), which would otherwise logs the user out right after login.
      if (operation == 'session_displaced' || operation == 'force_logout') {
        if (await SessionGuard.shouldForceLogout(message.data)) {
          await AuthManager.handleLogout(null);
        }
        return;
      }

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
            }
          }
        } catch (e) {
          debugPrint(
              '[RIDE_DEBUG] foreground ride_completed handler error: $e');
        }
      }

      // Auto go-live: the backend cron opened this rider server-side, but
      // location freshness needs the app (map-service auto-closes providers
      // with a stale lastSeen after ~5 min). Flip the toggle + start the
      // periodic location pinger so the rider is genuinely live through the
      // window. Non-returning — falls through to render the "You're live!"
      // banner. See docs/backend/RIDER_GO_LIVE_GUIDE.md.
      if (operation == 'auto_golive_opened') {
        try {
          if (Get.isRegistered<ViewPersonalDetailsController>()) {
            Get.find<ViewPersonalDetailsController>()
                .getServiceProviderStatus();
          }
        } catch (e) {
          debugPrint(
              '[RiderAutoGoLive] foreground auto_golive_opened error: $e');
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
      // Tapping the auto-go-live banner (app was backgrounded but alive)
      // re-asserts live state + restarts the location pinger, same as the
      // foreground path. See RIDER_GO_LIVE_GUIDE.md.
      final op = (message.data['operation'] ?? '').toString().toLowerCase();
      if (op == 'auto_golive_opened') {
        try {
          if (Get.isRegistered<ViewPersonalDetailsController>()) {
            Get.find<ViewPersonalDetailsController>()
                .getServiceProviderStatus();
          }
        } catch (_) {}
      }
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
          final operation = (data['operation'] ?? '').toString().toLowerCase();

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
    // Record the deep link being routed so the cold-start boot can make its
    // essential-vs-background decisions. Never throws; safe for all payloads.
    pendingDeepLink = PendingDeepLink.fromData(data) ?? pendingDeepLink;

    // Parse sender_user if it's a JSON string

    if (data['sender_user'] is String) {
      data['sender_user'] = jsonDecode(data['sender_user']);
    }

    // New-style notifications key off `type` rather than `operation`
    // (see NEW_NOTIFICATIONS_FRONTEND_GUIDE.md); fall back to it so their
    // body-tap routing works without disturbing the existing operations.
    final operation =
        (data['operation'] ?? data['type'] ?? '').toString().toLowerCase();

    // When launched from terminated state, push home screen first so the user
    // has a proper back stack after viewing the notification target screen.
    //
    // `admin_broadcast` is excluded: it runs its OWN `offAllNamed` onto the
    // Connect tab (index 2) below. Doing the generic index-0 push here first
    // would spin up a bottom-nav host that the second `offAllNamed` disposes
    // mid-flow — and that dispose tears the chat socket down right after we
    // warmed it, dropping the broadcast-history fetch so the tapped message
    // never appears. One navigation → no mid-transition dispose.
    if (fromColdStart && operation != 'admin_broadcast') {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        // deferHeavyInit: the home is only the background host here, so its
        // Discover categories fetch waits until the user navigates a tab
        // instead of booting behind the deep-link target screen.
        arguments: {'initialIndex': 0, 'deferHeavyInit': true},
      );
      // Small delay for home screen to settle before pushing target
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Also capture broadcast/system notifications that were received in the
    // background and are now being tapped (these never pass through the
    // foreground `showFromData` funnel, so mirror them into the BlueEra thread
    // here). Chat/call/ride operations are excluded — they have their own UI.
    if (!(operation == 'sent_message' ||
        operation == 'message_reminder' ||
        operation == 'tagged_in_message' ||
        operation == 'commented_on_message' ||
        operation == 'liked_message' ||
        operation.contains('call') ||
        operation.contains('ride') ||
        operation.contains('greeting'))) {
      try {
        final title = (data['title'] ?? 'BlueEra').toString();
        final body = (data['body'] ?? data['message'] ?? '').toString();
        final images = extractBroadcastImages(data);
        if (title.trim().isNotEmpty ||
            body.trim().isNotEmpty ||
            images.isNotEmpty) {
          BlueEraNotificationController.to.addNotification(
            title: title,
            body: body,
            operation: operation,
            images: images,
          );
        }
      } catch (_) {}
    }
    switch (operation) {
      // Single-session: tapped the "signed out on another device" notification
      // → run the full logout teardown and land on the login screen, but only
      // if the displaced session is ours (SessionGuard drops the self-login
      // echo so a re-login on this same device does not logs the user out).
      case 'session_displaced':
      case 'force_logout':
        if (await SessionGuard.shouldForceLogout(data)) {
          AuthManager.handleLogout(null);
        }
        break;

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

      // Fare ride / broadcast incoming — open the rider order screen
      case 'fare_ride_incoming_call':
      case 'broadcast_ride_request':
        rideNotifLog(
          'tap: op=$operation orderId='
          '${RideNotificationRouter.orderIdFromPayload(data, metadata: _rideMetadataOf(data)) ?? "(none)"}'
          ' → IncomingRiderOrderScreen',
        );
        rideNotifDumpPayload('tap', data);
        AppNotificationHandler()._showRiderOrderScreen(data);
        break;

      // Broadcast race lost/expired — dismiss quietly, never surface anything.
      case 'broadcast_ride_closed':
        rideNotifLog('tap: op=$operation → dismissBroadcastRide');
        rideNotifDumpPayload('tap', data);
        AppNotificationHandler().dismissBroadcastRide(data);
        break;

      // Live-ride operations — the passenger wants the tracking map, the rider
      // wants their job screen, and either may be tapping this hours after the
      // ride ended. `RideNotificationRouter` re-reads the order status and
      // decides; it falls back to the rider screen when there's no order id.
      case 'ride_order_accepted':
      case 'ride_order_picked_up':
      case 'ride_started':
        rideNotifLog('tap: op=$operation');
        rideNotifDumpPayload('tap', data);
        RideNotificationRouter.open(
          RideNotificationRouter.orderIdFromPayload(data,
              metadata: _rideMetadataOf(data)),
          data: data,
          fallback: () => Get.toNamed(RouteHelper.getRiderServiceScreenRoute()),
        );
        break;

      // Terminal ride operations — nothing to track. Clear the floating
      // mini-map so it stops advertising an order that is over.
      case 'ride_order_completed':
      case 'ride_completed':
      case 'ride_order_cancelled':
      case 'ride_cancelled_by_rider':
        RideNotificationRouter.clearOngoingRideOverlay();
        Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
        break;

      // Ride operations
      case 'ride_order_created':
      case 'ride_order_received':
      case 'ride_order_rejected':
      case 'ride_order_all_rejected':
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

      // Admin broadcast (prodcast) → open the BlueEra chat the SAME way tapping
      // the BlueEra row inside ConnectMainPage does: the Admin
      // [PersonalChatScreen], NOT the read-only [BlueEraNotificationScreen].
      // Reset the stack onto the Connect (chat) tab first so that pressing back
      // from the BlueEra thread lands on ConnectMainPage rather than exiting the
      // app or dropping onto an unrelated screen.
      case 'admin_broadcast':
        // Warm the chat socket up front. Tapping the push resumes the app with
        // a socket that's often mid-backoff (2s→4s→…→32s); kicking an immediate
        // reconnect here means the handshake overlaps the settle delay +
        // navigation below, so the broadcast-history fetch in the chat screen
        // goes out on a live socket and the message shows fast. No-op when
        // already connected.
        // Guard the socket across the stack swap below: replacing the root with
        // a fresh bottom-nav host disposes the outgoing one (background tap) and
        // its dispose() would otherwise call disposeSocket() — killing the very
        // connection reconnectNow() just warmed and clearing its listeners, so
        // the broadcast-history fetch is dropped. dispose() honours this flag
        // and keeps the socket alive; cleared once the chat has opened below.
        suppressSocketDisposeForRenav = true;
        ChatSocketService().reconnectNow();
        BlueEraNotificationController.to.markAllRead();
        Get.offAllNamed(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          arguments: {ApiKeys.initialIndex: 2, 'deferHeavyInit': true},
        );
        // Let the Connect tab + its chat list settle before opening the chat.
        await Future.delayed(const Duration(milliseconds: 350));
        // Awaited: on a cold start _openBlueEraChat polls for the chat list to
        // load, so keep the socket-dispose guard held until it has actually
        // opened the broadcast thread (or exhausted its retries).
        await _openBlueEraChat(data);
        // The outgoing host's dispose() has run by now (it fires during the
        // transition above), so it's safe to drop the guard for the next
        // legitimate backgrounding-driven teardown.
        suppressSocketDisposeForRenav = false;
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
      // Enquiry-card pushes — new card + status change, per
      // lib/docs/enquiry-verticals-flutter-integration.md §"Push operations".
      // All five verticals land on the customer↔owner business chat, so the
      // routing matches the pickup-order pattern above. Vehicle is a booking
      // (buyer can also cancel) but the push routing is identical.
      case 'business_enquiry':
      case 'business_enquiry_status':
      case 'healthcare_enquiry':
      case 'healthcare_enquiry_status':
      case 'hotel_enquiry':
      case 'hotel_enquiry_status':
      case 'hotel_booking':
      case 'hotel_booking_status':
      case 'education_enquiry':
      case 'education_enquiry_status':
      case 'vehicle_booking':
      case 'vehicle_booking_status':
        if (data['senderId'] != null) {
          _openChatWithUser(data['senderId']!);
        }
        break;

      // Symbol operations
      case 'symbol_created':
      case 'SYMBOL_CREATED':
        _openSymbolFromNotification(data);
        break;
      // Symbol engagement events reference the current user's own symbols →
      // open the user's symbol viewer (same flow as tapping the profile ring
      // on the Connect screen).
      case 'symbol_viewed':
      case 'symbol_liked':
      case 'symbol_commented':
        _openMySymbolsFromNotification();
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
      case 'new_user':
        Get.toNamed(RouteHelper.getNotificationScreenRoute());
        break;

      // Profile-completion nudge → the user's own "Me" → Overview tab, which
      // hosts the completion card. Reuse the live bottom-nav shell when present
      // (pop any pushed screens, then switch tab); otherwise route to it fresh.
      case 'profile_completion_reminder':
        if (Get.isRegistered<BottomBarController>()) {
          Get.until((route) => route.isFirst);
          Get.find<BottomBarController>().openMeOverviewTab();
        } else {
          Get.offAllNamed(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
          );
        }
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

      // Security-deposit / subscription lifecycle → the contribution screen,
      // which shows the held deposit or the plan catalog. It is not registered
      // in RouteHelper, so it is pushed directly like its other call sites
      // (drawer, account settings, rider service).
      case 'security_deposit_held':
      case 'security_deposit_reminder':
      case 'trial_started':
      case 'subscription_activated':
      case 'subscription_charged':
      case 'subscription_payment_failed':
      case 'subscription_cancelled':
      case 'subscription_expired':
      case 'recharge_activated':
        Get.to(() => const ContributionScreenV2());
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

  /// Open the current user's own symbols viewer. Symbol engagement pushes
  /// (viewed / liked / commented) are about the logged-in user's symbols, so
  /// we load them and open `SymbolViewImages` in "my symbols" mode — the same
  /// screen the profile ring on the Connect page opens.
  static Future<void> _openMySymbolsFromNotification() async {
    try {
      final ctrl = getOrPut(() => AddChatSymbolController());
      if (userId.isNotEmpty) {
        await ctrl.getSymbolsForPartUser(userId);
      }
      Get.to(() => SymbolViewImages(mySymbols: ctrl.mySymbols));
    } catch (e) {
      logs('Failed to open my symbols from notification: $e');
      // Never dead-end: fall back to the notification hub.
      Get.toNamed(RouteHelper.getNotificationScreenRoute());
    }
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
          "operation": operation
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
  /// Reject a ringing ride from the notification's Decline button.
  ///
  /// Goes through [CallController] so the ring teardown, the open incoming
  /// screen and the reject POST all stay in one place. Falls back to cancelling
  /// the ring alone when the push carried no order id — better a silent banner
  /// than a reject aimed at the wrong order.
  Future<void> _declineRideFromNotification(String? orderId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(
        ringNotificationIdFor(orderId),
      );
    } catch (_) {}

    if (orderId == null || orderId.isEmpty) {
      rideNotifLog('action: DECLINE without orderId — ring cancelled only');
      return;
    }
    try {
      if (!Get.isRegistered<CallController>()) {
        rideNotifLog('action: DECLINE — no CallController; ring cancelled only');
        return;
      }
      final controller = Get.find<CallController>();
      // The button can fire for a ride other than the one the controller is
      // holding (a second request rang while the first banner sat in the
      // shade), so point it at the order the button names.
      controller.fareCallOrderId.value = orderId;
      await controller.rejectFareCallRide();
      rideNotifLog('action: DECLINE rejected $orderId');
    } catch (e) {
      rideNotifLog('action: DECLINE failed for $orderId: $e');
    }
  }

  /// The `metadata` block inside a ride push's `payload`, which is where the
  /// order id usually lives. `payload` arrives as either a JSON string or an
  /// already-decoded map depending on the producer.
  static Map? _rideMetadataOf(Map<String, dynamic> data) {
    final raw = data['payload'];
    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return decoded['metadata'] as Map?;
      } else if (raw is Map) {
        return raw['metadata'] as Map?;
      }
    } catch (_) {
      // Malformed payload — the caller still tries the top-level keys.
    }
    return null;
  }

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

  /// Open the in-app "BlueEra" chat exactly like tapping its row in
  /// ConnectMainPage — the Admin [PersonalChatScreen], not the read-only
  /// [BlueEraNotificationScreen]. Resolution order:
  ///   1. The BlueEra conversation already present in the loaded personal chat
  ///      list (identical to a row tap → `openChatFromChatList`).
  ///   2. The BlueEra account id carried on the push (`senderId`), via the same
  ///      `checkChatConnectionAndOpenChat` the list-row tap ultimately runs.
  ///   3. Fallback to the read-only notifications screen when neither exists.
  /// Public entry point so other surfaces (e.g. the notification hub list) can
  /// open the in-app "BlueEra" broadcast thread through the same tested path a
  /// push tap uses. [data] may carry `senderId`/`conversationId` for the
  /// cold-start fallback; a warm app resolves the row from the loaded chat list.
  static Future<void> openBlueEraChat(Map<String, dynamic> data) =>
      _openBlueEraChat(data);

  static Future<void> _openBlueEraChat(Map<String, dynamic> data) async {
    // Fast path: the BlueEra row is already in the loaded chat list (app was
    // warm / list cached). Open it straight away.
    if (_openBlueEraChatFromList()) return;

    // Cold start (killed-state tap): the personal chat list is fetched over the
    // socket only after the handshake completes, so the BlueEra row is not yet
    // present — this is why the broadcast chat previously failed to open and
    // the tap fell through to a plain personal chat / the read-only screen.
    // Make sure the socket is connecting (which requests the list) and poll for
    // the row to appear before giving up. Opening it via the chat-list row is
    // the only path that carries the conversationId + the literal "Admin" type
    // that makes PersonalChatScreen render the broadcast thread with history.
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.connectSocket();

    const maxAttempts = 24; // ~6s total (24 × 250ms) to cover a slow handshake.
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (_openBlueEraChatFromList()) return;
    }

    // The row still hasn't loaded after waiting. Fall back to the BlueEra
    // account id carried on the push, opening it explicitly as an Admin
    // (broadcast) thread so it still renders with BroadcastMessageCard rather
    // than as a plain personal chat.
    final senderId = (data['senderId'] ?? data['sender_id'] ?? '').toString();
    if (senderId.isNotEmpty) {
      final conversationId =
          (data['conversationId'] ?? data['conversation_id'] ?? '').toString();
      chatViewController.openChatFromChatList(
        userId: senderId,
        conversationId: conversationId,
        type: AppStrings.Admin,
      );
      return;
    }

    // Neither the chat-list row nor an id is available — show the notifications
    // list so the tap still lands somewhere meaningful.
    Get.to(() => const BlueEraNotificationScreen());
  }

  /// Find the BlueEra system conversation in the loaded personal chat list and
  /// open it via [ChatViewController.openChatFromChatList] — the exact path a
  /// row tap in ConnectMainPage takes. Returns false when the row isn't present
  /// yet (e.g. the list hasn't finished loading on a cold start).
  static bool _openBlueEraChatFromList() {
    try {
      final chatViewController = getOrPut(() => ChatViewController());
      final list =
          chatViewController.getPersonalChatListModel?.value.chatList ??
              <ChatList?>[];
      for (final chat in list) {
        if (chat == null) continue;
        final name = (chat.sender?.name ?? '').trim().toLowerCase();
        final type = (chat.sender?.accountType ?? '');
        final isBlueEra = name == 'blueera' || type == AppStrings.Admin;
        if (!isBlueEra) continue;
        chatViewController.openChatFromChatList(
          userId: chat.sender?.id ?? '',
          conversationId: chat.conversationId ?? '',
          type: type.isNotEmpty ? type : AppStrings.Admin,
          contactName: chat.sender?.name,
          contactNo: chat.sender?.contactNo,
          profileImage: chat.sender?.profileImage,
        );
        return true;
      }
    } catch (_) {}
    return false;
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

    // Order alerts play their chime via the dedicated `order_alerts_v3`
    // channel, which works in foreground AND background/terminated. Skip the
    // audioplayers path (foreground-only) so the foreground doesn't chime
    // twice — once from the channel, once from here.
    if (_orderNotificationOperations.contains(operation)) return;

    try {
      if (operation == 'sent_message' ||
          operation == 'message_reminder' ||
          operation == 'tagged_in_message' ||
          operation == 'commented_on_message' ||
          operation == 'liked_message') {
        playNotificationSound = chatNotificationSound;
      } else if (operation == 'ride_order_received' ||
          operation == 'ride_order_accepted' ||
          operation == 'ride_order_created') {
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
