import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';

/// How a `vehicleType` is presented — artwork and display name — across the
/// ride-booking flow.
///
/// Shared rather than owned by the home screen because the destination search
/// now echoes the SAME vehicle the customer tapped there. Two copies of these
/// maps is how the tile that reads "Parcel On Bike" over a rider illustration
/// becomes "Bike" over a plain bike on the very next screen.
class RideVehicleArt {
  RideVehicleArt._();

  /// Artwork per `vehicleType`. Local because the catalogue endpoint carries no
  /// imagery — placeholders from the app's existing transport set until the
  /// dedicated illustrations land, so an unmapped new code still gets a tile
  /// (with the closest vehicle) instead of an empty box.
  static const Map<String, String> _artwork = {
    'twoWheelerRider': AppIconAssets.transport_bike,
    'autoTempo': AppIconAssets.transport_auto,
    'eRickshaw': AppIconAssets.transport_big_auto,
    'carMini': AppIconAssets.transport_taxi,
    'carSedan': AppIconAssets.transport_taxi,
    'suvCar': AppIconAssets.transport_7_seater,
    'miniBus': AppImageAssets.miniBus,
    'goods3Wheeler': AppIconAssets.transport_load_auto,
    'goods4Wheeler': AppIconAssets.transport_truck,
    'pickupGoods': AppIconAssets.transport_truck,
    'miniTruckGoods': AppIconAssets.transport_container,
    'largeTruckGoods': AppIconAssets.transport_container,
  };

  /// Overrides for vehicles that appear under more than one trip type, keyed by
  /// `orderFor`. The bike is the one that does: a parcel run is the same
  /// `twoWheelerRider` as a passenger ride, so only the presentation separates
  /// them.
  static const Map<String, Map<String, String>> _byOrderFor = {
    'Parcel': {
      'artwork': AppIconAssets.riderIconColorful,
      'label': 'Parcel On Bike',
    },
  };

  /// Whether [code] carries a trip-type-specific presentation under [orderFor].
  static Map<String, String>? _override(String code, String orderFor) =>
      code == 'twoWheelerRider' ? _byOrderFor[orderFor] : null;

  /// Asset path for a vehicle, given the trip it is booking.
  static String assetFor(String code, {required String orderFor}) =>
      _override(code, orderFor)?['artwork'] ??
      _artwork[code] ??
      AppIconAssets.transport_bike;

  /// Display name for a vehicle, given the trip it is booking.
  ///
  /// [catalogueLabel] is the backend's own `slug_value` when the caller has the
  /// catalogue entry to hand; the trip-type override still wins, because the
  /// server names the vehicle, not the service.
  static String labelFor(
    String code, {
    required String orderFor,
    String? catalogueLabel,
  }) =>
      _override(code, orderFor)?['label'] ??
      (catalogueLabel?.isNotEmpty == true ? catalogueLabel! : code);

  /// Human name for an `orderFor`, for the places that show the trip type
  /// alongside the vehicle.
  static String tripTypeLabel(String orderFor) {
    switch (orderFor) {
      case 'Parcel':
        return 'Parcel';
      case 'OutStation':
        return 'Out station';
      case 'HourlyRental':
        return 'Hourly rental';
      case 'InCity':
      default:
        return 'City ride';
    }
  }
}
