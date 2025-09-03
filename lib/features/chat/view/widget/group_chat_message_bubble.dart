import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'component_widgets.dart';
class GroupChatMessageBubble extends StatefulWidget {
  final String message;
  final String time;
  final Messages messages;
  final bool isReceiveMsg;

  const GroupChatMessageBubble({
    super.key,
    required this.message,
    required this.messages,
    required this.isReceiveMsg,
    required this.time,
  });

  @override
  State<GroupChatMessageBubble> createState() => _GroupChatMessageBubbleState();
}

class _GroupChatMessageBubbleState extends State<GroupChatMessageBubble> {

  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();

  @override
  Widget build(BuildContext context) {

    chatThemeController.isMessageSelectionActive;
    return GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(widget.messages);
      },
      onTap: (){
        if(chatThemeController.isMessageSelectionActive.value){
          chatThemeController.selectMoreMessage(widget.messages);
        }
      },

      child:Container(
        width: double.infinity,
        color: Colors.transparent,
        child: Container(
          width: 254,
          margin: EdgeInsets.only(left: (widget.isReceiveMsg)?0:50,right:  (widget.isReceiveMsg)?50:0),
          child: Align(
            alignment: (widget.isReceiveMsg) ? Alignment.centerLeft : Alignment.centerRight,
            child: IntrinsicWidth(
              // stepWidth: 200,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical:(widget.isReceiveMsg)? 5:8),
                decoration: BoxDecoration(
                  color: (widget.isReceiveMsg) ? chatThemeController.receiveMessageBgColor.value: chatThemeController.myMessageBgColor.value ,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular((widget.isReceiveMsg) ? 12 : 0),
                    bottomLeft: Radius.circular((widget.isReceiveMsg) ? 0 : 12),
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    (widget.isReceiveMsg)?Container(
                      child:Row(
                        children: [
                          CustomText(
                            "${widget.messages.sender?.name}",
                            fontWeight: FontWeight.w900,
                            color: Colors.grey.shade700,
                            fontSize: 12.3,
                          ),
                        ],
                      ),
                    ):SizedBox(),
                    (widget.isReceiveMsg)?SizedBox(
                      height: 2,
                    ):SizedBox(),
                    (widget.messages.replyId!=null&&widget.messages.replyId!=''&&widget.messages.replyId!='null')?Container(
                      height: 46,
                      margin: EdgeInsets.only(bottom: 4),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        color: AppColors.greyA5.withOpacity(0.4),
                      ),
                      padding: EdgeInsets.only(right: 8),
                      child: Center(child:
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8,),

                          InkWell(
                            onTap: (){
                              chatViewController.scrollController.jumpTo(100);
                            },
                            child: SizedBox(
                              width: 200,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText("${(widget.messages.replyParentMessage?.myMessage??false)?"You":widget.messages.replyParentMessage?.sender?.name}",
                                    fontWeight: FontWeight.w600,
                                    color: widget.isReceiveMsg ? Colors.black87 : Colors.white,
                                    fontSize: 15,
                                  ),
                                  replyMessageTypeIconWithLabel(widget.messages),

                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                    ):SizedBox(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: (widget.message.length <= 100)
                                      ? widget.message
                                      : widget.message.substring(0, 100),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: widget.isReceiveMsg ? Colors.black : Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                if (widget.message.length > 100)
                                  TextSpan(
                                    text: '... Read more',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.grey9A,
                                      fontSize: 16,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        FocusScope.of(context).unfocus();
                                        _showFullMessageDialog(
                                          context: context,
                                          message: widget.message,
                                          time: widget.time,
                                          isReceiveMsg: widget.isReceiveMsg,
                                        );
                                      },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8,),
                        Align(
                            alignment: Alignment.bottomRight,
                            child: timeAndReadInfoWidget(message: widget.messages,isMyMessage: widget.messages.myMessage??false,time: widget.time,timeColor: (!widget.isReceiveMsg) ? Colors.white : Colors.black54,)
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );


  }

  void _showFullMessageDialog({
    required BuildContext context,
    required String message,
    required String time,
    required bool isReceiveMsg,
  }) {
    Get.dialog(

      useSafeArea: true,
      AlertDialog(
        insetPadding:EdgeInsets.symmetric(horizontal: 18,vertical: 30) ,
        contentPadding: EdgeInsets.only(bottom: 12),
        backgroundColor: AppColors.appBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // side: const BorderSide(color: Colors.white, width: 0.5),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText('Message', color: AppColors.black,fontSize: 16,
                    fontWeight: FontWeight.w600,),
                  CustomText(
                    time,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.black,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6,),
            Divider(color: AppColors.greyB4,),
            const SizedBox(height: 6,),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 500, // ✅ Adjust max height as needed
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                  onTap: (){
                    Get.back();

                  },
                  child: CustomText('Close', color: AppColors.primaryColor,fontWeight: FontWeight.w600,fontSize: 14,)),
            ),
            const SizedBox(height: 4,),

          ],
        ),
      ),
    );

  }
}

class WhatsAppStyleChatBubble extends StatelessWidget {
  final String message;
  final String? label;
  final String time;

  const WhatsAppStyleChatBubble({
    super.key,
    required this.message,
    this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54), // WhatsApp green
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 16, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
