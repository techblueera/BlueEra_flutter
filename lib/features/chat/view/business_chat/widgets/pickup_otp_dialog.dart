import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

/// Popup to enter & verify the customer's self-pickup OTP. Replaces the old
/// "Call" shortcut on the self-pickup order cards (food / product / grocery).
/// Submits to the pickup endpoint via [OrderNowController.uploadThePickupOtp],
/// which marks the order verified on success.
Future<void> showPickupOtpDialog(BuildContext context,
    {required String orderId}) {
  if (orderId.trim().isEmpty) {
    commonSnackBar(message: 'Order ID not found');
    return Future.value();
  }
  return showDialog(
    context: context,
    builder: (_) => _PickupOtpDialog(orderId: orderId),
  );
}

class _PickupOtpDialog extends StatefulWidget {
  final String orderId;
  const _PickupOtpDialog({required this.orderId});

  @override
  State<_PickupOtpDialog> createState() => _PickupOtpDialogState();
}

class _PickupOtpDialogState extends State<_PickupOtpDialog> {
  final orderController = Get.isRegistered<OrderNowController>()
      ? Get.find<OrderNowController>()
      : Get.put(OrderNowController());
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      commonSnackBar(message: 'Please enter the 4-digit OTP');
      return;
    }
    FocusScope.of(context).unfocus();
    await orderController
        .uploadThePickupOtp({ApiKeys.pickupOTP: otp}, widget.orderId);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.enterOtp.tr,
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: AppColors.grayText),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              'Enter the pickup OTP shared by the customer to verify this order.',
              textAlign: TextAlign.center,
              fontSize: SizeConfig.size12,
              color: AppColors.grayText,
            ),
            SizedBox(height: SizeConfig.size20),
            Pinput(
              length: 4,
              controller: _otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onCompleted: (_) => _submit(),
              defaultPinTheme: PinTheme(
                width: 48,
                height: 48,
                textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            Obx(() => CustomBtn(
                  bgColor: AppColors.primaryColor,
                  isLoading: orderController.ownerOtpLoading.value,
                  onTap: _submit,
                  title: AppStrings.submit.tr,
                )),
          ],
        ),
      ),
    );
  }
}
