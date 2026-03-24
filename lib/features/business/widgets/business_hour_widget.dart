import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:get/utils.dart';

class BusinessHoursWidget extends StatelessWidget {
  final List<Schedule>? schedules;
  final bool showChevron;

  const BusinessHoursWidget({
    super.key,
    this.schedules,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ only open days
    final openSchedules = schedules
        ?.where((s) => s.isOpen == true && s.day?.isNotEmpty == true)
        .toList() ??
        [];

    if (openSchedules.isEmpty) return const SizedBox.shrink();

    final first = openSchedules.first;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        // ─── First entry preview ───
        title: _buildScheduleRow(first),
        trailing: openSchedules.length > 1
            ? Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: AppColors.mainTextColor,
        )
            : const SizedBox.shrink(),

        // ─── All entries in expansion ───
        children: openSchedules
            .skip(1)
            .map((s) => Padding(
          padding: EdgeInsets.only(
            top: SizeConfig.size6,
            left: SizeConfig.size12,
          ),
          child: _buildScheduleRow(s),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildScheduleRow(Schedule schedule) {
    final firstSlot  = schedule.timeSlots?.isNotEmpty == true ? schedule.timeSlots!.first : null;
    final openTime   = firstSlot?.startTime;
    final closeTime  = firstSlot?.endTime;
    final day        = schedule.day?.capitalizeFirst ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // ✅ left blue border
        Container(
          width: 3, height: 20,
          margin: EdgeInsets.only(right: SizeConfig.size8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                // Day
                TextSpan(
                  text: '$day: ',
                  style: TextStyle(
                    fontSize:   SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color:      AppColors.mainTextColor,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),

                // Open time — green
                if (openTime?.isNotEmpty == true)
                  TextSpan(
                    text: openTime,
                    style: TextStyle(
                      fontSize:   SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color:      Colors.green,
                      fontFamily: AppConstants.OpenSans,
                    ),
                  ),

                // Separator
                if (openTime?.isNotEmpty == true && closeTime?.isNotEmpty == true)
                  TextSpan(
                    text: ' – ',
                    style: TextStyle(
                      fontSize:   SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color:      AppColors.mainTextColor,
                      fontFamily: AppConstants.OpenSans,
                    ),
                  ),

                // Close time — red
                if (closeTime?.isNotEmpty == true)
                  TextSpan(
                    text: closeTime,
                    style: TextStyle(
                      fontSize:   SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color:      Colors.red,
                      fontFamily: AppConstants.OpenSans,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}