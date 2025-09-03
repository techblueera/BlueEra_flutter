import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../orders_chat/order_chat_screen.dart';
import 'custom_video_player.dart';

class ChatVideoMessage extends StatefulWidget {
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

   ChatVideoMessage({
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
  State<ChatVideoMessage> createState() => _ChatVideoMessageState();
}

class _ChatVideoMessageState extends State<ChatVideoMessage> {

  @override
  Widget build(BuildContext context) {

    return Container(
      child: Align(
        alignment: (widget.isReceiveMsg)?Alignment.centerLeft:Alignment.centerRight,
        child: Stack(
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
              child: ChatCustomVideoPlayer(videoUrl: widget.videoUrl?.url??'',filePath: widget.filePath,isFromFile: widget.isFromFile,),
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
              child: ReactionInfoWidget(message: widget.message,conversation: widget.conversation,userId: widget.userId,time: widget.time,),
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
      ),
    );
  }
}