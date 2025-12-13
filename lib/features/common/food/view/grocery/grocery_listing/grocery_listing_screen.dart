import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/inner_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryListingScreen extends StatefulWidget {
  final List<CollapsibleGridModel> arrGroceries;
  final CollapsibleGridModel selectedGroceryData;

  GroceryListingScreen({
    super.key,
    required this.arrGroceries,
    required this.selectedGroceryData
  });

  @override
  State<GroceryListingScreen> createState() => _GroceryListingScreenState();
}

class _GroceryListingScreenState extends State<GroceryListingScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();
  late CollapsibleGridModel selectedGroceryData;

  @override
  void initState() {
    selectedGroceryData = widget.selectedGroceryData;
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGrocery.value = selectedGroceryData.tagId;
      controller.fetchBoth();
    });
    super.initState();
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isGroceryCategoryProductsLoadingMore.value &&
        controller.groceryCategoryProductsHasMore) {
      controller.fetchGroceryCategoryProducts(
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
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.selectedGroceryData.label,
          isShadowShow: false,
          buildCustomWidget:()=>
              Obx(()=> controller.selectedGroceries.isEmpty
                  ?  Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Icon(Icons.search),
              )
                  :  InkWell(
                onTap: ()=> Get.toNamed(RouteHelper.getAddGroceryScreenRoute()),
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
                                  shape: BoxShape.circle
                              ),
                              alignment: Alignment.center,
                              child: CustomText(
                                '${controller.selectedGroceries.length}',
                                color: AppColors.white,
                              ),
                            )
                        )
                      ]
                  ),
                ),
              ),
              )

      ),
      bottomNavigationBar:
      Obx((){
        if(controller.selectedGroceries.isEmpty)
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
                  child: CustomBtn(
                    onTap: () {
                      Get.toNamed(RouteHelper.getAddGroceryScreenRoute());
                    },
                    isValidate: true,
                    radius: SizeConfig.size8,
                    title: AppStrings.next,
                    // isLoading: authController.isAddBusinessUserLoading.value
                  ),
                ),
              ),
            ),
          );
      }),

      body: Row(
        children: [
          leftCategoryList(),
          Expanded(
              child: rightContent()
          ),
        ],
      ),
    );
  }

  Widget  leftCategoryList() {
    return Container(
      width: 94,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: widget.arrGroceries.length,
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        itemBuilder: (context, index) {
          return Obx(()=> _categoryItem(
            widget.arrGroceries[index].icon,
            widget.arrGroceries[index].label,
            selected: controller.selectedGrocery.value == widget.arrGroceries[index].tagId,
            onTap: () {
              controller.selectedGrocery.value = widget.arrGroceries[index].tagId;
              controller.selectedTabIndex.value = 0;
              log('new selection ${controller.selectedGrocery.value}');

              /// api call
              controller.fetchBoth();

            },
          ));
        },
      ),
    );
  }

  Widget _categoryItem(
      String icon,
      String label,
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
                    imagePath: 'assets/category/grocery/$icon',
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
    return Obx(()=> Padding(
      padding: const EdgeInsets.all(8),
      child: controller.isInitialLoading.value
          ? Center(
          child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Max Limit Error
          if (controller.isMaxLimitHit)
            Container(
              width: SizeConfig.screenWidth,
              decoration: BoxDecoration(
                  color: AppColors.redBE,
                  borderRadius: BorderRadius.circular(10.0)
              ),
              margin: EdgeInsets.only(bottom: SizeConfig.size10),
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size4,
                  horizontal: SizeConfig.size10
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.warningOutlineIcon,
                        width: SizeConfig.size20,
                        height: SizeConfig.size20
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      'You can’t select more than ${controller.maxLimit} products at a time.',
                      color: AppColors.redLite,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),

          // TABS
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.arrChildrenOfGroceryCategory.length + 1,
              itemBuilder: (_, i) {
                bool selected = controller.selectedTabIndex.value == i;

                var item;
                if(i != 0){
                  item = controller.arrChildrenOfGroceryCategory[i -1];
                }

                return InkWell(
                  onTap: () {
                    controller.selectedTabIndex.value = i;
                    controller.fetchGroceryCategoryProducts();
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: i == 0 ? 0 : 3,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.greyLite, width: 0.5),
                    ),
                    child: Center(
                      child: CustomText(
                        (i!=0) ? item.name : 'All',
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
          controller.isGroceryCategoryProductsLoading.value
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
              : Expanded(
            child: GridView.builder(
              controller: scrollController,
              itemCount: controller.arrGroceryCategoryProducts.length +
                  (controller.isGroceryCategoryProductsLoadingMore.value ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.6,
              ),
              padding: EdgeInsets.only(bottom: SizeConfig.size30),
              itemBuilder: (_, i) {
                if (i == controller.arrGroceryCategoryProducts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return groceryCard(controller.arrGroceryCategoryProducts[i]);
              },
            ),
          )
        ],
      ),
    ));
  }

  Widget groceryCard(GroceryProductData groceryProductData) {
    final bool isSelected = controller.selectedGroceries.contains(groceryProductData);
    final price = controller.getPriceDetails(groceryProductData.variants?[0].pricing);
    // print("Selling Range: ${price.sellingRange}");
    // print("MRP Range: ${price.mrpRange}");
    // print("Discount Range: ${price.discountRange}");

    return GestureDetector(
      onTap: () => controller.toggleSelection(groceryProductData),
      child: Container(
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

                Positioned(
                    top: 0,
                    right: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          final dummyVariant = VariantsList(
                            sId: 'var_123',
                            variantName: 'Supreme Traditional Basmati',
                            unit: 'kg',
                            sku: 'SKU123',
                            weight: 2,
                            pricing: [
                              Pricing(
                                sellingPrice: 199,
                                mrp: 250,
                              ),
                            ],
                            images: [
                              ProductImage(
                                url: 'https://fastly.picsum.photos/id/437/80/80.jpg?hmac=xan26CIEh31MwVZuPZqjynRmn6bsKteTe8XoIwPwSFY',
                                id: '1'
                              )
                              ]
                          );

                          showEditProductBottomSheet(
                            context,
                            selectedVariant: dummyVariant, // or null
                            onAdd: (variant, qty) {
                              // add to cart / selection
                              // controller.addToCart(variant, qty);
                            },
                          );
                        },
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: AppColors.blackMite,
                              borderRadius: BorderRadius.circular(20)),
                          child: Icon(
                            Icons.add,
                            size: SizeConfig.size16,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ))
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
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showEditProductBottomSheet(
      BuildContext context, {
        required VariantsList selectedVariant,
        required Function(VariantsList variant, int qty) onAdd,
      }) {
    // Local state inside sheet
    VariantsList _currentVariant = selectedVariant;
    int _quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.whiteF1,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 4.0,
              offset: const Offset(0, -3),
            )
          ],
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  /// Drag handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: EdgeInsets.only(bottom: SizeConfig.size5),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  /// Header
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          "All Variant",
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close,
                          size: SizeConfig.size20,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),

                  /// Product image + name
                 Container(
                    padding: EdgeInsets.all(SizeConfig.size10),
                   decoration: BoxDecoration(
                     color: AppColors.white,
                     border: Border.all(
                       color: AppColors.greyE5,
                     ),
                     borderRadius: BorderRadius.circular(10.0),
                     boxShadow: [AppShadows.textFieldShadow]
                   ),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(6),
                         child: CachedNetworkImage(
                           imageUrl: _currentVariant.images?.first.url ?? '',
                           width: SizeConfig.size50,
                           height: SizeConfig.size50,
                           fit: BoxFit.cover,
                           placeholder: (_, __) => const Center(
                               child:
                               CircularProgressIndicator(strokeWidth: 2)),
                           errorWidget: (_, __, ___) => LocalAssets(
                             imagePath: AppIconAssets.place_holder_image,
                             boxFix: BoxFit.cover,
                           ),
                         ),
                       ),
                       SizedBox(width: SizeConfig.size10),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             CustomText(
                                 _currentVariant.variantName ?? '',
                                 fontSize: SizeConfig.small,
                                 fontWeight: FontWeight.w600,
                                 color: AppColors.mainTextColor,
                             ),
                             SizedBox(height: SizeConfig.size8),
                             Row(
                                 children: [
                                   CustomText(
                                       '${_currentVariant.weight} ${_currentVariant.unit}',
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
                                       '₹100/kg',
                                       fontSize: SizeConfig.small,
                                       fontWeight: FontWeight.w400,
                                       color: AppColors.secondaryTextColor
                                   ),
                                   SizedBox(width: SizeConfig.size6),
                                   Container(
                                     width: 0.5,
                                     height: SizeConfig.size12,
                                     color: AppColors.secondaryTextColor,
                                   ),
                                   SizedBox(width: SizeConfig.size6),
                                   CustomText(
                                       '₹1,499',
                                       fontSize: SizeConfig.small,
                                       fontWeight: FontWeight.w600,
                                       color: AppColors.mainTextColor
                                   ),
                                   SizedBox(width: SizeConfig.size6),
                                   CustomText(
                                       '₹98,000',
                                       fontSize: SizeConfig.small,
                                       fontWeight: FontWeight.w400,
                                       color: AppColors.secondaryTextColor
                                   ),
                                 ]
                             )
                           ],
                         ),
                       ),
                       SizedBox(width: SizeConfig.size10),
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
                       ClipRRect(
                         borderRadius: BorderRadius.circular(10.0),
                         child: InnerShadow(
                           shadows: [
                             BoxShadow(
                               blurRadius: 15.0,
                               color: AppColors.blue52
                             )
                           ],
                           child: CustomBtn(
                             width: SizeConfig.size70,
                             height: SizeConfig.size30,
                             onTap: () {
                               onAdd(_currentVariant, _quantity);
                               Navigator.pop(context);
                             },
                             title: 'ADD',
                             textColor: AppColors.primaryColor,
                             borderColor: AppColors.primaryColor,
                             bgColor: Colors.transparent, // let Container handle tint
                             radius: 10,
                           ),
                         ),
                       )

                     ],
                   ),
                 ),

                ],
              ),
            );
          },
        );
      },
    );
  }

}
