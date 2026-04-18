import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_contact_map_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_gallery_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_qr_code_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_testimonial_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/home_made_food_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/tiffin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/food_item_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/tiffin_bottom_sheet.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/primary_outline_button.dart';
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
  late final EarnProfileController earnProfileController;

  final RxInt _selectedFoodTab = 0.obs;

  static const _foodCategories = [
    (type: FoodCategoryType.bakery, title: 'Bakery'),
    (type: FoodCategoryType.namkeens, title: 'Namkeens'),
    (type: FoodCategoryType.sweets, title: 'Sweets'),
    (type: FoodCategoryType.pickles, title: 'Pickles'),
  ];

  static const _tiffinSlots = [
    (type: MealType.breakfast, title: 'Break-Fast', timing: '6AM - 10AM'),
    (type: MealType.morningTiffin, title: 'Morning Tiffin / Lunch', timing: '7AM - 2PM'),
    (type: MealType.eveningDinner, title: 'Evening Tiffin / Dinner', timing: '5PM - 10PM'),
  ];

  @override
  void initState() {
    super.initState();
    tiffinController = getOrPut(() => TiffinController());
    foodController = getOrPut(() => HomeMadeFoodController());
    earnProfileController = getOrPut(() => EarnProfileController());
    tiffinController.fetchAllMeals();
    foodController.fetchAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
      child: Column(
        children: [
          _buildTiffinSection(),
          _buildHomeMadeFoodSection(),
          Obx(() => EarnServiceGalleryCard(
                gallery: earnProfileController.earnProfile.value?.galleryImages,
                onAddImage: _pickAndUploadGalleryImage,
                onRemoveImage: earnProfileController.removeGalleryImage,
              )),
          EarnServiceTestimonialCard(testimonials: []),
          EarnServiceContactMapCard(
            controller: earnProfileController,
          ),
          EarnServiceQrCodeWidget(controller: earnProfileController),
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
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tiffinSlots.length,
                separatorBuilder: (_, __) => SizedBox(width: 10),
                itemBuilder: (_, i) => _buildTiffinSlotCard(_tiffinSlots[i]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTiffinSlotCard(
      ({MealType type, String title, String timing}) slot) {
    return Obx(() {
      final meal = tiffinController.mealData[slot.type]?.value;
      final hasData = meal?.hasData ?? false;
      return hasData
          ? _buildTiffinRealCard(slot, meal!)
          : _buildTiffinDummyCard(slot);
    });
  }

  Widget _buildTiffinRealCard(
      ({MealType type, String title, String timing}) slot,
      TiffinMealModel meal) {
    final imageUrl = meal.images.isNotEmpty ? meal.images.first : null;
    final mrp = double.tryParse(meal.mrpPrice) ?? 0;
    final selling = double.tryParse(meal.sellingPrice) ?? 0;
    final computed = (mrp > 0 && selling > 0 && selling < mrp)
        ? calculateDiscount(meal.sellingPrice, meal.mrpPrice)
        : null;
    final isVeg = meal.selectedFoodType.toLowerCase() == 'veg' ||
        meal.selectedFoodType.toLowerCase() == 'vegan';

    return Container(
      width: SizeConfig.screenWidth * 0.52,
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
                if (computed != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _gradientDiscountBadge('$computed% OFF'),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FoodTypeIndicator(isVegetarian: isVeg),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              (meal.selectedStartTime.isNotEmpty &&
                                      meal.selectedEndTime.isNotEmpty)
                                  ? '${meal.selectedStartTime} - ${meal.selectedEndTime}'
                                  : slot.timing,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(height: 2),
                            CustomText(
                              slot.title,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.greyE5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText('Live',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryTextColor),
                            SizedBox(width: 4),
                            CustomSwitch(
                              value: meal.isLive,
                              onChanged: (val) =>
                                  tiffinController.toggleGoLive(slot.type, val),
                              containerHeight: SizeConfig.size18,
                              containerWidth: SizeConfig.size32,
                              circleSize: SizeConfig.size14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  CustomText(
                    meal.tiffinName.isNotEmpty
                        ? meal.tiffinName
                        : '2 Idli + Sambar + Chutney',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (meal.selectedCookingMethod.isNotEmpty)
                        FoodTypeOrCookingMethod(
                          label: meal.selectedCookingMethod,
                          icon: AppIconAssets.boiled,
                        ),
                      if (meal.selectedFoodType.isNotEmpty)
                        FoodTypeOrCookingMethod(label: meal.selectedFoodType),
                    ],
                  ),
                  SizedBox(height: 8),
                  _dashedDivider(),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              '${AppConstants.rupeeSymbol}${meal.sellingPrice}',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                            ),
                            if (mrp > selling)
                              CustomText(
                                '${AppConstants.rupeeSymbol}${meal.mrpPrice}',
                                fontSize: 11,
                                color: AppColors.secondaryTextColor,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.secondaryTextColor,
                              ),
                          ],
                        ),
                      ),
                      PrimaryOutlineButton(
                        onPressed: () {
                          tiffinController.openEditSheet(meal);
                          TiffinBottomSheet.show(context, true);
                        },
                        icon: AppIconAssets.pen_line,
                        label: 'Edit',
                      ),
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

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, c) => CustomPaint(
        size: Size(c.maxWidth, 1),
        painter: _DashedLinePainter(color: AppColors.greyE5),
      ),
    );
  }

  Widget _gradientDiscountBadge(String text) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFD7845), Color(0xFFFA5568)],
            ),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: CustomText(
            text,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTiffinDummyCard(
      ({MealType type, String title, String timing}) slot) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: SizeConfig.screenWidth * 0.52,
        child: Stack(
          children: [
            _buildTiffinDummyContent(slot),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                    color: AppColors.black.withValues(alpha: 0.1)),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: PrimaryOutlineButton(
                  onPressed: () {
                    tiffinController.openCreateSheet(slot.type);
                    TiffinBottomSheet.show(context, false);
                  },
                  icon: AppIconAssets.add,
                  label: 'Add',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiffinDummyContent(
      ({MealType type, String title, String timing}) slot) {
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
            height: 130,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    width: double.infinity,
                    height: 130,
                    boxFix: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: _gradientDiscountBadge('50% OFF'),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FoodTypeIndicator(isVegetarian: true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText('Served ${slot.timing}',
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor),
                            SizedBox(height: 2),
                            CustomText(slot.title,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  CustomText('2 Idli + Sambar + Chutney',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FoodTypeOrCookingMethod(
                        label: 'Boiled',
                        icon: AppIconAssets.boiled,
                      ),
                      FoodTypeOrCookingMethod(label: 'Tiffin/Lunch'),
                    ],
                  ),
                  SizedBox(height: 8),
                  _dashedDivider(),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText('${AppConstants.rupeeSymbol}1,499',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor),
                            CustomText('${AppConstants.rupeeSymbol}98,000',
                                fontSize: 11,
                                color: AppColors.secondaryTextColor,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.secondaryTextColor),
                          ],
                        ),
                      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            _buildFoodCategoryTabs(),
            SizedBox(height: SizeConfig.size10),
            _buildFoodItems(),
          ],
        ),
      );
    });
  }

  Widget _buildFoodCategoryTabs() {
    return Obx(() => HorizontalTabSelector<({FoodCategoryType type, String title})>(
          tabs: _foodCategories,
          selectedIndex: _selectedFoodTab.value,
          labelBuilder: (cat) => cat.title,
          horizontalPadding: 16,
          verticalPadding: 6,
          horizontalMargin: 0,
          verticalMargin: 0,
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.greyE5,
          onTabSelected: (index, _) => _selectedFoodTab.value = index,
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
                : _buildFoodDummyCard(category.type),
          ),
          SizedBox(width: 8),
          Expanded(
            child: items.length >= 2
                ? _buildFoodItemCard(items[1])
                : _buildFoodDummyCard(category.type),
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
              child: Stack(
                children: [
                  Positioned.fill(
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
                  Positioned(
                    right: 10,
                    top: 10,
                    child: InkWell(
                      onTap: () {
                        foodController.openEditSheet(item);
                        FoodItemBottomSheet.show(context, true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 1.0,
                          ),
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.pen_line,
                          imgColor: AppColors.primaryColor,
                          height: 16,
                          width: 16,
                          boxFix: BoxFit.cover,
                        ),
                      ),
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

  Widget _buildFoodDummyCard(FoodCategoryType type) {
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
                  Positioned(
                    right: 10,
                    top: 10,
                    child: InkWell(
                      onTap: () {
                        foodController.openCreateSheet(type);
                        FoodItemBottomSheet.show(context, false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 1.0,
                          ),
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.add,
                          imgColor: AppColors.primaryColor,
                          height: 16,
                          width: 16,
                          boxFix: BoxFit.cover,
                        ),
                      ),
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

  Future<void> _pickAndUploadGalleryImage() async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: 'Upload Photo',
    );
    if (path == null || path.isEmpty) return;
    await earnProfileController.addGalleryImage(File(path));
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
