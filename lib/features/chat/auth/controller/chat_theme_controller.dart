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
  RxList<String> selectedId = <String>[].obs;
  Rx<Messages?>? selectedFirstMessage = Messages().obs;

  void resetSelection() {
    isMessageSelectionActive.value = false;
    selectedId.clear();
  }

  void activateSelection(Messages? message) {
    selectedFirstMessage?.value=message;
    String ids = (message?.forwardId==null)?message?.id:message?.forwardId;
    selectedId.add(ids);
    isMessageSelectionActive.value = true;
  }
  void selectMoreMessage(Messages? message){
    String id = (message?.forwardId==null)?message?.id:message?.forwardId;
    if(selectedId.contains(id)){
      selectedId.remove(id);
    }else{
      selectedId.add(id);
    }
    if(selectedId.length==0){
      isMessageSelectionActive.value = false;
      selectedFirstMessage=null;
    }
  }
  void deActivateSelection() {
    selectedFirstMessage=null;
    selectedId.clear();
    isMessageSelectionActive.value = true;
  }
}