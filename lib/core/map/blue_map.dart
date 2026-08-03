import 'dart:async';
import 'dart:math' as math;

import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/core/map/marker_cluster.dart';
import 'package:BlueEra/core/map/osm_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;

/// Which part of a marker's artwork sits on its coordinate.
///
/// Exposed as a plain enum so screens never import the map plugin — the whole
/// point of this layer is that swapping the plugin touches one file.
enum BlueMarkerAnchor {
  /// The middle of the artwork. Right for a symbol that *is* the thing — a
  /// vehicle glyph, a user dot.
  center,

  /// The bottom-centre. Right for a teardrop pin, whose tip points AT the
  /// coordinate; anchoring one centrally leaves it visibly high.
  bottom,
}

/// A marker to show on a [BlueMap].
///
/// Markers are described **declaratively** — a screen hands [BlueMap] the list
/// it wants on screen and the widget works out which to add, move and remove.
/// The underlying plugin is imperative (`addMarker`, `removeMarker`,
/// `changeLocationMarker`), which is a fine API to call once and a miserable one
/// to keep in sync with rebuilding UI across forty screens.
class BlueMapMarker {
  const BlueMapMarker({
    required this.id,
    required this.position,
    this.icon,
    this.color,
    this.size = 42,
    this.child,
    this.angle,
    this.anchor = BlueMarkerAnchor.center,
  }) : assert(icon != null || child != null,
            'a marker needs either an icon or a child widget');

  /// Stable identity, and the thing that makes diffing possible.
  ///
  /// It must survive rebuilds: `'pickup'`, `'drop'`, `'rider'`, or an order id.
  /// Do **not** derive it from the coordinate — a marker whose id changes when
  /// it moves reads to the diff as "one marker deleted, a different one added",
  /// which is both slower and visibly flickers.
  final String id;

  final LatLng position;

  /// Glyph form. Ignored when [child] is set.
  final IconData? icon;
  final Color? color;
  final double size;

  /// Arbitrary widget form — a profile avatar, a vehicle sprite, a price pill.
  final Widget? child;

  /// Rotation in radians, for heading-aware markers like a moving vehicle.
  final double? angle;

  final BlueMarkerAnchor anchor;

  osm.IconAnchor get osmAnchor => osm.IconAnchor(
        anchor: anchor == BlueMarkerAnchor.bottom
            // (0.5, 1) in the plugin's terms — the same anchor Google Maps
            // expresses as Offset(0.5, 1.0).
            ? osm.Anchor.top
            : osm.Anchor.center,
      );

  /// True when the visual changed, as opposed to only the position — the two
  /// need different plugin calls.
  bool sameAppearanceAs(BlueMapMarker other) =>
      icon == other.icon &&
      color == other.color &&
      size == other.size &&
      angle == other.angle &&
      // Widget children are compared by identity: a screen that rebuilds its
      // child every frame would otherwise redraw every marker every frame.
      identical(child, other.child);
}

/// A line to draw on a [BlueMap] — a route, a trip leg, a geofence edge.
class BlueMapPolyline {
  const BlueMapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.width = 5,
    this.borderColor,
    this.borderWidth,
    this.isDotted = false,
  });

  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
  final Color? borderColor;
  final double? borderWidth;
  final bool isDotted;

  bool sameAs(BlueMapPolyline other) =>
      color == other.color &&
      width == other.width &&
      borderColor == other.borderColor &&
      borderWidth == other.borderWidth &&
      isDotted == other.isDotted &&
      points.length == other.points.length &&
      // Endpoints are a cheap proxy for "same line". A route whose middle
      // changed but whose ends and length did not is not a case that occurs.
      (points.isEmpty ||
          (points.first == other.points.first &&
              points.last == other.points.last));
}

/// A filled circle on the map — a search radius, a delivery zone, a geofence.
class BlueMapCircle {
  const BlueMapCircle({
    required this.id,
    required this.center,
    required this.radiusMetres,
    required this.color,
    this.borderColor,
    this.strokeWidth = 1,
  });

  final String id;
  final LatLng center;

  /// Radius in **metres**, not pixels — it scales with the map as you zoom.
  final double radiusMetres;

  final Color color;
  final Color? borderColor;
  final double strokeWidth;

  bool sameAs(BlueMapCircle other) =>
      center == other.center &&
      radiusMetres == other.radiusMetres &&
      color == other.color &&
      borderColor == other.borderColor &&
      strokeWidth == other.strokeWidth;
}

/// Camera and location control for a [BlueMap].
///
/// Handed to the screen through `onMapCreated`. Every method is safe to call
/// **immediately** — before the underlying map has finished initialising — which
/// is the single most important thing this class does. See [BlueMap] for why.
class BlueMapController {
  BlueMapController._(this._state);

  final _BlueMapState _state;

  /// Centre on a point, optionally changing zoom.
  Future<void> moveTo(LatLng target, {double? zoom, bool animate = true}) =>
      _state._whenReady(() async {
        if (zoom != null) await _state._osmController.setZoom(zoomLevel: zoom);
        await _state._osmController
            .moveTo(_toGeoPoint(target), animate: animate);
      });

  /// Frame a region, with [padding] in pixels.
  ///
  /// A zero-area box is padded first — fitting one would otherwise zoom the map
  /// to maximum, which looks like a bug.
  Future<void> fitBounds(LatLngBounds bounds, {int padding = 48}) =>
      _state._whenReady(() async {
        final safe = bounds.southwest == bounds.northeast
            ? bounds.padded()
            : bounds;
        await _state._osmController.zoomToBoundingBox(
          osm.BoundingBox(
            north: safe.northeast.latitude.clamp(-85.0, 85.0),
            east: safe.northeast.longitude.clamp(-180.0, 180.0),
            south: safe.southwest.latitude.clamp(-85.0, 85.0),
            west: safe.southwest.longitude.clamp(-180.0, 180.0),
          ),
          paddinInPixel: padding,
        );
      });

  /// Frame every point given. No-op for fewer than two.
  Future<void> fitPoints(Iterable<LatLng> points, {int padding = 48}) async {
    final bounds = LatLngBounds.containing(points);
    if (bounds == null) return;
    return fitBounds(bounds, padding: padding);
  }

  Future<void> setZoom(double zoom) =>
      _state._whenReady(() => _state._osmController.setZoom(zoomLevel: zoom));

  Future<void> zoomIn() =>
      _state._whenReady(() => _state._osmController.zoomIn());

  Future<void> zoomOut() =>
      _state._whenReady(() => _state._osmController.zoomOut());

  /// The device's current position. Null when unavailable — permission denied,
  /// location off, or no fix yet. Callers must handle null rather than assume a
  /// coordinate.
  Future<LatLng?> myLocation() async {
    try {
      final point = await _state._osmController.myLocation();
      return LatLng(point.latitude, point.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Centre on the device and keep following it.
  Future<void> followMe() =>
      _state._whenReady(() => _state._osmController.currentLocation());

  /// The map's current centre, or null before it is ready.
  Future<LatLng?> center() async {
    try {
      final point = await _state._osmController.centerMap;
      return LatLng(point.latitude, point.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Present so screens migrating off `GoogleMapController.dispose()` have
  /// something to call. Deliberately a no-op: `OSMFlutter` disposes the
  /// controller it was given, and disposing it twice throws.
  void dispose() {}
}

osm.GeoPoint _toGeoPoint(LatLng value) =>
    osm.GeoPoint(latitude: value.latitude, longitude: value.longitude);

/// An OpenStreetMap map.
///
/// ## Why this wrapper exists
///
/// `OSMFlutter` is imperative and asynchronous in ways that are easy to get
/// wrong, and forty screens getting them wrong independently is the failure mode
/// this class prevents. Three specific hazards:
///
/// **1. Nothing works before the map is ready.** Markers added, roads drawn or
/// cameras moved before the platform view has initialised are silently dropped.
/// The natural place to add a marker is `initState`, which is always too early.
/// Here every controller call goes through [_whenReady], which queues work until
/// the map reports ready and then replays it in order — so a screen can call
/// `moveTo` in `initState` and it simply works.
///
/// **2. Markers are addressed by coordinate, not by identity.** The plugin's
/// `removeMarker` takes the *position* of the marker to remove, so a screen that
/// moves a marker must remember where it used to be. Miss that and you leak a
/// marker on every position update — which, on a live rider-tracking screen at
/// one update every three seconds, means hundreds of stale pins. [BlueMapMarker]
/// carries a stable [BlueMapMarker.id] and this widget tracks last-known
/// positions, so screens describe what they want and never track ghosts.
///
/// **3. Declarative UI over an imperative map.** Flutter screens rebuild; the
/// map does not. Diffing the requested marker/polyline lists against what is
/// drawn keeps the two in step without every screen writing its own reconciler.
///
/// ## Attribution
///
/// [OsmConfig.attribution] is rendered unless [showAttribution] is false. OSM
/// data is ODbL-licensed and attribution is a licence condition — only turn it
/// off where the surrounding UI already credits OpenStreetMap.
class BlueMap extends StatefulWidget {
  const BlueMap({
    super.key,
    this.initialCenter,
    this.initialZoom = 14,
    this.minZoom = 3,
    this.maxZoom = 19,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.myLocationEnabled = false,
    this.trackUserLocation = false,
    this.showZoomControls = false,
    this.interactive = true,
    this.onMapCreated,
    this.onMapReady,
    this.onTap,
    this.onLongPress,
    this.clusterMarkers = false,
    this.clusterRadiusPx = 90,
    this.clusterBuilder,
    this.onMarkerTap,
    this.onCameraMoved,
    this.onCameraIdle,
    this.cameraIdleDelay = const Duration(milliseconds: 400),
    this.showAttribution = true,
    this.loadingWidget,
  });

  /// Where the camera starts. Falls back to a national-scale view of India when
  /// null and [myLocationEnabled] is false — never 0,0, which is in the ocean
  /// and reads as a broken map.
  final LatLng? initialCenter;

  final double initialZoom;

  /// The plugin asserts `minZoomLevel >= 2` and `maxZoomLevel <= 19`; both are
  /// clamped rather than left to throw at runtime.
  final double minZoom;
  final double maxZoom;

  final List<BlueMapMarker> markers;
  final List<BlueMapPolyline> polylines;
  final List<BlueMapCircle> circles;

  /// Show the device's own position on the map.
  final bool myLocationEnabled;

  /// Keep the camera following the device as it moves. Implies
  /// [myLocationEnabled].
  final bool trackUserLocation;

  final bool showZoomControls;

  /// False wraps the map so it ignores gestures — for inline previews that open
  /// a full-screen map on tap.
  final bool interactive;

  final ValueChanged<BlueMapController>? onMapCreated;
  final VoidCallback? onMapReady;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;

  /// Collapse markers that would visually overlap into a numbered badge.
  ///
  /// Needed wherever a map plots more than a handful of pins: the plugin has no
  /// clustering of its own, and hundreds of overlapping platform-view markers
  /// are both unreadable and slow. Tapping a cluster zooms to fit its members.
  final bool clusterMarkers;

  /// How close, in **screen pixels**, two markers must be to cluster.
  final double clusterRadiusPx;

  /// Renders the cluster badge. Defaults to a filled circle with the count.
  final Widget Function(int count)? clusterBuilder;

  /// Fired with the id of the tapped marker. Prefer this to [onTap] for marker
  /// interactions — it does the hit-testing for you.
  ///
  /// Cluster pins are handled internally (they zoom the camera) and never reach
  /// this callback.
  final ValueChanged<String>? onMarkerTap;

  /// Fired continuously as the user pans/zooms, with the new centre.
  final ValueChanged<LatLng>? onCameraMoved;

  /// Fired once the camera has been still for [cameraIdleDelay], with the
  /// resting centre.
  ///
  /// This is the "drag the map, drop a pin" pattern — several screens resolve
  /// the centre to a street address when the user stops moving. The underlying
  /// plugin has **no idle event**, only a continuous move stream, so the
  /// settle is debounced here rather than in each screen: reverse-geocoding on
  /// every move event would fire dozens of lookups per drag and race its own
  /// replies, so the last one to arrive — not the last one requested — would
  /// win the address field.
  final ValueChanged<LatLng>? onCameraIdle;

  /// How long the camera must be still before [onCameraIdle] fires.
  final Duration cameraIdleDelay;

  final bool showAttribution;
  final Widget? loadingWidget;

  @override
  State<BlueMap> createState() => _BlueMapState();
}

class _BlueMapState extends State<BlueMap> {
  late final osm.MapController _osmController;
  late final BlueMapController _controller;

  /// Completes when the platform map reports ready. Everything queued by
  /// [_whenReady] waits on this.
  final Completer<void> _ready = Completer<void>();

  /// Serialises queued work. Without this, two calls awaiting [_ready] would
  /// both resume in the same microtask turn and race — two `addMarker`s landing
  /// out of order is harmless, but an `addMarker` overtaking the `removeMarker`
  /// it was meant to replace leaves a duplicate pin.
  Future<void> _queue = Future<void>.value();

  /// Where each marker currently sits, by id. The plugin removes markers by
  /// coordinate, so this is what lets a screen move one without tracking its
  /// previous position itself.
  final Map<String, BlueMapMarker> _drawnMarkers = {};

  /// Plugin road keys by polyline id, for targeted removal.
  final Map<String, String> _drawnRoadKeys = {};
  final Map<String, BlueMapPolyline> _drawnPolylines = {};
  final Map<String, BlueMapCircle> _drawnCircles = {};

  /// Debounces [BlueMap.onCameraIdle].
  Timer? _idleTimer;

  /// Last known zoom, used to size cluster cells. Seeded from the requested
  /// initial zoom so the first render clusters correctly rather than waiting
  /// for the user to move the map.
  late double _zoom = widget.initialZoom;

  /// Members of each cluster pin currently drawn, so a tap can zoom to fit
  /// them.
  final Map<String, MarkerCluster> _clusters = {};

  /// The marker list actually drawn — [BlueMap.markers] as given, or the
  /// clustered reduction of it.
  List<BlueMapMarker> get _effectiveMarkers {
    if (!widget.clusterMarkers) return widget.markers;

    final clusters = MarkerClusterer.cluster(
      markers: widget.markers,
      zoom: _zoom,
      radiusPx: widget.clusterRadiusPx,
    );

    _clusters
      ..clear()
      ..addEntries(clusters.map((c) => MapEntry(c.id, c)));

    return clusters.map((c) {
      if (c.isSingle) return c.members.first;
      return BlueMapMarker(
        id: c.id,
        position: c.center,
        child: widget.clusterBuilder?.call(c.count) ?? _defaultClusterBadge(c.count),
      );
    }).toList(growable: false);
  }

  Widget _defaultClusterBadge(int count) {
    // Grows with the count, but sub-linearly — a 200-marker cluster should read
    // as "many", not occupy a quarter of the screen.
    final diameter = 34.0 + math.min(18.0, math.log(count) * 5);
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade600,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: diameter * 0.36,
        ),
      ),
    );
  }

  /// Expands a tapped cluster by framing its members.
  void _onClusterTapped(MarkerCluster cluster) {
    final bounds = cluster.bounds;
    if (bounds == null) return;
    // Members sitting on the exact same coordinate produce a zero-area box that
    // no zoom can separate; step in a fixed amount instead of fitting.
    if (bounds.southwest == bounds.northeast) {
      _controller.moveTo(cluster.center, zoom: math.min(_zoom + 3, 19));
      return;
    }
    _controller.fitBounds(bounds, padding: 80);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // India-wide rather than 0,0 — an unset map should look like "not zoomed
    // in yet", not like a bug in the Gulf of Guinea.
    const fallback = LatLng(22.5937, 78.9629);
    final start = widget.initialCenter ?? fallback;

    _osmController = (widget.trackUserLocation || widget.myLocationEnabled) &&
            widget.initialCenter == null
        ? osm.MapController.withUserPosition(
            trackUserLocation: osm.UserTrackingOption(
              enableTracking: widget.trackUserLocation,
              unFollowUser: !widget.trackUserLocation,
            ),
          )
        : osm.MapController.withPosition(initPosition: _toGeoPoint(start));

    _controller = BlueMapController._(this);
    // After the first frame so a screen's onMapCreated can safely call
    // setState — during initState it cannot.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMapCreated?.call(_controller);
    });
  }

  /// Runs [action] once the map is ready, in call order, swallowing failures.
  ///
  /// A camera move or marker update that throws is never worth taking the
  /// screen down for — the map is almost always decoration around content that
  /// still works.
  Future<void> _whenReady(Future<void> Function() action) {
    _queue = _queue.then((_) async {
      await _ready.future;
      if (!mounted) return;
      try {
        await action();
      } catch (_) {
        // Map operations fail for transient reasons — a disposed platform view,
        // a controller torn down mid-flight. Never fatal.
      }
    });
    return _queue;
  }

  void _onMapIsReady(bool ready) {
    if (!ready || _ready.isCompleted) return;
    _ready.complete();
    // Draw whatever the screen asked for before the map existed.
    _syncMarkers(const [], _effectiveMarkers);
    _syncPolylines(const [], widget.polylines);
    _syncCircles(widget.circles);
    widget.onMapReady?.call();
  }

  @override
  void didUpdateWidget(covariant BlueMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.markers, widget.markers)) {
      _syncMarkers(oldWidget.markers, _effectiveMarkers);
    }
    if (!identical(oldWidget.polylines, widget.polylines)) {
      _syncPolylines(oldWidget.polylines, widget.polylines);
    }
    if (!identical(oldWidget.circles, widget.circles)) {
      _syncCircles(widget.circles);
    }
  }

  // --------------------------------------------------------------- diffing

  void _syncMarkers(List<BlueMapMarker> before, List<BlueMapMarker> after) {
    final wanted = {for (final m in after) m.id: m};

    _whenReady(() async {
      // Removals first, so a marker that moved onto another's old coordinate
      // cannot be clobbered by the wrong delete.
      for (final entry in _drawnMarkers.entries.toList()) {
        if (!wanted.containsKey(entry.key)) {
          await _osmController.removeMarker(_toGeoPoint(entry.value.position));
          _drawnMarkers.remove(entry.key);
        }
      }

      for (final marker in after) {
        final drawn = _drawnMarkers[marker.id];

        if (drawn == null) {
          await _osmController.addMarker(
            _toGeoPoint(marker.position),
            markerIcon: _iconFor(marker),
            angle: marker.angle,
            iconAnchor: marker.osmAnchor,
          );
          _drawnMarkers[marker.id] = marker;
          continue;
        }

        final moved = drawn.position != marker.position;
        final restyled = !drawn.sameAppearanceAs(marker);
        if (!moved && !restyled) continue;

        if (moved) {
          // One call, so the marker never blinks out of existence between a
          // remove and an add.
          await _osmController.changeLocationMarker(
            oldLocation: _toGeoPoint(drawn.position),
            newLocation: _toGeoPoint(marker.position),
            markerIcon: _iconFor(marker),
            angle: marker.angle,
            iconAnchor: marker.osmAnchor,
          );
        } else {
          await _osmController.setMarkerIcon(
            _toGeoPoint(marker.position),
            _iconFor(marker),
          );
        }
        _drawnMarkers[marker.id] = marker;
      }
    });
  }

  void _syncPolylines(
      List<BlueMapPolyline> before, List<BlueMapPolyline> after) {
    final wanted = {for (final p in after) p.id: p};

    _whenReady(() async {
      for (final id in _drawnRoadKeys.keys.toList()) {
        final replacement = wanted[id];
        final drawn = _drawnPolylines[id];
        // Roads cannot be edited in place, so an unchanged one is left alone
        // and a changed one is torn down and redrawn.
        if (replacement != null && drawn != null && drawn.sameAs(replacement)) {
          continue;
        }
        await _osmController.removeRoad(roadKey: _drawnRoadKeys[id]!);
        _drawnRoadKeys.remove(id);
        _drawnPolylines.remove(id);
      }

      for (final line in after) {
        if (_drawnRoadKeys.containsKey(line.id)) continue;
        if (line.points.length < 2) continue;

        final key = await _osmController.drawRoadManually(
          line.points.map(_toGeoPoint).toList(growable: false),
          osm.RoadOption(
            roadColor: line.color,
            roadWidth: line.width,
            roadBorderColor: line.borderColor,
            roadBorderWidth: line.borderWidth,
            isDotted: line.isDotted,
            // Never steal the camera — screens decide their own framing, and a
            // route that re-zooms the map on every tracking update is unusable.
            zoomInto: false,
          ),
        );
        _drawnRoadKeys[line.id] = key;
        _drawnPolylines[line.id] = line;
      }
    });
  }

  void _syncCircles(List<BlueMapCircle> after) {
    final wanted = {for (final c in after) c.id: c};

    _whenReady(() async {
      for (final id in _drawnCircles.keys.toList()) {
        final replacement = wanted[id];
        // Circles cannot be edited in place either — an unchanged one is left
        // alone, a changed one is removed and redrawn.
        if (replacement != null && _drawnCircles[id]!.sameAs(replacement)) {
          continue;
        }
        await _osmController.removeCircle(id);
        _drawnCircles.remove(id);
      }

      for (final circle in after) {
        if (_drawnCircles.containsKey(circle.id)) continue;
        await _osmController.drawCircle(
          osm.CircleOSM(
            key: circle.id,
            centerPoint: _toGeoPoint(circle.center),
            radius: circle.radiusMetres,
            color: circle.color,
            borderColor: circle.borderColor,
            strokeWidth: circle.strokeWidth,
          ),
        );
        _drawnCircles[circle.id] = circle;
      }
    });
  }

  osm.MarkerIcon _iconFor(BlueMapMarker marker) {
    if (marker.child != null) {
      return osm.MarkerIcon(iconWidget: marker.child);
    }
    return osm.MarkerIcon(
      icon: Icon(
        marker.icon,
        color: marker.color ?? Colors.red,
        size: marker.size,
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    Widget map = osm.OSMFlutter(
      controller: _osmController,
      onMapIsReady: _onMapIsReady,
      mapIsLoading: widget.loadingWidget ??
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      onGeoPointClicked: (point) {
        final tapped = LatLng(point.latitude, point.longitude);
        final hit = _drawnMarkers.entries
            .where((e) => e.value.position == tapped)
            .firstOrNull;
        if (hit == null) {
          widget.onTap?.call(tapped);
          return;
        }
        // A cluster badge expands rather than reporting a tap — its id is
        // synthetic and means nothing to the screen.
        final cluster = _clusters[hit.key];
        if (cluster != null && !cluster.isSingle) {
          _onClusterTapped(cluster);
          return;
        }
        widget.onMarkerTap?.call(hit.key);
      },
      onGeoPointLongPress: (point) =>
          widget.onLongPress?.call(LatLng(point.latitude, point.longitude)),
      onMapMoved: (region) {
        final centre =
            LatLng(region.center.latitude, region.center.longitude);
        widget.onCameraMoved?.call(centre);

        // Cluster cells are sized in screen pixels, so a zoom change alters
        // which markers group together. Re-cluster when the level actually
        // changes — panning at a fixed zoom must not, or every drag would
        // rebuild every pin.
        if (widget.clusterMarkers) {
          _osmController.getZoom().then((z) {
            if (!mounted || z.roundToDouble() == _zoom.roundToDouble()) return;
            _zoom = z;
            _syncMarkers(const [], _effectiveMarkers);
          }).catchError((_) {});
        }
        if (widget.onCameraIdle != null) {
          _idleTimer?.cancel();
          _idleTimer = Timer(widget.cameraIdleDelay, () {
            if (mounted) widget.onCameraIdle!.call(centre);
          });
        }
      },
      osmOption: osm.OSMOption(
        zoomOption: osm.ZoomOption(
          initZoom: widget.initialZoom.clamp(2.0, 19.0),
          minZoomLevel: widget.minZoom.clamp(2.0, 19.0),
          maxZoomLevel: widget.maxZoom.clamp(2.0, 19.0),
        ),
        showZoomController: widget.showZoomControls,
        // The plugin's own badge is replaced by our own, so attribution styling
        // is consistent with StaticMapPreview and can be positioned around each
        // screen's overlays.
        showContributorBadgeForOSM: false,
        enableRotationByGesture: false,
        userTrackingOption: widget.trackUserLocation
            ? const osm.UserTrackingOption(
                enableTracking: true, unFollowUser: false)
            : null,
        userLocationMarker: widget.myLocationEnabled
            ? osm.UserLocationMaker(
                personMarker: const osm.MarkerIcon(
                  icon: Icon(Icons.my_location, color: Colors.blue, size: 40),
                ),
                directionArrowMarker: const osm.MarkerIcon(
                  icon: Icon(Icons.navigation, color: Colors.blue, size: 40),
                ),
              )
            : null,
      ),
    );

    if (!widget.interactive) {
      map = AbsorbPointer(absorbing: true, child: map);
    }

    if (!widget.showAttribution) return map;

    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: Colors.white.withValues(alpha: 0.7),
              child: Text(
                OsmConfig.attribution,
                style: const TextStyle(fontSize: 8, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
