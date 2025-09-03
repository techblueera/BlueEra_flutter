import 'dart:io';


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import 'component_widgets.dart';
import 'custom_video_player.dart';
import 'group_media_comment_full_page.dart';
import 'group_reaction_info_widget.dart';
import 'group_video_type_message_ui.dart';
import 'media_message_full_view.dart';

class GroupVideoAndImageCardWidget extends StatefulWidget {
  const GroupVideoAndImageCardWidget({super.key, required this.name,required this.conversationId,required this.userId, this.profileImage, required this.isInitialMessage, this.contactNo, required this.message, required this.time, required this.isReceive, required this.theme,});
  final String conversationId;
  final String userId;
  final String? profileImage;
  final String? name;
  final bool isInitialMessage;
  final String? contactNo;
  final Messages message;
  final     String time;
  final bool isReceive;
  final     ThemeData theme;
  @override
  State<GroupVideoAndImageCardWidget> createState() => _GroupVideoAndImageCardWidgetState();
}

class _GroupVideoAndImageCardWidgetState extends State<GroupVideoAndImageCardWidget> {

  final chatThemeController = Get.find<ChatThemeController>();

  @override
  Widget build(BuildContext context) {

    return  buildImageMessage(widget.message,widget.time,widget.isReceive,widget.theme,widget.userId,widget.conversationId);
  }
  Widget buildImageMessage(Messages message, String time, bool isReceive,
      ThemeData theme, String userId, String conversation) {
    if (message.sendLoadingFile != null &&
        message.sendLoadingFile!.isNotEmpty) {
      return _buildUploadingSingleMedia(
          message.sendLoadingFile??[], time, isReceive, theme, userId,
          conversation,message);
    } else if (message.url?.length == 1) {

      return _buildSingleMedia(
          message.url?.first ?? MessageMediaUrl(), time, isReceive, theme,
          message);
    } else {
      return _buildMediaGrid(message.url ?? [], time, isReceive, theme,message);
    }
  }
  Widget _buildUploadingSingleMedia(List<File> path, String time, bool isReceiveMsg,
      ThemeData theme, String userId, String conversation,Messages message)
  {
    int displayCount = path.length > 4 ? 4 : path.length;
    return Center(
      child: Container(
        child: Align(
          alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
          child: Column(
            crossAxisAlignment:
            isReceiveMsg ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Container(
                width: 254,
                height: 252,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isReceiveMsg
                      ? chatThemeController.receiveMessageBgColor.value
                      : chatThemeController.myMessageBgColor.value,
                ),
                padding: EdgeInsets.all(3),
                child: Column(
                  children: [
                    (path.length==1)?
                    SizedBox(
                      height:216,
                      //         final isVideo =
                      //         path[index].path.toLowerCase().endsWith('.mp4');

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: (path[0].path.toLowerCase().endsWith('.mp4'))
                            ? GroupChatVideoMessage(
                          message: message,
                          conversation: conversation,
                          userId: userId,
                          videoUrl: MessageMediaUrl(),
                          time: time,
                          views: 0,
                          likes: 0,
                          comments: 0,
                          isReceiveMsg: isReceiveMsg,
                          isFromFile: true,
                          filePath: path[0],
                        )
                            : Image.file(path[0],
                            fit: BoxFit.cover),
                      ),
                    ):GridView.builder(
                      itemCount: displayCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisExtent: path.length == 2 ? 220 : 110,
                        crossAxisCount: 2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final isVideo =
                        path[index].path.toLowerCase().endsWith('.mp4');
                        final showOverlay = path.length > 4 && index == 3;

                        return GestureDetector(

                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: isVideo
                                    ? GroupChatVideoMessage(
                                  message: message,
                                  conversation: conversation,
                                  userId: userId,
                                  videoUrl: MessageMediaUrl(),
                                  time: time,
                                  views: 0,
                                  likes: 0,
                                  comments: 0,
                                  isReceiveMsg: isReceiveMsg,
                                  isFromFile: true,
                                  filePath: path[index],
                                )
                                    : Image.file(path[index],
                                    fit: BoxFit.cover),
                              ),
                              if (showOverlay)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${path.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        timeAndReadInfoWidget(message: message,isMyMessage: message.myMessage??false,time: time,timeColor: (!isReceiveMsg) ? Colors.white : Colors.black54,indicateColor:message.messageRead==1?Colors.blue:Colors.grey),
                        const SizedBox(
                          width: 11,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleMedia(MessageMediaUrl path, String time, bool isReceiveMsg,
      ThemeData theme, Messages message)
  {
    final isVideo = path.url?.toLowerCase().endsWith('.mp4');
    return (isVideo ?? false)
        ? GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(message);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if(chatThemeController.isMessageSelectionActive.value){
          chatThemeController.selectMoreMessage(message);
        }else{
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GroupVideoCommentsPage(chaterName: widget.name??'',videoPath: path.url ?? '', message: message, userId: '${widget.userId}', conversationId: '${widget.conversationId}',),
            ),
          );
        }
      },
      child: GroupChatVideoMessage(message: message,
        userId: widget.userId.toString(),
        conversation: widget.conversationId.toString(),
        videoUrl: path,
        time: time,
        views: 0,
        likes: 0,
        comments: 0,
        isReceiveMsg: isReceiveMsg,
      ),
    )
        : GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(message);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if(chatThemeController.isMessageSelectionActive.value){
          chatThemeController.selectMoreMessage(message);
        }else{
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GroupVideoCommentsPage(chaterName: widget.name??'',videoPath: path.url ?? '', message: message, userId: '${widget.userId}', conversationId: '${widget.conversationId}',),
            ),
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) =>
          //         FullImagePreviewPage(
          //           images: [path],
          //           initialIndex: 0,
          //         ),
          //   ),
          // );
        }
      },
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          color: (isReceiveMsg) ? chatThemeController.receiveMessageBgColor.value: chatThemeController.myMessageBgColor.value ,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment:
          isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (isReceiveMsg)?Padding(
                padding: const EdgeInsets.only(left: 8.0,top: 3),
                child: CustomText(

                  "${widget.message.sender?.name}",
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade700,
                  fontSize: 12.3,
                ),
              ):SizedBox(),
              (isReceiveMsg)?SizedBox(
                height: 4,
              ):SizedBox(),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isReceiveMsg
                                ? chatThemeController.receiveMessageBgColor.value
                                : chatThemeController.myMessageBgColor.value,
                            width: 2)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (path.url!.contains('http'))?
                      Image.network(path.url ?? '',
                          height: 250, width: 252, fit: BoxFit.cover):
                      Image.file(File(path.url ?? ''),
                          height: 250, width: 252, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: !isReceiveMsg ? 2 : null,
                    right: isReceiveMsg ? 2 : null,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (message.message != null && message.message != '')
                            ? Container(
                          decoration: BoxDecoration(
                              color: isReceiveMsg
                                  ? chatThemeController.receiveMessageBgColor.value
                                  : chatThemeController.myMessageBgColor.value,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                              )
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: CustomText("${message.message}",
                            fontWeight: FontWeight.w500,
                            color: isReceiveMsg ? Colors.black87 : Colors.white,
                            fontSize: 14,
                          ),
                        )
                            : SizedBox(),
                        GroupReactionInfoWidget(message: message,

                          time: time,
                          userId: widget.userId.toString(),
                          conversation: widget.conversationId.toString(),),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 26,
                    right: !isReceiveMsg ? 12 : null,
                    left: isReceiveMsg ? 12 : null,
                    child: Text(time,
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  )
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<MessageMediaUrl> paths, String time,
      bool isReceiveMsg, ThemeData theme,Messages message)
  {
    int displayCount = paths.length > 4 ? 4 : paths.length;
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: (isReceiveMsg) ? chatThemeController.receiveMessageBgColor.value: chatThemeController.myMessageBgColor.value ,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(
          crossAxisAlignment:
          isReceiveMsg ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            (isReceiveMsg)?Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CustomText(
                "${widget.message.sender?.name}",
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade700,
                fontSize: 12.3,
              ),
            ):SizedBox(),
            (isReceiveMsg)?SizedBox(
              height: 4,
            ):SizedBox(),
            Container(
              width: 254,
              height: 256,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isReceiveMsg
                    ? chatThemeController.receiveMessageBgColor.value
                    : chatThemeController.myMessageBgColor.value,
              ),
              padding: EdgeInsets.all(3),
              child: Column(
                children: [
                  GridView.builder(
                    itemCount: displayCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisExtent: paths.length == 2 ? 220 : 110,
                      crossAxisCount: 2,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final isVideo =
                      paths[index].url?.toLowerCase().endsWith('.mp4');
                      final showOverlay = paths.length > 4 && index == 3;
                      return GestureDetector(
                        onLongPress: (){
                          chatThemeController.activateSelection(message);
                        },
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          if(chatThemeController.isMessageSelectionActive.value){
                            chatThemeController.selectMoreMessage(message.forwardId==null?message.id:message.forwardId);
                          }else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FullImagePreviewPage(
                                      images: paths,
                                      initialIndex: index,
                                    ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: isVideo ?? false
                                  ? ChatCustomVideoPlayer(
                                videoUrl: paths[index].url ?? '',
                              )
                                  :((paths[index].url ?? '').contains('http'))? Image.network(paths[index].url ?? '',
                                  fit: BoxFit.cover):
                              Image.file(File(paths[index].url ?? ''),
                                  height: 250, width: 252, fit: BoxFit.cover),
                            ),
                            if (showOverlay)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${paths.length - 4}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      timeAndReadInfoWidget(message: message,isMyMessage: message.myMessage??false,time: time,timeColor: (!isReceiveMsg) ? Colors.white : Colors.black54,indicateColor:message.messageRead==1?Colors.blue:Colors.grey),
                      const SizedBox(
                        width: 11,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
