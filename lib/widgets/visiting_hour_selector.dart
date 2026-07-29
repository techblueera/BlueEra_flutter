import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Weekly open/closed + hours picker.
///
/// Laid out as one block per day, stacked in TWO rows rather than one:
///
/// ```
///   Monday                        Open  [switch]
///   [ 10:00 AM ▾ ]  to  [ 11:00 PM ▾ ]        ⧉
/// ```
///
/// The previous single-row layout put the day name in a `Flexible` beside a
/// `FittedBox` holding the switch, status label, both dropdowns and the
/// copy action. Because the `FittedBox` claimed its full intrinsic width
/// first, the day name was squeezed to a few pixels — often invisible — and
/// the controls were scaled down until unreadable on narrow screens.
///
/// Splitting the rows gives the day name the full width and lets the time
/// dropdowns share the second row via `Expanded`, so nothing overflows and
/// nothing shrinks, at any screen size or text scale.
class VisitingHoursSelector extends StatelessWidget {
  final controller = getOrPut(() => VisitingHoursSelectorController());

  VisitingHoursSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final days = controller.visitingHours.keys.toList();
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
          color: AppColors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < days.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: AppColors.greyE5),
              _DayRow(
                day: days[i],
                controller: controller,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final VisitingHoursSelectorController controller;

  const _DayRow({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.visitingHours[day] ?? false;
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: day name (takes the room it needs) + status + switch ──
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    day,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                // statusOpen/statusClosed, not `open`/`closed`: the latter
                // translate to the imperative verb in gu/mr/kn ("ખોલો" =
                // *open it*), which reads wrong as a state label.
                CustomText(
                  isOpen
                      ? AppStrings.statusOpen.tr
                      : AppStrings.statusClosed.tr,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? AppColors.greenShade : AppColors.grey83,
                ),
                SizedBox(width: SizeConfig.size8),
                CustomSwitch(
                  value: isOpen,
                  onChanged: (val) => controller.toggleDayStatus(day, val),
                  containerHeight: SizeConfig.size24,
                  containerWidth: SizeConfig.size44,
                  circleSize: SizeConfig.size18,
                ),
              ],
            ),
            // ── Row 2: the two time pickers, only while the day is open ──
            if (isOpen) ...[
              SizedBox(height: SizeConfig.size10),
              Row(
                children: [
                  Expanded(child: _TimeBox(day: day, isStart: true, controller: controller)),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                    child: CustomText(
                      AppStrings.toSeparator.tr,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Expanded(child: _TimeBox(day: day, isStart: false, controller: controller)),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// One time dropdown. Sized by its parent [Expanded] rather than its content,
/// so a long 12-hour label ("10:30 AM") can never push the row over.
class _TimeBox extends StatelessWidget {
  final String day;
  final bool isStart;
  final VisitingHoursSelectorController controller;

  const _TimeBox({
    required this.day,
    required this.isStart,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedTime = isStart
          ? (controller.startTimes[day] ?? const TimeOfDay(hour: 10, minute: 0))
          : (controller.endTimes[day] ?? const TimeOfDay(hour: 23, minute: 0));

      final timeOptions = controller.generateTimeList();
      final selectedString = controller.formatTime(selectedTime);
      final validValue = timeOptions.contains(selectedString)
          ? selectedString
          : timeOptions.first;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: DropdownButton<String>(
          value: validValue,
          isDense: true,
          // isExpanded lets the button shrink to the Expanded width instead
          // of demanding its widest item's width, which is what used to force
          // the whole row to overflow.
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: SizeConfig.size18,
            color: AppColors.secondaryTextColor,
          ),
          dropdownColor: AppColors.white,
          underline: const SizedBox(),
          style: TextStyle(
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
          ),
          items: timeOptions
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: CustomText(
                    controller.to12HourLabel(t),
                    fontSize: SizeConfig.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            final parts = val.split(':');
            final newTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            isStart
                ? controller.updateStartTime(day, newTime)
                : controller.updateEndTime(day, newTime);
          },
        ),
      );
    });
  }
}

