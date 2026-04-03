import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../auth/controller/call_controller.dart';
import '../../auth/service/call_activity_service.dart';
import '../../auth/controller/chat_flag_controller.dart';
import 'chat_flag_bottom_sheet.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../chat_theme/chat_background_screen.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/order_controllar.dart';
import '../../auth/model/GetChatListModel.dart';
import '../chat_screen_new.dart';
import '../contacts/view/contact_list_page.dart';
import '../group_chat/view_group_members.dart';
import '../group_chat/widgets/delete_chat_history_dialog.dart';
import '../group_chat/widgets/pin_message_dialoge_widget.dart';
import '../symbol_view/symbol_view_images.dart';
import 'common_ai_chat_topics.dart';
import 'chat_shortcut_service.dart';
import 'common_delete_message.dart';
import '../media_view_page/conversation_media_page.dart';

Widget timeAndReadInfoWidget({required Messages message,
  required bool isMyMessage,
  required String time,
  Color? indicateColor,
  Color? timeColor}) {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeCtrl = Get.find<ChatThemeController>();
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomText("${time}", color: timeColor ?? chatThemeCtrl.chatTimeColor.value, fontSize: 10),
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

Widget noChatsFound([bool? reminderMsg]) {
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
          reminderMsg==null?"No Chats Found":"No Reminder Messages Found",
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(
          height: 6,
        ),
        if(reminderMsg==null)
        CustomText("Go to contacts and start new conversation"),
        const SizedBox(
          height: 6,
        ),
        if(reminderMsg==null)

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

Widget _buildChatListName({
  String? senderName,
  String? senderContactNo,
  required String conversationId,
}) {
  final flagCtrl = Get.isRegistered<ChatFlagController>()
      ? Get.find<ChatFlagController>()
      : null;
  if (flagCtrl == null) {
    return CustomText(
      "${(senderName == null || senderName == "null") ? senderContactNo : senderName}",
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      fontSize: SizeConfig.size16,
      fontWeight: FontWeight.bold,
    );
  }
  return Obx(() {
    final flag = flagCtrl.getFlagForConversation(conversationId);
    return Row(
      children: [
        Flexible(
          child: CustomText(
            "${(senderName == null || senderName == "null") ? senderContactNo : senderName}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontSize: SizeConfig.size16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (flag != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: flag.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(flag.emoji, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );
  });
}

Widget  ChatListTile({
  required Function onSelect,
  required String type,
  required BuildContext context,
  required bool? isForwardUI,
  bool? isFromGroupSelect,
  Function()? onTab,
  Function()? onLongPress,
  bool isChatListSelected = false,
  bool isPinned = false,
  required int index,
  required ChatViewController chatViewController,
  required ChatList? chat,
  required ThemeData theme,
}) {
  final sender = chat?.sender;
  final senderName = chat?.lastMessage == "Order Message"
      ? chat?.groupName
      : sender?.name;
  final senderId = sender?.id ?? '';
  final senderContactNo = sender?.contactNo;
  final senderProfileImage = chat?.lastMessage == "Order Message" ? chat
      ?.groupProfileImage : sender?.profileImage;
  final senderDesignation = sender?.designation;
  // final senderBusinessId = sender?.businessId;

  final groupName = chat?.groupName;
  final conversationId = chat?.conversationId ?? '';
  final lastMessageType = chat?.lastMessageType;
  final lastMessage = chat?.lastMessage;
  final unreadCount = chat?.unreadCount ?? 0;
  final updatedAt = chat?.updatedAt ?? '';

  bool isSelected = false;

  if (chatViewController.selectedUserIds.isNotEmpty) {
    isSelected = chatViewController.selectedUserIds.contains(senderId);
  }
  void selectChatListCard() {
    if (isSelected) {
      chatViewController.selectedUserIds.remove(senderId);
      chatViewController.selectedChatList.remove(chat);
      onSelect();
    } else {
      if (chatViewController.selectedUserIds.length < 5) {
        chatViewController.selectedUserIds.add(senderId);
        chatViewController.selectedChatList.add(chat);
        onSelect();
      } else {
      commonSnackBar(message: "Only Five Members Can Choose");
      }
    }
  }

  return ((senderName == null || senderName == "null") & (senderContactNo ==
      null))
      ? const SizedBox()
      : InkWell(
    onLongPress: onLongPress,
    onTap: onTab ??
            () {
          if (chatViewController.isChatListSelectionMode.value) {
            chatViewController.toggleChatListSelection(chat);
            onSelect();
            return;
          }
          if (isForwardUI == true) {
            selectChatListCard();
          } else {
            chatViewController.openChatFromChatList(
              userId: senderId,
              conversationId: conversationId,
              type: type,
              contactName: senderName,
              contactNo: senderContactNo,
              profileImage: senderProfileImage,
            );
          }
        },
    child: Container(
      color: isChatListSelected
          ? AppColors.primaryColor.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: EdgeInsets.only(
        right: SizeConfig.size16,
        left: (chat?.symbolData?.isNotEmpty??false)?13.5:SizeConfig.size16,
        top: SizeConfig.size12,
        bottom: SizeConfig.size12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if(chat?.symbolData?.isNotEmpty??false){
                Get.to(SymbolViewImages(data: chat?.symbolData??[],userId: chat?.sender?.id, name: senderName, profileImage: senderProfileImage,));
                //
              }else{
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
                                child: (senderProfileImage?.isNotEmpty == true &&
                                    senderProfileImage?.contains('http') == true)
                                    ? CachedNetworkImage(
                                  imageUrl: senderProfileImage ?? "",
                                  placeholder: (context, url) =>
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, size: 40),
                                  fit: BoxFit.contain,
                                )
                                    : (senderProfileImage?.isNotEmpty == true)
                                    ? Image.file(
                                  File(senderProfileImage!),
                                  fit: BoxFit.contain,
                                )
                                    : CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                  Colors.grey.shade400,
                                  child: Text(
                                    (senderName?.isNotEmpty == true)
                                        ? senderName![0].toUpperCase()
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: SizedBox(
                                      width: 160,
                                      child: CustomText(
                                        "${(senderName == "null")
                                            ? senderContactNo
                                            : senderName ?? senderContactNo}",
                                        maxLines: 1,
                                        color: Colors.white,
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.close, color: Colors.white),
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

            },
            child: Container(
              padding: (chat?.symbolData?.isNotEmpty??false)?EdgeInsets.all(2):null, // border thickness
              decoration: (chat?.symbolData?.isNotEmpty??false)?BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: 0.0,
                  endAngle: 6.28319, // 2 * pi
                  colors: const [
                    AppColors.symbolBorderRed,
                    AppColors.symbolBorderBlue,     // 1st color
                    // 1st color
                    AppColors.symbolBorderYellow,
                    AppColors.symbolBorderGreen,

                    AppColors.symbolBorderRed,// 1st color
                        // 1st color

                    // 1st color
                  ],
                  stops: const [
                    0.0,
                    0.25,
                    0.50,
                    0.75,
                    1.0,
                  ],
                ),
              ):null,
              child: Container(

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppColors.white,
                ),
                child: Padding(
                  padding:  EdgeInsets.all((chat?.symbolData?.isNotEmpty??false)?2.0:0),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: (chat?.symbolData?.isNotEmpty??false)?SizeConfig.size20:SizeConfig.size22,
                    child: (senderProfileImage == null || senderProfileImage == "null")
                        ? Center(
                      child: CustomText(
                        "${groupName?.split('')[0]}",
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: SizeConfig.size18,
                      ),
                    )
                        : (senderProfileImage.isNotEmpty)
                        ? ClipOval(
                      child: (senderProfileImage.startsWith('http'))
                          ? CachedNetworkImage(
                        imageUrl: senderProfileImage,
                        fit: BoxFit.cover,
                        width: SizeConfig.size44,
                        height: SizeConfig.size44,
                      )
                          : (senderProfileImage.startsWith('assets'))?Image.asset(senderProfileImage): Image.file(
                        File(senderProfileImage),
                        width: SizeConfig.size44,
                        height: SizeConfig.size44,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Center(
                      child: CustomText(
                        senderName?.substring(0, 1) ?? '',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: SizeConfig.size18,
                      ),
                    ),
                  ),
                ),
              ),
            )
            ,
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChatListName(
                  senderName: senderName,
                  senderContactNo: senderContactNo,
                  conversationId: conversationId,
                ),
                SizedBox(height: SizeConfig.size2),
                SizedBox(
                  width: SizeConfig.size260,
                  child: (lastMessageType == "document" ||
                      lastMessageType == "contact" ||
                      lastMessageType == "audio" ||
                      lastMessageType == "location" ||
                      lastMessageType == "image" ||
                      lastMessageType == "video")
                      ? Row(
                    children: [
                      Icon(
                        lastMessageType == "document"
                            ? Icons.picture_as_pdf
                            : lastMessageType == "contact"
                            ? Icons.person
                            : lastMessageType == "audio"
                            ? Icons.audiotrack
                            : lastMessageType == "video"
                            ? Icons.video_chat
                            : lastMessageType == "location"
                            ? Icons.location_history
                            : Icons.camera_alt,
                        color: AppColors.grey9A,
                        size: SizeConfig.size16,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        lastMessageType == "document"
                            ? "Document"
                            : lastMessageType == "contact"
                            ? "Contact"
                            : lastMessageType == "audio"
                            ? "Audio"
                            : lastMessageType == "video"
                            ? "Video"
                            : lastMessageType == "location"
                            ? "Location"
                            : "Image",
                        fontSize: SizeConfig.size14,
                        color: AppColors.grey9A,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                      : lastMessage == null
                      ? CustomText(
                    "${(senderDesignation == null)
                        ? senderContactNo
                        : senderDesignation}",
                    fontSize: SizeConfig.size14,
                    color: AppColors.grey9A,
                    overflow: TextOverflow.ellipsis,
                  )
                      : CustomText(
                    maxLines: 1,
                    "$lastMessage",
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
              ? const SizedBox()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                "${formatTimeFromUtc(updatedAt)}",
                fontSize: SizeConfig.size11,
                color: AppColors.grey9A,
              ),
              SizedBox(height: SizeConfig.size6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.push_pin,
                          size: 14, color: Colors.grey.shade500),
                    ),
                  if ((index == 0 || index == 1 || index == 2) && unreadCount > 0)
                    CircleAvatar(
                      radius: SizeConfig.size12,
                      backgroundColor: Colors.lightBlue,
                      child: CustomText(
                        "$unreadCount",
                        color: AppColors.white,
                        fontSize: SizeConfig.size12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (isForwardUI == true)
            Theme(
              data: theme.copyWith(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.black),
                ),
              ),
              child: Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                  value: isSelected,
                  onChanged: (_) => selectChatListCard(),
                ),
              ),
            ),
          if (isChatListSelected)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
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
    color: AppColors.grayText,
  )
      : (message.replyParentMessage?.messageType == "video")
      ? Icon(
    Icons.video_camera_back_outlined,
    size: SizeConfig.size16,
    color: AppColors.grayText,
  )
      : (message.replyParentMessage?.messageType == "location")
      ? Icon(
    Icons.location_on_outlined,
    size: SizeConfig.size16,
    color: AppColors.grayText,
  )
      : (message.replyParentMessage?.messageType == "document")
      ? Icon(
    Icons.picture_as_pdf_outlined,
    size: SizeConfig.size16,
    color: AppColors.grayText,
  )
      : (message.replyParentMessage?.messageType == "contact")
      ? Icon(
    Icons.person_2_outlined,
    size: SizeConfig.size16,
    color: AppColors.grayText,
  )
      : (message.replyParentMessage?.messageType == "audio")
      ? Icon(
    Icons.audio_file_outlined,
    size: SizeConfig.size16,
    color: AppColors.grayText,
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: AppColors.grayText,
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
        color: AppColors.grayText,
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
        color: AppColors.grayText,
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
        color: AppColors.grayText,
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
        color: AppColors.grayText,
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
        color: AppColors.grayText,
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
        color: AppColors.grayText,
        fontSize: SizeConfig.size13,
      ),
    ],
  )
      : CustomText(
    "${message.replyParentMessage?.message}",
    fontWeight: FontWeight.w500,
    color: AppColors.grayText,
    fontSize: SizeConfig.size13,
    maxLines: 1,
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

void _initiateCallFromChat({
  required CallType callType,
  String? otherUserId,
  String? conversationId,
  required String userName,
  required String userImage,
}) async {
  // On Android: launch call in a separate task (WhatsApp-style separate Recent Apps entry)
  if (Platform.isAndroid) {
    CallController.isCallActivityActive = true;
    final launched = await CallActivityService.launchCallActivity(
      callId: '',
      roomId: '',
      conversationId: conversationId ?? '',
      callType: callType == CallType.video ? 'video' : 'audio',
      callerName: userName,
      callerImage: userImage,
      remoteUserId: otherUserId ?? '',
      remoteUserName: userName,
      remoteUserImage: userImage,
      isCaller: true,
    );
    print("launched: $launched");
    if (!launched) {
      // Fallback to in-app call if CallActivity launch fails
      CallController.isCallActivityActive = false;
      _initiateCallInApp(
        callType: callType,
        otherUserId: otherUserId,
        conversationId: conversationId,
        userName: userName,
        userImage: userImage,
      );
    }
    return;
  }

  // On iOS: use in-app call flow (no separate task support)
  _initiateCallInApp(
    callType: callType,
    otherUserId: otherUserId,
    conversationId: conversationId,
    userName: userName,
    userImage: userImage,
  );
}

/// Fallback: initiate call within the main app (iOS or when CallActivity fails)
void _initiateCallInApp({
  required CallType callType,
  String? otherUserId,
  String? conversationId,
  required String userName,
  required String userImage,
}) async {
  if (!Get.isRegistered<CallController>()) {
    Get.put(CallController());
  }
  final callController = Get.find<CallController>();

  final success = await callController.initiateCall(
    type: callType,
    otherUserId: otherUserId,
    existingConversationId: conversationId,
    userName: userName,
    userImage: userImage,
  );

  if (success) {
    Get.toNamed('/CallRoomScreen');
  }
}

void _showCallOptionsBottomSheet({
  required BuildContext context,
  String? otherUserId,
  String? conversationId,
  required String userName,
  required String userImage,
  required String contactNo,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _callOptionTile(
                icon: Icons.call,
                iconColor: Colors.green,
                title: 'Voice Call',
                subtitle: 'Call encrypted no contact share',
                onTap: () {
                  Navigator.pop(ctx);
                  _initiateCallFromChat(
                    callType: CallType.audio,
                    otherUserId: otherUserId,
                    conversationId: conversationId,
                    userName: userName,
                    userImage: userImage,
                  );
                },
              ),
              const SizedBox(height: 10),
              _callOptionTile(
                icon: Icons.videocam,
                iconColor: Colors.blue,
                title: 'Video Call',
                subtitle: 'Video call encrypted no contact share',
                onTap: () {
                  Navigator.pop(ctx);
                  _initiateCallFromChat(
                    callType: CallType.video,
                    otherUserId: otherUserId,
                    conversationId: conversationId,
                    userName: userName,
                    userImage: userImage,
                  );
                },
              ),
              if (contactNo.isNotEmpty) ...[
                const SizedBox(height: 10),
                _callOptionTile(
                  icon: Icons.phone_forwarded,
                  iconColor: Colors.orange,
                  title: 'Normal Call',
                  subtitle: 'Dial $contactNo',
                  onTap: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri.parse('tel:$contactNo'));
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _callOptionTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grayText),
        ],
      ),
    ),
  );
}

AppBar getChatTitleAppBar(BuildContext context, {
  String? userId,
  String? conversationId,
  String? type,
  String? socketType,
  String? name,
  String? contactNo,
  VoidCallback? onBackCallback,
  String? profileImage,
  bool? isGroupAppBar,
  bool? isGroupPrivate,
  bool? isFromAiChat,
}) {
  final theme = Theme.of(context);
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();
  void SendMessageToAI({required String message, String? tag}){
    chatViewController
        .sendMessageToAiSocket(
        type: AppConstants.personal_Chat_Type,
        tag:tag,
        message: message
    );
  }
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    leadingWidth: 38,
    leading: InkWell(
      onTap: onBackCallback ?? () {
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "$socketType"}, );
          bottomBarController.onChangeIndex(4);
          Navigator.popUntil(context, ModalRoute.withName(
              RouteHelper.getBottomNavigationBarScreenRoute()));
          chatViewController.onSelectChatTab(1);
        } else {
          Get.back();
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "$socketType"},);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: SizeConfig.size18),
        // Reduce touch padding if needed
        child: Icon(Icons.arrow_back_ios, color: Colors.black),
      ),
    ),
    titleSpacing: 0,
    title: InkWell(
      onTap: (type != AppStrings.Admin||type != AppStrings.PersonalChatAi||type != AppStrings.BusinessChatAi)
          ? () {
        if (isGroupAppBar != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ViewGroupMembers(

                    conversationId: conversationId,
                    type: type,

                  ),
              transitionsBuilder: (context, animation, secondaryAnimation,
                  child) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0)
                      .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
            ),
          );
        } else {
          _navigateToProfile(authorId: userId ?? '', type: type ?? "");
        }
      }

          : () {},
      child: Row(
        children: [
          CircleAvatar(
            radius: SizeConfig.size18,
            backgroundImage: (profileImage != null &&
                profileImage != 'null' &&
                profileImage.isNotEmpty)
                ? ((profileImage.contains('http'))
                ? NetworkImage(profileImage)
                :(profileImage.startsWith('assets'))?AssetImage(profileImage): FileImage(File(profileImage)) as ImageProvider)
                : null,

            child: (profileImage == 'null')
                ? CustomText(
              "${name!.split('')[0]}",
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: SizeConfig.size18,
            )
                : (profileImage != null)
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
                    Obx(() => chatViewController.e2eActive.value
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Colors.green, size: SizeConfig.size10),
                              SizedBox(width: 2),
                            ],
                          )
                        : const SizedBox.shrink()),
                    Obx(() {
                      // Show typing indicator if active
                      if (chatViewController.typingText.value.isNotEmpty) {
                        return CustomText(
                          chatViewController.typingText.value,
                          color: Colors.green,
                          fontSize: SizeConfig.size12,
                        );
                      }
                      return CustomText(
                        '${(type == AppConstants.personal_Chat_Type||type==AppConstants.business_Chat_Type)?"BlueCs Limited":(name == "BlueEra Orders") ? "BlueCs Ltd" : (type !=
                            AppStrings.Admin) ? (type == "business") ? chatViewController
                            .userOnlineStatus.value == "Online"
                            ? "Shop Open"
                            : "Shop Closed" : chatViewController
                            .userOnlineStatus.value : "BlueCs Limited"}',
                        color: AppColors.grayText,
                        fontSize: SizeConfig.size12,
                      );
                    }),
                    SizedBox(
                      width: SizeConfig.size3,
                    ),
                    (type != AppStrings.Admin)
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
    actions: (type == AppStrings.Admin||type == AppStrings.PersonalChatAi||type == AppStrings.BusinessChatAi||type == AppStrings.InventoryChatAi)
        ? null
        : [
      // E2E encryption indicator
      // Obx(() => chatViewController.e2eActive.value
      //     ? Tooltip(
      //         message: 'End-to-end encrypted',
      //         child: Padding(
      //           padding: const EdgeInsets.symmetric(horizontal: 4),
      //           child: Icon(Icons.lock, color: Colors.green, size: SizeConfig.size16),
      //         ),
      //       )
      //     : const SizedBox.shrink()),
      SizedBox(width: SizeConfig.size8),
      if(isGroupAppBar == null&&isFromAiChat!=true)
        Builder(
          builder: (ctx) {
            final flagCtrl = Get.isRegistered<ChatFlagController>()
                ? Get.find<ChatFlagController>()
                : Get.put(ChatFlagController());
            return Obx(() {
              final existingFlag = flagCtrl.getFlagForConversation(conversationId);
              return InkWell(
                onTap: () {
                  Get.dialog(
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.2),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12, top: 80),
                            child: GestureDetector(
                              onTap: () {},
                              child: ChatFlagDropdown(
                                conversationId: conversationId ?? '',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barrierDismissible: false,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: existingFlag != null
                      ? Text(existingFlag.emoji, style: const TextStyle(fontSize: 20))
                      : Icon(Icons.flag_outlined,
                          color: AppColors.chat_input_icon_color, size: 26),
                ),
              );
            });
          },
        ),
      if(isFromAiChat!=true)
        InkWell(
            onTap: () {
              _showCallOptionsBottomSheet(
                context: context,
                otherUserId: isGroupAppBar == null ? userId : null,
                conversationId: conversationId,
                userName: name ?? '',
                userImage: profileImage ?? '',
                contactNo: contactNo ?? '',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SvgPicture.asset(
                'assets/svg/audio_and_video_call.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  AppColors.chat_input_icon_color,
                  BlendMode.srcIn,
                ),
              ),
            )),
      if(isFromAiChat==true)
        PopupMenuButton<String>(
          menuPadding: EdgeInsets.zero,
          icon: SvgPicture.asset(AppIconAssets.editIcon,color: AppColors.black,),
          padding: EdgeInsets.zero,
          color: AppColors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (value) {

          },
          itemBuilder: (context) => PopupMenuBuilders.popPupMenuForAiChat(),
        ),
      if(isFromAiChat==true)
      InkWell(
        onTap: (){
          Get.dialog(
            GestureDetector(
              onTap: () {
                Get.back(); // 👈 close when tapping empty space
              },
              behavior: HitTestBehavior.opaque, // IMPORTANT
              child: Material(
                color: Colors.black.withOpacity(0.2), // optional dim background
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 20,top: 110),
                    child: GestureDetector(
                      onTap: () {}, // 👈 prevent dialog tap from closing
                      child: InitialMessageOptionDialog(
                        userName: userNameGlobal,
                        topics: AppConstants.aiChatTopics,
                        onSend: (message, tag) {
                          SendMessageToAI(message: message, tag: tag);
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            barrierDismissible: false, // handled manually now (more reliable)
          );
        },
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryColor)
            ),
            padding: EdgeInsets.symmetric(horizontal: 8,vertical: 2),
            child: CustomText("New",color: AppColors.primaryColor,)),
      ),
      SizedBox(width: SizeConfig.size12),
      // SvgPicture.asset(AppIconAssets.chat_video_call),
      // const SizedBox(width: 12),
      if(isGroupAppBar == null)
        PopupMenuButton<String>(
            icon: SvgPicture.asset(AppIconAssets.chat_info_pop,height: 20,width: 20,color: AppColors.black,),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            offset: const Offset(-6, 36),
            color: AppColors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (value) {
              if(value == "clear_chat"){
                showDeleteChatDialog(conversationId ?? '');
              } else if(value == "report"){
                // TODO: Handle report
              } else if(value == "block"){
                // TODO: Handle block
              } else if(value == "media_docs"){
                Get.to(() => ConversationMediaPage(
                  conversationId: conversationId ?? '',
                  contactName: name ?? 'Chat',
                  initialTab: 0,
                ));
              } else if(value == "chat_theme"){
                Get.to(() => ChatBackgroundScreen());
              } else if(value == "add_shortcut"){
                ChatShortcutService.createChatShortcut(
                  conversationId: conversationId ?? '',
                  name: name ?? 'Chat',
                  userId: userId ?? '',
                  profileImage: profileImage,
                  chatType: socketType ?? 'personal',
                );
              }
            },
            itemBuilder: (context) => PopupMenuBuilders.popPupMenuForPersonalChat(),
        ),
      if(isGroupAppBar != null)
        PopupMenuButton<String>(
            icon: SvgPicture.asset(AppIconAssets.chat_info_pop),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            offset: const Offset(-6, 36),
            color: AppColors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (value) {
              if(value == "clear_chat"){
                showDeleteChatDialog(conversationId ?? '');
              }
            },
            itemBuilder: (context) => PopupMenuBuilders.popPupMenuForGroupChat(),
        )
      else if (isFromAiChat==false)
        SizedBox(),
      SizedBox(width: SizeConfig.size8),

    ],
  );
}
void showDeleteChatDialog(String conId) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child:DeleteChatHistoryDialog(conversationId:conId ,),
    ),
    barrierDismissible: false, // user must tap button
  );
}
PreferredSize getChatOptionsAppBar(BuildContext context, {
   String? userId,
   String? conversationId,
   TextEditingController? editingController,
  String? profileImage,
  bool? isFromAiChat,
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
          padding: EdgeInsets.only(left: SizeConfig.size18),
          child: Icon(Icons.arrow_back_ios,
              color: AppColors.chat_input_icon_color),
        ),
      ),
      titleSpacing: 8,
      title: CustomText(
        "${chatThemeController.selectedMessageIds.length}",
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
              builder: (_) => CommonDeleteDialog(
                showDeleteForEveryone:
                chatThemeController.isDeleteForEveryOneAvailable.value,

                onDeleteForMe: () async {
                  FocusScope.of(context).unfocus();

                  Map<String, dynamic> data = {
                    ApiKeys.conversation_id: "$conversationId",
                    ApiKeys.delete_from_every_one: false,
                    ApiKeys.message_id_list: chatThemeController.selectedMessageIds
                  };

                  await chatViewController
                      .deleteChatMessage(data, userId ?? '');

                  chatThemeController.resetSelection();
                  chatThemeController.deActivateSelection();

                  Navigator.pop(context);
                },

                onDeleteForEveryone: () async {
                  FocusScope.of(context).unfocus();

                  Map<String, dynamic> data = {
                    ApiKeys.conversation_id: "$conversationId",
                    ApiKeys.delete_from_every_one: true,
                    ApiKeys.message_id_list: chatThemeController.selectedMessageIds
                  };

                  await chatViewController
                      .deleteChatMessage(data, userId ?? '');

                  chatThemeController.resetSelection();
                  chatThemeController.deActivateSelection();

                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
        (chatThemeController.selectedMessageIds.length == 1 &&
            chatThemeController.selectedFirstMessage?.value?.messageType ==
                "text")
            ? IconButton(
          icon: Icon(
            Icons.edit,
            color: AppColors.chat_input_icon_color,
            size: SizeConfig.size22,
          ),
          onPressed: () {
            editingController?.text = chatThemeController
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
        IconButton(
          icon:  Icon(Icons.push_pin_outlined,color: AppColors.chat_input_icon_color,size: 22,),
          onPressed: (){
            showPinDialog(conversationId??'');
          },
        // onPressed: (){},
        ),
        Padding(
          padding: EdgeInsets.only(left: SizeConfig.size6),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewChatMainScreen(
                            isForwardUI: true,

                          )));
            },
            child: SvgPicture.asset(
              AppIconAssets.chat_media_forward,
              height: SizeConfig.size24,
              width: SizeConfig.size24,
            ),
          ),
        ),


        // PopupMenuButton<String>(
        //   icon: Icon(Icons.more_vert, color: AppColors.chat_input_icon_color),
        //   offset: const Offset(20, 60), // 👈 shift menu 40 pixels downward
        //   onSelected: (value) {
        //     if (value == 'edit') {
        //       print("Edit selected");
        //       // Handle your edit logic
        //     }
        //   },
        //   itemBuilder: (context) => [],
        // ),

        SizedBox(width: SizeConfig.size8),
      ],
    ),
  );
}
void showPinDialog(String conId) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child:PinMessageDurationDialog(conversationId:conId ,),
    ),
    barrierDismissible: false, // user must tap button
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
    TextEditingController? editingController,
    ChatThemeController chatThemeController,
    ChatViewController chatViewController) {
  Get.dialog(
    AlertDialog(
      insetPadding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      // Reduced outer spacing
      contentPadding: EdgeInsets.only(bottom: SizeConfig.size10),
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
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
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
                EdgeInsets.symmetric(
                    horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
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
                      ApiKeys.message: "${editingController?.text}"
                    };
                    bool value =
                    await chatViewController.updateMessageApi(data);
                    if (value) {
                      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
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

class BusinessToRiderOtpVerificationCard extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isError;
  final bool isVerifying;

  const BusinessToRiderOtpVerificationCard({
    Key? key,
    required this.onSubmit,
    this.isError = false,
    this.isVerifying = false,
  }) : super(key: key);

  @override
  State<BusinessToRiderOtpVerificationCard> createState() =>
      _BusinessToRiderOtpVerificationCardState();
}

class _BusinessToRiderOtpVerificationCardState
    extends State<BusinessToRiderOtpVerificationCard> {
  final orderController = Get.isRegistered<OrderNowController>()
      ? Get.find<OrderNowController>()
      : Get.put(OrderNowController());

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              "Enter OTP",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.w700,

            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              "Dorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.",
              textAlign: TextAlign.center,
              fontSize: SizeConfig.size14,
              color: AppColors.grayText,

            ),
            SizedBox(height: SizeConfig.size20),
            _buildOtpInput(),
            SizedBox(height: SizeConfig.size20),
            _buildSubmitButton(context),
            if (widget.isError) ...[
              SizedBox(height: SizeConfig.size10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                      "Wrong OTP! ",
                      color: Colors.red, fontSize: SizeConfig.size12
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CustomText(
                      "Re-enter",

                      color: Colors.blue,
                      fontSize: SizeConfig.size12,
                      decoration: TextDecoration.underline,

                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Pinput(
      length: 4,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onCompleted: widget.onSubmit,
      defaultPinTheme: PinTheme(
        width: 45,
        height: 45,
        textStyle: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(() {
      return CustomBtn(
          bgColor: AppColors.primaryColor,
          isLoading: orderController.ownerOtpLoading.value,
          onTap: () {}, title: "Submit");
    });
  }
}
