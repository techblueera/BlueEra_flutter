import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_flag_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../widget/component_widgets.dart';

class FlagChatList extends StatelessWidget {
  const FlagChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final flagController = Get.find<ChatFlagController>();
    final theme = Theme.of(context);

    return Obx(() {
      final flaggedIds = flagController.flaggedConversationIds;

      if (flaggedIds.isEmpty) {
        return Expanded(child: noChatsFound());
      }

      final allChats =
          chatViewController.getPersonalChatListModel?.value.chatList ?? [];

      final flaggedChats = allChats.where((chat) {
        return chat != null && flaggedIds.contains(chat.conversationId);
      }).toList();

      if (flaggedChats.isEmpty) {
        return Expanded(child: noChatsFound());
      }

      return Expanded(
        child: Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: ListView.builder(
            itemCount: flaggedChats.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final chat = flaggedChats[index];

              return ChatListTile(
                type: chat?.sender?.accountType ?? AppConstants.individual,
                index: index,
                chatViewController: chatViewController,
                chat: chat,
                theme: theme,
                isForwardUI: false,
                context: context,
                onSelect: () {},
              );
            },
          ),
        ),
      );
    });
  }
}
