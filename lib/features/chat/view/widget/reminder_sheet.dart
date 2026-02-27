import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            const Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                "Quick Reminder",
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
                  },
                  title: CustomText(option,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: CustomText("Or",color: Colors.grey)
                ),
                Expanded(child: Divider(color: Colors.grey.shade400)),
              ],
            ),

            const SizedBox(height: 20),

            /// Schedule Title
            const Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                "Schedule Reminder",
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
              onTap: (){
                chatThemeController.saveReminderData(
                    conversationId: widget.conversationId,
                    name: widget.name,
                    profileImagePath:  widget.profileImagePath,
                  reminderTime: selectedOption==null?formatReminderDateTime():selectedOption!,
                );
               }, title: "Notify Me"),
          ],
        ),
      ),
    );
  }

  String formatRailwayTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0'); // 00–23
    final minute = time.minute.toString().padLeft(2, '0');

    return "$hour:$minute"; // e.g., 18:05
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
      initialEntryMode: TimePickerEntryMode.input,

    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

}