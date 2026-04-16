import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalContactEditScreen extends StatefulWidget {
  final BusinessProfile profile;
  final ViewBusinessDetailsController businessController;
  final String businessId;

  const MedicalContactEditScreen({
    super.key,
    required this.profile,
    required this.businessController,
    required this.businessId,
  });

  @override
  State<MedicalContactEditScreen> createState() =>
      _MedicalContactEditScreenState();
}

class _MedicalContactEditScreenState extends State<MedicalContactEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _ownerEmailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final owner = p.ownerDetails?.firstOrNull;
    _businessNameCtrl = TextEditingController(text: p.businessName ?? '');
    _descriptionCtrl = TextEditingController(text: p.businessDescription ?? '');
    _addressCtrl = TextEditingController(text: p.address ?? '');
    _websiteCtrl = TextEditingController(text: p.websiteUrl ?? '');
    _ownerNameCtrl = TextEditingController(text: owner?.name ?? '');
    _ownerEmailCtrl = TextEditingController(text: owner?.email ?? '');
    _phoneCtrl = TextEditingController(
        text: p.businessNumber?.officeMobNo?.number ?? '');
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final params = <String, dynamic>{
      ApiKeys.businessId: widget.businessId,
      ApiKeys.business_name: _businessNameCtrl.text.trim(),
      ApiKeys.business_description: _descriptionCtrl.text.trim(),
      ApiKeys.address: _addressCtrl.text.trim(),
      ApiKeys.websiteUrl: _websiteCtrl.text.trim(),
      ApiKeys.ownerName: _ownerNameCtrl.text.trim(),
      ApiKeys.email: _ownerEmailCtrl.text.trim(),
      ApiKeys.phoneNumber: _phoneCtrl.text.trim(),
    };

    await widget.businessController.updateBusinessProfileDetails(params);
    setState(() => _isSaving = false);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: AppStrings.editContactInfo),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size16,
            ),
            children: [
              // ─── BUSINESS INFO ───
              _sectionCard(
                icon: Icons.store_outlined,
                title: AppStrings.businessInfoSection.tr,
                children: [
                  CommonTextField(
                    textEditController: _businessNameCtrl,
                    title: AppStrings.businessName.tr,
                    hintText: AppStrings.enterBusinessName.tr,
                    keyBoardType: TextInputType.text,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.businessNameRequired.tr
                        : null,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: _descriptionCtrl,
                    title: AppStrings.description.tr,
                    hintText: AppStrings.enterDescriptionHint.tr,
                    keyBoardType: TextInputType.multiline,
                    maxLine: 3,
                    minLines: 3,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: _addressCtrl,
                    title: AppStrings.addressLabel.tr,
                    hintText: AppStrings.enterAddress.tr,
                    keyBoardType: TextInputType.streetAddress,
                    maxLine: 2,
                    minLines: 2,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: _websiteCtrl,
                    title: AppStrings.websiteUrlLabel.tr,
                    hintText: AppStrings.websiteUrlHint.tr,
                    keyBoardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return AppStrings.enterValidUrl.tr;
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: SizeConfig.size12),

              // ─── OWNER / CONTACT PERSON ───
              _sectionCard(
                icon: Icons.person_outline,
                title: AppStrings.ownerContactPersonSection.tr,
                children: [
                  CommonTextField(
                    textEditController: _ownerNameCtrl,
                    title: AppStrings.ownerNameLabel.tr,
                    hintText: AppStrings.enterOwnerName.tr,
                    keyBoardType: TextInputType.name,
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: _ownerEmailCtrl,
                    title: AppStrings.email.tr,
                    hintText: AppStrings.enterEmailAddress.tr,
                    keyBoardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex =
                          RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return AppStrings.invalidEmail.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    textEditController: _phoneCtrl,
                    title: AppStrings.phoneNumberLabel.tr,
                    hintText: AppStrings.enterPhoneNumberHint.tr,
                    keyBoardType: TextInputType.phone,
                    inputLength: 15,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (v.trim().length < 7) {
                        return AppStrings.enterValidPhoneNumber.tr;
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: SizeConfig.size24),

              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : PositiveCustomBtn(
                      onTap: _save,
                      title: AppStrings.saveChanges,
                    ),
              SizedBox(height: SizeConfig.size30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section card with header icon + title ───
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                title,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          Divider(
            color: AppColors.greyE5,
            height: SizeConfig.size20,
          ),
          ...children,
        ],
      ),
    );
  }
}
