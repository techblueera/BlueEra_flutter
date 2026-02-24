import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';

class PinMessageDurationDialog extends StatelessWidget {
  const PinMessageDurationDialog({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final chatViewController = getOrPut(() => ChatViewController());

    final chatThemeController = getOrPut(() => ChatThemeController());

    /// Selected duration in days


    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomText(
              "Choose how long pin lasts",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),

            /// Duration Options
            Column(
              children: [
                _durationTile(
                  title: "One Day",
                  value: 1,
                  groupValue: chatViewController.selectedDays.value,
                  onChanged: (val) =>
                  chatViewController.selectedDays.value = val,
                ),
                _durationTile(
                  title: "7 Days",
                  value: 7,
                  groupValue: chatViewController.selectedDays.value,
                  onChanged: (val) =>
                  chatViewController.selectedDays.value = val,
                ),
                _durationTile(
                  title: "30 Days",
                  value: 30,
                  groupValue: chatViewController.selectedDays.value,
                  onChanged: (val) =>
                  chatViewController.selectedDays.value = val,
                ),
                _durationTile(
                  title: "Life Time",
                  value: 34,
                  groupValue: chatViewController.selectedDays.value,
                  onChanged: (val) =>
                  chatViewController.selectedDays.value = val,
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Buttons
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    onTap: () => Get.back(),
                    title: "Cancel",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomBtn(
                    isLoading:chatViewController.isPinMessageLoading.value,
                    // chatViewController.isPinBtnLoading.value,
                    isValidate: true,
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    onTap: () async {

                      String duration;
                      if(chatViewController.selectedDays.value==1){
                        duration="ONE_DAY";
                      }else if(chatViewController.selectedDays.value==7){
                        duration="SEVEN_DAYS";
                      }
                      else if(chatViewController.selectedDays.value==30){
                        duration="ONE_MONTH";
                      }
                      else{
                        duration="LIFETIME";
                      }

                      Map<String,dynamic> params={
                        ApiKeys.message_id: chatThemeController.selectedId,
                        ApiKeys.conversation_id: conversationId,
                        ApiKeys.duration:duration,
                        ApiKeys.remove_from_pin: false
                      };
                     chatViewController.addToPinMessage(params);
                    },
                    title: "Confirm",
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  /// Reusable Radio Tile
  Widget _durationTile({
    required String title,
    required int value,
    required int groupValue,
    required Function(int) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<int>(
            value: value,
            groupValue: groupValue,
            onChanged: (val) => onChanged(val!),
          ),
          CustomText(title, fontSize: 14),
        ],
      ),
    );
  }
}