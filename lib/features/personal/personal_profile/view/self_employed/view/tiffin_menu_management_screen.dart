import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/tiffin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/tiffin_bottom_sheet.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/primary_outline_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TiffinMenuManagementScreen extends StatefulWidget {
  TiffinMenuManagementScreen({super.key});

  @override
  State<TiffinMenuManagementScreen> createState() =>
      _TiffinMenuManagementScreenState();
}

class _TiffinMenuManagementScreenState
    extends State<TiffinMenuManagementScreen> {
  final TiffinController controller = Get.find<TiffinController>();

  @override
  initState() {
    super.initState();
    controller.fetchAllMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              _buildHeaderInput(),
              const SizedBox(height: 16),
              _buildMealCategoryCard(
                context: context,
                mealType: MealType.breakfast,
                title: "Break-Fast",
                timing: "Served 6AM - 10AM",
                bgColor: const Color(0xFFFFF5EE),
                image: AppIconAssets.morningLunchIcon,
              ),
              const SizedBox(height: 10),
              _buildMealCategoryCard(
                context: context,
                mealType: MealType.morningTiffin,
                title: "Morning Tiffin / Lunch",
                timing: "Served 7AM - 2PM",
                bgColor: const Color(0xFFFCFFD7),
                image: AppIconAssets.morningBreakfastIcon,
              ),
              const SizedBox(height: 10),
              _buildMealCategoryCard(
                context: context,
                mealType: MealType.eveningDinner,
                title: "Evening Tiffin / Dinner",
                timing: "Served 5PM - 10PM",
                bgColor: const Color(0xFFF0F8FF),
                image: AppIconAssets.nightDinnerIcon,
              ),
              const SizedBox(height: 40 + kBottomNavigationBarHeight),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMealCategoryCard({
    required BuildContext context,
    required MealType mealType,
    required String title,
    required String timing,
    required Color bgColor,
    required String image,
  }) {
    return Obx(() {
      final meal = controller.mealData[mealType]?.value;

      final displayTiming = (meal != null &&
              meal.hasData &&
              meal.selectedStartTime.isNotEmpty &&
              meal.selectedEndTime.isNotEmpty)
          ? 'Served ${meal.selectedStartTime} - ${meal.selectedEndTime}'
          : timing;
      return CustomFormCard(
        padding: const EdgeInsets.all(10.0),
        color: bgColor,
        border: Border.all(color: AppColors.greyE5),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                LocalAssets(
                    imagePath: image,
                    height: SizeConfig.size40,
                    width: SizeConfig.size40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(title,
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor),
                      const SizedBox(height: 2.0),
                      CustomText(displayTiming,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.greyE5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 10.0),
                  child: Row(
                    children: [
                      const CustomText("Go Live",
                          fontWeight: FontWeight.w600,
                          fontSize: 12.0,
                          color: AppColors.secondaryTextColor),
                      const SizedBox(width: 5.0),
                      CustomSwitch(
                        value: meal?.isLive ?? false,
                        onChanged: (val) {
                          if (meal?.hasData == true) {
                            controller.toggleGoLive(mealType, val);
                          }
                        },
                        containerHeight: SizeConfig.size22,
                        containerWidth: SizeConfig.size40,
                        circleSize: SizeConfig.size18,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (meal == null || !meal.hasData)
              _buildDummyCard(context, mealType)
            else
              _buildProductItemCard(context, meal),
          ],
        ),
      );
    });
  }

  // Dummy card — shown before any meal is created
  Widget _buildDummyCard(BuildContext context, MealType mealType) {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppColors.greyE5),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dummy blurred image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    height: 120,
                    width: 100,
                    boxFix: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                            color: AppColors.black.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  _buildDietryIndicator(isMealCreated: false),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    "2 Idli + Sambar + Chutney",
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FoodTypeOrCookingMethod(
                        label: 'Boiled',
                        icon: AppIconAssets.boiled,
                      ),
                      const SizedBox(width: 6),
                      FoodTypeOrCookingMethod(
                        label: 'Tiffin/Lunch',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CustomText("₹159",
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.0,
                                    color: AppColors.secondaryTextColor),
                                SizedBox(width: 4),
                                CustomText(
                                  "₹200",
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12.0,
                                  color: AppColors.secondaryTextColor,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.secondaryTextColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DiscountBadge(
                              discountText: "20% Off",
                              icon: AppIconAssets.discountTagGreyIcon,
                              borderColor: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.2),
                              backgroundColor: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.1),
                              // iconColor: AppColors.secondaryTextColor,
                              textColor: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      //  Create button
                      PrimaryOutlineButton(
                        onPressed: () {
                          controller.openCreateSheet(mealType);
                          TiffinBottomSheet.show(context, false);
                        },
                        icon: AppIconAssets.add,
                        label: 'Create',
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

  // Real card — shown after meal is created/fetched from API
  Widget _buildProductItemCard(BuildContext context, TiffinMealModel meal) {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppColors.greyE5),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  meal.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: meal.imageUrl!,
                          height: 120,
                          width: 100,
                          fit: BoxFit.cover)
                      : LocalAssets(
                          imagePath: AppImageAssets.homeMadeFoodBanner,
                          height: 120,
                          width: 100,
                          boxFix: BoxFit.cover),
                  _buildDietryIndicator(isMealCreated: true),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    meal.tiffinName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (meal.selectedCookingMethod.isNotEmpty)
                        FoodTypeOrCookingMethod(
                          label: meal.selectedCookingMethod,
                          icon: AppIconAssets.boiled,
                        ),
                      if (meal.selectedFoodType.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        FoodTypeOrCookingMethod(
                          label: meal.selectedFoodType,
                          icon: AppIconAssets.boiled,
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomText('₹${meal.sellingPrice}',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.0,
                                    color: AppColors.mainTextColor),
                                const SizedBox(width: 4),
                                CustomText('₹${meal.mrpPrice}',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12.0,
                                    color: AppColors.secondaryTextColor,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor:
                                        AppColors.secondaryTextColor),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DiscountBadge(
                              discountText:
                                  "${calculateDiscount(meal.sellingPrice, meal.mrpPrice)}% ${AppStrings.off.tr}",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      //  Edit button — prefill form with real data
                      PrimaryOutlineButton(
                        onPressed: () {
                          controller.openEditSheet(meal);
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
          ],
        ),
      ),
    );
  }

  Widget _buildDietryIndicator({required bool isMealCreated}) {
    return Positioned(
      left: 6.0,
      top: 6.0,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0), color: AppColors.white),
        padding: const EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.0),
            border: Border.all(
                color: isMealCreated ? AppColors.green00 : AppColors.greyE0,
                width: 1.0),
          ),
          padding: const EdgeInsets.all(2.0),
          child: Container(
            height: 8.0,
            width: 8.0,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMealCreated ? AppColors.green00 : AppColors.greyE0),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInput() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Name Of Food Centre',
            fontWeight: FontWeight.w400,
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.medium,
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final isSaved   = controller.isCenterNameAvailable.value;
                  final isEditing = controller.isCenterNameEditing.value;

                  return CommonTextField(
                    hintText: "E.g. Gupta Food Centre",
                    textEditController: controller.foodCenterController,
                    //  read only when saved and not editing
                    readOnly: isSaved && !isEditing,
                    sIcon: isSaved && !isEditing
                    //  Edit icon — tap to enable editing
                        ? InkWell(
                      onTap: controller.enableCenterNameEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LocalAssets(
                          imagePath: AppIconAssets.pen_line,
                          imgColor: AppColors.primaryColor,
                        ),
                      ),
                    )
                        : isSaved && isEditing
                    //  green tick when saved and not editing
                        ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LocalAssets(
                       imagePath: AppIconAssets.green_tick_rounded,
                      ),
                    )
                        : null,
                  );
                }),
              ),
              const SizedBox(width: 10),

              Obx(() {
                final isSaved   = controller.isCenterNameAvailable.value;
                final isEditing = controller.isCenterNameEditing.value;

                //  hide button when saved and not editing
                if (isSaved && !isEditing) return const SizedBox.shrink();

                return CustomBtn(
                  width:     SizeConfig.size90,
                  height:    SizeConfig.size40,
                  title:     controller.isCenterLoading.value
                      ? null
                      : isEditing ? 'Update' : 'Submit',
                  onTap:     controller.submitCenterName,
                  bgColor: AppColors.primaryColor,
                  radius:    10,
                  isLoading: controller.isCenterLoading.value,
                );
              }),
            ],
          ),

          //  status label
          Obx(() {
            final isSaved   = controller.isCenterNameAvailable.value;
            final isEditing = controller.isCenterNameEditing.value;

            if (!isSaved) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(top: SizeConfig.size6),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_outlined : Icons.check_circle,
                    size: 13,
                    color: isEditing ? AppColors.primaryColor : Colors.green,
                  ),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    isEditing ? 'Editing centre name...' : 'Food centre name saved',
                    fontSize: SizeConfig.small,
                    color: isEditing ? AppColors.primaryColor : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
