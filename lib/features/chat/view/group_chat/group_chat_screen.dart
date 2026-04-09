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
  }

  Future<void> _checkPendingMessages() async {
    final connected = await NetworkUtils.isConnected();
    if (!connected) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        chatViewController.emitEvent(
            ChatEmitEvents.ChatList, {ApiKeys.type: "group"});
        return true;
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
            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              final messages = chatViewController.getListOfMessageData ?? [];
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
                            if (index == 0) {
                              chatViewController.emitEvent(
                                  ChatEmitEvents.messageReceived, {
                                ApiKeys.conversation_id: widget.conversationId,
                                ApiKeys.page: 1,
                                ApiKeys.is_online_user: userId,
                                ApiKeys.per_page_message: 30,
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
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(),
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppStrings.noConversationYet.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: AppStrings.sayNamaste.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
        final message = messages[messages.length - 1 - index];
        return GroupMessageCard(
          message: message,
          isInitialMessage: false,
          conversationId: widget.conversationId,
          userId: '',
          name: widget.name,
          contactNo: '',
          profileImage: widget.profileImage,
        );
      },
    );
  }
}
