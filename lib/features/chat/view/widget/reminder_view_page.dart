import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
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

  void _showRemoveConfirmation(ReminderMessage reminderMsg) {
    showDialog(
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
            const Expanded(
              child: Text(
                "Remove Reminder",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to remove this message from reminders?",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeReminder(reminderMsg);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeReminder(ReminderMessage reminderMsg) {
    final messageId = reminderMsg.message.id ?? '';
    if (messageId.isEmpty) return;

    chatThemeController.deleteReminderMessage(
      conversationId: widget.conversationId,
      messageId: messageId,
    ).then((_) {
      // If all messages removed, go back to the list
      if (chatThemeController.reminderMessageModel.isEmpty) {
        Get.back();
      }
    });
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
              chatThemeController.reminderMessageModel;
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
              Obx(() => chatThemeController.chatBackground()),
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
                                            /// Reminder Time Header (shown once per group)
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

                                            /// Messages under same time — swipe left to remove
                                            ...timeMessages.map((message) {
                                              final reminderMsg = message as ReminderMessage;
                                              return Dismissible(
                                                key: ValueKey(
                                                    reminderMsg.message.id ??
                                                        UniqueKey().toString()),
                                                direction:
                                                    DismissDirection.endToStart,
                                                confirmDismiss: (_) async {
                                                  _showRemoveConfirmation(
                                                      reminderMsg);
                                                  return false;
                                                },
                                                background: Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 20),
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .notifications_off_rounded,
                                                        color: Colors.red,
                                                        size: 22,
                                                      ),
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        "Remove",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                child: MessageCard(
                                                  isFromAiMessage: true,
                                                  message:
                                                      reminderMsg.message,
                                                  isInitialMessage: false,
                                                  conversationId: reminderMsg
                                                      .message
                                                      .conversationId,
                                                  userId: reminderMsg
                                                      .message.sender?.id,
                                                  name: reminderMsg
                                                      .message.sender?.name,
                                                  contactNo: reminderMsg
                                                      .message
                                                      .sender
                                                      ?.contactNo,
                                                  profileImage: reminderMsg
                                                      .message
                                                      .sender
                                                      ?.profileImage,
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        );
                                      }).toList(),
                                    ),
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
