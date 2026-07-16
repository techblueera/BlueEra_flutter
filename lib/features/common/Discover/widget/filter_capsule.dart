import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:flutter/material.dart';

/// Compact **sort** control shared by the Discover list screens (professional
/// consultants, self-profession, etc.). It replaced the old full-width, 42-px
/// three-segment capsule that read like a page-level toggle and ate the whole
/// row — this is a lighter, secondary affordance:
///
///   [ Nearest ]  [ Experienced ]  [ Price ↓ ]
///
/// A left-aligned row of small, radius-10 chips that take only the width they
/// need and scroll horizontally if labels are long. The selected chip is a solid
/// primary fill; the rest sit as hairline-bordered white cards. Purely visual —
/// tapping a chip fires [onChanged]; sorting / refetching is the caller's job.
class FilterCapsule extends StatelessWidget {
  final List<CategoryFilter> filters;
  final CategoryFilter selected;
  final ValueChanged<CategoryFilter> onChanged;

  const FilterCapsule({
    super.key,
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  IconData _iconFor(CategoryFilter f) {
    switch (f) {
      case CategoryFilter.nearest:
        return Icons.near_me_outlined;
      case CategoryFilter.experienced:
        return Icons.workspace_premium_outlined;
      case CategoryFilter.priceLowToHigh:
        return Icons.south_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      // Chips scroll horizontally so long localized labels never overflow on
      // narrow screens; with three chips they simply sit inline.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < filters.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _chip(filters[i], filters[i] == selected),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(CategoryFilter f, bool isActive) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primaryColor
                : const Color(0xFFE6E8EE),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0A001120),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(f),
              size: 13,
              color: isActive ? Colors.white : AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 5),
            Text(
              f.localizedLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : AppColors.mainTextColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
