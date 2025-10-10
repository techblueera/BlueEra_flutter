import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
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

    return Row(
      mainAxisAlignment: (!widget.isReceiveMsg)?MainAxisAlignment.end:MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        (!widget.isReceiveMsg)?SizedBox():Container(
          margin: EdgeInsets.only(right: 6),
          height: 26,
          width: 26,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown",0.1)
          ),
          child: Center(child: CustomText("${widget.message.sender?.name?.split('')[0]}",fontSize: 13.2,color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown"),)),
        ),
        Container(
          width:  SizeConfig.screenWidth*0.72,
          decoration: BoxDecoration(
            color: (widget.isReceiveMsg) ?chatThemeController.getColorForSender(widget.message.senderId ?? "unknown"): chatThemeController.myMessageBgColor.value ,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular((widget.isReceiveMsg) ? 12 : 0),
              bottomLeft: Radius.circular((widget.isReceiveMsg) ? 0 : 12),
            ),
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
                    fontWeight: FontWeight.w400,
                    color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown"),
                    fontFamily: "Rounded Mplus 1c",
                    fontSize: 13.3,
                  ),

                ):SizedBox(),
                (widget.isReceiveMsg)?SizedBox(
                  height: 4,
                ):SizedBox(),
                Stack(
                  children: [
                    Container(
                      width:  SizeConfig.screenWidth*0.72,
                      height: 280,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular((widget.isReceiveMsg) ? 12 : 0),
                            bottomLeft: Radius.circular((widget.isReceiveMsg) ? 0 : 12),
                          ),
                          border: Border.all(
                              color: widget.isReceiveMsg?chatThemeController.getColorForSender(widget.message.senderId ?? "unknown"): AppColors.chat_bubble_my_bg,
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
        ),
      ],
    );
  }
}