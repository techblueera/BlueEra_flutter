import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Full-width primary "create" CTA for the merchant catalog (Products) tabs.
///
/// One bold element per screen: a luminous brand-blue gradient bar that makes
/// "add a new item" the unmistakable first action of the tab. The leading glass
/// `+` chip inverts the section-header chip motif (a solid-blue circle with a
/// white `+` becomes white-on-glass over the gradient) so it reads as part of
/// the same family while clearly being the hero action.
class GradientAddButton extends StatelessWidget {
  const GradientAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.margin = EdgeInsets.zero,
    this.icon = Icons.add_rounded,
  });

  /// Localized action label, e.g. "Add Grocery" / "Add Food" / "Add Product".
  final String label;
  final VoidCallback onTap;

  /// Outer spacing — the Products tabs indent content from the left and keep a
  /// right gutter, so callers pass `EdgeInsets.only(right: …)` to line the bar
  /// up with the cards below it.
  final EdgeInsetsGeometry margin;
  final IconData icon;

  // Brand-blue ramp derived from AppColors.primaryColor (#0086FF): a deeper
  // royal at the start sweeping to a brighter sky at the end.
  static const _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0063E6), Color(0xFF0086FF), Color(0xFF34A8FF)],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Signature glass "+" chip.
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CustomText(
                      label,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
