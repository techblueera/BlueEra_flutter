import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_category_picker_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_colour_condition_sheet_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/widgets/vehicle_basket_fab_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/widgets/vehicle_trim_select_card_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add-vehicle landing — the same shape as [GrocerySuperCategoryScreen]:
/// "Quick Upload" rails, one per root category, each showing trims from
/// `GET /products/by-root-category`. Tapping a trim's "+" opens the colour +
/// condition sheet and drops it in the basket; the floating cart routes to the
/// review screen, which publishes.
///
/// "More" on a rail header opens the category list, and tapping a category
/// there opens **its products** — the same two-step grocery uses (nested
/// category screen → products selection). Both routes feed the same basket and
/// the same review screen; the old four-screen walk that published on its own
/// path is gone.
class VehicleSuperCategoryScreenV3 extends StatefulWidget {
  const VehicleSuperCategoryScreenV3({super.key});

  @override
  State<VehicleSuperCategoryScreenV3> createState() =>
      _VehicleSuperCategoryScreenV3State();
}

class _VehicleSuperCategoryScreenV3State
    extends State<VehicleSuperCategoryScreenV3> {
  final controller = getOrPut(() => VehicleV3Controller());

  /// Fixed rail-card width; the rail height follows the tallest card.
  static double get _railCardWidth => SizeConfig.size160;
  static const double _railSkeletonHeight = 220.0;

  @override
  void initState() {
    super.initState();
    // Rails. TTL-guarded, so re-entering reuses what's loaded.
    controller.fetchRootSectionsIfNeeded();
    // Root types back the "More" drill-down.
    controller.fetchRootCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.addProducts),
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(child: VehicleBasketFabV3(controller: controller)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody() {
    return Obx(() {
      final status = controller.rootSectionsStatus.value;
      final sections = controller.rootCategorySections;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size15,
                  SizeConfig.size12, SizeConfig.size8),
              child: CustomText(
                'Quick Upload',
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _railsSliver(status, sections),
          SliverToBoxAdapter(
            child: SizedBox(
              height: controller.basket.isEmpty
                  ? SizeConfig.size15
                  : SizeConfig.size80,
            ),
          ),
        ],
      );
    });
  }

  Widget _railsSliver(
      Status status, List<VehicleRootCategorySectionV3> sections) {
    if (sections.isEmpty) {
      if (status == Status.LOADING || status == Status.INITIAL) {
        return SliverToBoxAdapter(child: _buildRailsSkeleton());
      }
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: CustomText(
              status == Status.ERROR
                  ? AppStrings.somethingWentWrong
                  : 'No categories found.',
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _rootCategorySection(sections[index]),
        childCount: sections.length,
      ),
    );
  }

  /// One rail: header (icon + title + "More") over a horizontal row of trims.
  Widget _rootCategorySection(VehicleRootCategorySectionV3 section) {
    if (section.trims.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.fromLTRB(
          SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railHeader(section),
          // No fixed height: each card sizes to its content and the Row takes
          // the tallest, so there's no dead space under short cards.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
                SizeConfig.size12, 0, SizeConfig.size12, SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < section.trims.length; i++) ...[
                  if (i > 0) SizedBox(width: SizeConfig.size10),
                  VehicleTrimSelectCardV3(
                    trim: section.trims[i],
                    controller: controller,
                    width: _railCardWidth,
                    onAdd: () => showVehicleColourConditionSheetV3(
                      context: context,
                      trim: section.trims[i],
                      controller: controller,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railHeader(VehicleRootCategorySectionV3 section) {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size12,
          SizeConfig.size12, SizeConfig.paddingXSL),
      child: Row(
        children: [
          if (section.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: section.image,
                height: SizeConfig.size24,
                width: SizeConfig.size24,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  height: SizeConfig.size24,
                  width: SizeConfig.size24,
                  boxFix: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),
          ],
          Expanded(
            child: CustomText(
              section.name,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          InkWell(
            onTap: () => _openCategory(section),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: CustomText(
                AppStrings.more.tr,
                fontSize: SizeConfig.medium,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "More" → the catalog drill-down for this root category (brand → model →
  /// trim), for models the rail doesn't show.
  void _openCategory(VehicleRootCategorySectionV3 section) {
    final category = section.category;
    if (category == null) {
      Get.to(() => const VehicleCategoryPickerScreenV3());
      return;
    }
    Get.to(() => VehicleCategoryPickerScreenV3(rootCategory: category));
  }

  Widget _buildRailsSkeleton() {
    return buildLoadingShimmer(
      child: Column(
        children: List.generate(2, (_) {
          return Container(
            margin: EdgeInsets.fromLTRB(
                SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(height: 18, width: 140, radius: 4),
                SizedBox(height: SizeConfig.size12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size10),
                        child: shimmerContainer(
                          height: _railSkeletonHeight,
                          width: _railCardWidth,
                          radius: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
