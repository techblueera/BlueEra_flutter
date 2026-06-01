import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/view/ai_chat_screen.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/business_flag_chat_list.dart';
import '../pin_chat/business_pin_chat_list.dart';
import '../reminder_chat/reminder_chat_list.dart';
import '../widget/component_widgets.dart';

/// Where a business-list row belongs:
///   [chats] — the main chat list (buyer side, friends, groups)
///   [me]    — the seller's "my customers" section (stranger orders)
///   [skip]  — excluded entirely
enum ChatBucket { chats, me, skip }

/// Single source of truth for routing one chat row — the Dart twin of the
/// backend `bucketChat` spec. Call once per row.
///
/// Priority:
///   1. Group rows always go to [ChatBucket.chats].
///   2. Seller side (`i_own_business`) — friend orders stay in chats,
///      stranger customers go to [ChatBucket.me].
///   3. Buyer side (I ordered from someone else's business) → chats.
///
/// `i_own_business` is read straight from the row; when the server hasn't
/// sent it (legacy payload) we fall back to "the counterpart is NOT a
/// business account" — i.e. an individual messaging my business means I'm
/// the seller. `is_friend` similarly falls back to false.
ChatBucket bucketChat(ChatList chat) {
  // Group chats always live in the chat list.
  if (chat.isGroup == true) return ChatBucket.chats;

  final iOwnBusiness = chat.iOwnBusiness ??
      ((chat.sender?.accountType?.toUpperCase() ?? '') !=
          AppConstants.business.toUpperCase());

  // Business convo — seller side.
  if (iOwnBusiness) {
    // Friend override — a friend ordering from my business → chat list.
    if (chat.isFriend == true) return ChatBucket.chats;
    // Stranger customer → "me" section.
    return ChatBucket.me;
  }

  // Business convo — buyer side (I ordered from someone else's business).
  return ChatBucket.chats;
}

class BusinessChatsList extends StatefulWidget {
  const BusinessChatsList({
    super.key,
    this.isForwardUI,
    this.isNewGroupUI,
    this.excludeSenderId,
    this.onlySenderId,
    this.isInParentScroll = false,
  });
  final bool? isForwardUI;
  final bool? isNewGroupUI;

  /// Hides chats whose `lastMessageSenderId` equals this value — used
  /// by the self-employed / professionals "Order" tabs to surface only
  /// incoming inquiries (where the *other* party sent the latest msg).
  /// Null = no exclusion.
  final String? excludeSenderId;

  /// Mirror of [excludeSenderId] — keeps only chats whose
  /// `lastMessageSenderId` matches. Used by the Connect screen's
  /// Inquiry tab so the user sees only their own outgoing inquiries.
  /// Null = no inclusion filter.
  final String? onlySenderId;

  /// Embed-in-parent-scroll mode. When `true`, the inner chat list is
  /// not wrapped in `Expanded` and its `ListView` switches to
  /// `NeverScrollableScrollPhysics`, so the widget sizes to its
  /// content under an unbounded sliver/nested scroll surface (the
  /// self-employed / professionals "Order" tab). Defaults to `false`
  /// — the Connect screen and forward / group-add flows continue to
  /// rely on the bounded `Expanded` layout, unchanged.
  final bool isInParentScroll;

  @override
  State<BusinessChatsList> createState() => _BusinessChatsListState();
}

class _BusinessChatsListState extends State<BusinessChatsList> {
  final chatViewController = Get.find<ChatViewController>();
  late final ChatPinArchiveController pinArchiveController;
  late final ChatLockController lockController;

  @override
  void initState() {
    super.initState();

    pinArchiveController =getOrPut(() => ChatPinArchiveController());
    lockController = getOrPut(() => ChatLockController());
    if (chatViewController.canPopBusiness.value) {
      chatViewController.canPopBusiness.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      print("dljnclsncsdc ${chatViewController.businessChatListResponse.value.status}");
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
              // if (!widget.isInParentScroll) const SizedBox(height: 10),
              HorizontalTabSelector(
                horizontalMargin: 14,
                horizontalPadding: 10,
                verticalMargin: widget.isInParentScroll ? 0 : null,
                tabs: [
                  AppStrings.allTab.tr,
                  AppStrings.pinnedTab.tr,
                  AppStrings.reminderTab.tr,
                  AppStrings.flaggedTab.tr,
                  AppStrings.recordsTab.tr,
                ],
                selectedIndex:
                chatViewController.businessChatTabSelectedIndex.value,
                onTabSelected: (index, val) {
                  chatViewController.businessChatTabSelectedIndex.value = index;
                },
                labelBuilder: (value) => value,
              ),
              const SizedBox(height: 8),
              if (chatViewController.businessChatTabSelectedIndex.value == 0)
                widget.isInParentScroll
                    ? _businessChatListWidget(data, theme)
                    : Expanded(child: _businessChatListWidget(data, theme))
              else if (chatViewController.businessChatTabSelectedIndex.value == 1)
                BusinessPinChatList(isInParentScroll: widget.isInParentScroll)
              else if (chatViewController.businessChatTabSelectedIndex.value == 2)
                  ReminderChatList(isInParentScroll: widget.isInParentScroll)
                else if (chatViewController.businessChatTabSelectedIndex.value == 3)
                    BusinessFlagChatList(
                        isInParentScroll: widget.isInParentScroll)
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
                  AppStrings.noChatsFound.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 6),
                CustomText(AppStrings.goToContactsAndStartNewConversation.tr),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildArchiveTab() {
    final column = Column(
        mainAxisSize: MainAxisSize.min,
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
                        AppStrings.recordsCountFmt.trParams({'count': '$count'}),
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
      );

    return widget.isInParentScroll ? column : Expanded(child: column);
  }

  Widget _businessChatListWidget(GetChatListModel? data, ThemeData theme) {
    List<ChatList?> chatList = data?.chatList ?? [];
    final archivedIds = pinArchiveController.businessArchivedIds;
    final pinnedIds = pinArchiveController.businessPinnedIds;
    final lockedIds = lockController.businessLockedIds;

    // Filter out archived
    chatList = chatList.where((chat) {
      return chat == null || !archivedIds.contains(chat.conversationId);
    }).toList();

    // Locked chats live behind the PIN-gated Locked Chats screen, so they
    // must not appear in the main list (WhatsApp-style Chat Lock).
    chatList = chatList.where((chat) {
      return chat == null || !lockedIds.contains(chat.conversationId);
    }).toList();

    // B2B routing — split the business list into "chats" vs the seller's
    // "me" (my customers) section via [bucketChat]. The Order tabs that
    // surface incoming customers pass [excludeSenderId] → render the "me"
    // bucket; everything else is the main chat list, which hides stranger
    // customers (they live in the seller's "me" section). Forward / group-
    // add pickers must show everything, so they skip bucketing.
    //
    // The Connect "my inquiries" tab keeps its legacy [onlySenderId] filter
    // (outgoing-only), which is an orthogonal slice of the chats bucket.
    final isPicker =
        (widget.isForwardUI ?? false) || (widget.isNewGroupUI ?? false);
    if (widget.onlySenderId != null) {
      chatList = chatList
          .where((c) =>
              (c?.lastMessageSenderId ?? '') == widget.onlySenderId)
          .toList();
    } else if (widget.excludeSenderId != null) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.me)
          .toList();
    } else if (!isPicker) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.chats)
          .toList();
    }

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
      child:  ListView.builder(
        itemCount: chatList.length + topRowCount,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: widget.isInParentScroll
            ? const NeverScrollableScrollPhysics()
            : null,
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
                  AppStrings.recordsLabel.tr,
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
