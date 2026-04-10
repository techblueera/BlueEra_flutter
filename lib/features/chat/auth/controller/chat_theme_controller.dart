import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
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
import '../../view/reminder_chat/reminder_todo_screen.dart';

class ChatThemeController extends GetxController {
  Rx<Color> myMessageBgColor = AppColors.chat_bubble_my_bg.obs;
  Rx<Color> receiveMessageBgColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> readMessageStickColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> unReadMessageStickColor = AppColors.chat_bubble_receive_bg.obs;

  // ── Theme Properties ──
  RxBool isDarkMode = false.obs;
  RxString chatBgAsset = ''.obs; // empty = use bgColor
  RxString chatBgFilePath = ''.obs; // gallery picked wallpaper file path
  Rx<Color> chatBgColor = Colors.white.obs;
  Rx<Color> chatTextColor = Colors.black.obs;
  Rx<Color> chatTimeColor = AppColors.grayText.obs;
  Rx<Color> chatAppBarColor = Colors.white.obs;
  Rx<Color> chatInputBgColor = Colors.white.obs;
  Rx<Color> chatScaffoldColor = Color(0xFFF1F1F3).obs;
  RxString chatFontFamily = 'Default'.obs;
  RxDouble chatFontSize = 16.0.obs;

  static const String _themeBoxName = 'chat_theme_settings';

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }

  Future<void> _loadThemeFromStorage() async {
    final box = await Hive.openBox<String>(_themeBoxName);
    final isDark = box.get('isDarkMode', defaultValue: 'false') == 'true';
    final bgColorValue = int.tryParse(box.get('chatBgColor', defaultValue: '') ?? '');
    final bgAsset = box.get('chatBgAsset', defaultValue: '') ?? '';
    final bgFilePath = box.get('chatBgFilePath', defaultValue: '') ?? '';
    final fontFamily = box.get('chatFontFamily', defaultValue: 'Default') ?? 'Default';
    final fontSize = double.tryParse(box.get('chatFontSize', defaultValue: '16.0') ?? '16.0') ?? 16.0;

    chatFontFamily.value = fontFamily;
    chatFontSize.value = fontSize;
    chatBgAsset.value = bgAsset;
    chatBgFilePath.value = bgFilePath;

    if (isDark) {
      applyDarkTheme(save: false);
    } else if (bgColorValue != null) {
      applyChatBgColor(Color(bgColorValue), save: false);
    } else {
      applyLightTheme(save: false);
    }
  }

  Future<void> _saveThemeToStorage() async {
    final box = await Hive.openBox<String>(_themeBoxName);
    await box.put('isDarkMode', isDarkMode.value.toString());
    // ignore: deprecated_member_use
    await box.put('chatBgColor', chatBgColor.value.value.toString());
    await box.put('chatBgAsset', chatBgAsset.value);
    await box.put('chatBgFilePath', chatBgFilePath.value);
    await box.put('chatFontFamily', chatFontFamily.value);
    await box.put('chatFontSize', chatFontSize.value.toString());
  }

  void applyLightTheme({bool save = true}) {
    isDarkMode.value = false;
    chatBgAsset.value = '';
    chatBgFilePath.value = '';
    chatBgColor.value = Colors.white;
    chatTextColor.value = Colors.black;
    chatTimeColor.value = AppColors.grayText;
    chatAppBarColor.value = Colors.white;
    chatInputBgColor.value = Colors.white;
    chatScaffoldColor.value = Color(0xFFF1F1F3);
    myMessageBgColor.value = AppColors.chat_bubble_my_bg;
    receiveMessageBgColor.value = AppColors.chat_bubble_receive_bg;
    if (save) _saveThemeToStorage();
  }

  void applyDarkTheme({bool save = true}) {
    isDarkMode.value = true;
    chatBgAsset.value = '';
    chatBgFilePath.value = '';
    chatBgColor.value = Color(0xFF0B141A);
    chatTextColor.value = Color(0xFFE9EDEF);
    chatTimeColor.value = Color(0xFF8696A0);
    chatAppBarColor.value = Color(0xFF1F2C34);
    chatInputBgColor.value = Color(0xFF1F2C34);
    chatScaffoldColor.value = Color(0xFF0B141A);
    myMessageBgColor.value = Color(0xFF005C4B);
    receiveMessageBgColor.value = Color(0xFF1F2C34);
    if (save) _saveThemeToStorage();
  }

  void applyChatBgColor(Color color, {bool save = true}) {
    isDarkMode.value = false;
    chatBgAsset.value = '';
    chatBgFilePath.value = '';
    chatBgColor.value = color;
    // Keep other colors as light theme
    chatTextColor.value = Colors.black;
    chatTimeColor.value = AppColors.grayText;
    chatAppBarColor.value = Colors.white;
    chatInputBgColor.value = Colors.white;
    chatScaffoldColor.value = Color(0xFFF1F1F3);
    myMessageBgColor.value = AppColors.chat_bubble_my_bg;
    receiveMessageBgColor.value = AppColors.chat_bubble_receive_bg;
    if (save) _saveThemeToStorage();
  }

  void applyChatBgImage(String assetPath, {bool save = true}) {
    chatBgAsset.value = assetPath;
    chatBgFilePath.value = '';
    if (save) _saveThemeToStorage();
  }

  void applyChatBgFile(String filePath, {bool save = true}) {
    chatBgFilePath.value = filePath;
    chatBgAsset.value = '';
    if (save) _saveThemeToStorage();
  }

  void setChatFont(String fontFamily, {bool save = true}) {
    chatFontFamily.value = fontFamily;
    if (save) _saveThemeToStorage();
  }

  void setChatFontSize(double size, {bool save = true}) {
    chatFontSize.value = size;
    if (save) _saveThemeToStorage();
  }

  /// Public method to save current theme state to Hive
  void saveTheme() => _saveThemeToStorage();

  /// Build a TextStyle using the theme's font settings
  /// When [isMyMessage] is true and dark mode is on, text color becomes white
  /// so sender messages are always readable on dark bubble backgrounds.
  TextStyle chatTextStyle({double? fontSize, FontWeight? fontWeight, Color? color, bool isMyMessage = false}) {
    final Color effectiveColor;
    if (color != null) {
      effectiveColor = color;
    } else if (isDarkMode.value && isMyMessage) {
      effectiveColor = const Color(0xFFE9EDEF);
    } else {
      effectiveColor = chatTextColor.value;
    }

    return TextStyle(
      fontFamily: chatFontFamily.value == 'Default' ? null : chatFontFamily.value,
      fontSize: fontSize ?? chatFontSize.value,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: effectiveColor,
    );
  }

  /// Get background widget for chat screens
  Widget chatBackground() {
    if (chatBgFilePath.value.isNotEmpty) {
      return Positioned.fill(
        child: Image.file(File(chatBgFilePath.value), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: chatBgColor.value),
        ),
      );
    }
    if (chatBgAsset.value.isNotEmpty) {
      return Positioned.fill(
        child: Image.asset(chatBgAsset.value, fit: BoxFit.cover),
      );
    }
    // Default background image for all chat screens
    return Positioned.fill(
      child: Image.asset(AppImageAssets.chatDefaultBg, fit: BoxFit.cover),
    );
  }
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

    commonSnackBar(message: AppStrings.reminderMessageAdded.tr);
    resetSelection();
    Get.back();
    Get.to(() => const ReminderTodoScreen());
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
      return messageMap["_id"] == messageId;
    });

    if (updatedList.isEmpty) {
      await box.delete(conversationId);
      // Also remove from chat list
      await _removeConversationFromReminderList(conversationId);
    } else {
      await box.put(conversationId, jsonEncode(updatedList));
      // Update message count in chat list
      await _updateReminderChatListCount(conversationId, updatedList.length);
    }

    // Refresh the in-memory list
    reminderMessageModel.value =
        await getReminderMessagesByConversationId(conversationId);
    commonSnackBar(message: AppStrings.reminderRemoved.tr);
  }

  Future<void> _removeConversationFromReminderList(String conversationId) async {
    final chatBox = await Hive.openBox<String>('reminder_chat_list');
    const listKey = 'reminder_conversations';
    final existingJson = chatBox.get(listKey);
    if (existingJson == null || existingJson.isEmpty) return;

    List<dynamic> decoded = jsonDecode(existingJson);
    List<Map<String, dynamic>> chatList =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    chatList.removeWhere(
        (chat) => chat[ApiKeys.conversation_id] == conversationId);

    if (chatList.isEmpty) {
      await chatBox.delete(listKey);
    } else {
      await chatBox.put(listKey, jsonEncode(chatList));
    }
    // Refresh the chat list
    reminderChatList.value = await getReminderChatList();
    getListOfReminderMsgResponse.value = ApiResponse.complete();
  }

  Future<void> deleteAllRemindersForConversation(String conversationId) async {
    final box = await Hive.openBox<String>('reminder_messages_box');
    await box.delete(conversationId);
    await _removeConversationFromReminderList(conversationId);
    commonSnackBar(message: AppStrings.allRemindersRemoved.tr);
  }

  Future<void> _updateReminderChatListCount(
      String conversationId, int newCount) async {
    final chatBox = await Hive.openBox<String>('reminder_chat_list');
    const listKey = 'reminder_conversations';
    final existingJson = chatBox.get(listKey);
    if (existingJson == null || existingJson.isEmpty) return;

    List<dynamic> decoded = jsonDecode(existingJson);
    List<Map<String, dynamic>> chatList =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    final index = chatList.indexWhere(
        (chat) => chat[ApiKeys.conversation_id] == conversationId);
    if (index != -1) {
      chatList[index][ApiKeys.messageCount] = newCount;
      await chatBox.put(listKey, jsonEncode(chatList));
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