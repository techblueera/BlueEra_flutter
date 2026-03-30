import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AllProductStoreScreen extends StatefulWidget {
  final bool isShowInGrid;
  final ProviderType? providerType;
  final String? productCategoryName;
  final String? productCategory;

  const AllProductStoreScreen({
    super.key,
    required this.isShowInGrid,
    this.providerType,
    this.productCategoryName,
    this.productCategory,
  });

  @override
  State<AllProductStoreScreen> createState() => _AllProductStoreScreenState();
}

class _AllProductStoreScreenState extends State<AllProductStoreScreen> {
  final controller = getOrPut(() => DiscoverController());
  final ScrollController storesScrollController = ScrollController();
  ProviderType? _providerType;
  String? _productCategory;
  String? _productCategoryName;
  final List<OnboardingCategoryModel> _categories = businessProductsCategories;
  final RxInt _selectedIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _providerType = widget.providerType;

    // Use passed category or default to first
    if (widget.productCategory != null) {
      _productCategory = widget.productCategory;
      _productCategoryName = widget.productCategoryName;
      // Find matching index
      final idx = _categories.indexWhere((c) => c.slugId == _productCategory);
      if (idx >= 0) _selectedIndex.value = idx;
    } else {
      _productCategory = _categories.first.slugId;
      _productCategoryName = _categories.first.name;
    }

    controller.getAllProductNearBy(
      providerType: _providerType,
      productCategory: _productCategory,
    );

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
        productCategory: _productCategory,
        isLoadMore: true,
      );
    }
  }

  void _onCategoryTap(OnboardingCategoryModel item, int index) {
    _selectedIndex.value = index;
    _productCategory = item.slugId;
    _productCategoryName = item.name;
    controller.getAllProductNearBy(
      providerType: _providerType,
      productCategory: _productCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final idx = _selectedIndex.value;
          final name = (idx >= 0 && idx < _categories.length)
              ? _categories[idx].name
              : AppStrings.tab_product;
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
            Expanded(child: _buildProductContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: _categories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        final idx = _categories.indexOf(item);
        return _selectedIndex.value == idx;
      },
      onTap: _onCategoryTap,
    );
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
            message: _productCategoryName == null
                ? AppStrings.notFoundAnyProduct
                : 'No $_productCategoryName products found',
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
