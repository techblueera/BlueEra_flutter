import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../widget/component_widgets.dart';

class BusinessPinChatList extends StatelessWidget {
  const BusinessPinChatList({super.key, this.isInParentScroll = false});

  /// When `true`, the widget sizes to its content under an unbounded
  /// parent scroll (sliver/nested scroll) — no `Expanded`, and the
  /// inner `ListView` switches to `NeverScrollableScrollPhysics`.
  final bool isInParentScroll;

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final pinArchiveController = Get.find<ChatPinArchiveController>();
    final theme = Theme.of(context);

    return Obx(() {
      final pinnedIds = pinArchiveController.businessPinnedIds;

      if (pinnedIds.isEmpty) {
        return _emptyState();
      }

      final allChats =
          chatViewController.getBusinessChatListModel?.value.chatList ?? [];

      final pinnedChats = allChats.where((chat) {
        return chat != null && pinnedIds.contains(chat.conversationId);
      }).toList();

      if (pinnedChats.isEmpty) {
        return _emptyState();
      }

      final list = Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: ListView.builder(
            itemCount: pinnedChats.length,
            shrinkWrap: true,
            physics: isInParentScroll
                ? const NeverScrollableScrollPhysics()
                : null,
            itemBuilder: (context, index) {
              final chat = pinnedChats[index];

              return ChatListTile(
                type: chat?.sender?.accountType ?? AppConstants.business,
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

      return isInParentScroll ? list : Expanded(child: list);
    });
  }

  /// Empty placeholder that adapts to bounded vs. unbounded layout.
  Widget _emptyState() {
    if (isInParentScroll) {
      return SizedBox(height: 300, child: noChatsFound());
    }
    return Expanded(child: noChatsFound());
  }
}
