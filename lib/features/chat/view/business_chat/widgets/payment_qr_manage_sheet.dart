import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/payment_qr_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet for the QR owner to register a UPI Payment QR or view the one
/// they've already registered. See payment-qr-integration-guide.md.
Future<void> showMyPaymentQrSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MyPaymentQrSheet(),
  );
}

class _MyPaymentQrSheet extends StatefulWidget {
  const _MyPaymentQrSheet();

  @override
  State<_MyPaymentQrSheet> createState() => _MyPaymentQrSheetState();
}

class _MyPaymentQrSheetState extends State<_MyPaymentQrSheet> {
  final PaymentQrController _controller = getOrPut(() => PaymentQrController());
  final TextEditingController _upiCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final Rxn<File> _pickedQr = Rxn<File>();

  @override
  void initState() {
    super.initState();
    _controller.loadMyQrs();
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage() async {
    final XFile? picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) _pickedQr.value = File(picked.path);
  }

  Future<void> _register() async {
    final upi = _upiCtrl.text.trim();
    final file = _pickedQr.value;
    if (upi.isEmpty) {
      commonSnackBar(message: 'Enter your UPI ID');
      return;
    }
    if (file == null) {
      commonSnackBar(message: 'Pick your QR image');
      return;
    }
    final qr = await _controller.registerPaymentQr(
      upiId: upi,
      upiPhoneNumber: _phoneCtrl.text.trim(),
      qrImage: file,
    );
    if (qr != null && mounted) {
      _pickedQr.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Obx(() {
            final loading = _controller.isLoadingQrs.value;
            final qr = _controller.primaryQr;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: CustomText(
                    qr != null ? 'My Payment QR' : 'Register Payment QR',
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor),
                    ),
                  )
                else if (qr != null)
                  _registeredView(qr.qrImageUrl, qr.upiId, qr.upiPhoneNumber)
                else
                  _registerForm(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _registeredView(String? imageUrl, String? upiId, String? phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyE5, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: SizeConfig.screenWidth * 0.5,
                  height: SizeConfig.screenWidth * 0.5,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (upiId != null && upiId.isNotEmpty)
          _infoRow('UPI ID', upiId),
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoRow('Phone', phone),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          CustomText('$label: ',
              fontSize: SizeConfig.size13, color: AppColors.secondaryTextColor),
          Expanded(
            child: CustomText(
              value,
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(_upiCtrl, 'UPI ID (e.g. name@okhdfcbank)',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _textField(_phoneCtrl, 'UPI phone number (optional)',
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        // QR image picker
        Obx(() {
          final file = _pickedQr.value;
          return InkWell(
            onTap: _pickQrImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: file == null ? 56 : 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.35),
                    width: 1.2),
              ),
              child: file == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            color: AppColors.primaryColor),
                        const SizedBox(width: 8),
                        CustomText('Pick QR image',
                            fontSize: SizeConfig.size14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file, fit: BoxFit.contain),
                    ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Obx(() => SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _controller.isRegistering.value ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _controller.isRegistering.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : CustomText('Register QR',
                        fontSize: SizeConfig.size15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
              ),
            )),
      ],
    );
  }

  Widget _textField(TextEditingController c, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}
