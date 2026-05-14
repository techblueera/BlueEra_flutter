import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Soft tinted banner with a leading icon and a one-line message.
///
/// Used as the helper "tip" strip at the top of edit forms.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? accentColor;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = accentColor ?? AppColors.primaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              message,
              color: color,
              fontSize: SizeConfig.small,
            ),
          ),
        ],
      ),
    );
  }
}
