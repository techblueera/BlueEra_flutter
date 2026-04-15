import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/home_made_food_consumer_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/common/Discover/model/consumer_tiffin_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodNewScreen extends StatefulWidget {
  const HomeMadeFoodNewScreen({super.key});

  @override
  State<HomeMadeFoodNewScreen> createState() => _HomeMadeFoodNewScreenState();
}

class _HomeMadeFoodNewScreenState extends State<HomeMadeFoodNewScreen> {
  final controller = getOrPut(() => HomeMadeFoodConsumerController());
  final ScrollController _scrollController = ScrollController();

  // Sidebar: 0=Tiffin, 1=Bakery, 2=Sweets, 3=Namkeen, 4=Pickles
  static final List<_FoodCategory> _categories = [
    _FoodCategory('Tiffin',   AppIconAssets.morningLunchIcon),
    _FoodCategory('Bakery',   AppIconAssets.bakeryIcon),
    _FoodCategory('Sweets',   AppIconAssets.sweetsIcon),
    _FoodCategory('Namkeen',  AppIconAssets.namkeenIcon),
    _FoodCategory('Pickles',  AppIconAssets.picklesIcon),
  ];
  // Tiffin sub-tabs mapped to MealType keys
  final List<String> _tiffinFilterTabs = [
    'Break-Fast',
    'Morning Tiffin / Lunch',
    'Evening Tiffin / Dinner',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Default: tiffin category, breakfast tab
    controller.fetchAllTiffins();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    deleteIfRegistered<HomeMadeFoodConsumerController>();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.selectedCategoryIndex.value == 0) {
        controller.onTiffinScrollEnd();
      } else {
        controller.onHomeFoodScrollEnd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: 'Home Made Food',
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
        child: Column(
          children: [
            if (isIndividualUser()) ...[
              _buildPostButton(),
              SizedBox(height: SizeConfig.size4),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySidebar(),
                  SizedBox(width: SizeConfig.size4),
                  Expanded(child: _buildRightContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Post Button ──
  Widget _buildPostButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.size8,
        right: SizeConfig.size8,
        bottom: SizeConfig.size8,
        top: SizeConfig.size15,
      ),
      child: InkWell(
        onTap: () {
          if (isGuestUser()) return;
          Get.to(() => const SelfEmployeeScreen());
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomText(
              'Post Your Home Made Food',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Left Category Sidebar ──
  Widget _buildCategorySidebar() {
    return CommonGenericLeftSideCategoryList<_FoodCategory>(
      items: _categories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon,
      isSelected: (item) =>
          _categories.indexOf(item) ==
          controller.selectedCategoryIndex.value,
      onTap: (item, index) {
        controller.onCategoryChanged(index);
      },
    );
  }

  // ── Right Content ──
  Widget _buildRightContent() {
    return Obx(() {
      final catIndex = controller.selectedCategoryIndex.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiffin sub-tabs (only for index 0)
          if (catIndex == 0) _buildFilterTabs(),
          Expanded(child: _buildContentList(catIndex)),
        ],
      );
    });
  }

  Widget _buildFilterTabs() {
    return Obx(() => HorizontalTabSelector<String>(
          tabs: _tiffinFilterTabs,
          selectedIndex: controller.selectedFilterIndex.value,
          labelBuilder: (tab) => tab,
          horizontalPadding: 16,
          verticalPadding: 7,
          horizontalMargin: 0,
          verticalMargin: 8,
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.greyE5,
          onTabSelected: (index, _) => controller.onTiffinFilterChanged(index),
        ));
  }

  Widget _buildContentList(int catIndex) {
    return Obx(() {
      if (catIndex == 0) {
        // ── Tiffin ──
        if (controller.isTiffinFirstLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tiffinList.isEmpty) {
          return _emptyState('No tiffin items found.');
        }
        return _buildTiffinList();
      } else {
        // ── Food (Bakery / Sweets / Namkeen / Pickles) ──
        if (controller.isHomeFoodFirstLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.homeFoodList.isEmpty) {
          return _emptyState('No items found.');
        }
        return _buildFoodList();
      }
    });
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: EmptyStateWidget(message: message),
    );
  }

  // ── Tiffin List ──
  Widget _buildTiffinList() {
    return Obx(() {
      final items = controller.tiffinList;
      final showLoader = controller.isTiffinLoadingMore.value;

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(right: SizeConfig.size8, bottom: 20),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _buildTiffinCard(items[index]);
        },
      );
    });
  }

  Widget _buildTiffinCard(ConsumerTiffinItem meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Center name header ──
          if (meal.centerName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 10, bottom: 0),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront,
                    size: 15,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: CustomText(
                      meal.centerName,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Main content row ──
          Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: meal.centerName.isNotEmpty ? 8 : 10,
              bottom: 10,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: meal.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: meal.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        _placeholderIcon(),
                                  )
                                : _placeholderIcon(),
                          ),
                        ),
                        _buildVegIcon(meal.foodType),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiffin name
                          CustomText(
                            meal.tiffinName,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(height: 6),

                          // Price
                          PriceRow(
                            sellingPrice: '\u20B9${meal.sellingPrice}',
                            mrp: '\u20B9${meal.mrpPrice}',
                            discount:
                                '${calculateDiscount(meal.sellingPrice, meal.mrpPrice)}% Off',
                          ),
                          const SizedBox(height: 8),

                          // Tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (meal.cookingMethod.isNotEmpty)
                                FoodTypeOrCookingMethod(
                                  label: meal.cookingMethod,
                                  icon: AppIconAssets.boiled,
                                ),
                              if (meal.startTime.isNotEmpty)
                                FoodTypeOrCookingMethod(
                                  label: '${meal.startTime} - ${meal.endTime}',
                                  icon: AppIconAssets.storeWatch,
                                ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primaryColor, width: 1.2),
                    ),
                    child: CustomText(
                      'ADD',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Food List (Bakery, Sweets, Namkeen, Pickles) ──
  Widget _buildFoodList() {
    return Obx(() {
      final items = controller.homeFoodList;
      final showLoader = controller.isHomeFoodLoadingMore.value;

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(right: SizeConfig.size8, bottom: 20),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _buildFoodCard(items[index]);
        },
      );
    });
  }

  Widget _buildFoodCard(FoodItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => _placeholderIcon(),
                          )
                        : _placeholderIcon(),
                  ),
                ),
                _buildVegIcon(item.foodType),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.foodName,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      CustomText(
                        '\u20B9${item.sellingPrice}',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        '\u20B9${item.mrpPrice}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                      if (item.discount.isNotEmpty)
                        DiscountBadge(discountText: item.discount),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.cookingMethod.isNotEmpty)
                        FoodTypeOrCookingMethod(
                          label: item.cookingMethod,
                          icon: AppIconAssets.boiled,
                        ),
                      if (item.foodType.isNotEmpty)
                        FoodTypeOrCookingMethod(
                          label: item.cookingMethod,
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primaryColor, width: 1.2),
                      ),
                      child: CustomText(
                        'ADD',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ──

  Widget _placeholderIcon() {
    return Container(
      width: 100,
      height: 100,
      color: const Color(0xFFF5E6C8),
      child: Icon(Icons.lunch_dining, size: 40, color: Colors.orange.shade300),
    );
  }

  Widget _buildVegIcon(String foodType) {
    final bool isVeg = foodType.toLowerCase() == 'veg' ||
        foodType.toLowerCase() == 'vegan';
    final Color color = isVeg ? Colors.green : Colors.red;

    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }


}

class _FoodCategory {
  final String name;
  final String icon;
  const _FoodCategory(this.name, this.icon);
}
