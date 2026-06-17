import 'package:BlueEra/core/services/ads/native_ad_widget.dart';
import 'package:flutter/widgets.dart';

/// One row in a content list that has native ads interleaved: either a content
/// item (carrying its index into the original data list) or a native ad slot
/// (carrying an ordinal so the ad widget can be given a stable key).
class NativeAdRow {
  const NativeAdRow.content(this.contentIndex)
      : isAd = false,
        adOrdinal = -1;

  const NativeAdRow.ad(this.adOrdinal)
      : isAd = true,
        contentIndex = -1;

  final bool isAd;
  final int contentIndex;
  final int adOrdinal;
}

/// 1-indexed content positions AFTER which a native ad is inserted, e.g. an ad
/// goes after item 1, after item 3, etc. Shared by every ad-bearing list/grid so
/// the cadence is uniform across the app (matches the grocery stores screen).
const Set<int> _kAdAfterPositions = {1, 3, 7, 11, 13, 16, 20};

/// Beyond the last entry in [_kAdAfterPositions], keep inserting an ad every
/// this many items so long (load-more) lists keep showing ads. Matches the final
/// gap in the series (20 - 16 = 4).
const int _kAdRepeatStepAfterLast = 4;

/// Whether a native ad should be inserted AFTER the 1-indexed [position] (i.e.
/// after that many content items), per the shared series then a repeating step.
bool _shouldInsertAdAfter(int position) {
  if (_kAdAfterPositions.contains(position)) return true;
  const last = 20; // == _kAdAfterPositions.last
  return position > last &&
      (position - last) % _kAdRepeatStepAfterLast == 0;
}

/// Builds the interleaved row list for a content list of [contentCount] items:
/// a native ad is inserted after the positions in the shared series
/// (1, 3, 7, 11, 13, 16, 20, then every 4), never after the very last item.
///
/// Usage in a ListView.builder / SliverChildBuilderDelegate:
/// ```dart
/// final rows = buildNativeAdRows(items.length);
/// // itemCount: rows.length + (isLoadingMore ? 1 : 0)
/// // in the builder:
/// if (index == rows.length) return loaderWidget;          // load-more spinner
/// final row = rows[index];
/// if (row.isAd) return const NativeAdSlot(adOrdinal: 0);  // see NativeAdSlot
/// final item = items[row.contentIndex];
/// ```
List<NativeAdRow> buildNativeAdRows(int contentCount) {
  final rows = <NativeAdRow>[];
  var adOrdinal = 0;
  for (var i = 0; i < contentCount; i++) {
    rows.add(NativeAdRow.content(i));
    final pos = i + 1; // 1-indexed
    final isLast = i == contentCount - 1;
    if (!isLast && _shouldInsertAdAfter(pos)) {
      rows.add(NativeAdRow.ad(adOrdinal++));
    }
  }
  return rows;
}

/// Interleaves FULL-WIDTH native ad slivers into a multi-column (grid/masonry)
/// list. The grid is split into chunks at the shared series positions
/// (1, 3, 7, 11, 13, 16, 20, then every 4); each chunk is built by
/// [gridSliverBuilder] for the half-open range [start, end), and a full-width
/// native ad sliver is inserted after every chunk except the last.
///
/// Spread the result into a CustomScrollView's `slivers: [...]`:
/// ```dart
/// CustomScrollView(slivers: [
///   ...buildNativeAdGridSlivers(
///     itemCount: items.length,
///     keyPrefix: 'product_native_ad',
///     gridSliverBuilder: (start, end) => SliverGrid(
///       gridDelegate: <your 2-col delegate>,
///       delegate: SliverChildBuilderDelegate(
///         (c, i) => buildCard(items[start + i]),
///         childCount: end - start,
///       ),
///     ),
///   ),
/// ])
/// ```
List<Widget> buildNativeAdGridSlivers({
  required int itemCount,
  required Widget Function(int start, int end) gridSliverBuilder,
  String keyPrefix = 'native_ad',
  double adHeight = 300,
  EdgeInsetsGeometry adPadding = const EdgeInsets.symmetric(horizontal: 12),
}) {
  final slivers = <Widget>[];
  if (itemCount <= 0) return slivers;
  var adOrdinal = 0;
  var start = 0;
  for (var pos = 1; pos < itemCount; pos++) {
    // pos < itemCount: never break/insert after the final item.
    if (!_shouldInsertAdAfter(pos)) continue;
    slivers.add(gridSliverBuilder(start, pos));
    slivers.add(
      SliverPadding(
        padding: adPadding,
        sliver: SliverToBoxAdapter(
          child: NativeAdSlot(
            adOrdinal: adOrdinal++,
            keyPrefix: keyPrefix,
            height: adHeight,
          ),
        ),
      ),
    );
    start = pos;
  }
  if (start < itemCount) slivers.add(gridSliverBuilder(start, itemCount));
  return slivers;
}

/// A native ad row rendered inside a content list. Wraps [NativeAdWidget] with a
/// stable key (so the loaded ad survives list rebuilds / load-more instead of
/// reloading and burning impressions). [keyPrefix] should be unique per screen.
class NativeAdSlot extends StatelessWidget {
  const NativeAdSlot({
    super.key,
    required this.adOrdinal,
    this.keyPrefix = 'native_ad',
    this.height = 300,
  });

  final int adOrdinal;
  final String keyPrefix;

  /// Slot height. Defaults to 300 — enough for the custom native layout's
  /// >=120 media view plus header/body/CTA (smaller warns "media too small").
  final double height;

  @override
  Widget build(BuildContext context) {
    return NativeAdWidget(
      key: ValueKey('${keyPrefix}_$adOrdinal'),
      height: height,
    );
  }
}
