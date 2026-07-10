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

/// 1-indexed content position after which the FIRST native ad is inserted in a
/// single-column LIST. Set to 1 so the first ad shows early (after the 1st
/// item), then the wide [_kListAdEveryAfterFirst] spacing keeps only one ad on
/// screen at a time → positions 1, 11, 21, ...
const int _kListFirstAdAfter = 1;

/// After the first ad, insert another native ad every this many items in a LIST,
/// giving a uniform, sparse cadence (ad after 1, 11, 21, ...). The wide interval
/// keeps consecutive native slots from coming into view — and requesting an ad —
/// at the same time, which keeps concurrent ad loads down.
/// (The first ad's position doesn't affect concurrency; only the spacing does.)
const int _kListAdEveryAfterFirst = 10;

/// GRID/masonry cadence — deliberately WIDER than the list cadence. A multi-
/// column grid packs 2+ cards per row, so for the same scroll distance far more
/// ad slots come into view and request an ad almost at once. Loading native ads
/// too frequently can surface as blank/failed slots. A bigger gap keeps
/// concurrent ad loads down. First ad after the 10th card...
const int _kGridFirstAdAfter = 10;

/// ...then one every 10 cards thereafter (ad after 6, 16, 26, ...). With a
/// 2-column grid that's roughly one ad every 5 rows.
const int _kGridAdEveryAfterFirst = 10;

/// Whether a native ad should be inserted AFTER the 1-indexed [position] (i.e.
/// after that many content items): the first ad lands at [firstAfter], then one
/// every [everyAfter] items thereafter. Callers pass the list or grid cadence.
bool _shouldInsertAdAfter(
  int position, {
  required int firstAfter,
  required int everyAfter,
}) {
  if (position < firstAfter) return false;
  return (position - firstAfter) % everyAfter == 0;
}

/// Builds the interleaved row list for a single-column content list of
/// [contentCount] items: a native ad is inserted per the LIST cadence (after
/// item 3, then every 6: 3, 9, 15, 21, ...), never after the very last item.
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
    if (!isLast &&
        _shouldInsertAdAfter(pos,
            firstAfter: _kListFirstAdAfter,
            everyAfter: _kListAdEveryAfterFirst)) {
      rows.add(NativeAdRow.ad(adOrdinal++));
    }
  }
  return rows;
}

/// Interleaves FULL-WIDTH native ad slivers into a multi-column (grid/masonry)
/// list. The grid is split into chunks at the wider GRID cadence positions
/// (after item 6, then every 10: 6, 16, 26, ...); each chunk is built by
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
    if (!_shouldInsertAdAfter(pos,
        firstAfter: _kGridFirstAdAfter,
        everyAfter: _kGridAdEveryAfterFirst)) continue;
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
    this.factoryId = NativeAdWidget.defaultFactoryId,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  final int adOrdinal;
  final String keyPrefix;

  /// Slot height. Defaults to 300 — enough for the custom native layout's
  /// >=120 media view plus header/body/CTA (smaller warns "media too small").
  final double height;

  /// Which native layout renders the ad (defaults to the grocery card). Pass
  /// `'feedAdFactory'` for the feed-post-styled layout.
  final String factoryId;

  /// Outer corner radius (the feed card uses 20 to match a post card).
  final double borderRadius;

  /// Gap below the slot; pass `0` when the native layout supplies its own.
  final double? bottomGap;

  /// Outer spacing; overrides [bottomGap]. Feed uses `EdgeInsets.all(5)`.
  final EdgeInsetsGeometry? margin;

  /// Optional card border (feed post card's hairline).
  final BoxBorder? border;

  /// Optional card shadow (feed post card's soft shadow).
  final List<BoxShadow>? boxShadow;

  /// Optional fill behind the ad (white for a bordered card).
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return NativeAdWidget(
      key: ValueKey('${keyPrefix}_$adOrdinal'),
      height: height,
      factoryId: factoryId,
      borderRadius: borderRadius,
      bottomGap: bottomGap,
      margin: margin,
      border: border,
      boxShadow: boxShadow,
      backgroundColor: backgroundColor,
    );
  }
}
