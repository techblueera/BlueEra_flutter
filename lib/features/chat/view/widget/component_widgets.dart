import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
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
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/order_controllar.dart';
import '../../auth/model/GetChatListModel.dart';
import '../chat_screen_new.dart';
import '../contacts/contact_list_page.dart';
import '../group_chat/view_group_members.dart';
import '../symbol_view/symbol_view_images.dart';

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

Widget ChatListTile({
  required Function onSelect,
  required String type,
  required BuildContext context,
  required bool? isForwardUI,
  bool? isFromGroupSelect,
  Function()? onTab,
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
    } else {
      chatViewController.selectedUserIds.add(senderId);
      chatViewController.selectedChatList.add(chat);
    }
    onSelect();
  }

  return ((senderName == null || senderName == "null") & (senderContactNo ==
      null))
      ? const SizedBox()
      : InkWell(
    onTap: onTab ??
            () {
          if (isForwardUI == true) {
            selectChatListCard();
          } else {
            chatViewController.openAnyOneChatFunction(
              // businessId: senderBusinessId,
              type: type,
              isInitialMessage: false,
              userId: senderId,
              conversationId: conversationId,
              profileImage: senderProfileImage,
              contactName: senderName,
              contactNo: senderContactNo,
            );
          }
        },
    child: Padding(
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
                Get.to(SymbolViewImages(data: chat?.symbolData??[],userId: chat?.sender?.id,));
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
                          : Image.file(
                        File(senderProfileImage),
                        width: SizeConfig.size44,
                        height: SizeConfig.size44,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Center(
                      child: Text(
                        senderName?.substring(0, 1) ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: SizeConfig.size18,
                        ),
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
                CustomText(
                  "${(senderName == null || senderName == "null")
                      ? senderContactNo
                      : senderName}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.bold,
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
              (index == 0 || index == 1 || index == 2)
                  ? (unreadCount == 0)
                  ? const SizedBox()
                  : CircleAvatar(
                radius: SizeConfig.size12,
                backgroundColor: Colors.lightBlue,
                child: CustomText(
                  "$unreadCount",
                  color: AppColors.white,
                  fontSize: SizeConfig.size12,
                ),
              )
                  : const SizedBox(),
            ],
          ),
          if (isForwardUI == true)
            Theme(
              data: theme.copyWith(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.black),
                  ),
                  side: const BorderSide(color: Colors.black),
                ),
              ),
              child: Checkbox(
                activeColor: Colors.blue,
                checkColor: Colors.white,
                value: isSelected,
                onChanged: (_) => selectChatListCard(),
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

AppBar getChatTitleAppBar(BuildContext context, {
  required String? userId,
  required String? conversationId,
  required String? type,
  required String? socketType,
  required String? name,
  required String? contactNo,
  VoidCallback? onBackCallback,
  String? profileImage,
  bool? isGroupAppBar,
  bool? isGroupPrivate,
}) {
  final theme = Theme.of(context);
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    leadingWidth: 38,
    leading: InkWell(
      onTap: onBackCallback ?? () {
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "$socketType"}, true);
          bottomBarController.onChangeIndex(4);
          Navigator.popUntil(context, ModalRoute.withName(
              RouteHelper.getBottomNavigationBarScreenRoute()));
          chatViewController.onSelectChatTab(1);
        } else {
          Get.back();
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "$socketType"}, true);
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
                    publicGroup: isGroupPrivate??false,
                    conversationId: conversationId,
                    type: type,
                    name: name,
                    profileImage: profileImage,
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
            backgroundColor: theme.colorScheme.primary,
            radius: SizeConfig.size18,
            backgroundImage: profileImage != null
                ? ((profileImage.contains('http'))
                ? NetworkImage(profileImage)
                : FileImage(File(profileImage)) as ImageProvider)
                : null,
            child: (profileImage == 'null') ? CustomText(
              "${name!.split('')[0]}",
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: SizeConfig.size18,
            ) : (profileImage != null)
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
                      '${(type == AppConstants.personal_Chat_Type||type==AppConstants.business_Chat_Type)?"BlueCs Limited":(name == "BlueEra Orders") ? "BlueCs Ltd" : (type !=
                          AppStrings.Admin) ? (type == "business") ? chatViewController
                          .userOnlineStatus.value == "Online"
                          ? "Shop Open"
                          : "Shop Closed" : chatViewController
                          .userOnlineStatus.value : "BlueCs Limited"}',
                      color: AppColors.grayText,

                      fontSize: SizeConfig.size12,
                    ),
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
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ViewGroupMembers(
                          publicGroup: isGroupPrivate??false,
                          conversationId: conversationId,
                          type: type,
                          name: name,
                          profileImage: profileImage,
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
          padding: EdgeInsets.only(left: SizeConfig.size18),
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
                            chatThemeController.deActivateSelection();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(SizeConfig.size12),
                            margin: EdgeInsets.only(bottom: SizeConfig.size10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(
                                  SizeConfig.size10),
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
                            chatThemeController.deActivateSelection();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(SizeConfig.size12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(
                                  SizeConfig.size10),
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
          padding: EdgeInsets.only(left: SizeConfig.size6),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewChatMainScreen(
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
                      ApiKeys.message: "${editingController.text}"
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
