import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
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

/// Quick Info summary card shown on the school Overview tab.
///
/// Fully category-agnostic — the field list and their labels come from
/// `controller.quickInfoFields` (loaded by `GET /schools/:id/quick-info`),
/// and each field is rendered from `controller.quickInfoValues[field.key]`.
/// The same widget handles School Education, College/University, Sports &
/// Hobby, Professional Learn, etc. See
/// lib/docs/SCHOOL_QUICK_INFO_UI_INTEGRATION.md.
class SchoolQuickInfoCard extends StatelessWidget {
  final SchoolAboutUsController controller;

  /// Owner tap-target that opens the edit form. When null the card
  /// renders in read-only mode: the pencil icon disappears and the
  /// empty state collapses to a plain "no info" line instead of the
  /// per-field "Add" list.
  final VoidCallback? onEditTap;

  const SchoolQuickInfoCard({
    super.key,
    required this.controller,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Obx(() {
          final fields = controller.quickInfoFields;
          final values = controller.quickInfoValues;

          final hasAnyValue = fields.any((f) => _hasValue(values[f.key]));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    _headingFor(controller.quickInfoCategory.value),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  if (hasAnyValue && onEditTap != null)
                    _EditIconBtn(onTap: onEditTap!),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              if (fields.isEmpty)
                _LoadingPlaceholder()
              else if (!hasAnyValue)
                onEditTap != null
                    ? _EmptyHighlightsList(fields: fields, onAdd: onEditTap!)
                    : _ReadOnlyEmpty()
              else
                _FilledChipsGrid(fields: fields, values: values),
            ],
          );
        }),
      ),
    );
  }

  /// Category name is optional per the API; when absent we fall back to a
  /// generic label so the card doesn't render "null Highlights".
  String _headingFor(String? category) {
    if (category == null || category.trim().isEmpty) return 'Highlights';
    return '$category Highlights';
  }

  static bool _hasValue(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    if (v is num) return true;
    if (v is Map) return v.isNotEmpty;
    return false;
  }
}

/// Renders each populated field as a compact icon+label chip in a Wrap so
/// varying field counts (3 for school, 4 for sports, 6 for college…) all
/// lay out cleanly.
class _FilledChipsGrid extends StatelessWidget {
  final List<QuickInfoField> fields;
  final Map<String, dynamic> values;

  const _FilledChipsGrid({required this.fields, required this.values});

  @override
  Widget build(BuildContext context) {
    final populated = fields
        .where((f) => SchoolQuickInfoCard._hasValue(values[f.key]))
        .toList();
    if (populated.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 2-per-row grid; extra chips wrap onto subsequent rows.
        const spacing = 8.0;
        final chipWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final field in populated)
              SizedBox(
                width: chipWidth,
                child: _InfoChip(
                  icon: _iconFor(field.key),
                  label: _labelFor(field, values[field.key]),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Best-effort icon per known field key. Everything unknown falls back to
  /// the generic `outlinedDocument` glyph so new backend fields render
  /// without a frontend change.
  static String _iconFor(String key) {
    switch (key) {
      case 'classRange':
        return AppIconAssets.classIcon;
      case 'board':
        return AppIconAssets.outlinedDocument;
      case 'mediumOfInstruction':
        return AppIconAssets.mediumIcon;
      case 'numberOfStudents':
        return AppIconAssets.multiPersonsIcon;
      case 'studentTeacherRatio':
        return AppIconAssets.personProfileIcon;
      default:
        return AppIconAssets.outlinedDocument;
    }
  }

  /// Compresses list values ("CBSE" / "3 Boards") and appends the field
  /// label to give the chip meaning without a separate row of headings.
  static String _labelFor(QuickInfoField field, dynamic value) {
    if (value is List) {
      if (value.isEmpty) return field.label;
      if (value.length == 1) return '${value.first} ${field.label}';
      return '${value.length} ${field.label}';
    }
    if (value is num) return '$value ${field.label}';
    final str = value?.toString() ?? '';
    if (str.trim().isEmpty) return field.label;
    return str;
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
        border: Border.all(color: Color(0xffDDE2EE), width: 1),
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

/// Empty-state list — one row per descriptor with an "Add" pill. Uses
/// descriptor `label` and `placeholder` so it stays honest for every
/// category without a lookup table.
class _EmptyHighlightsList extends StatelessWidget {
  final List<QuickInfoField> fields;
  final VoidCallback onAdd;

  const _EmptyHighlightsList({required this.fields, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < fields.length; i++) ...[
          _EmptyRow(field: fields[i], onAdd: onAdd),
          if (i != fields.length - 1) SizedBox(height: SizeConfig.size10),
        ],
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final QuickInfoField field;
  final VoidCallback onAdd;
  const _EmptyRow({required this.field, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xffDDE2EE), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xffDDE2EE), width: 1),
            ),
            child: LocalAssets(
              imagePath: _FilledChipsGrid._iconFor(field.key),
              imgColor: AppColors.primaryColor,
              height: 20,
              width: 20,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  field.label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: 2),
                CustomText(
                  field.placeholder ?? 'Add ${field.label.toLowerCase()}',
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

/// Read-only stand-in for the "Add" list — used when the viewer can't
/// edit (public discover view).
class _ReadOnlyEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: CustomText(
        'No highlights added yet.',
        fontSize: 12,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
