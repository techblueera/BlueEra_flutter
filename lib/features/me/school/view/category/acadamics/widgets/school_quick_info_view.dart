import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../../widgets/local_assets.dart';

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
    final boards = data?.boards ?? const <String>[];
    final mediums = data?.mediumOfInstruction ?? const <String>[];
    // final fees = data?.fees;
    final numberOfStudents = data?.numberOfStudents;

    final isEmpty = classRange.isEmpty &&
        boards.isEmpty &&
        mediums.isEmpty &&
        numberOfStudents == null;

    final boardLabel = boards.isEmpty
        ? 'Board'
        : boards.length == 1
            ? '${boards.first} Board'
            : '${boards.length} Boards';

    final mediumLabel = mediums.isEmpty
        ? 'English Medium'
        : mediums.length == 1
            ? '${mediums.first} Medium'
            : '${mediums.length} Mediums';

    return CommonCardWidget(
      padding: 12,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "School Highlights",
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              if (!isEmpty) _EditIconBtn(onTap: onEditTap),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (isEmpty)
            _EmptyHighlightsList(onAdd: onEditTap)
          else
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: AppIconAssets.classIcon,
                    label: classRange.isNotEmpty ? classRange : 'Class 1-12',
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _InfoChip(
                    icon: AppIconAssets.outlinedDocument,
                    label: boardLabel,
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _InfoChip(
                    icon: AppIconAssets.mediumIcon,
                    label: mediumLabel,
                  ),
                ),
                // if (fees != null) ...[
                //   SizedBox(width: SizeConfig.size8),
                //   Expanded(
                //     child: _InfoChip(
                //       icon: Icons.currency_rupee,
                //       label: '$fees Fees',
                //     ),
                //   ),
                // ],
                if (numberOfStudents != null) ...[
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: _InfoChip(
                      icon: AppIconAssets.multiPersonsIcon,
                      label: '$numberOfStudents Students',
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xffDDE2EE), width: 0.5),
      ),
      child: Column(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: AppColors.primaryColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey7E,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _EmptyHighlightsList extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHighlightsList({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    const items = <_EmptyRowData>[
      _EmptyRowData(
        icon: Icons.menu_book_outlined,
        title: 'Total Classes',
        subtitle: 'Add Total classes',
      ),
      _EmptyRowData(
        icon: Icons.account_balance_outlined,
        title: 'School Board',
        subtitle: 'Add your school board name',
      ),
      _EmptyRowData(
        icon: Icons.translate,
        title: 'Medium Of Instruction',
        subtitle: 'Add the medium of instruction',
      ),
      _EmptyRowData(
        icon: Icons.groups_outlined,
        title: 'Student Strength',
        subtitle: 'Add the total number of students',
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _EmptyRow(data: items[i], onAdd: onAdd),
          if (i != items.length - 1) SizedBox(height: SizeConfig.size10),
        ],
      ],
    );
  }
}

class _EmptyRowData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _EmptyRow extends StatelessWidget {
  final _EmptyRowData data;
  final VoidCallback onAdd;
  const _EmptyRow({required this.data, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: AppColors.primaryColor, size: 20),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  data.title,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: 2),
                CustomText(
                  data.subtitle,
                  fontSize: 11,
                  color: AppColors.mainTextColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          _AddPill(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.add.tr,
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

class _EditIconBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EditIconBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.editIcon,
          imgColor: AppColors.primaryColor,
          height: 14,
          width: 14,
        ),
      ),
    );
  }
}
