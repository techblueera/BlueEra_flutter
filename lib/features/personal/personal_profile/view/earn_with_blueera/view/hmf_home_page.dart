import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
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
    (type: FoodCategoryType.bakery, title: AppStrings.bakery),
    (type: FoodCategoryType.namkeens, title: AppStrings.namkeensLabel),
    (type: FoodCategoryType.sweets, title: AppStrings.sweets),
    (type: FoodCategoryType.pickles, title: AppStrings.picklesLabel),
  ];

  static const _tiffinSlots = [
    (type: MealType.breakfast, title: AppStrings.breakFastSlot, timing: AppStrings.slotTimingBreakfast),
    (type: MealType.morningTiffin, title: AppStrings.morningTiffinLunch, timing: AppStrings.slotTimingLunch),
    (type: MealType.eveningDinner, title: AppStrings.eveningTiffinDinner, timing: AppStrings.slotTimingDinner),
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
      padding: EdgeInsets.fromLTRB(
        8,
        SizeConfig.size12,
        8,
        4 * kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTiffinSection(),
          SizedBox(height: SizeConfig.size12),
          _buildHomeMadeFoodSection(),
          SizedBox(height: SizeConfig.size12),
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
        ],
      ),
    );
  }

  // ─── Tiffin Section — numbered v2 section card.
  Widget _buildTiffinSection() {
    return Obx(() {
      if (tiffinController.isLoading.value) {
        return _buildTiffinShimmer();
      }

      return _section(
        AppStrings.tiffin.tr,
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tiffinSlots.length,
            separatorBuilder: (_, __) => SizedBox(width: 10),
            itemBuilder: (_, i) => _buildTiffinSlotCard(_tiffinSlots[i]),
          ),
        ),
      );
    });
  }

  Widget _buildTiffinShimmer() {
    return _section(
      AppStrings.tiffin.tr,
      SizedBox(
        height: 300,
        child: buildLoadingShimmer(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tiffinSlots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => _tiffinShimmerCard(),
          ),
        ),
      ),
    );
  }

  Widget _tiffinShimmerCard() {
    return SizedBox(
      width: SizeConfig.screenWidth * 0.52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerContainer(height: 130),
          const SizedBox(height: 10),
          shimmerContainer(height: 12, width: 90, radius: 4),
          const SizedBox(height: 8),
          shimmerContainer(height: 16, width: 140, radius: 4),
          const SizedBox(height: 10),
          shimmerContainer(height: 12, radius: 4),
          const SizedBox(height: 8),
          shimmerContainer(height: 12, width: 110, radius: 4),
          const SizedBox(height: 14),
          Row(
            children: [
              shimmerContainer(height: 32, width: 70, radius: 6),
              const Spacer(),
              shimmerContainer(height: 32, width: 70, radius: 6),
            ],
          ),
        ],
      ),
    );
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
                                  : slot.timing.tr,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(height: 2),
                            CustomText(
                              slot.title.tr,
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
                            CustomText(AppStrings.liveLabel.tr,
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
                        : AppStrings.dummyTiffinDish.tr,
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
                        label: AppStrings.edit.tr,
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
                  label: AppStrings.add.tr,
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
                            CustomText('${AppStrings.servedPrefix.tr} ${slot.timing.tr}',
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor),
                            SizedBox(height: 2),
                            CustomText(slot.title.tr,
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
                  CustomText(AppStrings.dummyTiffinDish.tr,
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
                        label: AppStrings.boiledLabel.tr,
                        icon: AppIconAssets.boiled,
                      ),
                      FoodTypeOrCookingMethod(label: AppStrings.tiffinLunchLabel.tr),
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

  // ─── Home Made Food Section — numbered v2 section card.
  Widget _buildHomeMadeFoodSection() {
    return Obx(() {
      if (foodController.isLoading.value) {
        return _buildHomeMadeFoodShimmer();
      }

      return _section(
        AppStrings.homeMadeFoodSection.tr,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFoodCategoryTabs(),
            SizedBox(height: SizeConfig.size10),
            _buildFoodItems(),
          ],
        ),
      );
    });
  }

  Widget _buildHomeMadeFoodShimmer() {
    return _section(
      AppStrings.homeMadeFoodSection.tr,
      buildLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: shimmerContainer(height: 30, width: 70, radius: 20),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            Row(
              children: [
                Expanded(child: _foodShimmerCard()),
                const SizedBox(width: 8),
                Expanded(child: _foodShimmerCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodShimmerCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerContainer(height: SizeConfig.size170),
        const SizedBox(height: 10),
        shimmerContainer(height: 13, radius: 4),
        const SizedBox(height: 8),
        shimmerContainer(height: 12, width: 90, radius: 4),
        const SizedBox(height: 8),
        shimmerContainer(height: 14, width: 70, radius: 4),
      ],
    );
  }

  Widget _buildFoodCategoryTabs() {
    return Obx(() => HorizontalTabSelector<({FoodCategoryType type, String title})>(
          tabs: _foodCategories,
          selectedIndex: _selectedFoodTab.value,
          labelBuilder: (cat) => cat.title.tr,
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
                CustomText(AppStrings.dummyPickleDish.tr,
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
      title: AppStrings.uploadPhotoTitle.tr,
    );
    if (path == null || path.isEmpty) return;
    await earnProfileController.addGalleryImage(File(path));
  }

  // ─────────────────────────────────────────────
  // SECTION SHELL — clean white card + plain bold heading, mirroring the
  // consumer store-details screen (hmf_store_details_discover_screen).
  // ─────────────────────────────────────────────
  Widget _section(String title, Widget child, {EdgeInsetsGeometry? margin}) {
    return CustomFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeading(title),
          SizedBox(height: SizeConfig.size12),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return CustomText(
      text,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
      letterSpacing: 0.2,
    );
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
