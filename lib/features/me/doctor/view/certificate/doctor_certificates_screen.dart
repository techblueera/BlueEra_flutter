import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_certificate_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/features/me/doctor/view/about/doctor_about_me_edit_screen.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_certificate_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Certificate & Awards — list, add, edit, delete.
///
/// Not paginated: `GET /doctor-certificates/me` returns everything.
class DoctorCertificatesScreen extends StatelessWidget {
  const DoctorCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => DoctorCertificateController());
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: CommonBackAppBar(title: AppStrings.doctorCertificateAwards.tr),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, controller, null),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(
          AppStrings.doctorAddCertificate.tr,
          color: Colors.white,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.certificates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.certificates.isEmpty) {
          return _EmptyState(
            onAdd: () => _openForm(context, controller, null),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchCertificates,
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size14,
              SizeConfig.size14,
              90,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.certificates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (_, i) {
              final cert = controller.certificates[i];
              return Stack(
                children: [
                  Positioned.fill(
                    child: DoctorCertificateCard(
                      certificate: cert,
                      onTap: () => _openForm(context, controller, cert),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => _confirmDelete(context, controller, cert),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    DoctorCertificateController controller,
    DoctorCertificate? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CertificateFormSheet(
        controller: controller,
        existing: existing,
      ),
    );
    // The API answers 404 when the doctor profile does not exist yet. That is
    // a routing signal, not a dead end — send the user to the profile form.
    if (controller.needsProfileFirst.value) {
      controller.needsProfileFirst.value = false;
      Get.to(() => const DoctorAboutMeEditScreen());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DoctorCertificateController controller,
    DoctorCertificate cert,
  ) async {
    await showCommonDialog(
      context: context,
      text: AppStrings.deleteConfirm.tr,
      confirmCallback: () async {
        Get.back();
        await controller.deleteCertificate(id: cert.id ?? '');
      },
      cancelCallback: () => Navigator.of(context).pop(),
      confirmText: AppStrings.yes.tr,
      cancelText: AppStrings.no.tr,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 64, color: Colors.grey[300]),
            SizedBox(height: SizeConfig.size14),
            CustomText(
              AppStrings.doctorNoCertificates.tr,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.medium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size14),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size24,
                  vertical: SizeConfig.size12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: CustomText(
                AppStrings.doctorAddCertificate.tr,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateFormSheet extends StatefulWidget {
  final DoctorCertificateController controller;
  final DoctorCertificate? existing;

  const _CertificateFormSheet({required this.controller, this.existing});

  @override
  State<_CertificateFormSheet> createState() => _CertificateFormSheetState();
}

class _CertificateFormSheetState extends State<_CertificateFormSheet> {
  static const int _titleLimit = 200;
  static const int _descriptionLimit = 1000;

  /// The backend rejects anything larger; checking here avoids a long upload
  /// on mobile data ending in a 400.
  static const int _maxImageBytes = 10 * 1024 * 1024;

  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _issuedByCtrl =
      TextEditingController(text: widget.existing?.issuedBy ?? '');
  late DateTime? _issuedDate = widget.existing?.issuedDate;
  File? _imageFile;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _issuedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.doctorCertificateImage.tr,
    ).catchError((_) => null);
    if (path == null || path.isEmpty) return;

    final file = File(path);
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.path}_compressed.jpg',
      quality: 75,
    );
    final result = File(compressed?.path ?? path);
    if (await result.length() > _maxImageBytes) {
      commonSnackBar(message: AppStrings.doctorImageTooLarge.tr);
      return;
    }
    setState(() => _imageFile = result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _issuedDate = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      commonSnackBar(message: AppStrings.doctorCertificateTitleRequired.tr);
      return;
    }
    if (title.length > _titleLimit) {
      commonSnackBar(message: AppStrings.doctorCertificateTitleLimit.tr);
      return;
    }
    if (_descCtrl.text.trim().length > _descriptionLimit) {
      commonSnackBar(message: AppStrings.doctorDescriptionLimitError.tr);
      return;
    }

    final ok = _isEdit
        ? await widget.controller.updateCertificate(
            id: widget.existing!.id ?? '',
            title: title,
            description: _descCtrl.text,
            issuedBy: _issuedByCtrl.text,
            issuedDate: _issuedDate,
            imageFile: _imageFile,
          )
        : await widget.controller.addCertificate(
            title: title,
            description: _descCtrl.text,
            issuedBy: _issuedByCtrl.text,
            issuedDate: _issuedDate,
            imageFile: _imageFile,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.whiteE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(
                _isEdit
                    ? AppStrings.doctorEditCertificate.tr
                    : AppStrings.doctorAddCertificate.tr,
                fontWeight: FontWeight.w700,
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size16),
              _field(AppStrings.title.tr, _titleCtrl,
                  AppStrings.doctorCertificateTitleHint.tr),
              SizedBox(height: SizeConfig.size12),
              _field(AppStrings.doctorIssuedBy.tr, _issuedByCtrl,
                  AppStrings.doctorIssuedByHint.tr),
              SizedBox(height: SizeConfig.size12),
              _field(AppStrings.description.tr, _descCtrl,
                  AppStrings.doctorCertificateDescHint.tr,
                  maxLines: 3),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                AppStrings.doctorIssuedDate.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.whiteE5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          _issuedDate == null
                              ? AppStrings.doctorSelectDate.tr
                              : DateFormat('dd MMM yyyy').format(_issuedDate!),
                          fontSize: SizeConfig.small,
                          color: _issuedDate == null
                              ? AppColors.grey99
                              : AppColors.mainTextColor,
                        ),
                      ),
                      Icon(Icons.calendar_month_outlined,
                          size: 18, color: AppColors.primaryColor),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          size: 18, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: CustomText(
                          _imageFile != null
                              ? _imageFile!.path.split('/').last
                              : AppStrings.doctorCertificateImage.tr,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      widget.controller.isSaving.value ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.4),
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: widget.controller.isSaving.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : CustomText(
                          AppStrings.save.tr,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                ),
              ),
              SizedBox(height: SizeConfig.size10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String title,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: SizeConfig.small,
              color: AppColors.grey99,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.whiteE5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.whiteE5),
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
