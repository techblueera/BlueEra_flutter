import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/get_Group_List_Model.dart';
import '../widget/component_widgets.dart';
import 'group_chat_screen.dart';
class GroupChatList extends StatefulWidget {
  const GroupChatList({super.key});

  @override
  State<GroupChatList> createState() => _GroupChatListState();
}

class _GroupChatListState extends State<GroupChatList> {
  final chatViewController = Get.find<GroupChatViewController>();

  @override
  void initState() {
    super.initState();
    // Ensure group list is fetched when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatViewController.emitEvent("ChatList", {ApiKeys.type: "group"});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
         print("Datass:${chatViewController.getGroupChatListModel?.value.chatList}");
      if (chatViewController.groupChatListResponse.value.status == Status.COMPLETE) {
     
        GroupChatListModel? data = chatViewController.getGroupChatListModel?.value;

        return RefreshIndicator(
          onRefresh: () async{
            chatViewController.emitEvent("ChatList", {
              ApiKeys.type:"group"
            });
          },
          child:Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty??true)?noChatsFound(): ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: data?.chatList?.length,
                itemBuilder: (context, index) {
                  final chat=data?.chatList?[index];
                  return  InkWell(
                    onTap: () async{
                      chatViewController.emitEvent("messageReceived", {
                        ApiKeys.conversation_id: chat?.conversationId,
                        ApiKeys.page: 1,
                        ApiKeys.per_page_message: 30,
                      });
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupChatScreen(
                        type: "group",
                        conversationId: chat?.conversationId,
                        profileImage: chat?.groupProfileImage,
                        name: chat?.groupName,
                      )));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: (){
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.all(40),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 300,
                                        maxHeight: 300,
                                      ),
                                      child: Stack(
                                        children: [
                                          // Image Viewer
                                          Center(
                                            child: InteractiveViewer(
                                              panEnabled: true,
                                              minScale: 1.0,
                                              maxScale: 5.0,
                                              child: (chat?.groupProfileImage?.contains('http') ?? false)
                                                  ? CachedNetworkImage(
                                                imageUrl: chat?.groupProfileImage ?? "",
                                                placeholder: (context, url) => const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: CircularProgressIndicator(),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                const Icon(Icons.error, size: 40),
                                                fit: BoxFit.contain,
                                              )
                                                  : Image.file(
                                                File(chat?.groupProfileImage ?? ''),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          // Title Bar
                                          Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                                    child:SizedBox(
                                                      width: 200,
                                                      child: CustomText(
                                                        "${chat?.groupName}",
                                                        maxLines: 1,
                                                        color: Colors.white,
                                                        overflow: TextOverflow.ellipsis, // 👈 ensures "..."
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    )),
                                                IconButton(
                                                  icon: const Icon(Icons.close,color: Colors.white,),
                                                  onPressed: () => Navigator.of(context).pop(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );


                            },
                            child: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              radius: 22,
                              backgroundImage: (chat?.groupProfileImage != null)
                                  ? ((chat?.groupProfileImage!.contains('http')??false)
                                  ? NetworkImage(chat?.groupProfileImage??"")
                                  : FileImage(File(chat?.groupProfileImage??'')) as ImageProvider)
                                  : null,
                              child: (chat?.groupProfileImage != null)
                                  ? null
                                  : Center(child: CustomText("${(chat?.groupName?.split('')[0])!.capitalize}",color: Colors.white,fontWeight: FontWeight.w800,fontSize: 18,)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                child: CustomText(
                                  "${chat?.groupName?.capitalize}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // 👈 ensures "..."
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              SizedBox(
                                width: 150,
                                child: (chat?.lastMessageType == "document" ||
                                    chat?.lastMessageType == "contact" ||
                                    chat?.lastMessageType == "audio" ||
                                    chat?.lastMessageType == "location" ||chat?.lastMessageType == "image" ||
                                    chat?.lastMessageType == "video")
                                    ? Row(
                                  children: [
                                    Icon(
                                      chat?.lastMessageType == "document"
                                          ? Icons.picture_as_pdf
                                          : chat?.lastMessageType == "contact"
                                          ? Icons.person
                                          : chat?.lastMessageType == "audio"
                                          ? Icons.audiotrack
                                          : chat?.lastMessageType == "video"
                                          ? Icons.video_chat
                                          : chat?.lastMessageType == "location"?
                                      Icons.location_history
                                          :Icons.camera_alt,
                                      color: AppColors.grey9A,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    CustomText(
                                      chat?.lastMessageType == "document"
                                          ? "Document"
                                          : chat?.lastMessageType == "contact"
                                          ? "Contact"
                                          : chat?.lastMessageType == "audio"
                                          ? "Audio"
                                          : chat?.lastMessageType == "video"
                                          ? "Video"
                                          : chat?.lastMessageType == "location"?
                                      "Location"
                                          :"Image",
                                      fontSize: 14,
                                      color: AppColors.grey9A,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                )
                                    : CustomText(
                                  "${chat?.lastMessage==''?"No message yet":chat?.lastMessage}",
                                  fontSize: 14,
                                  color: AppColors.grey9A,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          SizedBox(width: 10),
                         Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                "${formatTimeFromUtc(chat?.updatedAt ?? '')}",
                                fontSize: 11,
                                color: AppColors.grey9A,
                              ),
                              SizedBox(height: 6),
                              (index == 0 || index == 1 || index == 2)
                                  ? (chat?.unreadCount == 0)
                                  ? SizedBox()
                                  : CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.lightBlue,
                                child: CustomText(
                                  "${chat?.unreadCount}",
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              )
                                  : SizedBox(),
                            ],
                          ),

                        ],
                      ),
                    ),
                  );
                }
            ),
          ),
        );

      } else if(chatViewController.personalChatListResponse.value.status == Status.INITIAL){
        return SizedBox();
      }else{
        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(AppIconAssets.chat,color: Colors.black,
                  height: 70,
                  width: 70,),
                const SizedBox(height: 14,),
                CustomText("No Chats Found",fontSize: 16,fontWeight: FontWeight.w600,),
                const SizedBox(height: 6,),
                CustomText("Go to contacts and start new conversation"),
              ],
            ),
          ),
        );
      }
    });
  }
}
