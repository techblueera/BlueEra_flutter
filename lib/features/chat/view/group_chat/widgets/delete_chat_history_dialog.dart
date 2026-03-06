import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';

class DeleteChatHistoryDialog extends StatelessWidget {
  const DeleteChatHistoryDialog({super.key, required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomText(
            "Delete Chat",
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),
          const CustomText(
              "Are you sure you want to delete chat history?",
              textAlign: TextAlign.center,
              fontSize: 14
          ),
          const SizedBox(height: 24),

          /// Buttons Row
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: CustomBtn(onTap: () {
                    Get.back();
                  }, title: "Cancel"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomBtn(
                      isLoading: chatViewController.isDeleteBtnLoading.value,
                      isValidate: true,
                      bgColor: AppColors.red,
                      textColor: AppColors.white,
                      onTap: () async{
                        Map<String,dynamic> params={
                          ApiKeys.conversation_id: conversationId
                        };
                        bool? value=await chatViewController.clearChatHistory(params);
                        if(value!=null&&value){
                          Get.back();
                        }

                      },
                      title: "Delete"),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
