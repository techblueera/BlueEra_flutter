import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/search/controller/global_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/view/product_inquiry_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global search screen, launched from the Discover search bar. Type-ahead
/// suggestions while typing; a full hybrid search with facet tabs and infinite
/// scroll once a query is committed. Standalone — nothing else depends on it.
class GlobalSearchScreen extends StatefulWidget {
  /// Optional pre-filled query (e.g. if launched with an initial term).
  final String? initialQuery;

  const GlobalSearchScreen({super.key, this.initialQuery});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final controller = getOrPut(() => GlobalSearchController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      controller.queryController.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.submitSearch(initial);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Drop the controller so each entry into search starts from a clean state
    // (and its TextEditingController / FocusNode are disposed via onClose).
    deleteIfRegistered<GlobalSearchController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(

        preferredSize: const Size.fromHeight(60),
        child: SafeArea(child: _buildSearchField()),
      ),
      body: Obx(() {
        if (controller.showSuggestions.value) {
          return _buildSuggestions();
        }
        return _buildResults();
      }),
    );
  }

  // ── Search field ────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.mainTextColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // const Icon(Icons.search,
                  //     color: AppColors.secondaryTextColor, size: 22),
                  // const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.queryController,
                      focusNode: controller.focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: controller.onQueryChanged,
                      onSubmitted: controller.submitSearch,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mainTextColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search anything',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.queryController,
                    builder: (_, value, __) {
                      // Empty field mirrors the Flipkart reference — mic +
                      // camera affordances. Once the user types, they collapse
                      // to a single clear (✕) button.
                      if (value.text.isEmpty) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12),

                            LocalAssets(
                              imagePath: AppIconAssets.mic,
                              width: 20,
                              height: 20,
                              imgColor: AppColors.secondaryTextColor,
                            ),
                            const SizedBox(width: 12),
                            LocalAssets(
                              imagePath: AppIconAssets.camera_black,
                              width: 20,
                              height: 20,
                              imgColor: AppColors.secondaryTextColor,
                            ),
                          ],
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            controller.queryController.clear();
                            controller.onQueryChanged('');
                          },
                          child: const Icon(Icons.close,
                              color: AppColors.secondaryTextColor, size: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions view ────────────────────────────────────────────────
  /// Shown while [GlobalSearchController.showSuggestions] is true. With an
  /// empty field it renders the Flipkart-style discovery landing (recent /
  /// trending / popular); once the user types it becomes the type-ahead list.
  Widget _buildSuggestions() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.queryController,
      builder: (_, value, __) {
        if (value.text.trim().isEmpty) {
          return _buildSearchLanding();
        }
        return _buildSuggestionList(value.text);
      },
    );
  }

  Widget _buildSuggestionList(String query) {
    return Obx(() {
      final items = controller.suggestions;
      if (items.isEmpty) {
        return _centeredHint(
          icon: Icons.search,
          message: 'Keep typing to see suggestions',
        );
      }
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, thickness: 1, color: AppColors.greyE5, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => _suggestionTile(items[i], query),
      );
    });
  }

  Widget _suggestionTile(Suggestion s, String query) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: 6),
      horizontalTitleGap: 12,
      leading: _thumb(s.imageUrl, s.entityType),
      title: _highlightedSuggestionTitle(s.title, query),
      subtitle: (s.subtitle != null && s.subtitle!.trim().isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomText(
                // "in {category}" context line, as in the reference.
                'in ${s.subtitle!.trim()}',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.blue5CAF,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      // The ↖ arrow lifts the term back into the field (doesn't run the
      // search) so the user can refine it further — matching the reference.
      trailing: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _fillQuery(s.title),
        child: const Icon(Icons.north_west,
            size: 20, color: AppColors.secondaryTextColor),
      ),
      onTap: () => controller.submitSearch(s.title),
    );
  }

  /// Lift a suggestion into the search field (cursor at end) without
  /// committing the search, and refresh the suggestion list for it.
  void _fillQuery(String term) {
    controller.queryController.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    controller.onQueryChanged(term);
  }

  /// Renders the suggestion title with the matched query substring
  /// de-emphasised (regular grey) and the rest bold — the classic
  /// type-ahead treatment shown in the reference (e.g. "mo" grey +
  /// "torola mobile 5g" bold).
  Widget _highlightedSuggestionTitle(String title, String query) {
    final restStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
    final matchStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.secondaryTextColor,
    );

    final q = query.trim();
    final matchIndex =
        q.isEmpty ? -1 : title.toLowerCase().indexOf(q.toLowerCase());
    if (matchIndex < 0) {
      return Text(title,
          style: restStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final before = title.substring(0, matchIndex);
    final match = title.substring(matchIndex, matchIndex + q.length);
    final after = title.substring(matchIndex + q.length);
    return Text.rich(
      TextSpan(children: [
        if (before.isNotEmpty) TextSpan(text: before, style: restStyle),
        TextSpan(text: match, style: matchStyle),
        if (after.isNotEmpty) TextSpan(text: after, style: restStyle),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Discovery landing (empty query) ─────────────────────────────────
  /// Curated trending terms. Trending is normally an admin/server-driven
  /// list; this static set gives the section shippable content and each
  /// entry commits a real search on tap.
  static const List<String> _trendingSearches = [
    'Mobiles under 15000',
    'Shoes',
    'Bike covers',
    'Home cleaning',
    'Salon at home',
    'Men accessories',
  ];

  /// Popular product/category shortcuts shown as cards. Each opens a real
  /// search for its title.
  static const List<({String title, String subtitle, IconData icon})>
      _popularProducts = [
    (title: 'Mobiles', subtitle: 'Latest 5G phones', icon: Icons.smartphone_outlined),
    (title: 'Fashion', subtitle: 'Shoes & apparel', icon: Icons.checkroom_outlined),
    (title: 'Grocery', subtitle: 'Daily essentials', icon: Icons.local_grocery_store_outlined),
    (title: 'Electronics', subtitle: 'Gadgets & more', icon: Icons.headphones_outlined),
    (title: 'Home', subtitle: 'Kitchen & decor', icon: Icons.chair_outlined),
  ];

  Widget _buildSearchLanding() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: SizeConfig.size24),
      children: [
        _recentSearchesSection(),
        _trendingSearchesSection(),
        _popularProductsSection(),
      ],
    );
  }

  Widget _landingSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size16, SizeConfig.size16, SizeConfig.size12),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionSpacer() =>
      Container(height: 8, color: AppColors.whiteF4);

  // ── Recent searches ────────────────────────────────────────────────
  Widget _recentSearchesSection() {
    return Obx(() {
      final recents = controller.recentSearches;
      if (recents.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _landingSectionTitle(
            'Recent Searches',
            trailing: GestureDetector(
              onTap: controller.clearRecentSearches,
              child: CustomText(
                'Clear all',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.blue5CAF,
              ),
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              itemCount: recents.length,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size16),
              itemBuilder: (_, i) => _recentSearchTile(recents[i]),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          _sectionSpacer(),
        ],
      );
    });
  }

  Widget _recentSearchTile(String term) {
    return GestureDetector(
      onTap: () => controller.submitSearch(term),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greyE5),
              ),
              alignment: Alignment.center,
              child: LocalAssets(
                imagePath: AppIconAssets.history,
                width: 24,
                height: 24,
                imgColor: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            CustomText(
              term,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Trending searches ──────────────────────────────────────────────
  Widget _trendingSearchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _landingSectionTitle('Trending Searches'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final term in _trendingSearches)
                    SizedBox(width: tileWidth, child: _trendingTile(term)),
                ],
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        _sectionSpacer(),
      ],
    );
  }

  Widget _trendingTile(String term) {
    return GestureDetector(
      onTap: () => controller.submitSearch(term),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.whiteF9,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          children: [
            _tintedIconBox(Icons.trending_up, size: 40, radius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                term,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular products ───────────────────────────────────────────────
  Widget _popularProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _landingSectionTitle('Popular Products'),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            itemCount: _popularProducts.length,
            separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
            itemBuilder: (_, i) => _popularProductCard(_popularProducts[i]),
          ),
        ),
      ],
    );
  }

  Widget _popularProductCard(
      ({String title, String subtitle, IconData icon}) product) {
    return GestureDetector(
      onTap: () => controller.submitSearch(product.title),
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.whiteF9,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: _tintedIconBox(product.icon, size: 56, radius: 14),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    product.title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    product.subtitle,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Brand-tinted rounded square holding an entity/category icon — the app's
  /// consistent stand-in for a product/category thumbnail.
  Widget _tintedIconBox(IconData icon, {required double size, required double radius}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blue5CAF.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: AppColors.blue5CAF),
    );
  }

  // ── Results view ────────────────────────────────────────────────────
  Widget _buildResults() {
    return Obx(() {
      final status = controller.status.value;
      if (status == Status.LOADING) {
        return const Center(child: CircularProgressIndicator());
      }
      if (status == Status.ERROR) {
        return _errorState();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultsHeaderBar(),
          _appliedFiltersChip(),
          Expanded(child: _resultsList()),
        ],
      );
    });
  }

  // ── Sort / Filter / chips bar (Flipkart-style) ──────────────────────
  Widget _resultsHeaderBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.greyE5)),
      ),
      height: 52,
      child: Obx(() {
        final active = controller.activeType.value;
        final entries = controller.facets.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12, vertical: 8),
          children: [
            _pillButton(
              label: 'Sort',
              trailingIcon: Icons.keyboard_arrow_down,
              onTap: _openSortSheet,
            ),
            const SizedBox(width: 8),
            _pillButton(
              label: 'Filter',
              trailingIcon: Icons.tune,
              onTap: () => commonSnackBar(message: 'Filters coming soon'),
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(width: 8),
              _vDivider(),
              const SizedBox(width: 8),
              _chip('All (${controller.total.value})', active == null,
                  () => controller.selectType(null)),
              for (final e in entries)
                _chip('${_entityLabel(e.key)} (${e.value})', active == e.key,
                    () => controller.selectType(e.key)),
            ],
          ],
        );
      }),
    );
  }

  Widget _pillButton({
    required String label,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 18, color: AppColors.mainTextColor),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.greyE5,
      );

  void _openSortSheet() {
    const options = <({String label, String? key})>[
      (label: 'Relevance', key: null),
      (label: 'Price -- Low to High', key: 'price_asc'),
      (label: 'Price -- High to Low', key: 'price_desc'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CustomText(
                'Sort by',
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ),
            Obx(() {
              final current = controller.sortKey.value;
              return Column(
                children: [
                  for (final o in options)
                    ListTile(
                      title: CustomText(
                        o.label,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: current == o.key
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      trailing: current == o.key
                          ? const Icon(Icons.check, color: AppColors.blue5CAF)
                          : null,
                      onTap: () {
                        controller.applySort(o.key);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue5CAF : AppColors.white,
            border: Border.all(
                color: selected ? AppColors.blue5CAF : AppColors.greyE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.white : AppColors.mainTextColor,
          ),
        ),
      ),
    );
  }

  Widget _appliedFiltersChip() {
    return Obx(() {
      final text = controller.appliedFiltersText.value;
      if (text.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.fromLTRB(SizeConfig.size12, 4, SizeConfig.size12, 4),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined,
                size: 16, color: AppColors.secondaryTextColor),
            const SizedBox(width: 4),
            Flexible(
              child: CustomText(
                text,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _resultsList() {
    return Obx(() {
      final items = controller.results;
      if (items.isEmpty) {
        return _centeredHint(
          icon: Icons.search_off,
          message:
              'No results for "${controller.committedQuery}".\nTry a different search.',
        );
      }
      // Two-column grid (Flipkart-style) for the results. Product entities get
      // the rich product tile; other entity types fall back to a compact card.
      // A CustomScrollView keeps the paginating footer full-width below the grid.
      return CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(SizeConfig.size12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: SizeConfig.size12,
                crossAxisSpacing: SizeConfig.size12,
                mainAxisExtent: 290,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  return _isProductType(item.entityType)
                      ? _productGridCard(item)
                      : _resultGridCard(item);
                },
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            // Footer: loading spinner while paginating, else spacer.
            child: Obx(() => controller.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: 24)),
          ),
        ],
      );
    });
  }

  static const Set<String> _productTypes = {
    'product',
    'variant',
    'grocery_product',
  };

  bool _isProductType(String entityType) => _productTypes.contains(entityType);

  // ── Product grid tile (Flipkart-style, 2-per-row) ───────────────────
  Widget _productGridCard(SearchResultItem item) {
    final green = Colors.green.shade700;
    return InkWell(
      // Tapping a product tile opens the Flipkart-style enquiry sheet
      // (photo, pricing, discount, variants, highlights + nearby sellers).
      onTap: () => showProductInquiryBottomSheet(context, item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner with wishlist heart + optional "Sponsored" tag.
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _gridProductImage(item.imageUrl),
                ),
                if (item.sponsored)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomText(
                        'Sponsored',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                Positioned(top: 2, right: 2, child: _WishlistHeart()),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      item.title,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.rating != null) ...[
                      const SizedBox(height: 6),
                      _gridRatingRow(item, green),
                    ],
                    const Spacer(),
                    if (item.price != null) _gridPriceBlock(item, green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridProductImage(String? url) {
    final placeholder = Container(
      height: 150,
      width: double.infinity,
      color: AppColors.whiteF9,
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined,
          color: AppColors.secondaryTextColor, size: 38),
    );
    return (url != null && url.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.contain,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          )
        : placeholder;
  }

  Widget _gridRatingRow(SearchResultItem item, Color green) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                item.rating!.toStringAsFixed(1),
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star, size: 11, color: AppColors.white),
            ],
          ),
        ),
        if (item.ratingCount != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: CustomText(
              '(${item.ratingCount})',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (item.assured) ...[
          const SizedBox(width: 4),
          Icon(Icons.verified, size: 14, color: AppColors.blue5CAF),
        ],
      ],
    );
  }

  Widget _gridPriceBlock(SearchResultItem item, Color green) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              '₹${SearchResponse.formatPrice(item.price)}',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            if (item.hasDiscount) ...[
              const SizedBox(width: 6),
              Flexible(
                child: CustomText(
                  '₹${SearchResponse.formatPrice(item.mrp)}',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  decoration: TextDecoration.lineThrough,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (item.hasDiscount)
          CustomText(
            '${item.discountPercent}% off',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: green,
          ),
      ],
    );
  }

  // ── Non-product result tile (compact, for the grid) ─────────────────
  Widget _resultGridCard(SearchResultItem item) {
    return InkWell(
      onTap: () => _openResult(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _thumb(item.imageUrl, item.entityType)),
            const SizedBox(height: 10),
            CustomText(
              item.title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              CustomText(
                item.subtitle!,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            _typeBadge(item.entityType),
            const Spacer(),
            if (item.price != null)
              CustomText(
                '₹${SearchResponse.formatPrice(item.price)}',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String entityType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.blue5CAF.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        _entityLabel(entityType),
        fontSize: SizeConfig.small,
        color: AppColors.blue5CAF,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _thumb(String? url, String entityType) {
    final bool isPerson = entityType == 'user' || entityType == 'business';
    final radius = isPerson ? 24.0 : 8.0;
    Widget placeholder = Container(
      width: 48,
      height: 48,
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: Icon(_entityIcon(entityType),
          color: AppColors.secondaryTextColor, size: 22),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off,
              size: 48, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'Something went wrong',
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size8),
          TextButton(
            onPressed: controller.retry,
            child: CustomText(
              'Retry',
              fontSize: SizeConfig.medium,
              color: AppColors.blue5CAF,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredHint({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.greyE5),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              message,
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle a result tap. Product-type results open the existing self-pickup
  /// order flow (add to cart → [GrocerySelfPickUpCartScreen] → place order).
  /// Other entity types aren't wired into the app's detail screens yet, so
  /// they surface safely as a snackbar without touching any existing flow.
  void _openResult(SearchResultItem item) {
    if (_isProductType(item.entityType)) {
      controller.openProductOrder(item);
      return;
    }
    commonSnackBar(message: item.title);
  }

  String _entityLabel(String type) {
    switch (type) {
      case 'product':
      case 'variant':
        return 'Product';
      case 'grocery_product':
        return 'Grocery';
      case 'grocery_shop':
        return 'Grocery Shop';
      case 'user':
        return 'People';
      case 'business':
        return 'Business';
      case 'service':
        return 'Service';
      default:
        return type.isEmpty
            ? 'Result'
            : '${type[0].toUpperCase()}${type.substring(1)}';
    }
  }

  IconData _entityIcon(String type) {
    switch (type) {
      case 'product':
      case 'variant':
        return Icons.shopping_bag_outlined;
      case 'grocery_product':
      case 'grocery_shop':
        return Icons.local_grocery_store_outlined;
      case 'user':
        return Icons.person_outline;
      case 'business':
        return Icons.storefront_outlined;
      case 'service':
        return Icons.handyman_outlined;
      default:
        return Icons.search;
    }
  }
}

/// Wishlist heart shown on each product card. Toggles locally only — there is
/// no wishlist backend for search results yet, so it's a purely visual
/// affordance matching the reference (outline → filled red on tap).
class _WishlistHeart extends StatefulWidget {
  @override
  State<_WishlistHeart> createState() => _WishlistHeartState();
}

class _WishlistHeartState extends State<_WishlistHeart> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _liked = !_liked),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 2),
        child: Icon(
          _liked ? Icons.favorite : Icons.favorite_border,
          size: 22,
          color: _liked ? const Color(0xFFC2185B) : AppColors.secondaryTextColor,
        ),
      ),
    );
  }
}
