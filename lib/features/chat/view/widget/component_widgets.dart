import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';

Widget timeAndReadInfoWidget(
    {required Messages message,
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
      CustomText("${time}", color: timeColor ?? AppColors.white, fontSize: 10),
      const SizedBox(
        width: 1.5,
      ),
      isMyMessage
          ? (message.sendStatus=="pending")?Icon(
        Icons.timelapse_outlined,
        color: Colors.grey,
        size: 16,
      ):Obx(() {

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
              : (message.status == 'sent' || message.status == null)
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

Widget ChatListTile(
    {required Function onSelect,
      required String type,
      required BuildContext context,
      required bool? isForwardUI,
      required bool? isFromGroupSelect,
      required int index,
      required ChatViewController chatViewController,
      GroupChatViewController? groupChatViewController,
      required ChatList? chat,
      required ThemeData theme}) {
  final userId = chat?.sender?.id ?? '';
  final isSelected =
  chatViewController.selectedUserIds.contains(chat?.sender?.id ?? '');

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
  return InkWell(
    onTap: () {
      if (isForwardUI == true) {
        selectChatListCard();
      } else {

        chatViewController.openAnyOneChatFunction(
          businessId: chat?.sender?.businessId,
          type:type,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: (chat?.sender?.profileImage?.isNotEmpty == true &&
                            chat?.sender?.profileImage?.contains('http') == true)
                            ? CachedNetworkImage(
                          imageUrl: chat?.sender?.profileImage ?? "",
                          placeholder: (context, url) => const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 40),
                          fit: BoxFit.contain,
                        )
                            : (chat?.sender?.profileImage?.isNotEmpty == true)
                            ? Image.file(
                          File(chat!.sender!.profileImage!),
                          fit: BoxFit.contain,
                        )
                            : CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade400,
                          child: Text(
                            (chat?.sender?.name?.isNotEmpty == true)
                                ? chat!.sender!.name![0].toUpperCase()
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
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                    padding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(
                                      width: 160,
                                      child: CustomText(
                                        "${(chat?.sender?.name == "null") ? chat?.sender?.contactNo : chat?.sender?.name ?? chat?.sender?.contactNo}",
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
              backgroundImage: (chat?.sender?.profileImage != null)
                  ? ((chat?.sender!.profileImage!.contains('http') ?? false)
                  ? NetworkImage(chat?.sender?.profileImage ?? "")
                  : FileImage(File(chat?.sender?.profileImage ?? ''))
              as ImageProvider)
                  : null,
              child: ((chat?.sender?.profileImage != null&&(chat?.sender?.profileImage?.isNotEmpty??false)))
                  ? null
                  : Center(
                  child: CustomText(
                    "${chat?.sender?.name?.split('')[0]}",
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  )),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "${(chat?.sender?.name == "null") ? chat?.sender?.contactNo : chat?.sender?.name ?? chat?.sender?.contactNo}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // 👈 ensures "..."
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 2),
                SizedBox(
                  width: 260,
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
                            : chat?.lastMessageType == "video"
                            ? Icons.video_chat
                            : chat?.lastMessageType ==
                            "location"
                            ? Icons.location_history
                            : Icons.camera_alt,
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
                            : chat?.lastMessageType ==
                            "location"
                            ? "Location"
                            : "Image",
                        fontSize: 14,
                        color: AppColors.grey9A,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  )
                      : chat?.lastMessage ==null ?CustomText(
                    "${chat?.sender!.designation}",
                    fontSize: 14,
                    color: AppColors.grey9A,
                    overflow: TextOverflow.ellipsis,
                  ):CustomText(
                    "${chat?.lastMessage}",
                    fontSize: 14,
                    color: AppColors.grey9A,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          (isForwardUI == true)
              ? SizedBox()
              : Column(
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
          if (isForwardUI == true)
            Theme(
              data: theme.copyWith(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                        color: Colors.black), // Border color when unchecked
                  ),
                  side: BorderSide(
                      color: Colors.black), // Ensure it's applied globally
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
  DateTime dateToCompare = DateTime(localDate.year, localDate.month, localDate.day);

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
    size: 16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "video")
      ? Icon(
    Icons.video_camera_back_outlined,
    size: 16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "location")
      ? Icon(
    Icons.location_on_outlined,
    size: 16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "document")
      ? Icon(
    Icons.picture_as_pdf_outlined,
    size: 16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "contact")
      ? Icon(
    Icons.person_2_outlined,
    size: 16,
    color: Colors.white,
  )
      : (message.replyParentMessage?.messageType == "audio")
      ? Icon(
    Icons.audio_file_outlined,
    size: 16,
    color: Colors.white,
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: !(message.myMessage ?? false)
        ? Colors.black87
        : Colors.white,
    fontSize: 13,
  );
}

Widget messageTypeIcons(Messages message) {
  return (message.messageType == "image")
      ? Icon(
    Icons.camera_enhance_outlined,
    size: 16,
    color: Colors.black,
  )
      : (message.messageType == "video")
      ? Icon(
    Icons.video_camera_back_outlined,
    size: 16,
    color: Colors.black,
  )
      : (message.messageType == "location")
      ? Icon(
    Icons.location_on_outlined,
    size: 16,
    color: Colors.black,
  )
      : (message.messageType == "document")
      ? Icon(
    Icons.picture_as_pdf_outlined,
    size: 16,
    color: Colors.black,
  )
      : (message.messageType == "contact")
      ? Icon(
    Icons.person_2_outlined,
    size: 16,
    color: Colors.black,
  )
      :
  (message.messageType == "audio")
      ? Icon(
    Icons.audio_file_outlined,
    size: 16,
    color: Colors.black,
  )
      :
  CustomText(
    "${message.message}",
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontSize: 13,
  );
}

Widget replyMessageTypeIconWithLabel(Messages message) {
  return (message.replyParentMessage?.messageType == "image")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Image",
        fontWeight: FontWeight.w500,
        color:
        !(message.myMessage ?? false) ? Colors.black87 : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "video")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Video",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "location")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Location",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "document")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Document",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "contact")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Contact",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : (message.replyParentMessage?.messageType == "audio")
      ? Row(
    children: [
      replyMessageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Audio",
        fontWeight: FontWeight.w500,
        color: !(message.myMessage ?? false)
            ? Colors.black87
            : Colors.white,
        fontSize: 13,
      ),
    ],
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: !(message.myMessage ?? false)
        ? Colors.black87
        : Colors.white,
    fontSize: 13,
  );
}

Widget messageTypeIconWithLabel(Messages message) {
  return (message.messageType == "image")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Image",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : (message.messageType == "video")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Video",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : (message.messageType == "location")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Location",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : (message.messageType == "document")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Document",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : (message.messageType == "contact")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Contact",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : (message.messageType == "audio")
      ? Row(
    children: [
      messageTypeIcons(message),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        "Audio",
        fontWeight: FontWeight.w500,
        color: Colors.black,
        fontSize: 13,
      ),
    ],
  )
      : CustomText(
    "${message.message}",
    fontWeight: FontWeight.w500,
    color: Colors.black,
    fontSize: 13,
  );
}
