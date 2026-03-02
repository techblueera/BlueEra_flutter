// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_new, unrelated_type_equality_checks, unused_local_variable
import 'dart:convert';
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
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:googleapis_auth/auth_io.dart' as auth;

import 'package:permission_handler/permission_handler.dart';

import '../../features/chat/view/ai_chat/view/ai_chat_screen.dart';
import '../../features/chat/view/orders_chat/widget/order_call_alert_page.dart';
import '../routes/route_helper.dart';
import 'notifications/ride_notification_data_model.dart';

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
  Future<void> showMsg(RemoteMessage message)async {
        if(message.data["operation"]=='RIDE_ORDER_RECEIVED'){
          NotificationData rideNotification=NotificationData.fromJson(message.data);
          showFullCallScreen(rideNotification);
          // callShow(orderId: '${rideNotification.metadata?.orderId}',lng: double.parse(rideNotification.deliveryLong.toString()),lat: double.parse(rideNotification.deliveryLat.toString()) );
        }
    showNotification(message);
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
    RemoteMessage notification,
  ) async {
    print("SHOW MSG 3");

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
    print("SHOW MSG 4");

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
    if(data.operation =='SEND_NIGHTLY_GREETING'){
      final chat = ChatViewController.personalAiChatModule;

      Get.to(()=> AiChatScreen(
        profileImage: chat?.sender?.profileImage,
        name: chat?.sender?.name,
        type: chat?.sender?.accountType,
     ));
    }else
    if (data.operation == "sent_message") {
      OpenedMessageDataModel resModel=OpenedMessageDataModel.fromJson(dataNotificationResponse);
      // if(resModel.conversationType==AppConstants.group_Chat_Type){
      //   Get.to(()=>GroupChatScreen(
      //     type: AppConstants.group_Chat_Type,
      //     conversationId: resModel.conversationId,
      //     profileImage: '',
      //     name: resModel.senderName,
      //   ));
      // }else{
        final chatViewController = Get.put(ChatViewController());
        chatViewController.connectSocket();
       Future.delayed(Duration(milliseconds: 500),(){
         chatViewController.openAnyOneChatFunction(
           type: resModel.conversationType ?? '',
           conversationId: resModel.conversationId ?? '',
           userId: resModel.senderId,
           contactName: resModel.senderName,
           contactNo: resModel.senderContact,
           profileImage: resModel.senderProfileImage,

           isInitialMessage: false,
         );
       });
      // }

    }else if(data.operation=="RIDE_ORDER_RECEIVED"){
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
      // Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
    }

    ///CLEAR ALL NOTIFICATION...
   // var penNotification=await flutterLocalNotificationsPlugin.pendingNotificationRequests();
   //  log("kjdskjsj ${penNotification}");
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
    } on Exception {
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

