import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_flag_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';

/// Full-screen list of flagged chats opened from the flag icon in the
/// `SocialMainScreen` app bar. Aggregates flagged conversations from
/// both the Inquiry (business) and Orders chat lists.
class OrderFlaggedChatsScreen extends StatelessWidget {
  const OrderFlaggedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final flagController = Get.find<ChatFlagController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const CustomText(
          "Flagged Chats",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: Obx(() {
        final flaggedIds = flagController.flaggedConversationIds;

        final businessChats =
            chatViewController.getBusinessChatListModel?.value.chatList ?? [];
        final orderChats =
            chatViewController.getOrderChatListModel?.value.chatList ?? [];

        final flaggedChats = <ChatList?>[
          ...businessChats,
          ...orderChats,
        ]
            .where((chat) =>
                chat != null && flaggedIds.contains(chat.conversationId))
            .toList();

        if (flaggedChats.isEmpty) {
          return noChatsFound();
        }

        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size16),
          child: ListView.builder(
            itemCount: flaggedChats.length,
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
        );
      }),
    );
  }
}
