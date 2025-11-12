import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/contacts/view/contact_list_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../../common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../chat_screen.dart';
import '../group_chat/view_group_members.dart';

Widget timeAndReadInfoWidget({required Messages message,
  required bool isMyMessage,
  required String time,
  Color? indicateColor,
  Color? timeColor}) {
  final chatViewController = Get.find<ChatViewController>();
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomText("${time}", color: timeColor ?? AppColors.black, fontSize: 10),
      const SizedBox(
        width: 1.5,
      ),
      isMyMessage
          ? (message.sendStatus == "pending")
          ? Icon(
        Icons.timelapse_outlined,
        color: Colors.grey,
        size: 16,
      )
          : Obx(() {
        return Container(
          child: (message.sendStatus == "pending")
              ? Icon(
            Icons.timelapse_outlined,
            color: Colors.grey,
            size: 16,
          )
              : (chatViewController.readMessageStatus.value == 'read')
              ? SvgPicture.asset(
            AppIconAssets.chat_double_tick,
            color: Colors.blue,
          )
              : (message.status == 'sent' ||
              message.status == null)
              ? Icon(
            Icons.check,
            color: indicateColor ?? AppColors.white,
            size: 16,
          )
              : SvgPicture.asset(
            AppIconAssets.chat_double_tick,
            color: ((message.status == 'delivered'))
                ? Colors.grey
                : Colors.blue,
          ),
        );
      })
          : SizedBox()
    ],
  );
}

Widget noChatsFound() {
  return Center(
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
          "No Chats Found",
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(
          height: 6,
        ),
        CustomText("Go to contacts and start new conversation"),
        const SizedBox(
          height: 6,
        ),
        InkWell(
            onTap: () {
              Get.toNamed(RouteHelper.getChatContactsRoute());
            },
            child: CustomText(
              "Click Here to Start Conversation",
              color: Colors.blue,
            )),
      ],
    ),
  );
}

Widget noGroupChatsFound() {
  return Center(
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
          "No Group Chats Found",
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(
          height: 6,
        ),
        CustomText("Go to contacts and create new group"),
        const SizedBox(
          height: 6,
        ),
        InkWell(
            onTap: () {
              Get.to(ContactsPage(from: "group",));
            },
            child: CustomText(
              "Create your first group",
              color: AppColors.primaryColor,
            )),
      ],
    ),
  );
}

Widget ChatListTile({required Function onSelect,
  required String type,
  required BuildContext context,
  required bool? isForwardUI,
   bool? isFromGroupSelect,
   Function()? onTab,
  required int index,
  required ChatViewController chatViewController,
  required ChatList? chat,
  required ThemeData theme}) {
  final userId = chat?.sender?.id ?? '';
  bool isSelected =false;
  if(chatViewController.selectedUserIds.isNotEmpty){
    isSelected= chatViewController.selectedUserIds.contains(chat?.sender?.id ?? '');
  }

  void selectChatListCard() {
    if (isSelected) {
      chatViewController.selectedUserIds.remove(chat?.sender?.id ?? '');
      chatViewController.selectedChatList.remove(chat);
    } else {
      chatViewController.selectedUserIds.add(chat?.sender?.id ?? '');
      chatViewController.selectedChatList.add(chat);
    }
    onSelect();
  }
  return ((chat?.sender?.name == null || chat?.sender?.name == "null") &
  (chat?.sender?.contactNo == null))
      ? SizedBox()
      : InkWell(
    onTap:onTab?? () {
      if (isForwardUI == true) {
        selectChatListCard();
      } else {

        chatViewController.openAnyOneChatFunction(
          businessId: chat?.sender?.businessId,
          type: type,
          isInitialMessage: false,
          userId: userId,
          conversationId: chat?.conversationId ?? '',
          profileImage: chat?.sender?.profileImage,
          contactName: chat?.sender?.name,
          contactNo: chat?.sender?.contactNo,
        );
      }
    },
    child: Padding(
      padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
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
                              child: (chat?.sender?.profileImage
                                  ?.isNotEmpty ==
                                  true &&
                                  chat?.sender?.profileImage
                                      ?.contains('http') ==
                                      true)
                                  ? CachedNetworkImage(
                                imageUrl:
                                chat?.sender?.profileImage ??
                                    "",
                                placeholder: (context, url) =>
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child:
                                  CircularProgressIndicator(),
                                ),
                                errorWidget:
                                    (context, url, error) =>
                                const Icon(Icons.error,
                                    size: 40),
                                fit: BoxFit.contain,
                              )
                                  : (chat?.sender?.profileImage
                                  ?.isNotEmpty ==
                                  true)
                                  ? Image.file(
                                File(chat!
                                    .sender!.profileImage!),
                                fit: BoxFit.contain,
                              )
                                  : CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                Colors.grey.shade400,
                                child: Text(
                                  (chat?.sender?.name
                                      ?.isNotEmpty ==
                                      true)
                                      ? chat!.sender!.name![0]
                                      .toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Title Bar
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: SizedBox(
                                      width: 160,
                                      child: CustomText(
                                        "${(chat?.sender?.name == "null") ? chat
                                            ?.sender?.contactNo : chat?.sender
                                            ?.name ?? chat?.sender?.contactNo}",
                                        maxLines: 1,
                                        color: Colors.white,
                                        overflow: TextOverflow.ellipsis,
                                        // 👈 ensures "..."
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
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
              radius: SizeConfig.size22,
              child:  (chat?.sender?.profileImage == null||chat?.sender?.profileImage == "null")? Center(
                  child: CustomText(
                    "${chat?.groupName?.split('')[0]}",
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: SizeConfig.size18,
                  )):(chat?.sender?.profileImage != null &&
                  chat!.sender!.profileImage!.isNotEmpty)
                  ? ClipOval(
                child: (chat.sender!.profileImage!.startsWith('http'))
                    ? CachedNetworkImage(
                  imageUrl: chat.sender!.profileImage!,
                  fit: BoxFit.cover,
                  width: SizeConfig.size44,
                  height: SizeConfig.size44,
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
                      chat.sender!.name!.substring(0, 1),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: SizeConfig.size18,
                      ),
                    ),
                  ),
                )
                    : Image.file(
                  File(chat.sender!.profileImage!),
                  width: SizeConfig.size44,
                  height: SizeConfig.size44,
                  fit: BoxFit.cover,
                ),
              )
                  : Center(
                child: Text(
                  chat?.sender?.name?.substring(0, 1) ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: SizeConfig.size18,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "${(chat?.sender?.name == null ||
                      chat?.sender?.name == "null") ? "${chat?.sender
                      ?.contactNo}" : chat?.sender?.name ??
                      chat?.sender?.contactNo}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // 👈 ensures "..."
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height:  SizeConfig.size2),
                SizedBox(
                  width:  SizeConfig.size260,
                  child: (chat?.lastMessageType == "document" ||
                      chat?.lastMessageType == "contact" ||
                      chat?.lastMessageType == "audio" ||
                      chat?.lastMessageType == "location" ||
                      chat?.lastMessageType == "image" ||
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
                            : chat?.lastMessageType ==
                            "video"
                            ? Icons.video_chat
                            : chat?.lastMessageType ==
                            "location"
                            ? Icons.location_history
                            : Icons.camera_alt,
                        color: AppColors.grey9A,
                        size: SizeConfig.size16,
                      ),
                       SizedBox(width:  SizeConfig.size4),
                      CustomText(
                        chat?.lastMessageType == "document"
                            ? "Document"
                            : chat?.lastMessageType == "contact"
                            ? "Contact"
                            : chat?.lastMessageType == "audio"
                            ? "Audio"
                            : chat?.lastMessageType ==
                            "video"
                            ? "Video"
                            : chat?.lastMessageType ==
                            "location"
                            ? "Location"
                            : "Image",
                        fontSize: SizeConfig.size14,
                        color: AppColors.grey9A,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  )
                      : chat?.lastMessage == null
                      ? CustomText(
                    "${(chat?.sender?.designation == null) ? chat?.sender
                        ?.contactNo : chat?.sender?.designation}",
                    fontSize:  SizeConfig.size14,
                    color: AppColors.grey9A,
                    overflow: TextOverflow.ellipsis,
                  )
                      : CustomText(
                    maxLines: 1,
                    "${chat?.lastMessage}",
                    fontSize: SizeConfig.size14,
                    color: AppColors.grey9A,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          (isForwardUI == true)
              ? SizedBox()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                "${formatTimeFromUtc(chat?.updatedAt ?? '')}",
                fontSize: SizeConfig.size11,
                color: AppColors.grey9A,
              ),
              SizedBox(height: SizeConfig.size6),
              (index == 0 || index == 1 || index == 2)
                  ? (chat?.unreadCount == 0)
                  ? SizedBox()
                  : CircleAvatar(
                radius:  SizeConfig.size12,
                backgroundColor: Colors.lightBlue,
                child: CustomText(
                  "${chat?.unreadCount}",
                  color: AppColors.white,
                  fontSize:  SizeConfig.size12,
                ),
              )
                  : SizedBox(),
            ],
          ),
          if (isForwardUI == true)
            Theme(
              data: theme.copyWith(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                        color:
                        Colors.black), // Border color when unchecked
                  ),
                  side: BorderSide(
                      color:
                      Colors.black), // Ensure it's applied globally
                ),
              ),
              child: Checkbox(
                activeColor: Colors.blue, // fill color when selected
                checkColor: Colors.white, // tick color
                value: isSelected,
                onChanged: (_) {
                  selectChatListCard();
                },
              ),
            ),
        ],
      ),
    ),
  );
}

String formatTimeFromUtc(String utcString) {
  if (utcString.isEmpty) return '';

  DateTime utcDate = DateTime.parse(utcString);
  DateTime localDate = utcDate.toLocal();

  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(Duration(days: 1));
  DateTime dateToCompare =
  DateTime(localDate.year, localDate.month, localDate.day);

  if (dateToCompare == today) {
    // Today: return time
    return DateFormat.jm().format(localDate);
  } else if (dateToCompare == yesterday) {
    // Yesterday
    return 'Yesterday';
  } else {
    // Older date: return formatted date
    return DateFormat('dd/MM/yy').format(localDate);
  }
}

String formatChatTime(String isoDateString) {
  try {
    final dateTime = DateTime.parse(isoDateString).toLocal();
    return DateFormat.jm().format(dateTime); // e.g. 9:52 PM
  } catch (e) {
    return ''; // fallback in case of invalid date
  }
}

Widget replyMessageTypeIcons(Messages message) {
  return (message.replyParentMessage?.messageType == "image")
      ? Icon(
    Icons.camera_enhance_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "video")
      ? Icon(
    Icons.video_camera_back_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "location")
      ? Icon(
    Icons.location_on_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "document")
      ? Icon(
    Icons.picture_as_pdf_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "contact")
      ? Icon(
    Icons.person_2_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "audio")
      ? Icon(
    Icons.audio_file_outlined,
    size: SizeConfig.size16,
    color: Colors.white,
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: !(message.myMessage ?? false)
        ? Colors.black87
        : Colors.white,
    fontSize: SizeConfig.size13,
  );
}

Widget messageTypeIcons(Messages message) {
  return (message.messageType == "image")
      ? Icon(
    Icons.camera_enhance_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : (message.messageType == "video")
      ? Icon(
    Icons.video_camera_back_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : (message.messageType == "location")
      ? Icon(
    Icons.location_on_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : (message.messageType == "document")
      ? Icon(
    Icons.picture_as_pdf_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : (message.messageType == "contact")
      ? Icon(
    Icons.person_2_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : (message.messageType == "audio")
      ? Icon(
    Icons.audio_file_outlined,
    size: SizeConfig.size16,
    color: Colors.black,
  )
      : CustomText(
    "${message.message}",
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontSize: SizeConfig.size13,
  );
}

Widget replyMessageTypeIconWithLabel(Messages message) {
  return (message.replyParentMessage?.messageType == "image")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Image",
        fontWeight: FontWeight.w500,
        color:
        !(message.myMessage ?? false) ? Colors.black87 : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "video")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Video",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "location")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Location",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "document")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Document",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "contact")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Contact",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "audio")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Audio",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: !(message.myMessage ?? false)
        ? Colors.black87
        : Colors.white,
    fontSize: SizeConfig.size13,
  );
}

Widget messageTypeIconWithLabel(Messages message) {
  return (message.messageType == "image")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Image",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.messageType == "video")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Video",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.messageType == "location")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Location",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.messageType == "document")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Document",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.messageType == "contact")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Contact",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : (message.messageType == "audio")
      ? Row(
    children: [
      messageTypeIcons(message),
       SizedBox(
        width: SizeConfig.size4,
      ),
      CustomText(
        "Audio",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : CustomText(
    "${message.message}",
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontSize: SizeConfig.size13,
  );
}

void _navigateToProfile({required String authorId, required String type}) {
  if (type.toUpperCase() == AppConstants.business) {
    Get.to(() =>
        VisitBusinessProfileNew(
          businessId: authorId,
          screenName: AppConstants.chatScreen,
        ));
  } else if (type.toUpperCase() == AppConstants.individual) {
    Get.to(() =>
        NewVisitProfileScreen(
          authorId: authorId,
          screenFromName: AppConstants.chatScreen,
        ));
  }
}

AppBar getChatTitleAppBar(BuildContext context, {
  required String? userId,
  required String? conversationId,
  required String? type,
  required String? socketType,
  required String? name,
  required String? contactNo,
  String? profileImage,
  String? businessId,
  bool? isGroupAppBar,
}) {
  final theme = Theme.of(context);
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();

  return AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    leadingWidth: 38,
    leading: InkWell(
      onTap: () {
        if(chatViewController.canPopBusiness.value){
          chatViewController.emitEvent(
              "ChatList", {ApiKeys.type: "$socketType"}, true);
          bottomBarController.onChangeIndex(4);
          Navigator.popUntil(context, ModalRoute.withName(RouteHelper.getBottomNavigationBarScreenRoute()));
          chatViewController.onSelectChatTab(1);
        }else{
          Get.back();
          chatViewController.emitEvent(
              "ChatList", {ApiKeys.type: "$socketType"}, true);
        }
      },
      child: Padding(
        padding:  EdgeInsets.only(left: SizeConfig.size18),
        // Reduce touch padding if needed
        child: Icon(Icons.arrow_back_ios, color: Colors.black),
      ),
    ),
    titleSpacing: 0,
    title: InkWell(
      onTap: (type != "Admin")
          ? () {
        if(isGroupAppBar!=null){
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) => ViewGroupMembers(
                conversationId: conversationId,
                type: type,
                name: name,
                profileImage: profileImage,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
            ),
          );

        }else{

          _navigateToProfile(authorId: userId ?? '', type: type ?? "");

        }
      }
          : () {},
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: SizeConfig.size18,
            backgroundImage: profileImage != null
                ? ((profileImage.contains('http'))
                ? NetworkImage(profileImage)
                : FileImage(File(profileImage)) as ImageProvider)
                : null,
            child:(profileImage=='null')? CustomText(
               "${name!.split('')[0]}",
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: SizeConfig.size18,
            ): (profileImage != null)
                ? null
                : (name != null)
                ? Center(
                child: CustomText(
                  name.isNotEmpty ? "${name.split('')[0]}" : "U",
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: SizeConfig.size18,
                ))
                : Center(
              child: Icon(
                Icons.person,
                color: theme.colorScheme.surface,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size6), // Slightly smaller spacing
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: SizeConfig.size160,
                child: CustomText(
                  '${(name == "null") ? (contactNo) : name ?? contactNo}',
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.size16,
                ),
              ),
              if(isGroupAppBar == null)
                Row(
                  children: [
                    CustomText(
                      '${(type != "Admin") ? (type=="business")?chatViewController
                          .userOnlineStatus.value=="Online"?"Shop Open":"Shop Closed":chatViewController
                          .userOnlineStatus.value : "BlueCs Limited"}',
                      color: AppColors.grayText,

                      fontSize: SizeConfig.size12,
                    ),
                     SizedBox(
                      width: SizeConfig.size3,
                    ),
                    (type != "Admin")
                        ? SizedBox()
                        : Icon(
                      Icons.verified,
                      color: Colors.blue,
                      size: SizeConfig.size14,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
    actions: (type == "Admin")
        ? null
        : [
       SizedBox(width: SizeConfig.size8),
      if(isGroupAppBar == null)
        InkWell(
            onTap: () {
              // Map<String,dynamic> data={
              //   if(conversationId!=null)
              //     "conversation_id": "${conversationId}",
              //   if(conversationId==null)
              //     "other_user_id": "${userId}",
              //   "call_type": "audio_call"
              // };
              // callController.callToUser(data);
              // Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (context) => AudioCallScreen(
              //               isCaller: true,
              //               conversationId: conversationId,
              //               userId: userId,
              //               callerName: name ?? '',
              //           conversation_id: conversationId??'',
              //           receiverImage: '',
              //           receiverUserName: name ?? '',
              //             )));
              launchDialPad(contactNo ?? '');
            },
            child: SvgPicture.asset(AppIconAssets.chat_call)),
       SizedBox(width: SizeConfig.size12),
      // SvgPicture.asset(AppIconAssets.chat_video_call),
      // const SizedBox(width: 12),

      if(isGroupAppBar != null)
        PopupMenuButton<String>(
            icon: SvgPicture.asset(AppIconAssets.chat_info_pop),
            onSelected: (value) {
              if (value == "group_info") {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondaryAnimation) => ViewGroupMembers(
                      conversationId: conversationId,
                      type: type,
                      name: name,
                      profileImage: profileImage,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0)
                            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                  ),
                );

              }
            },
            itemBuilder: (context) =>
            [
              // PopupMenuItem(
              //   value: "group_members",
              //   child: Text("Group Members"),
              // ),
              PopupMenuItem(
                onTap: () {

                },
                value: "group_info",
                child: Text("Group Info"),
              ),
            ])
      else
        SvgPicture.asset(AppIconAssets.chat_info_pop),
       SizedBox(width: SizeConfig.size8),

    ],
  );
}

PreferredSize getChatOptionsAppBar(BuildContext context, {
  required String? userId,
  required String? conversationId,
  required String? type,
  required String? name,
  required String? contactNo,
  required TextEditingController editingController,
  String? profileImage,
}) {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  return PreferredSize(
    preferredSize: Size.fromHeight(kToolbarHeight),
    child: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: SizeConfig.size38,
      leading: InkWell(
        onTap: () {
          chatThemeController.resetSelection();
        },
        child: Padding(
          padding:  EdgeInsets.only(left: SizeConfig.size18),
          child: Icon(Icons.arrow_back_ios,
              color: AppColors.chat_input_icon_color),
        ),
      ),
      titleSpacing: 8,
      title: CustomText(
        "${chatThemeController.selectedId.length}",
        // or make dynamic
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: SizeConfig.size16,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline,
              color: AppColors.chat_input_icon_color),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) =>
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: CustomText("Are you sure you want to delete?",
                        color: Colors.black),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            Map<String, dynamic> data = {
                              ApiKeys.conversation_id: "${conversationId}",
                              ApiKeys.delete_from_every_one: false,
                              ApiKeys.message_id_list:
                              chatThemeController.selectedId
                            };
                            await chatViewController.deleteChatMessage(
                                data, userId ?? '');
                            chatThemeController.resetSelection();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding:  EdgeInsets.all(SizeConfig.size12),
                            margin:  EdgeInsets.only(bottom: SizeConfig.size10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(SizeConfig.size10),
                            ),
                            child: Center(
                              child: CustomText(
                                "Delete for me",
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        (chatThemeController.isDeleteForEveryOneAvailable.value)
                            ? GestureDetector(
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            Map<String, dynamic> data = {
                              ApiKeys.conversation_id: "${conversationId}",
                              ApiKeys.delete_from_every_one: true,
                              ApiKeys.message_id_list:
                              chatThemeController.selectedId
                            };
                            await chatViewController.deleteChatMessage(
                                data, userId ?? '');
                            chatThemeController.resetSelection();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding:  EdgeInsets.all(SizeConfig.size12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(SizeConfig.size10),
                            ),
                            child: Center(
                              child: CustomText(
                                "Delete for everyone",
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                            : SizedBox(),
                      ],
                    ),
                  ),
            );
          },
        ),
        (chatThemeController.selectedId.length == 1 &&
            chatThemeController.selectedFirstMessage?.value?.messageType ==
                "text")
            ? IconButton(
          icon: Icon(
            Icons.edit,
            color: AppColors.chat_input_icon_color,
            size: SizeConfig.size22,
          ),
          onPressed: () {
            editingController.text = chatThemeController
                .selectedFirstMessage?.value?.message ??
                '';
            showMessageEditDialog(
              userId ?? "",
              conversationId ?? "",
              editingController,
              chatThemeController,
              chatViewController,
            );
          },
        )
            : SizedBox(),
        // IconButton(
        //   icon:  Icon(Icons.push_pin_outlined,color: AppColors.chat_input_icon_color,size: 22,),
        //   onPressed: _showPinDialog,
        // ),
        Padding(
          padding:  EdgeInsets.only(left: SizeConfig.size6),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ChatMainScreen(
                            isForwardUI: true,
                            message:
                            chatThemeController.selectedFirstMessage?.value,
                            forwardId: chatThemeController
                                .selectedFirstMessage?.value?.id ??
                                '',
                          )));
            },
            child: SvgPicture.asset(
              AppIconAssets.chat_media_forward,
              height: SizeConfig.size24,
              width: SizeConfig.size24,
            ),
          ),
        ),

        /// 🔽 Three Dots Menu (Edit option)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.chat_input_icon_color),
          offset: const Offset(20, 60), // 👈 shift menu 40 pixels downward
          onSelected: (value) {
            if (value == 'edit') {
              print("Edit selected");
              // Handle your edit logic
            }
          },
          itemBuilder: (context) => [],
        ),

         SizedBox(width: SizeConfig.size8),
      ],
    ),
  );
}

void launchDialPad(String phoneNumber) async {
  final Uri url = Uri(scheme: 'tel', path: phoneNumber);

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch dialer';
  }
}

void showMessageEditDialog(String userId,
    String conversationId,
    TextEditingController editingController,
    ChatThemeController chatThemeController,
    ChatViewController chatViewController) {
  Get.dialog(
    AlertDialog(
      insetPadding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      // Reduced outer spacing
      contentPadding:  EdgeInsets.only(bottom: SizeConfig.size10),
      backgroundColor: AppColors.appBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
           SizedBox(height: SizeConfig.size10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Message',
                  color: AppColors.black,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
           SizedBox(height: SizeConfig.size4),
          Divider(color: AppColors.greyB4),
           SizedBox(height: SizeConfig.size6),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size14),
            child: TextFormField(
              controller: editingController,
              maxLines: 6,
              minLines: 6,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding:
                 EdgeInsets.symmetric(horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style:  TextStyle(
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
           SizedBox(height: SizeConfig.size24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: CustomText(
                    'Close',
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size14,
                  ),
                ),
                 SizedBox(width: SizeConfig.size16),
                InkWell(
                  onTap: () async {
                    ApiKeys;
                    Map<String, dynamic> data = {
                      ApiKeys.id:
                      "${chatThemeController.selectedFirstMessage?.value?.id}",
                      ApiKeys.type: "message",
                      ApiKeys.message: "${editingController.text}"
                    };
                    bool value =
                    await chatViewController.updateMessageApi(data);
                    if (value) {
                      chatViewController.emitEvent("messageReceived", {
                        ApiKeys.conversation_id: conversationId,
                        ApiKeys.page: 1,
                        ApiKeys.is_online_user: userId,
                        ApiKeys.per_page_message: 30,
                      });
                      chatThemeController.resetSelection();
                      Get.back();
                    }
                  },
                  child: CustomText(
                    'Edit',
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.size14,
                  ),
                ),
                 SizedBox(width: SizeConfig.size2),
              ],
            ),
          ),
           SizedBox(height: SizeConfig.size6),
        ],
      ),
    ),
    useSafeArea: true,
  );
}
