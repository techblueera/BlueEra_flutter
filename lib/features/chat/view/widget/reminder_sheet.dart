import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';

class ReminderBottomSheet extends StatefulWidget {
  const ReminderBottomSheet({super.key,required this.conversationId,required this.name,required this.profileImagePath});
  final conversationId;
  final name;
  final profileImagePath;
  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  String? selectedOption;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final chatThemeController = getOrPut(() => ChatThemeController());

  final List<String> quickOptions = [
    "1 Day",
    "2 Hours Later",
    "2 Days",
    "4 Hours Later",
    "1 Week",
    "6 Hours Later",
  ];

  String _localizedOption(String option) {
    switch (option) {
      case "1 Day": return AppStrings.oneDayOption.tr;
      case "2 Hours Later": return AppStrings.twoHoursLater.tr;
      case "2 Days": return AppStrings.twoDays.tr;
      case "4 Hours Later": return AppStrings.fourHoursLater.tr;
      case "1 Week": return AppStrings.oneWeek.tr;
      case "6 Hours Later": return AppStrings.sixHoursLater.tr;
      default: return option;
    }
  }
  void applyQuickOption(String option) {
    final now = DateTime.now();
    DateTime updatedDateTime = now;

    switch (option) {
      case "1 Day":
        updatedDateTime = now.add(const Duration(days: 1));
        break;

      case "2 Days":
        updatedDateTime = now.add(const Duration(days: 2));
        break;

      case "1 Week":
        updatedDateTime = now.add(const Duration(days: 7));
        break;

      case "2 Hours Later":
        updatedDateTime = now.add(const Duration(hours: 2));
        break;

      case "4 Hours Later":
        updatedDateTime = now.add(const Duration(hours: 4));
        break;

      case "6 Hours Later":
        updatedDateTime = now.add(const Duration(hours: 6));
        break;
    }

    setState(() {
      selectedDate = DateTime(
        updatedDateTime.year,
        updatedDateTime.month,
        updatedDateTime.day,
      );

      selectedTime = TimeOfDay(
        hour: updatedDateTime.hour,
        minute: updatedDateTime.minute,
      );
    });
  }
  String formatReminderDateTime(
      ) {
    // Combine Date + Time into one DateTime
    final DateTime combinedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Format: 12/02/2026 - 12:04 PM
    final String formatted =
    DateFormat('dd/MM/yyyy - hh:mm a').format(combinedDateTime);

    return formatted;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                AppStrings.quickReminder.tr,
               fontSize: 16, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            /// Radio Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5,
              ),
              itemBuilder: (context, index) {
                final option = quickOptions[index];
                return RadioListTile<String>(hoverColor: AppColors.secondaryTextColor,
                  // activeColor: AppColors.secondaryTextColor,
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (val) {
                    setState(() => selectedOption = val);
                    applyQuickOption(val!);
                  },
                  title: CustomText(_localizedOption(option),
                      fontSize: 14,
                  color: AppColors.secondaryTextColor,),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              },
            ),

            const SizedBox(height: 20),

            /// OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade400)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomText(AppStrings.orLabel.tr,color: Colors.grey)
                ),
                Expanded(child: Divider(color: Colors.grey.shade400)),
              ],
            ),

            const SizedBox(height: 20),

            /// Schedule Title
            Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                AppStrings.scheduleReminder.tr,
               fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            /// Date & Time Row
            Row(
              children: [
                /// Date Picker
                Expanded(
                  child: _buildPickerBox(
                    text: DateFormat("dd/MM/yyyy").format(selectedDate),
                    icon: Icons.calendar_today,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                /// Hour Box
                Expanded(
                  child: _buildPickerBox(
                    text: "${formatRailwayTime(selectedTime)}",
                    onTap: _pickTime,
                  ),
                ),
                const SizedBox(width: 10),

                /// Minute Box
                Expanded(
                  child: _buildPickerBox(
                    text:
                    "${selectedTime.minute.toString().padLeft(2, '0')} min",
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Notify Button
          CustomBtn(
              isValidate: true,
              onTap: ()async{
                bool? value= await chatThemeController.setReminderApiCall({
                  if(selectedOption==null)
                  ApiKeys.reminder_time: getIsoReminderDateTime(),
                  if(selectedOption!=null)
                  ApiKeys.quick_option: selectedOption??""
                });
                if(value!=null&&value){
                  chatThemeController.saveReminderData(
                    conversationId: widget.conversationId,
                    name: widget.name,
                    profileImagePath:  widget.profileImagePath,
                    reminderTime: selectedOption==null?formatReminderDateTime():selectedOption!,
                  );
                }

               }, title: AppStrings.notifyMe.tr),
          ],
        ),
      ),
    );
  }
  String getIsoReminderDateTime() {
    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
    );

    // Convert to UTC and return ISO format like: 2026-02-28T07:21:31.432Z
    return combined.toUtc().toIso8601String();
  }
  String formatRailwayTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0'); // 00–23

    return "$hour Hr"; // e.g., 18:05
  }
  Widget _buildPickerBox({
    required String text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.whiteE5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color:AppColors.secondaryTextColor),
              const SizedBox(width: 6),
            ],
            CustomText(
              text,
             fontSize: 14, color: AppColors.secondaryTextColor
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _pickTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

}