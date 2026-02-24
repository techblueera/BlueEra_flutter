import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/message_card.dart';
class AiChatMessageViewScreen extends StatelessWidget {
  const AiChatMessageViewScreen({super.key, required this.messages, required this.type, this.conversationId, this.userId, this.profileImage, this.businessId, this.name, this.contactNo, required this.isInitialMessage,});
  final  List<Messages> messages;
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? businessId;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;
  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();

    return (messages.isEmpty)
        ? SizedBox()
        : LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                controller: chatViewController
                    .scrollController,
                reverse: (type == AppStrings.Admin)
                    ? false
                    : true,
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: messages.map((message) {
                    return MessageCard(
                      message: message,
                      isInitialMessage:
                      isInitialMessage,
                      conversationId:
                      conversationId,
                      userId: userId,
                      name: name,
                      contactNo:contactNo,
                      profileImage:
                      profileImage,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TopicButton extends StatelessWidget {
  final String title;
  final Function() onTab;
  const TopicButton({super.key, required this.title, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTab,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
        child: CustomText(
          title,

            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,

        ),
      ),
    );
  }
}