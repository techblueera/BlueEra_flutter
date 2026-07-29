import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_hours_sheet_content.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_profile_model.dart';
import 'package:BlueEra/features/me/doctor/view/about/doctor_about_me_form.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// About tab — hosts BOTH the read-only "About Me" card and the edit form
/// inline, swapping between them in place.
///
/// The design keeps the dashboard tab bar visible in both states, so Edit must
/// not push a route: doing that replaces the whole dashboard and loses the
/// tabs. Editing is a mode of this tab, not a separate screen.
class DoctorAboutMeTab extends StatefulWidget {
  final DoctorProfileController controller;

  const DoctorAboutMeTab({super.key, required this.controller});

  @override
  State<DoctorAboutMeTab> createState() => _DoctorAboutMeTabState();
}

class _DoctorAboutMeTabState extends State<DoctorAboutMeTab> {
  bool _isEditing = false;

  void _enterEdit() => setState(() => _isEditing = true);
  void _exitEdit() => setState(() => _isEditing = false);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // First response still in flight — the dashboard shows its own skeleton,
      // so stay quiet rather than flashing an empty state.
      if (!widget.controller.isReady.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final hasProfile = widget.controller.hasProfile.value;
      final profile = widget.controller.profile.value;

      // No profile yet is a normal 200 (`hasProfile: false`), never an error.
      // Drop straight into the form — that IS the "create profile" flow.
      // Deliberately NO key here. A save writes `profile.value`, which
      // rebuilds this Obx; a value-key tied to the profile would tear down
      // the form's State mid-save, so its `mounted` check would swallow the
      // onSaved callback and leave the user stuck in edit mode.
      if (_isEditing || !hasProfile) {
        return DoctorAboutMeForm(
          onSaved: _exitEdit,
          // Back only makes sense when there IS a saved profile to return to.
          // During first-time creation there is no read-only view behind this
          // form, so the button is hidden rather than leading to a blank tab.
          onCancel: hasProfile ? _exitEdit : null,
        );
      }

      if (profile == null) return const SizedBox.shrink();
      return _AboutView(profile: profile, onEdit: _enterEdit);
    });
  }
}

/// The read-only card: title row with the Edit pill, then divider-separated
/// icon/label/value rows.
class _AboutView extends StatelessWidget {
  final DoctorProfile profile;
  final VoidCallback onEdit;

  const _AboutView({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Padding(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size16,
                SizeConfig.size12,
                SizeConfig.size16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.doctorAboutMe.tr,
                      fontWeight: FontWeight.w800,
                      fontSize: SizeConfig.large18,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  _EditPill(onTap: onEdit),
                ],
              ),
            ),
            _Row(
              icon: Icons.school_outlined,
              label: AppStrings.doctorDegree.tr,
              value: profile.degree.join(', '),
            ),
            _Row(
              icon: Icons.medical_services_outlined,
              label: AppStrings.doctorSpecialization.tr,
              value: profile.specialization.join(', '),
            ),
            _Row(
              icon: Icons.workspace_premium_outlined,
              label: AppStrings.doctorExperience.tr,
              value: profile.experienceYears == null
                  ? ''
                  : '${profile.experienceYears} ${AppStrings.doctorYears.tr}',
            ),
            _Row(
              icon: Icons.verified_user_outlined,
              label: AppStrings.doctorRegistrationNumber.tr,
              value: profile.registrationNumber ?? '',
            ),
            // Empty when the fee is unset — rendering ₹0 would advertise a
            // free consultation.
            _Row(
              icon: Icons.currency_rupee,
              label: AppStrings.doctorConsultationFee.tr,
              value: profile.feeLabel,
            ),
            _Row(
              icon: Icons.translate,
              label: AppStrings.doctorLanguagesSpoken.tr,
              value: profile.languagesSpoken.join(', '),
            ),
            _Row(
              icon: Icons.location_on_outlined,
              label: AppStrings.addressLabel.tr,
              value: profile.address ?? '',
            ),
            _Row(
              icon: Icons.person_outline,
              label: AppStrings.description.tr,
              value: profile.description ?? '',
            ),
            // Availability is a BUSINESS field (user-service), not part of
            // `GET /doctors/me`. The business profile already carries the same
            // Availability document the `/availability/hours` endpoint reads,
            // so no second request is needed.
            Obx(() {
              final schedule = businessController
                      .businessProfileDetails.value?.data?.availability?.schedule ??
                  const <Schedule>[];
              return _AvailabilityRow(
                schedule: schedule.where((s) => s.isOpen ?? false).toList(),
                onAdd: () => _openHoursSheet(context, businessController),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Reuses the existing business-hours sheet — availability is a business
  /// concern, so there is nothing doctor-specific to build here.
  void _openHoursSheet(
    BuildContext context,
    ViewBusinessDetailsController businessController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessHoursSheetContent(
        details: businessController.businessProfileDetails.value?.data,
        controller: businessController,
      ),
    );
  }
}

/// One icon / label / value row with the hairline separator above it.
class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFEFF2F7)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: icon),
              SizedBox(width: SizeConfig.size12),
              SizedBox(
                width: 92,
                child: CustomText(
                  label,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  value,
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Consultation Availability row — shows the first open day inline with the
/// open/close times colour-coded, and expands to the full week on tap.
class _AvailabilityRow extends StatefulWidget {
  final List<Schedule> schedule;
  final VoidCallback onAdd;

  const _AvailabilityRow({required this.schedule, required this.onAdd});

  @override
  State<_AvailabilityRow> createState() => _AvailabilityRowState();
}

class _AvailabilityRowState extends State<_AvailabilityRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.schedule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFEFF2F7)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.calendar_today_outlined),
              SizedBox(width: SizeConfig.size12),
              SizedBox(
                width: 92,
                child: CustomText(
                  AppStrings.doctorConsultationAvailability.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: open.isEmpty
                    ? InkWell(
                        onTap: widget.onAdd,
                        child: CustomText(
                          AppStrings.doctorAddVisitingDays.tr,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dayLine(open.first),
                          if (_expanded)
                            ...open.skip(1).map(
                                  (s) => Padding(
                                    padding: EdgeInsets.only(
                                        top: SizeConfig.size6),
                                    child: _dayLine(s),
                                  ),
                                ),
                        ],
                      ),
              ),
              if (open.length > 1)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// `Monday: 9:00 AM – 6:00 PM`, with the open time green and the close time
  /// red as in the design.
  Widget _dayLine(Schedule s) {
    final slot = (s.timeSlots?.isNotEmpty ?? false) ? s.timeSlots!.first : null;
    final day = s.day?.capitalizeFirst ?? '';
    final from = slot?.startTime ?? '';
    final to = slot?.endTime ?? '';
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: SizeConfig.medium,
          color: AppColors.secondaryTextColor,
          fontFamily: 'OpenSans',
        ),
        children: [
          TextSpan(text: from.isEmpty && to.isEmpty ? day : '$day: '),
          if (from.isNotEmpty)
            TextSpan(
              text: from,
              style: const TextStyle(
                color: Color(0xFF1BA94C),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (from.isNotEmpty && to.isNotEmpty) const TextSpan(text: ' – '),
          if (to.isNotEmpty)
            TextSpan(
              text: to,
              style: const TextStyle(
                color: Color(0xFFEA4335),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: AppColors.primaryColor),
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
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              AppStrings.edit.tr,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
