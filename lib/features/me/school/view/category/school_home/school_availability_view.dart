import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const List<String> kSchoolWeekDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class SchoolAvailabilityCard extends StatelessWidget {
  final SchoolAboutUsController controller;
  final VoidCallback onEditTap;

  const SchoolAvailabilityCard({
    super.key,
    required this.controller,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final availability = controller.schoolDetailsData?.value.availability ??
        const <Availability>[];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "Set Your School Timing",
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                _EditPill(onTap: onEditTap),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            ...kSchoolWeekDays.map((day) {
              final slot = availability.firstWhereOrNull(
                (a) => (a.day ?? '').toLowerCase() == day.toLowerCase(),
              );
              return _AvailabilityRow(
                day: day,
                isOpen: slot?.isOpen ?? false,
                openTime: slot?.openTime ?? '10:00',
                closeTime: slot?.closeTime ?? '10:00',
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  final String day;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const _AvailabilityRow({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: CustomText(
              day,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          _StatusBadge(isOpen: isOpen),
          const Spacer(),
          if (isOpen) ...[
            _TimeChip(time: openTime),
            const SizedBox(width: 6),
            CustomText('-', fontSize: 12, color: AppColors.grey99),
            const SizedBox(width: 6),
            _TimeChip(time: closeTime),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final bg = isOpen
        ? AppColors.greenShade.withValues(alpha: 0.12)
        : AppColors.greyE6;
    final fg = isOpen ? AppColors.greenShade : AppColors.grey83;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        isOpen ? 'Open' : 'Closed',
        fontSize: 11,
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  const _TimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.whiteE0),
      ),
      child: CustomText(time, fontSize: 12, color: AppColors.grey83),
    );
  }
}

class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 13, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
