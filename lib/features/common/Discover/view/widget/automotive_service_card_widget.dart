import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/automotive_other_services_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_discover_screen_v3.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_category_discover_screen.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Automotive section of Discover, built from the `/category` response
/// [AuthController] already loads — the same source the sibling Discover cards
/// (Find Services, Shopping) read from. The hardcoded
/// `automotiveServiceItemsCategories` it used to render is gone, so a category
/// added or renamed server-side lands here without an app release.
///
/// Tile artwork comes from the same response (`image_url`). It used to be
/// bundled and keyed by tag in `AutomotiveCategoryIcons` — that map is gone,
/// because it meant a category the backend added rendered blank until the app
/// shipped an asset for it, which is the opposite of what reading the category
/// list from the API buys us.
///
/// The one thing the backend doesn't model is the new/used split: it returns a
/// single `VEHICLE_SALES` category, while the listing screen wants a condition.
/// So that one category is expanded into two tiles — see [_tilesFromApi].
class AutomotiveServiceCardWidget extends StatelessWidget {
  const AutomotiveServiceCardWidget({super.key});

  /// The backend category that becomes two tiles.
  static const String _vehicleSalesTag = 'VEHICLE_SALES';

  /// Synthetic slugs for the two halves of [_vehicleSalesTag]. They exist only
  /// on this card — nothing is sent to the server under these names; they just
  /// carry the new/used intent from the tile to [_conditionForSlug].
  static const String _newVehicleSalesSlug = 'VEHICLE_SALES_NEW';
  static const String _oldVehicleSalesSlug = 'VEHICLE_SALES_OLD';

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    // Obx because the categories arrive from `/category` asynchronously — on a
    // cold start Discover can mount before that lands, and without it the
    // section would sit empty until something else rebuilt this subtree.
    return Obx(() {
      final categories = _tilesFromApi(
          authController.businessOnboardingAutomotiveServicesCategories);
      return DiscoverGridSection(
        title: AppStrings.automotiveShowroom,
        items: categories,
        getName: (item) => item.name,
        getIcon: (item) => item.icon ?? '',
        onItemTap: _onCategoryTap,
      );
    });
  }

  /// Flattens the API categories into grid tiles, splitting `VEHICLE_SALES`
  /// into "New …" and "Old …" so the vehicle listing can open pre-filtered on
  /// condition. Every other category maps straight across, `tagId → slugId`, so
  /// the routing below keys off the backend tag rather than a local slug.
  ///
  /// Names are prefixed onto whatever the backend calls the category rather
  /// than hardcoded, so a server-side rename carries through.
  ///
  /// Icons are `category.imageUrl`. The two halves of the sales split share one
  /// image, since the backend models them as a single category — they're told
  /// apart by their labels ("New …" / "Old …") and by where they land.
  List<CollapsibleGridModel> _tilesFromApi(List<CategoryData> apiCategories) {
    final tiles = <CollapsibleGridModel>[];
    for (final category in apiCategories) {
      final tag = category.tagId ?? '';
      final name = category.name ?? '';
      final icon = category.imageUrl ?? '';

      if (tag == _vehicleSalesTag) {
        tiles.add(CollapsibleGridModel(
          name: 'New $name',
          slugId: _newVehicleSalesSlug,
          icon: icon,
        ));
        tiles.add(CollapsibleGridModel(
          name: 'Old $name',
          slugId: _oldVehicleSalesSlug,
          icon: icon,
        ));
        continue;
      }

      tiles.add(CollapsibleGridModel(
        name: name,
        slugId: tag,
        icon: icon,
      ));
    }
    return tiles;
  }

  /// Maps a tile slug to the listing condition the buyer flow opens on, so
  /// tapping "Old Vehicle Sales" lands already filtered to used stock. Only
  /// the two halves of the sales split carry one; anything else browses both.
  String? _conditionForSlug(String? slugId) {
    switch (slugId) {
      case _newVehicleSalesSlug:
        return VehicleListingCondition.isNew;
      case _oldVehicleSalesSlug:
        return VehicleListingCondition.used;
      default:
        return null;
    }
  }

  /// Card-tap routing:
  ///   * Auto Parts → automotive products discover screen.
  ///   * Vehicle Service / Support / Transport Logistics Parking → the
  ///     `/other-service/business-profile/search` listing.
  ///   * Everything else → the public vehicle listing.
  void _onCategoryTap(CollapsibleGridModel item) {
    final tag = item.slugId.toLowerCase();
    final name = item.name.toLowerCase();
    final isParts = tag.contains('part') || name.contains('part');

    if (isParts) {
      Get.to(() => const AutomotiveCategoryDiscoverScreen());
      return;
    }

    final otherServiceWire = _otherServiceWireForSlug(item.slugId);
    if (otherServiceWire != null) {
      Get.to(() => AutomotiveOtherServicesScreen(
            initialCategoryWire: otherServiceWire,
          ));
      return;
    }

    // Vehicle sales → the rebuilt buyer flow: `/products/user/search` rolled
    // up to trim cards, then listings per trim, then an enquiry. Replaces
    // VehicleListingScreen, which read the removed `/vehicles` API.
    Get.to(() => VehicleDiscoverScreenV3(
          initialCondition: _conditionForSlug(item.slugId),
        ));
  }

  /// The three categories that belong on the "Other Service" listing. Now that
  /// the tiles carry the backend `tagId`, the slug *is* the `categoryOfBusiness`
  /// wire value `/other-service/business-profile/search` expects — the old
  /// local-slug → wire translation table is gone. Returns null for anything
  /// that doesn't belong on that listing.
  String? _otherServiceWireForSlug(String slugId) {
    switch (slugId) {
      case 'VEHICLE_SERVICE':
      case 'VEHICLE_SUPPORT':
      case 'TRANSPORT_LOGISTICS_PARKING':
        return slugId;
      default:
        return null;
    }
  }
}
