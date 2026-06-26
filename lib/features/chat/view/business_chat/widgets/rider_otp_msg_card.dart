import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/repo/make_order_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

/// Renders a chat handoff OTP card (`message_type: "rider_otp"`).
///
/// Per the flipped-direction handoff (RIDER_FRONTEND_INTEGRATION_GUIDE §8) the
/// OTP travels from the person receiving the service to the person performing
/// the action, so the two private variants (server-filtered via `visible_to`)
/// render differently:
///   • pickup   → shown to the SHOP as an OTP **input + confirm** (`mode:enter`).
///                The rider reads the digits out; the shop types them to release
///                the goods → `POST /riders/orders/:id/pickup` (single shop) or
///                `PATCH /fare/multi-shop/orders/:id/stops/:businessId/pickup`.
///   • delivery → shown to the CUSTOMER as the **digits** (`mode:show`) to read
///                to the rider, who enters them in the rider app.
///
/// When the server flips `status` to "consumed" (via the `riderOtpUpdated`
/// socket, handled in ChatViewController), the card greys out with a
/// "Picked up" / "Delivered" check.
class RiderOtpMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const RiderOtpMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<RiderOtpMsgCard> createState() => _RiderOtpMsgCardState();
}

class _RiderOtpMsgCardState extends State<RiderOtpMsgCard> {
  final _otpController = TextEditingController();
  bool _submitting = false;

  RiderOtpInfo? get _otp => widget.message.metadata?.riderOtp;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Shop confirms the pickup OTP the rider read out. Routes to the multi-shop
  /// per-stop endpoint when the card belongs to one shop of a multi-stop order,
  /// otherwise the single-shop pickup endpoint.
  Future<void> _confirmPickup() async {
    final otp = _otp;
    if (otp == null) return;
    final entered = _otpController.text.trim();
    if (entered.length < 4) {
      commonSnackBar(message: 'Please enter the 4-digit OTP');
      return;
    }
    // The ride order id (RideOrder._id) from the card payload is the only valid
    // id for the rider-service pickup endpoint. selfpickupOrderId is the
    // original grocery/food/product order id from a DIFFERENT service — using it
    // as a fallback always 404s (see MULTISHOP_PICKUP_OTP_FIX_GUIDE.md).
    final orderId = otp.rideOrderId ?? '';
    if (orderId.isEmpty) {
      commonSnackBar(message: 'Order reference missing');
      return;
    }

    // A multi-shop card MUST go to the per-stop endpoint with its own
    // businessId. Falling back to the single-shop POST for a multi-stop order
    // is the bug this card guards against — it 404s ("Order not found"). If the
    // card is multi-stop but the businessId is missing, fail loud instead.
    if (otp.isMultiStop && (otp.businessId ?? '').isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final repo = MakeOrderRepo();
      ResponseModel res;
      if (otp.isMultiStop) {
        res = await repo.multiShopStopPickupApi(
          orderId: orderId,
          businessId: otp.businessId!,
          pickupOTP: entered,
        );
      } else {
        res = await repo.uploadThePickupOtp({'pickupOTP': entered}, orderId);
      }

      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.pickupOrderVerifiedSuccessfully.tr);
        // Optimistic flip; the `riderOtpUpdated` socket also marks it consumed.
        setState(() => otp.status = 'consumed');
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otp = _otp;
    // Defensive: a malformed card without OTP data renders nothing rather than
    // a broken bubble.
    if (otp == null) return const SizedBox.shrink();

    final isPickup = otp.isPickup;
    final consumed = otp.isConsumed;
    final accent = consumed ? AppColors.grey9B : AppColors.primaryColor;
    // Pickup cards on the shop side now collect the OTP (no digits to show).
    final showInput = otp.wantsInput && !consumed;

    final title = isPickup
        ? AppStrings.riderOtpPickupTitle.tr
        : AppStrings.riderOtpDeliveryTitle.tr;
    final consumedLabel =
        isPickup ? AppStrings.riderOtpPickedUp.tr : AppStrings.riderOtpDelivered.tr;

    return Container(
      constraints: BoxConstraints(maxWidth: SizeConfig.screenWidth * 0.72),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: consumed ? AppColors.fillColor : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — icon + role-appropriate title.
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPickup
                      ? Icons.storefront_outlined
                      : Icons.local_shipping_outlined,
                  size: 17,
                  color: accent,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      title,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Multi-shop pickup cards identify which shop they belong
                    // to ("Shop 2 of 3" / shop name) so the rider works the
                    // stops in order.
                    if ((otp.shopLabel ?? '').isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        otp.shopLabel!,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Handoff headline from the customer, e.g. "The order pickup will be
          // done by the rider Rahul". Sits above the OTP input on the shop card.
          if ((otp.message ?? '').isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            CustomText(
              otp.message!,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 3,
            ),
          ],
          SizedBox(height: SizeConfig.size10),

          // Body: either the shop's OTP input (pickup/enter) or the holder's
          // digits (delivery/show, and consumed pickup cards).
          if (showInput) _buildOtpInput(accent) else _buildOtpDigits(accent, consumed),
          SizedBox(height: SizeConfig.size8),

          // Status line: hint while active, "Picked up"/"Delivered" once done.
          if (consumed)
            Row(
              children: [
                Icon(Icons.check_circle, size: 15, color: AppColors.greenShade),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  consumedLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenShade,
                ),
              ],
            )
          else
            CustomText(
              showInput
                  ? 'Enter the pickup OTP the rider gives you to release the order.'
                  : (isPickup
                      ? AppStrings.riderOtpPickupHint.tr
                      : AppStrings.riderOtpDeliveryHint.tr),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),

          // Rider name (when the server included it).
          if ((otp.riderName ?? '').isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: AppColors.grey9B),
                SizedBox(width: SizeConfig.size4),
                Flexible(
                  child: CustomText(
                    otp.riderName!,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: SizeConfig.size6),
          Align(
            alignment: Alignment.bottomRight,
            child: CustomText(
              widget.time,
              fontSize: 10,
              color: AppColors.grey9B,
            ),
          ),
        ],
      ),
    );
  }

  /// Digit display — the holder's card (delivery/customer) and consumed cards.
  Widget _buildOtpDigits(Color accent, bool consumed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size10,
        horizontal: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text(
          _otp?.otp ?? '----',
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: accent,
            decoration:
                consumed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  /// OTP input + confirm — the verifier's card (pickup/shop side).
  Widget _buildOtpInput(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pinput(
          length: 4,
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !_submitting,
          onCompleted: (_) => _confirmPickup(),
          defaultPinTheme: PinTheme(
            width: 44,
            height: 44,
            textStyle: const TextStyle(fontSize: 18, color: Colors.black),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        CustomBtn(
          bgColor: AppColors.primaryColor,
          isLoading: _submitting,
          onTap: _confirmPickup,
          title: AppStrings.submit.tr,
        ),
      ],
    );
  }
}
