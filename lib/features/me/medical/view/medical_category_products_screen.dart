import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_card_adapter.dart';
import 'package:BlueEra/features/me/medical/widget/medical_floating_cart.dart';
import 'package:BlueEra/features/me/medical/widget/medical_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Products under one pharmacy category — left sub-category rail, sub-sub
/// category tabs, 2-column product grid, floating cart. The pharmacy twin of
/// `VisitGroceryProductsScreen`.
///
/// **No fetching.** Grocery hits two endpoints here (nested-with-inventory for
/// the rail, then a paged products call per category). Neither has a medical
/// equivalent — but it doesn't need one: `medical-service/profile/home/{id}`
/// already returns the whole category tree with products at the leaves, so the
/// pharmacy detail screen hands that subtree straight in and every rail tap,
/// tab switch and search runs against memory. That also means no pagination and
/// no loading state.
class MedicalCategoryProductsScreen extends StatefulWidget {
  /// The tapped top-level category's name — app bar title fallback.
  final String title;

  /// The tapped category's children: one entry per left-rail row.
  final List<CategoryWithProducts> children;

  /// Business context for the cart, so ADD works from this screen.
  final MedicalCartBusiness businessCtx;

  const MedicalCategoryProductsScreen({
    super.key,
    required this.title,
    required this.children,
    required this.businessCtx,
  });

  @override
  State<MedicalCategoryProductsScreen> createState() =>
      _MedicalCategoryProductsScreenState();
}

class _MedicalCategoryProductsScreenState
    extends State<MedicalCategoryProductsScreen> {
  final _cart = getOrPut(() => MedicalCartController(), permanent: true);
  final _searchController = TextEditingController();

  /// Left-rail selection. Rx rather than plain state because
  /// [CommonGenericLeftSideCategoryList] wraps each row in its own `Obx` — a
  /// `setState` would not repaint the rail's selected styling.
  final _selectedIndex = 0.obs;

  /// Top-tab selection. 0 = "All" (everything under the selected rail
  /// category); N = that category's Nth child.
  final _selectedTabIndex = 0.obs;

  final _isSearchOpen = false.obs;
  final _query = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CategoryWithProducts? get _selectedCategory {
    if (widget.children.isEmpty) return null;
    final i = _selectedIndex.value.clamp(0, widget.children.length - 1);
    return widget.children[i];
  }

  /// Tabs: "All" plus the selected rail category's own children.
  List<CategoryWithProducts> get _tabCategories =>
      _selectedCategory?.children ?? const <CategoryWithProducts>[];

  /// Products for the current rail + tab selection, then filtered by the search
  /// query. Tab 0 collects the whole subtree; tab N narrows to that child.
  ///
  /// Note: grocery's equivalent re-requests the *parent* category id on every
  /// tab tap, so its tabs don't actually filter — deliberately not copied.
  List<CategoryProduct> get _visibleProducts {
    final category = _selectedCategory;
    if (category == null) return const <CategoryProduct>[];

    final tabs = _tabCategories;
    final tabIndex = _selectedTabIndex.value;
    final source = (tabIndex == 0 || tabIndex - 1 >= tabs.length)
        ? category
        : tabs[tabIndex - 1];

    final products = source.getAllProducts();
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) {
      final name = (p.name ?? '').toLowerCase();
      final brand = (p.brand ?? '').toLowerCase();
      final generic = (p.genericName ?? '').toLowerCase();
      return name.contains(q) || brand.contains(q) || generic.contains(q);
    }).toList();
  }

  /// Name of the active tab — used by the empty state.
  String get _currentTabName {
    final tabs = _tabCategories;
    final i = _selectedTabIndex.value;
    if (i == 0 || i - 1 >= tabs.length) {
      return _selectedCategory?.name ?? widget.title;
    }
    return tabs[i - 1].name ?? widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        // Don't return Expanded/Flexible here — CommonBackAppBar already wraps
        // the result in Flexible(Padding(Builder(...))), so an Expanded would
        // land inside Padding rather than the Row and throw
        // "Incorrect use of ParentDataWidget".
        isCustomTitleWidget: () => Obx(
          () => _isSearchOpen.value
              ? CommonSearchBar(
                  controller: _searchController,
                  isShowCursor: true,
                  onChange: (value) => _query.value = value,
                  onClearCallback: () {
                    _searchController.clear();
                    _query.value = '';
                  },
                  hintText: AppStrings.groceryViewSearchProductsHint.tr,
                )
              : CustomText(
                  _selectedCategory?.name ?? widget.title,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
        ),
        buildCustomActionWidget: () => Obx(
          () => InkWell(
            onTap: () {
              _isSearchOpen.value = !_isSearchOpen.value;
              if (!_isSearchOpen.value) {
                _searchController.clear();
                _query.value = '';
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Icon(
                _isSearchOpen.value
                    ? Icons.search_off_outlined
                    : Icons.search_outlined,
                color: AppColors.black,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (widget.children.isEmpty)
            Center(
              child: EmptyStateWidget(
                message: AppStrings.groceryViewNoXFound
                    .trParams({'name': widget.title}),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leftCategoryList(),
                Expanded(child: _rightContent()),
              ],
            ),
          // Same floating cart as the pharmacy detail screen — ADD from this
          // grid keeps the cart reachable without going back. Self-hides when
          // empty and carries its own SafeArea.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MedicalFloatingCart(controller: _cart),
          ),
        ],
      ),
    );
  }

  Widget _leftCategoryList() {
    return CommonGenericLeftSideCategoryList<CategoryWithProducts>(
      items: widget.children,
      // The API's category nodes carry no image, so every row falls back to the
      // section placeholder rather than showing a broken tile.
      getIcon: (_) => '',
      placeholderAssetPath: 'assets/category/medical/health_pharmacy.png',
      getLabel: (item) => item.name?.replaceAll('_', ' ') ?? '',
      isSelected: (item) => _selectedCategory?.sId == item.sId,
      onTap: (item, index) {
        if (_selectedIndex.value == index) return;
        _selectedIndex.value = index;
        // A new rail category has its own children — reset to "All" so the tab
        // index can't point at a sub-category that no longer exists.
        _selectedTabIndex.value = 0;
      },
    );
  }

  Widget _rightContent() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final tabs = _tabCategories;
            final labels = <String>[
              AppStrings.groceryViewAll.tr,
              ...tabs.map((c) => c.name?.replaceAll('_', ' ') ?? ''),
            ];
            // A leaf rail category has no children — one lone "All" tab is
            // noise, so drop the strip entirely.
            if (labels.length <= 1) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HorizontalTabSelector<String>(
                tabs: labels,
                selectedIndex:
                    _selectedTabIndex.value.clamp(0, labels.length - 1),
                labelBuilder: (label) => label,
                horizontalPadding: 8,
                verticalPadding: 6,
                verticalMargin: 0,
                horizontalMargin: 0,
                unSelectedBackgroundColor: AppColors.white,
                unSelectedBorderColor: AppColors.greyE5,
                onTabSelected: (index, _) => _selectedTabIndex.value = index,
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              final products = _visibleProducts;
              if (products.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(SizeConfig.size20),
                  child: EmptyStateWidget(
                    message: AppStrings.groceryViewNoXFound
                        .trParams({'name': _currentTabName}),
                  ),
                );
              }
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    // Clears the floating cart pinned over this grid.
                    padding: EdgeInsets.only(
                        bottom: SizeConfig.size15 + kBottomNavigationBarHeight),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childCount: products.length,
                      itemBuilder: (context, i) => MedicalProductCard(
                        product: products[i].toCardProduct(),
                        businessCtx: widget.businessCtx,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
