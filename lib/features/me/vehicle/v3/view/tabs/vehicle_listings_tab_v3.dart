import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_super_category_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/my_vehicle_listings_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/widgets/vehicle_listing_card_v3.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Vehicles** tab of the showroom home: the add masthead, the seller's live
/// listings and the catalog's vehicle types.
///
/// The grocery Products tab one-for-one, with listings where products were.
/// Content-only — the host supplies the refreshable scroll view padded
/// `left: 20` with nothing on the right, which is why the rails here bleed
/// off the right edge and each section owns its own trailing inset.
class VehicleListingsTabV3 extends StatelessWidget {
  /// The showroom whose listings are being managed.
  final String businessId;

  const VehicleListingsTabV3({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => VehicleV3Controller());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: productsTabTrailingInset),
          child: OrderActionsCarousel(),
        ),
        SizedBox(height: SizeConfig.size16),
        ProductsTabBanner(
          title: AppStrings.vehiclesTab.tr,
          subtitle: 'Manage the vehicles you have for sale',
          ctaLabel: AppStrings.addVehicleLabel.tr,
          onAdd: () => _onAddVehicle(controller),
          gradient: ProductsBannerGradient.grocery,
        ),
        SizedBox(height: SizeConfig.size16),
        _summaryStrip(controller),
        SizedBox(height: SizeConfig.size20),
        _listingsSection(context, controller),
        SizedBox(height: SizeConfig.size20),
        _categorySection(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  /// Opens the catalog walk. On the way back, reload if something was
  /// actually published — the flow sets the flag rather than returning a
  /// value, so an abandoned draft costs no refetch.
  Future<void> _onAddVehicle(VehicleV3Controller controller) async {
    await Get.to(() => const VehicleSuperCategoryScreenV3());
    if (controller.listingsNeedRefresh) {
      controller.listingsNeedRefresh = false;
      await controller.loadDashboard(businessId);
    }
  }

  // ───── Summary counters ───────────────────────────────────────────

  /// `GET /inventory/summary` in a line: total / live / new / used. Collapses
  /// entirely until the call lands, so it never renders a row of zeros over
  /// listings that do exist.
  Widget _summaryStrip(VehicleV3Controller controller) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null || summary.total == 0) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(right: productsTabTrailingInset),
        child: Row(
          children: [
            _summaryChip('Total', summary.total),
            SizedBox(width: SizeConfig.size8),
            _summaryChip('Live', summary.active),
            SizedBox(width: SizeConfig.size8),
            _summaryChip('New', summary.newCount),
            SizedBox(width: SizeConfig.size8),
            _summaryChip('Used', summary.usedCount),
          ],
        ),
      );
    });
  }

  Widget _summaryChip(String label, int value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'OpenSans',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'OpenSans',
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── Listings rail ──────────────────────────────────────────────

  Widget _listingsSection(
      BuildContext context, VehicleV3Controller controller) {
    return Obx(() {
      final isLoading = controller.listingsStatus.value == Status.LOADING ||
          controller.listingsStatus.value == Status.INITIAL;
      final listings = controller.myListings;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: 'Your vehicles',
            subtitle: 'Everything you have listed, live or paused',
            action: listings.isEmpty
                ? null
                : ProductsViewAllPill(
                    label: AppStrings.groceryViewViewAll.tr,
                    onTap: () => Get.to(
                      () => MyVehicleListingsScreenV3(businessId: businessId),
                    ),
                  ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            const ProductsRailLoader(
              height: VehicleListingCardV3.railHeight,
              cardWidth: VehicleListingCardV3.cardWidth,
            )
          else if (listings.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size20,
                top: SizeConfig.size10,
                bottom: SizeConfig.size10,
              ),
              child: EmptyStateWidget(
                message: 'No vehicles listed yet. Add your first one.',
              ),
            )
          else
            ProductsRail(
              height: VehicleListingCardV3.railHeight,
              itemCount: listings.length >
                      VehicleV3Controller.listingsPreviewLimit
                  ? VehicleV3Controller.listingsPreviewLimit
                  : listings.length,
              spacing: 12,
              itemBuilder: (_, index) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: VehicleListingCardV3.cardWidth,
                  child: VehicleListingCardV3(
                    listing: listings[index],
                    compact: true,
                    showStatus: true,
                    onTap: () => Get.to(
                      () => MyVehicleListingsScreenV3(businessId: businessId),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  // ───── Manage via categories ──────────────────────────────────────

  /// The categories this showroom actually has stock in —
  /// `GET /categories/nested/with-inventory?businessId=`, the vehicle
  /// analogue of what grocery's Products tab renders.
  ///
  /// It used to render level-0 of the whole catalog, which listed every
  /// vehicle type in existence rather than the ones this shop sells. Tapping
  /// a tile now drills into that category's listings instead of jumping
  /// straight into the add flow — "manage", as the header says.
  Widget _categorySection(VehicleV3Controller controller) {
    return Obx(() {
      final isLoading =
          controller.stockedCategoriesStatus.value == Status.LOADING ||
              controller.stockedCategoriesStatus.value == Status.INITIAL;
      final categories =
          List<VehicleCategoryV3>.from(controller.myStockedCategories);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(title: AppStrings.manageViaCategories.tr),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            const ProductCategoryRailSkeleton()
          else if (categories.isEmpty)
            // Kept as an empty state rather than hidden, same as grocery: an
            // empty catalog is the merchant's cue to add stock, so hiding the
            // section would hide the prompt with it.
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              child: SizedBox(
                width: double.infinity,
                child: EmptyStateWidget(
                  message: 'You have not listed any vehicles yet.',
                  actionText: AppStrings.addVehicleLabel.tr,
                  actionCallback: () => _onAddVehicle(controller),
                ),
              ),
            )
          else
            ProductsRail(
              height: ProductCategoryTile.railHeight,
              itemCount: categories.length,
              spacing: SizeConfig.size8,
              itemBuilder: (_, i) => ProductCategoryTile(
                image: categories[i].image,
                name: categories[i].name,
                onTap: () => _openCategory(controller, categories[i]),
              ),
            ),
        ],
      );
    });
  }

  /// Opens the seller's listings filtered to this branch of the catalog.
  ///
  /// The filter is a set of ids rather than one, because the rail shows a
  /// BRANCH (a type or brand) while a listing carries its leaf model — so the
  /// whole subtree has to match. `/inventory/my` has no category parameter, so
  /// this is applied client-side over the already-loaded page.
  void _openCategory(
    VehicleV3Controller controller,
    VehicleCategoryV3 category,
  ) {
    Get.to(
      () => MyVehicleListingsScreenV3(
        businessId: businessId,
        categoryIds: controller.descendantCategoryIds(category),
        categoryName: category.name,
      ),
    );
  }
}
