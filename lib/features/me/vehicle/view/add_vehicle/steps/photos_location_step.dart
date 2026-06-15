import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/widgets/vehicle_form_widgets.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Final step shared by both flows — photo/video upload, location and
/// seller contact. Mirrors the `new3` / `old3` reference screens.
class PhotosLocationStep extends VehicleFormStep {
  final VehicleController controller;
  const PhotosLocationStep({
    super.key,
    required super.draft,
    required this.controller,
  });

  @override
  VehicleFormStepState<PhotosLocationStep> createState() =>
      _PhotosLocationStepState();
}

class _PhotosLocationStepState
    extends VehicleFormStepState<PhotosLocationStep> {
  final _picker = ImagePicker();

  late final TextEditingController _stateCtrl =
      TextEditingController(text: draft.state ?? '');
  late final TextEditingController _cityCtrl =
      TextEditingController(text: draft.city ?? '');
  late final TextEditingController _areaCtrl =
      TextEditingController(text: draft.area ?? '');
  late final TextEditingController _pincodeCtrl =
      TextEditingController(text: draft.pincode?.toString() ?? '');
  late final TextEditingController _sellerNameCtrl =
      TextEditingController(text: draft.sellerName ?? '');
  late final TextEditingController _mobileCtrl =
      TextEditingController(text: draft.sellerMobile ?? '');

  String? _sellerNameErr, _mobileErr;

  @override
  void initState() {
    super.initState();
    // Pre-fill seller contact from the caller's profile, once resolved,
    // without clobbering anything the user already typed.
    widget.controller.fetchSellerDefaults().then((_) {
      if (!mounted) return;
      if (_sellerNameCtrl.text.trim().isEmpty) {
        _sellerNameCtrl.text = widget.controller.sellerDefaultName.value;
      }
      if (_mobileCtrl.text.trim().isEmpty) {
        _mobileCtrl.text =
            _stripCc(widget.controller.sellerDefaultMobile.value);
      }
    });
  }

  /// Strip a leading +91 / 91 country code for display in the +91-prefixed
  /// field.
  String _stripCc(String raw) {
    var v = raw.trim();
    if (v.startsWith('+91')) v = v.substring(3);
    else if (v.startsWith('91') && v.length > 10) v = v.substring(2);
    return v.replaceAll(RegExp(r'\D'), '');
  }

  @override
  void dispose() {
    for (final c in [
      _stateCtrl,
      _cityCtrl,
      _areaCtrl,
      _pincodeCtrl,
      _sellerNameCtrl,
      _mobileCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() =>
          draft.photoFiles.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _pickVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x != null) setState(() => draft.videoFiles.add(File(x.path)));
  }

  @override
  bool validateAndSave() {
    draft.state = _stateCtrl.text.trim();
    draft.city = _cityCtrl.text.trim();
    draft.area = _areaCtrl.text.trim();
    draft.pincode = int.tryParse(_pincodeCtrl.text.trim());
    draft.sellerName = _sellerNameCtrl.text.trim();
    final mobile = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
    draft.sellerMobile = mobile.isEmpty ? '' : '+91$mobile';

    setState(() {
      _sellerNameErr = draft.sellerName!.isEmpty
          ? AppStrings.sellerNameRequiredErr.tr
          : null;
      _mobileErr = mobile.length < 6
          ? (mobile.isEmpty
              ? AppStrings.mobileNumberRequiredErr.tr
              : AppStrings.enterValidPhoneErr.tr)
          : null;
    });

    return _sellerNameErr == null && _mobileErr == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mediaCard(),
        _locationCard(),
        _sellerCard(),
      ],
    );
  }

  Widget _mediaCard() {
    return VehicleSectionCard(
      title: AppStrings.uploadPhotosVideosLabel.tr,
      children: [
        Row(
          children: [
            Expanded(
              child: _UploadTile(
                icon: Icons.camera_alt_outlined,
                label: AppStrings.uploadPhotosLabel.tr,
                onTap: _pickPhotos,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: _UploadTile(
                icon: Icons.videocam_outlined,
                label: AppStrings.uploadVideoLabel.tr,
                onTap: _pickVideo,
              ),
            ),
          ],
        ),
        if (draft.photoFiles.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: draft.photoFiles.length,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
              itemBuilder: (_, i) => _thumb(
                child: Image.file(draft.photoFiles[i], fit: BoxFit.cover),
                onRemove: () => setState(() => draft.photoFiles.removeAt(i)),
              ),
            ),
          ),
        ],
        if (draft.videoFiles.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size10),
          Wrap(
            spacing: SizeConfig.size8,
            runSpacing: SizeConfig.size8,
            children: List.generate(draft.videoFiles.length, (i) {
              return Chip(
                avatar: const Icon(Icons.play_circle_fill,
                    size: 18, color: Colors.white),
                backgroundColor: AppColors.primaryColor,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                label: Text(draft.videoFiles[i].uri.pathSegments.last,
                    overflow: TextOverflow.ellipsis),
                onDeleted: () => setState(() => draft.videoFiles.removeAt(i)),
                deleteIconColor: Colors.white,
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _thumb({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 76, height: 76, child: child),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationCard() {
    return VehicleSectionCard(
      title: AppStrings.location.tr,
      children: [
        VehicleFieldLabel(AppStrings.state.tr),
        CommonTextField(
          textEditController: _stateCtrl,
          hintText: AppStrings.state.tr,
          isValidate: false,
          isOptionalFiled: true,
        ),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.city.tr),
        CommonTextField(
          textEditController: _cityCtrl,
          hintText: AppStrings.city.tr,
          isValidate: false,
          isOptionalFiled: true,
        ),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.areaLocalityLabel.tr),
        CommonTextField(
          textEditController: _areaCtrl,
          hintText: AppStrings.areaHintExample.tr,
          isValidate: false,
          isOptionalFiled: true,
        ),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.pinCodeLabel.tr),
        CommonTextField(
          textEditController: _pincodeCtrl,
          hintText: AppStrings.pinCodeHintExample.tr,
          keyBoardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          isValidate: false,
          isOptionalFiled: true,
        ),
      ],
    );
  }

  Widget _sellerCard() {
    return VehicleSectionCard(
      title: AppStrings.sellerContactDetailsLabel.tr,
      children: [
        VehicleFieldLabel(AppStrings.sellerNameLabel.tr),
        CommonTextField(
          textEditController: _sellerNameCtrl,
          hintText: AppStrings.sellerNameHintExample.tr,
          isValidate: false,
          isOptionalFiled: true,
          onChange: (_) {
            if (_sellerNameErr != null) setState(() => _sellerNameErr = null);
          },
        ),
        VehicleErrorText(_sellerNameErr),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.mobileNumberLabel.tr),
        CommonTextField(
          textEditController: _mobileCtrl,
          hintText: AppStrings.mobileNumberLabel.tr,
          prefixText: '+91 ',
          keyBoardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          isValidate: false,
          isOptionalFiled: true,
          onChange: (_) {
            if (_mobileErr != null) setState(() => _mobileErr = null);
          },
        ),
        VehicleErrorText(_mobileErr),
      ],
    );
  }
}

/// Dashed-style upload affordance used for the photo / video pickers.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            SizedBox(height: SizeConfig.size6),
            CustomText(
              label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
