import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

/// Branded **shimmer** skeleton shown on the "Me" tab (business AND individual)
/// while the own-profile fetch that populates `businessTypeGlobal` /
/// `userProfileTypeGlobal` is still resolving (first load, re-login, or an
/// in-flight refresh). It mimics the real Me-dashboard layout — cover banner +
/// avatar + identity lines + stats card + action pills + content cards — so the
/// transition to the real screen doesn't jump. Swaps to the resolved screen the
/// moment the type global lands (the resolve Obx rebuilds).
///
/// This deliberately REPLACES the old "unknown fallback on empty type" flash:
/// an empty type means "not loaded yet" → shimmer; the identity fallbacks are
/// reserved for a genuinely unrecognised *non-empty* type.
class MeTabShimmer extends StatelessWidget {
  const MeTabShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // Lives in the tab *body* only — the bottom nav bar is a sibling Positioned
    // in the parent Stack, so tabs stay visible/tappable while this shows.
    //
    // Mirrors the real Me-dashboard skeleton (HomeTabScaffold): a top-bar header
    // (avatar + title lines + go-live pill) → a pinned 5-tab row with an
    // underline indicator → tab content cards. So the swap to the real screen
    // reads as the same page finishing loading, not a different layout.
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size12,
          SizeConfig.size16,
          SizeConfig.size16,
        ),
        child: buildLoadingShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (top bar): avatar + title/subtitle + go-live pill ──
              Row(
                children: [
                  shimmerContainer(width: 44, height: 44, radius: 22),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerContainer(height: 16, width: 160),
                        const SizedBox(height: 9),
                        shimmerContainer(height: 12, width: 100),
                      ],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  // Go-live pill
                  shimmerContainer(width: 86, height: 32, radius: 16),
                ],
              ),
              const SizedBox(height: 20),
              // ── Pinned tab row: 5 label placeholders + indicator on tab 1 ──
              Row(
                children: List.generate(5, (i) {
                  return Expanded(
                    child: Column(
                      children: [
                        shimmerContainer(height: 11, width: 46, radius: 6),
                        const SizedBox(height: 8),
                        // Active-tab underline under the first tab only.
                        shimmerContainer(
                          height: 3,
                          width: i == 0 ? 26 : 0,
                          radius: 2,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              // Hairline under the tab bar.
              shimmerContainer(height: 1, radius: 0),
              const SizedBox(height: 16),
              // ── Tab content: a hero card + a few list rows ──
              shimmerContainer(height: 150, radius: 14),
              const SizedBox(height: 16),
              _contentRow(),
              const SizedBox(height: 14),
              _contentRow(),
              const SizedBox(height: 14),
              _contentRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// One list-row skeleton: leading thumbnail + two text lines + trailing pill,
  /// matching the card rows the real Me tabs render (products, orders, etc.).
  Widget _contentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        shimmerContainer(width: 56, height: 56, radius: 12),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shimmerContainer(height: 14, width: 200),
              const SizedBox(height: 9),
              shimmerContainer(height: 11, width: 130),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        shimmerContainer(width: 64, height: 30, radius: 15),
      ],
    );
  }
}
