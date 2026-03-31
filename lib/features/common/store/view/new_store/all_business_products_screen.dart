import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/models/product_nested_category_response.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  final ScrollController storesScrollController = ScrollController();
  late ProviderType _providerType;
  final RxnString _productCategory = RxnString();

  List<CategoryData> get _categories => Get.find<AuthController>().businessOnboardingProductsCategories;

  @override
  void initState() {
    super.initState();
    _providerType = ProviderType.business;

    _productCategory.value = widget.productCategory ??
        (_categories.isNotEmpty ? _categories.first.tagId : null);

    storeController.selectedProductSubCategory.value = null;
    _fetchSubCategoriesAndProducts();

    storesScrollController.addListener(_onLoadMore);
  }

  @override
  void dispose() {
    storesScrollController.removeListener(_onLoadMore);
    storesScrollController.dispose();
    super.dispose();
  }

  void _onLoadMore() {
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: storeController.selectedProductSubCategory.value?.key ?? _productCategory.value,
        isLoadMore: true,
      );
    }
  }

  void _fetchSubCategoriesAndProducts() {
    if (_productCategory.value == null) return;
    storeController.fetchProductCategoryTree(group: _productCategory.value!).then((_) {
      if (storeController.productCategoryTreeList.isNotEmpty) {
        storeController.selectedProductSubCategory.value =
            storeController.productCategoryTreeList.first;
        controller.getAllProductNearBy(
          providerType: _providerType,
          productCategory: storeController.productCategoryTreeList.first.key,
        );
      } else {
        controller.getAllProductNearBy(
          providerType: _providerType,
          productCategory: _productCategory.value,
        );
      }
    });
  }

  void _onCategoryTap(CategoryData item, int index) {
    _productCategory.value = item.tagId;
    storeController.selectedProductSubCategory.value = null;
    _fetchSubCategoriesAndProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final match = _categories.firstWhereOrNull((c) => c.tagId == _productCategory.value);
          final name = match?.name ?? AppStrings.tab_product;
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryList(),
            SizedBox(width: SizeConfig.size6),
            Expanded(
              child: Column(
                children: [
                  _buildSubCategoryTabs(),
                  Expanded(child: _buildProductContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<CategoryData>(
      items: _categories,
      getLabel: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      isSelected: (item) => _productCategory.value == item.tagId,
      onTap: _onCategoryTap,
    );
  }

  Widget _buildSubCategoryTabs() {
    return Obx(() {
      if (storeController.isProductCategoryTreeLoading.value) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: const SizedBox(
            height: 30,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      }

      if (storeController.productCategoryTreeList.isEmpty) {
        return const SizedBox.shrink();
      }

      final selected = storeController.selectedProductSubCategory.value;
      final selectedIdx = selected == null
          ? 0
          : storeController.productCategoryTreeList
                .indexWhere((c) => c.sId == selected.sId);

      return Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.size8,
          right: SizeConfig.size8,
        ),
        child: HorizontalTabSelector<ProductNestedCategory>(
          tabs: storeController.productCategoryTreeList,
          selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
          labelBuilder: (item) => item.name ?? '',
          horizontalPadding: 8,
          verticalPadding: 6,
          verticalMargin: 0,
          horizontalMargin: 0,
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.greyE5,
          onTabSelected: (index, label) {
            final subCategory = storeController.productCategoryTreeList[index];
            storeController.selectedProductSubCategory.value = subCategory;
            controller.getAllProductNearBy(
              providerType: _providerType,
              productCategory: subCategory.key ?? _productCategory.value,
            );
          },
        ),
      );
    });
  }

  Widget _buildProductContent() {
    return Obx(() {
      if (controller.isProductDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final productList = List<GetProductData>.from(controller.productDataList);

      if (productList.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: 'No ${_categories.firstWhereOrNull((c) => c.tagId == _productCategory.value)?.name ?? ''} products found',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store count chip
          Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.paddingS,
              right: SizeConfig.paddingXS,
              bottom: SizeConfig.size6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greyE5, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  CustomText(
                    "${productList.length}${controller.isProductDataLoadingMore.value ? '+' : ''} Products",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),

          // Product grid/list
          Expanded(
            child: widget.isShowInGrid
                ? MasonryGridView.count(
                    controller: storesScrollController,
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                      return StoreProductCard(
                        productStore: productList[index].product,
                        isShowInGrid: widget.isShowInGrid,
                      );
                    },
                  )
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
