import 'dart:math';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
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
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class VisitFoodStoreDetailsScreen extends StatefulWidget {
  final String visitBusinessId;

  const VisitFoodStoreDetailsScreen(
      {super.key, required this.visitBusinessId});

  @override
  State<VisitFoodStoreDetailsScreen> createState() =>
      _VisitFoodStoreDetailsScreenState();
}

class _VisitFoodStoreDetailsScreenState
    extends State<VisitFoodStoreDetailsScreen> {
  final controller = getOrPut(() => RestaurantController());
  final foodCustomerController = getOrPut(() => FoodCustomerController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.viewBusinessProfileById(widget.visitBusinessId);
    controller.fetchHomeData(businessId: widget.visitBusinessId);
    _trackBusinessStoreView(widget.visitBusinessId);
  }

  void _trackBusinessStoreView(String visitBusinessId) {
    if (kReleaseMode && visitBusinessId.isNotEmpty) {
      Future.microtask(() async {
        try {
          StoreRepo().businessByViewCountIDApi(businessId: visitBusinessId);
        } catch (e) {
          print("Failed to track view: $e");
        }
      });
    }
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

        final visitDetails = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
        final details = visitDetails ?? data.businessProfileDetails;

        return RefreshIndicator(
          onRefresh: () async {
            viewBusinessDetailsController.viewBusinessProfileById(widget.visitBusinessId);
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
                VisitBusinessCommonHeader(
                  details: details,
                  onRated: () => viewBusinessDetailsController
                      .viewBusinessProfileById(widget.visitBusinessId),
                ),

                /// Business Stats
                const SizedBox(height: 10),
                VisitBusinessStatsCard(details: details),

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

                /// Business Live Photos
                if (details?.livePhotos != null &&
                    details!.livePhotos!.any((p) => p.trim().isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  CustomFormCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(
                          'Live Photos',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 10),
                        StoreLivePhotoWidget(
                          livePhotos: details.livePhotos!
                              .where((p) => p.trim().isNotEmpty)
                              .toList(),
                          natureOfBusiness:
                              details.subCategoryDetails?.name ??
                                  details.natureOfBusiness ??
                                  'OTHER',
                          onViewFullScreen: ({
                            required int index,
                            required List<String> storeImage,
                            required String natureOfBusiness,
                          }) {
                            navigatePushTo(
                              context,
                              ImageViewScreen(
                                appBarTitle: details.businessName ?? '',
                                subTitle: natureOfBusiness,
                                imageUrls: storeImage,
                                initialIndex: index,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

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

                /// QR Code
                const SizedBox(height: 10),
                BusinessQrCodeWidget(data: details),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
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
