import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:flutter/material.dart';

/// Segmented capsule filter shared between the Discover list screens
/// (professional consultants, self-profession, etc.). Three equal-width
/// segments inside a rounded outer track. The selected segment is a
/// solid primary fill with a soft drop shadow; inactive segments sit
/// transparent on the white track. The widget itself is purely visual
/// — tapping a segment fires [onChanged] with the chosen
/// [CategoryFilter]; sorting / refetching is the caller's job.
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
    final selectedIndex =
        filters.indexOf(selected).clamp(0, filters.length - 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        const trackPadding = 4.0;
        final pillWidth =
            (constraints.maxWidth - trackPadding * 2) / filters.length;
        return Container(
          height: 42,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14001120),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: pillWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: List.generate(filters.length, (i) {
                    final f = filters[i];
                    final isActive = i == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(f),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconFor(f),
                                size: 14,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.mainTextColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    f.localizedLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppConstants.OpenSans,
                                      fontSize: 12,
                                      fontWeight: isActive
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.mainTextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
