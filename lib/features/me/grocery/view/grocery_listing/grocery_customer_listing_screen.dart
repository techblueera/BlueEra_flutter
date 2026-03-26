import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/common_cart_icon.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/me/grocery/widget/view_cart_footer.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/inner_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class GroceryCustomerListingScreen extends StatefulWidget {
  final List<GroceryNestedCategoryModel> arrGroceries;

  GroceryCustomerListingScreen(
      {super.key,
      required this.arrGroceries,
      });

  @override
  State<GroceryCustomerListingScreen> createState() => _GroceryCustomerListingScreenState();
}

class _GroceryCustomerListingScreenState extends State<GroceryCustomerListingScreen> {
  final controller = getOrPut(() => GrocerySelfPickupConsumerController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGroceryData.value = widget.arrGroceries.first;
      controller.fetchBoth();
    });
    super.initState();
  }

  void _onScrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !controller.isUserGroceryLoadingMore.value &&
        controller.userGroceryHasMore) {
      controller.fetchUserGroceries(
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: CommonBackAppBar(
              title: controller.selectedGroceryData.value?.name,
              isShadowShow: false,
              buildCustomActionWidget: () => const CommonCartIcon(
                  argIsDeliveredByRider: true
              ),
          ),
          bottomNavigationBar: ViewCartFooter(),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
              Expanded(
                  child: rightContent()
              ),
            ],
          ),
        ));
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

        // If same category already selected → DO NOTHING
        if (controller.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }

        controller.selectedGroceryData.value = selected;
        controller.selectedTabIndex.value = 0;

        log('new selection ${controller.selectedGroceryData.value}');
        controller.fetchBoth();
      },
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: EdgeInsets.all(8),
          child: controller.isInitialLoading.value
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // // Max Limit Error
                    // if (controller.isMaxLimitHit)
                    //   Container(
                    //     width: SizeConfig.screenWidth,
                    //     decoration: BoxDecoration(
                    //         color: AppColors.redBE,
                    //         borderRadius: BorderRadius.circular(10.0)
                    //     ),
                    //     margin: EdgeInsets.only(bottom: SizeConfig.size10),
                    //     padding: EdgeInsets.symmetric(
                    //         vertical: SizeConfig.size4,
                    //         horizontal: SizeConfig.size10
                    //     ),
                    //     child: FittedBox(
                    //       fit: BoxFit.scaleDown,
                    //       child: Row(
                    //         children: [
                    //           LocalAssets(
                    //               imagePath: AppIconAssets.warningOutlineIcon,
                    //               width: SizeConfig.size20,
                    //               height: SizeConfig.size20
                    //           ),
                    //           SizedBox(width: SizeConfig.size8),
                    //           CustomText(
                    //             'You can’t select more than ${controller.maxLimit} products at a time.',
                    //             color: AppColors.redLite,
                    //             fontSize: SizeConfig.extraSmall,
                    //             fontWeight: FontWeight.w400,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),

                    // TABS

                    if(controller.arrChildrenOfGroceryWithInventoryCategory.isNotEmpty)
                    ...[
                      SizedBox(
                        height: 28,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.arrChildrenOfGroceryWithInventoryCategory.length + 1,
                          itemBuilder: (_, i) {
                            bool selected =
                                controller.selectedTabIndex.value == i;

                            var item;
                            if (i != 0) {
                              item =
                              controller.arrChildrenOfGroceryWithInventoryCategory[i - 1];
                            }

                            return InkWell(
                              onTap: () {
                                controller.selectedTabIndex.value = i;
                                controller.fetchUserGroceries();
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: i == 0 ? 0 : 3,
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryColor
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: selected
                                      ? null
                                      : Border.all(
                                      color: AppColors.greyLite, width: 0.5),
                                ),
                                child: Center(
                                  child: CustomText(
                                    (i != 0) ? item.name : 'All',
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 8),
                    ],

                    // GRID
                    Expanded(
                        child: controller.isUserGroceryLoading.value
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(SizeConfig.size20),
                                  child: SizedBox(
                                      height: SizeConfig.size30,
                                      width: SizeConfig.size30,
                                      child: CircularProgressIndicator()),
                                ),
                              )
                            : controller.arrUserGrocery.isNotEmpty
                                ? MasonryGridView.count(
                          controller: scrollController,
                          itemCount:
                          controller.arrUserGrocery.length +
                              (controller.isUserGroceryLoadingMore
                                  .value
                                  ? 1
                                  : 0),
                          crossAxisCount: 2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          padding: EdgeInsets.only(
                              bottom: SizeConfig.size30),
                          itemBuilder: (_, i) {
                            if (i ==
                                controller.arrUserGrocery.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              );
                            }

                            return groceryCard(
                                controller.arrUserGrocery[i]);
                          },
                        )
                                : Padding(
                                    padding: EdgeInsets.all(SizeConfig.size20),
                                    child: EmptyStateWidget(
                                        message:
                                        'No ${controller.currentTabName.tr} found.')
                        )
                    )
                  ],
                ),
        ));
  }

  Widget groceryCard(GroceryProductData groceryProductData) {
    // final price = groceryController
    //     .getPriceDetails(groceryProductData.variants?[0].pricing);
    // print("Selling Range: ${price.sellingRange}");
    // print("MRP Range: ${price.mrpRange}");
    // print("Discount Range: ${price.discountRange}");
    // final sellingPrice = price.sellingRange;
    // final mrp = price.mrpRange;
    // final discount = price.discountRange;


    final sellingPrice = "₹${groceryProductData.variants?[0].pricing?[0].sellingPrice}";
    final mrp = "₹${groceryProductData.variants?[0].pricing?[0].mrp}";
    final discount = '${calculateDiscount(
      sellingPrice,
      mrp,
    ).toInt()}% ${AppStrings.offCaps.tr}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  height: SizeConfig.size140,
                  width: double.infinity,
                  child: (groceryProductData.images?.isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: groceryProductData.images!.first.url ?? '',
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
              Positioned(
                top: 0,
                right: 0,
                child: Obx(() {
                  final bool isAdded =
                      groceryProductData.variants?.any((variant) =>
                          controller.selectedGroceriesVariants
                              .any((selected) => selected.sId == variant.sId)
                      ) ?? false;
                  log('isAdded-- $isAdded');

                  return IconButton(
                    onPressed:
                    // isAdded
                    //     ? null // disable if already added
                    //     :
                        () {
                      if (groceryProductData.variants == null ||
                          groceryProductData.variants!.isEmpty) {
                        commonSnackBar(message: 'No variants available');
                        return;
                      }

                      showProductVariantsBottomSheet(
                        context,
                        productImage: (groceryProductData.images?.isNotEmpty??false)
                            ? groceryProductData.images!.first.url ?? ''
                            : '',
                        allVariants: groceryProductData.variants!,
                        onAdd: (variant) {
                          controller.addToCart(
                              variant,
                              productId: variant.sId, inventoryId: groceryProductData.sId);
                        },
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isAdded
                            ? AppColors.greenShade
                            : AppColors.blackMite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        !isAdded ? Icons.add : Icons.check,
                        size: SizeConfig.size16,
                        color: AppColors.white,
                      ),
                    ),
                  );
                }),
              )

            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size28,
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
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      child: CustomText(
                        '${groceryProductData.variants?[0].quantity}',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: sellingPrice,
                  mrp: mrp,
                  discount: discount,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showProductVariantsBottomSheet(
    BuildContext context, {
    required String productImage,
    required List<ProductVariants> allVariants,
    required Function(ProductVariants variant) onAdd,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.whiteF1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),
                _header(context),

                const SizedBox(height: 12),

                /// Variants list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allVariants.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: SizeConfig.size10),
                  itemBuilder: (_, index) {
                    final variant = allVariants[index];

                    return _variantItem(
                      variant: variant,
                      productImage: productImage,
                      onAdd: () {
                        onAdd(variant);
                        // Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _variantItem({
    required ProductVariants variant,
    required String productImage,
    required VoidCallback onAdd,
  }) {
    // final price = groceryController.getPriceDetails(variant.pricing);

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          /// Product Image
          (productImage.isNotEmpty)
              ? CustomImageSlideshow(
            isLoading: false,
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            imagePaths: [productImage],
            borderRadius: BorderRadius.circular(6),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.fill,
              width: SizeConfig.size50,
              height: SizeConfig.size50,
            ),
          ),

          // /// Variant Image
          // (variant.images != null && variant.images!.isNotEmpty)
          //     ? CustomImageSlideshow(
          //         isLoading: false,
          //         width: SizeConfig.size50,
          //         height: SizeConfig.size50,
          //         imagePaths: variant.images!.map((i) => i.url ?? '').toList(),
          //         borderRadius: BorderRadius.circular(6),
          //       )
          //     : ClipRRect(
          //         borderRadius: BorderRadius.circular(6),
          //         child: LocalAssets(
          //           imagePath: AppIconAssets.place_holder_image,
          //           boxFix: BoxFit.fill,
          //           width: SizeConfig.size50,
          //           height: SizeConfig.size50,
          //         ),
          //       ),


          SizedBox(width: SizeConfig.size10),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4),
                Row(
                    children: [
                      CustomText(
                          '${variant.quantity}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        width: 0.5,
                        height: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                          '₹${variant.pricing?[0].sellingPrice}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                          '₹${variant.pricing?[0].mrp}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                    ]
                )
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Dashed Border Container
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(
              height: SizeConfig.size50,
              width: 1,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Add Button
          Obx(() {
            final bool isAdded = controller.selectedGroceriesVariants
                .any((v) => v.sId == variant.sId);

            return ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: InnerShadow(
                shadows: [
                  BoxShadow(
                    blurRadius: 20.0,
                    color: AppColors.blue52,
                  )
                ],
                child: CustomBtn(
                  width: SizeConfig.size70,
                  height: SizeConfig.size30,
                  title: isAdded ? 'ADDED' : 'ADD',
                  onTap: isAdded ? null : onAdd,
                  textColor: AppColors.primaryColor,
                  borderColor: AppColors.primaryColor,
                  bgColor: Colors.transparent,
                  radius: 10,
                ),
              ),
            );
          })


          // Obx(() {
          //   final bool isAdded = controller.selectedGroceriesVariants
          //       .any((v) => v.sId == variant.sId);
          //
          //   return AddToCartButton(
          //     isAdded: isAdded,
          //     onAdd: onAdd,
          //   );
          // })

        ],
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          const Expanded(
            child: CustomText(
              "All Variants",
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}
