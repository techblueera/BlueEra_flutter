
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/reminder_chat_list_model.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../widget/component_widgets.dart';
import '../widget/reminder_view_page.dart';

class ReminderChatList extends StatefulWidget {
  const ReminderChatList({super.key});



  @override
  State<ReminderChatList> createState() => _ReminderChatListState();
}

class _ReminderChatListState extends State<ReminderChatList> {
  final chatThemeController = Get.find<ChatThemeController>();
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatThemeController.getReminderChatListData();
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatThemeController.getListOfReminderMsgResponse.value.status ==
          Status.COMPLETE) {
        List<ReminderChatListModel>? members = chatThemeController.reminderChatList;

        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20),
                  topRight:  Radius.circular(20)),
            ),
            padding: EdgeInsets.symmetric(vertical: 8),
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                (members.isEmpty )
                    ? Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: noChatsFound(true),
                )
                    : ListView.builder(
                  itemCount: members.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final chat =members[index];
                    String senderProfileImage=chat.profileImagePath;
                    String senderName=chat.name;
                    return  Dismissible(
                      key: ValueKey(chat.conversationId),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_off_rounded,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppStrings.removeAllReminders.tr,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              "${AppStrings.removeAllRemindersConfirm.tr} $senderName?",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(AppStrings.cancel.tr,
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(AppStrings.removeLabel.tr,
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await chatThemeController
                              .deleteAllRemindersForConversation(
                                  chat.conversationId);
                        }
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.removeLabel.tr,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: InkWell(
                      onTap: (){
                        Get.to(()=>ReminderViewPage(
                          name: senderName,
                          profileImagePath: senderProfileImage,
                          conversationId: chat.conversationId,
                        ));
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: SizeConfig.size16,
                          left: SizeConfig.size16,
                          top: SizeConfig.size12,
                          bottom: SizeConfig.size12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(

                              child: Container(

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: AppColors.white,
                                ),
                                child: Padding(
                                  padding:  EdgeInsets.all(0),
                                  child: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary,
                                    radius: SizeConfig.size20,
                                    child:  (senderProfileImage.isNotEmpty)
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
                                        senderName,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: SizeConfig.size18,
                                      ),
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
                                    "${(senderName == "null")
                                        ? ""
                                        : senderName}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: SizeConfig.size16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: SizeConfig.size2),
                                  CustomText(
                                    maxLines: 1,
                                    AppStrings.reminderMessageLabel.tr,
                                    fontSize: SizeConfig.size14,
                                    color: AppColors.grey9A,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CustomText(
                                  "${formatTimeFromUtc(chat.updatedAt??"")}",
                                  fontSize: SizeConfig.size11,
                                  color: AppColors.grey9A,
                                ),
                                SizedBox(height: SizeConfig.size6),
                                CircleAvatar(
                                  radius: SizeConfig.size12,
                                  backgroundColor: Colors.lightBlue,
                                  child: CustomText(
                                    "${chat.messageCount}",
                                    color: AppColors.white,
                                    fontSize: SizeConfig.size12,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }

  String formatTimeFromUtc(String utcString) {
    DateTime utcDate = DateTime.parse(utcString);
    DateTime localDate = utcDate.toLocal();
    String formattedTime = DateFormat.jm().format(localDate); // e.g. 9:52 PM
    return formattedTime;
  }
}
