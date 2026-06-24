import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/component_widgets.dart';
import '../widget/group_chat_input_box.dart';
import '../widget/group_message_card.dart';

class GroupChatScreen extends StatefulWidget {
  GroupChatScreen({
    required this.conversationId,
    required this.isGroupPrivate,
    this.profileImage,
    required this.type,
    this.name,
  });

  final String? conversationId;
  final String? profileImage;
  final String? name;
  final bool isGroupPrivate;
  final String? type;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to the "All" tab on entry so a stale mention/assigned filter
    // from a previous group session doesn't leak into the initial fetch.
    chatViewController.groupChatScreenSelectedTab.value = 0;
    chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
      ApiKeys.conversation_id: widget.conversationId,
      ApiKeys.page: 1,
      ApiKeys.per_page_message: 30,
    });
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatViewController.listenUserNewMessages(
        userId: "", conversationId: widget.conversationId ?? '');
    chatThemeController.resetSelection();

    _checkPendingMessages();
    chatViewController.getGroupMembersApi({
      ApiKeys.conversation_id: widget.conversationId,
    });

    // WhatsApp-style "jump to latest" affordance.
    chatViewController.scrollController.addListener(_onScroll);
  }

  /// List is `reverse: true`, so the newest message sits at offset 0. Once the
  /// user scrolls up past a threshold we surface the scroll-to-bottom button.
  void _onScroll() {
    if (!chatViewController.scrollController.hasClients) return;
    final show = chatViewController.scrollController.offset > 300;
    if (show != _showScrollDown) {
      setState(() => _showScrollDown = show);
    }
  }

  void _scrollToBottom() {
    if (chatViewController.scrollController.hasClients) {
      chatViewController.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _showScrollDown = false;

  Future<void> _checkPendingMessages() async {
    final connected = await NetworkUtils.isConnected();
    if (!connected) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    chatViewController.scrollController.removeListener(_onScroll);
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (val)  {
        chatViewController.leaveConversation();
        chatViewController.emitEvent(
            ChatEmitEvents.ChatList, {ApiKeys.type: "group"});
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          appBar: (chatThemeController.isMessageSelectionActive.value &&
                  widget.type != "Admin")
              ? getChatOptionsAppBar(context,
                  profileImage: widget.profileImage,
                  editingController: editingController,
                  conversationId: widget.conversationId,
                )
              : getChatTitleAppBar(
                  isGroupPrivate: widget.isGroupPrivate,
                  socketType: "group",
                  context,
                  userId: '',
                  isGroupAppBar: true,
                  type: widget.type,
                  name: widget.name,
                  profileImage: widget.profileImage,
                  contactNo: '',
                  conversationId: widget.conversationId),
          body: Obx(() {
            final _status =
                chatViewController.getListOfMessageResponse.value.status;
            final messages = chatViewController.getListOfMessageData ?? [];
            // Show cached Hive history immediately; spinner only when empty
            // and still loading. Required for WhatsApp-style offline view.
            if (messages.isNotEmpty || _status == Status.COMPLETE) {
              messages.sort((a, b) {
                final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
                    ? DateTime.parse(a.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
                    ? DateTime.parse(b.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return dateA.compareTo(dateB);
              });

              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Obx(() => chatThemeController.chatBackground()),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12),
                        HorizontalTabSelector(
                          unSelectedBackgroundColor: AppColors.white,
                          horizontalMargin: 14,
                          horizontalPadding: 10,
                          tabs: [AppStrings.allTab.tr, AppStrings.mentionedTab.tr, AppStrings.assignedTab.tr, AppStrings.pinnedTab.tr],
                          selectedIndex: chatViewController
                              .groupChatScreenSelectedTab.value,
                          onTabSelected: (index, val) {
                            chatViewController
                                .groupChatScreenSelectedTab.value = index;
                            // Tabs 0/1/2 share the same `messageReceived`
                            // transport — only the filter flags change.
                            // See lib/docs/filtered-messages-integration-guide.md.
                            //   0 → All       (no filter)
                            //   1 → Mentioned (outgoing: messages I sent that
                            //                  tagged at least one user)
                            //   2 → Assigned  (incoming: messages where I'm
                            //                  in tagged_users)
                            //   3 → Pinned    (separate REST API)
                            if (index == 0 || index == 1 || index == 2) {
                              chatViewController.emitEvent(
                                  ChatEmitEvents.messageReceived, {
                                ApiKeys.conversation_id: widget.conversationId,
                                ApiKeys.page: 1,
                                ApiKeys.is_online_user: userId,
                                ApiKeys.per_page_message: 30,
                                if (index == 1) ApiKeys.mentioned: true,
                                if (index == 2) ApiKeys.assigned: true,
                              });
                            } else if (index == 3) {
                              chatViewController.getPinMessageListDataApi({
                                ApiKeys.conversation_id: widget.conversationId,
                              });
                            }
                          },
                          labelBuilder: (value) => value,
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: messages.isEmpty
                              ? _buildEmptyState()
                              : _buildMessageList(messages),
                        ),
                        const SizedBox(height: 6),
                        GroupChatInputBar(
                          conversationId: widget.conversationId ?? '',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                    Positioned(
                      right: 12,
                      bottom: 92,
                      child: _buildScrollToBottomButton(),
                    ),
                  ],
                ),
              );
            } else {
              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Obx(() => chatThemeController.chatBackground()),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        );
      }),
    );
  }

  Widget _buildScrollToBottomButton() {
    return IgnorePointer(
      ignoring: !_showScrollDown,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _showScrollDown ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showScrollDown ? 1 : 0,
          child: GestureDetector(
            onTap: _scrollToBottom,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: InkWell(
        onTap: () {
          chatViewController.sendInitialMessage({
            ApiKeys.conversation_id: widget.conversationId,
            ApiKeys.message: AppStrings.namasteSayHi.tr,
            ApiKeys.message_type: "text",
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5C4), // WhatsApp soft-amber notice tone
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waving_hand_rounded,
                  color: AppColors.primaryColor, size: 28),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: AppStrings.noConversationYet.tr,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: AppStrings.sayNamaste.tr,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<Messages> messages) {
    return ListView.builder(
      controller: chatViewController.scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final pos = messages.length - 1 - index;
        final message = messages[pos];
        // The message rendered visually ABOVE this one (older, since the list
        // is sorted ascending). A run "starts" when the sender changes or a
        // date divider sits above — that first bubble gets the tail + name.
        final olderAbove = pos - 1 >= 0 ? messages[pos - 1] : null;
        final isFirstInGroup = olderAbove == null ||
            olderAbove.senderId != message.senderId ||
            olderAbove.messageType == 'date';
        return GroupMessageCard(
          message: message,
          isInitialMessage: false,
          conversationId: widget.conversationId,
          userId: '',
          name: widget.name,
          contactNo: '',
          profileImage: widget.profileImage,
          showTail: isFirstInGroup,
          showSenderInfo: isFirstInGroup,
        );
      },
    );
  }
}
