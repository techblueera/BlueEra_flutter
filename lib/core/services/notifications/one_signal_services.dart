
import 'dart:developer';

import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../../features/chat/auth/controller/chat_view_controller.dart';
import 'model/OneSignalNotificationDetailsModel.dart';


class OnesignalService {

  Future<void> initialize() async {
    // Set debug log level
    await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // OneSignal.initialize("6cc2a225-b303-4818-9d30-4f6113708187");
    OneSignal.initialize("0f8a3218-2a6a-4811-b352-cb1c8c2b58d7");
    // Request notification permission
    final bool granted = await OneSignal.Notifications.requestPermission(true);
    print("🔔 Notification permission granted: $granted");

    OneSignal.User.pushSubscription.token;


    // Only initialize if permission was granted
    if (granted) {
      OneSignal.User.pushSubscription.addObserver((state) {
        print("✅ PushSubscription optedIn: ${OneSignal.User.pushSubscription.optedIn}");
        print("✅ PushSubscription ID: ${OneSignal.User.pushSubscription.id}");
        print("✅ PushSubscription Token: ${OneSignal.User.pushSubscription.token}");
        print("✅ PushSubscription JSON: ${state.current.jsonRepresentation()}");
      });

      print("✅ OneSignal initialized successfully after permission granted.");
    } else {
      print("❌ Notification permission denied. OneSignal not initialized.");
    }
  }
  static Future<void> setOneSignalUserIdentity(String userName) async {
    try {
       await OneSignal.login(userName); // ✅ Correct method

      print('✅ OneSignal external user ID set: $userName');
      print('🔔 Push Token: ${OneSignal.User.pushSubscription.token}');
    } catch (e) {
      print('❌ Error setting OneSignal user ID: $e');
    }
  }
  Future<void> checkOneSignalStatus() async {
    final isOptedIn = OneSignal.User.pushSubscription.optedIn;
    final userId = OneSignal.User.pushSubscription.id;
    final pushToken = OneSignal.User.pushSubscription.token;

    print("🔍 OneSignal Opted In: $isOptedIn");
    print("🔍 OneSignal User ID: $userId");
    print("🔍 OneSignal Push Token: $pushToken");

    if (userId == null || pushToken == null) {
      print("❌ OneSignal is not properly initialized.");
    } else {
      print("✅ OneSignal is active and initialized.");
    }
  }
  onNotifiacation() {

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      log("kdjacnksjdcnksjcnsdc (( ${event.notification.additionalData}");

      if (event.notification.additionalData!['call_type'].toString() == 'video_call') {
        if (event.notification.additionalData!['missed_call'].toString() ==
            'true') {
          OneSignal.Notifications.clearAll();
          // stopRingtone();
          // Get.offAll(
          //   Chats(
          //   ),
          // );
          // Get.put(ChatListController()).forChatList();
        } else {
          // Get.to(IncomingCallScrenn(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   callerImage: event
          //       .notification.additionalData!['sender_profile_image']
          //       .toString(),
          //   senderName:
          //   event.notification.additionalData!['senderName'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   message_id:
          //   event.notification.additionalData!['message_id'].toString(),
          //   caller_id:
          //   event.notification.additionalData!['senderId'].toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
          // // FlutterRingtonePlayer().playRingtone();
          // playCustomRingtone();
          // AudioManager.setEarpiece();
        }
      } else if (event.notification.additionalData!['call_type'].toString() ==
          'audio_call') {
        if (event.notification.additionalData!['missed_call'].toString() ==
            "true") {
          OneSignal.Notifications.clearAll();
          // stopRingtone();
          // Get.offAll(
          //   Chats(
          //   ),
          // );
          // Get.put(ChatListController()).forChatList();
        } else {
          // Get.to(IncomingCallScrenn(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   callerImage: event
          //       .notification.additionalData!['sender_profile_image']
          //       .toString(),
          //   senderName:
          //   event.notification.additionalData!['senderName'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   message_id:
          //   event.notification.additionalData!['message_id'].toString(),
          //   caller_id:
          //   event.notification.additionalData!['senderId'].toString(),
          //   forVideoCall: false,
          //   receiverImage: event
          //       .notification.additionalData!['receiver_profile_image']
          //       .toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
          // // FlutterRingtonePlayer().playRingtone();
          // playCustomRingtone();
          // AudioManager.setEarpiece();
        }
      }
    });
  }

  onNotificationClick() {

    OneSignal.Notifications.addClickListener((event) {
      if(event.notification.additionalData!=null){
        OneSignalNotificationDetailsModel data =OneSignalNotificationDetailsModel.fromJson(event.notification.additionalData);
        if(event.notification.additionalData!['operation']=="sent_message"){
          // OneSignal.Notifications.clearAll();
          final chatViewController = Get.find<ChatViewController>();
          chatViewController.connectSocket();
          chatViewController.openAnyOneChatFunction(type: "personal",
            conversationId: data.conversationId??'',
            userId: data.senderUser?.id,
      contactName: data.senderUser?.name,
            contactNo: data.senderUser?.contact,
              isInitialMessage: false
          );
        }
      }

      if (event.result.actionId == "accept") {
        if (event.notification.additionalData!['call_type'].toString() ==
            'video_call') {
          //
          // stopRingtone();
          // Get.off(VideoCallScreen(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
        } else if (event.notification.additionalData!['call_type'].toString() ==
            'audio_call') {

          // stopRingtone();
          // Get.off(AudioCallScreen(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   receiverImage: event
          //       .notification.additionalData!["sender_profile_image"]
          //       .toString(),
          //   receiverUserName:
          //   event.notification.additionalData!["senderName"].toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
        }
      } else if (event.result.actionId == "decline") {
        if (event.notification.additionalData!['call_type'].toString() ==
            'video_call') {
          // stopRingtone();
          if (event.notification.additionalData!['is_group'].toString() ==
              "true") {
          //   Get.offAll(
          //     Chats(
          //     ),
          //   );
          } else {
            // roomIdController.callCutByReceiver(
            //   conversationID: event
            //       .notification.additionalData!['conversation_id']
            //       .toString(),
            //   message_id:
            //   event.notification.additionalData!['message_id'].toString(),
            //   caller_id:
            //   event.notification.additionalData!['senderId'].toString(),
            // );
          }
        } else if (event.notification.additionalData!['call_type'].toString() ==
            'audio_call') {
          // stopRingtone();
          if (event.notification.additionalData!['is_group'].toString() ==
              "true") {
            // Get.offAll(
            //   Chats(
            //   ),
            // );
          } else {
            // roomIdController.callCutByReceiver(
            //   conversationID: event
            //       .notification.additionalData!['conversation_id']
            //       .toString(),
            //   message_id:
            //   event.notification.additionalData!['message_id'].toString(),
            //   caller_id:
            //   event.notification.additionalData!['senderId'].toString(),
            // );
          }
        }
      } else {
        if (event.notification.additionalData!['call_type'].toString() ==
            'video_call' &&
            event.notification.additionalData!['missed_call'].toString() ==
                'false') {
          // stopRingtone();
          // Get.to(IncomingCallScrenn(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   callerImage: event
          //       .notification.additionalData!['sender_profile_image']
          //       .toString(),
          //   senderName:
          //   event.notification.additionalData!['senderName'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   message_id:
          //   event.notification.additionalData!['message_id'].toString(),
          //   caller_id:
          //   event.notification.additionalData!['senderId'].toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
        } else if (event.notification.additionalData!['call_type'].toString() ==
            'audio_call' &&
            event.notification.additionalData!['missed_call'].toString() ==
                'false') {
          // stopRingtone();
          // Get.to(IncomingCallScrenn(
          //   roomID: event.notification.additionalData!['room_id'].toString(),
          //   callerImage: event
          //       .notification.additionalData!['sender_profile_image']
          //       .toString(),
          //   senderName:
          //   event.notification.additionalData!['senderName'].toString(),
          //   conversation_id: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   message_id:
          //   event.notification.additionalData!['message_id'].toString(),
          //   caller_id:
          //   event.notification.additionalData!['senderId'].toString(),
          //   forVideoCall: false,
          //   receiverImage: event
          //       .notification.additionalData!['receiver_profile_image']
          //       .toString(),
          //   isGroupCall:
          //   event.notification.additionalData!['is_group'].toString(),
          // ));
        } else if (event.notification.additionalData!['notification_type']
            .toString() ==
            'message' &&
            event.notification.additionalData!['is_group'].toString() ==
                'false') {
        // Get.to(SingleChatMsg(
          //   conversationID: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   username:
          //   event.notification.additionalData!['senderName'].toString(),
          //   userPic:
          //   event.notification.additionalData!['profile_image'].toString(),
          //   index: 0,
          //   isMsgHighLight: false,
          //   isBlock: bool.parse(event.notification.additionalData!['is_block']),
          //   userID: event.notification.additionalData!['senderId'].toString(),
          // ));
        } else if (event.notification.additionalData!['notification_type']
            .toString() ==
            'message' &&
            event.notification.additionalData!['is_group'].toString() ==
                'true') {
          // Get.to(GroupChatMsg(
          //   conversationID: event
          //       .notification.additionalData!['conversation_id']
          //       .toString(),
          //   gPusername:
          //   event.notification.additionalData!['senderName'].toString(),
          //   gPPic:
          //   event.notification.additionalData!['profile_image'].toString(),
          //   index: 0,
          //   isMsgHighLight: false,
          // ));
        }
      }
    });
  }
}

