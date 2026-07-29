import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/size_config.dart';
import '../../../../widgets/local_assets.dart';

/// Shared course card — same visual used by the owner's Academics tab
/// (`SchoolAcademicsTabV2`) and by the public-facing discover screen
/// (`DiscoverSchoolHomeScreen`). Owner callers pass [onEdit] and
/// [onDelete]; when either is null the overflow menu is hidden, which
/// is what the read-only discover view uses.
class SchoolCourseListItemCard extends StatelessWidget {
  final Courses course;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Draws a thin grey outline around the card. The owner Academics tab
  /// prefers the shadow-only look (default `false`); the public-facing
  /// [DiscoverSchoolHomeScreen] rail asks for `true` so the horizontal
  /// cards read as distinct tiles even when the background scroll
  /// container is also white.
  final bool showBorder;

  const SchoolCourseListItemCard({
    super.key,
    required this.course,
    this.onEdit,
    this.onDelete,
    this.showBorder = false,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            showBorder ? Border.all(color: Color(0xffDDE2EE), width: 1) : null,
        // In the bordered variant (discover home screen) the outline
        // already delimits the card, so drop the shadow to avoid a
        // "double edge" look. Owner Academics tab keeps the shadow.
        boxShadow: showBorder
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 165,
              height: 165,
              child: img.isNotEmpty
                  ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerFallback(),
                    )
                  : _bannerFallback(),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomText(
                        course.name ?? 'N/A',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.black22,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showMenu) _CardMenu(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                CustomText(
                  feeLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.black22,
                ),
                const SizedBox(height: 2),
                _CardDescription(text: course.description ?? ''),
                if ((course.eligibility ?? '').trim().isNotEmpty ||
                    (course.duration ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                          label: "${course.duration!} Years",
                        ),
                    ],
                  ),
                ],
                if ((course.admissionProcess ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 10),
                  // Full-width pill button (matches assets/img.png). The
                  // Container previously sized to its text, so long
                  // `admissionProcess` strings made the button dwarf the
                  // rest of the card. width: infinity + textAlign.center
                  // gives a uniform CTA; ellipsis stops any overflow when
                  // the string is longer than the right column width.
                  Container(
                    width: 150,
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xff2E7D32),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: CustomText(
                      course.admissionProcess!,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    // Long `eligibility` / `duration` strings used to push the chip's
    // Row past the parent Wrap's max width (right-column ~140px in the
    // horizontal rail). Flexible + ellipsis makes the label truncate
    // instead of the Row overflowing. mainAxisSize.min keeps short
    // labels tight so two chips can still sit side-by-side.
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
          Flexible(
            child: CustomText(
              label,
              fontSize: 12,
              color: AppColors.grey7E,
              fontWeight: FontWeight.w400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-line description with an inline "Read more" tap target when
/// the text would overflow.
class _CardDescription extends StatelessWidget {
  final String text;
  const _CardDescription({required this.text});

  static const _style = TextStyle(color: AppColors.grey7E, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    // Estimate available width for overflow detection: screen -
    // outer screen padding (20) - card padding (20) - image (160) - gap (10).
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        (screenWidth - 20 - 20 - 160 - 10).clamp(80.0, double.infinity);

    final tp = TextPainter(
      text: TextSpan(text: text, style: _style),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);

    void openFull() {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: SingleChildScrollView(
            child: Text(text, style: _style),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    final readMore = TextSpan(
      text: AppStrings.read_more.tr,
      style: _style.copyWith(
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      recognizer: TapGestureRecognizer()..onTap = openFull,
    );

    if (!tp.didExceedMaxLines) {
      return Text(text, style: _style);
    }

    final endOffset =
        tp.getPositionForOffset(Offset(tp.size.width, tp.size.height)).offset;
    final cutIndex = (endOffset - 12).clamp(0, text.length);
    final truncated = text.substring(0, cutIndex);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$truncated... ', style: _style),
        readMore,
      ]),
      maxLines: 2,
      overflow: TextOverflow.clip,
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
    return SizedBox(
      width: 20,
      height: 20,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: AppColors.grey7E),
        padding: EdgeInsets.zero,
        onSelected: (v) {
          if (v == 'edit') onEdit?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => items,
      ),
    );
  }
}
