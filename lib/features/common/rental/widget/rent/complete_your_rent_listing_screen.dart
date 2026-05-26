import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompleteYourRentListingScreen extends StatefulWidget {
  const CompleteYourRentListingScreen({super.key});

  @override
  State<CompleteYourRentListingScreen> createState() =>
      _CompleteYourRentListingScreenState();
}

class _CompleteYourRentListingScreenState
    extends State<CompleteYourRentListingScreen> {
  static const int _maxPhotos = 4;
  static const Color _uploadFill = Color(0xFFE9F0FB);

  late final PropertyController _ctrl;
  final List<String> _photoPaths = [];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
  }

  Future<void> _pickFromCamera() async {
    if (_photoPaths.length >= _maxPhotos) return;
    final path = await PhotoPickerService.pickFromCamera(context);
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
      appBar: CommonBackAppBar(title: 'Complete Your Listing'),
      body: Column(
        children: [
          const RentalStepProgressBar(progress: 1.0),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                                'Upload Your Work Photo',
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
                                  label: 'Take A Picture',
                                  onTap: _pickFromCamera,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _UploadTile(
                                  icon: Icons.folder_outlined,
                                  label: 'Folders',
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
                    child: _RentPriceDetailsSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalBottomBar(
        child: Obx(() => RentalPrimaryButton(
          label: 'Post Now',
          isLoading: _ctrl.isLoading.value,
          onTap: () async {
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
          Image.file(File(path), fit: BoxFit.cover),
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

class _RentPriceDetailsSection extends StatefulWidget {
  const _RentPriceDetailsSection();

  @override
  State<_RentPriceDetailsSection> createState() =>
      _RentPriceDetailsSectionState();
}

class _RentPriceDetailsSectionState extends State<_RentPriceDetailsSection> {
  late final PropertyController _ctrl;
  bool _isRange = false;
  bool _allInclusive = false;
  bool _securityDeposit = false;
  bool _electricityIncluded = false;
  bool _waterIncluded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                'Price Details',
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
                    'Price Range',
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
            children: [
              Expanded(
                child: RentalFieldWithSuffix(
                  label: '',
                  hint: 'Min Price',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ctrl.priceFrom.value = v,
                  suffix: _priceTypeSuffix(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RentalFieldWithSuffix(
                  label: '',
                  hint: 'Max Price',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ctrl.priceTo.value = v,
                  suffix: _priceTypeSuffix(),
                ),
              ),
            ],
          )
        else
          RentalFieldWithSuffix(
            label: '',
            hint: 'E.g. ₹40,660',
            keyboardType: TextInputType.number,
            onChanged: (v) => _ctrl.price.value = v,
            suffix: _priceTypeSuffix(),
          ),
        const SizedBox(height: 12),
        _checkRow('All Inclusive Price', _allInclusive, (v) {
          setState(() => _allInclusive = v);
          _ctrl.allInclusivePrice.value = v;
        }),
        const SizedBox(height: 8),
        _checkRow('Security Deposit', _securityDeposit, (v) {
          setState(() => _securityDeposit = v);
          _ctrl.securityDeposit.value = v;
        }),
        const SizedBox(height: 8),
        _checkRow('Electricity Included', _electricityIncluded, (v) {
          setState(() => _electricityIncluded = v);
          _ctrl.electricityIncluded.value = v;
        }),
        const SizedBox(height: 8),
        _checkRow('Water Charges Included', _waterIncluded, (v) {
          setState(() => _waterIncluded = v);
          _ctrl.waterChargesIncluded.value = v;
        }),
      ],
    );
  }

  Widget _priceTypeSuffix() {
    return GestureDetector(
      onTap: () => _showPriceTypePicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.secondaryTextColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  PropertyController.priceTypeLabels[_ctrl.priceType.value] ??
                      _ctrl.priceType.value,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            )),
      ),
    );
  }

  void _showPriceTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE2EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              CustomText(
                'Select Price Type',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 8),
              ...PropertyController.priceTypeOptions.map(
                (type) {
                  final label =
                      PropertyController.priceTypeLabels[type] ?? type;
                  return Obx(() => ListTile(
                        title: CustomText(
                          label,
                          fontSize: 14,
                          fontWeight: _ctrl.priceType.value == type
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _ctrl.priceType.value == type
                              ? AppColors.primaryColor
                              : AppColors.mainTextColor,
                        ),
                        trailing: _ctrl.priceType.value == type
                            ? Icon(Icons.check_circle,
                                color: AppColors.primaryColor, size: 20)
                            : null,
                        onTap: () {
                          _ctrl.priceType.value = type;
                          Navigator.of(context).pop();
                        },
                      ));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
                  color: _CompleteYourRentListingScreenState._uploadFill,
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
