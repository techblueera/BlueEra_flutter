import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Icon + title + subtitle row used as the section header inside a card.
///
/// Used across the laboratory module (and any other module that follows the
/// same "tinted-icon-square + heading + helper-text" pattern).
class SectionIconHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;

  const SectionIconHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = accentColor ?? AppColors.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.medium,
              ),
              const SizedBox(height: 2),
              CustomText(
                subtitle,
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
