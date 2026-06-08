import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompleteYourListingScreen extends StatefulWidget {
  const CompleteYourListingScreen({super.key});

  @override
  State<CompleteYourListingScreen> createState() =>
      _CompleteYourListingScreenState();
}

class _CompleteYourListingScreenState extends State<CompleteYourListingScreen> {
  static const int _maxPhotos = 4;
  static const Color _uploadFill = Color(0xFFE9F0FB);

  // Property photos are cropped to a 2:3 portrait frame so every
  // listing's hero image reads consistently across the cards.
  static const CropAspectRatio _cropAspectRatio =
      CropAspectRatio(width: 2, height: 3);

  final List<String> _photoPaths = [];

  // Form-level validation — mirrors how every other create flow in
  // the app gates submission. Inline error messages render under each
  // bad field; the controller now only checks things the form can't
  // (photo count, image upload).
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;

  late final PropertyController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
  }

  Future<void> _pickFromCamera() async {
    if (_photoPaths.length >= _maxPhotos) return;
    final path = await PhotoPickerService.pickFromCamera(
      context,
      cropAspectRatio: _cropAspectRatio,
    );
    if (path != null && mounted) {
      setState(() => _photoPaths.add(path));
      _ctrl.photoPaths.add(path);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_photoPaths.length >= _maxPhotos) return;
    final remaining = _maxPhotos - _photoPaths.length;
    final paths = await PhotoPickerService.pickMultipleFromGallery(
      context,
      maxImages: remaining,
      cropAspectRatio: _cropAspectRatio,
    );
    if (paths != null && paths.isNotEmpty && mounted) {
      setState(() => _photoPaths.addAll(paths));
      _ctrl.photoPaths.addAll(paths);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
    _ctrl.photoPaths.removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.completeYourListing.tr),
      body: Column(
        children: [
          const RentalStepProgressBar(progress: 1.0),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RentalFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                AppStrings.uploadYourWorkPhoto.tr,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor,
                              ),
                            ),
                            CustomText(
                              '${_photoPaths.length}/$_maxPhotos',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_photoPaths.length < _maxPhotos)
                          Row(
                            children: [
                              Expanded(
                                child: _UploadTile(
                                  icon: Icons.camera_alt_outlined,
                                  label: AppStrings.takeAPicture.tr,
                                  onTap: _pickFromCamera,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _UploadTile(
                                  icon: Icons.folder_outlined,
                                  label: AppStrings.foldersLabel.tr,
                                  onTap: _pickFromGallery,
                                ),
                              ),
                            ],
                          ),
                        if (_photoPaths.isNotEmpty) ...[
                          if (_photoPaths.length < _maxPhotos)
                            const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: _photoPaths.length,
                            itemBuilder: (_, i) =>
                                _photoThumb(_photoPaths[i], i),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const RentalFormCard(
                    child: _PriceDetailsSection(),
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalBottomBar(
        child: Obx(() => RentalPrimaryButton(
          label: AppStrings.postNow.tr,
          isLoading: _ctrl.isLoading.value,
          onTap: () async {
            FocusScope.of(context).unfocus();
            // Switch to live autovalidate the moment the user attempts
            // submission so inline errors keep refreshing as they fix
            // things — same pattern step 1 uses.
            setState(() =>
                _autovalidate = AutovalidateMode.onUserInteraction);
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final success = await _ctrl.submitProperty();
            if (success) Get.close(3);
          },
        )),
      ),
    );
  }

  Widget _photoThumb(String path, int index) {
    final radius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(

        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceDetailsSection extends StatefulWidget {
  const _PriceDetailsSection();

  @override
  State<_PriceDetailsSection> createState() => _PriceDetailsSectionState();
}

class _PriceDetailsSectionState extends State<_PriceDetailsSection> {
  late final PropertyController _ctrl;
  bool _isRange = false;
  bool _allInclusive = false;
  bool _negotiable = false;
  bool _taxExcluded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
    // Selling is a one-time transaction — there's no rent duration to
    // pick, so pin the shared [priceType] key to 'OneTime' (still a
    // valid [priceTypeOptions] entry, so step-3 validation passes) and
    // hide the duration chip below.
    if (_ctrl.listingType.value == 'Sell') {
      _ctrl.priceType.value = 'OneTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSell = _ctrl.listingType.value == 'Sell';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                AppStrings.priceDetails.tr,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _isRange = !_isRange);
                _ctrl.isPriceRange.value = _isRange;
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRange
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  CustomText(
                    AppStrings.priceRangeLabel.tr,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isRange)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RentalLabeledField(
                  label: '',
                  hint: AppStrings.minPriceHint.tr,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ctrl.priceFrom.value = v,
                  validator: _numericRequired(AppStrings.enterMinPrice.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RentalLabeledField(
                  label: '',
                  hint: AppStrings.maxPriceHint.tr,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ctrl.priceTo.value = v,
                  validator: _numericRequired(AppStrings.enterMaxPrice.tr),
                ),
              ),
            ],
          )
        else
          RentalLabeledField(
            label: '',
            hint: AppStrings.egRupees40660.tr,
            keyboardType: TextInputType.number,
            onChanged: (v) => _ctrl.price.value = v,
            validator: _numericRequired(AppStrings.enterPrice.tr),
          ),
        const SizedBox(height: 12),
        _checkRow(AppStrings.allInclusivePriceLabel.tr, _allInclusive, (v) {
          setState(() => _allInclusive = v);
          _ctrl.allInclusivePrice.value = v;
        }),
        const SizedBox(height: 8),
        _checkRow(AppStrings.priceNegotiableLabel.tr, _negotiable, (v) {
          setState(() => _negotiable = v);
          _ctrl.priceNegotiable.value = v;
        }),
        const SizedBox(height: 8),
        _checkRow(AppStrings.taxAndGovtChargesExcluded.tr, _taxExcluded, (v) {
          setState(() => _taxExcluded = v);
          _ctrl.taxAndGovtChargeExcluded.value = v;
        }),
        // Rent duration only matters when renting — selling is a
        // one-time price, so this strip is hidden and [priceType] is
        // pinned to 'OneTime' in initState. Wire-format keys live on
        // the controller's [rentDurationOptions]; the chip index maps
        // to that list 1:1 so the controller stays the source of truth
        // without duplicating the string constants here.
        if (!isSell) ...[
          const SizedBox(height: 16),
          RentalChipSelector(
            label: AppStrings.rentDurationLabel.tr,
            options: PropertyController.rentDurationOptions
                .map((k) => PropertyController.priceTypeLabels[k] ?? k)
                .toList(),
            initialIndex: _initialDurationIndex(),
            onChanged: (i) {
              _ctrl.priceType.value =
                  PropertyController.rentDurationOptions[i];
            },
          ),
        ],
        const SizedBox(height: 16),
        // Sell flow reuses the same [securityDepositAmount] key for the
        // token/booking money the buyer puts down, so the wire payload
        // stays identical across both flows — only the label changes.
        RentalLabeledField(
          label: isSell
              ? AppStrings.bookingAmountLabel.tr
              : AppStrings.securityDepositLabel.tr,
          hint: AppStrings.egRupees50000.tr,
          keyboardType: TextInputType.number,
          onChanged: (v) => _ctrl.securityDepositAmount.value = v,
          validator: _numericRequired(
            isSell
                ? AppStrings.enterBookingAmount.tr
                : AppStrings.enterSecurityDepositAmount.tr,
          ),
        ),
      ],
    );
  }

  /// Required-numeric validator factory used by the price / deposit
  /// fields — keeps each call site one-liner short and the messages
  /// consistent.
  String? Function(String?) _numericRequired(String emptyMessage) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return emptyMessage;
      if (int.tryParse(v) == null) return AppStrings.enterValidNumber.tr;
      return null;
    };
  }

  /// Picks the chip index that matches the controller's current
  /// price-type key. Falls back to 0 (Monthly) when the controller
  /// holds a value outside the duration set (e.g. 'OneTime').
  int _initialDurationIndex() {
    final idx = PropertyController.rentDurationOptions
        .indexOf(_ctrl.priceType.value);
    return idx >= 0 ? idx : 0;
  }

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: AppColors.secondaryTextColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          CustomText(
            label,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return SizedBox(
      height: 130,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
          highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _CompleteYourListingScreenState._uploadFill,
                  borderRadius: radius,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: DashedRRectBorder(
                    color: AppColors.primaryColor.withValues(alpha: 0.55),
                    radius: 12,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: AppColors.primaryColor.withValues(alpha: 0.8),
                        size: 30),
                    const SizedBox(height: 8),
                    CustomText(
                      label,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
