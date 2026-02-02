import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import '../controller/timing_controller.dart';

class TimingScreen extends StatelessWidget {
   TimingScreen({Key? key}) : super(key: key);
  final controller = Get.put(TimingController());

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Timing",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              "Set your Availability",
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
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
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.timingList.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                return Column(
                  children:
                      List.generate(controller.timingList.length, (index) {
                    final dayTiming = controller.timingList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Day Name
                          SizedBox(
                            width: 80,
                            child: CustomText(
                              dayTiming.day,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mainTextColor,
                            ),
                          ),

                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: dayTiming.isOpen.value,
                                  onChanged: (val) =>
                                      controller.toggleDay(index, val),
                                  activeColor: Colors.white,
                                  activeTrackColor: AppColors.primaryColor,
                                  // Google Blue
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.grey.shade300,
                                ),
                              ),
                              // Status Text or Time Pickers
                              dayTiming.isOpen.value
                                  ? CustomText(
                                "Open",
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.size12,
                              )
                                  : const CustomText(
                                "Closed",
                                color: AppColors.mainTextColor,
                              ),

                              if (dayTiming.isOpen.value) ...[
                                SizedBox(
                                  width: 10,
                                ),
                                _buildDropdown(
                                    controller.timeSlots,
                                    dayTiming.openTime.value,
                                        (val) => controller.updateTime(
                                        index, val!, true)),
                                const SizedBox(width: 8),
                                _buildDropdown(
                                    controller.timeSlots,
                                    dayTiming.closeTime.value,
                                        (val) => controller.updateTime(
                                        index, val!, false)),
                              ]
                            ],
                          ),

                          const SizedBox(width: 8),
                        ],
                      ),
                    );
                  }),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                    onPressed:
                        controller.isLoading.value ? null : controller.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      // Blue color from screenshot
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const CustomText(
                            "Submit",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String currentValue, Function(String?) onChanged) {
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
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.mainTextColor,
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: CustomText(
                value,
                fontSize: 12,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
