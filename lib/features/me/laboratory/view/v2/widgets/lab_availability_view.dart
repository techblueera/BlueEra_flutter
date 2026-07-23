import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_availability_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const List<String> kLabWeekDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Weekly-hours card for the lab overview tab. Mirrors
/// [SchoolAvailabilityCard] visually — day rows with Open/Closed badge and
/// time chips, plus an edit pill in the header — but reads from the
/// business-level [ViewBusinessDetailsController.weeklySchedule] since labs
/// go live via the shared business availability endpoint rather than a
/// lab-specific model.
class LabAvailabilityCard extends StatefulWidget {
  final ViewBusinessDetailsController businessController;

  const LabAvailabilityCard({
    super.key,
    required this.businessController,
  });

  @override
  State<LabAvailabilityCard> createState() => _LabAvailabilityCardState();
}

class _LabAvailabilityCardState extends State<LabAvailabilityCard> {
  @override
  void initState() {
    super.initState();
    // Weekly hours aren't fetched by the profile view — hydrate on mount so
    // the day rows show real data instead of the "10:00" defaults from the
    // controller's empty state.
    if (widget.businessController.weeklySchedule.isEmpty) {
      widget.businessController.loadHours();
    }
  }

  Future<void> _openEditor() async {
    // Lab-specific editor (mirrors `ShopAvailabilityScreen` with lab copy).
    // Persists through the shared business availability endpoint and refreshes
    // the schedule on success so the day rows update in place.
    final result = await Get.to(
      () => LabAvailabilityScreen(
        initialSchedule: widget.businessController.weeklySchedule,
        onSave: _saveWeeklyHours,
      ),
    );
    if (result == true) await widget.businessController.loadHours();
  }

  Future<String?> _saveWeeklyHours(List<Schedule> schedule) async {
    final res = await BusinessProfileRepo().setBusinessHours({
      'timezone': 'Asia/Kolkata',
      'schedule': schedule.map((s) => s.toJson()).toList(),
    });
    return res.isSuccess
        ? null
        : (res.message ?? AppStrings.somethingWentWrong.tr);
  }

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 12,
      cardMargin: 0,
      child: Obx(() {
        final schedule = widget.businessController.weeklySchedule;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Set Your Lab Timing',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                _EditPill(onTap: _openEditor),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            ...kLabWeekDays.map((day) {
              final slot = schedule.firstWhereOrNull(
                (s) => (s.day ?? '').toLowerCase() == day.toLowerCase(),
              );
              return _AvailabilityRow(
                day: day,
                isOpen: slot?.isOpen ?? false,
                openTime: _resolveOpen(slot),
                closeTime: _resolveClose(slot),
              );
            }),
          ],
        );
      }),
    );
  }

  // Prefer the explicit `shopOpenTime` / `shopCloseTime` fields; fall back to
  // the first `timeSlots` entry for older payloads that only carried slots.
  String _resolveOpen(Schedule? s) {
    final direct = (s?.shopOpenTime ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final slot = (s?.timeSlots != null && s!.timeSlots!.isNotEmpty)
        ? s.timeSlots!.first
        : null;
    final st = (slot?.startTime ?? '').trim();
    return st.isNotEmpty ? st : '10:00';
  }

  String _resolveClose(Schedule? s) {
    final direct = (s?.shopCloseTime ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final slot = (s?.timeSlots != null && s!.timeSlots!.isNotEmpty)
        ? s.timeSlots!.first
        : null;
    final et = (slot?.endTime ?? '').trim();
    return et.isNotEmpty ? et : '10:00';
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
