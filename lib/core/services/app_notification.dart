// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_new, unrelated_type_equality_checks, unused_local_variable
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart' as dio;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:permission_handler/permission_handler.dart';

import '../../features/chat/auth/controller/call_controller.dart';
import '../../features/chat/view/ai_chat/view/ai_chat_screen.dart';
import '../../features/chat/view/orders_chat/widget/order_call_alert_page.dart';
import '../routes/route_helper.dart';
import 'notifications/ride_notification_data_model.dart';

String notificationSound = 'sound/iphone_tone.mp3';
String hello_delivery = 'sound/hello_delivery.mp3';
String chatNotificationSound = 'sound/messenger.mp3';

/// Top-level handler for background notification actions (inline reply, mark as read, etc.)
/// Must be a top-level or static function for flutter_local_notifications
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // Delegate to async handler — use .then() to keep isolate alive until complete
  _handleBackgroundNotificationResponse(response).then((_) {}).catchError((_) {});
}

Future<void> _handleBackgroundNotificationResponse(NotificationResponse response) async {
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

  // --- Inline reply (WhatsApp-style, no app open) ---
  if (actionId.startsWith('reply_message_') && response.input != null && response.input!.isNotEmpty) {
    final conversationId = data['conversationId'] ?? '';
    // Send reply via REST API (works in background isolate without GetX context)
    await _sendReplyViaApi(conversationId: conversationId, message: response.input!);
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
  if (actionId.startsWith('view_chat_') || actionId.startsWith('view_conversation_')) {
    final senderId = data['senderId'] ?? '';
    if (senderId.isNotEmpty) {
      final chatViewController = getOrPut(() => ChatViewController());
      chatViewController.connectSocket();
      Future.delayed(const Duration(milliseconds: 500), () {
        chatViewController.checkChatConnectionAndOpenChat(userId: senderId);
      });
    }
    return;
  }

  // --- Connection actions ---
  if (actionId.startsWith('accept_connection_') || actionId.startsWith('decline_connection_') ||
      actionId.startsWith('view_profile_') || actionId.startsWith('message_')) {
    Get.toNamed(RouteHelper.getNotificationScreenRoute());
    return;
  }

  // --- Ride actions ---
  if (actionId.startsWith('track_ride_') || actionId.startsWith('view_order_') ||
      actionId.startsWith('accept_order_') || actionId.startsWith('contact_rider_')) {
    Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
    return;
  }

  // --- Post / Reel actions ---
  if (actionId.startsWith('view_post_') || actionId.startsWith('view_comment_') ||
      actionId.startsWith('view_reel_') || actionId.startsWith('view_response_')) {
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

/// Send reply message via direct REST API call.
/// Works in both foreground and background isolate contexts.
Future<void> _sendReplyViaApi({
  required String conversationId,
  required String message,
}) async {
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: SharedPreferenceUtils.authToken);
    final storedBaseUrl = await storage.read(key: SharedPreferenceUtils.baseURL);
    final apiUrl = (storedBaseUrl ?? baseUrl ?? '') + 'chat-service/chat/send-message';

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
      new FlutterLocalNotificationsPlugin();

  /// FIREBASE NOTIFICATION SETUP
  Future<void> firebaseNotificationSetup() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payLoad =
          notificationAppLaunchDetails!.notificationResponse?.payload;
    }

    /// Android Notification Channels per backend documentation
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default',
      'General Notifications',
      description: 'All standard push notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel incomingCallChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Incoming voice and video call alerts',
      importance: Importance.max,
    );

    const AndroidNotificationChannel missedCallChannel = AndroidNotificationChannel(
      'missed_calls',
      'Missed Calls',
      description: 'Missed call notifications',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel messagesChannel = AndroidNotificationChannel(
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

    const AndroidNotificationChannel announcementsChannel = AndroidNotificationChannel(
      'announcements',
      'Announcements',
      description: 'Admin and system announcements',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel channelsChannel = AndroidNotificationChannel(
      'channels',
      'Channels',
      description: 'Channel and follower updates',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel ongoingCallChannel = AndroidNotificationChannel(
      'ongoing_call',
      'Ongoing Calls',
      description: 'Shows when a call is in progress',
      importance: Importance.low,
    );

    ///local notification...
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
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
  }

  ///background notification handler..
  //  @pragma('vm:entry-point')
  //  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // // playCustomSound();
  //    // callUnreadCount();
  //  }

  static AndroidNotificationDetails androidPlatformChannelSpecifics =
      const AndroidNotificationDetails(
          'default', // channel id — must match registered channel
          'General Notifications', // title
          importance: Importance.high,
          playSound: true,
          enableVibration: false);

  static DarwinNotificationDetails iOSPlatformChannelSpecificsForNewOrder(
          {String? sound}) =>
      DarwinNotificationDetails(
        sound: sound,
      );

  static NotificationDetails platformChannelSpecificsForNewOrder(
          String sound) =>
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecificsForNewOrder(sound: sound),
      );

  ///get fcm token
  static Future<void> getFcmToken() async {
    final fcmToken = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.notificationDeviceToken);
    logs("fcmToken==== $fcmToken");
    if (fcmToken == null || fcmToken.toString().isEmpty || fcmToken == 0) {
      FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      try {
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
  void getInitialMsg() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat'),
        iOS: DarwinInitializationSettings(),
      ),
      // Foreground: when app is open and user taps notification or action
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!) as Map<String, dynamic>;
          // Handle ongoing call notification tap → return to active call screen
          if (data['action'] == 'open_active_call') {
            if (response.actionId == 'hangup_call') {
              if (Get.isRegistered<CallController>()) {
                Get.find<CallController>().endCall();
              }
            } else {
              Get.toNamed('/CallRoomScreen');
            }
            return;
          }
          if (response.actionId != null && response.actionId!.isNotEmpty) {
            String? replyText;
            if (response.input != null && response.input!.isNotEmpty) {
              replyText = response.input;
            }
            _handleActionButtonTap(response.actionId!, data, replyText: replyText);
          } else {
            _onTapNotificationFromStatusBar(data);
          }
        }
      },
      // Background: handles Reply & Mark as Read WITHOUT opening the app
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
  }

  /// Handle action button taps from notification
  static void _handleActionButtonTap(String actionId, Map<String, dynamic> data, {String? replyText}) {
    // Inline reply from notification (WhatsApp-style)
    if (actionId.startsWith('reply_message_') && replyText != null && replyText.isNotEmpty) {
      final conversationId = data['conversationId'] ?? '';
      final senderId = data['senderId'] ?? '';
      _sendQuickReply(conversationId: conversationId, senderId: senderId, message: replyText);
      return;
    }

    // Chat actions - open chat screen
    if (actionId.startsWith('reply_message_') || actionId.startsWith('view_chat_') || actionId.startsWith('view_conversation_')) {
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
    if (actionId.startsWith('accept_connection_') || actionId.startsWith('decline_connection_') ||
        actionId.startsWith('view_profile_') || actionId.startsWith('message_')) {
      Get.toNamed(RouteHelper.getNotificationScreenRoute());
      return;
    }

    // Ride actions
    if (actionId.startsWith('track_ride_') || actionId.startsWith('view_order_') ||
        actionId.startsWith('accept_order_') || actionId.startsWith('contact_rider_')) {
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
      return;
    }

    // Post/Reel actions
    if (actionId.startsWith('view_post_') || actionId.startsWith('view_comment_') ||
        actionId.startsWith('view_reel_') || actionId.startsWith('view_response_')) {
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
      final response = await ChatViewRepo().sendMessageToUser({
        'conversation_id': conversationId,
        'message': message,
        'message_type': 'text',
      });
      // Dismiss the notification
      flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      // Fallback: try direct API call
      try {
        await _sendReplyViaApi(conversationId: conversationId, message: message);
        flutterLocalNotificationsPlugin.cancelAll();
      } catch (_) {
        // Last resort: open chat screen
        _openChatWithUser(senderId);
      }
    }
  }

  ///show notification msg
  Future<void> showMsg(RemoteMessage message) async {
    final operation = (message.data['operation'] ?? '').toString().toLowerCase();

    // Handle ride order received
    if (operation == 'ride_order_received') {
      NotificationData rideNotification = NotificationData.fromJson(message.data);
      showFullCallScreen(rideNotification);
      return;
    }

    // Handle incoming call - show native call UI via CallKit
    // if (operation == 'incoming_call') {
    //   _handleIncomingCallPush(message);
    //   return;
    // }

    // Use the generic data-only renderer for all other notifications.
    // This reads channelId, channelName, channelImportance, style, imageUrl,
    // groupKey, actions, etc. directly from the data payload.
    await showFromData(message.data);
  }

  /// Handle incoming call when app is in foreground — open in-app call screen directly
  // void _handleIncomingCallForeground(RemoteMessage message) {
  //   final data = message.data;
  //   final senderId = data['senderId'] ?? '';
  //   final convId = data['conversationId'] ?? '';
  //   final callerNameStr = data['senderName'] ?? 'Unknown';
  //   final callerImageStr = data['senderProfileImage'] ?? '';
  //   final callTypeStr = (data['message'] ?? '').toString().contains('video')
  //       ? 'video_call'
  //       : 'voice_call';
  //
  //   // Ensure CallController exists
  //   if (!Get.isRegistered<CallController>()) {
  //     Get.put(CallController(), permanent: true);
  //   }
  //   final callController = Get.find<CallController>();
  //
  //   // If already ringing/active (socket event may have arrived first), skip
  //   if (callController.callStatus.value != CallStatus.idle) return;
  //
  //   // Use initStateFromCallKitExtra which sets all state including _remoteUserId & socket
  //   callController.initStateFromCallKitExtra({
  //     'senderId': senderId,
  //     'conversationId': convId,
  //     'callType': callTypeStr,
  //     'callerName': callerNameStr,
  //     'callerImage': callerImageStr,
  //     'callId': data['callId'] ?? data['notificationId'] ?? '',
  //     'roomId': data['roomId'] ?? data['room_id'] ?? '',
  //     'operation': 'incoming_call',
  //   });
  //
  //   // Navigate to the in-app incoming call screen (avoid duplicate)
  //   if (Get.currentRoute != '/IncomingCallScreen') {
  //     Get.toNamed('/IncomingCallScreen');
  //   }
  // }

  /// Handle incoming call push notification — works in foreground, background, and killed state.
  void _handleIncomingCallPush(RemoteMessage message) {
    try {
      final data = message.data;
      final callerName = data['senderName'] ?? 'Unknown';
      final callerImage = data['senderProfileImage'] ?? '';

      // Parse payload — may be a JSON string or already decoded
      Map<String, dynamic> payload = {};
      try {
        final rawPayload = data['payload'];
        if (rawPayload is String && rawPayload.isNotEmpty) {
          payload = jsonDecode(rawPayload);
        } else if (rawPayload is Map) {
          payload = Map<String, dynamic>.from(rawPayload);
        }
      } catch (e) {
        log('_handleIncomingCallPush: payload parse error: $e');
      }

      final callType = payload['call_type'] ?? data['callType'] ?? 'audio_call';
      final callId = payload['call_id'] ?? data['callId'] ?? data['notificationId'] ?? '';
      final roomId = payload['room_id'] ?? data['roomId'] ?? '';

      // Parse caller data for designation (if available)
      String designation = '';
      try {
        final rawCallerData = data['callerData'];
        if (rawCallerData != null) {
          Map<String, dynamic> callerData = rawCallerData is String
              ? jsonDecode(rawCallerData)
              : Map<String, dynamic>.from(rawCallerData);

          final accountType = callerData['account_type']?.toString() ?? '';
          if (accountType == 'BUSINESS') {
            var biz = callerData['businessData'];
            if (biz is String) biz = jsonDecode(biz);
            if (biz is Map) {
              designation = (biz['category_of_business'] ?? biz['sub_category_of_business'] ?? '').toString();
            }
          } else {
            designation = (callerData['designation'] ?? '').toString();
          }
        }
      } catch (_) {}

      log('_handleIncomingCallPush: callId=$callId, roomId=$roomId, type=$callType, caller=$callerName');

      showFlutterCallNotification(
        desiginations: designation.isNotEmpty ? designation : 'Incoming Call',
        callSessionId: callId,
        callerName: callerName,
        callerImage: callerImage.isNotEmpty ? callerImage : null,
        callType: callType,
        extra: {
          'senderId': data['senderId'] ?? '',
          'conversationId': data['conversationId'] ?? '',
          'callType': callType,
          'callerName': callerName,
          'callerImage': callerImage,
          'callId': callId,
          'roomId': roomId,
          'operation': 'incoming_call',
        },
      );
    } catch (e, stack) {
      log('_handleIncomingCallPush ERROR: $e');
      log('Stack: $stack');
    }
  }
  Future<void> showFullCallScreen(NotificationData rideNotification )async{
    String? pickupLocation=await getAddressFromLatLngAsString(lat:double.parse(rideNotification.deliveryLat.toString()),lng:double.parse(rideNotification.deliveryLong.toString()));
    String? dropLocation=await getAddressFromLatLngAsString(lat:double.parse(rideNotification.metadata?.dropAddress?.lat.toString()??''),lng:double.parse(rideNotification.metadata?.dropAddress?.long.toString()??''));
    Get.to(()=> NewDeliveryRequestScreen(
      notificationData: rideNotification,
      orderId: '${rideNotification.metadata?.orderId}',
      customerImage: ''
      , distance: '${rideNotification.deliveryLong}',
      pickupAddress: '$pickupLocation', amount: '${rideNotification.metadata?.ridefare}', dropAddress: '$dropLocation',));

  }

  Future<String?> getAddressFromLatLngAsString({required double lat ,required double lng}) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build clean string (area, city, pincode)

        String locationString =
        "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''} - ${place.postalCode ?? ''}".trim();

        return locationString;
      } else {

        return "View Order you get address";
      }
    } catch (e) {
      return "View Order you get address";
    }
  }
  Future<void>  callShow({required String orderId,required double lat,required double lng })async{
    CallKitParams callKitParams = CallKitParams(
      id: "_currentUuid",
      nameCaller: 'New Delivery Order',
      appName: 'Callkit',
      avatar: '',
      handle: "Drop Location : ${await getAddressFromLatLngAsString(lat:lat,lng:lng)}",
      type: 0,
      textAccept: 'View',
      textDecline: 'Reject',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'You Missed an Order ',
        callbackText: 'Chat Now',
      ),
      callingNotification:  NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'order waiting for your confirmation',
        callbackText: 'Chat',
      ),
      duration: 30000,
      extra: <String, dynamic>{'orderId': '$orderId'},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android:  AndroidParams(
          isImportant: true,
          isCustomNotification: true,
          isShowLogo: false,
          logoUrl: '',
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: '',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: "New Delivery Order",
          missedCallNotificationChannelName: "You Missed an Order",
          isShowCallID: true
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }

  Future<void> showNotification(
    RemoteMessage notification, {
    String channelId = 'default',
    String channelName = 'General Notifications',
    Importance importance = Importance.high,
  }) async {
    final data = notification.data;
    final operation = (data['operation'] ?? '').toString().toLowerCase();
    final title = notification.notification?.title ?? data['title'] ?? "";
    final body = notification.notification?.body ?? data['message'] ?? "";
    final isChatMessage = _isChatOperation(operation);

    // Build action buttons
    final List<AndroidNotificationAction> androidActions = isChatMessage
        ? _buildChatActions(data)
        : _parseNotificationActions(data);

    // Use BigTextStyle so notification expands on swipe down (like WhatsApp)
    final styleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: isChatMessage ? (data['senderContact'] ?? '') : null,
    );

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      title,
      body,
      NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: '',
            enableVibration: true,
            importance: importance,
            icon: '@drawable/ic_stat',
            playSound: true,
            styleInformation: styleInformation,
            category: isChatMessage ? AndroidNotificationCategory.message : null,
            actions: androidActions,
          ),
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentSound: true,
          )),
      payload: jsonEncode(data),
    );
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
    final channelImportance = (data['channelImportance'] ?? 'default').toString();
    final groupKey = (data['groupKey'] ?? '').toString();
    final notificationId = (data['notificationId'] ?? '${DateTime.now().millisecondsSinceEpoch}').toString();
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
    final styleInformation = _buildStyleInformation(style, body, bigPicture, title);

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
  List<AndroidNotificationAction> _parseNotificationActions(Map<String, dynamic> data) {
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

  ///WORKING CODE..
  /* Future<void> showNotification(
    RemoteMessage notification,
  ) async {
    final imageUrl =
        "https://img.freepik.com/free-vector/flat-design-minimal-technology-twitch-banner_23-2149089532.jpg?semt=ais_hybrid&w=740&q=80";
    // String imageUrl = notification.data['image'];
    //

    if (imageUrl.isNotEmpty) {
      final bigPicture = await _downloadAndSaveFile(imageUrl, 'bigPicture');

      final styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicture),
        largeIcon: null,
        contentTitle: notification.notification?.title ?? "",
        summaryText: notification.notification?.body ?? "",
      );
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        "",
        "",
        NotificationDetails(
            android: AndroidNotificationDetails(
              AppStrings.appName, // id
              // AppStrings.appName, // id
              'High Importance Notifications', // title
              channelDescription: '',
              enableVibration: false,
              // description
              importance: Importance.high,
              icon: '@drawable/ic_stat',
              playSound: true,
              styleInformation: styleInformation,
            ),
            iOS: DarwinNotificationDetails(
              presentBanner: true,
              presentSound: true,
            )),
        payload: jsonEncode(notification.data),
      );
    } else {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.notification?.title ?? "",
        notification.notification?.body ?? "",
        NotificationDetails(
            android: AndroidNotificationDetails(
              AppStrings.appName, // id
              // AppStrings.appName, // id
              'High Importance Notifications', // title
              channelDescription: '',
              enableVibration: false,
              // description
              importance: Importance.high,
              icon: '@drawable/ic_stat',
              playSound: true,
              // styleInformation: styleInformation,
            ),
            iOS: DarwinNotificationDetails(
              presentBanner: true,
              presentSound: true,
            )),
        payload: jsonEncode(notification.data),
      );
    }
  }*/

  ///call when click on notification
  void onMsgOpen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final operation = (message.data['operation'] ?? '').toString().toLowerCase();
      log("jhsjhsbajhbdasjdhb  For ${message.data}");

      // Incoming call in foreground: show native CallKit UI immediately
      // if (operation == 'incoming_call') {
      //   _handleIncomingCallPush(message);
      //   return;
      // }

      // Play custom sound for foreground notifications
      playCustomSound(message);

      // Use the generic data-only renderer for both platforms.
      // Data-only messages are NOT auto-displayed by Firebase,
      // so we must render them ourselves.
      showMsg(message);
    });

    /// when app is in background and user tap on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

      if (message != null && message.data != null) {
        _onTapNotificationFromStatusBar(message.data);
      }
    });

    /// when app is in terminated and user tap on it.
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (message != null && message.data != null) {
        _onTapNotificationFromStatusBar(message.data);
      }
    });
  }

  ///DELETE FCM AND REGENERATE...
  static deleteFCMToken() async {
    await FirebaseMessaging.instance.deleteToken();
  }

  static Future<void> _onTapNotificationFromStatusBar(
    Map<String, dynamic> data,
  ) async {
    // Parse sender_user if it's a JSON string
    log("sldclsdkmcskldcmsdc ${data}");
    if (data['sender_user'] is String) {
      data['sender_user'] = jsonDecode(data['sender_user']);
    }

    final operation = (data['operation'] ?? '').toString().toLowerCase();

    switch (operation) {
      // Call operations
      case 'incoming_call':
        // Already handled by CallKit; tapping missed notification opens chat
        if (data['senderId'] != null) {
          _openChatWithUser(data['senderId']!);
        }
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

      default:
        // Default: open notifications screen or home
        break;
    }

    /// Clear all local notifications
    flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Helper to open chat with a user by their ID
  static void _openChatWithUser(String userId) {
    if (userId.isEmpty) return;
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.connectSocket();
    Future.delayed(const Duration(milliseconds: 500), () {
      chatViewController.checkChatConnectionAndOpenChat(userId: userId);
    });
  }

  ///SET AUDIO SOUND....
  Future<void> playCustomSound(RemoteMessage dataNotificationResponse) async {
    final operation = (dataNotificationResponse.data['operation'] ?? '').toString().toLowerCase();
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
          operation == 'ride_order_created') {
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
                  onTap: (){
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


/*
  static Future<void> sendMessage(
      {required List<DeviceTokenListModel> deviceTokenList,
        required String msg,
        required String title,
        bool isChatting = false,
        Map<String, dynamic>? data}) async {
    /// PROD MODE SERVER KEY
    // var serverKey =
    //     'AAAAnb0-ipw:APA91bHfom7DxO6tHfaPnlprGIfMVTwdZyBCIiXMR5IIDkkcYw7WkLB9G56-TveFLit6I7bGL38SMc0R5nkmyB16Etdq4O9bnzXQNGYyN-QEgHiDkoMB-t_oNmVsg1HE1ZepgS04U0lN';

    /// DEV MODE SERVER KEY
    // var serverKey =
    //     'AAAAWSZoobU:APA91bHUGhYAylnYQFo2vYd2CDtrfCH6sqL7DmeJpQNKH204dkl9CmciNaZ_v_IcDdfRY5Y6942JCcyihgL4arlvQqkwUyMbPnBqkPOIHublu3KB8n4v_xSx7HY7ZHQ6puTVUXs1GlVJ';

    if (deviceTokenList.isEmpty) {
      return;
    }
    final serverKey = await getServerToken();

    for (int index = 0; index < deviceTokenList.length; index++) {
      String body = jsonEncode(
        <String, dynamic>{
          "message": {
            "notification": {
              "body": msg,
              "title": title,
              // "badge": "1",
              // "sound": "default",
            },
            // "priority": "high",
            "android": {
              "notification": {
                'body': msg,
                'title': title,
                "sound": deviceTokenList[index].defaultSound ?? "default"
              }
            },
            "apns": {
              "headers": {
                "apns-priority": "10",
              },
              "payload": {
                "aps": {
                  "sound": deviceTokenList[index].defaultSound ?? "default"
                }
              }
            },
            "data": data ??
                <String, dynamic>{
                  "click_action": "FLUTTER_NOTIFICATION_CLICK",
                  'id': DateTime.now().millisecond.toString(),
                  "status": "done",
                },
            // "to": tokenData.token,
            "token": deviceTokenList[index].token,
          }
        },
      );

      try {
        http.Response response = await http.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/clubgrub-e0/messages:send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $serverKey',
          },
          body: body,
        );
        print("RESPONSE CODE ${response.statusCode}");
        print("RESPONSE BODY ${response.body}");
      } catch (e) {
        print("error push notification");
      }
    }
  }*/

}
class OpenedMessageDataModel {
  final String? conversationId;
  final String? messageId;
  final String? senderProfileImage;
  final String? priority;
  final String? type;
  final String? title;
  final String? message;
  final String? userId;
  final String? conversationType;
  final String? senderName;
  final String? senderId;
  final String? messageType;
  final String? senderContact;
  final String? notificationId;
  final String? senderType;
  final String? operation;
  final DateTime? timestamp;

  OpenedMessageDataModel({
    this.conversationId,
    this.messageId,
    this.senderProfileImage,
    this.priority,
    this.type,
    this.title,
    this.message,
    this.userId,
    this.conversationType,
    this.senderName,
    this.senderId,
    this.messageType,
    this.senderContact,
    this.notificationId,
    this.senderType,
    this.operation,
    this.timestamp,
  });

  factory OpenedMessageDataModel.fromJson(Map<String, dynamic> json) {
    return OpenedMessageDataModel(
      conversationId: json['conversationId'],
      messageId: json['messageId'],
      senderProfileImage: json['senderProfileImage'],
      priority: json['priority'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      userId: json['userId'],
      conversationType: json['conversationType'],
      senderName: json['senderName'],
      senderId: json['senderId'],
      messageType: json['messageType'],
      senderContact: json['senderContact']?.toString(),
      notificationId: json['notificationId']?.toString(),
      senderType: json['senderType'],
      operation: json['operation'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'messageId': messageId,
      'senderProfileImage': senderProfileImage,
      'priority': priority,
      'type': type,
      'title': title,
      'message': message,
      'userId': userId,
      'conversationType': conversationType,
      'senderName': senderName,
      'senderId': senderId,
      'messageType': messageType,
      'senderContact': senderContact,
      'notificationId': notificationId,
      'senderType': senderType,
      'operation': operation,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

