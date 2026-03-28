import 'dart:math';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_availability_widget.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_cart_icon.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class OtherFoodStoreDetailsScreen extends StatefulWidget {
  final String visitBusinessId;

  const OtherFoodStoreDetailsScreen(
      {super.key, required this.visitBusinessId});

  @override
  State<OtherFoodStoreDetailsScreen> createState() =>
      _OtherFoodStoreDetailsScreenState();
}

class _OtherFoodStoreDetailsScreenState
    extends State<OtherFoodStoreDetailsScreen> {
  final controller = getOrPut(() => RestaurantController());
  final foodCustomerController = getOrPut(() => FoodCustomerController());

  @override
  void initState() {
    super.initState();
    controller.fetchHomeData(businessId: widget.visitBusinessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        buildCustomActionWidget: () => FoodCartIconButton(),
      ),
      body: Obx(() {
        if (controller.foodHomeDataResponse.value.status == Status.INITIAL) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.restaurantData.value;
        if (data == null) {
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        }

        final details = data.businessProfileDetails;

        return RefreshIndicator(
          onRefresh: () async {
            controller.fetchHomeData(businessId: widget.visitBusinessId);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Profile Header (Read-Only)
                _buildProfileHeader(details),

                /// Offer Dish (Discount) — only when items exist
                if (controller.allFoodItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  CustomFormCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const CustomText(
                                'Offer Dish  (Discount)',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              CustomText(
                                AppStrings.viewAll.tr,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
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
                ],

                /// Restaurant Specials — only when data exists
                if (controller.restaurantSpecials.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildRestaurantSpecials(),
                ],

                /// Food Menu Categories
                _buildMenuCategories(
                  menus: data.foodMenu ?? [],
                  businessProfileDetails: details,
                ),

                /// Gallery
                if (data.gallery?.isNotEmpty ?? false)
                  CustomFormCard(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustomText(AppStrings.gallery.tr,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildGallery(data.gallery ?? [], context),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                _buildContactAndMapCard(details),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  PROFILE HEADER (View-Only)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProfileHeader(BusinessProfileDetails? details) {
    final hasCover =
        details?.coverimage != null && details!.coverimage!.isNotEmpty;
    final hasAddress =
        details?.address != null && details!.address!.trim().isNotEmpty;
    final hasDietaryType = details?.dietaryType != null &&
        details!.dietaryType!.trim().isNotEmpty;
    final hasAvailability = details?.availability?.schedule != null;

    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Profile Image
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: hasCover
                        ? Image.network(
                            details.coverimage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildBannerPlaceholder(),
                          )
                        : _buildBannerPlaceholder(),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.white,
                      child: details?.logo?.isNotEmpty == true
                          ? ClipOval(
                              child: NetWorkOcToAssets(
                                  imgUrl: details?.logo ?? ""))
                          : LocalAssets(
                              imagePath: AppIconAssets.user_out_line),
                    ),
                  ),
                ),
                // User rating bar
                Positioned(
                  right: 5,
                  bottom: 10,
                  child: RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 15,
                    unratedColor: AppColors.secondaryTextColor,
                    itemPadding:
                        const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => LocalAssets(
                      imagePath: AppIconAssets.star_rounded,
                      imgColor: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      // TODO: submit rating to API
                    },
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(details?.businessName,
                    fontSize: 20,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),

                // Dietary + SubCategory + Rating row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasDietaryType) ...[
                      _buildDietaryIndicator(details.dietaryType!),
                      const SizedBox(width: 6),
                    ],
                    if (details?.subCategoryDetails?.name != null)
                      BusinessCommonSubCategoryWidget(
                        label: details?.subCategoryDetails?.name,
                      ),
                    const SizedBox(width: 5),
                    CommonRatingRow(
                      rating: double.tryParse(
                              details?.avg_rating.toString() ?? '0.0') ??
                          0.0,
                      reviews: details?.total_ratings?.toInt() ?? 0,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Distance + locality row
                Row(
                  children: [
                    Icon(Icons.near_me_rounded,
                        size: 14, color: AppColors.primaryColor),
                    const SizedBox(width: 5),
                    CustomText(
                      '${calculateDistance(
                        details?.businessLocation?.lat?.toDouble() ??
                            0.0,
                        details?.businessLocation?.lon?.toDouble() ??
                            0.0,
                      )?.toStringAsFixed(2) ?? '--'} KM',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                    if (hasAddress) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: CustomText(
                          '|',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      Expanded(
                        child: CustomText(
                          getLocalityAddress(details.address),
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Full address
                if (hasAddress) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: CustomText(details.address,
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Availability (view-only)
                if (hasAvailability) ...[
                  BusinessAvailabilityWidget(
                    hasAvailability: true,
                    schedule: details?.availability?.schedule,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: AppColors.greyLite,
      child: Center(
        child: LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
          height: 160,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildDietaryIndicator(String dietaryType) {
    if (dietaryType == 'Both') {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 7, width: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.green00),
            ),
            const SizedBox(width: 4),
            Container(
              height: 7, width: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.red00),
            ),
          ],
        ),
      );
    }
    return FoodTypeIndicator(
      isVegetarian: dietaryType == 'Veg',
      size: 7,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  OFFER DISH (Horizontal List with Discount)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                filter: ImageFilter.blur(
                                    sigmaX: 2, sigmaY: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFFFD7845),
                                        Color(0xFFFA5568),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.white
                                          .withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                    borderRadius:
                                        const BorderRadius.only(
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
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            item.product?.name ?? "",
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            fontSize: 13,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (item.rating != null && item.rating! > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  RatingBadge(
                                      rating:
                                          item.rating.toString()),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          _buildDottedLine(),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CustomText(
                                "₹${sellingPrice ?? 0}",
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              if (mrp != null &&
                                  sellingPrice != null &&
                                  mrp > sellingPrice) ...[
                                const SizedBox(width: 6),
                                CustomText(
                                  "₹$mrp",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                  decoration:
                                      TextDecoration.lineThrough,
                                  decorationColor:
                                      AppColors.secondaryTextColor,
                                ),
                              ],
                            ],
                          ),
                          if (isMultiVariant)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(4),
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
                    ),
                  ],
                ),
              );
            },
          ),
        ));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  RESTAURANT SPECIALS (View-Only, no empty state)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildRestaurantSpecials() {
    return Obx(() {
      final specials = controller.restaurantSpecials;
      if (specials.isEmpty) return const SizedBox();

      return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: CustomText(
                'Restaurant Special Dish',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: specials.length,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  return _buildSpecialDishCard(specials[index]);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  Widget _buildSpecialDishCard(RestaurantSpecial item) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  MENU CATEGORIES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildMenuCategories({
    required List<GroceryNestedCategoryModel> menus,
    BusinessProfileDetails? businessProfileDetails,
  }) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.paddingXSL),
        CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText('Menu',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600),
              SizedBox(height: SizeConfig.paddingXSL),
              menus.isNotEmpty
                  ? MasonryGridView.count(
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
                          getName: (item) => item.name ?? '',
                          getIcon: (item) => item.image ?? '',
                          iconHeight: SizeConfig.size60,
                          boxShadow: [],
                          onTap: (item) {
                            Get.toNamed(
                              RouteHelper
                                  .getFoodCustomerListingScreenRoute(),
                              arguments: {
                                ApiKeys.argCategoryData: item,
                                ApiKeys.argBusinessId:
                                    businessProfileDetails?.id,
                              },
                            );
                          },
                        );
                      },
                    )
                  : EmptyStateWidget(
                      message:
                          '${businessProfileDetails?.businessName ?? 'This shop'} hasn\'t listed any products yet.',
                    ),
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  GALLERY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildGallery(
      List<FoodGallery> galleryList, BuildContext context) {
    List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) allImages.addAll(g.imageUrls!);
    }
    if (allImages.isEmpty) return const SizedBox();

    allImages.shuffle(Random());
    final displayCount = allImages.length > 10 ? 10 : allImages.length;

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(displayCount, (index) {
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;

        if (index % 6 == 0 || index % 6 == 5) {
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () => navigatePushTo(
              context,
              ImageViewScreen(
                subTitle: AppStrings.imageViewer,
                appBarTitle: AppStrings.imageViewer,
                imageUrls: allImages,
                initialIndex: index,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                allImages[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  CONTACT & MAP
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildContactAndMapCard(
      BusinessProfileDetails? details) {
    final logoUrl = details?.logo;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.contactUs.tr,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      key: ValueKey(logoUrl),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12, blurRadius: 10)
                        ],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl) as ImageProvider
                              : AssetImage(
                                  AppIconAssets.place_holder_image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(details?.businessName,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          if (details?.businessDescription
                                  ?.isNotEmpty ??
                              false)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5),
                              child: CustomText(
                                details?.businessDescription,
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.greyE5, height: 30),
                if (details?.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.website_click,
                      details?.websiteUrl ?? "",
                      AppColors.primaryColor),
                if (details?.subCategoryDetails?.name?.isNotEmpty ??
                    false)
                  _contactItem(
                      AppIconAssets.principal,
                      details?.subCategoryDetails?.name ?? "",
                      AppColors.secondaryTextColor),
                if (details?.ownerDetails?.isNotEmpty == true &&
                    (details?.ownerDetails?[0].email?.isNotEmpty ??
                        false))
                  _contactItem(
                      AppIconAssets.email,
                      details?.ownerDetails?[0].email ?? "",
                      AppColors.secondaryTextColor),
                if (details?.userContactNo?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.phone_outline,
                      details?.userContactNo ?? "",
                      AppColors.secondaryTextColor),
                if (details?.address?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.location_new,
                      details?.address ?? "",
                      AppColors.secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          BusinessLocationMapWidget(
            latitude: details?.businessLocation?.lat ?? 0.0,
            longitude: details?.businessLocation?.lon ?? 0.0,
            businessName: details?.businessName ?? "",
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label,
                fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
}
