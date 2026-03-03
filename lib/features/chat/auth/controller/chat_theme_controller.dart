import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../model/GetListOfMessageData.dart';
import '../model/reminder_chat_list_model.dart';
import '../model/shared_person_live_location_model.dart';
import '../repo/chat_view_repo.dart';
import '../socket/live_location_track_socket.dart';
import 'dart:convert';
import 'package:hive/hive.dart';

class ChatThemeController extends GetxController {
  Rx<Color> myMessageBgColor = AppColors.chat_bubble_my_bg.obs;
  Rx<Color> receiveMessageBgColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> readMessageStickColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> unReadMessageStickColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<ApiResponse> getListOfReminderMsgResponse = ApiResponse.initial('Initial').obs;
  RxList<ReminderMessage> reminderMessageModel = <ReminderMessage>[].obs;
  RxList<ReminderChatListModel> reminderChatList = <ReminderChatListModel>[].obs;
  RxBool isMessageSelectionActive = false.obs;
  RxBool isDeleteForEveryOneAvailable = true.obs;
  RxString viewLiverLocationReceivedUserId = ''.obs;
  RxList<String> selectedMessageIds = <String>[].obs;
  RxInt reminderSubTabSelectedIndex=0.obs;
  Rx<Messages?>? selectedFirstMessage = Messages().obs;

  RxList<Messages> selectedMessages = <Messages>[].obs;
  Rx<SharedPersonsLiveLocationModel> senderLiveLocation=SharedPersonsLiveLocationModel().obs;
  final liveTrackSocket = LiveTrackingSocketService();
  final Map<String, Color> senderColorMap = {}; // senderId → color map

  final List<Color> availableColors = [
    Color(0xFFFFF2F7),
    Color(0xFFEFF9FF),
    Color(0xFFFFF6EE),
    Color(0xFFF1F9FF),
    Color(0xFFFFF3F3),
    Color(0xFFFFFDE7),
    Color(0xFFEFFFEF),
    Color(0xFFF9F4FF),
  ];

  /// Assign or get consistent color for sender

  Color getDarkColorForSender(String senderId, [double amount = 0.50]) {
    final color = getColorForSender(senderId);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
  Color getColorForSender(String senderId) {
    if (senderColorMap.containsKey(senderId)) {
      return senderColorMap[senderId]!;
    }

    // Pick next color from the list or random if needed
    final color = availableColors[senderColorMap.length % availableColors.length]
        .withValues(alpha: 1);

    senderColorMap[senderId] = color;
    return color;
  }
  void resetSelection() {
    isMessageSelectionActive.value = false;
    selectedMessages.clear();
    selectedMessageIds.clear();
    selectedFirstMessage=null;

  }

  void activateSelection(Messages? message) {
    if (message == null) return;

    isMessageSelectionActive.value = true;

    // First selected message
    selectedFirstMessage?.value = message;

    // Add message object
    selectedMessages.add(message);

    // Add id
    String id = message.forwardId ?? message.id;
    selectedMessageIds.add(id);

    // Initial delete-for-everyone state
    isDeleteForEveryOneAvailable.value = message.myMessage == true;
  }


  void selectMoreMessage(Messages? message) {
    if (message == null) return;

    String id = message.forwardId ?? message.id;

    // Select / Deselect
    if (selectedMessages.any((e) => (e.forwardId ?? e.id) == id)) {
      // REMOVE
      selectedMessages.removeWhere((e) => (e.forwardId ?? e.id) == id);
      selectedMessageIds.remove(id);
    } else {
      // ADD
      selectedMessages.add(message);
      selectedMessageIds.add(id);
    }

    // No selection
    if (selectedMessages.isEmpty) {
      isDeleteForEveryOneAvailable.value = true;
      isMessageSelectionActive.value = false;
      selectedFirstMessage = null;
      return;
    }

    // 🔥 Recalculate every time
    isDeleteForEveryOneAvailable.value =
        selectedMessages.every((e) => e.myMessage == true);
  }


  void deActivateSelection() {
    isDeleteForEveryOneAvailable.value=true;
    selectedFirstMessage=null;
    selectedMessageIds.clear();
    selectedMessages.clear();
  }

  Future<void> connectSocket(String userId) async {
      await liveTrackSocket.connectToSocket(null);
      liveTrackSocket.emitEvent(LiveTrackEmitEvents.subscribeToProviders, {
        ApiKeys.userIds: ["${userId}"],
      });
      liveTrackSocket.listenEvent(LiveTrackEmitEvents.locationUpdate, (data) async {
        SharedPersonsLiveLocationModel value = SharedPersonsLiveLocationModel.fromMap(data);
        // if(value.userId==viewLiverLocationReceivedUserId){
          senderLiveLocation.value=value;

        // }
      });

    }




  Future<void> saveReminderData({
    required String conversationId,
    required String name,
    required String profileImagePath,
    required String reminderTime, // 🔥 ADD THIS
  }) async
  {


    final modifiedMessages = <Map<String, dynamic>>[];

    for (var message in selectedMessages) {
      final messageMap = message.toJson();

      /// 🔥 STORE WITH REMINDER TIME (MAIN CHANGE)
      modifiedMessages.add({
        "message": messageMap,
        "reminderTime": reminderTime,
      });
    }

    final reminderMessageBox =
    await Hive.openBox<String>('reminder_messages_box');

    final existingJson = reminderMessageBox.get(conversationId);

    List<Map<String, dynamic>> finalMessages = [];

    if (existingJson != null && existingJson.isNotEmpty) {
      final List decoded = jsonDecode(existingJson);
      finalMessages =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    /// Append new reminders (GOOD – already correct)
    finalMessages.addAll(modifiedMessages);

    await reminderMessageBox.put(
      conversationId,
      jsonEncode(finalMessages),
    );

    /// ================= CHAT LIST PART (NO CHANGE NEEDED) =================
    final reminderChatBox =
    await Hive.openBox<String>('reminder_chat_list');

    const listKey = 'reminder_conversations';

    final existingChatListJson = reminderChatBox.get(listKey);

    List<Map<String, dynamic>> chatList = [];

    if (existingChatListJson != null && existingChatListJson.isNotEmpty) {
      final List decoded = jsonDecode(existingChatListJson);
      chatList =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final index = chatList.indexWhere(
            (chat) => chat[ApiKeys.conversation_id] == conversationId);

    final updatedMeta = {
      ApiKeys.conversation_id: conversationId,
      ApiKeys.name: name,
      ApiKeys.profileImagePath: profileImagePath,
      ApiKeys.messageCount: finalMessages.length,
      ApiKeys.updatedAt: DateTime.now().toIso8601String(),
    };

    if (index != -1) {
      chatList[index] = updatedMeta;
    } else {
      chatList.add(updatedMeta);
    }

    chatList.sort((a, b) =>
        (b['updatedAt'] ?? '').compareTo(a['updatedAt'] ?? ''));

    await reminderChatBox.put(listKey, jsonEncode(chatList));

    commonSnackBar(message: "Reminder Message Added");
    resetSelection();
    Get.back();
  }
  Future<void> getReminderChatListData()async{
    reminderChatList.value= await getReminderChatList();
    getListOfReminderMsgResponse.value=ApiResponse.complete();
  }
  Future<List<ReminderChatListModel>> getReminderChatList() async
  {
    final box = await Hive.openBox<String>('reminder_chat_list');

    const key = 'reminder_conversations';
    final jsonString = box.get(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((item) =>
        ReminderChatListModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
  Future<void> getMessageListByConId(String ConId)async
  {
    reminderMessageModel.value=await getReminderMessagesByConversationId(ConId);
  }
  Future<List<ReminderMessage>> getReminderMessagesByConversationId(
      String conversationId) async
  {
    final box = await Hive.openBox<String>('reminder_messages_box');

    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((item) {
      final map = Map<String, dynamic>.from(item);

      return ReminderMessage(
        message: Messages.fromJson(
          Map<String, dynamic>.from(map["message"]),
        ),
        reminderTime: map["reminderTime"] ?? "",
      );
    }).toList();
  }
  Future<void> updateReminderTime({
    required String conversationId,
    required String messageId, // 👈 unique id of message
    required String newReminderTime,
  }) async {
    final box = await Hive.openBox<String>('reminder_messages_box');

    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) return;

    List<dynamic> jsonList = jsonDecode(jsonString);

    List<Map<String, dynamic>> updatedList =
    jsonList.map((e) => Map<String, dynamic>.from(e)).toList();

    for (var item in updatedList) {
      final messageMap = Map<String, dynamic>.from(item["message"]);

      if (messageMap["messageId"] == messageId) {
        item["reminderTime"] = newReminderTime;
        break;
      }
    }

    await box.put(conversationId, jsonEncode(updatedList));
  }
  Future<void> deleteReminderMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final box = await Hive.openBox<String>('reminder_messages_box');

    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) return;

    List<dynamic> jsonList = jsonDecode(jsonString);

    List<Map<String, dynamic>> updatedList =
    jsonList.map((e) => Map<String, dynamic>.from(e)).toList();

    updatedList.removeWhere((item) {
      final messageMap = Map<String, dynamic>.from(item["message"]);
      return messageMap["messageId"] == messageId;
    });

    if (updatedList.isEmpty) {
      await box.delete(conversationId); // 🔥 optional: delete entire conversation
    } else {
      await box.put(conversationId, jsonEncode(updatedList));
    }
  }
  Future<bool?> setReminderApiCall(Map<String, dynamic> params) async {
    try {
      List<String> value=selectedMessageIds;
      params[ApiKeys.message_ids]=value;
      log("kjsdcnksdjcnksjdcn ${params}");
      ResponseModel responseModel =
      await ChatViewRepo().setReminderApi(params);

      if (responseModel.isSuccess) {

        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    }
    return null;
  }
}
class ReminderMessage {
  final Messages message;
  final String reminderTime;

  ReminderMessage({
    required this.message,
    required this.reminderTime,
  });
}