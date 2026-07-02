import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/search/controller/global_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
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
            icon: const Icon(Icons.arrow_back, color: AppColors.mainTextColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppColors.secondaryTextColor, size: 22),
                  const SizedBox(width: 8),
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
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          controller.queryController.clear();
                          controller.onQueryChanged('');
                        },
                        child: const Icon(Icons.close,
                            color: AppColors.secondaryTextColor, size: 20),
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
  Widget _buildSuggestions() {
    return Obx(() {
      final items = controller.suggestions;
      if (items.isEmpty) {
        return _centeredHint(
          icon: Icons.search,
          message: controller.queryController.text.trim().isEmpty
              ? 'Search for products, shops, people, services…'
              : 'Keep typing to see suggestions',
        );
      }
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.greyE5),
        itemBuilder: (_, i) {
          final s = items[i];
          return ListTile(
            leading: _thumb(s.imageUrl, s.entityType),
            title: CustomText(
              s.title,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: (s.subtitle != null && s.subtitle!.isNotEmpty)
                ? CustomText(
                    s.subtitle!,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.north_west,
                size: 18, color: AppColors.secondaryTextColor),
            onTap: () => controller.submitSearch(s.title),
          );
        },
      );
    });
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
          _facetTabs(),
          _appliedFiltersChip(),
          Expanded(child: _resultsList()),
        ],
      );
    });
  }

  Widget _facetTabs() {
    return Obx(() {
      final facets = controller.facets;
      if (facets.isEmpty) return const SizedBox.shrink();
      final active = controller.activeType.value;
      // All tab + one per facet (sorted by descending count).
      final entries = facets.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          children: [
            _chip('All (${controller.total.value})', active == null,
                () => controller.selectType(null)),
            for (final e in entries)
              _chip('${_entityLabel(e.key)} (${e.value})', active == e.key,
                  () => controller.selectType(e.key)),
          ],
        ),
      );
    });
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
      return ListView.separated(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.greyE5),
        itemBuilder: (_, i) {
          if (i == items.length) {
            // Footer: loading spinner while paginating, else empty.
            return Obx(() => controller.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: 24));
          }
          return _resultTile(items[i]);
        },
      );
    });
  }

  Widget _resultTile(SearchResultItem item) {
    return ListTile(
      leading: _thumb(item.imageUrl, item.entityType),
      title: CustomText(
        item.title,
        fontSize: SizeConfig.medium,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.subtitle != null && item.subtitle!.isNotEmpty)
            CustomText(
              item.subtitle!,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              _typeBadge(item.entityType),
              if (item.city != null && item.city!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.secondaryTextColor),
                Flexible(
                  child: CustomText(
                    item.city!,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: (item.price != null)
          ? CustomText(
              '₹${SearchResponse.formatPrice(item.price)}',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            )
          : null,
      onTap: () => _openResult(item),
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
    const productTypes = {'product', 'variant', 'grocery_product'};
    if (productTypes.contains(item.entityType)) {
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
