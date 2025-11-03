// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_new, unrelated_type_equality_checks, unused_local_variable
import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/notifications/model/OneSignalNotificationDetailsModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

String notificationSound = 'sound/iphone_tone.mp3';
// String notificationSound = 'sound/notification_sound.wav';

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

    ///firebase initiallize
    // await Firebase.initializeApp();
    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      AppStrings.appName, // id
      'Notifications', // title
      importance: Importance.high,
    );

    ///local notification...
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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
          AppStrings.appName, // id
          'High Importance Notifications', // title
          importance: Importance.high,
          playSound: true,
          enableVibration: true);

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
        ), onDidReceiveNotificationResponse: (payLoad) {
      if (payLoad != null && payLoad.payload != null) {
        _onTapNotificationFromStatusBar(
          json.decode(payLoad.payload!),
        );
      }
    });
  }

  ///show notification msg
  void showMsg(RemoteMessage message) {
    // callUnreadCount();

    ///FOR GROUND....

    showNotification(message);
  }

  void showNotification(
    RemoteMessage notification,
  ) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.notification?.title ?? "",
      notification.notification?.body ?? "",
      const NotificationDetails(
          android: AndroidNotificationDetails(
            AppStrings.appName, // id
            'High Importance Notifications', // title
            channelDescription: '',
            enableVibration: true,
            // description
            importance: Importance.high,
            icon: '@drawable/ic_stat',
            playSound: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentSound: true,
          )),
      payload: jsonEncode(notification.data),
    );
  }

  ///call when click on notification
  void onMsgOpen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      ///FOR APP IS IN FOR GROUND....

      ///IOS LOCAL NOTIFICATION IS TRIGGER BY SELF & ANDROID NOT HANDLE
      if (notification != null && Platform.isAndroid) {
        playCustomSound();
        showMsg(message);
      } else if (Platform.isIOS) {
        Vibration.vibrate(duration: 1000);
        print("IOS CALL");

        ///FOR IOS....
        // callUnreadCount();
      }
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
    Map<String, dynamic> dataNotificationResponse,
  ) async {
    if (dataNotificationResponse['sender_user'] is String) {
      dataNotificationResponse['sender_user'] = jsonDecode(dataNotificationResponse['sender_user']);
    }
    OneSignalNotificationDetailsModel data =
        OneSignalNotificationDetailsModel.fromJson(dataNotificationResponse);
    if (data.operation == "sent_message") {
      final chatViewController = Get.put(ChatViewController());
      chatViewController.connectSocket();

      chatViewController.openAnyOneChatFunction(
        type: data.conversationType ?? '',
        conversationId: data.conversationId ?? '',
        userId: data.senderUser?.id,
        contactName: data.senderUser?.name,
        contactNo: "",
        // contactNo: data.senderUser?.contact,
        isInitialMessage: false,
      );
    }

    ///CLEAR ALL NOTIFICATION...
    flutterLocalNotificationsPlugin.cancelAll();
  }

  ///SET AUDIO SOUND....
  Future<void> playCustomSound() async {
    print("play sound call");
    Vibration.vibrate(duration: 1000);
    // Permission.
    try {
      await audioPlayer.play(AssetSource(notificationSound));
    } on Exception catch (e) {
      logs("SOUND ERROR====${e.toString()}");
      // TODO
    }
  }
}
