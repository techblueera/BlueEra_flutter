import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/home_made_food_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/food_item_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodMenuManagementScreen extends StatefulWidget {
  const FoodMenuManagementScreen({super.key});

  @override
  State<FoodMenuManagementScreen> createState() =>
      _FoodMenuManagementScreenState();
}

class _FoodMenuManagementScreenState extends State<FoodMenuManagementScreen> {
  final HomeMadeFoodController controller = Get.find<HomeMadeFoodController>();

  static final _categories = [
    (
      type: FoodCategoryType.bakery,
      title: 'Bakery',
      bgColor: const Color(0xFFFCFFD7),
      image: AppIconAssets.bakeryIcon
    ),
    (
      type: FoodCategoryType.namkeens,
      title: 'Namkeens',
      bgColor: const Color(0xFFFFE8DB),
      image: AppIconAssets.bakeryIcon
    ),
    (
      type: FoodCategoryType.sweets,
      title: 'Sweets',
      bgColor: const Color(0xFFFFDBDB),
      image: AppIconAssets.bakeryIcon
    ),
    (
      type: FoodCategoryType.pickles,
      title: 'Pickles',
      bgColor: const Color(0xFFDAE8FF),
      image: AppIconAssets.bakeryIcon
    ),
  ];

  @override
  initState() {
    super.initState();
    controller.fetchAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCategoryCard(
                    context: context,
                    type: cat.type,
                    title: cat.title,
                    bgColor: cat.bgColor,
                    image: cat.image,
                  ),
                )),
            const SizedBox(height: 40 + kBottomNavigationBarHeight),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required FoodCategoryType type,
    required String title,
    required Color bgColor,
    required String image,
  }) {
    return Obx(() {
      final items = controller.categoryData[type] ?? <FoodItemModel>[].obs;

      return CustomFormCard(
        padding: const EdgeInsets.all(10.0),
        color: bgColor,
        border: Border.all(color: AppColors.greyE5),
        child: Column(
          children: [
            // ─── Header ───
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    title,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                  ),
                ),
                //  Add button — only if < 2 items
                if (controller.canAddMore(type))
                  GestureDetector(
                    onTap: () {
                      controller.openCreateSheet(type);
                      FoodItemBottomSheet.show(context, false);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add,
                            size: 16, color: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          'Add Items',
                          fontSize: SizeConfig.medium,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ─── Items ───
            // Always show 2 slots
            Row(
              children: [
                // Slot 1
                Expanded(
                  child: items.isNotEmpty
                      ? _buildItemCard(context, items[0])
                      : _buildDummyCard(context, type),
                ),
                const SizedBox(width: 8),
                // Slot 2
                Expanded(
                  child: items.length >= 2
                      ? _buildItemCard(context, items[1])
                      : _buildDummyCard(context, type),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // Dummy card — same style as tiffin
  Widget _buildDummyCard(BuildContext context, FoodCategoryType type) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      border: Border.all(color: AppColors.greyE5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blurred image
          SizedBox(
            height: SizeConfig.size170,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              child: Stack(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    height: SizeConfig.size170,
                    width: double.infinity,
                    boxFix: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                            color: AppColors.black.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 10.0,
              right: 10.0,
              top: 6.0,
              bottom: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  "Kerala Style Mango Pickle",
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDietryIndicator(isFoodCreated: false),
                    const SizedBox(width: 4),
                    _buildTag("Boiled"),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CustomText("₹99",
                        fontWeight: FontWeight.w700,
                        fontSize: 16.0,
                        color: AppColors.secondaryTextColor),
                    const SizedBox(width: 4),
                    const CustomText("₹150",
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                    const SizedBox(width: 6),
                    DiscountBadge(
                      discountText: "34% Off",
                      icon: AppIconAssets.discountTagGreyIcon,
                      borderColor:
                          AppColors.secondaryTextColor.withValues(alpha: 0.2),
                      backgroundColor:
                          AppColors.secondaryTextColor.withValues(alpha: 0.1),
                      textColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Real item card
  Widget _buildItemCard(BuildContext context, FoodItemModel item) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      border: Border.all(color: AppColors.greyE5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: SizeConfig.size170,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              child: Stack(
                children: [
                  item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          height: SizeConfig.size170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : LocalAssets(
                          imagePath: AppImageAssets.homeMadeFoodBanner,
                          height: SizeConfig.size170,
                          width: double.infinity,
                          boxFix: BoxFit.cover,
                        ),

                  Positioned(
                    right: 10,
                    top: 10,
                    child:  InkWell(
                      onTap: (){
                        controller.openEditSheet(item);
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
                  )
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 10.0,
              right: 10.0,
              top: 6.0,
              bottom: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.foodName,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDietryIndicator(isFoodCreated: true),
                    const SizedBox(width: 4),
                    if (item.cookingMethod.isNotEmpty)
                      _buildTag(item.cookingMethod),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CustomText('₹${item.sellingPrice}',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.0,
                        color: AppColors.mainTextColor),
                    const SizedBox(width: 4),
                    CustomText('₹${item.mrpPrice}',
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor),
                    const SizedBox(width: 6),
                    DiscountBadge(
                      discountText: item.discount,
                    ),
                  ],
                ),
              ],
            ),
          )

        ],
      ),
    );
  }

  Widget _buildDietryIndicator({required bool isFoodCreated}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.0),
        border: Border.all(
            color: isFoodCreated
                ? AppColors.green00
                : AppColors.secondaryTextColor,
            width: 1.0),
      ),
      padding: const EdgeInsets.all(5.0),
      child: Container(
        height: 8.0,
        width: 8.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFoodCreated
                ? AppColors.green00
                : AppColors.secondaryTextColor),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.greyE5)),
      child: Row(
        children: [
          LocalAssets(
            imagePath: AppIconAssets.boiled,
            imgColor: AppColors.secondaryTextColor,
          ),
          SizedBox(width: 4.0),
          CustomText(label,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.extraSmall),
        ],
      ),
    );
  }
}
