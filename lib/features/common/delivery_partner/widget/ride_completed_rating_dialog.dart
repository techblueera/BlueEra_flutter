import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/full_screen_qr_view.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shown to the rider the moment a ride is completed: confirmation, the QR the
/// passenger scans to pay, and a rating for the customer.
///
/// The rating posts to the **customer's personal** rating endpoint — the rider
/// is rating a person, not a shop — and only when a [customerId] came through
/// with the order. Without one the block still collects the stars and closes
/// with a thank-you rather than showing a Submit that cannot do anything;
/// there is nobody to attach the score to, and inventing one would put a
/// stranger's rating on a random profile.
///
/// Opened on the ROOT navigator (via [Get.dialog]) rather than from the caller's
/// context. Completing a ride makes the orders stream drop it from the ongoing
/// list, which disposes the card that started this — a `showDialog(context:)`
/// from there raced that disposal and simply never appeared.
Future<void> showRideCompletedDialog({
  required String customerName,
  required String qrData,
  String? customerId,
}) {
  return Get.dialog(
    RideCompletedRatingDialog(
      customerName: customerName,
      qrData: qrData,
      customerId: customerId,
    ),
    barrierDismissible: false,
  );
}

class RideCompletedRatingDialog extends StatefulWidget {
  /// Who the QR is shown to, and who the rating is about.
  final String customerName;

  /// Payload encoded in the QR. The payment string will replace this once the
  /// collection flow is defined; today it identifies the order.
  final String qrData;

  /// Who the rating is posted against. Null on an order whose payload carried
  /// no user — the stars still work, they simply go nowhere.
  final String? customerId;

  const RideCompletedRatingDialog({
    super.key,
    required this.customerName,
    required this.qrData,
    this.customerId,
  });

  @override
  State<RideCompletedRatingDialog> createState() =>
      _RideCompletedRatingDialogState();
}

class _RideCompletedRatingDialogState extends State<RideCompletedRatingDialog> {
  int _rating = 0;
  bool _sending = false;
  final TextEditingController _reviewController = TextEditingController();

  /// Shared between the inline code and the full-screen one so the Hero can
  /// match them. Keyed by the payload — two dialogs can't be open at once, but
  /// a constant tag would still be the wrong thing to leave lying around.
  String get _qrHeroTag => 'ride-qr-${widget.qrData}';

  /// Full-screen QR: the code as large as the display allows, on white, because
  /// this is held up for another phone's camera. Tap anywhere to dismiss.
  void _openFullScreenQr(BuildContext context) {
    showFullScreenQr(
      context: context,
      data: widget.qrData,
      heroTag: _qrHeroTag,
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: SizeConfig.size16),
              const _DashedDivider(),
              SizedBox(height: SizeConfig.size16),
              _buildPaymentQr(),
              SizedBox(height: SizeConfig.size16),
              _buildRatingCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.greenCircleTickIcon,
          height: SizeConfig.size80,
          width: SizeConfig.size80,
        ),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          AppStrings.orderCompletedTitle,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.orderCompletedSubtitle,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
        ),
      ],
    );
  }

  /// QR beside the instruction, with the customer's name picked out — the rider
  /// is holding the phone out to a specific person.
  Widget _buildPaymentQr() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tap to blow it up: a 100px code inside a dialog is hard for another
          // phone to lock onto, especially in sunlight or on a cracked screen.
          // The Hero carries the same code into the full-screen view so it
          // visibly grows out of the card rather than cutting to a new page.
          InkWell(
            onTap: () => _openFullScreenQr(context),
            child: Hero(
              tag: _qrHeroTag,
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: SizeConfig.size100,
                padding: EdgeInsets.zero,
                // Scanned off one phone screen by another, often in sunlight.
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                gapless: true,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  fontFamily: 'OpenSans',
                ),
                children: [
                  TextSpan(text: '${AppStrings.showThisQrTo}\n'),
                  TextSpan(
                    text: widget.customerName.isNotEmpty
                        ? widget.customerName
                        : 'Customer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.green1A,
                    ),
                  ),
                  TextSpan(text: '\n${AppStrings.toConfirmYourPayment}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.green1A.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          CustomText(
            AppStrings.howWasYourRide,
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            AppStrings.feedbackHelpsUsImprove,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          _buildStars(),
          // The board writes the word, not the number — `4/5` is a score,
          // `Excellent` is an opinion, and the second is what the rider is
          // actually being asked for.
          SizedBox(
            height: SizeConfig.size20,
            child: CustomText(
              _rating == 0 ? '' : _ratingWords[_rating],
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.greenShade,
            ),
          ),
          SizedBox(height: SizeConfig.size8),
          TextField(
            controller: _reviewController,
            maxLines: 1,
            style: TextStyle(fontSize: SizeConfig.medium),
            decoration: InputDecoration(
              hintText: AppStrings.writeAShortReview,
              hintStyle: TextStyle(
                fontSize: SizeConfig.medium,
                color: AppColors.grey9A,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyE5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomBtn(
            title: AppStrings.submit.tr,
            // No star, no submit: a dialog that opens on five stars collects
            // five stars from every rider who taps straight through it.
            onTap: _rating == 0 || _sending ? null : _handleSubmit,
            height: SizeConfig.size48,
            radius: 24,
            bgColor: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  static const _ratingWords = [
    '', 'Poor', 'Fair', 'Good', 'Great', 'Excellent',
  ];

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = star <= _rating;
        return IconButton(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
          constraints: const BoxConstraints(),
          onPressed: () => setState(() => _rating = star),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: SizeConfig.size32,
            color: filled ? AppColors.yellow00 : AppColors.secondaryTextColor,
          ),
        );
      }),
    );
  }

  /// Posts the rider's rating of the customer.
  ///
  /// The dialog closes either way. Completing a ride is done; holding a rider
  /// on a retry screen for a score that changes nothing about the order —
  /// while their next job is coming in — is the wrong trade.
  Future<void> _handleSubmit() async {
    if (_rating == 0 || _sending) return;
    final userId = (widget.customerId ?? '').trim();

    if (userId.isEmpty) {
      Navigator.of(context).pop();
      commonSnackBar(message: AppStrings.thanksForYourFeedback);
      return;
    }

    setState(() => _sending = true);
    try {
      await BusinessProfileRepo().submitRatingToPersonal(
        userId,
        {'rating': _rating, 'comment': _reviewController.text.trim()},
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        Navigator.of(context).pop();
        commonSnackBar(message: AppStrings.thanksForYourFeedback);
      }
    }
  }
}
/// The hairline under the header, drawn as a dashed rule.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dash,
              height: 1,
              color: AppColors.greyE5,
            ),
          ),
        );
      },
    );
  }
}
