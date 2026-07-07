import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import 'component_widgets.dart';
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
              child: ChatCustomVideoPlayer(key: ValueKey('vp_${widget.videoUrl?.url ?? widget.filePath?.path ?? ''}'), videoUrl: widget.videoUrl?.url??'',filePath: widget.filePath,isFromFile: widget.isFromFile,),
            ),
            // WhatsApp-style time + read-receipt chip overlaid on the video,
            // instead of the like/comment/forward reaction footer.
            (widget.isFromFile == true)
                ? const SizedBox()
                : Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: timeAndReadInfoWidget(
                        message: widget.message,
                        isMyMessage: widget.message.myMessage ?? false,
                        time: widget.time,
                        timeColor: Colors.white,
                        indicateColor:
                            widget.message.messageRead == 1 ? Colors.blue : Colors.white70,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}