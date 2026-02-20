import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';
import 'group_chat_screen.dart';

class GroupChatListTabPage extends StatefulWidget {
  const GroupChatListTabPage({super.key});

  @override
  State<GroupChatListTabPage> createState() => _GroupChatListTabPageState();
}

class _GroupChatListTabPageState extends State<GroupChatListTabPage> {
  final groupChatViewController = Get.find<ChatViewController>();

  // @override
  // void initState() {
  //   super.initState();
  //   // Ensure group list is fetched when screen opens
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     groupChatViewController.emitEvent("ChatList", {ApiKeys.type: "group"});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (groupChatViewController.groupChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            groupChatViewController.getGroupChatListModel?.value;

        return RefreshIndicator(
          onRefresh: () async {
            groupChatViewController
                .emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});
          },
          child: Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty ?? true)
                ? noGroupChatsFound()
                : ListView.builder(
                    itemCount: data?.chatList?.length,
                    itemBuilder: (context, index) {
                      final chat = data?.chatList?[index];

                      return InkWell(
                        onTap: () async {

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                    isGroupPrivate: chat?.publicGroup??false ,
                                        type: AppConstants.group_Chat_Type,
                                        conversationId: chat?.conversationId,
                                        profileImage: chat?.groupProfileImage
                                            ?.replaceAll('[', '')
                                            .replaceAll(']', ''),
                                        name: chat?.groupName,
                                      )));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
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
                                                  child:
                                                      (chat?.groupProfileImage
                                                                  ?.replaceAll(
                                                                      '[', '')
                                                                  .replaceAll(
                                                                      ']', '')
                                                                  .contains(
                                                                      'http') ??
                                                              false)
                                                          ? CachedNetworkImage(
                                                              imageUrl: chat
                                                                      ?.groupProfileImage
                                                                      ?.replaceAll(
                                                                          '[',
                                                                          '')
                                                                      .replaceAll(
                                                                          ']',
                                                                          '') ??
                                                                  "",
                                                              placeholder: (context,
                                                                      url) =>
                                                                  const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            20),
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  const Icon(
                                                                      Icons
                                                                          .error,
                                                                      size: 40),
                                                              fit: BoxFit
                                                                  .contain,
                                                            )
                                                          : Image.file(
                                                              File(chat
                                                                      ?.groupProfileImage
                                                                      ?.replaceAll(
                                                                          '[',
                                                                          '')
                                                                      .replaceAll(
                                                                          ']',
                                                                          '') ??
                                                                  ''),
                                                              fit: BoxFit
                                                                  .contain,
                                                            ),
                                                ),
                                              ),
                                              // Title Bar
                                              Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16),
                                                        child: SizedBox(
                                                          width: 200,
                                                          child: CustomText(
                                                            "${chat?.groupName}",
                                                            maxLines: 1,
                                                            color: Colors.white,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            // 👈 ensures "..."
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
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
                                // CircleAvatar(
                                //                     backgroundColor: theme.colorScheme.primary,
                                //                     radius: 22,
                                //                     backgroundImage: (chat?.sender?.profileImage != null)
                                //                         ? ((chat?.sender!.profileImage!.contains('http') ??
                                //                                 false)
                                //                             ? NetworkImage(chat?.sender?.profileImage ?? "")
                                //                             : FileImage(File(chat?.sender?.profileImage ?? ''))
                                //                                 as ImageProvider)
                                //                         : null,
                                //                     child: ((chat?.sender?.profileImage != null &&
                                //                             (chat?.sender?.profileImage?.isNotEmpty ?? false)))
                                //                         ? null
                                //                         : Center(
                                //                             child: CustomText(
                                //                             "${chat?.sender?.name?.split('')[0]}",
                                //                             color: Colors.white,
                                //                             fontWeight: FontWeight.w800,
                                //                             fontSize: 18,
                                //                           )),
                                //                   ),
                                child: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  radius: 22,
                                  child: (chat?.groupProfileImage == null ||
                                          chat?.groupProfileImage == "null")
                                      ? Center(
                                          child: CustomText(
                                          "${chat?.groupName?.split('')[0]}",
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ))
                                      : (chat?.groupProfileImage != null &&
                                              chat!.groupProfileImage!
                                                  .isNotEmpty)
                                          ? ClipOval(
                                              child: (chat.groupProfileImage!
                                                      .replaceAll('[', '')
                                                      .replaceAll(']', '')
                                                      .startsWith('http'))
                                                  ? CachedNetworkImage(
                                                      imageUrl: chat
                                                          .groupProfileImage!
                                                          .replaceAll('[', '')
                                                          .replaceAll(']', ''),
                                                      fit: BoxFit.cover,
                                                      width: 44,
                                                      height: 44,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        color: Colors
                                                            .grey.shade300,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Center(
                                                        child: Text(
                                                          chat.groupName?[0]??'',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Image.file(
                                                      File(chat
                                                          .groupProfileImage!
                                                          .replaceAll('[', '')
                                                          .replaceAll(']', '')),
                                                      width: 44,
                                                      height: 44,
                                                      fit: BoxFit.cover,
                                                    ),
                                            )
                                          : Center(
                                              child: Text(
                                                chat?.groupName
                                                        ?.substring(0, 1) ??
                                                    '',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                              SizedBox(
                                width: SizeConfig.size15,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: CustomText(
                                        "${chat?.groupName?.capitalize}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        // 👈 ensures "..."
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      width: 260,
                                      child:
                                          (chat?.lastMessageType ==
                                                      "document" ||
                                                  chat?.lastMessageType ==
                                                      "contact" ||
                                                  chat?.lastMessageType ==
                                                      "audio" ||
                                                  chat?.lastMessageType ==
                                                      "location" ||
                                                  chat?.lastMessageType ==
                                                      "image" ||
                                                  chat?.lastMessageType ==
                                                      "video")
                                              ? Row(
                                                  children: [
                                                    Icon(
                                                      chat?.lastMessageType ==
                                                              "document"
                                                          ? Icons.picture_as_pdf
                                                          : chat?.lastMessageType ==
                                                                  "contact"
                                                              ? Icons.person
                                                              : chat?.lastMessageType ==
                                                                      "audio"
                                                                  ? Icons
                                                                      .audiotrack
                                                                  : chat?.lastMessageType ==
                                                                          "video"
                                                                      ? Icons
                                                                          .video_chat
                                                                      : chat?.lastMessageType ==
                                                                              "location"
                                                                          ? Icons
                                                                              .location_history
                                                                          : Icons
                                                                              .camera_alt,
                                                      color: AppColors.grey9A,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    CustomText(
                                                      chat?.lastMessageType ==
                                                              "document"
                                                          ? AppStrings
                                                              .document.tr
                                                          : chat?.lastMessageType ==
                                                                  "contact"
                                                              ? AppStrings
                                                                  .contact.tr
                                                              : chat?.lastMessageType ==
                                                                      "audio"
                                                                  ? AppStrings
                                                                      .audio.tr
                                                                  : chat?.lastMessageType ==
                                                                          "video"
                                                                      ? AppStrings
                                                                          .video
                                                                          .tr
                                                                      : chat?.lastMessageType ==
                                                                              "location"
                                                                          ? AppStrings
                                                                              .location
                                                                              .tr
                                                                          : AppStrings
                                                                              .image
                                                                              .tr,
                                                      fontSize: 14,
                                                      color: AppColors.grey9A,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  ],
                                                )
                                              : chat?.lastMessage == null
                                                  ? CustomText(
                                                      // "${(chat?.sender?.designation==null)?chat?.sender?.contactNo:chat?.sender?.designation}",
                                                      AppStrings
                                                          .startConversation,
                                                      fontSize: 14,
                                                      color: AppColors.grey9A,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  : CustomText(
                                                      maxLines: 1,
                                                      "${chat?.lastMessage}",
                                                      fontSize: 14,
                                                      color: AppColors.grey9A,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: SizeConfig.size15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CustomText(
                                    "${formatTimeFromUtc(chat?.updatedAt ?? '')}",
                                    fontSize: 11,
                                    color: AppColors.grey9A,
                                  ),
                                  SizedBox(height: 6),


                                  Row(
                                    children: [
                                      if(chat?.tagged == true)
                                           CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.lightBlue,
                                        child: CustomText(
                                          "@",
                                          color: AppColors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if(chat?.tagged == true)
                                        SizedBox(width: 6,),
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
                            ],
                          ),
                        ),
                      );
                    }),
          ),
        );
      } else if (groupChatViewController
              .personalChatListResponse.value.status ==
          Status.INITIAL) {
        return SizedBox();
      } else {
        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppIconAssets.chat,
                  color: Colors.black,
                  height: 70,
                  width: 70,
                ),
                const SizedBox(
                  height: 14,
                ),
                CustomText(
                  AppStrings.noChatsFound,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(
                  height: 6,
                ),
                CustomText(AppStrings.goToContactsStartConversation),
              ],
            ),
          ),
        );
      }
    });
  }
}
