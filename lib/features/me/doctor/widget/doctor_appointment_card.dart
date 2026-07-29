import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// One appointment request in the doctor's Booking tab.
///
/// Accept / Decline are shown only while the request is `pending` — they are
/// the doctor's transitions, and the server rejects them from any other state.
/// Cancel belongs to the customer and never appears here.
class DoctorAppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    required this.isUpdating,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001120),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  appointment.patientName?.trim().isNotEmpty == true
                      ? appointment.patientName!
                      : AppStrings.doctorPatient.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusChip(),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _row(
            Icons.calendar_today_outlined,
            _formatDate(appointment.appointmentDate),
          ),
          if ((appointment.preferredTime ?? '').isNotEmpty)
            _row(Icons.access_time, appointment.preferredTime!),
          if ((appointment.note ?? '').isNotEmpty)
            _row(Icons.sticky_note_2_outlined, appointment.note!),
          if (appointment.photos.isNotEmpty)
            _row(
              Icons.attach_file,
              '${appointment.photos.length} ${AppStrings.doctorAttachments.tr}',
            ),
          if (appointment.canOwnerAct) ...[
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                      ),
                      side: const BorderSide(color: Color(0xFFEA4335)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: CustomText(
                      AppStrings.doctorDecline.tr,
                      color: const Color(0xFFEA4335),
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      disabledBackgroundColor:
                          AppColors.primaryColor.withValues(alpha: 0.4),
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : CustomText(
                            AppStrings.doctorAccept.tr,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.small,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.secondaryTextColor),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final (bg, fg, label) = switch (appointment.status) {
      DoctorAppointmentStatus.accepted => (
          AppColors.greenShade.withValues(alpha: 0.12),
          AppColors.greenShade,
          AppStrings.doctorStatusAccepted.tr,
        ),
      DoctorAppointmentStatus.declined => (
          const Color(0xFFEA4335).withValues(alpha: 0.12),
          const Color(0xFFEA4335),
          AppStrings.doctorStatusDeclined.tr,
        ),
      DoctorAppointmentStatus.cancelled => (
          AppColors.greyE6,
          AppColors.grey83,
          AppStrings.doctorStatusCancelled.tr,
        ),
      _ => (
          AppColors.primaryColor.withValues(alpha: 0.12),
          AppColors.primaryColor,
          AppStrings.doctorStatusPending.tr,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }
}
