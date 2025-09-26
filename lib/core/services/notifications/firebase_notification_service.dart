import 'dart:convert';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../features/chat/auth/controller/chat_view_controller.dart';
import 'model/OneSignalNotificationDetailsModel.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('💤 Background message: ${message.messageId}');
  await _showBackgroundNotification(message);
}


Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin localNotifications =
  FlutterLocalNotificationsPlugin();

  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const iosDetails = DarwinNotificationDetails();
  const notificationDetails =
  NotificationDetails(android: androidDetails, iOS: iosDetails);

  await localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final notification = message.notification;
  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    notification?.title ?? 'New Message',
    notification?.body ?? '',
    notificationDetails,
    payload: json.encode(message.data),
  );
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
  FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await Firebase.initializeApp();
    print("🔧 Initializing Firebase Notification Service");


    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


    await _requestPermission();


    await _initLocalNotifications();

    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received: ${message.data}');
      _showLocalNotification(message);
    });

    // When user taps on notification (while in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification opened (background)');
      _handleNavigation(message);
    });

    // When app opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched from notification (terminated)');

      // Normalize sender_user
      Map<String, dynamic> dataa = Map<String, dynamic>.from(initialMessage.data);
      if (dataa['sender_user'] is String) {
        dataa['sender_user'] = jsonDecode(dataa['sender_user']);
      }

      _handleNavigation(RemoteMessage(data: dataa));
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔐 Permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          Map<String, dynamic> data = json.decode(response.payload!);
          _handleNavigation(RemoteMessage(data: data));
        }
      },
    );
  }

  Map<String, List<String>> _messagesMap = {}; // keep this globally or in your service

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final senderId = message.data['senderId'] ?? 'unknown';
    final senderName = message.data['senderName'] ?? 'Someone';
    final text = notification?.body ?? '';
log("lkdmlsdkmlsdvmlsdkm,vv ${notification}");
log("lkdmlsdkmlsdvmlsdkm,vv ${message.data}");
log("lkdmlsdkmlsdvmlsdkm,vv ${notification?.body}");
log("lkdmlsdkmlsdvmlsdkm,vv ${notification?.title}");
    // store messages per sender
    if (!_messagesMap.containsKey(senderId)) {
      _messagesMap[senderId] = [];
    }
    _messagesMap[senderId]!.add(text);

    // build inbox style with all messages from this sender
    final inboxStyle = InboxStyleInformation(
      _messagesMap[senderId]!
          .map((msg) => '$senderName: $msg')
          .toList(),
      contentTitle: "$senderName (${_messagesMap[senderId]!.length} messages)",
      summaryText: "New messages",
    );

    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      styleInformation: inboxStyle,
    );

    await _localNotifications.show(
      senderId.hashCode, // 🔑 same sender = same notification, groups together
        notification?.title ?? 'New Message',
        notification?.body ?? '',
      NotificationDetails(android: androidDetails),
      payload: json.encode(message.data),
    );
  }



// When receiving notification
  void _handleNavigation(RemoteMessage message) {
    log('🧭 Navigate to chatId: ${message.data}');

    // Convert everything into a Map
    Map<String, dynamic> dataa = Map<String, dynamic>.from(message.data);

    // If sender_user is a string, decode it into a Map
    if (dataa['sender_user'] is String) {
      dataa['sender_user'] = jsonDecode(dataa['sender_user']);
    }

    print("skdjnckjs One ");
    OneSignalNotificationDetailsModel data =
    OneSignalNotificationDetailsModel.fromJson(dataa);
    print("skdjnckjs One ");

    final chatViewController = Get.put(ChatViewController());
    print("skdjnckjs One Twoq ");
    chatViewController.connectSocket();
    print("skdjnckjs One KK");

    chatViewController.openAnyOneChatFunction(
      type: data.conversationType ?? '',
      conversationId: data.conversationId ?? '',
      userId: data.senderUser?.id,
      contactName: data.senderUser?.name,
      contactNo: data.senderUser?.contact,
      isInitialMessage: false,
    );
    print("ksjdckjsdncksjcns ");
  }

}

