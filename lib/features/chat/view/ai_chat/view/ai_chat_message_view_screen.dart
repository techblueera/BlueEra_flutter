import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/common_ai_chat_topics.dart';
import '../../widget/message_card.dart';
class AiChatMessageViewScreen extends StatefulWidget {
  const AiChatMessageViewScreen({super.key, required this.messages, required this.type});
  final  List<Messages> messages;
  final String? type;
  @override
  State<AiChatMessageViewScreen> createState() => _AiChatMessageViewScreenState();
}

class _AiChatMessageViewScreenState extends State<AiChatMessageViewScreen> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {

    return (widget.messages.isEmpty)
        ? InitialMessageOptionDialog(
      userName: userNameGlobal,
      topics: AppConstants.aiChatTopics,
      onSend: (message, tag) {
        SendMessageToAI(message: message, tag: tag);
      },
    )
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
                reverse: (widget.type == AppStrings.Admin)
                    ? false
                    : true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    ...widget.messages.map((message) {
                    return MessageCard(
                      message: message,
                      isInitialMessage:false,
                      conversationId:
                      message.conversationId,
                      userId: message.sender?.id,
                      name: message.sender?.name,
                      contactNo:message.sender?.contactNo,
                      profileImage:
                      message.sender?.profileImage,
                    );
                  }).toList(),
                    InitialMessageOptionDialog(
                      userName: userNameGlobal,
                      topics: AppConstants.aiChatTopics,
                      onSend: (message, tag) {
                        SendMessageToAI(message: message, tag: tag);
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  void SendMessageToAI({required String message, String? tag}){
    chatViewController
        .sendMessageToAiSocket(
        type: widget.type ?? '',
        tag:tag,
        message: message
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