import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolQuickInfoCard extends StatelessWidget {
  final SchoolAboutUsController controller;
  final VoidCallback onEditTap;

  const SchoolQuickInfoCard({
    super.key,
    required this.controller,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = controller.schoolDetailsData?.value;
    final classRange = (data?.classRange ?? '').trim();
    final board = (data?.board ?? '').trim();
    final mediums = data?.mediumOfInstruction ?? const <String>[];
    final mediumLabel = mediums.isEmpty
        ? 'English Medium'
        : mediums.length == 1
            ? '${mediums.first} Medium'
            : '${mediums.length} Mediums';
    final fees = data?.fees;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "School Quick Info",
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                _EditPill(onTap: onEditTap),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.menu_book_outlined,
                    label: classRange.isNotEmpty ? classRange : 'Class 1-12',
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.account_balance_outlined,
                    label: board.isNotEmpty ? board : 'Board',
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.translate,
                    label: mediumLabel,
                  ),
                ),
                if (fees != null) ...[
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.currency_rupee,
                      label: '$fees Fees',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 22),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 13, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
