import 'package:flutter/material.dart';

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color backgroundColor;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.iconSize = 16.0,
    this.iconColor = Colors.black,
    this.backgroundColor = const Color(0xFFEEEEEE), // AppColors.whiteEE
    this.alignment = Alignment.centerRight,
    this.padding = const EdgeInsets.all(6.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
