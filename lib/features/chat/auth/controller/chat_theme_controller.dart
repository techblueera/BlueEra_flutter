import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/GetListOfMessageData.dart';

class ChatThemeController extends GetxController {
  Rx<Color> myMessageBgColor = AppColors.chat_bubble_my_bg.obs;
  Rx<Color> receiveMessageBgColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> readMessageStickColor = AppColors.chat_bubble_receive_bg.obs;
  Rx<Color> unReadMessageStickColor = AppColors.chat_bubble_receive_bg.obs;

  RxBool isMessageSelectionActive = false.obs;
  RxBool isDeleteForEveryOneAvailable = true.obs;
  RxList<String> selectedId = <String>[].obs;
  Rx<Messages?>? selectedFirstMessage = Messages().obs;

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
    selectedId.clear();
  }

  void activateSelection(Messages? message) {
      isDeleteForEveryOneAvailable.value=message?.myMessage??true;
    selectedFirstMessage?.value=message;
    String ids = (message?.forwardId==null)?message?.id:message?.forwardId;
    selectedId.add(ids);
    isMessageSelectionActive.value = true;
  }
  void selectMoreMessage(Messages? message){
    if(isDeleteForEveryOneAvailable.value==false){
      isDeleteForEveryOneAvailable.value=message?.myMessage??true;
    }
    String id = (message?.forwardId==null)?message?.id:message?.forwardId;
    if(selectedId.contains(id)){
      selectedId.remove(id);
    }else{
      selectedId.add(id);
    }
    if(selectedId.length==0){
      isDeleteForEveryOneAvailable.value=true;
      isMessageSelectionActive.value = false;
      selectedFirstMessage=null;
    }
  }
  void deActivateSelection() {
    isDeleteForEveryOneAvailable.value=true;
    selectedFirstMessage=null;
    selectedId.clear();
    isMessageSelectionActive.value = true;
  }
}