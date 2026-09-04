import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// One entry in the Quick Access grid.
class QuickAccessItem {
  const QuickAccessItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;

  /// Bundled asset path. These are the self-contained plates from
  /// `assets/discover/` — the tint and the corner radius are baked into the
  /// PNG — so the tile draws them EDGE-TO-EDGE with no plate behind and no
  /// padding around. See `DiscoverIcons.isSelfContained`.
  final String icon;

  final VoidCallback onTap;
}

/// The ten-tile launcher across the top of `DiscoverScreenV2`: five per row,
/// two rows, as drawn.
///
/// Fixed at five columns rather than a wrapping grid. The design's rhythm is
/// two even rows of five, and the labels ("Grocery & Food", "Health Care") are
/// sized to that column width — letting it reflow puts four on a narrow phone
/// and breaks the pairing between the two rows.
class DiscoverQuickAccessGrid extends StatelessWidget {
  const DiscoverQuickAccessGrid({super.key, required this.items});

  final List<QuickAccessItem> items;

  static const int _columns = 5;

  /// Gap between columns. The tile itself takes whatever is left, so the icon
  /// grows on a wide screen instead of stranding the row against one edge.
  static const double _columnGap = 6;

  /// Gap between the two rows — larger than [_columnGap] because a label sits
  /// directly above the next row's artwork and needs the separation.
  static const double _rowGap = 14;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final rows = <List<QuickAccessItem>>[];
    for (var i = 0; i < items.length; i += _columns) {
      rows.add(items.sublist(
          i, i + _columns > items.length ? items.length : i + _columns));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r != 0) const SizedBox(height: _rowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < _columns; c++) ...[
                if (c != 0) const SizedBox(width: _columnGap),
                // A short last row keeps its columns rather than stretching
                // the tiles it does have — the grid stays aligned with the
                // full row above it.
                Expanded(
                  child: c < rows[r].length
                      ? _QuickTile(item: rows[r][c])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});

  final QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Square by construction: the artwork is a square plate, so an
          // AspectRatio keeps every tile identical whatever width the column
          // resolves to, instead of a fixed height that clips on small phones.
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                item.icon,
                // COVER, not contain: the PNG's own tinted background IS the
                // tile, so any gap around it is a gap in the tile itself.
                fit: BoxFit.cover,
                // A missing asset leaves an empty plate rather than Flutter's
                // grey broken-image box in the middle of the launcher.
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Two lines, because "Grocery & Food" and "Health Care" do not fit
          // one column width at this size on a small phone. A fixed height so
          // a one-line label and a two-line label still bottom-align across
          // the row.
          SizedBox(
            height: 26,
            child: CustomText(
              item.label,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
