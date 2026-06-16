import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_vehicle_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_category_discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AutomotiveServiceCardWidget extends StatelessWidget {
  const AutomotiveServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(AppStrings.automotiveShowroom),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              // Categories now come from the master getAllCategories list
              // (Automotive bucket) instead of a hardcoded constant. The
              // bucket is reactive, so wrap in Obx to repaint when it loads.
              return Obx(() {
                final categories =
                    authController.businessOnboardingAutomotiveServicesCategories;
                if (categories.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: categories.map((item) {
                    return SizedBox(
                      width: itemWidth,
                      child: CommonServiceCard<CategoryData>(
                        service: item,
                        getName: (i) => i.name ?? '',
                        getIcon: (i) => i.imageUrl ?? '',
                        onTap: (i) => _onCategoryTap(i, categories),
                      ),
                    );
                  }).toList(),
                );
              });
            }),
          ),
        ],
      ),
    );
  }

  /// "Vehicle Parts" opens the products category-discover screen; every
  /// other automotive category keeps the existing AllVehicleServiceScreen
  /// listing.
  void _onCategoryTap(CategoryData item, List<CategoryData> categories) {
    final tag = (item.tagId ?? '').toLowerCase();
    final name = (item.name ?? '').toLowerCase();
    final isParts = tag.contains('part') || name.contains('part');

    if (isParts) {
      Get.to(() => const AutomotiveCategoryDiscoverScreen());
      return;
    }

    // AllVehicleServiceScreen is typed against CollapsibleGridModel and keys
    // its category filter off `slugId`, so map the API categories
    // (tag_id → slugId) before handing off.
    final gridList = categories
        .map((c) => CollapsibleGridModel(
              name: c.name ?? '',
              slugId: c.tagId ?? '',
              icon: c.imageUrl,
            ))
        .toList();
    Get.to(() => AllVehicleServiceScreen(
          automotiveCategories: gridList,
          selectedAutomotiveData: CollapsibleGridModel(
            name: item.name ?? '',
            slugId: item.tagId ?? '',
            icon: item.imageUrl,
          ),
        ));
  }
}
