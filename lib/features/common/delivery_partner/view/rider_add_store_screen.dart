import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_link_stores_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class RiderAddStoreScreen extends StatefulWidget {
  const RiderAddStoreScreen({super.key});

  @override
  State<RiderAddStoreScreen> createState() => _RiderAddStoreScreenState();
}

class _RiderAddStoreScreenState extends State<RiderAddStoreScreen> {
  final AuthController _authController = Get.find<AuthController>();

  void _navigateToLinkStores({
    required CategoryData selectedCategory,
    bool isGrocery = true,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderLinkStoresScreen(
          selectedCategory: selectedCategory,
          isGroceryStore: isGrocery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: const CommonBackAppBar(title: 'Add Store'),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        child: CustomScrollView(
          slivers: [
            /// Grocery & Stationary
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.paddingXSL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.groceryNdStationary,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _buildCategoryGrid(
                      items: _authController.businessOnboardingGroceriesCategories,
                      getName: (item) => item.name ?? '',
                      getIcon: (item) => item.imageUrl ?? '',
                      onTap: (item) {
                        _navigateToLinkStores(
                          selectedCategory: item,
                          isGrocery: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            _buildGap(),

            /// Food & Restaurant
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.paddingXSL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.foodNearMe,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _buildCategoryGrid(
                      items: _authController.businessOnboardingFoodsCategories,
                      getName: (item) => item.name ?? '',
                      getIcon: (item) => item.imageUrl ?? '',
                      onTap: (item) {
                        _navigateToLinkStores(
                          selectedCategory: item,
                          isGrocery: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            _buildGap(),

            /// Cloud Kitchen / Home Made Food
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.paddingXSL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Cloud Kitchen / Home Made Food',
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _buildCategoryGrid(
                      items: cloudKitchenHomeMadeFood,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon ?? '',
                      onTap: (item) {
                        // Cloud kitchen tap
                      },
                    ),
                  ],
                ),
              ),
            ),

            _buildGap(),

            /// Add Medical Store
            SliverToBoxAdapter(
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.paddingXSL),
                child: InkWell(
                  onTap: () {
                    Get.toNamed(RouteHelper.getMedicalScreenRoute());
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Container(
                        width: SizeConfig.size60,
                        height: SizeConfig.size60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            AppImageAssets.pharmacyMedicalStore,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_pharmacy_outlined,
                              size: 30,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: CustomText(
                          'Add Medical Store',
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _buildGap(gap: SizeConfig.paddingM),
          ],
        ),
      ),
    );
  }

  Widget _buildGap({double? gap}) {
    return SliverToBoxAdapter(
      child: SizedBox(height: gap ?? SizeConfig.paddingXSL),
    );
  }

  Widget _buildCategoryGrid<T>({
    required List<T> items,
    required String Function(T) getName,
    required String Function(T) getIcon,
    required Function(T) onTap,
  }) {
    return MasonryGridView.count(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        var item = items[index];
        return CommonServiceCard<T>(
          service: item,
          getName: (item) => getName(item),
          getIcon: (item) => getIcon(item),
          iconHeight: SizeConfig.size60,
          boxShadow: const [],
          onTap: (item) => onTap(item),
        );
      },
    );
  }
}
