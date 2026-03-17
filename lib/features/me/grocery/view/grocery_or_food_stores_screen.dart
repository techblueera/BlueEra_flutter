import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_enum.dart';

class GroceryOrFoodStoresScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> arrCategories;
  final OnboardingCategoryModel selectedGroceryOrFoodCategory;
  final bool isGroceryStore;

  const GroceryOrFoodStoresScreen(
      { super.key,
        required this.arrCategories,
        required this.selectedGroceryOrFoodCategory,
        required this.isGroceryStore,
        });

  @override
  State<GroceryOrFoodStoresScreen> createState() =>
      _GroceryOrFoodStoresScreenState();
}

class _GroceryOrFoodStoresScreenState extends State<GroceryOrFoodStoresScreen> {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
  final foodCustomerListingScreen = getOrPut(() => FoodCustomerController());
  final ScrollController storesScrollController = ScrollController();
  late List<OnboardingCategoryModel> _arrCategories;
  final List<Color> cardColors = [
    const Color(0xFFFFFEF7), // Soft Cream
    const Color(0xFFFFF9F3), // Pale Peach
    const Color(0xFFFFF5F5), // Light Rose
  ];

  @override
  initState() {
    super.initState();

    if(widget.isGroceryStore){
      controller.typeOfBusiness = BusinessType.Grocery.name;
    }else{
      controller.typeOfBusiness = BusinessType.Food.name;
    }

    controller.selectedGroceryOrFoodCategoryData.value =
        widget.selectedGroceryOrFoodCategory;
    _arrCategories = widget.arrCategories;
    controller.businessCategoryId = controller.selectedGroceryOrFoodCategoryData.value?.slugId;

    controller.getAllStoreNearBy();

    // Listener for Pagination
    controller.addListener(_onLoadMore);
  }

  void _onLoadMore(){
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isGroceryStore
            ? 'Grocery & Stationary'
            : 'Restaurant & Food',
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftCategoryList(),
            SizedBox(
              width: SizeConfig.size6,
            ),
            Expanded(
                child: rightContent()
            ),
          ],
        )
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = OnboardingCategoryModel(
      name: 'Recently Visited',
      slugId: 'RECENTLY_VISITED',
      icon: AppImageAssets.all,
      accountType: AppConstants.business,
    );

    final fullList = [allItem, ..._arrCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        if (item.slugId == 'RECENTLY_VISITED') {
          return controller.selectedGroceryOrFoodCategoryData.value == null;
        }
        return controller.selectedGroceryOrFoodCategoryData.value?.slugId == item.slugId;
      },
      onTap: (item, index) {
        if (item.slugId == 'RECENTLY_VISITED') {
          controller.selectedGroceryOrFoodCategoryData.value = null;
        } else {
          controller.selectedGroceryOrFoodCategoryData.value = item;
        }
        controller.businessCategoryId = item.slugId;

        // Single API Call (Clean & Shared)
        controller.getAllStoreNearBy();
      },
    );
  }
  
  Widget rightContent() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
            child: EmptyStateWidget(message: "No ${controller.businessCategoryId} found"));
      }

      return ListView.builder(
          controller: storesScrollController,
          itemCount: controller.allStore.length +
              (controller.isAllStoreLoadingMore.value ? 1 : 0),
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: SizeConfig.paddingM,
              bottom: SizeConfig.paddingL,
            right: SizeConfig.paddingXS,
          ),
          itemBuilder: (context, index) {
            final Color bgColor = cardColors[index % cardColors.length];

            if (index == controller.allStore.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            var store = controller.allStore[index];

            return groceryStoreCard(
                store,
                bgColor
            );
          });
    });
  }

  Widget groceryStoreCard(GetAllStoreResModel store, Color bgColor) {
    return InkWell(
      onTap: (){
        if(widget.isGroceryStore){
          Get.toNamed(
              RouteHelper.getOtherGroceryStoreScreenRoute(),
              arguments: {
                ApiKeys.userId: store.userId,
                ApiKeys.businessId: store.id,
              }
          );
        } else{
          Get.toNamed(
              RouteHelper.getOtherFoodStoreDetailsScreenRoute(),
              arguments: {
                ApiKeys.businessId: store.id,
              }
          );
        }
      },
      child: Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: bgColor,
          border: Border.all(
              color: AppColors.greyE5,
              width: 0.5
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                _buildRatingBadge(store.avgRating.toString()),
                                const SizedBox(width: 6), // Added spacing
                                _buildCategoryBadge(store.subCategoryOfBusiness?.name ?? AppStrings.na),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  // Address & Distance
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 0.5),
                      color: AppColors.white,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIconContainer(AppIconAssets.location_outline),
                        SizedBox(width: 10),
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
                                fontSize: 13.0,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: SizeConfig.size4),
                              CustomText(
                                store.address ?? AppStrings.na,
                                fontSize: 11.0,
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

                  // Category & Product Stats
                  Row(
                    children: [
                      _buildStatBox(
                        icon: AppIconAssets.staggeredIcon,
                        count: '${store.totalCategoryCount}',
                        label: 'Category',
                        iconColor: const Color(0xFF9964F4),
                        bgColor: AppColors.purpleFD,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _buildStatBox(
                        icon: AppIconAssets.productCartIcon,
                        count: '${store.totalProductCount}',
                        label: 'Product',
                        iconColor: const Color(0xFF6179CD),
                        bgColor: AppColors.purpleFF,
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Last Visit Footer
            if(store.quirkyMessage!=null)...[
              const Divider(height: 0.5, color: AppColors.greyE5),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CustomText(
                    store.quirkyMessage,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ]

          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.lightYellowShade,
        border: Border.all(color: AppColors.lightYellowShade, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(rating, fontSize: 10, color: AppColors.blue2D, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.greenCB,
        border: Border.all(color: AppColors.greenCB, width: 0.5),
      ),
      child: CustomText(text, fontSize: 10, color: AppColors.green2C, fontWeight: FontWeight.w400),
    );
  }

  Widget _buildStatBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppColors.greyE5, width: 0.5),
            color: AppColors.white,
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6.0)),
              child: LocalAssets(
                  imagePath: icon,
                  imgColor: iconColor, height: 18, width: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(count, fontSize: SizeConfig.medium, color: AppColors.secondaryTextColor, fontWeight: FontWeight.w600),
                  CustomText(label, fontSize: SizeConfig.extraSmall, color: AppColors.secondaryTextColor, fontWeight: FontWeight.w400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.08), offset: const Offset(0, 1), blurRadius: 2.0)
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

