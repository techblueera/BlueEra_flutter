import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../model/GetListOfMessageData.dart';
import '../model/shared_person_live_location_model.dart';
import '../socket/live_location_track_socket.dart';

class ChatThemeController extends GetxController {
  Rx<Color> myMessageBgColor = AppColors.chat_bubble_my_bg.obs;
  Rx<Color> receiveMessageBgColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> readMessageStickColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> unReadMessageStickColor = AppColors.chat_bubble_receive_bg.obs;

  RxBool isMessageSelectionActive = false.obs;
  RxBool isDeleteForEveryOneAvailable = true.obs;
  RxString viewLiverLocationReceivedUserId = ''.obs;
  RxList<String> selectedId = <String>[].obs;
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
    selectedId.add(id);

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
      selectedId.remove(id);
    } else {
      // ADD
      selectedMessages.add(message);
      selectedId.add(id);
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
    selectedId.clear();
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
}