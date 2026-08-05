import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_vehicle_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map markers drawn from the flow's vehicle artwork.
///
/// [BitmapDescriptor] only takes raster bytes, and every vehicle illustration
/// in the app is an SVG — so the picture is rasterised here once per
/// (asset, size, density) and kept. Rasterising is not cheap and a map redraws
/// constantly: without the cache, every camera move would re-decode the same
/// bike.
///
/// The cache is static and never evicted on purpose. It holds a handful of
/// small bitmaps for the life of the app run, and the alternative — dropping
/// them with the screen — means paying the decode again every time the customer
/// opens the flow.
class RideMarkerIcons {
  RideMarkerIcons._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Marker for [assetPath] at [logicalSize] logical pixels square.
  ///
  /// [devicePixelRatio] is what keeps the marker crisp: the bitmap is rendered
  /// at the device's real density and handed to the map with the same ratio, so
  /// it occupies [logicalSize] on screen at every density instead of shrinking
  /// on a 3x phone.
  static Future<BitmapDescriptor?> vehicleMarker(
    String assetPath, {
    double logicalSize = 40,
    double devicePixelRatio = 1,
  }) async {
    final key = '$assetPath@${logicalSize}x$devicePixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final descriptor = await _rasterise(
        assetPath,
        logicalSize * devicePixelRatio,
        devicePixelRatio,
      );
      _cache[key] = descriptor;
      return descriptor;
    } catch (_) {
      // A missing or malformed asset must not take the map down with it — the
      // caller falls back to a default pin.
      return null;
    }
  }

  /// Marker for a `vehicleType`, in that vehicle's own artwork.
  static Future<BitmapDescriptor?> forVehicleType(
    String vehicleType, {
    double devicePixelRatio = 1,
  }) =>
      vehicleMarker(
        // orderFor: the map is showing vehicles, not services — a bike out
        // there is a bike whether the customer is sending a parcel or riding.
        RideVehicleArt.assetFor(vehicleType, orderFor: 'InCity'),
        devicePixelRatio: devicePixelRatio,
      );

  static Future<BitmapDescriptor> _rasterise(
    String assetPath,
    double pixels,
    double devicePixelRatio,
  ) async {
    final PictureInfo info = await vg.loadPicture(SvgAssetLoader(assetPath), null);
    try {
      final side = pixels.round();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Contain, not stretch: the vehicle SVGs have different aspect ratios
      // (the rider is near-square, the truck is wide) and a marker that
      // squashes to fit reads as the wrong vehicle.
      final scale = math.min(
        pixels / info.size.width,
        pixels / info.size.height,
      );
      canvas.translate(
        (pixels - info.size.width * scale) / 2,
        (pixels - info.size.height * scale) / 2,
      );
      canvas.scale(scale);
      canvas.drawPicture(info.picture);

      final image = await recorder.endRecording().toImage(side, side);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return BitmapDescriptor.bytes(
          bytes!.buffer.asUint8List(),
          imagePixelRatio: devicePixelRatio,
        );
      } finally {
        image.dispose();
      }
    } finally {
      // loadPicture hands over ownership of the picture — see its contract.
      info.picture.dispose();
    }
  }
}

/// Draws `riders/live-in-radius` results on a screen's map.
///
/// A mixin rather than a widget because the markers belong to a [GoogleMap] the
/// screen already owns — the home map and the fare-screen map both show the
/// same live vehicles around the pickup, and neither wants to hand its map over
/// to something else to get them.
mixin RideLiveRiderMarkers<T extends StatefulWidget> on State<T> {
  /// Rasterised artwork by `vehicleType`, built lazily as riders arrive.
  final Map<String, BitmapDescriptor> riderMarkerIcons = {};

  /// Rasterise the artwork for any vehicle type on the map we haven't drawn
  /// before, then repaint.
  ///
  /// Async and off the build: [BitmapDescriptor] can only be made from raster
  /// bytes, and turning the SVGs into them is a decode. Markers drawn before
  /// their artwork is ready fall back to a default pin and upgrade on the
  /// setState below, which is why the map never waits on this.
  Future<void> ensureRiderMarkerIcons(List<RideLiveRider> riders) async {
    final pending = {
      for (final rider in riders)
        if (rider.vehicleType.isNotEmpty &&
            !riderMarkerIcons.containsKey(rider.vehicleType))
          rider.vehicleType,
    };
    if (pending.isEmpty) return;

    final ratio = MediaQuery.devicePixelRatioOf(context);
    var added = false;
    for (final code in pending) {
      final icon = await RideMarkerIcons.forVehicleType(
        code,
        devicePixelRatio: ratio,
      );
      if (!mounted) return;
      if (icon == null) continue;
      riderMarkerIcons[code] = icon;
      added = true;
    }
    if (added && mounted) setState(() {});
  }

  /// The live vehicles, drawn in their own artwork.
  ///
  /// Anchored at the centre and flat on the map, unlike a teardrop pin: these
  /// are vehicles sitting ON a road, not labels pointing at one, so a marker
  /// whose point is its bottom edge would sit a vehicle's height off its actual
  /// position.
  Set<Marker> liveRiderMarkers(List<RideLiveRider> riders) {
    return {
      for (final rider in riders)
        Marker(
          markerId: MarkerId('live_${rider.userId}'),
          position: LatLng(rider.latitude, rider.longitude),
          // Falls back to a plain pin until the artwork is rasterised, and for
          // a vehicle type the app has no illustration for.
          icon: riderMarkerIcons[rider.vehicleType] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          // Tapping says who and how far — the customer can't pick this rider
          // (dispatch is a broadcast), so it stays informational.
          infoWindow: InfoWindow(
            title: rider.name.isNotEmpty ? rider.name : 'Rider nearby',
            snippet: rider.distanceKm != null
                ? '${rider.distanceKm!.toStringAsFixed(1)} km away'
                : null,
          ),
        ),
    };
  }
}
