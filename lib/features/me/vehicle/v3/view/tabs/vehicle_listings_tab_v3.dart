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
        // Listings and categories are ONE block, not two independent sections
        // — see [_listingsAndCategories] for why they have to decide together.
        Obx(() => _listingsAndCategories(context, controller)),
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

  // ───── Listings + categories ──────────────────────────────────────

  /// The two sections resolved TOGETHER, because their two endpoints describe
  /// one thing.
  ///
  /// `/inventory/my` and `/categories/nested/with-inventory` are derived from
  /// the same stock: a showroom with listings necessarily has the categories
  /// those listings sit in. So the only honest states are "has stock" and "has
  /// no stock" — and letting each section answer for itself produced neither.
  ///
  ///  * Both empty → ONE empty state for the whole block. Two separate ones
  ///    ("No vehicles listed yet" / "You have not listed any vehicles yet")
  ///    said the same thing twice, in two different sentences, one screen
  ///    apart.
  ///  * Listings present but categories empty → the categories section is
  ///    dropped entirely, header and all. That combination is a backend
  ///    hiccup, not a state worth a prompt: telling a seller who is looking at
  ///    their own car that they "have not listed any vehicles yet" is simply
  ///    wrong (this is the screenshotted bug).
  ///
  /// Nothing is decided until BOTH calls have landed — while either is in
  /// flight the sections render their own skeletons, so a slow categories call
  /// can't flash the empty state under listings that are already on screen.
  Widget _listingsAndCategories(
      BuildContext context, VehicleV3Controller controller) {
    final listingsLoading =
        controller.listingsStatus.value == Status.LOADING ||
            controller.listingsStatus.value == Status.INITIAL;
    final categoriesLoading =
        controller.stockedCategoriesStatus.value == Status.LOADING ||
            controller.stockedCategoriesStatus.value == Status.INITIAL;
    final listings = controller.myListings;
    final categories =
        List<VehicleCategoryV3>.from(controller.myStockedCategories);

    final nothingListed = !listingsLoading &&
        !categoriesLoading &&
        listings.isEmpty &&
        categories.isEmpty;

    if (nothingListed) return _emptyShowroom(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _listingsSection(context, controller, listingsLoading, listings),
        if (categoriesLoading || categories.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size20),
          _categorySection(controller, categoriesLoading, categories),
        ],
      ],
    );
  }

  /// The one empty state for a showroom with no stock at all — the listings
  /// header over a single prompt, carrying the add CTA the categories section
  /// used to own.
  Widget _emptyShowroom(VehicleV3Controller controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductsSectionHeader(
          title: 'Your vehicles',
          subtitle: 'Everything you have listed, live or paused',
        ),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size10,
          ),
          child: SizedBox(
            width: double.infinity,
            child: EmptyStateWidget(
              message: 'No vehicles listed yet. Add your first one.',
              actionText: AppStrings.addVehicleLabel.tr,
              actionCallback: () => _onAddVehicle(controller),
            ),
          ),
        ),
      ],
    );
  }

  // ───── Listings rail ──────────────────────────────────────────────

  Widget _listingsSection(
    BuildContext context,
    VehicleV3Controller controller,
    bool isLoading,
    List<VehicleListingV3> listings,
  ) {
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
        // No empty branch here any more: with listings empty the whole block
        // renders as [_emptyShowroom] instead, so this section only ever draws
        // the loader or the rail.
        else
          ProductsRail(
            // sizeToContent — the rail takes the height of the tallest card
            // rather than the 244 the constant reserves for a two-line title.
            // Top-aligned in a fixed box, a one-line card left ~30px of dead
            // rail under it, which is the gap that opened up between the card
            // and "Manage Via Categories". Safe here because the rail is
            // capped at listingsPreviewLimit cards.
            sizeToContent: true,
            height: VehicleListingCardV3.railHeight,
            itemCount:
                listings.length > VehicleV3Controller.listingsPreviewLimit
                    ? VehicleV3Controller.listingsPreviewLimit
                    : listings.length,
            spacing: 12,
            itemBuilder: (_, index) => SizedBox(
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
      ],
    );
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
  ///
  /// Only ever built with categories to show or the call still in flight —
  /// [_listingsAndCategories] owns the empty case for the whole block.
  Widget _categorySection(
    VehicleV3Controller controller,
    bool isLoading,
    List<VehicleCategoryV3> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductsSectionHeader(title: AppStrings.manageViaCategories.tr),
        SizedBox(height: SizeConfig.size12),
        if (isLoading)
          const ProductCategoryRailSkeleton()
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
