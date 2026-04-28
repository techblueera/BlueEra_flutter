import 'dart:math';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/me/food/view/all_offer_dish_screen.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_self_pickup_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_offer_dish_tile.dart';
import 'package:BlueEra/features/me/food/view/widget/food_self_pickup_variants_sheet.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final storeController = getOrPut(() => NewStoreController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();

  /// Session cart — registered by [RestaurantNearMeScreen] entry point.
  /// Found (not `put`) here so add/remove on this screen mutates the same
  /// instance the cart bar on the entry point is watching.
  final FoodSelfPickupController foodCartController =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.viewBusinessProfileById(widget.visitBusinessId);
    controller.fetchHomeData(businessId: widget.visitBusinessId);
    controller.fetchDiscountFoodProducts(businessId: widget.visitBusinessId);
    storeController.trackStoreDetailView(widget.visitBusinessId);
  }

  void _openVariantsSheetForOfferDish(CategoryFoodProductData product) {
    final visitDetails =
        viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
    final details =
        visitDetails ?? controller.restaurantData.value?.businessProfileDetails;

    // The discountProducts API already returns CategoryFoodProductData (same
    // model the listing screen uses), so we can hand it straight to the
    // self-pickup variants sheet — no conversion needed.
    showFoodSelfPickupVariantsSheet(
      context,
      args: FoodSelfPickupSheetArgs.fromCategoryProduct(
        product,
        visitBusinessId: widget.visitBusinessId,
        visitBusinessName: details?.businessName,
        visitBusinessLogo: details?.logo,
        visitBusinessAddress: details?.address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildScrollBody(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FoodSelfPickupCart(controller: foodCartController),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return Obx(() {
        // Subscribe to silent profile refreshes — bumps on every
        // successful viewBusinessProfileById fetch so the rate / follow
        // callbacks can refresh the header + stats without a loader.
        viewBusinessDetailsController.profileVersion.value;
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
                      .viewBusinessProfileById(
                    widget.visitBusinessId,
                    silent: true,
                  ),
                  onFollowChanged: () => viewBusinessDetailsController
                      .viewBusinessProfileById(
                    widget.visitBusinessId,
                    silent: true,
                  ),
                ),

                /// Business Stats
                const SizedBox(height: 10),
                VisitBusinessStatsCard(details: details),

                /// Offer Dish (Discount) — paginated discountProducts API
                if (controller.discountFoodItems.isNotEmpty) ...[
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
                              CustomText(
                                AppStrings.foodOfferDishDiscount.tr,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              GestureDetector(
                                onTap: () => Get.to(() => AllOfferDishScreen(
                                  businessId: widget.visitBusinessId,
                                )),
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
                        _buildDiscountFoodList(),
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
                        CustomText(
                          AppStrings.livePhotos.tr,
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

                BusinessContactMapCard(
                  businessProfileDetails: details,
                  showEditButton: false,
                ),

                /// QR Code
                // Obx(() {
                //   if (viewBusinessDetailsController.isProfileLoading.value) {
                //     return const SizedBox.shrink();
                //   }
                //   final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                //   return BusinessQrCodeWidget(data: details);
                // }),


                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      });
  }


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  OFFER DISH (Horizontal List with Discount)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildDiscountFoodList() {
    return Obx(() => SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.discountFoodItems.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final item = controller.discountFoodItems[index];
              final bool hasVariants =
                  item.variants != null && item.variants!.isNotEmpty;
              final sellingPrice =
                  hasVariants ? item.variants![0].baseSellingPrice : null;
              final mrp = hasVariants ? item.variants![0].mrp : null;

              final int discountPercent =
                  (mrp != null && sellingPrice != null && mrp > sellingPrice)
                      ? (((mrp - sellingPrice) / mrp) * 100).round()
                      : 0;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openVariantsSheetForOfferDish(item),
                child: Container(
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
                            imageUrl: item.images?.firstOrNull ?? "",
                            height: 130,
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
                            isVegetarian:
                                item.dietaryType?.toLowerCase() == "veg",
                            size: 8,
                          ),
                        ),
                      ],
                    ),
                    FoodOfferDishInfoSection(item: item),
                  ],
                ),
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
              CustomText(AppStrings.foodMenuLabel.tr,
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
                          '${businessProfileDetails?.businessName ?? AppStrings.foodThisShopLabel.tr} hasn\'t listed any products yet.',
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
                subTitle: AppStrings.imageViewer.tr,
                appBarTitle: AppStrings.imageViewer.tr,
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
  //  HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
