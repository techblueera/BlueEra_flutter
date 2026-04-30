import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/view/ai_chat_screen.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/business_flag_chat_list.dart';
import '../pin_chat/business_pin_chat_list.dart';
import '../reminder_chat/reminder_chat_list.dart';
import '../widget/component_widgets.dart';

class BusinessChatsList extends StatefulWidget {
  const BusinessChatsList({super.key, this.isForwardUI, this.isNewGroupUI});
  final bool? isForwardUI;
  final bool? isNewGroupUI;
  @override
  State<BusinessChatsList> createState() => _BusinessChatsListState();
}

class _BusinessChatsListState extends State<BusinessChatsList> {
  final chatViewController = Get.find<ChatViewController>();
  late final ChatPinArchiveController pinArchiveController;

  @override
  void initState() {
    super.initState();
    pinArchiveController = Get.find<ChatPinArchiveController>();
    if (chatViewController.canPopBusiness.value) {
      chatViewController.canPopBusiness.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.businessChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            chatViewController.getBusinessChatListModel?.value;
        return RefreshIndicator(
          onRefresh: () async {
            chatViewController.emitEvent(
                ChatEmitEvents.ChatList, {ApiKeys.type: "business"});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              HorizontalTabSelector(
                horizontalMargin: 14,
                horizontalPadding: 10,
                tabs: ['All', "Pinned", "Reminder", "Flagged", "Records"],
                selectedIndex:
                    chatViewController.businessChatTabSelectedIndex.value,
                onTabSelected: (index, val) {
                  chatViewController.businessChatTabSelectedIndex.value = index;
                },
                labelBuilder: (value) => value,
              ),
              SizedBox(height: 12),
              if (chatViewController.businessChatTabSelectedIndex.value == 0)
                Expanded(child: _businessChatListWidget(data, theme))
              else if (chatViewController.businessChatTabSelectedIndex.value == 1)
                const BusinessPinChatList()
              else if (chatViewController.businessChatTabSelectedIndex.value == 2)
                ReminderChatList()
              else if (chatViewController.businessChatTabSelectedIndex.value == 3)
                const BusinessFlagChatList()
              else if (chatViewController.businessChatTabSelectedIndex.value == 4)
                _buildArchiveTab(),
            ],
          ),
        );
      } else if (chatViewController.businessChatListResponse.value.status ==
          Status.INITIAL) {
        return SizedBox();
      } else {
        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppIconAssets.chat,
                  color: Colors.black,
                  height: 70,
                  width: 70,
                ),
                const SizedBox(height: 14),
                CustomText(
                  "No Chats Found",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 6),
                CustomText("Go to contacts and start new conversation"),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildArchiveTab() {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () => Get.to(() => const ArchiveChatListPage(isBusiness: true)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                final count =
                    pinArchiveController.businessArchivedIds.length;
                return Row(
                  children: [
                    Icon(Icons.archive_outlined,
                        color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Records ($count)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
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

  Widget _businessChatListWidget(GetChatListModel? data, ThemeData theme) {
    List<ChatList?> chatList = data?.chatList ?? [];
    final archivedIds = pinArchiveController.businessArchivedIds;
    final pinnedIds = pinArchiveController.businessPinnedIds;

    // Filter out archived
    chatList = chatList.where((chat) {
      return chat == null || !archivedIds.contains(chat.conversationId);
    }).toList();

    // Sort pinned to top
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Top rows: Records + AI chat
    final recordsOffset = hasArchived ? 1 : 0;
    final aiOffset = 1; // always show AI chat
    final topRowCount = recordsOffset + aiOffset;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size70),
      child: (chatList.isEmpty && !hasArchived)
          ? noChatsFound()
          : ListView.builder(
              itemCount: chatList.length + topRowCount,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                // Records row at very top
                if (hasArchived && index == 0) {
                  return _buildRecordsRow();
                }

                // AI chat right after Records row
                if (index == recordsOffset) {
                  final chat = ChatViewController.businessAiChatModule;
                  final isInSelectionMode =
                      chatViewController.isChatListSelectionMode.value;
                  final isChatSelected = chatViewController
                      .selectedConversationIds
                      .contains(chat?.conversationId ?? '');

                  return ChatListTile(
                    onTab: () {
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
                    },
                    isFromGroupSelect: widget.isNewGroupUI,
                    onLongPress: () {
                      if (!isInSelectionMode) {
                        chatViewController.isChatListSelectionMode.value =
                            true;
                        chatViewController.toggleChatListSelection(chat);
                        setState(() {});
                      }
                    },
                    isChatListSelected: isChatSelected,
                    onSelect: () => setState(() {}),
                    type:
                        chat?.sender?.accountType ?? AppConstants.business,
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
                final isInSelectionMode =
                    chatViewController.isChatListSelectionMode.value;
                final isChatSelected = chatViewController
                    .selectedConversationIds
                    .contains(chat?.conversationId ?? '');
                final isPinned =
                    pinnedIds.contains(chat?.conversationId);

                return ChatListTile(
                  isFromGroupSelect: widget.isNewGroupUI,
                  onLongPress: () {
                    if (!isInSelectionMode) {
                      chatViewController.isChatListSelectionMode.value =
                          true;
                      chatViewController.toggleChatListSelection(chat);
                      setState(() {});
                    }
                  },
                  isChatListSelected: isChatSelected,
                  isPinned: isPinned,
                  onSelect: () => setState(() {}),
                  type: chat?.sender?.accountType ?? AppConstants.business,
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
      final count = pinArchiveController.businessArchivedIds.length;
      if (count == 0) return const SizedBox.shrink();
      return InkWell(
        onTap: () => Get.to(() => const ArchiveChatListPage(isBusiness: true)),
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
                child: Text(
                  "Records",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
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
