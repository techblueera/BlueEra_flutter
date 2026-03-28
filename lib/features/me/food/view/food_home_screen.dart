import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_common_gallery_card.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/food_service_gallery/food_service_photos_screen.dart';
import 'package:BlueEra/features/me/food/view/my_food_product_screen.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class RestaurantHomeScreen extends StatefulWidget {
  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  final controller = getOrPut(() => RestaurantController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  BusinessProfileDetails? businessProfileDetails;
  
  @override
  initState() {
    super.initState();
    controller.fetchHomeData(businessId: businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.foodHomeDataResponse.value.status == Status.INITIAL) {
          return const Center(child: CircularProgressIndicator());
        }

        businessProfileDetails = viewBusinessDetailsController.businessProfileDetails.value?.data;
        final data = controller.restaurantData.value;
        if (data == null)
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        return RefreshIndicator(
          onRefresh: () async {
            controller.fetchHomeData(businessId: businessId);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 40,
              top: 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                ///FOOD HOTEL....
                BusinessProfileHeaderView(
                  details:  businessProfileDetails,
                  controller: viewBusinessDetailsController,
                  isRestaurantProfile: true
                ),

                const SizedBox(height: 10),

                // ── 4. Business Stats ──
                BusinessStats(details: businessProfileDetails),

                ///Food Selection (Horizontal List)
                if (controller.allFoodItems.isNotEmpty)
                  CustomFormCard(
                    padding: EdgeInsets.zero,
                    margin: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const CustomText(
                                'Offer Dish  (Discount)',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              InkWell(
                                onTap: () {
                                  // TODO: navigate to all offers
                                },
                                child: CustomText(
                                  AppStrings.viewAll.tr,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildHorizontalFoodList(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                /// Restaurant Specials
                const SizedBox(height: 10),
                _buildRestaurantSpecials(),

                ///FOOD MENU...
                _buildMenuCategories(controller.foodMenuNestedCategory),

                /// Gallery
                SizedBox(height: 10.0),
                CommonGalleryCard(
                  gallery: data.gallery
                      ?.expand((g) => g.imageUrls ?? [])
                      .cast<String>()
                      .toList(),
                  onEditTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
                  onAddTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
                  emptyTitle: 'You Have Not Post Any Photo',
                  addButtonLabel: 'Add Photo',
                  isRestaurantGallery: true
                ),

                SizedBox(height: 10.0),
                BusinessContactMapCard(
                  businessProfileDetails: businessProfileDetails,
                ),

                // ── 11. QR Code ──
                BusinessQrCodeWidget(
                  data:       businessProfileDetails,
                  onDownload: () {
                    // downloadQrCode();
                  },
                  onShare:    () {
                    // shareQrCode();
                  },
                ),
                const SizedBox(height: 100),

              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHorizontalFoodList() {
    return Obx(() => SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.allFoodItems.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final item = controller.allFoodItems[index];
              final bool hasVariants =
                  item.variants != null && item.variants!.isNotEmpty;
              final int variantCount = item.variants?.length ?? 0;
              final bool isMultiVariant = variantCount > 1;

              final sellingPrice = hasVariants
                  ? item.variants![0].price?.sellingPrice
                  : item.price?.sellingPrice;
              final mrp = hasVariants
                  ? item.variants![0].price?.mrp
                  : item.price?.mrp;

              final int discountPercent =
                  (mrp != null && sellingPrice != null && mrp > sellingPrice)
                      ? (((mrp - sellingPrice) / mrp) * 100).round()
                      : 0;

              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.greyE5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image card with discount badge ──
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl:
                                item.product?.images?.firstOrNull ?? "",
                            height: 140,
                            width: 170,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          ),
                        ),

                        // Discount badge
                        if (discountPercent > 0)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFFFD7845),
                                        Color(0xFFFA5568),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.white.withValues(alpha: 0.2),
                                      width: 0.5
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: CustomText(
                                    '$discountPercent% OFF',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Veg/Non-veg indicator
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FoodTypeIndicator(
                            isVegetarian: item.product?.dietaryType
                                ?.toLowerCase() ==
                                "veg",
                            size: 8,
                          ),
                        ),

                     ]
                    ),

                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Item name ──
                          CustomText(
                            item.product?.name ?? "",
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            fontSize: 13,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              RatingBadge(rating: '4.5'),
                              const SizedBox(width: 4),
                              CustomText(
                                '1.2 K Reviews',
                                fontWeight: FontWeight.w600,
                                maxLines: 1,
                                color: AppColors.secondaryTextColor,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Dotted divider
                          _buildDottedLine(),
                          const SizedBox(height: 6),

                          // ── Price row: selling + MRP strikethrough ──
                          Row(
                            children: [
                              CustomText(
                                "₹${sellingPrice ?? 0}",
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              if (mrp != null &&
                                  sellingPrice != null &&
                                  mrp >= sellingPrice) ...[
                                const SizedBox(width: 6),
                                CustomText(
                                  "₹$mrp",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.secondaryTextColor,
                                ),
                              ],
                            ],
                          ),

                          // --- 4. Multiple Variants Indicator ---
                          if (isMultiVariant)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(
                                      alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CustomText(
                                  "+${variantCount - 1} more variant",
                                  fontSize: 10,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )


                  ],
                ),
              );
            },
          ),
        ));
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 3.0;
        final dashCount =
        (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.greyE5),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: 170,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  Widget _buildRestaurantSpecials() {
    return Obx(() {
      final specials = controller.restaurantSpecials;
      final isEmpty = specials.isEmpty;

      return CustomFormCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: CustomText(
                'Your Restaurant Special Dish',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (isEmpty)
              _buildSpecialDishEmptyState()
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: specials.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final item = specials[index];
                    return _buildSpecialDishCard(item);
                  },
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  Widget _buildSpecialDishEmptyState() {
    // Dummy data to show behind the blur
    final dummyItems = [
      {'name': 'Traditional Turkish\nBreakfast', 'desc': 'Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....'},
      {'name': 'Traditional Turkish\nBreakfast', 'desc': 'Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum....'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              // Dummy cards row behind blur
              Row(
                children: dummyItems.map((item) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: item == dummyItems.last ? 0 : 10,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              AppImageAssets.homeMadeFoodBanner,
                              fit: BoxFit.cover,
                            ),
                            // Dark gradient

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: AppColors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),

                            // Dummy text
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    item['name']!,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (_) => const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    item['desc']!,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Blur overlay + empty state content
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: AppColors.black.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LocalAssets(
                            imagePath: AppImageAssets.noMeContent,
                            height: SizeConfig.size80,
                            width: SizeConfig.size80,
                          ),
                          const SizedBox(height: 6),
                          CustomText(
                            'You Have Not Added Any Special Dish',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              // TODO: navigate to add special dish
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.primaryColor,
                              ),
                              child: CustomText(
                                'Add Special Dish',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialDishCard(RestaurantSpecial item) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: item.image ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.grey.shade300),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.restaurant,
                      color: Colors.grey, size: 40),
                ),
              ),
            ),

            // Dark gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Content at bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    item.name ?? '',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.rating != null && item.rating! > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < item.rating!.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      item.description!,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCategories(List<GroceryNestedCategoryModel> menus) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.paddingXSL),
        CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                  'Our Menu',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600),

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

              menus.isNotEmpty ?
              MasonryGridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                itemCount: menus.length,
                itemBuilder: (context, index) {
                  var categoryItem = menus[index];
                  return CommonServiceCard(
                    service: categoryItem,
                    getName: (_categoryItem) => _categoryItem.name ?? '',
                    getIcon: (_categoryItem) => _categoryItem.image ?? '',
                    iconHeight: SizeConfig.size60,
                    boxShadow: [],
                    onTap: (_categoryItem) {
                      return Get.to(
                              () =>
                              MyFoodProductScreen(
                                foodMenu: _categoryItem,
                              ));

                      // return Get.toNamed(RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
                      //   arguments: {
                      //     ApiKeys.userId: userId,
                      //     ApiKeys.argGroceryCategoryWithInventory: foodCategoryList,
                      //     ApiKeys.argArrGroceryCatKey: _categoryItem.key,
                      //     ApiKeys.argArrGroceryCatName: _categoryItem.name,
                      //   },
                      // );

                    },
                  );
                },
              )
                  : EmptyStateWidget(
                message: 'You don\'t have inventory yet, Want to create one?',
              ),

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

            ],
          ),
        ),
      ],
    );
  }
}
