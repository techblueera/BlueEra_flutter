// lib/features/app_maintannace/maintenance_screen.dart
//
// Full-screen maintenance / offline interstitial.
//
// Shown whenever AppMaintenanceController reports the platform is degraded,
// OR when the call to the maintenance endpoint itself fails (network down,
// timeout, 5xx). All visuals are drawn with Flutter widgets — no assets, no
// new dependencies.
import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/app_maintannace/app_maintenance_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppMaintenanceController>();
    final isTabletLayout = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: Stack(
        children: [
          // Layered atmosphere — gradient + soft blobs + dot grid.
          const Positioned.fill(child: _Backdrop()),

          // Centered, constrained content.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardMaxWidth =
                    isTabletLayout ? 540.0 : constraints.maxWidth;
                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    // Extra bottom padding reserves space for the pinned
                    // footer wordmark so the scrolled card never visually
                    // overlaps it on small / landscape devices.
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.paddingL,
                      SizeConfig.paddingXL,
                      SizeConfig.paddingL,
                      SizeConfig.paddingXL + 48,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth),
                      child: Obx(() {
                        // While we're actively re-checking, collapse to a
                        // single centered spinner — keeps the transition
                        // calm and avoids stale copy flashing.
                        if (controller.isLoading.value) {
                          return SizedBox(
                            height: 360,
                            child: Center(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return _MaintenanceCard(controller: controller);
                      }),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pinned footer wordmark.
          Positioned(
            left: 0,
            right: 0,
            bottom: SizeConfig.paddingM,
            child: const _Footer(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Backdrop — warm-white linear gradient, two soft radial blobs, dotted grid.
// ---------------------------------------------------------------------------
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBFCFF),
            Color(0xFFEFF5FF),
            Color(0xFFE6EEFC),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _SoftBlob(
              size: 340,
              color: AppColors.primaryColor.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _SoftBlob(
              size: 380,
              color: const Color(0xFF7AB8FF).withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                color: AppColors.primaryColor.withValues(alpha: 0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 26.0;
    const radius = 1.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Main card — pill, hero, headline, reassurance, scheduled-return callout,
// muted secondary links.
// ---------------------------------------------------------------------------
class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.controller});

  final AppMaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _StatusPill(),
        SizedBox(height: SizeConfig.paddingL),
        const _HeroComposition(),
        SizedBox(height: SizeConfig.paddingXL),
        CustomText(
          "We'll be right back.",
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w700,
          fontSize: SizeConfig.heading,
          color: AppColors.black1A,
          height: 1.15,
          letterSpacing: -0.5,
        ),
        SizedBox(height: SizeConfig.paddingS),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
          child: CustomText(
            "We're polishing a few things behind the scenes so your "
            "experience stays smooth. Your account and data are safe with us.",
            textAlign: TextAlign.center,
            fontSize: SizeConfig.medium15,
            color: AppColors.grey72,
            height: 1.55,
          ),
        ),
        SizedBox(height: SizeConfig.paddingXL),
        _MessageBlock(controller: controller),
        SizedBox(height: SizeConfig.paddingM),
        _SecondaryLinks(controller: controller),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status pill — frosted chip with a pulsing dot.
// ---------------------------------------------------------------------------
class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingS,
        vertical: SizeConfig.paddingXSmall + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2EBF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          CustomText(
            "Live status • Maintenance in progress",
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.blue3F,
            letterSpacing: 0.2,
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14 * (0.6 + 0.4 * t),
                height: 14 * (0.6 + 0.4 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color
                      .withValues(alpha: 0.15 + 0.15 * (1 - t)),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — pulsing halo rings, frosted disk, gradient-masked twin gears.
// ---------------------------------------------------------------------------
class _HeroComposition extends StatefulWidget {
  const _HeroComposition();

  @override
  State<_HeroComposition> createState() => _HeroCompositionState();
}

class _HeroCompositionState extends State<_HeroComposition>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = SizeConfig.isTablet ? 260.0 : 220.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding halo rings.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _HaloPainter(progress: _pulse.value),
              );
            },
          ),

          // Frosted center disk with layered light/shadow.
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF1F6FF)],
              ),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.20),
                  blurRadius: 42,
                  offset: const Offset(0, 22),
                  spreadRadius: -10,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
          ),

          // Small counter-rotating gear (back layer).
          Positioned(
            left: size * 0.22,
            top: size * 0.27,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                return Transform.rotate(
                  angle: -_spin.value * 2 * math.pi,
                  child: Icon(
                    Icons.settings_rounded,
                    size: size * 0.22,
                    color: AppColors.primaryColor.withValues(alpha: 0.45),
                  ),
                );
              },
            ),
          ),

          // Main gradient-masked gear.
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) {
              return Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryColor, Color(0xFF005CAF)],
                  ).createShader(rect),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.settings_rounded,
                    size: size * 0.40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // Three concentric rings staggered through one pulse cycle.
    for (int i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final eased = Curves.easeOut.transform(phase);
      final radius = maxRadius * (0.34 + eased * 0.62);
      final opacity = (1 - eased) * 0.38;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.primaryColor.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Message block — shows whatever `controller.message` holds verbatim, inside
// the same soft card frame the old scheduled-return callout used. No time
// computation, no extra copy: the backend message is the source of truth,
// and the block is hidden entirely if the message is empty (error path).
// ---------------------------------------------------------------------------
class _MessageBlock extends StatelessWidget {
  const _MessageBlock({required this.controller});

  final AppMaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = controller.message.value.trim();
      if (msg.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingL,
          vertical: SizeConfig.paddingM,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.10),
              AppColors.primaryColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomText(
          msg,
          textAlign: TextAlign.center,
          fontSize: SizeConfig.medium15,
          fontWeight: FontWeight.w600,
          color: AppColors.black1A,
          height: 1.45,
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Muted secondary links — manual refresh + contact route.
// ---------------------------------------------------------------------------
class _SecondaryLinks extends StatelessWidget {
  const _SecondaryLinks({required this.controller});

  final AppMaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LinkAction(
          icon: Icons.refresh_rounded,
          label: "Refresh",
          onTap: controller.checkMaintenance,
        ),
        Container(
          width: 1,
          height: 14,
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
          color: AppColors.whiteDB,
        ),
        _LinkAction(
          icon: Icons.support_agent_rounded,
          label: "Contact support",
          onTap: () {},
        ),
      ],
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingXS,
          vertical: SizeConfig.paddingXSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.grey72),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.blue3F,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer wordmark pinned to the bottom of the viewport.
// ---------------------------------------------------------------------------
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            "BlueEra • Status",
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.grey9A,
            letterSpacing: 1.4,
          ),
        ],
      ),
    );
  }
}
