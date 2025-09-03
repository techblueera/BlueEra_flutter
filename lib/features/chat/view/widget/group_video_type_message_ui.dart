import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../orders_chat/order_chat_screen.dart';
import 'custom_video_player.dart';
import 'group_custom_video_player.dart';
import 'group_reaction_info_widget.dart';

class GroupChatVideoMessage extends StatefulWidget {
  final MessageMediaUrl? videoUrl;
  final Messages message;
  final String time;
  final int views;
  final int comments;
  final int likes;
  final bool isReceiveMsg;
  final String userId;
  final String conversation;
  final bool? isFromFile;
  final File? filePath;

  GroupChatVideoMessage({
    super.key,
    required this.videoUrl,
    required this.time,
    this.views = 0,
    this.comments = 0,
    this.isFromFile = false,
    this.filePath ,
    this.likes = 0, required this.isReceiveMsg, required this.userId, required this.conversation,required this.message,
  });
  @override
  State<GroupChatVideoMessage> createState() => _GroupChatVideoMessageState();
}

class _GroupChatVideoMessageState extends State<GroupChatVideoMessage> {
  final chatThemeController = Get.find<ChatThemeController>();
  @override
  Widget build(BuildContext context) {

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: (widget.isReceiveMsg) ? chatThemeController.receiveMessageBgColor.value: chatThemeController.myMessageBgColor.value ,
    borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: (widget.isReceiveMsg)?Alignment.centerLeft:Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (widget.isReceiveMsg)?Padding(
              padding: const EdgeInsets.only(left: 8.0,top: 4),
              child: CustomText(

                "${widget.message.sender?.name}",
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade700,
                fontSize: 12.3,
              ),
            ):SizedBox(),
            (widget.isReceiveMsg)?SizedBox(
              height: 4,
            ):SizedBox(),
            Stack(
              children: [
                Container(
                  width: 256,
                  height: 280,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: widget.isReceiveMsg?AppColors.chat_bubble_receive_bg: AppColors.chat_bubble_my_bg,
                          width: 2
                      )
                  ),
                  child: GroupChatCustomVideoPlayer(videoUrl: widget.videoUrl?.url??'',filePath: widget.filePath,isFromFile: widget.isFromFile,),
                ),
                // (widget.isFromFile==true)?SizedBox():Positioned(
                //   bottom: 0,
                //   left: !(widget.isReceiveMsg)?0:null,
                //   right: (widget.isReceiveMsg)?24:null,
                //   child: ReactionInfoWidget(),
                // ),
                (widget.isFromFile==true)?SizedBox():Positioned(
                  bottom: 2,
                  left: !(widget.isReceiveMsg)?2:null,
                  right: (widget.isReceiveMsg)?2:null,
                  child: GroupReactionInfoWidget(message: widget.message,conversation: widget.conversation,userId: widget.userId,time: widget.time,),
                ),
                // Positioned(
                //   bottom: 26,
                //   right: !(widget.isReceiveMsg)?12:null,
                //   left: (widget.isReceiveMsg)?12:null,
                //   child: Text(widget.time,
                //       style: TextStyle(color: Colors.white, fontSize: 10)),
                // )
              ],
            ),

          ],
        ),
      ),
    );
  }
}