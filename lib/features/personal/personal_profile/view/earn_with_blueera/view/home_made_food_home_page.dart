import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_contact_map_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_gallery_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_qr_code_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_stats.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_testimonial_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/home_made_food_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/tiffin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodHomePage extends StatefulWidget {
  const HomeMadeFoodHomePage({super.key});

  @override
  State<HomeMadeFoodHomePage> createState() => _HomeMadeFoodHomePageState();
}

class _HomeMadeFoodHomePageState extends State<HomeMadeFoodHomePage> {
  late final TiffinController tiffinController;
  late final HomeMadeFoodController foodController;

  final RxInt _selectedFoodTab = 0.obs;

  static const _foodCategories = [
    (type: FoodCategoryType.bakery, title: 'Bakery'),
    (type: FoodCategoryType.namkeens, title: 'Namkeens'),
    (type: FoodCategoryType.sweets, title: 'Sweets'),
    (type: FoodCategoryType.pickles, title: 'Pickles'),
  ];

  @override
  void initState() {
    super.initState();
    tiffinController = getOrPut(() => TiffinController());
    foodController = getOrPut(() => HomeMadeFoodController());
    tiffinController.fetchAllMeals();
    foodController.fetchAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
      child: Column(
        children: [
          EarnServiceProfileHeader(
            serviceName: 'Rahul Tiffin Centre',
            serviceCategory: 'Tiffin Service',
            isFoodProfile: true,
            foodType: 'Veg',
            rating: 4.5,
            totalRatings: 120,
            address: 'Lucknow, Uttar Pradesh',
          ),
          EarnServiceStats(
            totalViews: 1200,
            totalInquiries: 25,
            totalFollowers: 340,
            totalFollowing: 56,
          ),
          _buildTiffinSection(),
          _buildHomeMadeFoodSection(),
          EarnServiceGalleryCard(
            gallery: null,
            onEditTap: () {},
            onAddTap: () {},
          ),
          EarnServiceTestimonialCard(testimonials: []),
          EarnServiceContactMapCard(
            serviceName: 'Rahul Tiffin Centre',
            address: 'Lucknow, Uttar Pradesh',
            description: 'Home made food service providing fresh and hygienic meals.',
          ),
          EarnServiceQrCodeWidget(
            serviceName: 'Rahul Tiffin Centre',
            serviceCategory: 'Tiffin Service',
          ),
          SizedBox(height: SizeConfig.size100),
        ],
      ),
    );
  }

  // ─── Tiffin Section ────────────────────────────────────────────
  Widget _buildTiffinSection() {
    return Obx(() {
      if (tiffinController.isLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final meals = <TiffinMealModel>[];
      for (final type in MealType.values) {
        final meal = tiffinController.mealData[type]?.value;
        if (meal != null && meal.hasData) meals.add(meal);
      }

      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Tiffin',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: 260,
              child: meals.isEmpty
                  ? _buildTiffinDummyList()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: meals.length,
                      separatorBuilder: (_, __) => SizedBox(width: 10),
                      itemBuilder: (_, i) => _buildTiffinCard(meals[i]),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTiffinDummyList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 2,
      separatorBuilder: (_, __) => SizedBox(width: 10),
      itemBuilder: (_, __) => _buildTiffinDummyCard(),
    );
  }

  Widget _buildTiffinCard(TiffinMealModel meal) {
    final imageUrl = meal.images.isNotEmpty ? meal.images.first : null;
    final mrp = double.tryParse(meal.mrpPrice) ?? 0;
    final selling = double.tryParse(meal.sellingPrice) ?? 0;
    final discount = (mrp > 0 && selling > 0 && selling < mrp)
        ? '${((mrp - selling) / mrp * 100).toStringAsFixed(0)}% Off'
        : '';
    final timing = (meal.selectedStartTime.isNotEmpty && meal.selectedEndTime.isNotEmpty)
        ? '${meal.selectedStartTime} - ${meal.selectedEndTime}'
        : '';

    return Container(
      width: SizeConfig.screenWidth * 0.44,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with discount badge
          SizedBox(
            height: 130,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 130,
                          fit: BoxFit.cover,
                        )
                      : LocalAssets(
                          imagePath: AppImageAssets.homeMadeFoodBanner,
                          width: double.infinity,
                          height: 130,
                          boxFix: BoxFit.cover,
                        ),
                ),
                if (discount.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DiscountBadge(discountText: discount),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          _mealTypeLabel(meal.mealType),
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (meal.isLive)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.green00.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText('Live',
                              fontSize: 10,
                              color: AppColors.green00,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  CustomText(
                    meal.tiffinName.isNotEmpty ? meal.tiffinName : '2 Idli + Sambar + Chutney',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Row(
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${meal.sellingPrice}',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      if (mrp > selling) ...[
                        SizedBox(width: 4),
                        CustomText(
                          '${AppConstants.rupeeSymbol}${meal.mrpPrice}',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiffinDummyCard() {
    return Container(
      width: SizeConfig.screenWidth * 0.44,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    boxFix: BoxFit.cover,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(color: AppColors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DiscountBadge(
                      discountText: '50% Off',
                      borderColor: AppColors.secondaryTextColor.withValues(alpha: 0.2),
                      backgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                      textColor: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText('Morning Tiffin / Lunch',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor),
                  SizedBox(height: 4),
                  CustomText('2 Idli + Sambar + Chutney + Lorem Ipsum',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Spacer(),
                  Row(
                    children: [
                      CustomText('${AppConstants.rupeeSymbol}1,499',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor),
                      SizedBox(width: 4),
                      CustomText('${AppConstants.rupeeSymbol}98,000',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Break-Fast';
      case MealType.morningTiffin:
        return 'Morning Tiffin / Lunch';
      case MealType.eveningDinner:
        return 'Evening Tiffin / Dinner';
    }
  }

  // ─── Home Made Food Section ────────────────────────────────────
  Widget _buildHomeMadeFoodSection() {
    return Obx(() {
      if (foodController.isLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Home Made Food',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            // Category tabs
            _buildFoodCategoryTabs(),
            SizedBox(height: SizeConfig.size10),
            // Items for selected category
            _buildFoodItems(),
          ],
        ),
      );
    });
  }

  Widget _buildFoodCategoryTabs() {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_foodCategories.length, (i) {
              final isSelected = _selectedFoodTab.value == i;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _selectedFoodTab.value = i,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyE5,
                      ),
                    ),
                    child: CustomText(
                      _foodCategories[i].title,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.mainTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ));
  }

  Widget _buildFoodItems() {
    return Obx(() {
      final category = _foodCategories[_selectedFoodTab.value];
      final items = foodController.categoryData[category.type] ?? <FoodItemModel>[].obs;

      return Row(
        children: [
          Expanded(
            child: items.isNotEmpty
                ? _buildFoodItemCard(items[0])
                : _buildFoodDummyCard(),
          ),
          SizedBox(width: 8),
          Expanded(
            child: items.length >= 2
                ? _buildFoodItemCard(items[1])
                : _buildFoodDummyCard(),
          ),
        ],
      );
    });
  }

  Widget _buildFoodItemCard(FoodItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: SizeConfig.size170,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : LocalAssets(
                      imagePath: AppImageAssets.homeMadeFoodBanner,
                      boxFix: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.foodName,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    FoodTypeIndicator(
                      isVegetarian: item.foodType.toLowerCase() == 'veg',
                    ),
                    SizedBox(width: 4),
                    if (item.cookingMethod.isNotEmpty)
                      FoodTypeOrCookingMethod(
                        label: item.cookingMethod,
                        icon: AppIconAssets.boiled,
                      ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}${item.sellingPrice}',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: 4),
                    CustomText(
                      '${AppConstants.rupeeSymbol}${item.mrpPrice}',
                      fontSize: 11,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                    if (item.discount.isNotEmpty) ...[
                      SizedBox(width: 6),
                      DiscountBadge(discountText: item.discount),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDummyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: SizeConfig.size170,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    boxFix: BoxFit.cover,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(color: AppColors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText('Kerala Style Mango Pickle...',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 6),
                Row(
                  children: [
                    FoodTypeOrCookingMethod(
                      label: 'Boiled',
                      icon: AppIconAssets.boiled,
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    CustomText('${AppConstants.rupeeSymbol}1,499',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor),
                    SizedBox(width: 4),
                    CustomText('${AppConstants.rupeeSymbol}98,000',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                    SizedBox(width: 6),
                    DiscountBadge(
                      discountText: '50% Off',
                      borderColor: AppColors.secondaryTextColor.withValues(alpha: 0.2),
                      backgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                      textColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
