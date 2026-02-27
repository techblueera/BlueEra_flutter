
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:any_link_preview/any_link_preview.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'component_widgets.dart';
class MessageBubble extends StatefulWidget {
  final String message;
  final String time;
  final Messages messages;
  final bool isReceiveMsg;

  const MessageBubble({
    super.key,
    required this.message,
    required this.messages,
    required this.isReceiveMsg,
    required this.time,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  Widget buildLinkPreview(String message) {
    final hasLink = message.contains("http");

    if (!hasLink) return const SizedBox();

    return AnyLinkPreview(
      link: message,
      // ❌ remove UIDirection (causing your crash)
      displayDirection: UIDirection.uiDirectionVertical, // REMOVE if error persists
      showMultimedia: true,
      bodyMaxLines: 1,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      bodyStyle: const TextStyle(fontSize: 14),

      // 🔥 IMPORTANT: Error Handler (prevents crash)
      errorWidget: const SizedBox.shrink(),
      errorImage: "https://via.placeholder.com/150",
    );
  }
  @override
  Widget build(BuildContext context) {

    chatThemeController.isMessageSelectionActive;
    return Container(
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
              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
                  (widget.messages.replyId!=null&&widget.messages.replyId!=''&&widget.messages.replyId!='null')?Container(
                    height: 46,
                    margin: EdgeInsets.only(bottom: 4),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      color: AppColors.greyA5..withValues(alpha: 0.4),
                    ),
                    padding: EdgeInsets.only(right: 8),
                    child: Center(child: Row(
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
                                  maxLines: 2,
                                ),
                                replyMessageTypeIconWithLabel(widget.messages),

                              ],
                            ),
                          ),
                        ),
                      ],
                    )),
                  ):SizedBox(),
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((widget.message.contains("https://")))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SizedBox(
                            height: 260,
                            width:328,
                            child:buildLinkPreview(widget.message),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: (widget.messages.sendStatus==AppStrings.PersonalChatAi)?buildAiWithCallButtons(widget.message): InkWell(
                              onTap: (widget.message.contains("https://"))?(){
                                UrlLauncher.launchUrl(Uri.parse(widget.message));
                              }:null,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: (widget.message.length <= 100)
                                          ? widget.message
                                          : widget.message.substring(0, 100),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: (widget.message.contains("https://"))?AppColors.navy:widget.isReceiveMsg ? Colors.black :Colors.black,
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
                          ),
                          const SizedBox(width: 8,),
                          Align(
                              alignment: Alignment.bottomRight,
                              child: timeAndReadInfoWidget(indicateColor: Colors.black,message: widget.messages,isMyMessage: widget.messages.myMessage??false,time: widget.time,timeColor: (!widget.isReceiveMsg) ? Colors.black : Colors.black54,)
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );


  }

  List<Map<String, dynamic>> _parseBusinesses(String text) {
    final lines = text.split('\n');

    final List<Map<String, dynamic>> results = [];
    Map<String, dynamic>? current;

    final phoneReg = RegExp(r'(\+?\d[\d\s\-()]{6,}\d)');  // More strong pattern

    for (var raw in lines) {
      var line = raw.trim();
      if (line.isEmpty) continue;

      if (RegExp(r'^\d+\.\s*').hasMatch(line)) {
        if (current != null) results.add(current);

        final name = line.replaceAll(RegExp(r'^\d+\.\s*|\*'), "").trim();
        current = {
          "name": name,
          "phones": <String>[],
        };
        continue;
      }


      final phoneMatches = phoneReg.allMatches(line);

      if (phoneMatches.isNotEmpty) {
        // If no business exists → create default group
        current ??= {
          "name": "General Info",
          "phones": <String>[],
        };

        for (var match in phoneMatches) {
          var num = match.group(0)!.trim();

          // normalize (remove extra spaces)
          num = num.replaceAll(RegExp(r'[\s\-]+'), ' ').trim();

          // CASE 3 : Filter +91 ONLY if text contains random data
          bool isIndian = num.contains("+91");

          // Accept only +91 numbers for this new format
          if (isIndian) {
            if (!current["phones"].contains(num)) {
              current["phones"].add(num);
            }
          }
        }
      }
    }

    if (current != null) results.add(current);

    return results;
  }

  Widget buildAiWithCallButtons(String text) {
    final businesses = _parseBusinesses(text);
    int numberCount=0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiFormattedText(text),   // <-- your existing formatted text
        const SizedBox(height: 16),

        // Call numbers under each company
        ...businesses.map((b) {
          numberCount=numberCount+1;
          List list=b["phones"];

          return (list.isEmpty)?SizedBox():Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business name
              CustomText(
                "${numberCount} . ${b["name"]}",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grayText,

              ),
              const SizedBox(height: 6),
              // Phone numbers with call icon
              ...b["phones"].map<Widget>((p) {
                return GestureDetector(
                  onTap: () => launchUrl(Uri.parse("tel:$p")),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            p,
                            // style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.black,
                              fontWeight: FontWeight.w400,
                              // decoration: TextDecoration.underline,
                            // ),
                          ),
                          LocalAssets(imagePath: AppIconAssets.chat_call)
                          // const Icon(Icons.phone, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }


  Widget _buildAiFormattedText(String text) {
    final parts = text.split("**");

    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      bool isBold = i.isOdd;

      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
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
                  Row(
                    children: [
                      CustomText(
                        time,
                        fontWeight: FontWeight.w500,
                        color:  AppColors.black,
                        fontSize: 12,
                      ),
                      SizedBox(width: SizeConfig.size8,),
                      InkWell(
                          onTap: (){
                            Clipboard.setData(ClipboardData(text: message));
                            commonSnackBar(
                                message: "Copied to clipboard");
                          },
                          child: Icon(Icons.copy, size: 20))

                    ],
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
                    color: Colors.white.withValues(alpha: 0.05),
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
              child: Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                      onTap: (){
                        Get.back();
                      },
                      child: CustomText('Close', color: AppColors.primaryColor,fontWeight: FontWeight.w600,fontSize: 14,)),

                ],
              ),
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
