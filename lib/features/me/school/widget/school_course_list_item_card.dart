import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared course card — same visual used by the owner's Academics tab
/// (`SchoolAcademicsTabV2`) and by the public-facing discover screen
/// (`DiscoverSchoolHomeScreen`). Owner callers pass [onEdit] and
/// [onDelete]; when either is null the overflow menu is hidden, which
/// is what the read-only discover view uses.
class SchoolCourseListItemCard extends StatelessWidget {
  final Courses course;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SchoolCourseListItemCard({
    super.key,
    required this.course,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final img = (course.image ?? '').trim();
    final yearly = course.courseFees?.yearly ?? 0;
    final monthly = course.courseFees?.monthly ?? 0;
    final feeLabel = monthly > 0
        ? '₹${formatNumber(monthly)}/${AppStrings.monthly.tr}'
        : '₹${formatNumber(yearly)}/${AppStrings.years.tr}';

    final showMenu = onEdit != null || onDelete != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // IntrinsicHeight + stretch lets the image fill the card's true
      // content height instead of forcing a fixed card height. Card grows
      // with its text; image grows with the card.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 152,
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bannerFallback(),
                      )
                    : _bannerFallback(),
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              course.name ?? 'N/A',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.black22,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              feeLabel,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.black22,
                            ),
                          ],
                        ),
                      ),
                      if (showMenu)
                        _CardMenu(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ExpandableText(
                    text: course.description ?? '',
                    trimLines: 2,
                    isReadMoreNewLine: false,
                    expandMode: ExpandMode.dialog,
                    style: TextStyle(
                      color: AppColors.grey7E,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if ((course.eligibility ?? '').trim().isNotEmpty)
                        _MiniChip(
                          icon: AppIconAssets.standardIcon,
                          label: course.eligibility!,
                        ),
                      if ((course.duration ?? '').trim().isNotEmpty)
                        _MiniChip(
                          icon: AppIconAssets.academic_calendar,
                          label: course.duration!,
                        ),
                    ],
                  ),
                  if ((course.admissionProcess ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff2E7D32),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: CustomText(
                          course.admissionProcess!,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerFallback() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
      );
}

class _MiniChip extends StatelessWidget {
  final String icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: AppColors.grey7E,
            height: 12,
            width: 12,
          ),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 12,
            color: AppColors.grey7E,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _CardMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Assemble the popup items dynamically so owner callers with only
    // one of the two callbacks still get a sensible menu.
    final items = <PopupMenuEntry<String>>[
      if (onEdit != null)
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
      if (onDelete != null)
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: AppColors.grey7E),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => items,
    );
  }
}
