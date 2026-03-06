import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../widget/component_widgets.dart';

class ArchiveChatListPage extends StatelessWidget {
  const ArchiveChatListPage({super.key, this.isBusiness = false});

  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final pinArchiveController = Get.find<ChatPinArchiveController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const CustomText(
          "Records Chats",
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      body: Obx(() {
        final archivedIds = pinArchiveController.archivedIds(isBusiness);

        if (archivedIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                CustomText(
                  "No records found",
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          );
        }

        final allChats = isBusiness
            ? chatViewController.getBusinessChatListModel?.value.chatList ?? []
            : chatViewController.getPersonalChatListModel?.value.chatList ?? [];

        final archivedChats = allChats.where((chat) {
          return chat != null && archivedIds.contains(chat.conversationId);
        }).toList();

        if (archivedChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                CustomText(
                  "No records found",
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: archivedChats.length,
          itemBuilder: (context, index) {
            final chat = archivedChats[index];
            return Dismissible(
              key: Key(chat?.conversationId ?? '$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppColors.primaryColor,
                child: const Icon(Icons.unarchive, color: Colors.white),
              ),
              onDismissed: (_) {
                pinArchiveController.toggleArchive(
                    chat?.conversationId ?? '',
                    isBusiness: isBusiness);
              },
              child: ChatListTile(
                type: chat?.sender?.accountType ??
                    (isBusiness ? AppConstants.business : AppConstants.individual),
                index: index,
                chatViewController: chatViewController,
                chat: chat,
                theme: theme,
                isForwardUI: false,
                context: context,
                onSelect: () {},
              ),
            );
          },
        );
      }),
    );
  }
}
