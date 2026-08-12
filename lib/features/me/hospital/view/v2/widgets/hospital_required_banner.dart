import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Amber nudge shown at the top of the Departments / Facilities "me" tabs
/// when the section is empty. Purely informational — the add form is
/// already rendered directly below, so no CTA is needed.
class HospitalRequiredBanner extends StatelessWidget {
  final String heading;
  final String message;

  const HospitalRequiredBanner({
    super.key,
    required this.heading,
    required this.message,
  });

  static const Color _bg = Color(0xFFFFF7E6);
  static const Color _border = Color(0xFFF5C87A);
  static const Color _iconColor = Color(0xFFB07500);
  static const Color _headingColor = Color(0xFF5A3A00);
  static const Color _messageColor = Color(0xFF7A5200);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _iconColor,
            size: SizeConfig.size20,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  heading,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: _headingColor,
                ),
                SizedBox(height: SizeConfig.size3),
                CustomText(
                  message,
                  fontSize: SizeConfig.extraSmall,
                  color: _messageColor,
                  fontWeight: FontWeight.w400,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
