import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/view/ai_chat_screen.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/flag_chat_list.dart';
import '../group_chat/group_chat_list.dart';
import '../pin_chat/pin_chat_list.dart';
import '../widget/component_widgets.dart';

class PersonalChatsList extends StatefulWidget {
  const PersonalChatsList({
    super.key,
    this.isForwardUI,
    this.isNewGroupUI,
    this.hideAiChats,
    this.hideSubTabs,
  });

  final bool? isForwardUI;
  final bool? isNewGroupUI;
  final bool? hideAiChats;
  /// When `true`, the All / Group / Pinned / Flagged / Records sub-tab
  /// strip is hidden and only the personal chat list is rendered.
  final bool? hideSubTabs;

  @override
  State<PersonalChatsList> createState() => _PersonalChatsListState();
}

class _PersonalChatsListState extends State<PersonalChatsList> {
  final chatViewController = getOrPut(() => ChatViewController());
  final pinArchiveController = getOrPut(() => ChatPinArchiveController());


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
                ChatEmitEvents.ChatList, {ApiKeys.type: "personal"}, );
          },
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(widget.isForwardUI==false && widget.hideSubTabs != true)
              SizedBox(height: 16,),
              if(widget.isForwardUI==false && widget.hideSubTabs != true)
              HorizontalTabSelector(horizontalMargin: 14,
                horizontalPadding: 10,
                  tabs: [AppStrings.allTab.tr, AppStrings.groupTab.tr, AppStrings.pinnedTab.tr, AppStrings.flaggedTab.tr, AppStrings.recordsTab.tr],
                  selectedIndex: chatViewController.personalTabSelectedIndex.value,
                  onTabSelected: (index,val){
                chatViewController.personalTabSelectedIndex.value=index;
                if(index==1){
                  chatViewController.emitEvent(ChatEmitEvents.ChatList,
                      {ApiKeys.type: AppConstants.group_Chat_Type});
                }
                  },
                  labelBuilder: (value)=>value),
              if(chatViewController.personalTabSelectedIndex.value==0)
                (widget.isForwardUI != true)?
                    Expanded(child: personalChatListWidget(data,theme)):personalChatListWidget(data,theme)
              else if(chatViewController.personalTabSelectedIndex.value==1 && widget.isForwardUI==false)
                Expanded(child: const GroupChatListTabPage())
              else if(chatViewController.personalTabSelectedIndex.value==2)
                const PinChatList()
              else if(chatViewController.personalTabSelectedIndex.value==3)
                const FlagChatList()
              else if(chatViewController.personalTabSelectedIndex.value==4)
                _buildArchiveTab(),


            ],
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }

  Widget _buildArchiveTab() {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () => Get.to(() => const ArchiveChatListPage()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                final count = pinArchiveController.personalArchivedIds.length;
                return Row(
                  children: [
                    Icon(Icons.archive_outlined, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        "${AppStrings.recordsLabel.tr} ($count)",
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey.shade400),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

Widget personalChatListWidget(GetChatListModel? data,ThemeData theme ){
    // Sort pinned to top — archived chats are no longer filtered out here.
    List<ChatList?> chatList = data?.chatList ?? [];
    final archivedIds = pinArchiveController.personalArchivedIds;
    final pinnedIds = pinArchiveController.personalPinnedIds;

    // Sort: pinned chats first, then unpinned
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Count special rows at top: AI chat + Records row (if archived exists)
    final aiOffset = widget.hideAiChats == true ? 0 : 1;
    final recordsOffset = hasArchived ? 1 : 0;
    final topRowCount = aiOffset + recordsOffset;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size70),
      child: (chatList.isEmpty && !hasArchived)
          ? noChatsFound()
          : ListView.builder(
        itemCount: chatList.length + topRowCount,
        shrinkWrap: true,
        physics: widget.isForwardUI == true
            ? NeverScrollableScrollPhysics()
            : null,
        itemBuilder: (context, index) {
          // Records row at very top (index 0)
          if (hasArchived && index == 0) {
            return _buildRecordsRow();
          }

          // AI chat right after Records row
          if (index == recordsOffset && widget.hideAiChats != true) {
            final chat = ChatViewController.personalAiChatModule;
            final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
            final isChatSelected = chatViewController.selectedConversationIds
                .contains(chat?.conversationId ?? '');

            return ChatListTile(
              onTab: (widget.isForwardUI == false) ? () {
                if (isInSelectionMode) {
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                  return;
                }
                Get.to(() => AiChatScreen(
                  profileImage: chat?.sender?.profileImage,
                  name: chat?.sender?.name,
                  type: chat?.sender?.accountType,
                ));
              } : null,
              isFromGroupSelect: widget.isNewGroupUI,
              onLongPress: () {
                if (!isInSelectionMode) {
                  chatViewController.isChatListSelectionMode.value = true;
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                }
              },
              isChatListSelected: isChatSelected,
              onSelect: () => setState(() {}),
              type: chat?.sender?.accountType ?? AppConstants.individual,
              index: -1,
              chatViewController: chatViewController,
              chat: chat,
              theme: theme,
              isForwardUI: widget.isForwardUI,
              showFlagBadge: true,
              context: context,
            );
          }

          final chatIndex = index - topRowCount;
          final chat = chatList[chatIndex];
          final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
          final isChatSelected = chatViewController.selectedConversationIds
              .contains(chat?.conversationId ?? '');
          final isPinned = pinnedIds.contains(chat?.conversationId);

          return ChatListTile(
            isFromGroupSelect: widget.isNewGroupUI,
            onLongPress: () {
              if (!isInSelectionMode) {
                chatViewController.isChatListSelectionMode.value = true;
                chatViewController.toggleChatListSelection(chat);
                setState(() {});
              }
            },
            isChatListSelected: isChatSelected,
            isPinned: isPinned,
            onSelect: () => setState(() {}),
            type: chat?.sender?.accountType ?? AppConstants.individual,
            index: chatIndex,
            chatViewController: chatViewController,
            chat: chat,
            theme: theme,
            isForwardUI: widget.isForwardUI,
            showFlagBadge: true,
            context: context,
          );
        },
      ),
    );
}

  Widget _buildRecordsRow() {
    return Obx(() {
      final count = pinArchiveController.personalArchivedIds.length;
      if (count == 0) return const SizedBox.shrink();
      return InkWell(
        onTap: () => Get.to(() => const ArchiveChatListPage()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.archive_outlined,
                    color: Colors.grey.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  AppStrings.recordsLabel.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    });
  }
}
