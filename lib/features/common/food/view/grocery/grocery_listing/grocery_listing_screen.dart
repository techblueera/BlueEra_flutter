import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/user_grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
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
import 'package:get/get.dart';

class GroceryListingScreen extends StatefulWidget {
  final List<CollapsibleGridModel> arrGroceries;
  final CollapsibleGridModel selectedGroceryData;

  GroceryListingScreen(
      {super.key,
      required this.arrGroceries,
      required this.selectedGroceryData});

  @override
  State<GroceryListingScreen> createState() => _GroceryListingScreenState();
}

class _GroceryListingScreenState extends State<GroceryListingScreen> {
  final controller = getOrPut(() => UserGroceryController());
  // final groceryController = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGroceryData.value = widget.selectedGroceryData;
      controller.fetchUserGrocery();
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
              title: controller.selectedGroceryData.value.label,
              isShadowShow: false,
              buildCustomWidget: () => Obx(()=> controller
                  .selectedGroceriesVariants.isEmpty
                  ? Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Icon(Icons.search),
              )
                  : InkWell(
                onTap: () =>
                    Get.toNamed(RouteHelper.getGroceryCartScreenRoute()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Stack(
                      clipBehavior: Clip.none,
                    children: [
                    LocalAssets(
                      imagePath: AppIconAssets.cartIcon,
                    ),
                    Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          height: SizeConfig.size16,
                          width: SizeConfig.size16,
                          decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: CustomText(
                            '${controller.selectedGroceriesVariants.length}',
                            color: AppColors.white,
                          ),
                        ))
                  ]),
                ),
              ))),
          bottomNavigationBar: Obx(() {
            if (controller.selectedGroceriesVariants.isEmpty)
              return SizedBox();
            else
              return Material(
                elevation: 8.0,
                child: Container(
                  color: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size15,
                        vertical: SizeConfig.size15),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              onTap: null,
                              isValidate: false,
                              radius: SizeConfig.size10,
                              title: '₹${controller.totalSellingPrice.toStringAsFixed(2)}, ${controller.selectedGroceriesVariants.length} Products',
                              // isLoading: authController.isAddBusinessUserLoading.value
                              borderColor: AppColors.primaryColor,
                              textColor: AppColors.primaryColor,
                              bgColor: AppColors.white,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          CustomBtn(
                            onTap: () {
                              Get.toNamed(RouteHelper.getGroceryCartScreenRoute());
                            },
                            isValidate: true,
                            radius: SizeConfig.size10,
                            title: 'View Cart',
                            width: SizeConfig.size100,
                            // isLoading: authController.isAddBusinessUserLoading.value
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
          }),
          body: Row(
            children: [
              leftCategoryList(),
              Expanded(child: rightContent()),
            ],
          ),
        ));
  }

  Widget leftCategoryList() {
    return Container(
      width: 94,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: widget.arrGroceries.length,
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        itemBuilder: (context, index) {
          return Obx(() => _categoryItem(
                widget.arrGroceries[index].icon,
                widget.arrGroceries[index].label,
                selected: controller.selectedGroceryData.value.tagId ==
                    widget.arrGroceries[index].tagId,
            onTap: () {
              final selected = widget.arrGroceries[index];

              // If same category already selected → DO NOTHING
              if (controller.selectedGroceryData.value.tagId == selected.tagId) {
                return;
              }

              controller.selectedGroceryData.value = selected;
              controller.selectedTabIndex.value = 0;

              log('new selection ${controller.selectedGroceryData.value}');
              controller.fetchUserGrocery();
            },

          ));
        },
      ),
    );
  }

  Widget _categoryItem(String icon, String label,
      {bool selected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 11 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.skyBlueE4,
                AppColors.skyBlueE4.withValues(alpha: 0.3),
              ],
            ),
            border: selected
                ? const Border(
                    left: BorderSide(
                        color: AppColors.primaryColor,
                        width: 3,
                        style: BorderStyle.solid))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? null : AppColors.skyBlueE4),
                  padding: EdgeInsets.all(selected ? 0 : 6),
                  child: LocalAssets(
                    imagePath: icon,
                    // boxFix: BoxFit.cover,
                    height: 40,
                    width: 40,
                  )),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.black : AppColors.grayText,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
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
                    SizedBox(
                      height: 28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.arrChildrenOfGroceryCategory.length + 1,
                        itemBuilder: (_, i) {
                          bool selected =
                              controller.selectedTabIndex.value == i;

                          var item;
                          if (i != 0) {
                            item =
                                controller.arrChildrenOfGroceryCategory[i - 1];
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
                                ? Builder(
                                  builder: (context) {
                                    double screenWidth = Get.width;
                                    double totalHorizontalPadding = 8.0;
                                    double crossAxisSpacing = 10.0;
                                    double gridItemWidth = (screenWidth - totalHorizontalPadding - crossAxisSpacing) / 2;
                                    double desiredItemHeight = 350.0;

                                    return GridView.builder(
                                        controller: scrollController,
                                        itemCount:
                                            controller.arrUserGrocery.length +
                                                (controller.isUserGroceryLoadingMore
                                                        .value
                                                    ? 1
                                                    : 0),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                              childAspectRatio: gridItemWidth / desiredItemHeight,
                                        ),
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
                                      );
                                  }
                                )
                                : Padding(
                                    padding: EdgeInsets.all(SizeConfig.size20),
                                    child: EmptyStateWidget(
                                        message:
                                            'No ${controller.selectedGroceryData.value.label} found.'))
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
                        allVariants: groceryProductData.variants!,
                        onAdd: (variant) {
                          controller.addToCart(variant);
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
                CustomText(
                  "${groceryProductData.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
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
                        '${groceryProductData.variants?[0].weight?.toInt()} ${groceryProductData.variants?[0].unit}',
                        fontSize: 11,
                        color: Colors.grey,
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
                            sellingPrice,
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
                            mrp,
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
                            discount,
                            fontSize: 10,
                            color: AppColors.green00,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
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
    required List<VariantsData> allVariants,
    required Function(VariantsData variant) onAdd,
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
    required VariantsData variant,
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
          /// Variant Image
          (variant.images != null && variant.images!.isNotEmpty)
              ? CustomImageSlideshow(
                  isLoading: false,
                  width: SizeConfig.size50,
                  height: SizeConfig.size50,
                  imagePaths: variant.images!.map((i) => i.url ?? '').toList(),
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

          // ClipRRect(
          //   borderRadius: BorderRadius.circular(6),
          //   child: CachedNetworkImage(
          //     imageUrl: variant.images?.first.url ?? '',
          //     width: SizeConfig.size50,
          //     height: SizeConfig.size50,
          //     fit: BoxFit.cover,
          //     errorWidget: (_, __, ___) =>
          //         LocalAssets(imagePath: AppIconAssets.place_holder_image),
          //   ),
          // ),

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
                          '${variant.weight} ${variant.unit}',
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
          }),
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
