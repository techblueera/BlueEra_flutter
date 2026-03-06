import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/chat_input_box.dart';
import '../widget/component_widgets.dart';
import '../widget/message_card.dart';

class PersonalChatScreen extends StatefulWidget {
  PersonalChatScreen(
      {required this.conversationId,
      required this.userId,
      this.profileImage,
      required this.type,
      this.name,
      this.contactNo,
      required this.isInitialMessage});

  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;


  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {

  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatViewController.listenUserNewMessages(
        userId: widget.userId ?? "",
        conversationId: widget.conversationId ?? '');
    chatThemeController.resetSelection();

    checkPendingMessages();
    super.initState();
  }

  Future<void> checkPendingMessages() async {
    final connectivityResult = await NetworkUtils.isConnected();
    if (!connectivityResult) {
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
            ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type}, );
        chatViewController.emitEvent(
            ChatEmitEvents.newMessageReceived, {ApiKeys.type: AppConstants.personal_Chat_Type}, );

        return true;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: AppColors.fillColor,
          appBar: (chatThemeController.isMessageSelectionActive.value &&
                  widget.type != "Admin")
              ? getChatOptionsAppBar(
              context,
                  profileImage: widget.profileImage,
                  editingController: editingController,
                  conversationId: widget.conversationId,
                  userId: widget.userId,
                  )
              : getChatTitleAppBar(socketType: AppConstants.personal,
              context,
                  userId: widget.userId,
                  type: widget.type,
                  name: widget.name,
                  profileImage: widget.profileImage,
                  contactNo: widget.contactNo, conversationId: widget.conversationId),
          body: Obx(() {

            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              List<Messages> messages =
                  chatViewController.getListOfMessageData ?? [];
              messages.sort((a, b) {
                final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
                    ? DateTime.parse(a.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
                    ? DateTime.parse(b.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return dateA.compareTo(dateB); // descending
              });
              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Obx(() => chatThemeController.chatBackground()),
                    Column(
                      children: [
                        Expanded(
                          child: (messages.isEmpty)
                              ? Center(
                                  child: InkWell(
                                    onTap: () {
                                      Map<String, dynamic> data = {
                                        ApiKeys.other_user_id: widget.userId,
                                        ApiKeys.message: "Namaste \u{1F64F}",
                                        ApiKeys.message_type: "text",
                                      };
                                      chatViewController
                                          .sendInitialMessage(data);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "No conversation yet. ",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "Say Namaste \u{1F64F}",
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: chatViewController.scrollController,
                                  reverse: widget.type != "Admin",
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = widget.type == "Admin"
                                        ? messages[index]
                                        : messages[messages.length - 1 - index];
                                    return MessageCard(
                                      message: message,
                                      isInitialMessage: false,
                                      conversationId: message.conversationId,
                                      userId: message.sender?.id,
                                      name: message.sender?.name,
                                      contactNo: message.sender?.contactNo,
                                      profileImage: message.sender?.profileImage,
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        (widget.type == "Admin")
                            ? SizedBox()
                            : ChatInputBar(
                                isInitialMessage: widget.isInitialMessage,
                                userId: widget.userId ?? '',
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
              ));
            }
          }),
        );
      }),
    );
  }
}
