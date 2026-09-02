import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/common/joining_bounce/view/widget/scratch_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Congrats! You have won a scratch card" claim popup. Shown once per app
/// launch when the profile API's `joining_bounce.show_card` is true.
///
/// The reward stays hidden behind a blue scratch surface — the user must
/// scratch it open. Past ~40% of the card ([ScratchCard]'s default) the amount
/// reveals with a burst of confetti and the "Claim Bonus" button becomes
/// active. Claiming credits the bonus to the wallet via the joining-bounce API.
class ClaimBonusDialog extends StatefulWidget {
  final JoiningBounce bounce;

  const ClaimBonusDialog({super.key, required this.bounce});

  @override
  State<ClaimBonusDialog> createState() => _ClaimBonusDialogState();
}

class _ClaimBonusDialogState extends State<ClaimBonusDialog> {
  final JoiningBounceRepo _repo = JoiningBounceRepo();
  bool _claiming = false;

  /// True once the user has scratched enough of the card to reveal the reward.
  /// Gates the confetti burst and the Claim button.
  bool _revealed = false;

  void _onRevealed() {
    if (_revealed) return;
    setState(() => _revealed = true);
  }

  Future<void> _onClaim() async {
    if (_claiming || !_revealed) return;
    // `tag_id` is the only required field for /createclaim; without it the
    // backend can't resolve the plan.
    final tagId = widget.bounce.tagId;
    if (tagId == null || tagId.isEmpty) {
      commonSnackBar(
          message: 'Bonus details are missing. Please try again later.');
      return;
    }
    setState(() => _claiming = true);
    try {
      // POST /joining-bounce/createclaim { tag_id, account_type? }.
      // account_type is optional (resolved from the JWT) — sent when known.
      final res = await _repo.createClaim(
        tagId: tagId,
        accountType: widget.bounce.accountType,
      );
      if (res.isSuccess) {
        final serverMsg = res.message?.toString();
        commonSnackBar(
            message: (serverMsg != null && serverMsg.isNotEmpty)
                ? serverMsg
                : 'Joining bonus activated 🎉');
        // Close THIS dialog SYNCHRONOUSLY before navigating. maybePop() defers
        // the pop (it awaits willPop as a microtask), so the wallet would get
        // pushed on top of the still-present dialog — backing out of the wallet
        // would then reveal the dialog again and let the bonus be claimed a
        // second time. A plain pop() removes the dialog before the push.
        if (mounted) Navigator.of(context).pop();
        Get.to(() => const WalletScreen());
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
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
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

                // ── Scratch card: reward hidden behind a scratchable cover ──
                // Fixed height so the card is the SAME size before and after
                // scratching. The revealed surface is white with a primary
                // border (shown once the cover is scratched away).
                ScratchCard(
                  revealed: _revealed,
                  onRevealed: _onRevealed,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: _revealedReward(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── T&C notice (informational; tap to open the T&C) ───────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                    children: [
                      const TextSpan(text: 'By claiming, you agree to our '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _openTnc,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Active only once the card is scratched.
                CustomBtn(
                  width: double.infinity,
                  height: SizeConfig.size40,
                  radius: 10,
                  isValidate: _revealed,
                  bgColor:
                      _revealed ? AppColors.primaryColor : AppColors.whiteF3,
                  textColor: _revealed ? AppColors.white : AppColors.grey9B,
                  isLoading: _claiming,
                  title: 'Claim Bonus',
                  onTap: _revealed ? _onClaim : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The reward hidden under the scratch surface — amount + congrats copy.
  Widget _revealedReward() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashedBorderContainer(
          borderRadius: 14,
          borderColor: AppColors.primaryColor.withValues(alpha: 0.5),
          strokeWidth: 1.4,
          dashLength: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
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
    );
  }
}
