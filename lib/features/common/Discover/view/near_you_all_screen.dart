import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/widget/nearby_entry.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Near you" — everything `map-service/api/nearby/discover` found around the
/// user, in full.
///
/// Reached from the Discover rail's View All. It renders the SAME set the rail
/// draws from, via the same shared [NearbyStoresController], so entering costs
/// no extra call; ordering and tap routing are shared verbatim through
/// `nearby_entry.dart`.
///
/// ## The design
///
/// The one fact that justifies this screen is **how far away each place is** —
/// it is the sort order and the reason the user opened it. So distance is the
/// page's spine: a hairline ladder down the left edge with each item's distance
/// as its rung, nearest at the top wearing the only filled marker on the page.
/// Cards therefore carry no distance chip of their own; the spine says it once,
/// in the position that also encodes the ranking.
///
/// Everything else is deliberately quiet — white cards, one hairline, no
/// shadows — so the ladder is the thing you remember. The condensed face
/// ([_condensed]) is reserved for the rungs, the eyebrows and the filter chips:
/// signage type for the wayfinding parts, humanist type for the names and
/// addresses people actually read.
///
/// ## Filters come from the response, not from a list in this file
///
/// The API answers in verticals (`grocery` / `food` / `product` /
/// `healthcare`), so the chips ARE those buckets, labelled and counted from
/// what actually came back. A vertical with nothing in it is not offered, and
/// a vertical added server-side shows up here without a change to this file.
///
/// ## Why the paging is client-side
///
/// `nearby/discover` has no page/limit parameters — it answers with the whole
/// neighbourhood in one shot, capped server-side at `per_category` items per
/// bucket. There is no cursor to ask for "the next 20", so a page counter on
/// the request would be fiction. What is worth paging is the render: building
/// a few hundred cards, each with its own network image, in one frame is what
/// makes a list like this stutter on entry, so rows are revealed [_pageSize] at
/// a time as the user reaches the end.
class NearYouAllScreen extends StatefulWidget {
  const NearYouAllScreen({super.key});

  @override
  State<NearYouAllScreen> createState() => _NearYouAllScreenState();
}

// ── Design tokens ──────────────────────────────────────────────────────────
// Local to this screen. It is a dense reading surface, so it takes a ground of
// its own rather than the Discover glass, which sits on a user-chosen
// background and cannot guarantee contrast behind small text.

/// Page ground: a cool paper, a shade darker than the cards so each card reads
/// as a sheet laid on it without needing a shadow.
const Color _paper = Color(0xFFEDF1F7);

/// The screen's dark. Same navy the rail fills a store avatar with, so a store
/// looks like the same object in both places.
const Color _ink = Color(0xFF17233F);

/// The only line weight on the page — card edges and the distance ladder.
const Color _hairline = Color(0xFFE1E8F0);

/// A worker who is online right now. The app's one "live" green.
const Color _live = Color(0xFF1FB35A);

/// Signage face, bundled with the app. Reserved for the distance rungs, the
/// category eyebrows and the chips — the parts you scan rather than read.
const String _condensed = 'AsapCondensed';

class _NearYouAllScreenState extends State<NearYouAllScreen> {
  /// The SAME instance the rail uses. Coming from the rail the set is already
  /// in memory, so the screen paints immediately and `fetchIfNeeded()` is a
  /// no-op; opened cold (deep link, back-stack restore) it fetches once.
  final _controller = getOrPut(() => NearbyStoresController());

  final ScrollController _scrollController = ScrollController();

  /// Rows revealed per page.
  static const int _pageSize = 24;

  /// How close to the bottom (in pixels) the user has to get before the next
  /// page is revealed — about a screen's worth, so the append has already
  /// happened by the time the end arrives.
  static const double _appendThreshold = 600;

  int _visible = _pageSize;

  /// Selected vertical, or null for "All". Held as the vertical's own label so
  /// it survives a refresh that changes the counts.
  String? _filter;

  /// Drives the shimmer during a pull-refresh. Local rather than read off the
  /// controller because the refresh re-acquires location first, and `isLoading`
  /// only covers the network call.
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchIfNeeded();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _appendThreshold) return;
    _revealNextPage();
  }

  void _revealNextPage() {
    final total = _entries().length;
    if (_visible >= total) return;
    setState(() => _visible = (_visible + _pageSize).clamp(0, total));
  }

  /// Re-acquire location so a move is picked up, then force-refetch (bypassing
  /// the controller's 24h TTL) and start over at page one — what comes back is
  /// a different neighbourhood's list, so keeping the scroll depth would strand
  /// the user in the middle of rows they never scrolled through.
  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await LocationService.ensureUsableLocation();
      await _controller.fetch();
    } finally {
      _visible = _pageSize;
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ── Data shaping ─────────────────────────────────────────────────────────

  /// Which chip an item belongs under. Stores answer with their own vertical
  /// (`Grocery` / `Food` / `Product` / `Healthcare`); workers are people, not a
  /// vertical, so they get their own bucket.
  String _verticalOf(NearbyEntry e) {
    final store = e.store;
    if (store == null) return 'People';
    switch (store.type.toLowerCase()) {
      case 'grocery':
        return 'Grocery';
      case 'food':
        return 'Food';
      case 'product':
        return 'Shops';
      case 'healthcare':
        return 'Health';
      default:
        // An unrecognised vertical still gets a chip rather than vanishing —
        // better a tab named after the raw type than stores nobody can reach.
        return store.type.isEmpty ? 'Shops' : store.type;
    }
  }

  /// Chip order. Not alphabetical and not the response's key order: everyday
  /// errands first, then the occasional ones.
  static const List<String> _verticalOrder = [
    'Grocery',
    'Food',
    'Shops',
    'Health',
    'People',
  ];

  /// Verticals present in the response, in [_verticalOrder], with their counts.
  /// Buckets with nothing in them are not offered — an empty tab is a dead end.
  List<MapEntry<String, int>> _buckets(List<NearbyEntry> all) {
    final counts = <String, int>{};
    for (final e in all) {
      counts.update(_verticalOf(e), (v) => v + 1, ifAbsent: () => 1);
    }
    final ordered = <MapEntry<String, int>>[];
    for (final key in _verticalOrder) {
      if (counts.containsKey(key)) ordered.add(MapEntry(key, counts.remove(key)!));
    }
    // Anything the order list doesn't name goes last, so a new vertical still
    // appears.
    ordered.addAll(counts.entries);
    return ordered;
  }

  List<NearbyEntry> _entries() {
    final all = buildNearbyEntries(_controller);
    if (_filter == null) return all;
    return all.where((e) => _verticalOf(e) == _filter).toList();
  }

  void _selectFilter(String? vertical) {
    if (_filter == vertical) return;
    setState(() {
      _filter = vertical;
      // A new, shorter list — start it at page one rather than showing three
      // pages of a five-item filter.
      _visible = _pageSize;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: CommonBackAppBar(title: 'Near you', isLeading: true),
      body: Obx(() {
        final all = buildNearbyEntries(_controller);
        final entries = _entries();
        // Shimmer on the first load and on a pull-refresh: `fetch()` leaves the
        // old list in place until the new one lands, so the list alone can't
        // say we're busy.
        final loading =
            (_controller.isLoading.value && all.isEmpty) || _isRefreshing;

        if (loading) return _skeleton();

        if (_controller.loaded.value && all.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _contextLine(all.length)),
              SliverToBoxAdapter(child: _filterRow(all)),
              _list(entries),
            ],
          ),
        );
      }),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  /// What the list is, in the fewest words that stay true: how many places, and
  /// the radius the BACKEND searched (`meta.radius`) rather than the one this
  /// app asked for.
  Widget _contextLine(int total) {
    final radius = _controller.radiusKm.value;
    final places = total == 1 ? '1 place' : '$total places';
    final scope = radius > 0 ? '$places within ${_trim(radius)} km' : places;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, SizeConfig.size14, 16, 0),
      child: CustomText(
        scope.toUpperCase(),
        fontFamily: _condensed,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: _ink.withValues(alpha: 0.55),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// The response's own buckets as filters. "All" leads, then each vertical
  /// with its count — the count is what makes the chip worth tapping, so it is
  /// part of the chip rather than a number revealed after.
  Widget _filterRow(List<NearbyEntry> all) {
    final buckets = _buckets(all);
    // One vertical means the chips would only ever restate the list.
    if (buckets.length < 2) return SizedBox(height: SizeConfig.size12);
    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        children: [
          _chip(label: 'All', count: all.length, vertical: null),
          for (final bucket in buckets) ...[
            const SizedBox(width: 8),
            _chip(
              label: bucket.key,
              count: bucket.value,
              vertical: bucket.key,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required int count,
    required String? vertical,
  }) {
    final selected = _filter == vertical;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectFilter(vertical),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _ink : AppColors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? _ink : _hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label.toUpperCase(),
              fontFamily: _condensed,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: selected ? AppColors.white : _ink,
            ),
            const SizedBox(width: 6),
            CustomText(
              '$count',
              fontFamily: _condensed,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.white.withValues(alpha: 0.6)
                  : _ink.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── The list ─────────────────────────────────────────────────────────────

  Widget _list(List<NearbyEntry> entries) {
    if (entries.isEmpty) {
      // Only reachable with a filter on — the unfiltered empty case is handled
      // before the list is built.
      return SliverToBoxAdapter(child: _emptyFilterState());
    }

    final shown = _visible.clamp(0, entries.length);
    final hasMore = shown < entries.length;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, SizeConfig.size24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == shown) return _appendFooter();
            final entry = entries[index];
            return _NearbyRow(
              key: ValueKey(entry.itemKey),
              entry: entry,
              // First rung starts the ladder, last one ends it — the hairline
              // is drawn per row, so the ends have to know they are ends.
              isFirst: index == 0,
              isLast: index == shown - 1 && !hasMore,
              onTap: openNearbyEntry,
            );
          },
          childCount: shown + (hasMore ? 1 : 0),
        ),
      ),
    );
  }

  /// Sits under the last revealed row while more remain. The append is driven
  /// by the scroll listener and is instant (the set is already in memory), so
  /// in practice this is a flash during a fast fling — it is here so the end of
  /// the page never reads as the end of the data.
  Widget _appendFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 6, bottom: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _ink.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  // ── Empty, outage and loading states ─────────────────────────────────────

  /// Nothing came back at all.
  ///
  /// One state, whatever the reason. A partly-failed response no longer gets
  /// its own wording here: `meta.degraded` carries a label on essentially every
  /// call, so branching on it meant the alarming copy was what users saw
  /// normally — and a warning nobody can act on is just noise. The retry covers
  /// both cases.
  Widget _emptyState() {
    final radius = _controller.radiusKm.value;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 36,
            color: _ink.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          CustomText(
            radius > 0
                ? 'Nothing within ${_trim(radius)} km'
                : 'Nothing nearby yet',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          CustomText(
            'Pull down to search again, or check back once you move.',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _ink.withValues(alpha: 0.55),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Center(child: _retryButton()),
        ],
      ),
    );
  }

  /// A filter with nothing behind it. Only reachable if the counts and the list
  /// disagree, so it points back to the way out rather than to a refresh.
  Widget _emptyFilterState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 48),
      child: Column(
        children: [
          CustomText(
            'No ${_filter?.toLowerCase() ?? ''} places in this list',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _selectFilter(null),
            child: CustomText(
              'Show all',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _retryButton() {
    return TextButton.icon(
      onPressed: _isRefreshing ? null : _refresh,
      style: TextButton.styleFrom(
        backgroundColor: _ink,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
      label: CustomText(
        'Search again',
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
      ),
    );
  }

  /// Placeholder in the shape of the real page — ladder included — so the swap
  /// to content moves nothing.
  Widget _skeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      itemCount: 6,
      itemBuilder: (_, index) => _SkeletonRow(isFirst: index == 0),
    );
  }

  /// `5` not `5.0`, `2.5` kept — the radius arrives as a double and reads as
  /// machine output with a trailing zero.
  static String _trim(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}

// ── One rung + its card ─────────────────────────────────────────────────────

/// A single row: the distance rung on the ladder, and the place it belongs to.
///
/// The two are one widget because the ladder only works if the hairline is
/// unbroken from row to row — it is drawn inside each row across the row's FULL
/// height (card and the gap under it), so consecutive rows join up.
class _NearbyRow extends StatelessWidget {
  const _NearbyRow({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final NearbyEntry entry;
  final bool isFirst;
  final bool isLast;
  final void Function(NearbyEntry entry) onTap;

  /// Width of the ladder column: the marker (13 at x=3) plus a 32px label slot,
  /// which is what "450" needs at the rung's size. The column is a label, not a
  /// margin, so it is measured against its widest real value rather than
  /// rounded up.
  static const double _spineWidth = 56;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _spineWidth,
            child: _Rung(
              distance: NearbyDistance.of(entry.distance),
              // The nearest place is the only filled marker on the page — the
              // one thing this screen is really answering.
              emphasised: isFirst,
              isFirst: isFirst,
              isLast: isLast,
            ),
          ),
          Expanded(child: _PlaceCard(entry: entry, onTap: onTap)),
        ],
      ),
    );
  }
}

/// One rung of the distance ladder: the hairline through the row, and this
/// item's distance sitting on it.
class _Rung extends StatelessWidget {
  const _Rung({
    required this.distance,
    required this.emphasised,
    required this.isFirst,
    required this.isLast,
  });

  final NearbyDistance? distance;
  final bool emphasised;
  final bool isFirst;
  final bool isLast;

  /// Where the rung sits from the top of the row — level with the card's logo,
  /// so the eye reads across from the distance to the place.
  static const double _rungTop = 22;

  @override
  Widget build(BuildContext context) {
    final label = distance;
    return Stack(
      children: [
        // The line starts at the first rung and stops at the last, so the
        // ladder never hangs a rail off either end — that reads as a list that
        // was cut off. A single result is all first AND last: one marker, no
        // line to draw at all.
        if (!(isFirst && isLast))
          Positioned(
            left: 9,
            top: isFirst ? _rungTop : 0,
            bottom: isLast ? null : 0,
            height: isLast ? _rungTop : null,
            child: Container(width: 1, color: _hairline),
          ),
        Positioned(
          // Centred on the line: 3 + 13/2 = 9.5, the line's own centre.
          left: 3,
          top: _rungTop - 6.5,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emphasised ? AppColors.primaryColor : _paper,
              border: Border.all(
                color: emphasised
                    ? AppColors.primaryColor
                    : _ink.withValues(alpha: 0.22),
                width: emphasised ? 4 : 1.5,
              ),
            ),
          ),
        ),
        if (label != null)
          Positioned(
            left: 22,
            right: 2,
            top: _rungTop - 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label.value,
                  fontFamily: _condensed,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: emphasised ? AppColors.primaryColor : _ink,
                  maxLines: 1,
                ),
                if (label.unit != null)
                  CustomText(
                    label.unit!.toUpperCase(),
                    fontFamily: _condensed,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    height: 1.2,
                    color: _ink.withValues(alpha: 0.45),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The place itself. A white sheet on the paper — one hairline, no shadow: with
/// a card on every row, shadows stack into grey mush and the ladder stops being
/// the thing you see first.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.entry, required this.onTap});

  final NearbyEntry entry;
  final void Function(NearbyEntry entry) onTap;

  @override
  Widget build(BuildContext context) {
    final store = entry.store;
    final worker = entry.worker;

    final String image =
        store != null ? store.displayImage : (worker?.profileImage ?? '');
    final String name = store != null
        ? store.businessName
        : (worker!.name.isNotEmpty ? worker.name : worker.professionName);
    final String eyebrow =
        store != null ? store.displayCategory : (worker?.displayLabel ?? '');
    final String detail = store?.address ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => onTap(entry),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _hairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(image: image, isStore: store != null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow.isNotEmpty) ...[
                        CustomText(
                          eyebrow.toUpperCase(),
                          fontFamily: _condensed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                          height: 1.1,
                          color: _ink.withValues(alpha: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                      ],
                      CustomText(
                        name,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: _ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        CustomText(
                          detail,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: _ink.withValues(alpha: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      _facts(store, worker),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The small true things, and only the ones this place actually has: a rating
  /// nobody has given is not a zero-star place, and a shop with no listed items
  /// should not advertise "0 items".
  Widget _facts(NearbyStoreCard? store, NearbyWorkerCard? worker) {
    final chips = <Widget>[];

    if (worker?.live == true) {
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _live, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            CustomText(
              'Available now',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _live,
            ),
          ],
        ),
      );
    }

    if (store != null && store.totalRatings > 0) {
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5A623)),
            const SizedBox(width: 3),
            CustomText(
              store.avgRating.toStringAsFixed(1),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
            const SizedBox(width: 3),
            CustomText(
              '(${store.totalRatings})',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.45),
            ),
          ],
        ),
      );
    }

    if (store != null && store.totalProductCount > 0) {
      final count = store.totalProductCount;
      chips.add(
        CustomText(
          count == 1 ? '1 item listed' : '$count items listed',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _ink.withValues(alpha: 0.5),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }
}

/// The place's own logo, on the navy the rail uses for a store. Square with a
/// generous radius rather than a circle: shop logos are usually square artwork,
/// and a circle crops their corners off.
class _Logo extends StatelessWidget {
  const _Logo({required this.image, required this.isStore});

  final String image;
  final bool isStore;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: _size,
        height: _size,
        color: isStore ? _ink : AppColors.primaryColor.withValues(alpha: 0.10),
        child: image.isEmpty
            ? _fallback()
            : CachedNetworkImage(
                imageUrl: Uri.encodeFull(image),
                fit: BoxFit.cover,
                width: _size,
                height: _size,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          isStore ? Icons.storefront_rounded : Icons.person_rounded,
          size: 24,
          color: isStore ? Colors.white : AppColors.primaryColor,
        ),
      );
}

/// Loading row — the ladder and a blank card in the real geometry, so nothing
/// jumps when the data lands.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.isFirst});

  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _NearbyRow._spineWidth,
            child: _Rung(
              distance: null,
              emphasised: false,
              isFirst: isFirst,
              isLast: false,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _hairline),
                ),
                child: Row(
                  children: [
                    _bar(52, 52, radius: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(8, 70),
                          const SizedBox(height: 8),
                          _bar(13, 150),
                          const SizedBox(height: 8),
                          _bar(10, double.infinity),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, double width, {double radius = 4}) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
