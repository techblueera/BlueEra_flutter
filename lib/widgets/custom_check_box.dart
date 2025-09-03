import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomCheckBox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onChanged;
  final double size;
  final Color? activeColor;
  final Color borderColor;
  final IconData checkIcon;

  const CustomCheckBox({
    super.key,
    required this.isChecked,
    required this.onChanged,
    this.size = 25.0,
    this.activeColor,
    this.borderColor = Colors.white,
    this.checkIcon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    final Color fillColor = isChecked ? (activeColor ?? AppColors.primaryColor) : Colors.transparent;
    final Color borderFinalColor = isChecked ? (activeColor ?? AppColors.primaryColor) : borderColor;

    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderFinalColor,
            width: 1,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: isChecked
              ? Icon(
            checkIcon,
            key: const ValueKey('checked'),
            color: Colors.white,
            size: size * 0.8,
          )
              : const SizedBox(key: ValueKey('unchecked')),
        ),
      ),
    );
  }
}
