import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../controller/food_upload_controller.dart';
import '../model/get_food_details_model.dart';

class FoodAndGroceryScreen extends StatefulWidget {
  final ProviderType providerType;
  final EarnServiceTypes? serviceSubType;
  final bool isShowGrid;

  const FoodAndGroceryScreen({
    super.key,
    required this.providerType,
    this.serviceSubType,
    this.isShowGrid = true
  });

  @override
  State<FoodAndGroceryScreen> createState() => _FoodAndGroceryScreenState();
}

class _FoodAndGroceryScreenState extends State<FoodAndGroceryScreen>
    with RouteAware {
  final controller = Get.put(FoodUploadController());
  final ScrollController scrollController = ScrollController();
  late Map<String, dynamic> queryParams;
  late bool isFromEarnWithBlueEra;

  @override
  void initState() {

    isFromEarnWithBlueEra = widget.providerType == ProviderType.user;

    queryParams = {
      ApiKeys.all: false,
      ApiKeys.type: AppConstants.food,
      ApiKeys.providerType: widget.providerType.title,
    };

    if(isFromEarnWithBlueEra) queryParams[ApiKeys.subType] = widget.serviceSubType?.label;

    // Only call API if first load or list is empty
    if (controller.foodDataList.isEmpty) {
      controller.getFoodService(queryParams, isFromEarnWithBlueEra: isFromEarnWithBlueEra);
    }

    scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.getFoodService(queryParams, isFromEarnWithBlueEra: isFromEarnWithBlueEra, isLoadMore: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (controller.shouldRefresh) {
      controller.getFoodService(queryParams, isFromEarnWithBlueEra: isFromEarnWithBlueEra);
      controller.shouldRefresh = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isFoodDataFirstLoading.value) {
          const Center(
            child: CircularProgressIndicator(),
          );
        }

        if(controller.foodDataList.isNotEmpty) {
          return Column(
            children: [

               Expanded(
                child: widget.isShowGrid
                    ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = 2;
                      final crossSpacing = 10.0;
                      final mainSpacing = 10.0;

                      final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
                      final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

                      final approximateItemHeight = SizeConfig.size280;

                      final childAspectRatio = itemWidth / approximateItemHeight;


                      return GridView.builder(
                        // controller: storesScrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: crossSpacing,
                          mainAxisSpacing: mainSpacing,
                          childAspectRatio: childAspectRatio,
                        ),
                        padding: EdgeInsets.only(
                            bottom: kBottomNavigationBarHeight + 40,
                          left: SizeConfig.size8,
                          right: SizeConfig.size8,
                          top: SizeConfig.size8,
                        ),
                        itemCount: controller.foodDataList.length,
                        itemBuilder: (context, index) {
                          final food = controller.foodDataList[index];
                          return FoodItemCard(
                              controller: controller,
                              foodData: food,
                              isFromEarnWithBlueEra: isFromEarnWithBlueEra,
                              isGridShow: true,
                          );
                        },
                      );
                    },
                  ),
                )
                    : ListView.builder(
                  itemCount: controller.foodDataList.length,
                  itemBuilder: (context, index) {
                    final food = controller.foodDataList[index];
                    return FoodItemCard(
                      controller: controller,
                      foodData: food,
                      isFromEarnWithBlueEra: isFromEarnWithBlueEra,
                      isGridShow: false,
                    ); // dynamic card
                  },
                ),
              ),

              if (controller.isFoodDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }else{
          return Center(child: CustomText(AppStrings.noFoodServiceFound, fontSize: 18));
        }
      }),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  const FoodItemCard({
    super.key,
    required this.controller,
    required this.foodData,
    required this.isFromEarnWithBlueEra,
    required this.isGridShow,
    this.width,
  });

  final GetFoodDetailsModel foodData;
  final FoodUploadController controller;
  final bool isFromEarnWithBlueEra;
  final bool isGridShow;
  final double? width;

  @override
  Widget build(BuildContext context) {

    final priceOptions = foodData.priceOptions;

    String priceText = AppStrings.na;
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return InkWell(
      onTap: (){
        Get.to(()=> FoodDetailsViewScreen(
          productPriceFormat:(foodData.priceType == "single")
              ? "${foodData.singlePrice ?? "0"}"
              : "$priceText",
          data: foodData,
        ));
      },
      child: (isGridShow) ? Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Food Image
            SizedBox(
              height: SizeConfig.size150,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (foodData.photos?.isNotEmpty??false)
                        ?  CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: SizeConfig.size150,
                      imagePaths: foodData.photos ?? [],
                      borderRadius: BorderRadius.zero,
                    ) : LocalAssets(
                      imagePath:
                      AppIconAssets.place_holder_image,
                      boxFix: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildIconBox(
                      onTap: () async {
                        await showCommonDialog(
                        context: context,
                        text: AppStrings.areYouSureDeleteThisFoodService,
                        confirmText: AppStrings.delete,
                        cancelText: AppStrings.cancel,
                        confirmCallback: () {
                          controller.deleteFoodService(
                              serviceId: foodData.id ?? '',
                              isFromEarnWithBlueEra: isFromEarnWithBlueEra
                          );
                        },
                        cancelCallback: () {
                          Get.back();
                        },
                        );
                      },
                      Icon(Icons.more_vert, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Food Details
            Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10, horizontal: SizeConfig.size8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name
                  CustomText(
                    foodData.title ?? AppStrings.na,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: SizeConfig.size5),

                  // Veg label + category
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: controller.getFoodTypeColor(foodData.vegType),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            foodData.vegType ?? "",
                            color: Colors.white,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          foodData.category ?? "",
                          color: Colors.grey.shade600,
                          fontSize:  SizeConfig.small,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size5),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.energyPrefix,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        CustomText(
                          " ${foodData.nutritionalSummaryPer100g?.caloriesKcal ?? AppStrings.na.tr} ${AppStrings.Cal100gm.tr}",
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size5),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: (foodData.priceType == "single")
                        ? CustomText(
                      "₹${foodData.singlePrice ?? "0"}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                        : CustomText(
                      "₹${priceText}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ) : Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            SizedBox(
              width: 140, // fixed width for image column
              height: 200, // fixed height (adjust as needed)
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: (foodData.photos?.isNotEmpty??false)
                    ? CustomImageSlideshow(
                  isLoading: false,
                  width: 140, // fixed width for image column
                  height: 200, // fixed height (adjust as needed)
                  imagePaths: foodData.photos ?? [],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  onPhotoIndex: (index) {
                    // productPhotoIndex = index;
                  },
                ) : LocalAssets(
                  imagePath:
                  AppIconAssets.place_holder_image,
                  boxFix: BoxFit.fill,
                ),

                // CachedNetworkImage(
                //   imageUrl: foodData.photos?.first ?? "",
                //   fit: BoxFit.cover, // fills entire box
                //   placeholder: (context, url) =>  LocalAssets(
                //     imagePath:
                //     AppIconAssets.place_holder_image,
                //     boxFix: BoxFit.fill,
                //   ),
                //   errorWidget: (context, url, error) =>
                //       LocalAssets(
                //         imagePath:
                //         AppIconAssets.place_holder_image,
                //         boxFix: BoxFit.fill,
                //       ),
                // ) : LocalAssets(
                //   imagePath:
                //   AppIconAssets.place_holder_image,
                //   boxFix: BoxFit.fill,
                // ),
              ),
            ),

            // CONTENT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + menu button
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0,
                        ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            foodData.title ?? AppStrings.na,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            color: AppColors.mainTextColor,
                          ),
                        ),

                        IconButton(
                            onPressed: () async {
                              await showCommonDialog(
                              context: context,
                              text: AppStrings.areYouSureDeleteThisFoodService,
                              confirmText: AppStrings.delete,
                              cancelText: AppStrings.cancel,
                              confirmCallback: () {
                                controller.deleteFoodService(
                                    serviceId: foodData.id ?? '',
                                    isFromEarnWithBlueEra: isFromEarnWithBlueEra
                                );
                              },
                              cancelCallback: () {
                                Get.back();
                              },
                              );
                            }, icon: Icon(
                          Icons.more_vert, color: Colors.black, size: 20,
                        ))
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Veg label + category
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: controller.getFoodTypeColor(foodData.vegType),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                foodData.vegType ?? "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              foodData.category ?? "",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Description
                        Text(
                          foodData.description ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: (foodData.priceType == "single")
                              ? CustomText(
                            "${AppStrings.pricePrefix.tr}₹ ${foodData.singlePrice ?? "0"}",
                            fontSize: SizeConfig.small,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            color: AppColors.primaryColor,
                          )
                              : CustomText(
                            "${AppStrings.pricePrefix.tr}₹${priceText}",
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.primaryColor,
                            maxLines: 1,
                          ),
                        ),
                        // Row(
                        //   children: [
                        //     Text("Small: ₹299",
                        //         style: TextStyle(fontWeight: FontWeight.w600)),
                        //     const SizedBox(width: 8),
                        //     Text("Medium: ₹499",
                        //         style: TextStyle(fontWeight: FontWeight.w600)),
                        //     const SizedBox(width: 8),
                        //     Text("Large: ₹799",
                        //         style: TextStyle(fontWeight: FontWeight.w600)),
                        //   ],
                        // ),
                        const SizedBox(height: 4),

                        // Discount
                        if (foodData.discounts != null &&
                            foodData.discounts!.isNotEmpty)
                          Text(
                            foodData.discounts!.first,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Add-ons
                        if (foodData.addOns != null
                            && foodData.addOns!.isNotEmpty)
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: foodData.addOns!
                                .map((addon) => InkWell(
                              onTap: () {},
                              child: Text(
                                addon,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ))
                                .toList(),
                          )
                      ],
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(Widget child, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

}
