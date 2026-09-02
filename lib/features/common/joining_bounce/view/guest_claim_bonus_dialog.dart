import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/joining_bounce/view/claim_bonus_dialog.dart';
import 'package:BlueEra/features/common/joining_bounce/view/widget/scratch_card.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Guest variant of the scratch-card popup — laid out to
/// `assets/claim_dialog_ui.png`.
///
/// Under the scratch cover is [AppImageAssets.claimDialog], a single piece of
/// artwork that carries the whole offer ("Create your account, and get your
/// ₹100 joining bonus", the bonus ticket, and the wallet strip). Scratching
/// past ~40% fades the cover away, reveals the full image with a confetti
/// burst, and activates the **Create Account Now** CTA.
///
/// This is the guest counterpart to [ClaimBonusDialog], shown when
/// [isGuestUser] is true. The difference is what is underneath: the signed-in
/// card reveals a real, claimable `bonus_inr` off the API, while a guest has no
/// profile and therefore no `JoiningBounce` at all — so theirs is a fixed promo
/// image and the CTA leads to sign-up rather than to a claim.
///
/// **The ₹100 lives in the artwork, not in code.** There is no amount constant
/// here to change; re-quoting the offer means replacing the PNG.
class GuestClaimBonusDialog extends StatefulWidget {
  const GuestClaimBonusDialog({super.key});

  /// Aspect ratio of [AppImageAssets.claimDialog] (960x630).
  ///
  /// The card is sized by the artwork's OWN ratio rather than a fixed height so
  /// the image is never cropped or letterboxed on any screen width — every word
  /// in it is baked into the pixels, so losing an edge loses copy.
  static const double _artworkAspect = 960 / 630;

  @override
  State<GuestClaimBonusDialog> createState() => _GuestClaimBonusDialogState();
}

class _GuestClaimBonusDialogState extends State<GuestClaimBonusDialog> {
  /// True once the guest has scratched enough to enable the Create Profile CTA.
  bool _scratchedEnough = false;

  void _onScratched() {
    if (_scratchedEnough) return;
    setState(() => _scratchedEnough = true);
  }

  void _onCreateProfile() {
    Navigator.of(context).maybePop();
    createProfileScreen();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Heading with the close button ON THE SAME LINE, as drawn.
            //
            // It used to be an Align in a row of ITS OWN, above the heading —
            // which pushed "Congrats!" down by the height of the button and
            // left a dead band across the top of the dialog. In the mock the
            // disc floats at the right edge, level with the heading, while the
            // heading stays centred on the dialog. A Stack is what gives both:
            // the full-width Column below sizes the stack and centres the text,
            // and the disc is positioned over its top-right corner without
            // taking any layout space from it.
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                    ],
                  ),
                ),
                // A soft grey disc rather than a bare glyph: it sits over white
                // here, and the disc is what gives it a hit target the eye can
                // find. 34 to match the mock, where the disc measures a little
                // over a tenth of the dialog's content width.
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.whiteF3,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: AppColors.mainTextColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scratch card. Under the cover is the artwork itself, which
            // carries ALL of the offer copy in its pixels: the headline, the
            // ₹100, the bonus ticket and the wallet strip. Nothing is drawn
            // over it — text laid on top would collide with the baked-in text
            // at some width, and there is no width at which both could be
            // right.
            //
            // `revealed: _scratchedEnough`, not a hard `false`. This card used
            // to keep its cover on forever because the guest variant existed to
            // withhold an amount. The artwork states the offer openly, so there
            // is nothing left to withhold: once the guest has scratched past
            // the threshold the remaining cover fades and the whole image is
            // shown (with the confetti burst), instead of leaving them to
            // scrub away every last corner by hand to read it.
            ScratchCard(
              revealed: _scratchedEnough,
              // Threshold left at the shared 40% default — the same gate as the
              // signed-in card, so a guest and a member scratch exactly as far
              // before their card opens.
              onRevealed: _onScratched,
              child: AspectRatio(
                aspectRatio: GuestClaimBonusDialog._artworkAspect,
                child: Image.asset(
                  AppImageAssets.claimDialog,
                  fit: BoxFit.cover,
                  // The card is the whole point of the dialog; if the asset
                  // ever goes missing, fail to a plain branded panel rather
                  // than to Flutter's grey broken-image box.
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: AppColors.primaryColor,
                    child: Center(
                      child: CustomText(
                        'Create your account and get\nyour joining bonus',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            CustomText(
              _scratchedEnough
                  ? 'Create your profile to claim your joining bonus — '
                      'it lands in your wallet straight away.'
                  : 'Scratch the card to see what you have won.',
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Disabled until the guest has scratched ~40% of the card.
            CustomBtn(
              width: double.infinity,
              height: SizeConfig.size40,
              radius: 10,
              isValidate: _scratchedEnough,
              bgColor:
                  _scratchedEnough ? AppColors.primaryColor : AppColors.whiteF3,
              textColor: _scratchedEnough ? AppColors.white : AppColors.grey9B,
              title: 'Create Account Now',
              onTap: _scratchedEnough ? _onCreateProfile : null,
            ),
          ],
        ),
      ),
    );
  }
}
