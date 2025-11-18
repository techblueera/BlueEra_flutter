import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class BlinkingVerifyButton extends StatefulWidget {
  final VoidCallback onTap;

  const BlinkingVerifyButton({super.key, required this.onTap});

  @override
  State<BlinkingVerifyButton> createState() => _BlinkingVerifyButtonState();
}

class _BlinkingVerifyButtonState extends State<BlinkingVerifyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // speed
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.redLite,
                  borderRadius: BorderRadius.circular(8)),
              child: const CustomText(
                AppStrings.verifyNow,
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}