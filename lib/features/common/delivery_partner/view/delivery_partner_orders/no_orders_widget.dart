import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class NoOrdersWidget extends StatefulWidget {
  final String? title;
  final String? subtitle;

  const NoOrdersWidget({super.key, this.title, this.subtitle});

  @override
  State<NoOrdersWidget> createState() => _NoOrdersWidgetState();
}

class _NoOrdersWidgetState extends State<NoOrdersWidget>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _breathController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<Offset> _slideUp;
  late Animation<double> _breathScale;
  late Animation<double> _breathOpacity;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _scaleUp = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.elasticOut));
    _slideUp = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Breathing animation — continuous loop
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
    _breathOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.06, end: 0.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.06), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));

    _entryController.forward();
    // Start breathing after entry completes
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _breathController.repeat();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Breathing icon
                ScaleTransition(
                  scale: _scaleUp,
                  child: AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _breathScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: _breathOpacity.value),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delivery_dining_outlined,
                                size: 34,
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                CustomText(
                  widget.title ?? "Oops! No Orders Yet",
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                CustomText(
                  widget.subtitle ??
                      "New orders will appear here.\nStay online to receive orders!",
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  textAlign: TextAlign.center,
                  height: 1.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
