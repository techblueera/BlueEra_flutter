import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../model/GetListOfMessageData.dart';

class LoadChatMediasController extends GetxController {
  Rx<ApiResponse> allMediaResponse = ApiResponse.initial('Initial').obs;
  final localStorageHelper = LocalStorageHelper();
  RxList<MessageMediaUrl> allMedias = <MessageMediaUrl>[].obs;
  final PageController pageController= PageController();
  RxBool? myMessage = true.obs;
  RxBool isBarsVisible = true.obs;
  RxString? createdAt = "".obs;
  RxString mimeType = "".obs;

  void onChangeMimeType(String value){
    mimeType.value=value;
  }
  void onChangeMyMessage(bool? value){
    myMessage?.value=value??true;
  }
  String formatChatHistoryTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

      final timeString = DateFormat('h:mm a').format(dateTime); // 12:30 PM

      if (today == messageDay) {
        return '${AppStrings.todayTime.tr}, $timeString';
      }
      if (today.subtract(Duration(days: 1)) == messageDay) {
        return '${AppStrings.yesterdayTime.tr}, $timeString';
      }

      final dateString = DateFormat('MMM d').format(dateTime);
      return '$dateString, $timeString'; // Jul 17, 12:30 PM

    } catch (e) {
      return '';
    }
  }


  void onChangeMessageTime(String? value){
    String formetText= formatChatHistoryTime(value??'');
    createdAt?.value=formetText;
  }
  Future<void> loadOfflineMessages(String conversationId,String selectedUrl,List<Messages> onlineMessagesList) async {
    List<Messages> messages =
    await localStorageHelper.getMediaMessagesByConversationId(conversationId);

    // Flatten media lists
    final List<MessageMediaUrl> temp = [];
    if(messages.isEmpty){
      for (var msg in messages) {
        if (msg.url != null && msg.url!.isNotEmpty) {
          for (var media in msg.url!) {

            // Attach parent message meta
            media.messageId = msg.id;
            media.conversationId = msg.conversationId;
            media.createdAt = msg.createdAt;
            media.myMessage = msg.myMessage;
            temp.add(media);
          }
        }
      }

    }else{
      for (var msg in onlineMessagesList) {
        if (msg.url != null && msg.url!.isNotEmpty) {
          for (var media in msg.url!) {

            // Attach parent message meta
            media.messageId = msg.id;
            media.conversationId = msg.conversationId;
            media.createdAt = msg.createdAt;
            media.myMessage = msg.myMessage;
            temp.add(media);
          }
        }
      }
    }

    allMedias.value = temp;

    int index = allMedias.indexWhere(
          (item) => item.url == selectedUrl,
    );

    if (index < 0) index = 0;

// jump only once
    Future.delayed(Duration(milliseconds: 50), () {
      if (pageController.hasClients) {
        pageController.jumpToPage(index);
      }
    });
    allMediaResponse.value = ApiResponse.complete(allMedias);
  }


}