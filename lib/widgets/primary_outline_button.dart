import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class PrimaryOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const PrimaryOutlineButton({
    super.key,
    this.onPressed,
    this.label = 'Create',
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFB8DFFF),
            ],
            stops: [0.4, 1.0],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}