import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Congrats! You have won a scratch card" claim popup. Shown once per app
/// launch when the profile API's `joining_bounce.show_card` is true. Claiming
/// credits the bonus to the wallet via the joining-bounce API.
class ClaimBonusDialog extends StatefulWidget {
  final JoiningBounce bounce;

  const ClaimBonusDialog({super.key, required this.bounce});

  @override
  State<ClaimBonusDialog> createState() => _ClaimBonusDialogState();
}

class _ClaimBonusDialogState extends State<ClaimBonusDialog> {
  final JoiningBounceRepo _repo = JoiningBounceRepo();
  bool _agreed = false;
  bool _claiming = false;

  Future<void> _onClaim() async {
    if (_claiming) return;
    if (!_agreed) {
      commonSnackBar(message: 'Please agree to the Terms & Conditions first.');
      return;
    }
    // Avoid a pointless round-trip when the bonus isn't claimable yet.
    if (!widget.bounce.eligible) {
      commonSnackBar(
        message:
            "You're ${widget.bounce.progressPercent}% there — keep using the "
            "app to unlock this bonus.",
      );
      return;
    }
    setState(() => _claiming = true);
    try {
      final res = await _repo.claim(
        joiningBounceId: widget.bounce.joiningBounceId.isEmpty
            ? null
            : widget.bounce.joiningBounceId,
      );
      if (res.isSuccess) {
        commonSnackBar(
            message:
                'Bonus of ₹${widget.bounce.bonusInr} credited to your wallet 🎉');
        if (mounted) Navigator.of(context).maybePop();
      } else {
        commonSnackBar(
            message: res.message ?? 'Could not claim the bonus right now.');
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _openTnc() async {
    final uri = Uri.tryParse(tncLink);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Icon(Icons.close_rounded,
                    size: 20, color: AppColors.secondaryTextColor),
              ),
            ),
            CustomText(
              'Congrats!',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 4),
            CustomText(
              'You have won a scratch card',
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
            const SizedBox(height: 16),

            // ── Scratch card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                children: [
                  DashedBorderContainer(
                    borderRadius: 14,
                    borderColor: AppColors.primaryColor.withValues(alpha: 0.5),
                    strokeWidth: 1.4,
                    dashLength: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 40),
                      child: CustomText(
                        '₹${widget.bounce.bonusInr}',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    "Yay! You've won",
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    'This will be credited to your wallet. You can use it at '
                    'the time of order payment.',
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── T&C agreement ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreed,
                    activeColor: AppColors.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.secondaryTextColor,
                      ),
                      children: [
                        const TextSpan(text: 'Agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = _openTnc,
                        ),
                        const TextSpan(text: ' before claiming.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            CustomBtn(
              width: double.infinity,
              height: SizeConfig.size50,
              radius: 10,
              bgColor: AppColors.primaryColor,
              textColor: AppColors.white,
              isLoading: _claiming,
              title: 'Claim Bonus',
              onTap: _onClaim,
            ),
          ],
        ),
      ),
    );
  }
}
