import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodNewScreen extends StatefulWidget {
  const HomeMadeFoodNewScreen({super.key});

  @override
  State<HomeMadeFoodNewScreen> createState() => _HomeMadeFoodNewScreenState();
}

class _HomeMadeFoodNewScreenState extends State<HomeMadeFoodNewScreen> {
  final RxInt selectedCategoryIndex = 0.obs;
  final RxInt selectedFilterIndex = 0.obs;

  final List<String> _categories = [
    'Tiffin',
    'Breakfast',
    'Bakery',
    'Sweets',
    'Namkeen',
    'Pickles',
    'Others',
  ];

  final List<IconData> _categoryIcons = [
    Icons.lunch_dining_rounded,
    Icons.free_breakfast_rounded,
    Icons.cake_rounded,
    Icons.cookie_rounded,
    Icons.tapas_rounded,
    Icons.local_grocery_store_rounded,
    Icons.more_horiz_rounded,
  ];

  final List<String> _filterTabs = ['All', 'Morning Tiffin', 'Evening Tiffin'];

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
            _buildPostButton(),
            SizedBox(height: SizeConfig.size4),
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
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      child: InkWell(
        onTap: () {
          if (isGuestUser()) return;
          Get.to(() => const EarnServiceScreen());
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
    return Container(
      width: 72,
      color: AppColors.white,
      child: Obx(() {
        final selectedIdx = selectedCategoryIndex.value;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = selectedIdx == index;
            return GestureDetector(
              onTap: () => selectedCategoryIndex.value = index,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryColor.withValues(alpha: 0.15)
                            : AppColors.fillColor,
                      ),
                      child: Icon(
                        _categoryIcons[index],
                        size: 22,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    CustomText(
                      _categories[index],
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.secondaryTextColor,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Right Content ──

  Widget _buildRightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTabs(),
        const SizedBox(height: 8),
        Expanded(child: _buildFoodList()),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 34,
      child: Obx(() {
        final selected = selectedFilterIndex.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          itemCount: _filterTabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isSelected = selected == index;
            return GestureDetector(
              onTap: () => selectedFilterIndex.value = index,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryColor : AppColors.greyE5,
                    width: 1,
                  ),
                ),
                child: CustomText(
                  _filterTabs[index],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.mainTextColor,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Food List (static) ──

  Widget _buildFoodList() {
    return ListView.builder(
      padding: EdgeInsets.only(right: SizeConfig.size8, bottom: 20),
      itemCount: 8,
      itemBuilder: (context, index) => _buildFoodItemCard(),
    );
  }

  // ── Food Item Card ──

  Widget _buildFoodItemCard() {
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
            // ── Food Image ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFF5E6C8),
                    child: Icon(Icons.lunch_dining,
                        size: 40, color: Colors.orange.shade300),
                  ),
                ),
                // Veg icon
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: _buildVegIcon(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // ── Food Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CustomText(
                    'Rice, 4 Chapati, Curd, Salad, Papad....',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Price row
                  Row(
                    children: [
                      CustomText(
                        '\u20B91,499',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\u20B998,000',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          '50% Off',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Business info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.fillColor,
                        child: Icon(Icons.store_rounded,
                            size: 11, color: AppColors.secondaryTextColor),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: CustomText(
                          'Ma Bhabani Tiffin Centre',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.star_rounded,
                          size: 12, color: Colors.amber.shade700),
                      CustomText(
                        '4.5',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.near_me_rounded,
                          size: 10, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 2),
                      CustomText(
                        '4.5km Away',
                        fontSize: 9,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Address + ADD
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: CustomText(
                          'Sastri Nagar, Lucknow.....',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
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

  // ── Veg Icon ──

  Widget _buildVegIcon() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
