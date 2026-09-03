import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/option_picker_sheet.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import '../controller/timing_controller.dart';

class TimingScreen extends StatelessWidget {
   TimingScreen({Key? key}) : super(key: key);
  final controller = Get.put(AutomotiveTimingController());

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherTimingTitle.tr,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.setYourAvailability.tr,
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                    return Column(
                      children: [
                        Padding(
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
                                    AppStrings.otherOpen.tr,
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size12,
                                  )
                                      : CustomText(
                                    AppStrings.otherClosed.tr,
                                    color: AppColors.mainTextColor,
                                  ),

                                ],
                              ),

                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        if (dayTiming.isOpen.value) ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              
                              _buildDropdown(
                                  context,
                                  controller.timeSlots,
                                  dayTiming.openTime.value,
                                      (val) => controller.updateTime(
                                      index, val!, true)),
                              const SizedBox(width: 8),
                              _buildDropdown(
                                  context,
                                  controller.timeSlots,
                                  dayTiming.closeTime.value,
                                      (val) => controller.updateTime(
                                      index, val!, false)),
                            ],
                          ),

                        ]

                      ],
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
                        : CustomText(
                            AppStrings.submit.tr,
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

  /// A time field: the chosen value, tapped to pick from the list.
  ///
  /// A sheet rather than a `DropdownButton` — 7 days × 2 fields × 48 slots is
  /// 672 rows a DropdownButton would build and lay out before this screen could
  /// paint. See [showOptionPickerSheet].
  Widget _buildDropdown(BuildContext context, List<String> items,
      String currentValue, Function(String?) onChanged) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final picked = await showOptionPickerSheet<String>(
          context: context,
          title: 'Select time',
          options: items,
          selected: items.contains(currentValue) ? currentValue : null,
          labelOf: (v) => v,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              currentValue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
