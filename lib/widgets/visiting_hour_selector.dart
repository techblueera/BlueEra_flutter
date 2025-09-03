import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VisitingHoursSelector extends StatelessWidget {
  final VisitingHoursSelectorController controller = Get.put(VisitingHoursSelectorController());
  
  VisitingHoursSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            width: 1.5,
            color: AppColors.greyE5
          ),
          color: AppColors.white,
          boxShadow: [AppShadows.textFieldShadow]
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.visitingHours.keys.map((day) {
          final isEnabled = controller.visitingHours[day]!;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CustomText(
                      day,
                      fontSize: SizeConfig.large,
                    // maxLines: 1,
                  ),
                ),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      CustomSwitch(
                        value: isEnabled,
                        onChanged: (val) {
                          controller.toggleDayStatus(day, val);
                        },
                        containerHeight: SizeConfig.size24,
                        containerWidth: SizeConfig.size50,
                        circleSize: SizeConfig.size18,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomText(
                        isEnabled ? "Open" : "Closed",
                        fontSize: SizeConfig.large,
                        color: AppColors.black,
                      ),
                      if (isEnabled) ...[  
                        SizedBox(width: SizeConfig.size10),
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _timeBox(day, true)),
                        SizedBox(width: SizeConfig.size3),
                        _timeBox(day, false),
                      ],
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      )),
    );
  }

  Widget _timeBox(String day, bool isStart) {
    return Obx(() {
      final selectedTime = isStart ? controller.startTimes[day]! : controller.endTimes[day]!;
      final timeOptions = controller.generateTimeList();
      String selectedString = controller.formatTime(selectedTime);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
        margin:  EdgeInsets.symmetric(horizontal: SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(4),
          // border: Border.all(
          //   color: AppColors.grey51
          // )
        ),
        child: DropdownButton<String>(
          value: selectedString,
          isDense: true,
          icon: const SizedBox(),
          dropdownColor: AppColors.white,
          underline: const SizedBox(),
          style: TextStyle(color: AppColors.grey9A, fontSize: SizeConfig.medium, fontWeight: FontWeight.w400),
          items: timeOptions.map((timeStr) {
            return DropdownMenuItem(
              value: timeStr,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6),
                child: Text(timeStr),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final parts = val.split(":");
              final newTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              if (isStart) {
                controller.updateStartTime(day, newTime);
              } else {
                controller.updateEndTime(day, newTime);
              }
            }
          },
        ),
      );
    });
  }


}
