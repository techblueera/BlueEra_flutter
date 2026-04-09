import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Branded interactive loader shown while the subscription trial flow
/// hits the network. Used by [SubscriptionPaymentHandler] for both the
/// `/subscription/trial/initiate` call (before Razorpay opens) and the
/// `/subscription/trial/verify` call (after the Razorpay sheet closes).
///
/// Composition:
///   - A circular progress ring around a glowing premium icon. The icon
///     has a continuous breathing scale + halo so the loader always feels
///     alive even if the request is fast.
///   - A bold message line that the caller customises per phase.
///   - A bouncing three-dot indicator below the message.
///
/// Render via Get.dialog with `barrierDismissible: false` so the user
/// can't accidentally tap through it while a network call is in flight.
class SubscriptionLoadingDialog extends StatefulWidget {
  /// Headline shown under the spinner ("Setting up your subscription",
  /// "Verifying your payment", etc.).
  final String message;

  /// Optional supporting line. Defaults to a generic reassurance.
  final String? subtitle;

  const SubscriptionLoadingDialog({
    super.key,
    required this.message,
    this.subtitle,
  });

  @override
  State<SubscriptionLoadingDialog> createState() =>
      _SubscriptionLoadingDialogState();
}

class _SubscriptionLoadingDialogState extends State<SubscriptionLoadingDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size32),
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        // One-shot reveal so the dialog doesn't pop in flat.
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, t, child) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size24,
            vertical: SizeConfig.size28,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.18),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _spinnerCluster(),
              SizedBox(height: SizeConfig.size20),
              CustomText(
                widget.message,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.size6),
              CustomText(
                widget.subtitle ?? 'This will only take a moment.',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.size16),
              _bouncingDots(),
            ],
          ),
        ),
      ),
    );
  }

  /// Circular progress ring + glowing premium icon at the centre.
  Widget _spinnerCluster() {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer spinner ring — always-on motion, branded colour.
          SizedBox(
            width: 86,
            height: 86,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
              backgroundColor:
                  AppColors.primaryColor.withValues(alpha: 0.14),
            ),
          ),
          // Breathing inner badge.
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final t = _pulseController.value;
              return Transform.scale(
                scale: 0.90 + 0.14 * t,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.72),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.45 * (1 - t)),
                        blurRadius: 18 + 10 * t,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Three dots that scale + fade in sequence to reinforce the loading
  /// affordance below the message.
  Widget _bouncingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot is offset by 1/3 of the cycle so they bounce in
            // sequence. The triangular wave gives a smooth in-out feel.
            final phase = (_dotsController.value + i / 3) % 1.0;
            final tri = 1 - (phase * 2 - 1).abs();
            final scale = 0.6 + 0.6 * tri;
            final opacity = 0.35 + 0.65 * tri;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
