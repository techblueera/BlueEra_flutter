// import 'dart:convert';
// import 'dart:developer';
// import 'package:BlueEra/main.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
//
// import '../../../features/chat/auth/controller/chat_view_controller.dart';
// import 'model/OneSignalNotificationDetailsModel.dart';
//
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // await Firebase.initializeApp();
//   await firebaseInitializeApp();
//   log('📩 Background message received: ${message.data}');
//
//   if (message.data['call_type'] == 'audio_call') {
//     print("FirebaseMessaging.onMessage audio call screen");
//     if (message.data['missed_call'] == "true") {
//       Get.back();
//     } else {
//       // Get.to(IncomingCallScrenn(
//       //   roomID: message.data['room_id'],
//       //   callerImage: message.data['sender_profile_image'],
//       //   senderName: message.data['senderName'],
//       //   conversation_id: message.data['conversation_id'],
//       //   message_id: message.data['message_id'],
//       //   caller_id: message.data['senderId'],
//       //   forVideoCall: false,
//       //   receiverImage: message.data['receiver_profile_image'],
//       //   isGroupCall: message.data['is_group'],
//       // ));
//     }
//   }else {
//     await _showBackgroundNotification(message);
//   }
// }
//
//
// Future<void> _showBackgroundNotification(RemoteMessage message) async {
//   final FlutterLocalNotificationsPlugin localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   const androidDetails = AndroidNotificationDetails(
//     'default_channel',
//     'Default',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//   );
//
//   const iosDetails = DarwinNotificationDetails();
//   const notificationDetails =
//   NotificationDetails(android: androidDetails, iOS: iosDetails);
//
//   await localNotifications.initialize(
//     const InitializationSettings(
//       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       iOS: DarwinInitializationSettings(),
//     ),
//   );
//
//   final notification = message.notification;
//   await localNotifications.show(
//     DateTime.now().millisecondsSinceEpoch ~/ 1000,
//     notification?.title ?? 'New Message',
//     notification?.body ?? '',
//     notificationDetails,
//     payload: json.encode(message.data),
//   );
// }
//
// class FirebaseNotificationService {
//   static final FirebaseNotificationService _instance =
//   FirebaseNotificationService._internal();
//   factory FirebaseNotificationService() => _instance;
//   FirebaseNotificationService._internal();
//
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   Future<void> init() async {
//     // await Firebase.initializeApp();
//     print("🔧 Initializing Firebase Notification Service");
//
//
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//
//     // await _requestPermission();
//
//
//     await _initLocalNotifications();
//
//     // Foreground message
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       log('📩 Foreground message received: ${message.data}');
//       if (message.data['call_type'] == 'audio_call') {
//         print("FirebaseMessaging.onMessage audio call screen");
//         if (message.data['missed_call'] == "true") {
//           Get.back();
//         } else {

//           // Get.to(IncomingCallScrenn(
//           //   roomID: message.data['room_id'],
//           //   callerImage: message.data['profile_image'],
//           //   senderName: message.data['name'],
//           //   conversation_id: message.data['conversation_id'],
//           //   message_id: message.data['message_id'],
//           //   caller_id: message.data['id'],
//           //   forVideoCall: false,
//           //   receiverImage: message.data['profile_image'],
//           //   isGroupCall: message.data['is_group'],
//           // ));
//         }
//       }else{
//         _showLocalNotification(message);
//       }
//
//     });
//
//     // When user taps on notification (while in background)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('📲 Notification opened (background)');
//       _handleNavigation(message);
//     });
//
//     // When app opened from terminated state
//     RemoteMessage? initialMessage = await _messaging.getInitialMessage();
//     if (initialMessage != null) {
//       print('🚀 App launched from notification (terminated)');
//
//       // Normalize sender_user
//       Map<String, dynamic> dataa = Map<String, dynamic>.from(initialMessage.data);
//       if (dataa['sender_user'] is String) {
//         dataa['sender_user'] = jsonDecode(dataa['sender_user']);
//       }
//
//       _handleNavigation(RemoteMessage(data: dataa));
//     }
//   }
//
//   Future<void> _requestPermission() async {
//     NotificationSettings settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     print('🔐 Permission: ${settings.authorizationStatus}');
//   }
//
//   Future<void> _initLocalNotifications() async {
//     _localNotifications
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();
//     const initSettings =
//     InitializationSettings(android: androidInit, iOS: iosInit);
//
//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         if (response.payload != null) {
//           Map<String, dynamic> data = json.decode(response.payload!);
//           _handleNavigation(RemoteMessage(data: data));
//         }
//       },
//     );
//   }
//
//   Map<String, List<String>> _messagesMap = {}; // keep this globally or in your service
//
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     final senderId = message.data['senderId'] ?? 'unknown';
//     final senderName = message.data['senderName'] ?? 'Someone';
//     final text = notification?.body ?? '';
//
//     // store messages per sender
//     if (!_messagesMap.containsKey(senderId)) {
//       _messagesMap[senderId] = [];
//     }
//     _messagesMap[senderId]!.add(text);
//
//     // build inbox style with all messages from this sender
//     final inboxStyle = InboxStyleInformation(
//       _messagesMap[senderId]!
//           .map((msg) => '$senderName: $msg')
//           .toList(),
//       contentTitle: "$senderName (${_messagesMap[senderId]!.length} messages)",
//       summaryText: "New messages",
//     );
//
//     final androidDetails = AndroidNotificationDetails(
//       'default_channel',
//       'Default',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       styleInformation: inboxStyle,
//     );
//
//     await _localNotifications.show(
//       senderId.hashCode, // 🔑 same sender = same notification, groups together
//         notification?.title ?? 'New Message',
//         notification?.body ?? '',
//       NotificationDetails(android: androidDetails),
//       payload: json.encode(message.data),
//     );
//   }
//
//
//
// // When receiving notification
//   void _handleNavigation(RemoteMessage message) {
//     log('🧭 Navigate to chatId: ${message.data}');
//
//     // Convert everything into a Map
//     Map<String, dynamic> dataa = Map<String, dynamic>.from(message.data);
//
//     // If sender_user is a string, decode it into a Map
//     if (dataa['sender_user'] is String) {
//       dataa['sender_user'] = jsonDecode(dataa['sender_user']);
//     }
//
//
//     OneSignalNotificationDetailsModel data =
//     OneSignalNotificationDetailsModel.fromJson(dataa);
//
//
//     final chatViewController = Get.put(ChatViewController());
//
//     chatViewController.connectSocket();
//
//
//     chatViewController.openAnyOneChatFunction(
//       type: data.conversationType ?? '',
//       conversationId: data.conversationId ?? '',
//       userId: data.senderUser?.id,
//       contactName: data.senderUser?.name,
//       contactNo: data.senderUser?.contact,
//       isInitialMessage: false,
//     );
//
//   }
//
// }
//
