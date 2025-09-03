import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/local_assets.dart';
import 'chat_input_box.dart';


class ChatBottomSheet extends StatelessWidget {
  const ChatBottomSheet({required this.userId,required this.conversationId});
 final String userId;
 final String conversationId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          height: 500,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.appBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 65,
                color: AppColors.appBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        CustomText(
                          "223 Comments",
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,

                        ),
                      ],
                    ).paddingOnly(left: 50),
                    const Spacer(),
                    InkWell(
                      onTap: Get.back,
                      child: Container(
                        height: 30,
                        width: 30,
                        margin: const EdgeInsets.only(right: 20),
                        child: Center(
                          child:
                          LocalAssets(imagePath: AppIconAssets.close_black),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    buildComment(username: "enzetto", text: "Nice one!", time: "13m", isCreator: true, likes: 10, liked: true),
                    buildComment(username: "cat_yay", text: "Love this ❤️", time: "30m", likes: 120),
                    buildComment(username: "allyoucaneat", text: "Great 👍 #epicness", time: "1h", likes: 1),
                    buildComment(username: "allyoucaneat", text: "Nice!! #epicness", time: "1h", likes: 12),
                    buildComment(username: "allyoucaneat", text: "@allyoucaneat Great #epicness", time: "1h", likes: 12000),
                  ],
                ),
              ),
          ChatInputBar(
            isInitialMessage: false,
            userId: userId,
            conversationId: conversationId,
          ),
              const SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
  Widget buildComment({
    required String username,
    required String text,
    required String time,
    bool isCreator = false,
    bool liked = false,
    int likes = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isCreator)
                      const Text(" (Creator)", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Text(text),
                Row(
                  children: [
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Text("Reply", style: TextStyle(fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Column(
            children: [
              Icon(liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.red : Colors.grey, size: 20),
              if (likes > 0)
                Text(likes.toString(), style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

}