import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_product_card.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class GroceryProductsScreen extends StatefulWidget {
  final String userId;
  final List<GroceryNestedCategoryModel> arrGroceries;

  GroceryProductsScreen({
    super.key,
    required this.userId,
    required this.arrGroceries,
  });

  @override
  State<GroceryProductsScreen> createState() => _GroceryProductsScreenState();
}

class _GroceryProductsScreenState extends State<GroceryProductsScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  late String _userId;

  @override
  void initState() {
    scrollController.addListener(_onScrollListener);
    _userId = widget.userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGroceryData.value = widget.arrGroceries.first;
      getGroceryProducts();
    });
    super.initState();
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isGroceryDataLoadingMore.value &&
        controller.groceryDataHasMore) {
      getGroceryProducts(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  void getGroceryProducts({bool isLoadMore = false}) {
    final String categoryId = controller.selectedGroceryData.value?.sId ?? '';

    controller.fetchGroceryProducts(
      userId: _userId,
      categoryId: categoryId,
      isLoadMore: isLoadMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        isCustomTitleWidget: ()=> Obx(() {
          final bool isOpen = controller.isSearchOpen.value;

          return Expanded(
            child: isOpen
                ? CommonSearchBar(
              controller: searchController,
              isShowCursor: true,
              // onSearchTap: () => controller.fetchGroceryProducts(),
              onClearCallback: () {
                searchController.clear();
                // controller.fetchGroceryProducts();
              },
              hintText: "Search products...",
            )
                : CustomText(
              controller.selectedGroceryData.value?.name ?? "Products",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        buildCustomActionWidget: ()=> Obx(() {
          final bool isOpen = controller.isSearchOpen.value;

            // The Toggle Button is now part of the Title Widget
            return InkWell(
                onTap: () {
                  controller.isSearchOpen.value = !isOpen;
                  if (!controller.isSearchOpen.value) {
                    searchController.clear();
                    // controller.fetchGroceryProducts();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Icon(
                    isOpen ? Icons.search_off_outlined : Icons.search_outlined,
                    color: AppColors.black,
                    size: 24,
                  ),
                ),
              );
          }),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCategoryList(),
          Expanded(
              child: rightContent()
          ),
        ],
      ),
    );
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: widget.arrGroceries,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
      controller.selectedGroceryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrGroceries[index];
        if (controller.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }
        controller.selectedGroceryData.value = selected;
        getGroceryProducts();
      },
    );
  }

  Widget rightContent() {
    return Obx(()=> Padding(
      padding: const EdgeInsets.all(4),
      child: controller.isGroceryDataFirstLoading.value
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: SizedBox(
              height: 20.0,
              width: 20.0,
              child: CircularProgressIndicator()
          ),
        ),
      )
          : controller.groceryProductsList.isNotEmpty
          ?
      ListView.builder(
          itemCount: controller.groceryProductsList.length +
              (controller.isGroceryDataLoadingMore.value ? 1 : 0),
          controller: scrollController,
          padding: EdgeInsets.only(
              bottom: SizeConfig.size15 + kBottomNavigationBarHeight
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index >= controller.groceryProductsList.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final groceryProducts = controller.groceryProductsList[index];

            return  GroceryProductCard(
                groceryProducts: groceryProducts,
            );
          },
        )


    //   MasonryGridView.count(
    //   controller: scrollController,
    //   itemCount: controller.groceryProductsList.length +
    //       (controller.isGroceryDataLoadingMore.value ? 1 : 0),
    //   crossAxisCount: 2,
    //   crossAxisSpacing: 10,
    //   mainAxisSpacing: 10,
    //   padding: EdgeInsets.only(bottom: SizeConfig.size30),
    //   itemBuilder: (_, i) {
    //     if (i == controller.groceryProductsList.length) {
    //       return const Center(
    //         child: Padding(
    //           padding: EdgeInsets.all(8.0),
    //           child: CircularProgressIndicator(strokeWidth: 2),
    //         ),
    //       );
    //     }
    //
    //     return GroceryProductCard(
    //         groceryProducts: controller.groceryProductsList[i]
    //     );
    //   },
    // )

            : Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: EmptyStateWidget(
              message:
              'No ${controller.currentTabName.tr} found.')
      ),
    ));
  }

  Widget groceryCard(GroceryProductData groceryProductData) {
    final bool isSelected = controller.selectedGroceries.contains(groceryProductData);
    final price = controller.getPriceDetails(groceryProductData.variants?[0].pricing);
    // print("Selling Range: ${price.sellingRange}");
    // print("MRP Range: ${price.mrpRange}");
    // print("Discount Range: ${price.discountRange}");

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: EdgeInsets.only(top: 4.0),
              height: SizeConfig.size140,
              width: double.infinity,
              child: (groceryProductData.images?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                imageUrl: groceryProductData.images!.first.url??'',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              )
                  : LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size30,
                  child: CustomText(
                    "${groceryProductData.name}",
                    fontSize: SizeConfig.small,
                    maxLines: 2,
                    color: AppColors.mainTextColor,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border:
                          Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                          Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: CustomText(
                        '${groceryProductData.variants?[0].quantity}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.price.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.sellingRange}",
                            fontSize: 10,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.mrp.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.mrpRange}",
                            fontSize: 10,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.discount.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.discountRange}",
                            fontSize: 10,
                            color: AppColors.green00,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CustomBtn(
                      height: SizeConfig.size36,
                      onTap: () => controller.toggleSelection(groceryProductData),
                      title: isSelected ? 'Added' : 'Add',
                      textColor: isSelected ? AppColors.white : AppColors.primaryColor,
                      bgColor: isSelected ? AppColors.primaryColor : AppColors.white,
                      radius: 6.0,
                      borderColor: AppColors.primaryColor,
                    )
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }

}



