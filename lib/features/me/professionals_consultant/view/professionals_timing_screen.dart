import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/option_picker_sheet.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_timing_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsTimingScreen extends StatelessWidget {
  ProfessionalsTimingScreen({Key? key}) : super(key: key);
  final controller = Get.put(ProfessionalsTimingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.proConsultAvailability.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Info Banner ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryColor
                        .withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule,
                      color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      AppStrings.proConsultWeeklyAvailabilityInfo.tr,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Schedule Card ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today,
                              color: AppColors.primaryColor,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              CustomText(AppStrings.proConsultWeeklySchedule.tr,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.medium),
                              const SizedBox(height: 2),
                              CustomText(
                                  AppStrings.proConsultToggleDaysHours.tr,
                                  color:
                                      AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.small),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value &&
                          controller.timingList.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return Column(
                        children: List.generate(
                          controller.timingList.length,
                          (index) {
                            final dayTiming =
                                controller.timingList[index];
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: dayTiming.isOpen.value
                                    ? AppColors.primaryColor
                                        .withValues(alpha: 0.03)
                                    : Colors.grey.shade50,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: dayTiming.isOpen.value
                                      ? AppColors.primaryColor
                                          .withValues(alpha: 0.15)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 55,
                                    child: CustomText(
                                      dayTiming.day.substring(
                                          0,
                                          dayTiming.day.length > 3
                                              ? 3
                                              : dayTiming
                                                  .day.length),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color:
                                          AppColors.mainTextColor,
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value:
                                          dayTiming.isOpen.value,
                                      onChanged: (val) =>
                                          controller.toggleDay(
                                              index, val),
                                      activeColor: Colors.white,
                                      activeTrackColor:
                                          AppColors.primaryColor,
                                      inactiveThumbColor:
                                          Colors.white,
                                      inactiveTrackColor:
                                          Colors.grey.shade300,
                                    ),
                                  ),
                                  if (dayTiming.isOpen.value) ...[
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildDropdown(
                                              context,
                                              controller
                                                  .timeSlots,
                                              dayTiming
                                                  .openTime.value,
                                              (val) => controller
                                                  .updateTime(
                                                      index,
                                                      val!,
                                                      true),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 4),
                                            child: CustomText("-",
                                                color: AppColors
                                                    .secondaryTextColor),
                                          ),
                                          Expanded(
                                            child: _buildDropdown(
                                              context,
                                              controller
                                                  .timeSlots,
                                              dayTiming.closeTime
                                                  .value,
                                              (val) => controller
                                                  .updateTime(
                                                      index,
                                                      val!,
                                                      false),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    CustomText(
                                      AppStrings.proConsultClosed.tr,
                                      color: Colors.red,
                                      fontSize: SizeConfig.small,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Submit ---
            Obx(() => CustomBtn(
                  title: AppStrings.submit.tr,
                  isValidate: !controller.isLoading.value,
                  isLoading: controller.isLoading.value,
                  onTap: controller.isLoading.value
                      ? null
                      : controller.submit,
                )),
            SizedBox(height: SizeConfig.size20),
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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: CustomText(
                currentValue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: AppColors.mainTextColor),
          ],
        ),
      ),
    );
  }
}
