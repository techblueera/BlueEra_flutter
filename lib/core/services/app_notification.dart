// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_new, unrelated_type_equality_checks, unused_local_variable
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/notifications/model/OneSignalNotificationDetailsModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as httpPkg;
import 'package:permission_handler/permission_handler.dart';

import '../routes/route_helper.dart';

String notificationSound = 'sound/iphone_tone.mp3';
String hello_delivery = 'sound/hello_delivery.mp3';
String chatNotificationSound = 'sound/messenger.mp3';

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
    log("sldclskdmclksdmclskdcmsldckmsdc ${message.toMap()}");

    ///FOR GROUND....

    showNotification(message);
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await httpPkg.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> showNotification(
    RemoteMessage notification,
  ) async {
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
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      ///FOR APP IS IN FOR GROUND....
      logs("message===== ${(message.data)}");

      ///IOS LOCAL NOTIFICATION IS TRIGGER BY SELF & ANDROID NOT HANDLE
      if (notification != null && Platform.isAndroid) {
        playCustomSound(message);
        showMsg(message);
      } else if (Platform.isIOS) {
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
      dataNotificationResponse['sender_user'] =
          jsonDecode(dataNotificationResponse['sender_user']);
    }
    OneSignalNotificationDetailsModel data =
        OneSignalNotificationDetailsModel.fromJson(dataNotificationResponse);
    log('sldjncksjncksdjcnskjc ${dataNotificationResponse} ___ ${data.operation}');

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
    }else if(data.operation=="RIDE_ORDER_CREATED"){
      Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
    }

    ///CLEAR ALL NOTIFICATION...
    flutterLocalNotificationsPlugin.cancelAll();
  }

  ///SET AUDIO SOUND....
  Future<void> playCustomSound(RemoteMessage dataNotificationResponse) async {
    Map<String, dynamic> dataMap = dataNotificationResponse.data;
    String playNotificationSound;
    if (dataMap['sender_user'] is String) {
      dataMap['sender_user'] = jsonDecode(dataMap['sender_user']);
    }
    try {
      OneSignalNotificationDetailsModel data =
          OneSignalNotificationDetailsModel.fromJson(dataMap);
      if (data.operation == "sent_message") {
        playNotificationSound = chatNotificationSound;
      } else if (data.operation == "order_placed") {
        playNotificationSound = hello_delivery;
      } else if (data.operation == "reposted_post" ||
          data.operation == "commented_on_post") {
        playNotificationSound = notificationSound;
      } else {
        ///DEFAULT...
        playNotificationSound = notificationSound;
      }
    } on Exception catch (e) {
      playNotificationSound = notificationSound;

      // TODO
    }

    // Permission.
    try {
      await audioPlayer.play(AssetSource(playNotificationSound));
    } on Exception catch (e) {
      logs("SOUND ERROR====${e.toString()}");
      // TODO
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
                    Get.back(); // Close dialog if granted

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
