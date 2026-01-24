import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/timing_controller.dart';

class TimingScreen extends StatelessWidget {
  const TimingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TimingController());

    return Scaffold(
      appBar: CommonBackAppBar(title: "Timing",),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set your Availability",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Obx(() => Column(
                children: List.generate(controller.timingList.length, (index) {
                  final dayTiming = controller.timingList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      children: [
                        // Day Name
                        SizedBox(
                          width: 100,
                          child: Text(
                            dayTiming.day,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        
                        // Toggle
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: dayTiming.isOpen.value,
                            onChanged: (val) => controller.toggleDay(index, val),
                            activeColor: Colors.white,
                            activeTrackColor: AppColors.primaryColor, // Google Blue
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Status Text or Time Pickers
                        Expanded(
                          child: dayTiming.isOpen.value
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      "Open",
                                      color: AppColors.secondaryTextColor,
                                      fontSize: SizeConfig.size12,
                                    ),
                                    const Spacer(),
                                    _buildDropdown(
                                      controller.timeSlots, 
                                      dayTiming.openTime.value, 
                                      (val) => controller.updateTime(index, val!, true)
                                    ),
                                    const SizedBox(width: 8),
                                    _buildDropdown(
                                      controller.timeSlots, 
                                      dayTiming.closeTime.value, 
                                      (val) => controller.updateTime(index, val!, false)
                                    ),
                                  ],
                                )
                              : const Text(
                                  "Closed",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              )),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4), // Blue color from screenshot
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue, Function(String?) onChanged) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
