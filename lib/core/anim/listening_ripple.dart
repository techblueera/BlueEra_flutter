import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ListeningRipple extends StatefulWidget {
  final bool isListening;
  final Widget child;

  const ListeningRipple({
    super.key,
    required this.isListening,
    required this.child,
  });

  @override
  State<ListeningRipple> createState() => _ListeningRippleState();
}

class _ListeningRippleState extends State<ListeningRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Speed of one pulse
    )..repeat(); // Keep repeating

    // 1. Scale from 1.0 to 1.5 (Expand)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // 2. Fade from 1.0 to 0.0 (Disappear as it expands)
    _fadeAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      // If not listening, just return the button without animation
      return widget.child;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // The Ripple Effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: _fadeAnimation.value),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}