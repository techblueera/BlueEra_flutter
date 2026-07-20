import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Shared visual language for the ride-booking flow.
///
/// The flow is styled as one continuous experience across six screens, so the
/// tokens live here rather than being redeclared per screen.
class RideStyle {
  RideStyle._();

  /// Primary action colour — the yellow "Confirm pickup" / "Book" buttons.
  static const Color action = Color(0xFFFFC300);

  /// Pickup marker / origin dot.
  static const Color pickup = Color(0xFF00A651);

  /// Drop marker / destination dot.
  static const Color drop = Color(0xFFE23A2E);

  /// Deep navy used for headings and primary body copy.
  static const Color ink = Color(0xFF12263F);

  /// Muted secondary copy.
  static const Color inkMuted = Color(0xFF6B7C8F);

  /// Card / divider hairline.
  static const Color hairline = Color(0xFFE4E9EF);

  /// Tinted surface behind grouped sections.
  static const Color surfaceTint = Color(0xFFF4F7FB);

  /// Destructive outline (Cancel Ride).
  static const Color danger = Color(0xFF9E1B1B);

  static const double sheetRadius = 22;

  static List<BoxShadow> get sheetShadow => const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 24,
          offset: Offset(0, -6),
        ),
      ];

  static List<BoxShadow> get floatingShadow => const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];
}

/// The grab handle at the top of every bottom sheet in this flow.
class RideSheetHandle extends StatelessWidget {
  const RideSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: RideStyle.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// White circular map button (back arrow, recentre) with a soft drop shadow.
class RideCircleButton extends StatelessWidget {
  const RideCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor ?? RideStyle.ink, size: 22),
        ),
      ),
    );
  }
}

/// The flow's primary CTA — full-width yellow pill.
class RidePrimaryButton extends StatelessWidget {
  const RidePrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: active ? RideStyle.action : RideStyle.action.withOpacity(0.45),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: active ? onTap : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(RideStyle.ink),
                    ),
                  )
                : CustomText(
                    label,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined pill used for secondary sheet actions (Cancel Ride, Go Back).
class RideOutlineButton extends StatelessWidget {
  const RideOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = RideStyle.ink,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: CustomText(
          label,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Origin / destination dot — a filled ring, green for pickup, red for drop.
class RideEndpointDot extends StatelessWidget {
  const RideEndpointDot({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
