import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_stats_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Statics tab.
///
/// Booking numbers come from hospital-service (`GET /doctors/me/stats`);
/// profile visits, chat clicks and ratings come from user-service and are
/// rendered by the existing `ProfileStatisticsScreen`. The two sources are
/// independent, so a failure in one shows `--` in its own tiles and leaves
/// the rest of the screen intact.
class DoctorStaticsTab extends StatelessWidget {
  final DoctorStatsController controller;

  /// Tapping a status tile jumps to the Booking tab pre-filtered to that
  /// status — the host owns the TabController, so it passes this in.
  final void Function(String status)? onStatusTap;

  const DoctorStaticsTab({
    super.key,
    required this.controller,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            SizeConfig.size14,
            SizeConfig.size12,
            0,
          ),
          child: CustomText(
            AppStrings.doctorAppointmentStats.tr,
            fontWeight: FontWeight.w700,
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          final stats = controller.stats.value;
          final loading = controller.isLoading.value && stats == null;
          final failed = controller.loadError.value.isNotEmpty && stats == null;
          // "--" only in these tiles: the user-service statistics below still
          // render normally.
          String value(int? v) => failed ? '--' : (v?.toString() ?? '0');

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                _Tile(
                  label: AppStrings.doctorTotalRequests.tr,
                  value: value(stats?.total),
                  isLoading: loading,
                ),
                _Tile(
                  label: AppStrings.doctorStatusPending.tr,
                  value: value(stats?.pending),
                  isLoading: loading,
                  onTap: () =>
                      onStatusTap?.call(DoctorAppointmentStatus.pending),
                ),
                _Tile(
                  label: AppStrings.doctorStatusAccepted.tr,
                  value: value(stats?.accepted),
                  isLoading: loading,
                  onTap: () =>
                      onStatusTap?.call(DoctorAppointmentStatus.accepted),
                ),
                _Tile(
                  label: AppStrings.doctorStatusDeclined.tr,
                  value: value(stats?.declined),
                  isLoading: loading,
                  onTap: () =>
                      onStatusTap?.call(DoctorAppointmentStatus.declined),
                ),
                _Tile(
                  label: AppStrings.doctorStatusCancelled.tr,
                  value: value(stats?.cancelled),
                  isLoading: loading,
                  onTap: () =>
                      onStatusTap?.call(DoctorAppointmentStatus.cancelled),
                ),
                _Tile(
                  label: AppStrings.doctorUpcomingVisits.tr,
                  value: value(stats?.upcomingAccepted),
                  isLoading: loading,
                ),
                _Tile(
                  label: AppStrings.doctorCertificates.tr,
                  value: value(stats?.certificateCount),
                  isLoading: loading,
                ),
              ],
            ),
          );
        }),
        SizedBox(height: SizeConfig.size16),
        // Views / visits / chat clicks / ratings — user-service, unchanged.
        ProfileStatisticsScreen(userId: userId),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final VoidCallback? onTap;

  const _Tile({
    required this.label,
    required this.value,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              Container(
                width: 34,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.greyE6,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              CustomText(
                value,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
