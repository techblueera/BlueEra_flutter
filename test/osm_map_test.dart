import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/core/map/marker_cluster.dart';
import 'package:BlueEra/core/map/osm_geocoder.dart';
import 'package:BlueEra/core/map/osrm_routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the pure functions in the OSM map layer — the parts that are easy to
/// get quietly wrong and impossible to eyeball once a route is drawn on a map.
void main() {
  group('polyline decoding', () {
    test('decodes the reference polyline from the algorithm spec', () {
      // The canonical example: `_p~iF~ps|U_ulLnnqC_mqNvxq`@` is documented as
      // decoding to these three coordinates. OSRM emits the same format at the
      // same precision, so passing this proves both.
      final points = OsrmRouting.decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points.length, 3);
      expect(points[0].latitude, closeTo(38.5, 0.00001));
      expect(points[0].longitude, closeTo(-120.2, 0.00001));
      expect(points[1].latitude, closeTo(40.7, 0.00001));
      expect(points[1].longitude, closeTo(-120.95, 0.00001));
      expect(points[2].latitude, closeTo(43.252, 0.00001));
      expect(points[2].longitude, closeTo(-126.453, 0.00001));
    });

    test('returns nothing for an empty string rather than throwing', () {
      expect(OsrmRouting.decodePolyline(''), isEmpty);
    });
  });

  group('place id round-trip', () {
    test('coordinates survive encode then decode', () {
      const original = LatLng(30.316496, 78.032188);
      final id = OsmPlace.placeIdFor(original);
      final decoded = OsmPlace.locationFromPlaceId(id);

      expect(decoded, isNotNull);
      expect(decoded!.latitude, closeTo(original.latitude, 0.000001));
      expect(decoded.longitude, closeTo(original.longitude, 0.000001));
    });

    test('negative coordinates survive the round-trip', () {
      // The id is comma-separated and minus signs are not, but this is exactly
      // the kind of thing a naive split gets wrong.
      const original = LatLng(-33.8688, 151.2093);
      final decoded = OsmPlace.locationFromPlaceId(
        OsmPlace.placeIdFor(original),
      );

      expect(decoded!.latitude, closeTo(-33.8688, 0.000001));
      expect(decoded.longitude, closeTo(151.2093, 0.000001));
    });

    test('a Google place_id from an older build is rejected, not misparsed', () {
      expect(
        OsmPlace.locationFromPlaceId('ChIJLfyY2E4bDTkRVBLNhOsQyPo'),
        isNull,
      );
      expect(OsmPlace.locationFromPlaceId(null), isNull);
      expect(OsmPlace.locationFromPlaceId('osm:nonsense'), isNull);
    });
  });

  group('bounds', () {
    test('contains every point it was built from', () {
      const points = [
        LatLng(30.30, 78.00),
        LatLng(30.35, 78.05),
        LatLng(30.32, 77.98),
      ];
      final bounds = LatLngBounds.containing(points)!;

      for (final p in points) {
        expect(bounds.contains(p), isTrue);
      }
      expect(bounds.southwest.latitude, closeTo(30.30, 0.0001));
      expect(bounds.southwest.longitude, closeTo(77.98, 0.0001));
      expect(bounds.northeast.latitude, closeTo(30.35, 0.0001));
      expect(bounds.northeast.longitude, closeTo(78.05, 0.0001));
    });

    test('a single point yields a zero-area box that padding can inflate', () {
      final bounds = LatLngBounds.containing([const LatLng(30.0, 78.0)])!;
      expect(bounds.southwest, bounds.northeast);

      final padded = bounds.padded();
      expect(padded.southwest.latitude, lessThan(30.0));
      expect(padded.northeast.latitude, greaterThan(30.0));
    });

    test('empty input yields null rather than an inverted box', () {
      expect(LatLngBounds.containing(const []), isNull);
    });
  });

  group('distance', () {
    test('matches a known city-to-city great-circle distance', () {
      // Dehradun to Delhi is ~180 km as the crow flies.
      final metres = distanceBetweenMetres(
        const LatLng(30.3165, 78.0322),
        const LatLng(28.6139, 77.2090),
      );
      expect(metres / 1000, closeTo(200, 15));
    });

    test('is zero for a point against itself', () {
      const p = LatLng(30.3165, 78.0322);
      expect(distanceBetweenMetres(p, p), closeTo(0, 0.001));
    });
  });

  group('marker clustering', () {
    BlueMapMarker pin(String id, double lat, double lng) => BlueMapMarker(
          id: id,
          position: LatLng(lat, lng),
          icon: Icons.place,
        );

    test('far-apart markers stay separate at street zoom', () {
      final clusters = MarkerClusterer.cluster(
        markers: [
          pin('a', 30.3165, 78.0322),
          pin('b', 28.6139, 77.2090), // ~200 km away
        ],
        zoom: 16,
      );
      expect(clusters.length, 2);
      expect(clusters.every((c) => c.isSingle), isTrue);
    });

    test('the same markers collapse into one cluster at country zoom', () {
      final clusters = MarkerClusterer.cluster(
        markers: [
          pin('a', 30.3165, 78.0322),
          pin('b', 28.6139, 77.2090),
        ],
        zoom: 4,
      );
      expect(clusters.length, 1);
      expect(clusters.first.count, 2);
    });

    test('a cluster centre is the mean of its members', () {
      final clusters = MarkerClusterer.cluster(
        markers: [
          pin('a', 30.0, 78.0),
          pin('b', 30.0, 78.0002),
        ],
        zoom: 10,
      );
      expect(clusters.length, 1);
      expect(clusters.first.center.latitude, closeTo(30.0, 0.0001));
      expect(clusters.first.center.longitude, closeTo(78.0001, 0.0001));
    });

    test('every marker survives clustering — none are dropped', () {
      final markers = List.generate(
        50,
        (i) => pin('m$i', 30.0 + i * 0.001, 78.0 + i * 0.001),
      );
      for (final zoom in [4.0, 8.0, 12.0, 16.0, 19.0]) {
        final clusters = MarkerClusterer.cluster(markers: markers, zoom: zoom);
        final total = clusters.fold<int>(0, (sum, c) => sum + c.count);
        expect(total, markers.length, reason: 'lost a marker at zoom $zoom');
      }
    });

    test('cluster ids are stable across repeated runs at the same zoom', () {
      final markers = [pin('a', 30.0, 78.0), pin('b', 30.0005, 78.0005)];
      final first = MarkerClusterer.cluster(markers: markers, zoom: 12);
      final second = MarkerClusterer.cluster(markers: markers, zoom: 12);
      expect(
        first.map((c) => c.id).toList(),
        second.map((c) => c.id).toList(),
      );
    });

    test('a single marker clusters to itself, keeping its own id', () {
      final clusters =
          MarkerClusterer.cluster(markers: [pin('solo', 30.0, 78.0)], zoom: 12);
      expect(clusters.single.id, 'solo');
      expect(clusters.single.isSingle, isTrue);
    });

    test('empty input yields no clusters', () {
      expect(MarkerClusterer.cluster(markers: const [], zoom: 12), isEmpty);
    });
  });

  group('waypoint parsing', () {
    test('parses a well-formed lat,lng pair', () {
      final point =
          const PolylineWayPoint(location: '30.3165,78.0322').toPoint();
      expect(point!.latitude, closeTo(30.3165, 0.0001));
      expect(point.longitude, closeTo(78.0322, 0.0001));
    });

    test('rejects a malformed stop instead of sending garbage to the router',
        () {
      expect(const PolylineWayPoint(location: 'somewhere').toPoint(), isNull);
      expect(const PolylineWayPoint(location: '1,2,3').toPoint(), isNull);
    });
  });
}
