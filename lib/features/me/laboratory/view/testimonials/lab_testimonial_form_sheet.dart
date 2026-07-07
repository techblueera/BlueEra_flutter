import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_testimonial_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_testimonial_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add / edit testimonial bottom sheet. Pops `true` on successful save so
/// the caller knows to refresh (the controller already refreshes on its
/// own via `fetchMyTestimonials`, so callers can just close).
class LabTestimonialFormSheet extends StatefulWidget {
  final LabTestimonial? existing;

  const LabTestimonialFormSheet({super.key, this.existing});

  @override
  State<LabTestimonialFormSheet> createState() => _LabTestimonialFormSheetState();
}

class _LabTestimonialFormSheetState extends State<LabTestimonialFormSheet> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const Color _line = Color(0xFFE5E7EB);

  late final LabTestimonialController _ctrl = getOrPut(() => LabTestimonialController());

  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _messageController = TextEditingController();

  File? _pickedPhoto;
  String? _uploadedPhotoUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.authorName ?? '';
      _designationController.text = e.designation ?? '';
      _messageController.text = e.message ?? '';
      _uploadedPhotoUrl = e.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty &&
      !_ctrl.isSaving.value &&
      !_ctrl.isUploadingImage.value;

  Future<void> _pickPhoto() async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: false,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _pickedPhoto = File(path);
      _uploadedPhotoUrl = null;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || message.isEmpty) {
      commonSnackBar(message: 'Author name and message are required');
      return;
    }

    String? photoUrl = _uploadedPhotoUrl;
    if (_pickedPhoto != null && photoUrl == null) {
      photoUrl = await _ctrl.uploadTestimonialPhoto(_pickedPhoto!);
      if (photoUrl == null) return;
      _uploadedPhotoUrl = photoUrl;
    }

    final t = LabTestimonial(
      id: widget.existing?.id,
      authorName: name,
      designation: _designationController.text.trim(),
      message: message,
      photoUrl: photoUrl,
    );

    bool ok;
    if (_isEdit) {
      ok = await _ctrl.updateTestimonial(t.id ?? '', t.toCreateJson());
    } else {
      ok = await _ctrl.createTestimonial(t);
    }
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabber(),
                _header(),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size20,
                      SizeConfig.size4,
                      SizeConfig.size20,
                      SizeConfig.size8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _photoPicker(),
                        SizedBox(height: SizeConfig.size18),
                        _eyebrow('Author name · required'),
                        SizedBox(height: SizeConfig.size8),
                        CommonTextField(
                          textEditController: _nameController,
                          hintText: 'e.g. Dr. Ramesh Gupta',
                          isValidate: false,
                          onChange: (_) => setState(() {}),
                        ),
                        SizedBox(height: SizeConfig.size18),
                        _eyebrow('Designation · ${AppStrings.optionalLabel.tr}'),
                        SizedBox(height: SizeConfig.size8),
                        CommonTextField(
                          textEditController: _designationController,
                          hintText: 'e.g. Managing Director',
                          isValidate: false,
                        ),
                        SizedBox(height: SizeConfig.size18),
                        _eyebrow('Message · required'),
                        SizedBox(height: SizeConfig.size8),
                        CommonTextField(
                          textEditController: _messageController,
                          hintText: 'What did the customer say?',
                          maxLine: 6,
                          minLines: 3,
                          isValidate: false,
                          onChange: (_) => setState(() {}),
                        ),
                        SizedBox(height: SizeConfig.size20),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: EdgeInsets.only(top: SizeConfig.size10, bottom: SizeConfig.size6),
          decoration: BoxDecoration(
            color: _line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size20, SizeConfig.size6, SizeConfig.size14, SizeConfig.size14),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              _isEdit ? 'Edit Testimonial' : 'Add Testimonial',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 18, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _photoPicker() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              clipBehavior: Clip.antiAlias,
              child: _pickedPhoto != null
                  ? Image.file(_pickedPhoto!, fit: BoxFit.cover, width: 72, height: 72)
                  : ((_uploadedPhotoUrl ?? '').isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _uploadedPhotoUrl!,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.person_rounded, size: 30, color: AppColors.secondaryTextColor),
                        )
                      : Icon(Icons.person_rounded, size: 30, color: AppColors.secondaryTextColor)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: _ctrl.isUploadingImage.value ? null : _pickPhoto,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Author photo',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                'Optional — falls back to initials.',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    final saving = _ctrl.isSaving.value || _ctrl.isUploadingImage.value;
    final enabled = _canSubmit && !saving;
    return Container(
      padding:
          EdgeInsets.fromLTRB(SizeConfig.size20, SizeConfig.size10, SizeConfig.size20, SizeConfig.size14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: enabled ? _save : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: enabled ? const LinearGradient(colors: [_accentDeep, _accent]) : null,
              color: enabled ? null : _line,
              borderRadius: BorderRadius.circular(14),
            ),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : CustomText(
                    _isEdit ? 'Update' : 'Add Testimonial',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : AppColors.greyCA,
                  ),
          ),
        ),
      ),
    );
  }
}
