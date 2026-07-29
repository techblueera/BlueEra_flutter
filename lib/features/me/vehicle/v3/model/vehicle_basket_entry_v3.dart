import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';

/// One vehicle in the add-flow basket: a catalog colour, the condition chosen
/// for it, and whatever the merchant has filled in on the review screen.
///
/// The grocery basket holds bare products because a grocery item is fully
/// identified by its product; a vehicle is not. `POST /inventory` requires the
/// **colour** (`productVariant`) and a `condition`, and the condition decides
/// which other fields the server expects — so both are captured at "+" time,
/// and the rest is edited on the review screen before publishing.
class VehicleBasketEntryV3 {
  /// Kept for display — the review screen and the rail card both show the
  /// trim's name and artwork.
  final VehicleTrimV3 trim;

  /// The colour. Its `_id` is what gets submitted as `productVariant`.
  final VehicleColorVariantV3 colour;

  /// `NEW` or `USED` — see [VehicleListingCondition].
  String condition;

  // ── NEW ──
  num? onRoadPrice;
  String? availability;
  String? deliveryTime;
  bool emiAvailable;

  // ── USED ──
  num? expectedPrice;
  int? kmDriven;
  int? registrationYear;
  String? ownership;
  bool isNegotiable;

  /// Seller photos, USED only. A NEW listing shows the catalog's artwork, so
  /// it uploads nothing.
  final List<String> photoPaths;

  VehicleBasketEntryV3({
    required this.trim,
    required this.colour,
    required this.condition,
    this.onRoadPrice,
    this.availability,
    this.deliveryTime,
    this.emiAvailable = false,
    this.expectedPrice,
    this.kmDriven,
    this.registrationYear,
    this.ownership,
    this.isNegotiable = false,
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? <String>[];

  bool get isNew =>
      condition.toUpperCase() == VehicleListingCondition.isNew;

  /// Seeded from the catalog so a merchant who changes nothing still publishes
  /// a sensible price — the trim's ex-showroom figure.
  void seedPriceFromCatalog() {
    if (isNew) {
      onRoadPrice ??= trim.exShowroomPrice;
    } else {
      expectedPrice ??= trim.exShowroomPrice;
    }
  }

  /// The request payload for this entry.
  ///
  /// Location comes from the device at publish time rather than being stored
  /// per entry — `lat`/`lng` go as plain fields and the server builds the
  /// GeoJSON point itself.
  VehicleListingDraftV3 toDraft() {
    final address = LocationService.userCurrentAddress.value;
    return VehicleListingDraftV3(
      productVariantId: colour.id,
      condition: condition,
      address: [address.street, address.subLocality]
          .where((p) => p.trim().isNotEmpty)
          .join(', '),
      city: address.city,
      state: address.state,
      pincode: address.postalCode,
      lat: LocationService.lat == 0.0 ? null : LocationService.lat,
      lng: LocationService.lng == 0.0 ? null : LocationService.lng,
      onRoadPrice: isNew ? onRoadPrice : null,
      availability: isNew ? availability : null,
      deliveryTime: isNew ? deliveryTime : null,
      emiAvailable: isNew ? emiAvailable : null,
      expectedPrice: isNew ? null : expectedPrice,
      kmDriven: isNew ? null : kmDriven,
      registrationYear: isNew ? null : registrationYear,
      ownership: isNew ? null : ownership,
      isNegotiable: isNew ? null : isNegotiable,
      imagePaths: isNew ? const [] : List<String>.from(photoPaths),
      coverImagePath: isNew || photoPaths.isEmpty ? null : photoPaths.first,
    );
  }
}
