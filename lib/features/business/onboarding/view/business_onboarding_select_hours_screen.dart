import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessOnboardingSelectHoursScreen extends StatelessWidget {
  BusinessOnboardingSelectHoursScreen({super.key});

  final controller = getOrPut(() => BusinessOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CommonBackAppBar(
        isLeading: true,
        title: 'Select hours',
        isShadowShow: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
              child: Column(
                children: BusinessOnboardingController.weekDays
                    .map((d) => _DayRow(
                          day: d,
                          controller: controller,
                        ))
                    .toList(),
              ),
            ),
          ),
          _bottomButton(),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final canProceed = controller.canProceedFromSelectHours;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              bgColor: canProceed
                  ? AppColors.mainTextColor
                  : AppColors.whiteF3,
              textColor:
                  canProceed ? AppColors.white : AppColors.grey9B,
              title: 'Next',
              onTap: canProceed
                  ? () => Get.toNamed(
                      RouteHelper
                          .getBusinessOnboardingPhotoScreenRoute())
                  : null,
            );
          }),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final BusinessOnboardingController controller;

  const _DayRow({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.dayOpen[day] == true;
      final slots = controller.daySlots[day] ?? const [];

      return Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.greyE5, width: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: isOpen && slots.isNotEmpty
                      ? Row(
                          children: [
                            _timeBox(
                              context,
                              label: 'Open',
                              time: slots[0].start,
                              onTap: () => _pick(context, 0, true),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size6),
                              child: CustomText('-',
                                  color: AppColors.mainTextColor),
                            ),
                            _timeBox(
                              context,
                              label: 'Close',
                              time: slots[0].end,
                              onTap: () => _pick(context, 0, false),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              day,
                              fontSize: SizeConfig.large,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              'Closed',
                              fontSize: SizeConfig.medium,
                              color: AppColors.grey9B,
                            ),
                          ],
                        ),
                ),
                CustomSwitch(
                  value: isOpen,
                  onChanged: (v) => controller.toggleDayOpen(day, v),
                  containerHeight: SizeConfig.size24,
                  containerWidth: SizeConfig.size50,
                  circleSize: SizeConfig.size18,
                ),
              ],
            ),
            if (isOpen) ...[
              SizedBox(height: SizeConfig.size4),
              CustomText(
                day,
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
              ),
              for (int i = 1; i < slots.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size8),
                  child: Row(
                    children: [
                      _timeBox(
                        context,
                        label: 'Open',
                        time: slots[i].start,
                        onTap: () => _pick(context, i, true),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size6),
                        child: CustomText('-',
                            color: AppColors.mainTextColor),
                      ),
                      _timeBox(
                        context,
                        label: 'Close',
                        time: slots[i].end,
                        onTap: () => _pick(context, i, false),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => controller.removeSlot(day, i),
                        child: Icon(
                          Icons.close,
                          size: SizeConfig.size18,
                          color: AppColors.grey9B,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: SizeConfig.size8),
              InkWell(
                onTap: () => controller.addSlot(day),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: SizeConfig.size4),
                  child: Row(
                    children: [
                      Icon(Icons.add,
                          size: SizeConfig.size18,
                          color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        'Add a set of hours',
                        fontSize: SizeConfig.medium,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _timeBox(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(SizeConfig.size8),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyE5),
          borderRadius: BorderRadius.circular(SizeConfig.size8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.grey9B,
            ),
            SizedBox(height: SizeConfig.size2),
            CustomText(
              _format(time),
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, int slotIndex, bool isStart) async {
    final slots = controller.daySlots[day] ?? const [];
    if (slotIndex < 0 || slotIndex >= slots.length) return;
    final initial = isStart ? slots[slotIndex].start : slots[slotIndex].end;
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    controller.setSlotTime(
      day,
      slotIndex,
      start: isStart ? picked : null,
      end: isStart ? null : picked,
    );
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
