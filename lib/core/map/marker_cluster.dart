import 'dart:math' as math;

import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// A group of markers collapsed into one pin.
class MarkerCluster {
  const MarkerCluster({
    required this.id,
    required this.center,
    required this.members,
  });

  final String id;
  final LatLng center;
  final List<BlueMapMarker> members;

  bool get isSingle => members.length == 1;
  int get count => members.length;

  /// The box containing every member — what a tap should zoom the camera to.
  LatLngBounds? get bounds =>
      LatLngBounds.containing(members.map((m) => m.position));
}

/// Grid clustering for map markers.
///
/// ## Why this exists
///
/// Google Maps ships a platform-side `ClusterManager`; `flutter_osm_plugin` has
/// no equivalent. Five Discover screens rely on clustering, and dropping it
/// would not merely look different — those maps plot every service in a city at
/// once, and un-clustered that is hundreds of overlapping pins, each one a
/// platform view. It would be both unreadable and slow.
///
/// So clustering moves client-side. This is deliberately the *simple* algorithm
/// (fixed grid, not k-means or a distance-based hierarchy): it is O(n), stable
/// between frames, and produces the same visual result at the zoom levels these
/// screens actually use. Cluster centres are the mean of their members, so a
/// cluster sits where its markers are rather than at an arbitrary cell corner.
class MarkerClusterer {
  const MarkerClusterer._();

  /// Web Mercator tile size, and the unit [radiusPx] is expressed in.
  static const double _kTileSize = 256.0;

  /// Groups [markers] into clusters, where markers closer together than
  /// [radiusPx] **screen pixels** at [zoom] land in the same cell.
  ///
  /// A pixel radius rather than a distance in metres is what makes this feel
  /// right: what matters is whether two pins visually overlap, and that depends
  /// on zoom. At city zoom a 90 px cell is kilometres wide; at street zoom it
  /// is tens of metres, so clusters dissolve naturally as the user zooms in.
  static List<MarkerCluster> cluster({
    required List<BlueMapMarker> markers,
    required double zoom,
    double radiusPx = 90,
  }) {
    if (markers.isEmpty) return const [];

    // World size in pixels at this zoom.
    final worldPx = _kTileSize * math.pow(2, zoom).toDouble();
    final cellPx = radiusPx <= 0 ? 1.0 : radiusPx;

    final cells = <String, List<BlueMapMarker>>{};

    for (final marker in markers) {
      final point = _project(marker.position, worldPx);
      final cx = (point.dx / cellPx).floor();
      final cy = (point.dy / cellPx).floor();
      cells.putIfAbsent('$cx:$cy', () => []).add(marker);
    }

    final result = <MarkerCluster>[];
    for (final entry in cells.entries) {
      final members = entry.value;

      if (members.length == 1) {
        result.add(MarkerCluster(
          id: members.first.id,
          center: members.first.position,
          members: members,
        ));
        continue;
      }

      // Mean position, so the badge sits among its members rather than at the
      // grid cell's corner.
      final meanLat =
          members.map((m) => m.position.latitude).reduce((a, b) => a + b) /
              members.length;
      final meanLng =
          members.map((m) => m.position.longitude).reduce((a, b) => a + b) /
              members.length;

      result.add(MarkerCluster(
        // Derived from the cell, so the id is stable while the camera holds
        // still — an id that changed every frame would make BlueMap's diff
        // remove and re-add every cluster pin continuously.
        id: 'cluster:${entry.key}',
        center: LatLng(meanLat, meanLng),
        members: members,
      ));
    }

    return result;
  }

  /// Latitude/longitude to world pixel coordinates under Web Mercator.
  static _Point _project(LatLng position, double worldPx) {
    final x = (position.longitude + 180.0) / 360.0 * worldPx;

    // Clamped short of the poles: Mercator's y is infinite at ±90°, and a
    // marker at the pole would otherwise produce NaN and land in a garbage
    // cell.
    final lat = position.latitude.clamp(-85.05112878, 85.05112878);
    final latRad = lat * math.pi / 180.0;
    final y = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        worldPx;

    return _Point(x, y);
  }
}

class _Point {
  const _Point(this.dx, this.dy);
  final double dx;
  final double dy;
}
