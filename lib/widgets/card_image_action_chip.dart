import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Compact icon + label pill meant to sit ON a product image (top-right
/// corner) — the add-to-cart affordance for the grocery and product customer
/// cards.
///
/// Deliberately a copy of [GroceryQtyStepper]'s chip
/// (`grocery_qty_stepper.dart`), the control the customer already sees in that
/// corner on the "All Top Selling" grid: same 20-radius pill, same 1.2 green
/// border, same shadow, same 11/w800 label. The two surfaces show the same
/// products, so the add control has to be the same object on both.
///
/// Two states, mirroring the stepper's own ADD → filled-green morph:
/// * `active: false` — white fill, green border, green content ("+ ADD")
/// * `active: true`  — filled green, white content ("✓ ADDED")
///
/// Unlike the stepper this is a single tap target: these cards sell per
/// VARIANT, so the tap opens the variants sheet rather than incrementing a
/// quantity. Stateless — wrap it in an `Obx` at the call site.
class CardImageActionChip extends StatelessWidget {
  /// Whether the product is already in the cart (drives the fill/label swap).
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Pill colour. Defaults to the green the grocery stepper uses.
  final Color accent;

  const CardImageActionChip({
    super.key,
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppColors.green00,
  });

  @override
  Widget build(BuildContext context) {
    final Color content = active ? AppColors.white : accent;

    // AnimatedSize smooths the width change between the two labels;
    // AnimatedSwitcher cross-fades the icon and text.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? accent : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    icon,
                    key: ValueKey(active),
                    size: 15,
                    color: content,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label,
                    key: ValueKey(active),
                    style: TextStyle(
                      color: content,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
