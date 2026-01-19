import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class GradientBorderContainer extends StatelessWidget {
  final String title;
  final Color gradientColor; // The main center color (e.g. #78EDA7)

  const GradientBorderContainer({
    super.key,
    required this.title,
    required this.gradientColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      // --- 1. The Shadow ---
      decoration: BoxDecoration(
        color: gradientColor.withValues(alpha: 0.1), // Need a background color for shadow to show properly
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- 2. The Content ---
          Container(
            padding: EdgeInsets.all(
             SizeConfig.size8,
            ),
            child: CustomText(
              title,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
          ),

          // --- 3. Top Gradient Border ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGradientLine(),
          ),

          // --- 4. Bottom Gradient Border ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGradientLine(),
          ),
        ],
      ),
    );
  }

  // Helper to build the gradient line
  Widget _buildGradientLine() {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor.withValues(alpha: 0.0), // Transparent Start
            gradientColor,                  // Solid Center
            gradientColor.withValues(alpha: 0.0), // Transparent End
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.16),
            offset: Offset(0, 2),     // x: 0, y: 2
            blurRadius: 10,           // blur: 10
          ),
        ],
      ),
    );
  }
}