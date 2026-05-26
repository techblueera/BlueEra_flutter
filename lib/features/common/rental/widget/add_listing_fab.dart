import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AddListingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const AddListingFab({
    super.key,
    required this.onPressed,
    this.label = 'Add Listing',
  });

  @override
  State<AddListingFab> createState() => _AddListingFabState();
}

class _AddListingFabState extends State<AddListingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 12),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: 0.22),
              highlightColor: Colors.white.withValues(alpha: 0.10),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      Color.lerp(
                          AppColors.primaryColor, Colors.black, 0.18)!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
