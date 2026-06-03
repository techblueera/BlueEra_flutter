import 'dart:ui';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_strings.dart';

class ReferEarnPill extends StatefulWidget {
  const ReferEarnPill({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<ReferEarnPill> createState() => _ReferEarnPillState();
}

class _ReferEarnPillState extends State<ReferEarnPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => Get.to(() => ReferralPage()),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value; // 0 → 1 → 0 loop
          // Bright, warm accents that blink between vivid orange and hot pink.
          const brightA = Color(0xFFFF6D00); // vivid orange
          const brightB = Color(0xFFFF1E56); // hot pink-red
          final accent = Color.lerp(brightA, brightB, t)!;
          final contentColor = accent;
          final borderColor =
              Color.lerp(brightA.withValues(alpha: 0.45), brightB, t)!;

          return Opacity(
            // Blink: bright → dim → bright on every cycle.
            opacity: 1.0 - 0.5 * t,
            child: Transform.scale(
            scale: 1.0 + 0.035 * t,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Pulsing primary glow to catch the eye.
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15 + 0.35 * t),
                    blurRadius: 6 + 12 * t,
                    spreadRadius: 0.5 + 1.5 * t,
                  ),
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                        width: 1 + 0.6 * t,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 14,
                          color: contentColor,
                        ),
                        SizedBox(width: SizeConfig.size6),
                        Flexible(
                          child: CustomText(
                            AppStrings.referAndEarn.tr,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: contentColor,
                            letterSpacing: 0.2,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
