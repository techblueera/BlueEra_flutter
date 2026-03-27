import 'package:BlueEra/core/api/model/new_food_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/all_food_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_food_home_screen.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuickFoodSearchScreen extends StatefulWidget {
  const QuickFoodSearchScreen({super.key});

  @override
  State<QuickFoodSearchScreen> createState() => _QuickFoodSearchScreenState();
}

class _QuickFoodSearchScreenState extends State<QuickFoodSearchScreen> {
  final controller = getOrPut(() => DiscoverController());
  final foodController = getOrPut(() => FoodServiceController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load food categories from API
    foodController.getFoodNestedCategoryApi();

    // Load all restaurants (no category filter)
    controller.selectedFoodServiceData.value = null;
    controller.fetchFoodRestaurantService();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        controller.fetchFoodRestaurantService(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Location Bar ──
            SliverToBoxAdapter(child: _buildLocationBar()),

            // ── Search Bar ──
            SliverToBoxAdapter(child: _buildSearchBar()),

            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size12)),

            // ── What's on your mind? ──
            SliverToBoxAdapter(child: _buildCategorySection()),

            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size8)),

            // ── Known & Loved (Horizontal restaurant cards) ──
            SliverToBoxAdapter(child: _buildKnownAndLovedSection()),

            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size8)),

            // ── All Restaurants Header + Filters ──
            SliverToBoxAdapter(child: _buildAllRestaurantsHeader()),

            // ── Restaurant List ──
            _buildRestaurantList(),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Location Bar ──────────────────────────────────────────────────────────

  Widget _buildLocationBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, size: 22),
          ),
          SizedBox(width: SizeConfig.size10),
          Icon(Icons.location_on, color: AppColors.red, size: 20),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  LocationService.userCurrentAddress.value.subLocality.isNotEmpty
                      ? LocationService.userCurrentAddress.value.subLocality
                      : 'Current Location',
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  [
                    LocationService.userCurrentAddress.value.subLocality,
                    LocationService.userCurrentAddress.value.city,
                  ].where((e) => e.isNotEmpty).join(', '),
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size8,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to search screen if available
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.fillColor,
            border: Border.all(width: 1, color: AppColors.secondaryTextColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.secondaryTextColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  'Search for dishes & restaurants',
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              LocalAssets(
                imagePath: AppIconAssets.mic,
                width: 20,
                height: 20,
                imgColor: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── What's on your mind? ──────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: CustomText(
              "What's on your mind?",
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 100,
            child: Obx(() {
              final categories = foodController.foodNestedCateList;
              if (categories.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size16),
                itemBuilder: (context, index) {
                  return _buildCategoryItem(categories[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(GroceryNestedCategoryModel category) {
    return InkWell(
      onTap: () {
        // Find matching onboarding category by name for navigation
        final matchingCategory = businessOnboardingFoodsCategories
            .firstWhereOrNull((c) =>
                c.name.replaceAll('\n', ' ').toLowerCase() ==
                (category.name ?? '').toLowerCase());
        Get.to(() => AllFoodServiceScreen(
              professionalConsultantCategories:
                  businessOnboardingFoodsCategories,
              selectedProfessionConsultantData:
                  matchingCategory ?? businessOnboardingFoodsCategories.first,
            ));
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.fillColor,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: (category.image?.isNotEmpty ?? false)
                  ? NetWorkOcToAssets(
                      imgUrl: category.image!,
                      boxFit: BoxFit.contain,
                    )
                  : Icon(Icons.fastfood_outlined,
                      size: 28, color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 6),
            CustomText(
              category.name ?? '',
              fontSize: 10,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w500,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Known & Loved ─────────────────────────────────────────────────────────

  Widget _buildKnownAndLovedSection() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Known & Loved',
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                InkWell(
                  onTap: () {
                    Get.to(() => AllFoodServiceScreen(
                          professionalConsultantCategories:
                              businessOnboardingFoodsCategories,
                          selectedProfessionConsultantData:
                              businessOnboardingFoodsCategories.first,
                        ));
                  },
                  child: CustomText(
                    'See all >',
                    fontSize: SizeConfig.medium,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: 180,
            child: Obx(() {
              if (controller.isFoodRestaurantLoading.value &&
                  controller.foodRestaurantDataList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.foodRestaurantDataList.isEmpty) {
                return Center(
                  child: CustomText(
                    'No restaurants found',
                    color: AppColors.secondaryTextColor,
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                itemCount: controller.foodRestaurantDataList.length > 10
                    ? 10
                    : controller.foodRestaurantDataList.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
                itemBuilder: (context, index) {
                  return _buildKnownLovedCard(
                      controller.foodRestaurantDataList[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKnownLovedCard(FoodData restaurant) {
    final profile = restaurant.businessProfile;
    return InkWell(
      onTap: () => Get.to(() => DiscoverFoodHomeScreen(foodData: restaurant)),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 110,
                width: 150,
                color: AppColors.fillColor,
                child: CachedAvatarWidget(
                  imageUrl: profile?.logo ?? '',
                  size: 150,
                  borderRadius: 12,
                  borderColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CustomText(
              profile?.businessName ?? 'Restaurant',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if ((profile?.avg_rating ?? 0) > 0) ...[
                  Icon(Icons.star, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 2),
                  CustomText(
                    '${profile?.avg_rating?.toStringAsFixed(1)}',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: CustomText(
                    profile?.typeOfBusiness ?? '',
                    fontSize: 11,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── All Restaurants Header + Filter Chips ──────────────────────────────────

  Widget _buildAllRestaurantsHeader() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size12,
        bottom: SizeConfig.size8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'All Restaurants',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Sort by', icon: Icons.swap_vert),
                SizedBox(width: SizeConfig.size8),
                _filterChip('Pure Veg'),
                SizedBox(width: SizeConfig.size8),
                _filterChip('Under 30 min'),
                SizedBox(width: SizeConfig.size8),
                _filterChip('Rating 4.0+'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.mainTextColor),
            const SizedBox(width: 4),
          ],
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  // ── All Restaurants List ──────────────────────────────────────────────────

  Widget _buildRestaurantList() {
    return Obx(() {
      if (controller.isFoodRestaurantLoading.value &&
          controller.foodRestaurantDataList.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (controller.foodRestaurantDataList.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: CustomText(
                'No restaurants found nearby',
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == controller.foodRestaurantDataList.length) {
              return controller.isFoodRestaurantLoadingMore.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const SizedBox.shrink();
            }
            return _buildRestaurantCard(
                controller.foodRestaurantDataList[index]);
          },
          childCount: controller.foodRestaurantDataList.length + 1,
        ),
      );
    });
  }

  Widget _buildRestaurantCard(FoodData restaurant) {
    final profile = restaurant.businessProfile;
    return InkWell(
      onTap: () => Get.to(() => DiscoverFoodHomeScreen(foodData: restaurant)),
      child: Container(
        color: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.fillColor,
                child: CachedAvatarWidget(
                  imageUrl: profile?.logo ?? '',
                  size: 100,
                  borderRadius: 12,
                  borderColor: Colors.transparent,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            // Restaurant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    profile?.businessName ?? 'Restaurant',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating row
                  Row(
                    children: [
                      if ((profile?.avg_rating ?? 0) > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                '${profile?.avg_rating?.toStringAsFixed(1)}',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.star,
                                  size: 10, color: AppColors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if ((profile?.total_ratings ?? 0) > 0)
                        CustomText(
                          '(${profile?.total_ratings} ratings)',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    profile?.typeOfBusiness ?? '',
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile?.address?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.secondaryTextColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: CustomText(
                            profile?.address ?? '',
                            fontSize: 11,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}
