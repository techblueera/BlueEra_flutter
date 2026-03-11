import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isAdded;
  const CustomAddButton({
    super.key,
    required this.onTap,
    this.isAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          // 1. Dynamic Background Based on isAdded
          color: isAdded ? Colors.green.withValues(alpha: 0.1) : Colors.blue.shade50,

          // 2. Dynamic Border
          border: Border.all(
            color: isAdded ? Colors.green.shade600 : Colors.blue.shade600,
            width: 1.5,
          ),

          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdded) ...[
              const Icon(Icons.check, color: Colors.green, size: 14),
              const SizedBox(width: 4),
            ],
            CustomText(
              isAdded ? "ADDED" : "ADD",
              color: isAdded ? Colors.green.shade700 : AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}