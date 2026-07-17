import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/chat_language.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
import '../../auth/controller/chat_pin_archive_controller.dart';
import 'chat_flag_bottom_sheet.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/ai_chat_profile_controller.dart';
import '../chat_theme/chat_background_screen.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../auth/controller/order_controllar.dart';
import '../../auth/model/GetChatListModel.dart';
import '../order_main_chat_screen.dart';
import '../contacts/view/contact_list_page.dart';
import '../group_chat/view_group_members.dart';
import '../group_chat/widgets/delete_chat_history_dialog.dart';
import '../group_chat/widgets/pin_message_dialoge_widget.dart';
import '../symbol_view/symbol_view_images.dart';
import 'chat_shortcut_service.dart';
import 'common_delete_message.dart';
import '../media_view_page/conversation_media_page.dart';

/// Returns true when [createdAt] (ISO-8601 from server) is older than 24 hours.
/// Used to expire rider action buttons, the order chat input, and the appbar
/// call button on order conversations once the delivery window has elapsed.
/// Whether [createdAt] is older than [maxAge] (default 24h). Callers that need
/// a longer active window (e.g. the rider / rider_map action cards) pass a
/// larger [maxAge] so their buttons stay enabled for longer-running rides.
bool isMessageOlderThan24Hours(String? createdAt,
    {Duration maxAge = const Duration(hours: 24)}) {
  if (createdAt == null || createdAt.isEmpty) return false;
  try {
    final created = DateTime.parse(createdAt).toLocal();
    return DateTime.now().difference(created) > maxAge;
  } catch (_) {
    return false;
  }
}

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
        // Determine the effective status: use whichever is further along
        // between the per-message status and the conversation-level status.
        const statusOrder = {'sent': 0, 'delivered': 1, 'read': 2};
        final msgStatus = message.status ?? 'sent';
        final convStatus = chatViewController.readMessageStatus.value;
        final msgRank = statusOrder[msgStatus] ?? 0;
        final convRank = statusOrder[convStatus] ?? -1;
        final effectiveStatus = (convRank > msgRank) ? convStatus : msgStatus;

        if (message.sendStatus == "pending") {
          return Icon(
            Icons.timelapse_outlined,
            color: Colors.grey,
            size: 16,
          );
        } else if (effectiveStatus == 'read') {
          return LocalAssets(
            imagePath: AppIconAssets.chat_double_tick,
            imgColor: Colors.blue,
          );
        } else if (effectiveStatus == 'delivered') {
          return LocalAssets(
            imagePath: AppIconAssets.chat_double_tick,
            imgColor: Colors.grey,
          );
        } else {
          // sent or null
          return Icon(
            Icons.check,
            color: indicateColor ?? AppColors.white,
            size: 16,
          );
        }
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
        LocalAssets(
          imagePath: AppIconAssets.chat,
          imgColor: Colors.black,
          height: 70,
          width: 70,
        ),
        const SizedBox(
          height: 14,
        ),
        CustomText(
          reminderMsg==null?AppStrings.noChatsFound.tr:AppStrings.noReminderMessagesFound.tr,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(
          height: 6,
        ),
        if(reminderMsg==null)
        CustomText(AppStrings.goToContactsAndStartNewConversation.tr),
        const SizedBox(
          height: 6,
        ),
        if(reminderMsg==null)

        InkWell(
            onTap: () {
              Get.toNamed(RouteHelper.getChatContactsRoute());
            },
            child: CustomText(
              AppStrings.clickHereToStartConversation.tr,
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
        LocalAssets(
          imagePath: AppIconAssets.chat,
          height: 70,
          imgColor: Colors.black,
          width: 70,
        ),
        const SizedBox(
          height: 14,
        ),
        CustomText(
          AppStrings.noGroupChatsFound.tr,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(
          height: 6,
        ),
        CustomText(AppStrings.goToContactsAndCreateNewGroup.tr),
        const SizedBox(
          height: 6,
        ),
        InkWell(
            onTap: () {
              Get.to(ContactsPage(from: "group",));
            },
            child: CustomText(
              AppStrings.createYourFirstGroup.tr,
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

/// Chat-list preview for `last_message_type == "reply_to_symbol"`. Renders a
/// tiny thumbnail of the quoted symbol (image content / coloured tile / icon)
/// followed by "Symbol reply: <text>". Reads from the snapshot the server
/// puts on `chat.repliedSymbol` per docs/reply-to-symbol-integration-guide.md.
Widget _buildSymbolReplyPreview(ChatList? chat, String? lastMessage) {
  final symbol = chat?.repliedSymbol;
  final type = symbol?.type;
  final content = symbol?.content ?? '';
  final bool isMedia =
      (type == 'photo' || type == 'video') && content.startsWith('http');

  Widget thumb;
  if (isMedia) {
    thumb = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: content,
        width: SizeConfig.size20,
        height: SizeConfig.size20,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: SizeConfig.size20,
          height: SizeConfig.size20,
          color: AppColors.grey9A.withValues(alpha: 0.2),
        ),
        errorWidget: (_, __, ___) => Container(
          width: SizeConfig.size20,
          height: SizeConfig.size20,
          color: AppColors.grey9A.withValues(alpha: 0.2),
          child: Icon(Icons.image, size: SizeConfig.size14, color: AppColors.grey9A),
        ),
      ),
    );
  } else {
    thumb = Icon(
      Icons.chat_bubble_outline,
      size: SizeConfig.size16,
      color: AppColors.grey9A,
    );
  }

  return Row(
    children: [
      thumb,
      SizedBox(width: SizeConfig.size4),
      Expanded(
        child: CustomText(
          (lastMessage ?? '').isEmpty
              ? AppStrings.symbolReply.tr
              : AppStrings.symbolReplyFmt.trParams({'message': lastMessage ?? ''}),
          fontSize: SizeConfig.size14,
          color: AppColors.grey9A,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
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
  bool showNewBadgeIfRecent = false,
  bool showFlagBadge = false,
  // Inquiry tab: show a "New" label below the time when the conversation was
  // created within the last 4 hours (uses `chat.createdAt`).
  bool showNewIfRecentlyCreated = false,
}) {
  final sender = chat?.sender;
  // Group rows can surface inside the personal/business list payloads
  // (`type:"group"`). For those, the conversation is identified by
  // `group_name` / `group_profile_image` rather than the embedded sender,
  // so prefer the group fields when the row is a group.
  final isGroupChat =
      (chat?.type == AppConstants.group_Chat_Type) || (chat?.isGroup == true);
  final senderName = (isGroupChat || chat?.lastMessage == "Order Message")
      ? chat?.groupName
      : sender?.name;
  final senderId = sender?.id ?? '';
  final senderContactNo = sender?.contactNo;
  final senderProfileImage =
      (isGroupChat || chat?.lastMessage == "Order Message")
          ? chat?.groupProfileImage
          : sender?.profileImage;
  final senderDesignation = sender?.designation;
  // final senderBusinessId = sender?.businessId;

  final groupName = chat?.groupName;
  final conversationId = chat?.conversationId ?? '';
  final lastMessageType = chat?.lastMessageType;
  final lastMessage = chat?.lastMessage;
  final unreadCount = chat?.unreadCount ?? 0;
  final updatedAt = chat?.updatedAt ?? '';
  final isPendingLastMessage = chat?.lastMessageSendStatus == "pending";
  // Orders tab: surface a "New" pill when the last message is fresh
  // (within 15 minutes) instead of the numeric unread-count badge.
  bool isRecentLastMessage = false;
  if (showNewBadgeIfRecent && updatedAt.isNotEmpty) {
    try {
      final lastMessageAt = DateTime.parse(updatedAt).toLocal();
      isRecentLastMessage =
          DateTime.now().difference(lastMessageAt).inMinutes < 15;
    } catch (_) {
      isRecentLastMessage = false;
    }
  }

  // Inquiry tab: a conversation whose last message arrived within the last
  // 4 hours is flagged "New" below the time, regardless of unread state.
  bool isRecentlyCreated = false;
  if (showNewIfRecentlyCreated && updatedAt.isNotEmpty) {
    try {
      final lastMessageAt = DateTime.parse(updatedAt).toLocal();
      final diff = DateTime.now().difference(lastMessageAt);
      isRecentlyCreated = !diff.isNegative && diff.inMinutes < 240;
    } catch (_) {
      isRecentlyCreated = false;
    }
  }

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

      commonSnackBar(message: AppStrings.onlyFiveMembersCanChoose.tr);
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
          } else if ((chat?.type == AppConstants.group_Chat_Type) ||
              (chat?.isGroup == true)) {
            // Group conversations can surface inside the personal/business
            // list payloads (`type:"group"`); open the dedicated group screen.
            chatViewController.openGroupFromChatList(chat);
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
          Stack(
            clipBehavior: Clip.none,
            children: [
          InkWell(
            onTap: () {
              if(chat?.symbolData?.isNotEmpty??false){
                Get.to(SymbolViewImages(userId: chat?.sender?.id, name: senderName, profileImage: senderProfileImage,));
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
                        // Decode at ~thumbnail size instead of the full
                        // source resolution. Avatars in the list are ~44dp,
                        // so a 132px memory cache covers up to 3x DPR and
                        // cuts decode time dramatically on offline reloads.
                        memCacheWidth: 132,
                        memCacheHeight: 132,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (_, __) => Container(
                          width: SizeConfig.size44,
                          height: SizeConfig.size44,
                          color: AppColors.white,
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: CustomText(
                            (senderName?.isNotEmpty ?? false) ? senderName!.substring(0, 1).toUpperCase() : '',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: SizeConfig.size18,
                          ),
                        ),
                      )
                          : (senderProfileImage.startsWith('assets'))?Image.asset(senderProfileImage): Image.file(
                        File(senderProfileImage),
                        width: SizeConfig.size44,
                        height: SizeConfig.size44,
                        fit: BoxFit.cover,
                        cacheWidth: 132,
                        cacheHeight: 132,
                      ),
                    )
                        : Center(
                      child: CustomText(
                        (senderName?.isNotEmpty ?? false) ? senderName!.substring(0, 1).toUpperCase() : '',
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
              // Small badge at the top-right (45° from 12 o'clock) marking the
              // row as a group conversation.
              if (isGroupChat)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 9,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
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
                Obx(() {
                  final isTyping = chatViewController
                      .typingByConversation.containsKey(conversationId);
                  if (isTyping) {
                    return SizedBox(
                      width: SizeConfig.size260,
                      child: CustomText(
                        AppStrings.typingDots.tr,
                        fontSize: SizeConfig.size14,
                        color: Colors.green,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return SizedBox(
                    width: SizeConfig.size260,
                    child: lastMessageType == "reply_to_symbol"
                        ? _buildSymbolReplyPreview(chat, lastMessage)
                        : (lastMessageType == "document" ||
                        lastMessageType == "contact" ||
                        lastMessageType == "audio" ||
                        lastMessageType == "location" ||
                        lastMessageType == "live_location" ||
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
                              : lastMessageType == "live_location"
                              ? (chat?.isEnded == true
                                  ? Icons.location_off_rounded
                                  : Icons.share_location_rounded)
                              : Icons.camera_alt,
                          color: AppColors.grey9A,
                          size: SizeConfig.size16,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          lastMessageType == "document"
                              ? AppStrings.documentLabel.tr
                              : lastMessageType == "contact"
                              ? AppStrings.contactLabel.tr
                              : lastMessageType == "audio"
                              ? AppStrings.audioLabel.tr
                              : lastMessageType == "video"
                              ? AppStrings.videoLabel.tr
                              : lastMessageType == "location"
                              ? AppStrings.locationLabel.tr
                              : lastMessageType == "live_location"
                              ? (chat?.isEnded == true
                                  ? AppStrings.liveLocationEnded.tr
                                  : AppStrings.liveLocationMsgType.tr)
                              : AppStrings.imageLabel.tr,
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
                        : Builder(builder: (_) {
                      final msg = lastMessage;
                      final lowerMsg = msg.toLowerCase();
                      Color msgColor = AppColors.grey9A;
                      if (lowerMsg.contains('missed call')) {
                        msgColor = Colors.red;
                      } else if (lowerMsg.contains('ongoing')) {
                        msgColor = AppColors.primaryColor;
                      } else if (lowerMsg.contains('calling')) {
                        msgColor = Colors.green;
                      }
                      return CustomText(
                        maxLines: 1,
                        msg,
                        fontSize: SizeConfig.size14,
                        color: msgColor,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  );
                }),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          (isForwardUI == true)
              ? const SizedBox()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPendingLastMessage)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.access_time,
                        size: SizeConfig.size12,
                        color: AppColors.grey9A,
                      ),
                    ),
                  CustomText(
                    "${formatTimeFromUtc(updatedAt)}",
                    fontSize: SizeConfig.size11,
                    color: AppColors.grey9A,
                  ),
                ],
              ),
              if (isRecentlyCreated) ...[
                SizedBox(height: SizeConfig.size4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomText(
                    AppStrings.newTag.tr,
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.size11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  if (showFlagBadge && Get.isRegistered<ChatFlagController>())
                    Obx(() {
                      final assignedFlag = Get.find<ChatFlagController>()
                          .getFlagForConversation(conversationId);
                      if (assignedFlag != null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: assignedFlag.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: assignedFlag.color, width: 0.8),
                          ),
                          child: CustomText(
                            assignedFlag.label,
                            color: assignedFlag.color,
                            fontSize: SizeConfig.size11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }
                      if (isRecentLastMessage) {
                        return CustomText(
                          AppStrings.newTag.tr,
                          color: AppColors.primaryColor,
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w600,
                        );
                      }
                      if (unreadCount > 0) {
                        return CircleAvatar(
                          radius: SizeConfig.size12,
                          backgroundColor: Colors.lightBlue,
                          child: CustomText(
                            "$unreadCount",
                            color: AppColors.white,
                            fontSize: SizeConfig.size12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    })
                  else if (isRecentLastMessage)
                    CustomText(
                      AppStrings.newTag.tr,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w600,
                    )
                  else if (unreadCount > 0)
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
    return AppStrings.yesterdayLabel.tr;
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
        AppStrings.imageLabel.tr,
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
        AppStrings.videoLabel.tr,
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
        AppStrings.locationLabel.tr,
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
        AppStrings.documentLabel.tr,
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
        AppStrings.contactLabel.tr,
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
        AppStrings.audioLabel.tr,
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
        AppStrings.imageLabel.tr,
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
        AppStrings.videoLabel.tr,
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
        AppStrings.locationLabel.tr,
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
        AppStrings.documentLabel.tr,
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
        AppStrings.contactLabel.tr,
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
        AppStrings.audioLabel.tr,
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

/// Public entry so chat widgets (e.g. tapping an @mention) can open a member's
/// profile using the same routing as the chat list.
void navigateToProfileFromChat(
        {required String authorId, required String type}) =>
    _navigateToProfile(authorId: authorId, type: type);

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

void _refreshChatAfterOutgoingCall(String? conversationId) {
  final id = conversationId ?? '';
  if (id.isEmpty) return;
  if (!Get.isRegistered<ChatViewController>()) return;
  final cvc = Get.find<ChatViewController>();
  // The backend persists the outgoing call record asynchronously, so a single
  // fixed delay sometimes races and returns the pre-call message list. Fire
  // the fetch a few times with increasing backoff so we pick it up as soon as
  // it lands.
  void _fetch() {
    cvc.emitEvent(ChatEmitEvents.messageReceived, {
      ApiKeys.conversation_id: id,
      ApiKeys.page: 1,
      ApiKeys.is_online_user: cvc.userOpenUserId.value,
      ApiKeys.per_page_message: 30,
    });
  }
  Future.delayed(const Duration(milliseconds: 500), _fetch);
  Future.delayed(const Duration(milliseconds: 1500), _fetch);
  Future.delayed(const Duration(milliseconds: 3000), _fetch);
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
    if (launched) {
      _refreshChatAfterOutgoingCall(conversationId);
    } else {
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
    _refreshChatAfterOutgoingCall(conversationId);
    Get.toNamed('/CallRoomScreen');
  }
}

/// Public entry to the chat call-options bottom sheet (voice / video / normal
/// call) — the same sheet the chat appbar's call icon opens. Exposed so other
/// widgets (e.g. the order card's Call button) can reuse it.
void showChatCallOptionsBottomSheet({
  required BuildContext context,
  String? otherUserId,
  String? conversationId,
  required String userName,
  required String userImage,
  required String contactNo,
}) {
  _showCallOptionsBottomSheet(
    context: context,
    otherUserId: otherUserId,
    conversationId: conversationId,
    userName: userName,
    userImage: userImage,
    contactNo: contactNo,
  );
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
                title: AppStrings.voiceCall.tr,
                subtitle: AppStrings.callEncryptedNoContactShare.tr,
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
                title: AppStrings.videoCall.tr,
                subtitle: AppStrings.videoCallEncryptedNoContactShare.tr,
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
                  title: AppStrings.normalCall.tr,
                  subtitle: AppStrings.dialFmt.trParams({'number': contactNo}),
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

/// Avatar shown in the chat title bar. Renders network/asset/file images with
/// a coloured initial placeholder fallback. Shared by AI and regular chats.
Widget _chatTitleAvatar({
  String? name,
  String? profileImage,
  required ThemeData theme,
}) {
  final hasImage =
      profileImage != null && profileImage != 'null' && profileImage.isNotEmpty;
  final initial = (name != null && name.isNotEmpty) ? name.substring(0, 1) : 'U';
  final placeholder = CircleAvatar(
    radius: SizeConfig.size18,
    backgroundColor: theme.colorScheme.primary,
    child: Center(
      child: CustomText(
        initial,
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: SizeConfig.size18,
      ),
    ),
  );
  if (!hasImage) return placeholder;
  if (profileImage.contains('http')) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: profileImage,
        width: SizeConfig.size36,
        height: SizeConfig.size36,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
  if (profileImage.startsWith('assets')) {
    return CircleAvatar(
      radius: SizeConfig.size18,
      backgroundImage: AssetImage(profileImage),
    );
  }
  return CircleAvatar(
    radius: SizeConfig.size18,
    backgroundImage: FileImage(File(profileImage)),
  );
}

/// Large avatar preview used inside the AI profile edit sheet.
Widget _aiAvatarPreview(String? image, String? name) {
  final hasImage = image != null && image != 'null' && image.isNotEmpty;
  final initial = (name != null && name.isNotEmpty && name != 'null')
      ? name.substring(0, 1).toUpperCase()
      : 'U';
  final placeholder = CircleAvatar(
    radius: 44,
    backgroundColor: AppColors.primaryColor,
    child: CustomText(initial,
        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30),
  );
  if (!hasImage) return placeholder;
  if (image.contains('http')) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: image,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
  if (image.startsWith('assets')) {
    return CircleAvatar(radius: 44, backgroundImage: AssetImage(image));
  }
  return CircleAvatar(radius: 44, backgroundImage: FileImage(File(image)));
}

/// Bottom sheet to rename the AI chat and change its profile image. Both are
/// stored locally per [type]; on reinstall the chat falls back to its default
/// name/image passed in by the caller.
void showAiChatProfileEditSheet(
  BuildContext context, {
  required AiChatProfileController controller,
  required String type,
  String? defaultName,
  String? defaultImage,
}) {
  final nameController = TextEditingController(
    text: controller.customName.value.isNotEmpty
        ? controller.customName.value
        : ((defaultName == null || defaultName == 'null') ? '' : defaultName),
  );
  final RxString previewPath = controller.customImagePath.value.obs;

  Future<void> pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    // Copy into app documents so the path survives cache clears / restarts.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext =
          picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
      final saved =
          await File(picked.path).copy('${dir.path}/ai_chat_${type}_avatar.$ext');
      previewPath.value = saved.path;
    } catch (_) {
      previewPath.value = picked.path;
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CustomText('Edit Profile',
                fontSize: SizeConfig.size16, fontWeight: FontWeight.w600),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  Obx(() => _aiAvatarPreview(
                        previewPath.value.isNotEmpty
                            ? previewPath.value
                            : defaultImage,
                        controller.customName.value.isNotEmpty
                            ? controller.customName.value
                            : defaultName,
                      )),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomText('Name',
                fontSize: SizeConfig.size14, fontWeight: FontWeight.w500),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter name',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child:
                        CustomText('Cancel', color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor),
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        await controller.saveName(type, newName);
                      }
                      if (previewPath.value.isNotEmpty) {
                        await controller.saveImage(type, previewPath.value);
                      }
                      Navigator.pop(ctx);
                      commonSnackBar(message: 'Profile updated');
                    },
                    child: CustomText('Save', color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Language picker for the AI chat 3-dot menu. Selecting a language sends the
/// `language=<Label>` directive over the chat socket so the AI replies only in
/// that language; the choice is locked server-side per conversation and shown
/// as a badge in the AppBar. Native scripts need a font (e.g. Noto Sans) that
/// covers Indic / Arabic / CJK glyphs.
void showAiChatLanguageSheet(
  BuildContext context, {
  required AiChatProfileController controller,
  required String type,
}) {
  final chatViewController = Get.find<ChatViewController>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomText(AppStrings.language.tr,
                  fontSize: SizeConfig.size16, fontWeight: FontWeight.w600),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kChatLanguages.length,
                itemBuilder: (_, i) {
                  final lang = kChatLanguages[i];
                  return Obx(() {
                    final selected = controller.language.value == lang.label;
                    return ListTile(
                      title: CustomText(
                        lang.label == lang.native
                            ? lang.label
                            : '${lang.label}  (${lang.native})',
                      ),
                      trailing: selected
                          ? Icon(Icons.check, color: AppColors.primaryColor)
                          : null,
                      onTap: () {
                        chatViewController.changeAiLanguage(
                          type: type,
                          label: lang.label,
                        );
                        Navigator.pop(ctx);
                        commonSnackBar(message: '${lang.label} selected');
                      },
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Confirmation dialog for clearing the local AI chat history.
void showAiChatClearDialog({required String type}) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: CustomText('Clear Chat',
          fontSize: SizeConfig.size16, fontWeight: FontWeight.w600),
      content: CustomText('Are you sure you want to clear this chat?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: CustomText('Cancel', color: AppColors.grayText),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            await Get.find<ChatViewController>().clearAiChat(type);
            commonSnackBar(message: 'Chat cleared');
          },
          child: CustomText('Clear', color: Colors.red),
        ),
      ],
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
  String? designation,
  bool? isGroupAppBar,
  bool? isGroupPrivate,
  bool? isFromAiChat,
  bool disableCallButton = false,
}) {
  final theme = Theme.of(context);
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();
  // AI chat keeps a locally-personalized name/image/mute state. Resolve (and
  // lazily register) its controller only for the AI variant of this appbar.
  final aiProfileCtrl = (isFromAiChat == true)
      ? (Get.isRegistered<AiChatProfileController>()
          ? Get.find<AiChatProfileController>()
          : Get.put(AiChatProfileController()))
      : null;
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    leadingWidth: 38,
    leading: InkWell(
      onTap: onBackCallback ?? () {
        // Tell server we left this conversation (screenRoom → "online")
        chatViewController.leaveConversation();
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "$socketType"}, );
          bottomBarController.onChangeIndex(2);
          Navigator.popUntil(context, ModalRoute.withName(
              RouteHelper.getBottomNavigationBarScreenRoute()));
          chatViewController.onSelectChatTab(1);
        } else {
          // Use the framework Navigator instead of Get.back(): Get.back()
          // internally calls closeCurrentSnackbar(), which throws a
          // LateInitializationError when a queued snackbar's animation
          // controller hasn't been initialized yet.
          Navigator.pop(context);
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
      onTap: (isFromAiChat == true)
          ? () {
        // Tapping the AI profile lets the user rename it / change its image,
        // stored locally only.
        showAiChatProfileEditSheet(
          context,
          controller: aiProfileCtrl!,
          type: type ?? '',
          defaultName: name,
          defaultImage: profileImage,
        );
      }
          : (type != AppStrings.Admin||type != AppStrings.PersonalChatAi||type != AppStrings.BusinessChatAi)
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
        } else if (socketType == "business") {
          // Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId:  userId ?? ""));
          Get.to(() => VisitProductStoreDetailsScreen(
                visitUserId: userId ?? "",
              ));
        } else {
          _navigateToProfile(authorId: userId ?? '', type: type ?? "");
        }
      }

          : () {},
      child: Row(
        children: [
          // AI chat shows the locally-personalized avatar (reactive); other
          // chats use the avatar passed in from the chat list.
          (isFromAiChat == true)
              ? Obx(() => _chatTitleAvatar(
                    name: aiProfileCtrl!.customName.value.isNotEmpty
                        ? aiProfileCtrl.customName.value
                        : name,
                    profileImage: aiProfileCtrl.customImagePath.value.isNotEmpty
                        ? aiProfileCtrl.customImagePath.value
                        : profileImage,
                    theme: theme,
                  ))
              : _chatTitleAvatar(
                  name: name, profileImage: profileImage, theme: theme),
          SizedBox(width: SizeConfig.size6), // Slightly smaller spacing
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: SizeConfig.size160,
                child: (isFromAiChat == true)
                    ? Obx(() => CustomText(
                          aiProfileCtrl!.customName.value.isNotEmpty
                              ? aiProfileCtrl.customName.value
                              : '${(name == "null") ? (contactNo) : name ?? contactNo}',
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size16,
                        ))
                    : CustomText(
                        '${(name == "null") ? (contactNo) : name ?? contactNo}',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig.size16,
                      ),
              ),
              if(isGroupAppBar == null)
                Row(
                  children: [
                    Obx(() {
                      // Show typing indicator if active
                      if (chatViewController.typingText.value.isNotEmpty) {
                        return CustomText(
                          chatViewController.typingText.value,
                          color: Colors.green,
                          fontSize: SizeConfig.size12,
                        );
                      }

                      final String statusLabel;
                      if (name == "BlueEra Orders") {
                        statusLabel = "BlueCs Ltd";
                      } else if (type != AppStrings.Admin) {
                        if (type == "business") {
                          statusLabel = chatViewController.userOnlineStatus.value == "Online"
                              ? AppStrings.shopOpen.tr
                              : AppStrings.shopClosed.tr;
                        } else if (socketType == "order") {
                          statusLabel = designation ?? '';
                        } else {
                          statusLabel = chatViewController.userOnlineStatus.value;
                        }
                      } else {
                        // Admin/broadcast (BlueEra community) thread: it's a
                        // one-way channel, not a person, so "offline" is
                        // meaningless — label it "Community" instead. The
                        // BlueEra Orders admin thread is handled above.
                        statusLabel = "Community";
                      }
                      return CustomText(
                        statusLabel,
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
            onTap: disableCallButton
                ? null
                : () {
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
              child: Image.asset(
             "assets/images/audio_and_video_call.png",
                width: 24,
                height: 24,

              ),
            )),
      // Language change shortcut — same action as the 3-dot menu's
      // "language" option.
      if(isFromAiChat == true)
        InkWell(
          onTap: () => showAiChatLanguageSheet(context,
              controller: aiProfileCtrl!, type: type ?? ''),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.language,
                color: AppColors.chat_input_icon_color, size: 26),
          ),
        )
      else
        SizedBox(width: SizeConfig.size12),
      if(isFromAiChat == true)
        Obx(() {
          // Read .value synchronously so Obx tracks it and rebuilds the menu
          // icon/labels when the mute state changes.
          final isMuted = aiProfileCtrl!.isMuted.value;
          return PopupMenuButton<String>(
            icon: LocalAssets(
              imagePath: AppIconAssets.chat_info_pop,
              height: 20,
              width: 20,
              imgColor: AppColors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            offset: const Offset(-6, 36),
            color: AppColors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (value) async {
              final t = type ?? '';
              if (value == "mute") {
                await aiProfileCtrl.toggleMute(t);
                commonSnackBar(
                    message: aiProfileCtrl.isMuted.value
                        ? 'Notifications muted'
                        : 'Notifications unmuted');
              } else if (value == "language") {
                showAiChatLanguageSheet(context,
                    controller: aiProfileCtrl, type: t);
              } else if (value == "clear") {
                showAiChatClearDialog(type: t);
              } else if (value == "background") {
                Get.to(() => ChatBackgroundScreen());
              }
            },
            itemBuilder: (context) =>
                PopupMenuBuilders.popupMenuForAiChatOptions(isMuted),
          );
        })
      else if(isGroupAppBar == null)
        PopupMenuButton<String>(
            icon: LocalAssets(
              imagePath: AppIconAssets.chat_info_pop,
              height: 20,
              width: 20,
              imgColor: AppColors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            offset: const Offset(-6, 36),
            color: AppColors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (value) {
              if(value == "clear_chat"){
                // Inquiry lane: a conversation can only be deleted/cleared once
                // it is at least 48h old. Personal chat is exempt.
                if (socketType == AppConstants.business_Chat_Type) {
                  final createdAt = chatViewController
                      .businessConversationCreatedAt(conversationId);
                  if (!chatViewController.isInquiryDeleteUnlocked(createdAt)) {
                    commonSnackBar(
                        message:
                            "This inquiry chat can only be deleted after 48 hours.");
                    return;
                  }
                }
                showDeleteChatDialog(conversationId ?? '');
              } else if(value == "report"){
                // TODO: Handle report
              } else if(value == "block"){
                // TODO: Handle block
              } else if(value == "media_docs"){
                Get.to(() => ConversationMediaPage(
                  conversationId: conversationId ?? '',
                  contactName: name ?? AppStrings.chat.tr,
                  initialTab: 0,
                ));
              } else if(value == "chat_theme"){
                Get.to(() => ChatBackgroundScreen());
              } else if(value == "add_shortcut"){
                ChatShortcutService.createChatShortcut(
                  conversationId: conversationId ?? '',
                  name: name ?? AppStrings.chat.tr,
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
              if(value == "group_info"){
                Get.to(() => ViewGroupMembers(
                      conversationId: conversationId,
                      type: type,
                    ));
              } else if(value == "clear_chat"){
                showDeleteChatDialog(conversationId ?? '');
              } else if(value == "background_change"){
                Get.to(() => ChatBackgroundScreen());
              } else if(value == "exit_group"){
                showExitGroupDialog(conversationId ?? '');
              } else if(value == "pin_group"){
                // Pin/unpin from the conversation list.
                final pinCtrl = Get.isRegistered<ChatPinArchiveController>()
                    ? Get.find<ChatPinArchiveController>()
                    : Get.put(ChatPinArchiveController());
                pinCtrl.togglePin(conversationId ?? '');
                commonSnackBar(message: "Group pin updated");
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

/// Confirmation before leaving a group. Backend leave endpoint is not yet
/// wired, so on confirm we clear the local conversation view and return the
/// user to the chat list. Replace the body of [onConfirm] with the REST/socket
/// call once `chat-service/group/leave` lands.
void showExitGroupDialog(String conId) {
  final chatViewController = Get.find<ChatViewController>();
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.logout, color: AppColors.red, size: 22),
                const SizedBox(width: 8),
                CustomText(
                  "Exit Group",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomText(
              "Are you sure you want to exit this group? You will no longer receive messages from it.",
              fontSize: 14,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    onTap: () => Get.back(),
                    title: AppStrings.cancel.tr,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomBtn(
                    isValidate: true,
                    bgColor: AppColors.red,
                    textColor: AppColors.white,
                    onTap: () {
                      Get.back();
                      chatViewController.leaveConversation();
                      chatViewController.emitEvent(
                          ChatEmitEvents.ChatList, {ApiKeys.type: "group"});
                      // Pop back to the chat list (group info + chat screen).
                      Get.until((route) => route.isFirst ||
                          route.settings.name ==
                              RouteHelper.getBottomNavigationBarScreenRoute());
                      commonSnackBar(message: "You exited the group");
                    },
                    title: "Exit",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

PreferredSize getChatOptionsAppBar(BuildContext context, {
   String? userId,
   String? conversationId,
   TextEditingController? editingController,
  String? profileImage,
  bool? isFromAiChat,
  /// Inquiry (business) lane only: block deleting messages newer than 48h.
  bool restrictDeleteWithin48h = false,
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
            // Inquiry lane: messages can only be deleted after 48 hours. Block
            // if any selected message is still inside the lock window.
            if (restrictDeleteWithin48h) {
              final blocked = chatThemeController.selectedMessages.any(
                  (m) => !chatViewController.isInquiryDeleteUnlocked(m.createdAt));
              if (blocked) {
                commonSnackBar(
                    message:
                        "Inquiry messages can only be deleted after 48 hours.");
                return;
              }
            }
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
                          OrderMainChatScreen(
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
    throw AppStrings.couldNotLaunchDialer.tr;
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
      backgroundColor: Colors.transparent,
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
                  AppStrings.messageLabel.tr,
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
                hintText: AppStrings.typeYourMessage.tr,
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
                    AppStrings.close.tr,
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
                    AppStrings.editLabel.tr,
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
              AppStrings.enterOtp.tr,
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
                      "${AppStrings.wrongOtp.tr} ",
                      color: Colors.red, fontSize: SizeConfig.size12
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CustomText(
                      AppStrings.reEnter.tr,

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
          onTap: () {}, title: AppStrings.submit.tr);
    });
  }
}
