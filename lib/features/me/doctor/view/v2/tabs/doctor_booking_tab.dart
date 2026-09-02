import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_appointment_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_appointment_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Booking tab — the doctor's appointment inbox
/// (`GET /doctor-appointments/owner/me`), with status filter chips and
/// infinite scroll.
class DoctorBookingTab extends StatelessWidget {
  final DoctorAppointmentController controller;

  const DoctorBookingTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size12),
        _FilterChips(controller: controller),
        SizedBox(height: SizeConfig.size12),
        Obx(() {
          if (controller.isLoading.value && controller.appointments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.loadError.value.isNotEmpty &&
              controller.appointments.isEmpty) {
            return _ErrorState(
              message: controller.loadError.value,
              onRetry: controller.fetchAppointments,
            );
          }
          if (controller.appointments.isEmpty) return const _EmptyState();

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: Column(
              children: [
                ...controller.appointments.map(
                  (appointment) => DoctorAppointmentCard(
                    appointment: appointment,
                    isUpdating:
                        controller.updatingIds.contains(appointment.id ?? ''),
                    onAccept: () => controller.accept(appointment.id ?? ''),
                    onDecline: () => controller.decline(appointment.id ?? ''),
                  ),
                ),
                if (controller.hasMore)
                  Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size12),
                    child: controller.isLoadingMore.value
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: controller.loadMore,
                            child: CustomText(
                              AppStrings.doctorLoadMore.tr,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DoctorAppointmentController controller;

  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String)>[
      ('', AppStrings.doctorFilterAll.tr),
      (DoctorAppointmentStatus.pending, AppStrings.doctorStatusPending.tr),
      (DoctorAppointmentStatus.accepted, AppStrings.doctorStatusAccepted.tr),
      (DoctorAppointmentStatus.declined, AppStrings.doctorStatusDeclined.tr),
      (DoctorAppointmentStatus.cancelled, AppStrings.doctorStatusCancelled.tr),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, i) {
          final (value, label) = filters[i];
          return Obx(() {
            final selected = controller.statusFilter.value == value;
            return GestureDetector(
              onTap: () => controller.setStatusFilter(value),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size14,
                  vertical: SizeConfig.size6,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        selected ? AppColors.primaryColor : AppColors.whiteE5,
                  ),
                ),
                child: Center(
                  child: CustomText(
                    label,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.secondaryTextColor,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, size: 56, color: Colors.grey[300]),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              AppStrings.doctorNoAppointments.tr,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.medium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size40,
        horizontal: SizeConfig.size20,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 42, color: Colors.grey[400]),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            message,
            color: AppColors.secondaryTextColor,
            fontSize: SizeConfig.small,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          SizedBox(height: SizeConfig.size12),
          OutlinedButton(
            onPressed: onRetry,
            child: CustomText(
              AppStrings.retry.tr,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
