import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/shop_open_status.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared "Shop status" sheet opened from the Go-Live pill once a weekly
/// schedule exists. It surfaces the schedule-driven auto open/close state and
/// the two controls the merchant actually needs:
///   1. a today-only override — flip the shop open/closed for *today* (reverts
///      to the weekly schedule automatically tomorrow), and
///   2. an entry point to edit the weekly hours.
///
/// There is deliberately no per-day *time* editing here — times are only set in
/// the weekly editor; the override is a plain open/closed switch for today.
Future<void> showShopAvailabilitySheet(
  ViewBusinessDetailsController controller,
) {
  return Get.bottomSheet(
    _ShopAvailabilitySheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ShopAvailabilitySheet extends StatelessWidget {
  const _ShopAvailabilitySheet({required this.controller});

  final ViewBusinessDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        SizeConfig.size12,
        18,
        SizeConfig.size16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber + explicit close button. iOS can't always swipe a
          // scroll-controlled sheet away, so give a tappable X.
          Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            // No weekly hours yet → show the "Set visiting hours" prompt
            // instead of the live status. Reading weeklySchedule here keeps the
            // sheet reactive to a save made from the editor.
            final hasHours =
                controller.weeklySchedule.any((s) => (s.isOpen ?? false));
            if (!hasHours) return _emptyState();

            final status = controller.shopStatus.value;
            final busy = controller.isAvailabilityUpdating.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + live status dot ─────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status.isOpenNow
                            ? const Color(0xFF2ECC71)
                            : AppColors.secondaryTextColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.shopStatus.tr,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  _statusLine(status),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: status.isOpenNow
                      ? const Color(0xFF1E8E4E)
                      : AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size16),
                Container(height: 1, color: AppColors.greyE5),
                SizedBox(height: SizeConfig.size12),

                // ── Today-only override ─────────────────────────────────
                CustomText(
                  AppStrings.todayOnly.tr,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        AppStrings.openTodayLabel.tr,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    if (busy)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      CustomSwitch(
                        value: status.openTodayAtAll,
                        containerWidth: 46,
                        containerHeight: 26,
                        circleSize: 18,
                        onChanged: (v) async {
                          if (v) {
                            await controller.setOpenToday();
                          } else {
                            await controller.setClosedToday();
                          }
                        },
                      ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  status.hasOverrideToday
                      ? AppStrings.revertsToScheduleTomorrow.tr
                      : AppStrings.autoOpenCloseNote.tr,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                if (status.hasOverrideToday) ...[
                  SizedBox(height: SizeConfig.size8),
                  GestureDetector(
                    onTap: busy ? null : controller.revertTodayOverride,
                    child: CustomText(
                      AppStrings.revertToScheduleNow.tr,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
                SizedBox(height: SizeConfig.size16),
                Container(height: 1, color: AppColors.greyE5),
                SizedBox(height: SizeConfig.size12),

                // ── Weekly hours (read-only) ────────────────────────────
                // Lets the merchant SEE their full week at a glance without
                // opening the editor. Today's row is highlighted.
                CustomText(
                  AppStrings.weeklyHoursTitle.tr,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                _weeklyHours(controller.weeklySchedule),
                SizedBox(height: SizeConfig.size20),

                // ── Edit weekly hours ───────────────────────────────────
                CustomBtn(
                  title: AppStrings.editWeeklyHours.tr,
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  onTap: () {
                    Get.back();
                    controller.openWeeklyEditor();
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Empty state shown when the merchant has never saved weekly hours. Tapping
  // "Set visiting hours" opens the weekly editor; on save the sheet reappears
  // (via the pill) already showing the live status.
  Widget _emptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Icon(
            Icons.schedule_rounded,
            size: 40,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          AppStrings.setYourShopTimings.tr,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.noHoursSetSubtitle.tr,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.size20),
        CustomBtn(
          title: AppStrings.setVisitingHours.tr,
          radius: 10,
          bgColor: AppColors.primaryColor,
          onTap: () {
            Get.back();
            controller.openWeeklyEditor();
          },
        ),
      ],
    );
  }

  // Read-only Mon→Sun list of the saved weekly hours. Each day shows its
  // open–close window or "Closed"; today's row is emphasised.
  Widget _weeklyHours(List<Schedule> schedule) {
    const order = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayName = ShopOpenStatus.weekdayName(DateTime.now());

    Schedule? rowFor(String day) {
      for (final s in schedule) {
        if (s.day == day) return s;
      }
      return null;
    }

    return Column(
      children: [
        for (final day in order) _weeklyRow(day, rowFor(day), day == todayName),
      ],
    );
  }

  Widget _weeklyRow(String day, Schedule? s, bool isToday) {
    final isOpen = s?.isOpen ?? false;
    final open = _fmt(s?.shopOpenTime) ?? s?.shopOpenTime;
    final close = _fmt(s?.shopCloseTime) ?? s?.shopCloseTime;
    final hasTimes = isOpen && open != null && close != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              isToday ? '$day · ${AppStrings.todayTag.tr}' : day,
              fontSize: 13.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          CustomText(
            hasTimes ? '$open – $close' : AppStrings.closed.tr,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isOpen
                ? const Color(0xFF1E8E4E)
                : AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // Human-readable status line, e.g.:
  //   Open now · till 5:00 PM
  //   Opens at 9:00 AM
  //   Closed for today
  //   Closed today
  String _statusLine(status) {
    if (!status.openTodayAtAll) return AppStrings.closedTodayLabel.tr;
    if (status.isOpenNow) {
      final till = _fmt(status.closeTime);
      return till == null
          ? AppStrings.openNowLabel.tr
          : '${AppStrings.openNowLabel.tr} · ${AppStrings.tillLabel.tr} $till';
    }
    // Open today but not right now — before open, or after close.
    final open = _fmt(status.openTime);
    if (open != null) return '${AppStrings.opensAtLabel.tr} $open';
    return AppStrings.closedNowLabel.tr;
  }

  // "17:00" → "5:00 PM" (null-safe).
  String? _fmt(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }
}
