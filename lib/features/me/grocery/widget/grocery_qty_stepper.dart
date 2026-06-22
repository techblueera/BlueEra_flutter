import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Compact cart control shown at the top-right of a grocery product
/// image. Quantity 0 shows a white **ADD** chip; quantity > 0 morphs
/// into a filled green **− N +** stepper. Mirrors the Blinkit/Zepto
/// pattern so add, increase, decrease and remove all read clearly from
/// the tile (the previous "+" → "✓ Added" toggle hid the remove/qty
/// affordances).
///
/// Stateless on purpose — the quantity comes from the cart controller,
/// so wrap this in an `Obx` at the call site and pass the live count.
class GroceryQtyStepper extends StatelessWidget {
  final int quantity;

  /// Add one (first tap = add to cart). Caller owns the add logic since
  /// it needs business/product context the stepper doesn't carry.
  final VoidCallback onIncrement;

  /// Remove one. At quantity 1 the controller drops the item entirely.
  final VoidCallback onDecrement;

  const GroceryQtyStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  static const Color _green = AppColors.green00;

  @override
  Widget build(BuildContext context) {
    // AnimatedSize smooths the width change as the chip grows into the
    // stepper and shrinks back; AnimatedSwitcher cross-fades the two.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: quantity <= 0 ? _addChip() : _stepper(),
      ),
    );
  }

  Widget _addChip() => _Pill(
        key: const ValueKey('add'),
        fill: AppColors.white,
        child: InkWell(
          onTap: onIncrement,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: _green),
                SizedBox(width: 3),
                Text(
                  'ADD',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _stepper() => _Pill(
        key: const ValueKey('stepper'),
        fill: _green,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tapZone(Icons.remove_rounded, onDecrement),
            // The count pops on change for tactile feedback.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Padding(
                key: ValueKey(quantity),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            _tapZone(Icons.add_rounded, onIncrement),
          ],
        ),
      );

  Widget _tapZone(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
      );
}

/// Rounded chip shell shared by both states — same radius, border and
/// shadow so the morph between ADD and the stepper reads as one element.
class _Pill extends StatelessWidget {
  final Widget child;
  final Color fill;

  const _Pill({super.key, required this.child, required this.fill});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GroceryQtyStepper._green, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
