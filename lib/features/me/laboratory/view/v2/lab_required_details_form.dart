import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/facility_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/widgets/lab_category_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_profile_card_preview.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_switch_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Mandatory-details gate for the laboratory dashboard.
///
/// The redesigned listing card (`docs/labnew.png`) renders a cover photo, the
/// lab type line, a description and the Tests / Facilities counters. A card
/// missing any of them reads as broken rather than sparse, so
/// `LabHomeScreenV2` shows this form INSTEAD of its tabs until all of them
/// exist — the same shape as the doctor dashboard's gate.
///
/// Deliberately a plain widget, not a route: it renders inside the dashboard
/// body under the existing top bar, so the drawer, notifications and Go-Live
/// stay reachable and the user is never trapped in a screen with no exit.
///
/// Nothing here is a new surface for data that already has an owner — tests
/// are still added through [LabCategoryScreen] and the facility flags are the
/// same [FacilityController] the Facilities tab writes. The form only gathers
/// them in one place and refuses to let the tabs open until they are filled.
class LabRequiredDetailsForm extends StatefulWidget {
  final LabFullDetailsController controller;

  const LabRequiredDetailsForm({super.key, required this.controller});

  @override
  State<LabRequiredDetailsForm> createState() => _LabRequiredDetailsFormState();
}

class _LabRequiredDetailsFormState extends State<LabRequiredDetailsForm> {
  /// Same cap the standalone description screen enforces.
  static const int _maxDescLength = 500;

  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  /// Registered permanently to match [FacilityScreen] — both surfaces edit the
  /// same flags, and sharing one instance keeps them from drifting apart.
  late final FacilityController _facilityController;

  final _typeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  /// Picked but not yet uploaded. Uploading happens on save so an abandoned
  /// form never leaves an orphan image on S3.
  File? _coverFile;

  bool _isPickingCover = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FacilityController>()) {
      _facilityController = Get.put(FacilityController(), permanent: true);
    } else {
      _facilityController = Get.find<FacilityController>();
    }

    // Prefilled from whatever the lab already has, so a profile created before
    // the card redesign is only asked for the pieces it is actually missing.
    _typeCtrl.text = widget.controller.labType.isNotEmpty
        ? widget.controller.labType
        : _businessSubCategory;
    _descCtrl.text = widget.controller.labDescription;

    // The preview mirrors both fields live.
    _typeCtrl.addListener(_onChanged);
    _descCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _typeCtrl.removeListener(_onChanged);
    _descCtrl.removeListener(_onChanged);
    _typeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// The business sub-category picked at sign-up — the same value the hospital
  /// card renders in this slot. Used to seed the Lab type field so the common
  /// case is one tap.
  String get _businessSubCategory =>
      (_businessController.businessProfileDetails.value?.data?.subCategoryDetails
                  ?.name ??
              '')
          .trim();

  // ── Cover picker ──────────────────────────────────────────────────────

  Future<void> _pickCover() async {
    if (_isPickingCover) return;
    setState(() => _isPickingCover = true);
    try {
      final path = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.labCoverPhoto.tr,
        cropAspectRatio: const CropAspectRatio(width: 16, height: 9),
      );
      if (path == null || path.isEmpty) return;

      final file = File(path);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      if (!mounted) return;
      setState(() => _coverFile = File(compressed?.path ?? path));
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed.tr);
    } finally {
      if (mounted) setState(() => _isPickingCover = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────

  bool get _hasCover =>
      _coverFile != null || widget.controller.coverUrl.isNotEmpty;

  bool get _hasAnyFacility =>
      _facilityController.wheelchairAssistance.value ||
      _facilityController.doctorConsultationTieUp.value ||
      _facilityController.insuranceCashlessSupport.value ||
      _facilityController.homeSampleCollection.value ||
      _facilityController.digitalReport.value;

  /// Every field here is mandatory, so this validates presence first and only
  /// then the one length cap the server enforces.
  String? _validate() {
    if (!_hasCover) return AppStrings.labCoverPhotoRequired.tr;
    if (_typeCtrl.text.trim().isEmpty) return AppStrings.labTypeRequired.tr;
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return AppStrings.labDescriptionRequired.tr;
    if (desc.length > _maxDescLength) {
      return AppStrings.labDescriptionTooLong.tr;
    }
    if (widget.controller.testCount <= 0) {
      return AppStrings.labTestsRequiredError.tr;
    }
    if (!_hasAnyFacility) return AppStrings.labFacilitiesRequiredError.tr;
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      commonSnackBar(message: error);
      return;
    }

    // Profile first: on a brand-new lab this is the call that creates the
    // record and populates `labIDGlobal`, which the facilities payload needs
    // to address the right laboratory.
    final profileSaved = await widget.controller.saveRequiredDetails(
      coverFile: _coverFile,
      labType: _typeCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
    if (!profileSaved) return;

    final facilitiesSaved = await _facilityController.saveFacilities();
    if (!facilitiesSaved) return;

    // Re-read so `details.facility` reflects the flags just written — that is
    // what flips the dashboard's gate over to the tabs.
    await widget.controller.fetchFullDetails();
    if (mounted) setState(() => _coverFile = null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

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
      decoration: _cardDecoration,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.biotech_outlined,
                size: 24, color: AppColors.primaryColor),
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            AppStrings.labRequiredDetailsTitle.tr,
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.labRequiredDetailsNote.tr,
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
      final address = (details?.address ?? details?.cityStatePincode ?? '').trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.labCardPreviewTitle.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size8),
          LabProfileCardPreview(
            coverFile: _coverFile,
            coverUrl: widget.controller.coverUrl,
            name: details?.businessName ?? '',
            rating: details?.avg_rating?.toDouble(),
            labType: _typeCtrl.text.trim(),
            address: address,
            isOpenNow: _businessController.isLive.value,
            testCount: widget.controller.testCount,
            facilityCount: widget.controller.facilityCount,
          ),
        ],
      );
    });
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(AppStrings.labCoverPhoto.tr),
          SizedBox(height: SizeConfig.size8),
          _coverPicker(),
          SizedBox(height: SizeConfig.size16),
          _TextField(
            title: _required(AppStrings.labTypeLabel.tr),
            hintText: AppStrings.labTypeHint.tr,
            controller: _typeCtrl,
            maxLength: 60,
          ),
          SizedBox(height: SizeConfig.size16),
          _TextField(
            title: _required(AppStrings.labDescriptionLabel.tr),
            hintText: AppStrings.labDescriptionHint.tr,
            controller: _descCtrl,
            maxLength: _maxDescLength,
            maxLines: 4,
          ),
          SizedBox(height: SizeConfig.size16),
          _testsRow(),
          SizedBox(height: SizeConfig.size16),
          _facilitiesBlock(),
          SizedBox(height: SizeConfig.size24),
          Obx(() {
            final busy = widget.controller.isSaving.value ||
                _facilityController.isSaving.value;
            return CustomBtn(
              isLoading: busy,
              onTap: busy ? null : _save,
              title: busy ? null : AppStrings.labSaveAndContinue.tr,
              radius: SizeConfig.size8,
              bgColor: AppColors.primaryColor,
            );
          }),
        ],
      ),
    );
  }

  // ── Cover ─────────────────────────────────────────────────────────────

  Widget _coverPicker() {
    final existing = widget.controller.coverUrl;
    return GestureDetector(
      onTap: _pickCover,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasCover ? const Color(0xFFE3E8F0) : AppColors.red,
              width: _hasCover ? 1 : 1.5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_coverFile != null)
                Image.file(_coverFile!, fit: BoxFit.cover)
              else if (existing.isNotEmpty)
                CachedNetworkImage(imageUrl: existing, fit: BoxFit.cover)
              else
                _coverEmptyState(),
              if (_isPickingCover)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  ),
                ),
              if (_hasCover)
                Positioned(
                  right: SizeConfig.size8,
                  bottom: SizeConfig.size8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      AppStrings.edit.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_camera_outlined,
            size: 26, color: AppColors.primaryColor),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.labCoverPhotoHint.tr,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  // ── Tests ─────────────────────────────────────────────────────────────

  /// Tests are not typed in here — they are catalog picks. This row reports
  /// the current count and hands off to the existing add-test flow, then
  /// refetches on return so the counter (and the preview) update.
  Widget _testsRow() {
    final count = widget.controller.testCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_required(AppStrings.labTestsLabel.tr)),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.all(SizeConfig.size12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: count > 0 ? const Color(0xFFE3E8F0) : AppColors.red,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomText(
                  count > 0
                      ? '$count ${AppStrings.labTestsAddedSuffix.tr}'
                      : AppStrings.labNoTestsAddedYet.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: count > 0
                      ? AppColors.mainTextColor
                      : AppColors.secondaryTextColor,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              InkWell(
                onTap: _openAddTests,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12,
                    vertical: SizeConfig.size8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        AppStrings.labAddTests.tr,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAddTests() async {
    await Get.to(() => LabCategoryScreen(controller: widget.controller));
    await widget.controller.fetchFullDetails();
    if (mounted) setState(() {});
  }

  // ── Facilities ────────────────────────────────────────────────────────

  Widget _facilitiesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_required(AppStrings.labFacilitiesLabel.tr)),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          AppStrings.labFacilitiesGateHint.tr,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          maxLines: 3,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE3E8F0)),
          ),
          child: Column(
            children: [
              LabSwitchRow(
                title: AppStrings.homeSampleCollection.tr,
                value: _facilityController.homeSampleCollection,
                onChanged: _onFacilityToggled,
              ),
              LabSwitchRow(
                title: AppStrings.digitalReport.tr,
                value: _facilityController.digitalReport,
                onChanged: _onFacilityToggled,
              ),
              LabSwitchRow(
                title: AppStrings.wheelchairAssistance.tr,
                value: _facilityController.wheelchairAssistance,
                onChanged: _onFacilityToggled,
              ),
              LabSwitchRow(
                title: AppStrings.doctorConsultationTieUp.tr,
                value: _facilityController.doctorConsultationTieUp,
                onChanged: _onFacilityToggled,
              ),
              LabSwitchRow(
                title: AppStrings.insuranceCashlessSupport.tr,
                value: _facilityController.insuranceCashlessSupport,
                onChanged: _onFacilityToggled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onFacilityToggled() {
    _facilityController.validateForm();
    setState(() {});
  }

  // ── Shared bits ───────────────────────────────────────────────────────

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      );

  Widget _label(String text) => CustomText(
        text,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w500,
        color: AppColors.mainTextColor,
      );

  String _required(String label) => '$label *';
}

/// Text input in the same style as the lab module's other forms.
class _TextField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final int maxLength;
  final int maxLines;

  const _TextField({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.maxLength,
    this.maxLines = 1,
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
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
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
