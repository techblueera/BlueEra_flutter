import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/search/controller/global_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_category.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/view/product_inquiry_bottom_sheet.dart';
import 'package:BlueEra/features/common/search/widget/search_result_card.dart';
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
        // Search field + the category strip beneath it. The strip stays pinned
        // for both the suggestion and the results view, so the scope can be
        // changed before *or* after a query is committed.
        preferredSize: const Size.fromHeight(110),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchField(),
              _buildCategoryBar(),
            ],
          ),
        ),
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
                        hintText: AppStrings.globalSearchHint.tr,
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

  // ── Category scope chips ────────────────────────────────────────────
  /// Icon shown on each category chip. Purely presentational — the wire value
  /// lives on [SearchCategory].
  static const Map<SearchCategory, IconData> _categoryIcons = {
    SearchCategory.all: Icons.apps_outlined,
    SearchCategory.content: Icons.dynamic_feed_outlined,
    SearchCategory.video: Icons.play_circle_outline,
    SearchCategory.userfeed: Icons.article_outlined,
    SearchCategory.grocery: Icons.local_grocery_store_outlined,
    SearchCategory.food: Icons.restaurant_outlined,
    SearchCategory.shopping: Icons.shopping_bag_outlined,
    SearchCategory.healthcare: Icons.local_hospital_outlined,
    SearchCategory.automotive: Icons.directions_car_outlined,
    SearchCategory.stay: Icons.hotel_outlined,
    SearchCategory.homemadeFood: Icons.soup_kitchen_outlined,
    SearchCategory.homemadeProducts: Icons.inventory_2_outlined,
    SearchCategory.homeServices: Icons.home_repair_service_outlined,
    SearchCategory.consultants: Icons.badge_outlined,
    SearchCategory.services: Icons.handyman_outlined,
    SearchCategory.rentals: Icons.vpn_key_outlined,
    SearchCategory.finance: Icons.account_balance_outlined,
    SearchCategory.jobs: Icons.work_outline,
    SearchCategory.education: Icons.school_outlined,
    SearchCategory.shops: Icons.storefront_outlined,
  };

  /// Horizontally scrolling scope selector shown under the search field. Picking
  /// a chip sets the `category` sent with the search; "All" (also the ✕ on the
  /// selected chip) clears it back to searching everything.
  Widget _buildCategoryBar() {
    const categories = SearchCategory.values;
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.greyE5)),
      ),
      child: Obx(() {
        final selected = controller.selectedCategory.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) =>
              _categoryChip(categories[i], categories[i] == selected),
        );
      }),
    );
  }

  Widget _categoryChip(SearchCategory category, bool selected) {
    final isAll = category == SearchCategory.all;
    return GestureDetector(
      onTap: () => controller.selectCategory(category),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue5CAF : AppColors.white,
          border: Border.all(
              color: selected ? AppColors.blue5CAF : AppColors.greyE5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcons[category] ?? Icons.search,
              size: 16,
              color: selected ? AppColors.white : AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            CustomText(
              category.labelKey.tr,
              fontSize: SizeConfig.small,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.white : AppColors.mainTextColor,
            ),
            // The selected vertical carries its own clear button, so the filter
            // can be dropped without hunting for "All" at the far left.
            if (selected && !isAll) ...[
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.clearCategory,
                child: const Icon(Icons.close, size: 14, color: AppColors.white),
              ),
            ],
          ],
        ),
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
          message: AppStrings.globalSearchKeepTyping.tr,
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
      subtitle: _suggestionSubtitle(s),
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

  /// "in {category}" context line, plus the row's distance / address when the
  /// backend measured one. Both are per-row — a shop suggestion has them, the
  /// product it stocks doesn't — so the line is built conditionally.
  Widget? _suggestionSubtitle(Suggestion s) {
    final context = s.subtitle?.trim() ?? '';
    final location = s.locationLine;
    if (context.isEmpty && location.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.isNotEmpty)
            CustomText(
              AppStrings.globalSearchInCategoryFmt
                  .trParams({'category': context}),
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.blue5CAF,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (location.isNotEmpty) _locationLine(location),
        ],
      ),
    );
  }

  /// Distance · address line. Rendered only when the row actually carries one —
  /// never as a fixed slot, since one list mixes rows that have it with rows
  /// that don't (`healthcare` returns hospitals next to medicines).
  Widget _locationLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 2),
          Expanded(
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
  ///
  /// [query] is what actually goes to the search API and stays English on
  /// purpose — the index is English, so searching a translated term would
  /// return nothing. Only [labelKey] is localised.
  static const List<({String query, String labelKey})> _trendingSearches = [
    (
      query: 'Mobiles under 15000',
      labelKey: AppStrings.globalSearchTrendMobilesUnder15000
    ),
    (query: 'Shoes', labelKey: AppStrings.globalSearchTrendShoes),
    (query: 'Bike covers', labelKey: AppStrings.globalSearchTrendBikeCovers),
    (
      query: 'Home cleaning',
      labelKey: AppStrings.globalSearchTrendHomeCleaning
    ),
    (
      query: 'Salon at home',
      labelKey: AppStrings.globalSearchTrendSalonAtHome
    ),
    (
      query: 'Men accessories',
      labelKey: AppStrings.globalSearchTrendMenAccessories
    ),
  ];

  /// Popular product/category shortcuts shown as cards. Each opens a real
  /// search for its (English) [query]; the card text is localised.
  static const List<
      ({
        String query,
        String titleKey,
        String subtitleKey,
        IconData icon
      })> _popularProducts = [
    (
      query: 'Mobiles',
      titleKey: AppStrings.globalSearchPopMobiles,
      subtitleKey: AppStrings.globalSearchPopMobilesSub,
      icon: Icons.smartphone_outlined
    ),
    (
      query: 'Fashion',
      titleKey: AppStrings.globalSearchPopFashion,
      subtitleKey: AppStrings.globalSearchPopFashionSub,
      icon: Icons.checkroom_outlined
    ),
    (
      query: 'Grocery',
      titleKey: AppStrings.globalSearchPopGrocery,
      subtitleKey: AppStrings.globalSearchPopGrocerySub,
      icon: Icons.local_grocery_store_outlined
    ),
    (
      query: 'Electronics',
      titleKey: AppStrings.globalSearchPopElectronics,
      subtitleKey: AppStrings.globalSearchPopElectronicsSub,
      icon: Icons.headphones_outlined
    ),
    (
      query: 'Home',
      titleKey: AppStrings.globalSearchPopHome,
      subtitleKey: AppStrings.globalSearchPopHomeSub,
      icon: Icons.chair_outlined
    ),
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
            AppStrings.globalSearchRecentSearches.tr,
            trailing: GestureDetector(
              onTap: controller.clearRecentSearches,
              child: CustomText(
                AppStrings.clearAll.tr,
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
        _landingSectionTitle(AppStrings.globalSearchTrendingSearches.tr),
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

  Widget _trendingTile(({String query, String labelKey}) term) {
    return GestureDetector(
      onTap: () => controller.submitSearch(term.query),
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
                term.labelKey.tr,
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
        _landingSectionTitle(AppStrings.globalSearchPopularProducts.tr),
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
      ({String query, String titleKey, String subtitleKey, IconData icon})
          product) {
    return GestureDetector(
      onTap: () => controller.submitSearch(product.query),
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
                    product.titleKey.tr,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    product.subtitleKey.tr,
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
          // Tinted backdrop so the white result cards read as separate cards
          // rather than as one flat sheet (as in the reference design).
          Expanded(
            child: Container(
              color: AppColors.whiteF9,
              child: _resultsList(),
            ),
          ),
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
              label: AppStrings.globalSearchSort.tr,
              trailingIcon: Icons.keyboard_arrow_down,
              onTap: _openSortSheet,
            ),
            const SizedBox(width: 8),
            _pillButton(
              label: AppStrings.globalSearchFilter.tr,
              trailingIcon: Icons.tune,
              onTap: () => commonSnackBar(
                  message: AppStrings.globalSearchFiltersComingSoon.tr),
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(width: 8),
              _vDivider(),
              const SizedBox(width: 8),
              // "100+" past the pool ceiling — `total` is the size of the
              // server's candidate pool, not a global match count.
              _chip(
                  '${AppStrings.searchCatAll.tr} (${controller.totalLabel.value})',
                  active == null, () => controller.selectType(null)),
              for (final e in entries)
                _chip('${searchEntityLabel(e.key)} (${e.value})', active == e.key,
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
    const options = <({String labelKey, String? key})>[
      (labelKey: AppStrings.globalSearchRelevance, key: null),
      (labelKey: AppStrings.globalSearchPriceLowToHigh, key: 'price_asc'),
      (labelKey: AppStrings.globalSearchPriceHighToLow, key: 'price_desc'),
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
                AppStrings.globalSearchSortBy.tr,
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
                        o.labelKey.tr,
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
        final category = controller.selectedCategory.value;
        final scoped = category != SearchCategory.all;
        return _centeredHint(
          icon: Icons.search_off,
          message: scoped
              ? AppStrings.globalSearchNoResultsInCategoryFmt.trParams({
                  'query': controller.committedQuery,
                  'category': category.labelKey.tr,
                })
              : AppStrings.globalSearchNoResultsFmt
                  .trParams({'query': controller.committedQuery}),
          // An empty scoped tab is usually the scope, not the query — offer the
          // way out rather than making the user find the chip again.
          action: scoped
              ? TextButton(
                  onPressed: controller.clearCategory,
                  child: CustomText(
                    AppStrings.globalSearchSearchAllCategories.tr,
                    fontSize: SizeConfig.medium,
                    color: AppColors.blue5CAF,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        );
      }
      // Single-column listing card (docs/saerch_cat_view.png): avatar, title,
      // rating · category, distance · address and a trailing count/price badge.
      // A CustomScrollView keeps the paginating footer below the list.
      return CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                SizeConfig.size12, SizeConfig.size12, SizeConfig.size12, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size12),
                    child: SearchResultCard(
                      item: item,
                      // Products keep the richer enquiry sheet (photo, pricing,
                      // variants, nearby sellers); every other entity type goes
                      // through _openResult.
                      onTap: () => isSearchProductType(item.entityType)
                          ? showProductInquiryBottomSheet(context, item)
                          : _openResult(item),
                    ),
                  );
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

  Widget _thumb(String? url, String entityType) {
    final bool isPerson = entityType == 'user' || entityType == 'business';
    final radius = isPerson ? 24.0 : 8.0;
    Widget placeholder = Container(
      width: 48,
      height: 48,
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: Icon(searchEntityIcon(entityType),
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
            AppStrings.globalSearchSomethingWentWrong.tr,
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          TextButton(
            onPressed: controller.retry,
            child: CustomText(
              AppStrings.retry.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.blue5CAF,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredHint({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
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
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  /// Handle a result tap. Product-type results open the existing self-pickup
  /// order flow (add to cart → [GrocerySelfPickUpCartScreen] → place order);
  /// people and shops open their profile screen. Anything else still has no
  /// detail screen wired, so it surfaces as a snackbar.
  void _openResult(SearchResultItem item) {
    if (isSearchProductType(item.entityType)) {
      controller.openProductOrder(item);
      return;
    }
    controller.openProfile(item);
  }
}
