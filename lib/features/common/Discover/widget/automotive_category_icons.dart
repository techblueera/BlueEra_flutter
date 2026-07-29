import 'package:BlueEra/core/constants/app_image_assets.dart';

/// Bundled artwork for the Discover automotive tiles, keyed by backend tag.
///
/// The `/category` response carries an `imageUrl` per category, but those are
/// photographic S3 assets that don't match the flat illustrated style the rest
/// of the Discover grid uses — and they cost a network round trip before the
/// section can finish painting. The tiles therefore keep the local icons the
/// hardcoded automotive list used to ship, while everything else about the
/// section (which categories exist, their names, their order) still comes from
/// the API.
///
/// Keys are the backend `tagId`s, plus the two synthetic slugs
/// `AutomotiveServiceCardWidget` splits `VEHICLE_SALES` into — new and used
/// sales are one category server-side but two tiles here, and they get
/// different art.
class AutomotiveCategoryIcons {
  const AutomotiveCategoryIcons._();

  /// Slug for the "new" half of the vehicle-sales split.
  static const String newVehicleSales = 'VEHICLE_SALES_NEW';

  /// Slug for the "used" half.
  static const String oldVehicleSales = 'VEHICLE_SALES_OLD';

  /// tag/slug → bundled asset. Uppercase keys; [assetFor] normalises lookups
  /// so a backend that changes `Vehicle_Sales` to `VEHICLE_SALES` (it has)
  /// doesn't silently lose its icon.
  static final Map<String, String> _icons = {
    newVehicleSales: AppImageAssets.VehicleSales,
    oldVehicleSales: AppImageAssets.VehicleRental,
    'VEHICLE_SALES': AppImageAssets.VehicleSales,
    'AUTO_PARTS': AppImageAssets.Vehicleparts,
    'VEHICLE_PARTS': AppImageAssets.Vehicleparts,
    'VEHICLE_SERVICE': AppImageAssets.vehicleService,
    'TRANSPORT_LOGISTICS_PARKING': AppImageAssets.TransportLogistic,
    'TRANSPORT_LOGISTIC': AppImageAssets.TransportLogistic,
    'VEHICLE_SUPPORT': AppImageAssets.VehicleSupport,
    'VEHICLE_RENTAL': AppImageAssets.VehicleRental,
  };

  /// The icon for [tagOrSlug].
  ///
  /// Falls back to a keyword match before giving up, so a category the backend
  /// adds later (`VEHICLE_SERVICE_PREMIUM`, say) still gets sensible art
  /// instead of an empty tile — and finally to the generic showroom icon, so a
  /// tile is never iconless.
  static String assetFor(String? tagOrSlug) {
    final key = (tagOrSlug ?? '').trim().toUpperCase();
    if (key.isEmpty) return AppImageAssets.vehicleShowroom;

    final exact = _icons[key];
    if (exact != null) return exact;

    // Order matters: PARTS before SALES, because "AUTO_PARTS_SALES" is parts.
    if (key.contains('PART')) return AppImageAssets.Vehicleparts;
    if (key.contains('SERVICE')) return AppImageAssets.vehicleService;
    if (key.contains('SUPPORT')) return AppImageAssets.VehicleSupport;
    if (key.contains('TRANSPORT') || key.contains('LOGISTIC')) {
      return AppImageAssets.TransportLogistic;
    }
    if (key.contains('RENTAL') || key.contains('USED') || key.contains('OLD')) {
      return AppImageAssets.VehicleRental;
    }
    if (key.contains('SALE')) return AppImageAssets.VehicleSales;

    return AppImageAssets.vehicleShowroom;
  }
}
