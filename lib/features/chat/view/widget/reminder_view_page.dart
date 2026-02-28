import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../widget/chat_input_box.dart';
import '../widget/message_card.dart';

class ReminderViewPage extends StatefulWidget {
  const ReminderViewPage({super.key,required this.conversationId,required this.name,required this.profileImagePath});
  final conversationId;
  final name;
  final profileImagePath;


  @override
  State<ReminderViewPage> createState() => _ReminderViewPageState();
}

class _ReminderViewPageState extends State<ReminderViewPage> {

  final chatThemeController = Get.find<ChatThemeController>();

  @override
  void initState() {
    chatThemeController.getMessageListByConId(widget.conversationId);
    super.initState();
  }
  Map<String, List<dynamic>> groupMessagesByTime(List<dynamic> messages) {
    Map<String, List<dynamic>> grouped = {};

    for (var msg in messages) {
      final time = msg.reminderTime ?? "";

      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }

      grouped[time]!.add(msg);
    }

    return grouped;
  }
  @override
  Widget build(BuildContext context) {

    return  Scaffold(
      appBar: CommonBackAppBar(
      title: widget.name,
      ),
      body: Obx(() {
        if (chatThemeController.getListOfReminderMsgResponse.value.status ==
            Status.COMPLETE) {
          List<ReminderMessage> messages =
              chatThemeController.reminderMessageModel ?? [];
          messages.sort((a, b) {
            final dateA = (a.message.createdAt != null && a.message.createdAt!.isNotEmpty)
                ? DateTime.parse(a.message.createdAt!).toLocal()
                : DateTime.fromMillisecondsSinceEpoch(0);

            final dateB = (b.message.createdAt != null && b.message.createdAt!.isNotEmpty)
                ? DateTime.parse(b.message.createdAt!).toLocal()
                : DateTime.fromMillisecondsSinceEpoch(0);

            return dateA.compareTo(dateB); // descending
          });
          final groupedMessages = groupMessagesByTime(messages);
          return  Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppImageAssets.chating_bg,
                fit: BoxFit.cover,
                width: SizeConfig.screenWidth,
                height: SizeConfig.screenHeight,
              ),
              Column(
                children: [
                  Expanded(
                    child: (messages.isEmpty)
                        ? Center(
                      child: CustomText("No Reminder Message yet"),
                    )
                        : LayoutBuilder(
                      builder: (context, constraints) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,

                                reverse: true,
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: groupedMessages.entries.map((entry) {
                                        final reminderTime = entry.key;
                                        final timeMessages = entry.value;

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            /// 🔵 Reminder Time Header (shown once per group)
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                color: chatThemeController.myMessageBgColor.value.withOpacity(0.13),
                                              ),
                                              margin: const EdgeInsets.only(top: 6, bottom: 4),
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  CustomText(
                                                    reminderTime,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            /// 📨 Messages under same time
                                            ...timeMessages.map((message) {
                                              return MessageCard(isFromAiMessage: true,
                                                message: message.message,
                                                isInitialMessage: false,
                                                conversationId: message.message.conversationId,
                                                userId: message.message.sender?.id,
                                                name: message.message.sender?.name,
                                                contactNo: message.message.sender?.contactNo,
                                                profileImage: message.message.sender?.profileImage,
                                              );
                                            }).toList(),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                    // if(chatThemeController.isMessageSelectionActive.value)
                                    //   Container(
                                    //     decoration: BoxDecoration(
                                    //       borderRadius: BorderRadius.circular(10),
                                    //       color: AppColors.lightBlueShade.withOpacity(0.2),
                                    //     ),
                                    //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    //     child: Row(
                                    //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    //       children: [
                                    //
                                    //         /// Reminder
                                    //         ChatActionButton(
                                    //           title: "Change Reminder",
                                    //           iconPath: AppIconAssets.clock_new,
                                    //           onTap: () {
                                    //             showModalBottomSheet(
                                    //               context: context,
                                    //               isScrollControlled: true,
                                    //               backgroundColor: Colors.transparent,
                                    //               builder: (context) =>  ReminderBottomSheet(
                                    //                 profileImagePath: widget.profileImagePath,
                                    //                 conversationId: widget.conversationId,
                                    //                 name: widget.name,
                                    //               ),
                                    //             );
                                    //           },
                                    //         ),
                                    //         ChatActionButton(
                                    //           title: "Remove From Reminder",
                                    //           iconPath: AppIconAssets.clock_new,
                                    //           onTap: () {
                                    //             // chatThemeController.removeSelectedReminderMessages();
                                    //           },
                                    //         ),
                                    //
                                    //
                                    //       ],
                                    //     ),
                                    //   ),
                                    SizedBox(height: 8,)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ChatInputBar(
                    isInitialMessage: false,
                    hideMedia: true,
                    conversationId: widget.conversationId ?? '',
                  ),
                  SizedBox(height: 30,),
                ],
              ),
            ],
          );
        } else {
          return SafeArea(
              child:   Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(),
                ),
              ));
        }
      }),
    );
  }
}
