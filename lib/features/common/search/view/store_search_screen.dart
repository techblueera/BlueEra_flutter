import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/search/controller/store_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen store search for ONE vertical, opened from a listing screen's
/// search bar (currently the grocery stores screen).
///
/// Three states, in the order a user meets them — the shape every e-commerce
/// search uses:
///
///  1. **Landing** (empty field) — recent searches, tap to re-run.
///  2. **Typing** — debounced type-ahead suggestions from `/suggest`.
///  3. **Committed** — the paginated `/search` result list; tapping a store
///     opens its profile.
///
/// Nothing here is grocery-specific: the category searched, the entity types
/// asked for, the recents key and the profile a tap opens all come from
/// [StoreSearchConfig], so another vertical reuses this screen as-is.
class StoreSearchScreen extends StatefulWidget {
  const StoreSearchScreen({super.key, required this.config, this.initialQuery});

  final StoreSearchConfig config;

  /// Optional pre-filled query, committed on first frame.
  final String? initialQuery;

  @override
  State<StoreSearchScreen> createState() => _StoreSearchScreenState();
}

class _StoreSearchScreenState extends State<StoreSearchScreen> {
  late final StoreSearchController controller;
  final ScrollController _scrollController = ScrollController();

  /// One registration per vertical, so a second store search opened over this
  /// one (a different category) gets its own state instead of inheriting this
  /// query and result list.
  String get _tag => 'store_search_${widget.config.recentSearchesKey}';

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => StoreSearchController(widget.config),
        tag: _tag);
    _scrollController.addListener(_onScroll);

    final initial = widget.initialQuery?.trim() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (initial.isNotEmpty) {
        controller.submitSearch(initial);
      } else {
        // Land with the keyboard already up — the user tapped a search bar.
        controller.focusNode.requestFocus();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Drop the controller so the next entry starts clean (and its
    // TextEditingController / FocusNode are disposed via onClose). Recents
    // survive — they live in SharedPreferences, not in the instance.
    deleteIfRegistered<StoreSearchController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            const Divider(height: 1, color: AppColors.greyE5),
            Expanded(
              child: Obx(() {
                if (controller.showSuggestions.value) {
                  return controller.queryText.value.trim().isEmpty
                      ? _recentSearches()
                      : _suggestionList();
                }
                return _resultList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ─────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.mainTextColor, size: 22),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.secondaryTextColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppColors.secondaryTextColor, size: 20),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: TextField(
                      controller: controller.queryController,
                      focusNode: controller.focusNode,
                      onChanged: controller.onQueryChanged,
                      onSubmitted: controller.submitSearch,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.config.hintText,
                        hintStyle: TextStyle(
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 14,
                        ),

                        // Default Border
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1.2,
                          ),
                        ),

                        // Enabled Border
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1.2,
                          ),
                        ),

                        // Focused Border
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),

                        // Error Border (Optional)
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  /*    Expanded(
                    child: TextField(
                      controller: controller.queryController,
                      focusNode: controller.focusNode,
                      onChanged: controller.onQueryChanged,
                      onSubmitted: controller.submitSearch,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: widget.config.hintText,
                        hintStyle: TextStyle(
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),*/
                  // Clear — only once there is something to clear.
                  Obx(() {
                    if (controller.queryText.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller.clearQuery,
                      child: Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size6),
                        child: const Icon(Icons.close,
                            color: AppColors.secondaryTextColor, size: 18),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size8),
        ],
      ),
    );
  }

  // ─── Landing: recent searches ───────────────────────────────────────

  Widget _recentSearches() {
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return _hintState(
          icon: Icons.storefront_outlined,
          message: 'Search by name',
        );
      }
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: SizeConfig.size24),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size16,
                SizeConfig.size8, SizeConfig.size4),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Recent searches',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                TextButton(
                  onPressed: controller.clearRecentSearches,
                  child: CustomText(
                    'Clear all',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...controller.recentSearches.map(
            (term) => ListTile(
              dense: true,
              leading: const Icon(Icons.history,
                  color: AppColors.secondaryTextColor, size: 20),
              title: CustomText(
                term,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.secondaryTextColor, size: 16),
                onPressed: () => controller.removeRecentSearch(term),
              ),
              onTap: () => controller.submitSearch(term),
            ),
          ),
        ],
      );
    });
  }

  // ─── Typing: suggestions ────────────────────────────────────────────

  Widget _suggestionList() {
    return Obx(() {
      final items = controller.suggestions;
      if (items.isEmpty) {
        // Deliberately no spinner: suggestions are a 250 ms-debounced
        // convenience, and a flashing loader under the keyboard on every
        // keystroke reads worse than nothing. The user can commit the query
        // from the keyboard at any point.
        return _hintState(
          icon: Icons.search,
          message: 'Press search to look for “${controller.queryText.value}”',
        );
      }
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 56, color: AppColors.greyE5),
        itemBuilder: (_, i) {
          final s = items[i];
          return ListTile(
            dense: true,
            leading: _suggestionLeading(s),
            title: CustomText(
              s.title,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: (s.subtitle?.trim().isNotEmpty ?? false)
                ? CustomText(
                    s.subtitle!,
                    fontSize: SizeConfig.small11,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            // Fills the field instead of committing, so the user can refine —
            // the standard type-ahead affordance.
            trailing: IconButton(
              icon: const Icon(Icons.north_west,
                  color: AppColors.secondaryTextColor, size: 18),
              onPressed: () {
                controller.queryController.text = s.title;
                controller.onQueryChanged(s.title);
              },
            ),
            onTap: () => controller.submitSearch(s.title),
          );
        },
      );
    });
  }

  Widget _suggestionLeading(Suggestion s) {
    final url = s.imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const Icon(Icons.search,
          color: AppColors.secondaryTextColor, size: 20);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.greyE5),
        errorWidget: (_, __, ___) => const Icon(Icons.search,
            color: AppColors.secondaryTextColor, size: 20),
      ),
    );
  }

  // ─── Committed: results ─────────────────────────────────────────────

  Widget _resultList() {
    return Obx(() {
      if (controller.status.value == Status.LOADING) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
      }
      if (controller.status.value == Status.ERROR) {
        return _hintState(
          icon: Icons.wifi_off,
          message: 'Something went wrong',
          actionLabel: 'Retry',
          onAction: controller.retry,
        );
      }
      if (controller.results.isEmpty) {
        return _hintState(
          icon: Icons.storefront_outlined,
          message: 'No results found for “${controller.committedQuery}”',
        );
      }

      final showLoadMore = controller.isLoadingMore.value;
      return ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size8,
            SizeConfig.size12, SizeConfig.size24),
        itemCount: controller.results.length + 1 + (showLoadMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size4, bottom: SizeConfig.size8),
              child: CustomText(
                // The server's own count of the whole match set, not the page
                // — every config is scoped server-side, so nothing is dropped
                // on the client and this can be trusted.
                //
                // Neutral noun on purpose: the same list renders stores,
                // hospitals, properties and home kitchens depending on the
                // config, and "properties" is not "property" + s.
                '${controller.total.value} ${controller.total.value == 1 ? 'result' : 'results'} found',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
            );
          }
          if (index == controller.results.length + 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.blue.shade300),
                ),
              ),
            );
          }
          return _storeCard(controller.results[index - 1]);
        },
      );
    });
  }

  Widget _storeCard(SearchResultItem item) {
    final logo = item.imageUrl?.trim() ?? '';
    final location = [item.city, item.pincode]
        .where((e) => (e?.trim().isNotEmpty ?? false))
        .join(' · ');
    final subtitle = (item.subtitle?.trim().isNotEmpty ?? false)
        ? item.subtitle!.trim()
        : location;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => controller.openResult(item),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logo.isEmpty
                  ? Container(
                      width: 48,
                      height: 48,
                      color: AppColors.greyE5,
                      child: const Icon(Icons.storefront,
                          color: AppColors.secondaryTextColor, size: 22),
                    )
                  : CachedNetworkImage(
                      imageUrl: logo,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 48, height: 48, color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.greyE5,
                        child: const Icon(Icons.storefront,
                            color: AppColors.secondaryTextColor, size: 22),
                      ),
                    ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    item.title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.small11,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Shared empty / error state ─────────────────────────────────────

  Widget _hintState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              message,
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: SizeConfig.size12),
              TextButton(
                onPressed: onAction,
                child: CustomText(
                  actionLabel,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
