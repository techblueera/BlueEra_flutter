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
            groupChatViewController.emitEvent(
                ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});
          },
          child: Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty ?? true)
                ? noGroupChatsFound()
                : ListView.builder(
                    itemCount: data?.chatList?.length,
                    itemBuilder: (context, index) {
                      final chat = data?.chatList?[index];
                      final profileUrl = _cleanImageUrl(chat?.groupProfileImage);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                        isGroupPrivate:
                                            chat?.publicGroup ?? false,
                                        type: AppConstants.group_Chat_Type,
                                        conversationId: chat?.conversationId,
                                        profileImage: profileUrl,
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
                                onTap: () => _showProfileDialog(context, chat),
                                child: _buildGroupAvatar(
                                    theme, chat, profileUrl),
                              ),
                              SizedBox(width: SizeConfig.size15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: CustomText(
                                        "${chat?.groupName}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      width: 260,
                                      child: _buildLastMessage(chat),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: SizeConfig.size15),
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
                                      if (chat?.tagged == true)
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.lightBlue,
                                          child: CustomText(
                                            "@",
                                            color: AppColors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      if (chat?.tagged == true)
                                        SizedBox(width: 6),
                                      if ((chat?.unreadCount ?? 0) > 0)
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.lightBlue,
                                          child: CustomText(
                                            "${chat?.unreadCount}",
                                            color: AppColors.white,
                                            fontSize: 12,
                                          ),
                                        ),
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
              .groupChatListResponse.value.status ==
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
                const SizedBox(height: 14),
                CustomText(
                  AppStrings.noChatsFound,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 6),
                CustomText(AppStrings.goToContactsStartConversation),
              ],
            ),
          ),
        );
      }
    });
  }

  String? _cleanImageUrl(String? raw) {
    if (raw == null) return null;
    return raw.replaceAll('[', '').replaceAll(']', '');
  }

  Widget _buildGroupAvatar(ThemeData theme, ChatList? chat, String? profileUrl) {
    final name = chat?.groupName;
    final initial = (name != null && name.isNotEmpty) ? name[0] : '';

    return CircleAvatar(
      backgroundColor: theme.colorScheme.primary,
      radius: 22,
      child: (profileUrl == null || profileUrl.isEmpty || profileUrl == "null")
          ? Center(
              child: CustomText(
                initial,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            )
          : ClipOval(
              child: profileUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: profileUrl,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : Image.file(
                      File(profileUrl),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
            ),
    );
  }

  void _showProfileDialog(BuildContext context, ChatList? chat) {
    final profileUrl = _cleanImageUrl(chat?.groupProfileImage);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: (profileUrl != null && profileUrl.contains('http'))
                        ? CachedNetworkImage(
                            imageUrl: profileUrl,
                            placeholder: (context, url) => const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 40),
                            fit: BoxFit.contain,
                          )
                        : (profileUrl != null && profileUrl.isNotEmpty)
                            ? Image.file(
                                File(profileUrl),
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.group, size: 60),
                  ),
                ),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 200,
                          child: CustomText(
                            "${chat?.groupName}",
                            maxLines: 1,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
  }

  Widget _buildLastMessage(ChatList? chat) {
    final mediaTypes = {'document', 'contact', 'audio', 'location', 'image', 'video'};

    if (mediaTypes.contains(chat?.lastMessageType)) {
      return Row(
        children: [
          Icon(_getMediaIcon(chat?.lastMessageType), color: AppColors.grey9A, size: 16),
          const SizedBox(width: 4),
          CustomText(
            _getMediaLabel(chat?.lastMessageType),
            fontSize: 14,
            color: AppColors.grey9A,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (chat?.lastMessage == null) {
      return CustomText(
        AppStrings.startConversation,
        fontSize: 14,
        color: AppColors.grey9A,
        overflow: TextOverflow.ellipsis,
      );
    }

    return CustomText(
      maxLines: 1,
      "${chat?.lastMessage}",
      fontSize: 14,
      color: AppColors.grey9A,
      overflow: TextOverflow.ellipsis,
    );
  }

  IconData _getMediaIcon(String? type) {
    switch (type) {
      case 'document': return Icons.picture_as_pdf;
      case 'contact': return Icons.person;
      case 'audio': return Icons.audiotrack;
      case 'video': return Icons.video_chat;
      case 'location': return Icons.location_history;
      default: return Icons.camera_alt;
    }
  }

  String _getMediaLabel(String? type) {
    switch (type) {
      case 'document': return AppStrings.document.tr;
      case 'contact': return AppStrings.contact.tr;
      case 'audio': return AppStrings.audio.tr;
      case 'video': return AppStrings.video.tr;
      case 'location': return AppStrings.location.tr;
      default: return AppStrings.image.tr;
    }
  }
}
