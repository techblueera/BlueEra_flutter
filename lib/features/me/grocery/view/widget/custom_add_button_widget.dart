import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const CustomAddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Adjust width and height to match your specific UI needs
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          // 1. The Light Blue Gradient Background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50, // Lighter top
              const Color(0xFFE3F2FD), // Subtle blue middle/bottom
            ],
          ),
          // 2. The Solid Blue Border
          border: Border.all(
            color: Colors.blue.shade600,
            width: 1.5,
          ),
          // 3. Rounded Corners
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: CustomText(
            "ADD",
            color: AppColors.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
