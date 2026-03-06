import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../widget/component_widgets.dart';

class PinChatList extends StatelessWidget {
  const PinChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final pinArchiveController = Get.find<ChatPinArchiveController>();
    final theme = Theme.of(context);

    return Obx(() {
      final pinnedIds = pinArchiveController.personalPinnedIds;

      if (pinnedIds.isEmpty) {
        return Expanded(child: noChatsFound());
      }

      final allChats =
          chatViewController.getPersonalChatListModel?.value.chatList ?? [];

      final pinnedChats = allChats.where((chat) {
        return chat != null && pinnedIds.contains(chat.conversationId);
      }).toList();

      if (pinnedChats.isEmpty) {
        return Expanded(child: noChatsFound());
      }

      return Expanded(
        child: Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: ListView.builder(
            itemCount: pinnedChats.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final chat = pinnedChats[index];

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
