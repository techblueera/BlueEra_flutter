import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/view/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantNearMeScreen extends StatefulWidget {
  const RestaurantNearMeScreen({super.key});

  @override
  State<RestaurantNearMeScreen> createState() => _RestaurantNearMeScreenState();
}

class _RestaurantNearMeScreenState extends State<RestaurantNearMeScreen> {
  final storeController = getOrPut(() => NewStoreController());
  final ScrollController _scrollController = ScrollController();
  final RxInt selectedCategoryIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _fetchStores();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        storeController.getAllStoreNearBy(isLoadMore: true);
      }
    });
  }

  void _fetchStores({String? categoryId}) {
    storeController.typeOfBusiness = AppConstants.food;
    storeController.businessCategoryId = categoryId;
    storeController.getAllStoreNearBy();
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
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final categories = businessOnboardingFoodsCategories;
          final idx = selectedCategoryIndex.value;
          final name = (idx >= 0 && idx < categories.length)
              ? categories[idx].name
              : 'Restaurant Near Me';
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        buildCustomActionWidget: () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, size: 24),
            ),
            const DiscoverCartIcon(),
          ],
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategorySidebar(),
            SizedBox(width: SizeConfig.size6),
            Expanded(child: _buildRestaurantList()),
          ],
        ),
      ),
    );
  }

  // ── Left Category Sidebar ─────────────────────────────────────────────────

  Widget _buildCategorySidebar() {
    final categories = businessOnboardingFoodsCategories;

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: categories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        final idx = categories.indexOf(item);
        return selectedCategoryIndex.value == idx;
      },
      onTap: (item, index) {
        selectedCategoryIndex.value = index;
        _fetchStores(categoryId: item.slugId);
      },
    );
  }

  // ── Right Restaurant List ─────────────────────────────────────────────────

  Widget _buildRestaurantList() {
    return Obx(() {
      if (storeController.isAllStoreFirstLoading.value &&
          storeController.allStore.isEmpty) {
        return _buildShimmerList();
      }

      if (storeController.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(message: 'No restaurants found nearby'),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          right: SizeConfig.size8,
          bottom: SizeConfig.paddingL,
          top: SizeConfig.size8,
        ),
        itemCount: storeController.allStore.length +
            (storeController.isAllStoreLoadingMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == storeController.allStore.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _buildRestaurantCard(storeController.allStore[index]);
        },
      );
    });
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.only(
        right: SizeConfig.size8,
        bottom: SizeConfig.paddingL,
        top: SizeConfig.size8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return buildLoadingShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerContainer(height: 160, radius: 0),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      shimmerContainer(width: 36, height: 36, radius: 18),
                      const SizedBox(width: 10),
                      Expanded(child: shimmerContainer(height: 14, radius: 4)),
                      const SizedBox(width: 40),
                      shimmerContainer(width: 44, height: 22, radius: 5),
                    ],
                  ),
                  const SizedBox(height: 12),
                  shimmerContainer(width: 140, height: 10, radius: 4),
                  const SizedBox(height: 12),
                  shimmerContainer(height: 32, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool _isVeg(String subCategoryName) {
    final name = subCategoryName.toLowerCase();
    return !name.contains('non') &&
        !name.contains('meat') &&
        !name.contains('chicken') &&
        !name.contains('fish');
  }

  Widget _buildVegNonVegIcon(bool isVeg, {double size = 16}) {
    final color = isVeg ? Colors.green : Colors.red;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryGradient(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('restaurant') || name.contains('food')) {
      return [const Color(0xFFE53935), const Color(0xFFFF7043)];
    } else if (name.contains('cafe') || name.contains('coffee')) {
      return [const Color(0xFF6D4C41), const Color(0xFFA1887F)];
    } else if (name.contains('bakery') || name.contains('sweet')) {
      return [const Color(0xFFD81B60), const Color(0xFFF06292)];
    } else if (name.contains('grocery') || name.contains('veg')) {
      return [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
    } else if (name.contains('fast') || name.contains('burger')) {
      return [const Color(0xFFFF6F00), const Color(0xFFFFCA28)];
    } else if (name.contains('pizza') || name.contains('italian')) {
      return [const Color(0xFFC62828), const Color(0xFFEF5350)];
    } else if (name.contains('chinese') || name.contains('asian')) {
      return [const Color(0xFF4E342E), const Color(0xFF8D6E63)];
    } else if (name.contains('ice') || name.contains('dessert')) {
      return [const Color(0xFF7B1FA2), const Color(0xFFCE93D8)];
    } else if (name.contains('juice') || name.contains('drink')) {
      return [const Color(0xFF00838F), const Color(0xFF4DD0E1)];
    } else if (name.contains('biryani') || name.contains('north')) {
      return [const Color(0xFFBF360C), const Color(0xFFFF8A65)];
    }
    return [const Color(0xFF37474F), const Color(0xFF78909C)];
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

  // ── Restaurant Card ─────────────────────────────────────────────────────

  Widget _buildRestaurantCard(GetAllStoreResModel store) {
    final categoryName = store.categoryOfBusiness?.name ?? '';
    final subCategoryName =
        store.subCategoryOfBusiness?.name ?? 'Veg Restaurant';
    final livePhotos = (store.livePhotos ?? [])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final hasLivePhoto = livePhotos.isNotEmpty;
    final hasLogo = store.logo?.isNotEmpty ?? false;
    final totalOrders = store.views ?? '10k+';
    final categoryGradient = _getCategoryGradient(categoryName);
    final isVeg = _isVeg(subCategoryName);
    final rating = (store.avgRating ?? 0) > 0 ? '${store.avgRating}' : '4.5';

    return GestureDetector(
      onTap: () => _navigateToDetail(store),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image ──
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: hasLivePhoto
                      ? NetWorkOcToAssets(
                          imgUrl: livePhotos.first,
                          boxFit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.fillColor,
                                AppColors.greyE5,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.restaurant_menu,
                                size: 48,
                                color: AppColors.secondaryTextColor
                                    .withValues(alpha: 0.5)),
                          ),
                        ),
                ),
                // Orders badge (top-right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        CustomText(
                          '$totalOrders Orders',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                // Veg/Non-veg indicator (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildVegNonVegIcon(isVeg, size: 14),
                  ),
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
                // Live photo count (bottom-right, if multiple)
                if (livePhotos.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          CustomText(
                            '${livePhotos.length}',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Logo + Name + Rating
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fillColor,
                          border:
                              Border.all(color: AppColors.greyE5, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasLogo
                            ? NetWorkOcToAssets(
                                imgUrl: store.logo!,
                                boxFit: BoxFit.cover,
                              )
                            : Icon(Icons.store_rounded,
                                size: 18,
                                color: AppColors.secondaryTextColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              store.businessName ?? 'Restaurant',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                CustomText(
                                  subCategoryName,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondaryTextColor,
                                ),
                                if (categoryName.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor
                                            .withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: CustomText(
                                      categoryName,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryTextColor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingBadge(rating: rating)
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dotted divider
                  _buildDottedLine(),
                  const SizedBox(height: 10),

                  // Row 3: Distance + Address + View
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor
                                    .withValues(alpha: 0.08),
                                AppColors.greenCB.withValues(alpha: 0.3),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.near_me_rounded,
                                  size: 14,
                                  color: AppColors.primaryColor),
                              const SizedBox(width: 5),
                              CustomText(
                                '${calculateDistance(
                                    store.businessLocation?.lat?.toDouble() ?? 0.0,
                                    store.businessLocation?.lon?.toDouble() ?? 0.0)?.toStringAsFixed(2)} KM',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
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
                                  getLocalityAddress(store.address),
                                  fontSize: 11,
                                  color: AppColors.secondaryTextColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(22),
                        elevation: 2,
                        shadowColor:
                            AppColors.primaryColor.withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: () => RouteMapBottomSheet.show(
                            context: context,
                            destinationName: store.businessName ?? 'Restaurant',
                            destinationAddress: store.address ?? '',
                            destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
                            destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
                            livePhotos: store.livePhotos,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.directions_rounded,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(GetAllStoreResModel store) {
    if (store.id == null) return;
    Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: store.id!));
  }
}
