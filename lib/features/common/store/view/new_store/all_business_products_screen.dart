import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/models/product_consumer_nested_category_response.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllBusinessProductsScreen extends StatefulWidget {
  final String? productCategoryName;
  final String? productCategory;
  final bool isShowInGrid;

  const AllBusinessProductsScreen({
    super.key,
    this.productCategoryName,
    this.productCategory,
    this.isShowInGrid = true,
  });

  @override
  State<AllBusinessProductsScreen> createState() => _AllBusinessProductsScreenState();
}

class _AllBusinessProductsScreenState extends State<AllBusinessProductsScreen> {
  final controller = getOrPut(() => DiscoverController());
  final storeController = getOrPut(() => NewStoreController());
  final AuthController _authController = Get.find<AuthController>();
  final ScrollController storesScrollController = ScrollController();
  final ProviderType _providerType = ProviderType.business;

  /// The currently active top-level product category (tagId + name),
  /// mutable so the header dropdown can switch it at runtime.
  String? _currentCategoryTagId;
  String? _currentCategoryName;

  /// Selected level-1 category (left sidebar)
  final Rxn<ProductNestedCategory> _selectedCategory = Rxn<ProductNestedCategory>();

  /// Selected level-2 child (horizontal tab)
  final Rxn<ProductNestedCategory> _selectedChild = Rxn<ProductNestedCategory>();

  List<CategoryData> get _allProductCategories =>
      _authController.businessOnboardingProductsCategories;

  @override
  void initState() {
    super.initState();

    _currentCategoryTagId = widget.productCategory;
    _currentCategoryName = widget.productCategoryName;
    _loadTree();

    storesScrollController.addListener(_onLoadMore);
  }

  /// Fetch the category tree for the currently active top-level category
  /// and auto-select the first sidebar entry when it arrives.
  void _loadTree() {
    final tagId = _currentCategoryTagId;
    if (tagId == null || tagId.isEmpty) return;
    storeController.fetchProductCategoryTree(group: tagId).then((_) {
      if (!mounted) return;
      final list = storeController.productCategoryTreeList;
      if (list.isNotEmpty) {
        _selectCategory(list.first);
      }
    });
  }

  /// Switch the top-level category from the header dropdown — resets the
  /// sidebar/tab selection, refetches the tree, and re-loads products.
  void _changeMainCategory(CategoryData category) {
    if (category.tagId == null || category.tagId == _currentCategoryTagId) return;
    setState(() {
      _currentCategoryTagId = category.tagId;
      _currentCategoryName = category.name;
      _selectedCategory.value = null;
      _selectedChild.value = null;
    });
    _loadTree();
  }

  @override
  void dispose() {
    storesScrollController.removeListener(_onLoadMore);
    storesScrollController.dispose();
    super.dispose();
  }

  /// Select a level-1 category, auto-select its first child, and fetch products
  void _selectCategory(ProductNestedCategory category) {
    _selectedCategory.value = category;

    if (category.children != null && category.children!.isNotEmpty) {
      _selectedChild.value = category.children!.first;
      _fetchProducts(category.children!.first.key ?? category.key);
    } else {
      _selectedChild.value = null;
      _fetchProducts(category.key);
    }
  }

  /// Select a level-2 child tab and fetch products
  void _selectChild(ProductNestedCategory child) {
    _selectedChild.value = child;
    _fetchProducts(child.key);
  }

  void _fetchProducts(String? productCategory) {
    controller.getAllProductNearBy(
      providerType: _providerType,
      productCategory: productCategory,
    );
  }

  void _onLoadMore() {
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      final key = _selectedChild.value?.key ??
          _selectedCategory.value?.key;
      controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: key,
        isLoadMore: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => _buildTitleDropdown(),
        buildCustomActionWidget: () {
          final chat = ChatViewController.inventoryAiChatListSearchModule;
          return IconButton(
            onPressed: () {
              Get.to(() => AiCommonSearchScreen(
                chatType: AppConstants.askInventory_Chat_Type,
                profileImage: chat?.sender?.profileImage,
                name: chat?.sender?.name,
                contactNo: chat?.sender?.contactNo,
                conversationId: '',
                userId: '',
                businessId: '',
                type: chat?.sender?.accountType,
                isInitialMessage: false,
              ));
            },
            icon: Icon(
              Icons.auto_awesome,
              color: AppColors.primaryColor,
              size: SizeConfig.size24,
            ),
          );
        },
      ),
      body: SafeArea(
        child: Obx(() {
          if (storeController.isProductCategoryTreeLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryList(),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                child: Column(
                  children: [
                    _buildChildTabs(),
                    Expanded(child: _buildProductContent()),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// App-bar title rendered as a popup menu — tapping opens the full list
  /// of top-level product categories (with icons) so the user can switch
  /// without going back.
  Widget _buildTitleDropdown() {
    final name = _currentCategoryName ?? AppStrings.tab_product;
    final categories = _allProductCategories;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: AppColors.mainTextColor,
        ),
      ],
    );

    if (categories.isEmpty) return label;

    return PopupMenuButton<CategoryData>(
      tooltip: '',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: _changeMainCategory,
      itemBuilder: (ctx) => categories.map((c) {
        final isActive = c.tagId == _currentCategoryTagId;
        return PopupMenuItem<CategoryData>(
          value: c,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: _buildCategoryMenuIcon(c.imageUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.name ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primaryColor
                        : AppColors.mainTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Icon(Icons.check,
                    size: 16, color: AppColors.primaryColor),
            ],
          ),
        );
      }).toList(),
      child: label,
    );
  }

  Widget _buildCategoryMenuIcon(String? url) {
    if (url == null || url.isEmpty) {
      return Image.asset(
        AppIconAssets.place_holder_image,
        fit: BoxFit.contain,
      );
    }
    if (isNetworkImage(url)) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => Image.asset(
          AppIconAssets.place_holder_image,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(url, fit: BoxFit.contain);
  }

  /// Left sidebar: level-1 categories from API tree
  Widget _buildCategoryList() {
    return Obx(() {
      final list = storeController.productCategoryTreeList;
      if (list.isEmpty) return const SizedBox.shrink();

      return CommonGenericLeftSideCategoryList<ProductNestedCategory>(
        items: list,
        getLabel: (item) => item.name ?? '',
        getIcon: (item) => '',
        isSelected: (item) => _selectedCategory.value?.sId == item.sId,
        onTap: (item, index) => _selectCategory(item),
      );
    });
  }

  /// Horizontal tabs: level-2 children of the selected category
  Widget _buildChildTabs() {
    return Obx(() {
      final children = _selectedCategory.value?.children ?? [];
      if (children.isEmpty) return const SizedBox.shrink();

      final selected = _selectedChild.value;
      final selectedIdx = selected == null
          ? 0
          : children.indexWhere((c) => c.sId == selected.sId);

      return Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.size8,
          right: SizeConfig.size8,
        ),
        child: HorizontalTabSelector<ProductNestedCategory>(
          tabs: children,
          selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
          labelBuilder: (item) => item.name ?? '',
          horizontalPadding: 8,
          verticalPadding: 6,
          verticalMargin: 0,
          horizontalMargin: 0,
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.greyE5,
          onTabSelected: (index, label) => _selectChild(children[index]),
        ),
      );
    });
  }

  /// Two-column grid that pushes an odd-count last item to the right cell.
  Widget _buildTwoColumnGrid(List<GetProductData> products) {
    final rowCount = (products.length / 2).ceil();
    final hasLoadMore = controller.isProductDataLoadingMore.value;
    final totalItems = rowCount + (hasLoadMore ? 1 : 0);

    return ListView.builder(
      controller: storesScrollController,
      padding: EdgeInsets.only(
        right: SizeConfig.paddingXS,
        bottom: SizeConfig.paddingL,
      ),
      itemCount: totalItems,
      itemBuilder: (context, rowIdx) {
        if (rowIdx >= rowCount) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final leftIdx = rowIdx * 2;
        final rightIdx = leftIdx + 1;
        final Widget leftCell = StoreProductCard(
          productStore: products[leftIdx].product,
          isShowInGrid: true,
        );
        final Widget rightCell = rightIdx < products.length
            ? StoreProductCard(
                productStore: products[rightIdx].product,
                isShowInGrid: true,
              )
            : const SizedBox.shrink();
        // IntrinsicHeight + CrossAxisAlignment.stretch lets both cards in
        // the row share the taller card's height. The taller card is
        // whichever has the 2-line name, so a 1-line-name card next to a
        // 2-line-name card expands its content area to match — the 8px
        // row gap stays the same and the shorter card just shows
        // whitespace below the name.
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: leftCell),
                const SizedBox(width: 8),
                Expanded(child: rightCell),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductContent() {
    return Obx(() {
      if (controller.isProductDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final productList = controller.productDataList
          .where((d) => d.product.details != null)
          .toList();

      if (productList.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: 'No ${_selectedChild.value?.name ?? _selectedCategory.value?.name ?? ''} products found',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product count chip
          // Padding(
          //   padding: EdgeInsets.only(
          //     top: SizeConfig.paddingS,
          //     right: SizeConfig.paddingXS,
          //     bottom: SizeConfig.size6,
          //   ),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: AppColors.white,
          //       borderRadius: BorderRadius.circular(20),
          //       border: Border.all(color: AppColors.greyE5, width: 0.5),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.inventory_2_outlined,
          //             size: 14, color: AppColors.primaryColor),
          //         const SizedBox(width: 6),
          //         CustomText(
          //           "${productList.length}${controller.isProductDataLoadingMore.value ? '+' : ''} Products",
          //           fontSize: 11,
          //           fontWeight: FontWeight.w600,
          //           color: AppColors.mainTextColor,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // Product grid/list

          SizedBox(height: SizeConfig.size8),

          Expanded(
            child: widget.isShowInGrid
                ? _buildTwoColumnGrid(productList)
                : ListView.builder(
                    controller: storesScrollController,
                    padding: EdgeInsets.only(
                      right: SizeConfig.paddingXS,
                      bottom: SizeConfig.paddingL,
                    ),
                    itemCount: productList.length +
                        (controller.isProductDataLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= productList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size10),
                        child: StoreProductCard(
                          productStore: productList[index].product,
                          isShowInGrid: widget.isShowInGrid,
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}
