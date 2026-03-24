import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:get/utils.dart';

class BusinessAvailabilityWidget extends StatefulWidget {
  final List<Schedule>? schedule;
  final bool hasAvailability;
  final VoidCallback? onEditTap;
  final VoidCallback? onAddTap;
  final String addLabel;

  const BusinessAvailabilityWidget({
    super.key,
    this.schedule,
    required this.hasAvailability,
    this.onEditTap,
    this.onAddTap,
    this.addLabel = 'Add Your Visiting Days',
  });

  @override
  State<BusinessAvailabilityWidget> createState() =>
      _BusinessAvailabilityWidgetState();
}

class _BusinessAvailabilityWidgetState
    extends State<BusinessAvailabilityWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return widget.hasAvailability ? _buildSchedule() : _buildAddButton();
  }

  Widget _buildSchedule() {
    final openSchedules = widget.schedule
            ?.where((s) => s.isOpen == true && s.day?.isNotEmpty == true)
            .toList() ??
        [];

    if (openSchedules.isEmpty) return _buildAddButton();

    final hasMore = openSchedules.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── First row ───
        InkWell(
          onTap:
              hasMore ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Row(
            children: [
              Expanded(child: _buildScheduleRow(openSchedules.first)),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: AppColors.secondaryTextColor),
                  ),
                ),
            ],
          ),
        ),

        // ─── Expanded rows ───
        if (_isExpanded) ...[
          ...openSchedules.skip(1).map((s) => Padding(
                padding: EdgeInsets.only(top: SizeConfig.size12),
                // ✅ exact same gap
                child: _buildScheduleRow(s),
              )),
          if (widget.onEditTap != null)
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.size10),
              child: InkWell(
                onTap: widget.onEditTap,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.pen_line,
                        height: 12,
                        width: 12,
                        imgColor: AppColors.primaryColor),
                    SizedBox(width: SizeConfig.size4),
                    CustomText('Edit Timing',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildScheduleRow(Schedule schedule) {
    final firstSlot = schedule.timeSlots?.isNotEmpty == true
        ? schedule.timeSlots!.first
        : null;
    final openTime = firstSlot?.startTime;
    final closeTime = firstSlot?.endTime;
    final day = schedule.day?.capitalizeFirst ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3, height: 20,
          margin: EdgeInsets.only(right: SizeConfig.size12),
          decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(2)),
        ),
        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '$day: ',
                    style: TextStyle(
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                        fontFamily: AppConstants.OpenSans)),
                if (openTime?.isNotEmpty == true)
                  TextSpan(
                      text: openTime,
                      style: TextStyle(
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: Colors.green,
                          fontFamily: AppConstants.OpenSans)),
                if (openTime?.isNotEmpty == true &&
                    closeTime?.isNotEmpty == true)
                  TextSpan(
                      text: ' – ',
                      style: TextStyle(
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                          fontFamily: AppConstants.OpenSans)),
                if (closeTime?.isNotEmpty == true)
                  TextSpan(
                      text: closeTime,
                      style: TextStyle(
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                          fontFamily: AppConstants.OpenSans)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddTap,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.skyBlueFF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(widget.addLabel,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}
