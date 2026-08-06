import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Asks how the customer wants to reach their captain, then places the call.
///
/// The call button on the ongoing-ride cards used to go straight to the phone
/// dialler, which skipped the app's own calling system entirely. There are two
/// genuinely different things a customer might want here, so the button asks
/// rather than picking for them:
///
///   • **Internet call** — the in-app WebRTC call ([CallController]). Free, and
///     neither side's real number is exposed, since it is keyed on the
///     captain's user id.
///   • **Phone call** — the normal dialler, which still works when one side has
///     no data and is what people fall back to when a ride is going wrong.
///
/// Each option is only offered when it can actually be placed: no captain user
/// id means no internet call, no number means no dialler. When neither is
/// available the sheet isn't shown at all and the caller is told why.
///
/// Shared by the Discover ongoing-ride chip and the Connect tab's card so the
/// same button can't behave differently in the two places it appears.
Future<void> showRiderCallOptionsSheet({
  required String riderName,
  String? riderUserId,
  String? phone,
  String? photoUrl,
}) async {
  final canInternetCall = (riderUserId ?? '').isNotEmpty;
  final canPhoneCall = (phone ?? '').trim().isNotEmpty;

  if (!canInternetCall && !canPhoneCall) {
    commonSnackBar(message: AppStrings.captainContactUnavailable.tr);
    return;
  }

  await Get.bottomSheet<void>(
    _CallOptionsSheet(
      riderName: riderName,
      riderUserId: riderUserId,
      phone: phone,
      photoUrl: photoUrl,
      canInternetCall: canInternetCall,
      canPhoneCall: canPhoneCall,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _CallOptionsSheet extends StatelessWidget {
  const _CallOptionsSheet({
    required this.riderName,
    required this.riderUserId,
    required this.phone,
    required this.photoUrl,
    required this.canInternetCall,
    required this.canPhoneCall,
  });

  final String riderName;
  final String? riderUserId;
  final String? phone;
  final String? photoUrl;
  final bool canInternetCall;
  final bool canPhoneCall;

  /// Place the in-app audio call. Closes the sheet first so the call UI isn't
  /// pushed underneath it.
  Future<void> _internetCall() async {
    Get.back();
    if (!Get.isRegistered<CallController>()) {
      commonSnackBar(message: AppStrings.callingUnavailableRightNow.tr);
      return;
    }
    await Get.find<CallController>().initiateCall(
      type: CallType.audio,
      otherUserId: riderUserId,
      userName: riderName,
      userImage: photoUrl ?? '',
    );
  }

  Future<void> _phoneCall() async {
    Get.back();
    await openDialer(phone!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size20,
        SizeConfig.size12,
        SizeConfig.size20,
        MediaQuery.of(context).padding.bottom + SizeConfig.size20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E9EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            '${AppStrings.callLabel.tr} $riderName',
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size16),
          if (canInternetCall)
            _option(
              icon: Icons.wifi_calling_3_rounded,
              tint: AppColors.primaryColor,
              title: AppStrings.internetCall.tr,
              subtitle: AppStrings.internetCallHint.tr,
              onTap: _internetCall,
            ),
          if (canInternetCall && canPhoneCall)
            SizedBox(height: SizeConfig.size10),
          if (canPhoneCall)
            _option(
              icon: Icons.call_rounded,
              tint: const Color(0xFF1FA463),
              title: AppStrings.phoneCall.tr,
              subtitle: AppStrings.phoneCallHint.tr,
              onTap: _phoneCall,
            ),
        ],
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: tint.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 21),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      title,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.small11,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.secondaryTextColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
