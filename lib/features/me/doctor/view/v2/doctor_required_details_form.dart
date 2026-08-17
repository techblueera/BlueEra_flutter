import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_profile_model.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_chip_input_field.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_profile_card_preview.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Mandatory-details gate for the standalone doctor dashboard.
///
/// The redesigned listing card (`docs/newdrcard.png`) renders specialization,
/// experience, degree, services and the consultation fee. A card missing any
/// of them reads as broken rather than sparse, so `DoctorHomeScreenV2` shows
/// this form INSTEAD of its tabs until all five are saved — the same shape as
/// the school module's Quick Info gate, which hides the profile body behind
/// `SchoolQuickInfoFormScreen` until its required fields exist.
///
/// Deliberately a plain widget, not a route: it renders inside the dashboard
/// body under the existing top bar, so the drawer, notifications and Go-Live
/// stay reachable and the user is never trapped in a screen with no exit.
///
/// It writes through [DoctorProfileController.saveProfile], which picks
/// `POST /doctors` or `PUT /doctors/me` from `hasProfile` — so this same form
/// both creates a profile and tops up an existing one that predates the new
/// card. Only the five card fields are sent; everything else the About tab
/// owns (address, description, languages, registration number) is left
/// untouched, which matters because the PUT is partial.
class DoctorRequiredDetailsForm extends StatefulWidget {
  final DoctorProfileController controller;

  const DoctorRequiredDetailsForm({super.key, required this.controller});

  @override
  State<DoctorRequiredDetailsForm> createState() =>
      _DoctorRequiredDetailsFormState();
}

class _DoctorRequiredDetailsFormState extends State<DoctorRequiredDetailsForm> {
  /// Same server-side caps the About Me form mirrors.
  static const int _maxEntries = 30;
  static const int _maxExperienceYears = 80;

  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  late List<String> _specialization;
  late List<String> _degree;
  late List<String> _services;

  final _experienceCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefilled from whatever the doctor already has, so a profile created
    // before the card redesign only asks for the pieces it is actually
    // missing rather than making the user retype everything.
    final p = widget.controller.profile.value;
    _specialization = [...?p?.specialization];
    _degree = [...?p?.degree];
    _services = [...?p?.expertise];
    _experienceCtrl.text =
        (p?.experienceYears ?? 0) > 0 ? p!.experienceYears.toString() : '';
    final fee = p?.consultationFee;
    _feeCtrl.text = (fee == null || fee <= 0)
        ? ''
        : (fee % 1 == 0 ? fee.toInt().toString() : fee.toString());
    // The preview mirrors the fields live, so both numeric inputs repaint it.
    _experienceCtrl.addListener(_onChanged);
    _feeCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _experienceCtrl.removeListener(_onChanged);
    _feeCtrl.removeListener(_onChanged);
    _experienceCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  int? get _experience => int.tryParse(_experienceCtrl.text.trim());

  num? get _fee => num.tryParse(_feeCtrl.text.trim());

  /// Every field here is mandatory, so this validates presence first and only
  /// then the ranges the server enforces — a missed range check comes back as
  /// an opaque 400.
  String? _validate() {
    if (_specialization.isEmpty) {
      return AppStrings.doctorSpecializationRequired.tr;
    }
    if ((_experience ?? 0) <= 0) return AppStrings.doctorExperienceRequired.tr;
    if (_experience! > _maxExperienceYears) {
      return AppStrings.doctorExperienceRangeError.tr;
    }
    if (_degree.isEmpty) return AppStrings.doctorDegreeRequired.tr;
    if (_services.isEmpty) return AppStrings.doctorServicesRequired.tr;
    if ((_fee ?? 0) <= 0) return AppStrings.doctorFeeRequired.tr;
    if (_specialization.length > _maxEntries ||
        _degree.length > _maxEntries ||
        _services.length > _maxEntries) {
      return AppStrings.doctorMaxEntriesError.tr;
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      commonSnackBar(message: error);
      return;
    }

    // Only the card's own fields. Sending anything else would overwrite About
    // Me values on the partial PUT taken by an existing profile.
    final body = <String, dynamic>{
      'specialization': _specialization,
      'experienceYears': _experience,
      'degree': _degree,
      'expertise': _services,
      'consultationFee': _fee,
      // The card renders "₹1000/Visit"; the API enum for that is "Per Visit",
      // matching what the About Me form already writes.
      'feeType': DoctorProfile.perVisitFeeType,
    };

    // No navigation on success: saving updates `profile`/`hasProfile`, and the
    // dashboard's Obx swaps this form out for the tabs on the next frame.
    await widget.controller.saveProfile(body);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        kBottomNavigationBarHeight + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _intro(),
          SizedBox(height: SizeConfig.size12),
          _previewSection(),
          SizedBox(height: SizeConfig.size12),
          _formCard(),
        ],
      ),
    );
  }

  Widget _intro() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.badge_outlined,
                size: 24, color: AppColors.primaryColor),
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            AppStrings.doctorRequiredDetailsTitle.tr,
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.doctorRequiredDetailsNote.tr,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  /// Live preview of the card the fields below feed, so it is obvious what
  /// each one is for and what is still blank.
  Widget _previewSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.doctorCardPreviewTitle.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size8),
          DoctorProfileCardPreview(
            photoUrl: details?.logo,
            name: details?.businessName ?? '',
            rating: details?.avg_rating?.toDouble(),
            specialization:
                _specialization.isEmpty ? '' : _specialization.first,
            experienceYears: _experience,
            degree: _degree.join(', '),
            services: _services,
            feeLabel: (_fee ?? 0) <= 0
                ? ''
                : DoctorProfile.formatFee(
                    _fee, DoctorProfile.perVisitFeeType),
          ),
        ],
      );
    });
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
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
            title: _required(AppStrings.doctorSpecialization.tr),
            hintText: AppStrings.doctorSpecializationHint.tr,
            values: _specialization,
            onChanged: (v) => setState(() => _specialization = v),
          ),
          SizedBox(height: SizeConfig.size16),
          _NumberField(
            title: _required(AppStrings.doctorExperience.tr),
            hintText: AppStrings.doctorExperienceHint.tr,
            controller: _experienceCtrl,
            maxLength: 2,
          ),
          SizedBox(height: SizeConfig.size16),
          DoctorChipInputField(
            title: _required(AppStrings.doctorDegree.tr),
            hintText: AppStrings.doctorDegreeHint.tr,
            values: _degree,
            onChanged: (v) => setState(() => _degree = v),
          ),
          SizedBox(height: SizeConfig.size16),
          // Stored as `expertise` — the card labels it "Services", which is
          // also what the Overview tab's expertise editor writes to.
          DoctorChipInputField(
            title: _required(AppStrings.doctorServices.tr),
            hintText: AppStrings.doctorServicesHint.tr,
            values: _services,
            onChanged: (v) => setState(() => _services = v),
          ),
          SizedBox(height: SizeConfig.size16),
          _NumberField(
            title: _required(AppStrings.doctorConsultationFee.tr),
            hintText: AppStrings.doctorFeeHint.tr,
            controller: _feeCtrl,
            maxLength: 6,
          ),
          SizedBox(height: SizeConfig.size24),
          Obx(
            () => CustomBtn(
              isLoading: widget.controller.isSaving.value,
              onTap: widget.controller.isSaving.value ? null : _save,
              title: widget.controller.isSaving.value
                  ? null
                  : AppStrings.doctorSaveAndContinue.tr,
              radius: SizeConfig.size8,
              bgColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _required(String label) => '$label *';
}

/// Digits-only field in the same style as the About Me form's inputs.
class _NumberField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final int maxLength;

  const _NumberField({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.maxLength,
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          style: TextStyle(
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
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
