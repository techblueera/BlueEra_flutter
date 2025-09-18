import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';


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
      _handleNavigation(initialMessage);
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

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification?.title ?? 'New Message',
      notification?.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: json.encode(message.data),
    );
  }

  void _handleNavigation(RemoteMessage message) {
    String? screen = message.data['screen'];
    String? chatId = message.data['chatId'];
    // TODO: Use Navigator or GetX to navigate to the correct screen
    print('🧭 Navigate to $screen with chatId: $chatId');
  }
}
