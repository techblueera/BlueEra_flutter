
import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../widget/component_widgets.dart';

class PersonalChatsList extends StatefulWidget {
  const PersonalChatsList({super.key, this.isForwardUI, this.isNewGroupUI});

  final bool? isForwardUI;
  final bool? isNewGroupUI;

  @override
  State<PersonalChatsList> createState() => _PersonalChatsListState();
}

class _PersonalChatsListState extends State<PersonalChatsList> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.personalChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            chatViewController.getPersonalChatListModel?.value;

        return RefreshIndicator(
          onRefresh: () async {
            chatViewController.emitEvent(
                ChatEmitEvents.ChatList, {ApiKeys.type: "personal"}, true);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty ?? true)
                ? noChatsFound()
                : ListView.builder(
              itemCount: (data?.chatList?.length ?? 0) + 1, // ADD 1 EXTRA ITEM
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final chat =(index == 0)? ChatViewController.personalAiChatModule:data?.chatList?[index - 1];
                return ChatListTile(onTab: (index == 0)?(){
                 Get.to(()=> AiChatScreen(
                   profileImage: chat?.sender?.profileImage,
                   name: chat?.sender?.name,
                   contactNo: chat?.sender?.contactNo,
                   conversationId: '',
                   userId: '',
                     businessId: '',
                   type: chat?.sender?.accountType,
                   isInitialMessage: false,));
                }:null,
                  isFromGroupSelect: widget.isNewGroupUI,
                  onSelect: () {
                    setState(() {});
                  },
                  type: chat?.sender?.accountType ?? AppConstants.individual,
                  index: index - 1, // correct index for chat list
                  chatViewController: chatViewController,
                  chat: chat,
                  theme: theme,
                  isForwardUI: widget.isForwardUI,
                  context: context,
                );
              },
            ),
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }

  String formatTimeFromUtc(String utcString) {
    DateTime utcDate = DateTime.parse(utcString);
    DateTime localDate = utcDate.toLocal();
    String formattedTime = DateFormat.jm().format(localDate); // e.g. 9:52 PM
    return formattedTime;
  }
}
