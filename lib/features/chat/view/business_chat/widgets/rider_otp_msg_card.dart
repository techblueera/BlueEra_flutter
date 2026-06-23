import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders a chat-dispatch handoff OTP card (`message_type: "rider_otp"`).
///
/// Two private variants arrive over the chat socket (server-filtered via
/// `visible_to`, so this widget never has to hide one itself):
///   • pickup   → shown to the shop; "Show this OTP to the rider at pickup".
///   • delivery → shown to the customer; "Give this OTP to the rider on delivery".
///
/// The card is display-only: the rider verifies the OTP through the existing
/// pickup/deliver endpoints, and the server flips `status` to "consumed" via
/// the `riderOtpUpdated` socket, at which point this card greys out with a
/// "Picked up" / "Delivered" check. See
/// docs/backend/CHAT_DISPATCH_RIDER_FRONTEND_GUIDE.md.
class RiderOtpMsgCard extends StatelessWidget {
  final Messages message;
  final String time;

  const RiderOtpMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final otp = message.metadata?.riderOtp;
    // Defensive: a malformed card without OTP data renders nothing rather than
    // a broken bubble.
    if (otp == null) return const SizedBox.shrink();

    final isPickup = otp.isPickup;
    final consumed = otp.isConsumed;
    final accent = consumed ? AppColors.grey9B : AppColors.primaryColor;

    final title =
        isPickup ? AppStrings.riderOtpPickupTitle.tr : AppStrings.riderOtpDeliveryTitle.tr;
    final hint =
        isPickup ? AppStrings.riderOtpPickupHint.tr : AppStrings.riderOtpDeliveryHint.tr;
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
                child: CustomText(
                  title,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),

          // OTP digits — spaced for readability; struck/greyed once consumed.
          Container(
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
                otp.otp ?? '----',
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
          ),
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
              hint,
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
              time,
              fontSize: 10,
              color: AppColors.grey9B,
            ),
          ),
        ],
      ),
    );
  }
}
