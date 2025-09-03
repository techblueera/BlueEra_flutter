import 'package:flutter/material.dart';

class AnimatedHeaderVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;

  const AnimatedHeaderVisibility({
    Key? key,
    required this.visible,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
