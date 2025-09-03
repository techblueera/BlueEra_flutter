import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_divider.dart';
import '../../../../widgets/common_icon_row.dart';
import '../../../../widgets/local_assets.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/getMediaMsgCommentsModel.dart';
import '../chat_screen.dart';
import 'component_widgets.dart';
import 'media_message_full_view.dart';
class GroupVideoCommentsPage extends StatefulWidget {
  const GroupVideoCommentsPage(
      {super.key, required this.videoPath, required this.message, required this.chaterName, required this.userId, required this.conversationId});

  final String videoPath;
  final Messages message;
  final String userId;
  final String conversationId;
  final String chaterName;

  @override
  State<GroupVideoCommentsPage> createState() => _GroupVideoCommentsPageState();
}

class _GroupVideoCommentsPageState extends State<GroupVideoCommentsPage> {
  late VideoPlayerController _controller;
  final TextEditingController messageTypeController = TextEditingController();
  final chatViewController = Get.find<GroupChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  bool? like;
  int? like_count;
  int? reply_count;
  String messageTime='';
  @override
  void initState() {
    super.initState();
    messageTime= formatChatTime(widget.message.createdAt ?? '');
    _controller = VideoPlayerController.network(widget.videoPath)
      ..setVolume(1.0)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });

    like_count=int.parse(widget.message.likes_count=="null"?"0":widget.message.likes_count??'0');
    reply_count=int.parse(widget.message.replies_count=='null'?"0":widget.message.replies_count??'0');
    chatViewController.emitEvent("messageViewed", {
      ApiKeys.message_id: widget.message.id ?? '',
      ApiKeys.page: 1,
      ApiKeys.per_page_message: 50,
    });
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildActionRow() {

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [


          CommonIconRow(
            onTap: () async{
              Map<String,dynamic> data={
                ApiKeys.message_id: "${widget.message.id}",
                ApiKeys.type: "Code1"
              };
              bool value = await chatViewController.likeAndUnlikeMessage(data,widget.userId,widget.conversationId);
              if(value){

                setState(() {
                  if(like==null){
                    like=widget.message.is_liked;
                  }
                  if(like??false){
                    like_count=like_count!-1;
                  }else{
                    like_count=like_count!+1;
                  }
                  like=!(like??false);
                });

              }
            },
            imageIcon: (like??widget.message.is_liked ??false) ?
            Icon(Icons.favorite,color: Colors.blue,)
                : Icon(Icons.favorite_border,color: AppColors.secondaryTextColor,),
            text: "${like_count}",
          ),
          CommonVerticalDivider(),

          // Comment
          CommonIconRow(
            onTap: () {

            },
            imageIcon: LocalAssets(imagePath: AppIconAssets.commentIcon),
            text: "${reply_count}",
          ),

          CommonVerticalDivider(),

          // Save
          CommonIconRow(
            imageIcon: LocalAssets(imagePath: AppIconAssets.savedIcon),
            text: "Save",
            onTap: () {

            },
          ),

          CommonVerticalDivider(),

          // upload
          CommonIconRow(
            imageIcon: SvgPicture.asset(
              AppIconAssets.chat_media_forward, height: 24, width: 24,),
            text: "${widget.message.forwards_count=='null'?'0':widget.message.forwards_count??'0'}",
            onTap: () {
              chatThemeController.selectedId.add(widget.message.id??'');
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatMainScreen(isForwardUI:true,message: widget.message,forwardId: widget.message.id??'',)));
            },
          ),
        ],
      ),
    );
  }

  Widget buildComment({
    required Comments comments,    required String username,
    required String profileImage,
    required String text,
    required String time,
    bool isCreator = false,
    bool liked = false,
    int likes = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16,
              backgroundImage: (profileImage!='')?NetworkImage(profileImage):null,
              backgroundColor: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(
                        username,
                        fontWeight: FontWeight.bold
                    ),
                    if (isCreator)
                      const CustomText(" (Creator)",
                          color: Colors.grey
                      ),
                  ],
                ),
                CustomText(text),
                Row(
                  children: [
                    CustomText(time,
                        color: Colors.grey, fontSize: 12),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: (){
                        if(messageTypeController.text.isNotEmpty){
                          messageTypeController.clear();
                          messageTypeController.text="@$username ";
                        }else{
                          messageTypeController.text="@$username ";
                        }

                      },
                      child: const CustomText("Reply",
                          fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
          ),

          Column(
            children: [
              InkWell(
                onTap: ()async{
                  Map<String,dynamic> data={
                    ApiKeys.message_id: "${comments.id}",
                    ApiKeys.type: "Code1"
                  };
                  bool value = await chatViewController.likeAndUnlikeMessage(data,widget.userId,widget.conversationId);
                  if(value){
                    chatViewController.emitEvent("messageViewed", {
                      ApiKeys.message_id: widget.message.id ?? '',
                      ApiKeys.page: 1,
                      ApiKeys.per_page_message: 50,
                    });
                  }

                },
                child: Icon(liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.grey, size: 20),
              ),
              if (likes > 0)
                CustomText(likes.toString(),
                    fontSize: 12
                ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (!_controller.value.isInitialized&&widget.message.messageType=="video") {
      return Scaffold(
        body: const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final Size videoSize = _controller.value.size;
    final bool isPortrait = videoSize.height > videoSize.width;
    return Obx(() {
      return WillPopScope(
        onWillPop: () async {
          chatViewController.emitEvent("messageReceived", {
            ApiKeys.conversation_id: widget.conversationId,
            ApiKeys.page: 1,
            ApiKeys.is_online_user: widget.userId,
            ApiKeys.per_page_message: 30,
          });
          return true;
        },
        child: Scaffold(
          appBar: CommonBackAppBar(
            onBackTap: (){
              chatViewController.emitEvent("messageReceived", {
                ApiKeys.conversation_id: widget.conversationId,
                ApiKeys.page: 1,
                ApiKeys.is_online_user: widget.userId,
                ApiKeys.per_page_message: 30,
              });
              Navigator.pop(context);
            },
            title: "${widget.chaterName}",
          ),
          backgroundColor: AppColors.whiteFE,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: (widget.message.messageType=="video")?videoSize.height/2:250,
                        alignment: Alignment.center,
                        child: (widget.message.messageType=="video")?
                        _controller.value.isInitialized
                            ?  Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: isPortrait ? 40.0 : 0),
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                            ),

                            // Play / Pause overlay icon
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.black26,
                                ),
                                child: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ):const Center(child: CircularProgressIndicator()):Container(

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: (widget.message.url?.first.url?.contains('http')??false)?
                            Image.network(widget.message.url?.first.url ?? '',
                                height: 250, width: 252, fit: BoxFit.cover):
                            Image.file(File(widget.message.url?.first.url ?? ''),
                                height: 250, width: 252,
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 12,
                          right: 22,
                          child: InkWell(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FullImagePreviewPage(
                                          isFromComment: true,
                                          images: [widget.message.url?.first??MessageMediaUrl()],
                                          initialIndex: 0,
                                        ),
                                  ),
                                );
                              },
                              child: Icon(size: 22,Icons.open_in_new,color: Colors.black,)))
                    ],
                  ),


                  buildActionRow(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 18,
                                vertical: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.greyE5
                                )
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(height: 22,
                                  width: 22,
                                  AppIconAssets.chat_box_smile,
                                  color: AppColors.primaryColor,),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    keyboardType: TextInputType.text,
                                    textCapitalization: TextCapitalization.words,
                                    controller: messageTypeController,
                                    onChanged: (value) {

                                    },
                                    style: TextStyle(color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: "Write a comment...",
                                      hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500
                                      ),
                                      fillColor: Colors.transparent,
                                      filled: true,
                                      isDense: true,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            Map<String, dynamic> data = {
                              ApiKeys.conversation_id: widget.message.conversationId,
                              ApiKeys.message: "${messageTypeController.text}",
                              ApiKeys.reply_id: "${widget.message.id}",
                              ApiKeys.message_type: "text",
                            };

                            bool? value= await chatViewController.sendMessage(data);
                            if(value!=null&&value){
                              reply_count=reply_count!+1;
                            }
                            setState(() {

                            });
                            messageTypeController.clear();
                          },
                          child: Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(16)
                            ),
                            child: SvgPicture.asset(height: 21, width: 21,
                                AppIconAssets.send_message_chat),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    height: 400,
                    padding: EdgeInsets.only(top: 8),
                    child: (chatViewController.getMediaMsgCommentsModel?.value.comments?.isEmpty??false)?SizedBox():ListView(
                      children: chatViewController.getMediaMsgCommentsModel?.value.comments?.map((comment) {
                        return buildComment(
                            comments: comment,
                            profileImage:"${comment.sender?.profileImage}" ,
                            liked:  comment.isLiked??false,
                            isCreator: comment.myComment??false,
                            username: "${comment.sender?.name}",
                            text: "${comment.message}",
                            time: "${getRelativeTime(comment.updatedAt??'')}",
                            likes: comment.likesCount??0);
                      }).toList()??[SizedBox()],


                      // buildComment(username: "allyoucaneat",
                      //     text: "Great 👍 #epicness",
                      //     time: "1h",
                      //     likes: 12000),
                      // buildComment(username: "allyoucaneat",
                      //     text: "Nice!! #epicness",
                      //     time: "1h",
                      //     likes: 12000),
                      // buildComment(username: "allyoucaneat",
                      //     text: "@allyoucaneat Great #epicness",
                      //     time: "1h",
                      //     likes: 12000),
                      // ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
  String getRelativeTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return timeago.format(dateTime, locale: 'en_short'); // '13m', '1h', etc.
  }
}
