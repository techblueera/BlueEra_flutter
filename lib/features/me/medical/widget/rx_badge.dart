import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// The small red **Rx** chip marking a prescription-only medicine.
///
/// Sized to the same visual weight as grocery's veg-dot, so a pharmacy row and
/// a grocery row keep the same rhythm — it takes the leading slot that the dot
/// occupies there.
///
/// Shared by the customer-facing [MedicalProductCard] and the merchant's
/// [MedicalTopSellingProductCard]: an Rx marker that looked different depending
/// on which screen you were on would undermine the one thing it exists to do,
/// which is be recognised instantly.
class RxBadge extends StatelessWidget {
  const RxBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.red, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: CustomText(
        'Rx',
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColors.red,
        letterSpacing: 0.2,
      ),
    );
  }
}
