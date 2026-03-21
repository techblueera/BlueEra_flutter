import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Store listing screen for riders to browse and send link requests.
/// Same layout as GroceryOrFoodStoresScreen but:
///  - No "Recently Visited" in the left sidebar
///  - Each store card has a "Send Request" button
class RiderLinkStoresScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> arrCategories;
  final OnboardingCategoryModel selectedCategory;
  final bool isGroceryStore;

  const RiderLinkStoresScreen({
    super.key,
    required this.arrCategories,
    required this.selectedCategory,
    required this.isGroceryStore,
  });

  @override
  State<RiderLinkStoresScreen> createState() => _RiderLinkStoresScreenState();
}

class _RiderLinkStoresScreenState extends State<RiderLinkStoresScreen> {
  final controller = getOrPut(() => NewStoreController());
  final ScrollController _scrollController = ScrollController();

  final List<Color> _cardColors = const [
    Color(0xFFFFFEF7),
    Color(0xFFFFF9F3),
    Color(0xFFFFF5F5),
  ];

  @override
  void initState() {
    super.initState();

    controller.typeOfBusiness =
        widget.isGroceryStore ? BusinessType.Grocery.name : BusinessType.Food.name;
    controller.selectedGroceryOrFoodCategoryData.value = widget.selectedCategory;
    controller.businessCategoryId =
        controller.selectedGroceryOrFoodCategoryData.value?.slugId;

    controller.getAllStoreNearBy();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isGroceryStore ? 'Grocery & Stationary' : 'Restaurant & Food',
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeftCategoryList(),
            SizedBox(width: SizeConfig.size6),
            Expanded(child: _buildRightContent()),
          ],
        ),
      ),
    );
  }

  // ─── Left sidebar (NO "Recently Visited") ──────────────────────

  Widget _buildLeftCategoryList() {
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: widget.arrCategories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        return controller.selectedGroceryOrFoodCategoryData.value?.slugId ==
            item.slugId;
      },
      onTap: (item, index) {
        controller.selectedGroceryOrFoodCategoryData.value = item;
        controller.businessCategoryId = item.slugId;
        controller.getAllStoreNearBy();
      },
    );
  }

  // ─── Right store list with "Send Request" button ───────────────

  Widget _buildRightContent() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: 'No ${controller.businessCategoryId} found',
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        itemCount: controller.allStore.length +
            (controller.isAllStoreLoadingMore.value ? 1 : 0),
        shrinkWrap: true,
        padding: EdgeInsets.only(
          top: SizeConfig.paddingM,
          bottom: SizeConfig.paddingL,
          right: SizeConfig.paddingXS,
        ),
        itemBuilder: (_, index) {
          if (index == controller.allStore.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final store = controller.allStore[index];
          final bgColor = _cardColors[index % _cardColors.length];

          return _LinkStoreCard(
            store: store,
            bgColor: bgColor,
            onSendRequest: () => _handleSendRequest(store),
          );
        },
      );
    });
  }

  void _handleSendRequest(GetAllStoreResModel store) {
    // TODO: Call your link-request API here
    commonSnackBar(
      message: 'Request sent to ${store.businessName ?? 'store'}',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORE CARD WITH "SEND REQUEST" BUTTON
//  Same as StoreCard but replaces the InkWell tap-to-navigate
//  with a "Send Request" button at the bottom.
// ═══════════════════════════════════════════════════════════════════

class _LinkStoreCard extends StatelessWidget {
  final GetAllStoreResModel store;
  final Color bgColor;
  final VoidCallback onSendRequest;

  const _LinkStoreCard({
    required this.store,
    required this.bgColor,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bgColor,
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Logo & Name ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedAvatarWidget(
                      imageUrl: store.logo ?? '',
                      size: SizeConfig.size40,
                      borderColor: Colors.white,
                      borderRadius: SizeConfig.size20,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            store.businessName ?? 'Unknown Business',
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(height: SizeConfig.size6),
                          Row(
                            children: [
                              _ratingBadge(store.avgRating.toString()),
                              const SizedBox(width: 6),
                              _categoryBadge(
                                  store.subCategoryOfBusiness?.name ??
                                      AppStrings.na),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.paddingXSL),

                // ─── Address & Distance ───
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      _iconContainer(AppIconAssets.location_outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              '${calculateDistanceKm(
                                LocationService.lat,
                                LocationService.lng,
                                store.businessLocation?.lat?.toDouble() ?? 0.0,
                                store.businessLocation?.lon?.toDouble() ?? 0.0,
                              ).toStringAsFixed(2)} Km Away',
                              fontSize: 13,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              store.address ?? AppStrings.na,
                              fontSize: 11,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size6),

                // ─── Stats ───
                Row(
                  children: [
                    _statBox(
                      icon: AppIconAssets.staggeredIcon,
                      count: '${store.totalCategoryCount}',
                      label: 'Category',
                      iconColor: const Color(0xFF9964F4),
                      bgColor: AppColors.purpleFD,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    _statBox(
                      icon: AppIconAssets.productCartIcon,
                      count: '${store.totalProductCount}',
                      label: 'Product',
                      iconColor: const Color(0xFF6179CD),
                      bgColor: AppColors.purpleFF,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Quirky Message ───
          if (store.quirkyMessage != null &&
              store.quirkyMessage!.isNotEmpty) ...[
            const Divider(height: 0.5, color: AppColors.greyE5),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: CustomText(
                  store.quirkyMessage!,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          // ─── Send Request Button ───
          const Divider(height: 0.5, color: AppColors.greyE5),
          InkWell(
            onTap: onSendRequest,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded,
                      size: 16, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  CustomText(
                    'Send Request',
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers (same as StoreCard) ───────────────────────────────

  Widget _ratingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.lightYellowShade,
        border: Border.all(color: AppColors.lightYellowShade, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(rating,
              fontSize: 10,
              color: AppColors.blue2D,
              fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _categoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.greenCB,
        border: Border.all(color: AppColors.greenCB, width: 0.5),
      ),
      child: CustomText(text,
          fontSize: 10,
          color: AppColors.green2C,
          fontWeight: FontWeight.w400),
    );
  }

  Widget _statBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(6)),
              child: LocalAssets(
                  imagePath: icon,
                  imgColor: iconColor,
                  height: 18,
                  width: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(count,
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600),
                  CustomText(label,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: LocalAssets(
        imagePath: iconPath,
        imgColor: AppColors.secondaryTextColor,
        height: 24,
        width: 20,
      ),
    );
  }
}
