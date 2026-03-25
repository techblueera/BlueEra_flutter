import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
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
    _businessNameCtrl =
        TextEditingController(text: p.businessName ?? '');
    _descriptionCtrl =
        TextEditingController(text: p.businessDescription ?? '');
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
      appBar: CommonBackAppBar(title: 'Edit Contact Info'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('Business Info'),
            _field(
              controller: _businessNameCtrl,
              label: 'Business Name',
              hint: 'Enter business name',
              prefixIcon: Icons.store_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
            ),
            _field(
              controller: _descriptionCtrl,
              label: 'Description',
              hint: 'Enter description',
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            _field(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'Enter address',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            _field(
              controller: _websiteCtrl,
              label: 'Website URL',
              hint: 'https://example.com',
              prefixIcon: Icons.language_outlined,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasScheme) {
                  return 'Enter a valid URL (e.g. https://example.com)';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _sectionLabel('Owner / Contact Person'),
            _field(
              controller: _ownerNameCtrl,
              label: 'Owner Name',
              hint: 'Enter owner name',
              prefixIcon: Icons.person_outlined,
            ),
            _field(
              controller: _ownerEmailCtrl,
              label: 'Email',
              hint: 'Enter email address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            _field(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'Enter phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length < 7) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : PositiveCustomBtn(
                    onTap: _save,
                    title: 'Save Changes',
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: CustomText(
        label,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
