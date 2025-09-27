import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';

Future<void> showHiveBottomSheet(BuildContext context,String userId,String conversationId,bool isInitialFlow) async {
  await Hive.initFlutter();
  var box = await Hive.openBox<String>('myItems');
  final TextEditingController controller = TextEditingController();
  final chatViewController = Get.find<ChatViewController>();
  void addItem() {
    if (controller.text.trim().isNotEmpty) {
      box.add(controller.text.trim());
      controller.clear();
    }
  }
  Future<void> sendMessageToUser(
      {required Map<String, dynamic> data, required bool isInitial, List<
          File>? sendLoadingFiles, String? fileName}) async {
    if (isInitialFlow) {
      chatViewController.sendInitialMessage(data);
    } else {
      chatViewController.sendMessage(data, sendLoadingFiles, fileName);
    }
    Navigator.pop(context);
  }
  List<String> staticGreeting=[
    "Hello! Welcome to our service. How can we assist you today?",
  ];
  showModalBottomSheet(
    useSafeArea: true,
    isDismissible: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.5, // Half screen
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.end,

            children: [
              const CustomText(
                "Quick Replies",
                // style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold
                // ),
              ),
              const SizedBox(height: 12),

              // Show stored items
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (context, Box<String> items, _) {
                    if (items.isEmpty) {
                      return const Center(
                          child: CustomText("No replies yet, add something!"));
                    }
                    return Wrap(
                      verticalDirection: VerticalDirection.down,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: items.values.map((e) {
                        return GestureDetector(onTap: (){

                              Messages? reply = chatViewController.replyMessage
                                  ?.value;
                              Map<String, dynamic> data;
                              if (isInitialFlow) {
                                data = {
                                  ApiKeys.other_user_id: userId,
                                  ApiKeys.message: "${chatViewController
                                      .sendMessageController.value.text}",
                                  ApiKeys.message_type: "text",
                                };
                              } else if (reply?.id != null) {
                                data = {
                                  if(isInitialFlow)
                                    ApiKeys.other_user_id: userId
                                  else
                                    ApiKeys.conversation_id: conversationId,
                                  ApiKeys.message: "${e}",
                                  ApiKeys.reply_id: "${reply?.id}",
                                  ApiKeys.message_type: "text",
                                };
                              } else {
                                data = {
                                  if(isInitialFlow)
                                    ApiKeys.other_user_id: userId
                                  else
                                    ApiKeys.conversation_id: conversationId,
                                  ApiKeys.message: "${e}",
                                  ApiKeys.message_type: "text",
                                };
                              }
                              print('SEND PAYLOAD (text): '+data.toString());
                              sendMessageToUser(
                                  data: data, isInitial: isInitialFlow);

                        },
                          onLongPress: () {
                            // Show confirmation popup
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete"),
                                content: Text("Do you want to delete \"$e\"?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final key = items.keys.firstWhere(
                                            (k) => items.get(k) == e,
                                        orElse: () => null,
                                      );
                                      if (key != null) items.delete(key);
                                      Navigator.pop(context);
                                    },
                                    child:  CustomText(
                                      "Delete",
                                     color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Chip(
                            label: Text(e),
                            backgroundColor: Colors.blue.shade100,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),


               Divider(
                color: AppColors.greyA5.withOpacity(0.3),
              ),

              // Input + Plus Button
              Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  CustomText("Greeting Message",fontSize: 14,fontWeight: FontWeight.w600,),
                  Wrap(
                    verticalDirection: VerticalDirection.down,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: staticGreeting.map((e) {
                      return GestureDetector(onTap: (){

                        Messages? reply = chatViewController.replyMessage
                            ?.value;
                        Map<String, dynamic> data;
                        if (isInitialFlow) {
                          data = {
                            ApiKeys.other_user_id: userId,
                            ApiKeys.message: "${chatViewController
                                .sendMessageController.value.text}",
                            ApiKeys.message_type: "text",
                          };
                        } else if (reply?.id != null) {
                          data = {
                            if(isInitialFlow)
                              ApiKeys.other_user_id: userId
                            else
                              ApiKeys.conversation_id: conversationId,
                            ApiKeys.message: "${e}",
                            ApiKeys.reply_id: "${reply?.id}",
                            ApiKeys.message_type: "text",
                          };
                        } else {
                          data = {
                            if(isInitialFlow)
                              ApiKeys.other_user_id: userId
                            else
                              ApiKeys.conversation_id: conversationId,
                            ApiKeys.message: "${e}",
                            ApiKeys.message_type: "text",
                          };
                        }
                        print('SEND PAYLOAD (text): '+data.toString());
                        sendMessageToUser(
                            data: data, isInitial: isInitialFlow);

                      },

                        child: Chip(
                          label: Text(e),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Enter your message...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: addItem,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
