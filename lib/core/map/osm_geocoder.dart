import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/core/map/osm_config.dart';
import 'package:BlueEra/core/map/osm_http_client.dart';

/// One address suggestion, with its coordinates already attached.
///
/// That last part is the important difference from what this replaced. Google's
/// autocomplete returned a `place_id` and no geometry, so every tapped row cost
/// a second, separately-billed Place Details call — and four screens in this app
/// had loops that resolved *every* prediction to render a distance label, at
/// five lookups per keystroke burst (`docs/GOOGLE_MAPS_COST_GUIDE.md` §3.1).
///
/// Photon returns coordinates inline with each suggestion, so that entire class
/// of cost and complexity disappears: the lookup a row needs has already
/// happened by the time the row is drawn.
class OsmPlace {
  const OsmPlace({
    required this.placeId,
    required this.description,
    required this.location,
    this.name,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  /// Synthetic, and **not** an OSM object id.
  ///
  /// The app's screens and cached models pass a `placeId` string around and
  /// later ask to resolve it to coordinates. Rather than break that contract on
  /// forty call sites, the coordinates are encoded *into* the id — see
  /// [locationFromPlaceId]. Resolving one is then pure string parsing: no
  /// network, no cache, no failure mode.
  ///
  /// An OSM node id would have been the natural choice, but resolving it back
  /// would require a Nominatim `/lookup` round-trip, which is exactly the
  /// billed-second-call pattern we just escaped.
  final String placeId;

  /// Comma-joined human-readable address; what the suggestion row displays.
  /// Mirrors Google's `description` field.
  final String description;

  final LatLng location;
  final String? name;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  /// The shape the app's existing `PlacePrediction.fromJson` already parses, so
  /// screens reading `data['predictions']` keep working untouched.
  Map<String, dynamic> toPredictionJson() => {
        'description': description,
        'place_id': placeId,
        // Not part of Google's payload, but harmless to include and it lets a
        // caller skip the resolve step entirely if it wants to.
        'lat': location.latitude,
        'lng': location.longitude,
        'city': city,
      };

  /// Coordinates packed into an id string. Six decimals is ~11 cm — far beyond
  /// what any address needs, and it keeps the id short.
  static String placeIdFor(LatLng location) =>
      'osm:${location.latitude.toStringAsFixed(6)},'
      '${location.longitude.toStringAsFixed(6)}';

  /// Unpacks [placeIdFor]. Null when the string is not one of ours — a
  /// persisted Google `place_id` from a previous app version, most likely,
  /// which the caller should treat as unresolvable and re-search.
  static LatLng? locationFromPlaceId(String? placeId) {
    if (placeId == null || !placeId.startsWith('osm:')) return null;
    final parts = placeId.substring(4).split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }
}

/// A reverse-geocoded address, broken into the parts the app actually reads.
class OsmAddress {
  const OsmAddress({
    required this.formattedAddress,
    required this.location,
    this.houseNumber,
    this.road,
    this.suburb,
    this.city,
    this.district,
    this.state,
    this.postcode,
    this.country,
  });

  final String formattedAddress;
  final LatLng location;
  final String? houseNumber;
  final String? road;
  final String? suburb;
  final String? city;
  final String? district;
  final String? state;
  final String? postcode;
  final String? country;

  /// Re-shaped as a Google Geocoding API response.
  ///
  /// `LocationController.getAddressDetails` parses `GeocodingResponse` and picks
  /// components out by Google's `types` strings — specifically `locality` and
  /// `postal_code`. Emitting that shape means the controller, and the model it
  /// parses, do not change at all.
  Map<String, dynamic> toGoogleGeocodeJson() {
    Map<String, dynamic> component(String? value, List<String> types) => {
          'long_name': value ?? '',
          'short_name': value ?? '',
          'types': types,
        };

    final components = <Map<String, dynamic>>[
      if (houseNumber != null) component(houseNumber, ['street_number']),
      if (road != null) component(road, ['route']),
      if (suburb != null)
        component(suburb, ['sublocality', 'sublocality_level_1']),
      // `locality` is what the controller reads for "city".
      if (city != null) component(city, ['locality', 'political']),
      if (district != null)
        component(district, ['administrative_area_level_2', 'political']),
      if (state != null)
        component(state, ['administrative_area_level_1', 'political']),
      if (country != null) component(country, ['country', 'political']),
      // `postal_code` is what the controller reads for "pinCode".
      if (postcode != null) component(postcode, ['postal_code']),
    ];

    return {
      'status': 'OK',
      'results': [
        {
          'formatted_address': formattedAddress,
          'address_components': components,
          'geometry': {
            'location': {
              'lat': location.latitude,
              'lng': location.longitude,
            },
          },
          'place_id': OsmPlace.placeIdFor(location),
        },
      ],
    };
  }

  /// Re-shaped as a Google **Place Details** response, for
  /// `PlaceDetailsResponse.fromJson`.
  Map<String, dynamic> toGooglePlaceDetailsJson() => {
        'status': 'OK',
        'result': toGoogleGeocodeJson()['results'][0],
      };
}

/// Address search and reverse geocoding over OSM services.
///
/// Search goes to **Photon**, reverse goes to **Nominatim** — see [OsmConfig]
/// for why they are different services and what must change before production.
class OsmGeocoder {
  const OsmGeocoder._();

  /// Type-ahead address search, biased towards [near] when a fix is available.
  ///
  /// A bias, not a filter — matching the old behaviour, where `strictbounds`
  /// was deliberately not sent so a user in Dehradun could still search an
  /// address in Delhi and simply see it ranked below local results.
  ///
  /// Returns an empty list on any failure. Callers render "no results", which
  /// is the same thing a genuinely empty search shows, so a dropped connection
  /// degrades quietly rather than throwing into a text field's onChanged.
  static Future<List<OsmPlace>> autocomplete({
    required String query,
    LatLng? near,
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final response = await OsmHttpClient.instance.get(
        '${OsmConfig.photonBaseUrl}/api',
        queryParameters: OsmHttpClient.withKey({
          'q': trimmed,
          'limit': limit,
          'lang': 'en',
          if (near != null && !near.isZero) ...{
            'lat': near.latitude,
            'lon': near.longitude,
          },
        }),
      );

      final body = response.data;
      if (body is! Map) return const [];
      final features = body['features'];
      if (features is! List) return const [];

      return features
          .map(_placeFromPhotonFeature)
          .whereType<OsmPlace>()
          // Photon is worldwide and takes no country filter, so the country
          // restriction the Google calls expressed as `components=country:in`
          // is applied here instead.
          .where((p) => _matchesCountry(p))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// City-name search, replacing the old `types=(cities)` autocomplete.
  ///
  /// Worth noting this is still a network call for what is a **static
  /// dataset** — the cities of a state do not change between releases. Both
  /// cost guides flag bundling it as a JSON asset instead
  /// (`GOOGLE_MAPS_COST_GUIDE.md` §3A.4). That is now a latency and
  /// rate-limit argument rather than a billing one, but it still stands.
  static Future<List<OsmPlace>> searchCities({
    required String state,
    int limit = 20,
  }) async {
    final results = await autocomplete(query: state, limit: limit);
    return results.where((p) => p.city != null && p.city!.isNotEmpty).toList();
  }

  /// Coordinates to a structured address.
  ///
  /// Prefer the on-device geocoder (`placemarkFromCoordinates` from the
  /// `geocoding` package) where you can — it is free, works offline, and does
  /// not consume the Nominatim rate limit that the whole app shares. This is
  /// the fallback for when it returns nothing.
  static Future<OsmAddress?> reverse(LatLng location) async {
    try {
      final response = await OsmHttpClient.instance.get(
        '${OsmConfig.nominatimBaseUrl}/reverse',
        queryParameters: OsmHttpClient.withKey({
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
          'accept-language': 'en',
        }),
      );

      final body = response.data;
      if (body is! Map) return null;
      final address = body['address'];
      if (address is! Map) return null;

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      return OsmAddress(
        formattedAddress: (body['display_name'] as String?)?.trim() ?? '',
        location: location,
        houseNumber: pick(['house_number']),
        road: pick(['road', 'pedestrian', 'footway']),
        suburb: pick(['suburb', 'neighbourhood', 'residential', 'quarter']),
        // OSM tags a settlement by its size, so "the city" can arrive under any
        // of these depending on how populous it is. Checking one key finds
        // Delhi and misses every town.
        city: pick(['city', 'town', 'village', 'municipality', 'hamlet']),
        district: pick(['state_district', 'county', 'district']),
        state: pick(['state', 'region']),
        postcode: pick(['postcode']),
        country: pick(['country']),
      );
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------ parsing

  static OsmPlace? _placeFromPhotonFeature(dynamic feature) {
    if (feature is! Map) return null;

    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final coords = geometry['coordinates'];
    // GeoJSON is [longitude, latitude] — reversed from every Google payload
    // this codebase used to read.
    if (coords is! List || coords.length < 2) return null;

    final lng = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final props = feature['properties'];
    final p = props is Map ? props : const {};

    String? str(String key) {
      final value = p[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final location = LatLng(lat, lng);

    // Built widest-first the way a postal address reads, de-duplicated because
    // Photon frequently repeats a value across fields — a village's `name` and
    // its `city` are often the same string, and "Rishikesh, Rishikesh,
    // Uttarakhand" looks like a bug to a user.
    final parts = <String>[
      if (str('name') != null) str('name')!,
      if (str('housenumber') != null && str('street') != null)
        '${str('housenumber')} ${str('street')}'
      else if (str('street') != null)
        str('street')!,
      if (str('district') != null) str('district')!,
      if (str('city') != null) str('city')!,
      if (str('state') != null) str('state')!,
      if (str('postcode') != null) str('postcode')!,
    ];

    final seen = <String>{};
    final description =
        parts.where((part) => seen.add(part.toLowerCase())).join(', ');

    return OsmPlace(
      placeId: OsmPlace.placeIdFor(location),
      description: description.isEmpty ? (str('name') ?? '') : description,
      location: location,
      name: str('name'),
      city: str('city') ?? str('district'),
      state: str('state'),
      postcode: str('postcode'),
      country: str('country'),
    );
  }

  static bool _matchesCountry(OsmPlace place) {
    final wanted = OsmConfig.countryCode.trim();
    if (wanted.isEmpty) return true;
    final country = place.country?.toLowerCase();
    // Photon returns the country's English name, not its ISO code, so the two
    // common spellings of the configured country are checked by name. An
    // unknown country is kept rather than dropped — filtering out a result we
    // could not classify would be worse than showing it.
    if (country == null) return true;
    if (wanted.toLowerCase() == 'in') return country == 'india';
    return true;
  }
}
