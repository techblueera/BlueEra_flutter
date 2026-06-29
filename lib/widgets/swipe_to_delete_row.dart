import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Zomato-style swipe-to-reveal delete row: the [child] slides left only up to
/// a fixed delete panel (it never fully dismisses); the user taps the revealed
/// red Delete button to act. Snaps open/closed on release.
///
/// Shared between the food and product (and other) variant sheets so the
/// delete affordance reads identically across me-section catalog screens.
class SwipeToDeleteRow extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onDelete;

  const SwipeToDeleteRow({
    super.key,
    required this.child,
    required this.onDelete,
  });

  @override
  State<SwipeToDeleteRow> createState() => _SwipeToDeleteRowState();
}

class _SwipeToDeleteRowState extends State<SwipeToDeleteRow>
    with SingleTickerProviderStateMixin {
  // Width of the revealed delete panel (how far the row slides). Sized for a
  // comfortable icon + label tap target, not a full-width dismiss.
  static const double _revealW = 96;

  // 0 = closed, 1 = fully revealed. Drag drives it; release snaps it.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _c.value = (_c.value - (d.primaryDelta ?? 0) / _revealW).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = v < -300 ? true : (v > 300 ? false : _c.value > 0.5);
    _c.animateTo(open ? 1 : 0, curve: Curves.easeOut);
  }

  void _close() => _c.animateTo(0, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Red delete button pinned on the right, revealed as the row slides.
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  await widget.onDelete();
                  _close();
                },
                child: Container(
                  width: _revealW,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(height: 2),
                      Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The sliding content. Tapping it while open just closes the row.
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Transform.translate(
              offset: Offset(-_revealW * _c.value, 0),
              child: child,
            ),
            child: GestureDetector(
              // Tap the content while open → close (checked live, not at build).
              onTap: () {
                if (_c.value > 0) _close();
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
