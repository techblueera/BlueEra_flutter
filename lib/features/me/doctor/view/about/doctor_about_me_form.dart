import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_hours_sheet_content.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_chip_input_field.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// About Me — the create/edit form body.
///
/// A plain widget (no Scaffold) because the design renders it INSIDE the
/// dashboard's About tab, with the tab bar still visible above it. The tab
/// swaps between [DoctorAboutMeForm] and the read-only view; it is not a
/// pushed route.
///
/// Whether Save creates or updates is decided by the controller from
/// `hasProfile`: `POST /doctors` the first time, `PUT /doctors/me` after.
///
/// Consultation Availability is deliberately NOT part of this payload — it
/// saves to user-service through the shared business-hours sheet.
class DoctorAboutMeForm extends StatefulWidget {
  /// Called after a successful save so the host can leave edit mode.
  final VoidCallback? onSaved;

  /// Called when the user backs out without saving. When null the Back button
  /// is hidden — the host passes null where there is nothing to go back TO
  /// (a doctor with no profile yet has no read-only view to show).
  final VoidCallback? onCancel;

  const DoctorAboutMeForm({super.key, this.onSaved, this.onCancel});

  @override
  State<DoctorAboutMeForm> createState() => _DoctorAboutMeFormState();
}

class _DoctorAboutMeFormState extends State<DoctorAboutMeForm> {
  static const int _descriptionLimit = 1000;
  static const int _maxEntries = 30;
  static const int _maxExperienceYears = 80;

  final _controller = getOrPut(() => DoctorProfileController());
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  late List<String> _degree;
  late List<String> _specialization;
  late List<String> _languages;

  final _experienceCtrl = TextEditingController();
  final _registrationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  /// Snapshot of the prefilled state, taken once. Backing out compares
  /// against this so an untouched form closes immediately and only real edits
  /// prompt before being discarded.
  late final String _initialSnapshot;

  @override
  void initState() {
    super.initState();
    // Prefill once from the cached profile. The form owns its state from here
    // — a half-filled form is never written back to the controller.
    final p = _controller.profile.value;
    _degree = [...?p?.degree];
    _specialization = [...?p?.specialization];
    _languages = [...?p?.languagesSpoken];
    _experienceCtrl.text = p?.experienceYears?.toString() ?? '';
    _registrationCtrl.text = p?.registrationNumber ?? '';
    _feeCtrl.text = p?.consultationFee == null
        ? ''
        : (p!.consultationFee! % 1 == 0
            ? p.consultationFee!.toInt().toString()
            : p.consultationFee!.toString());
    _addressCtrl.text = p?.address ?? '';
    _descriptionCtrl.text = p?.description ?? '';
    _initialSnapshot = _snapshot();
    _descriptionCtrl.addListener(() => setState(() {}));
  }

  /// Every editable value flattened into one comparable string. Cheap enough
  /// to recompute on demand and avoids tracking each field separately.
  String _snapshot() => [
        _degree.join('|'),
        _specialization.join('|'),
        _languages.join('|'),
        _experienceCtrl.text.trim(),
        _registrationCtrl.text.trim(),
        _feeCtrl.text.trim(),
        _addressCtrl.text.trim(),
        _descriptionCtrl.text.trim(),
      ].join('§');

  bool get _isDirty => _snapshot() != _initialSnapshot;

  @override
  void dispose() {
    _experienceCtrl.dispose();
    _registrationCtrl.dispose();
    _feeCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  /// Mirrors the server's rules so a missed check doesn't become a 400.
  String? _validate() {
    if (_degree.length > _maxEntries ||
        _specialization.length > _maxEntries ||
        _languages.length > _maxEntries) {
      return AppStrings.doctorMaxEntriesError.tr;
    }
    final experienceText = _experienceCtrl.text.trim();
    if (experienceText.isNotEmpty) {
      final years = int.tryParse(experienceText);
      if (years == null || years < 0 || years > _maxExperienceYears) {
        return AppStrings.doctorExperienceRangeError.tr;
      }
    }
    final feeText = _feeCtrl.text.trim();
    if (feeText.isNotEmpty) {
      final fee = num.tryParse(feeText);
      if (fee == null || fee < 0) return AppStrings.doctorFeeError.tr;
    }
    if (_descriptionCtrl.text.trim().length > _descriptionLimit) {
      return AppStrings.doctorDescriptionLimitError.tr;
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      commonSnackBar(message: error);
      return;
    }

    final experience = int.tryParse(_experienceCtrl.text.trim());
    final fee = num.tryParse(_feeCtrl.text.trim());

    // Chip lists are always sent: they are the field's full value, and the
    // user may legitimately have cleared one. Scalars are only sent when
    // non-empty so a blank field doesn't wipe a stored value on update.
    final body = <String, dynamic>{
      'degree': _degree,
      'specialization': _specialization,
      'languagesSpoken': _languages,
      if (experience != null) 'experienceYears': experience,
      if (_registrationCtrl.text.trim().isNotEmpty)
        'registrationNumber': _registrationCtrl.text.trim(),
      if (fee != null) 'consultationFee': fee,
      // The design renders the fee as "₹600/Visit"; the API enum for that is
      // "Per Visit".
      if (fee != null) 'feeType': 'Per Visit',
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_descriptionCtrl.text.trim().isNotEmpty)
        'description': _descriptionCtrl.text.trim(),
    };

    final ok = await _controller.saveProfile(body);
    if (ok && mounted) widget.onSaved?.call();
  }

  /// Leaves the form without saving. An untouched form closes straight away;
  /// a modified one confirms first so edits aren't lost to a stray tap.
  Future<void> _handleBack() async {
    if (!_isDirty) {
      widget.onCancel?.call();
      return;
    }
    await showCommonDialog(
      context: context,
      text: AppStrings.discardChanges.tr,
      confirmCallback: () {
        Get.back();
        widget.onCancel?.call();
      },
      cancelCallback: () => Navigator.of(context).pop(),
      confirmText: AppStrings.yes.tr,
      cancelText: AppStrings.no.tr,
    );
  }

  void _openHoursSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessHoursSheetContent(
        details: _businessController.businessProfileDetails.value?.data,
        controller: _businessController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final descriptionLength = _descriptionCtrl.text.length;
    return Container(
      margin: EdgeInsets.all(SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DoctorChipInputField(
            title: AppStrings.doctorDegree.tr,
            hintText: AppStrings.doctorDegreeHint.tr,
            values: _degree,
            onChanged: (v) => setState(() => _degree = v),
          ),
          SizedBox(height: SizeConfig.size16),
          DoctorChipInputField(
            title: AppStrings.doctorSpecialization.tr,
            hintText: AppStrings.doctorSpecializationHint.tr,
            values: _specialization,
            onChanged: (v) => setState(() => _specialization = v),
          ),
          SizedBox(height: SizeConfig.size16),
          DoctorChipInputField(
            title: AppStrings.doctorLanguageSpoken.tr,
            hintText: AppStrings.doctorLanguageHint.tr,
            values: _languages,
            onChanged: (v) => setState(() => _languages = v),
          ),
          SizedBox(height: SizeConfig.size16),
          _Field(
            title: AppStrings.doctorExperience.tr,
            hintText: AppStrings.doctorExperienceHint.tr,
            controller: _experienceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          _Field(
            title: AppStrings.doctorRegistrationNumber.tr,
            hintText: AppStrings.doctorRegistrationHint.tr,
            controller: _registrationCtrl,
          ),
          SizedBox(height: SizeConfig.size16),
          _Field(
            title: AppStrings.doctorConsultationFee.tr,
            hintText: AppStrings.doctorFeeHint.tr,
            controller: _feeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: SizeConfig.size16),
          _Field(
            title: AppStrings.addressLabel.tr,
            hintText: AppStrings.doctorAddressHint.tr,
            controller: _addressCtrl,
          ),
          SizedBox(height: SizeConfig.size16),
          _Field(
            title: AppStrings.description.tr,
            hintText: AppStrings.doctorDescriptionHint.tr,
            controller: _descriptionCtrl,
            maxLines: 5,
            maxLength: _descriptionLimit,
          ),
          SizedBox(height: SizeConfig.size6),
          Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              '$descriptionLength/$_descriptionLimit',
              fontSize: SizeConfig.small,
              color: descriptionLength > _descriptionLimit
                  ? AppColors.red
                  : AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            AppStrings.doctorConsultationAvailability.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size8),
          InkWell(
            onTap: _openHoursSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 17, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    AppStrings.doctorAddVisitingDays.tr,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size24),
          Obx(
            () => CustomBtn(
              isLoading: _controller.isSaving.value,
              onTap: _controller.isSaving.value ? null : _save,
              title: _controller.isSaving.value ? null : AppStrings.save.tr,
              radius: SizeConfig.size8,
              bgColor: AppColors.primaryColor,
            ),
          ),
          // Way out for someone who opened the form only to read it. Without
          // this the inline edit mode is a trap: it has no app bar, so Save
          // was the only exit.
          if (widget.onCancel != null) ...[
            SizedBox(height: SizeConfig.size12),
            Obx(
              () => OutlinedButton(
                onPressed: _controller.isSaving.value ? null : _handleBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.size8),
                  ),
                ),
                child: CustomText(
                  AppStrings.back.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single-line / multi-line text field in the design's style: pale fill, thin
/// border, grey hint.
class _Field extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;

  const _Field({
    required this.title,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            // The screen renders its own live counter under the description
            // field, matching the design's `50/1000`.
            counterText: '',
            hintStyle: TextStyle(
              fontSize: SizeConfig.medium,
              color: AppColors.grey99,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
