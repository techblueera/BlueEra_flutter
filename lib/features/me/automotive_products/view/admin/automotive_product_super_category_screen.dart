import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_nested_category_response.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_create_own_product_via_ai_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AutomotiveProductSuperCategoryScreen extends StatefulWidget {
  final String? ownerID;
  final ProviderType? providerType;

  const AutomotiveProductSuperCategoryScreen({
    super.key,
    this.ownerID,
    this.providerType,
  });

  @override
  State<AutomotiveProductSuperCategoryScreen> createState() =>
      _AutomotiveProductSuperCategoryScreenState();
}

class _AutomotiveProductSuperCategoryScreenState
    extends State<AutomotiveProductSuperCategoryScreen> {
  final controller = getOrPut(() => AutomotiveProductController());

  @override
  void initState() {
    super.initState();
    // Fetch ONCE on entry — not in build(). build() re-runs on every
    // keyboard open/close (the root MediaQuery viewInsets change rebuilds
    // every mounted route, including this one when it sits under the
    // add-variant dialog), and an unguarded call here hammered
    // `categories/nested` on each toggle.
    if (widget.ownerID != null) controller.ownerID = widget.ownerID;
    if (widget.providerType != null) {
      controller.ownerProviderType = widget.providerType;
    }
    controller.fetchProductsNestedCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => AutomotiveCreateOwnProductViaAiWidget(
          providerType: ProviderType.business,
        ),
      ),
      // Lazy CustomScrollView: the category grid is a SliverMasonryGrid that
      // builds only the cards currently on screen, so the screen can't
      // ANR-crash no matter how many categories the API returns.
      body: SafeArea(
        child: Obx(() {
          final resp = controller.nestedProductCategoryResponse.value;
          final categories = controller.productsNestedCategoryList;
          return CustomScrollView(
            slivers: [
              // ── Snap-search suggestion ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size15, SizeConfig.size8, SizeConfig.paddingXSL),
                  child: CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Add AutomotiveProducts',
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        _snapSearchSuggestion(
                          onTap: () => Get.toNamed(
                            RouteHelper.getAutomotiveAddProductTextOrSnapScreenRoute(),
                            arguments: {
                              ApiKeys.id: controller.ownerID,
                              ApiKeys.providerType:
                                  controller.ownerProviderType,
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── AutomotiveCategory title ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8, 0,
                      SizeConfig.size8, SizeConfig.paddingXSL),
                  child: CustomText(
                    'AutomotiveCategory',
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // ── AutomotiveCategory grid (lazy) / states ───────────────────────────
              _categorySliver(resp, categories),
              SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size15)),
            ],
          );
        }),
      ),
    );
  }

  /// AutomotiveCategory grid as a LAZY sliver (builds only visible cards) plus the
  /// error / empty / loading states.
  Widget _categorySliver(
      ApiResponse resp, List<AutomotiveProductNestedCategoryResponse> categories) {
    if (categories.isNotEmpty) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CommonServiceCard<AutomotiveProductNestedCategoryResponse>(
              service: category,
              getName: (item) => item.name ?? '',
              getIcon: (item) => item.image ?? '',
              iconHeight: SizeConfig.size60,
              boxShadow: const [],
              onTap: (item) {
                Get.toNamed(
                  RouteHelper.getAutomotiveProductNestedCategoryScreenRoute(),
                  arguments: {
                    ApiKeys.argArrProductSuperCategory: categories.toList(),
                    ApiKeys.argArrProductCatId: item.sId,
                    ApiKeys.argArrProductCatName: item.name,
                  },
                );
              },
            );
          },
        ),
      );
    } else if (resp.status == Status.ERROR) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CustomText(AppStrings.somethingWentWrong),
          ),
        ),
      );
    } else if (resp.status == Status.COMPLETE) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: CustomText('No categories found.'),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(child: buildCategoryGridSkeleton());
  }

  Widget _snapSearchSuggestion({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.cameraAddOutlineIcon,
                height: 18,
                width: 18,
                boxFix: BoxFit.scaleDown,
                imgColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'Search products by photo',
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    'Upload a picture to find products instantly.',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
