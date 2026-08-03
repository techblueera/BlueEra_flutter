/// Every OpenStreetMap-backed endpoint the app talks to, in one place.
///
/// ## Why this file exists
///
/// The app used to buy four separate Google products — Places Autocomplete,
/// Place Details, Geocoding and Directions — plus a Dynamic Maps load for every
/// `GoogleMap` widget. All of that is now served by OSM-based providers, and the
/// only thing that changes between "free public servers" and "a provider we pay
/// or host" is a **host name**. So the host names live here and nowhere else.
///
/// ## READ THIS BEFORE SHIPPING TO PRODUCTION
///
/// The defaults below point at the **public community servers**. They are free,
/// they are excellent for development, and their usage policies do **not permit
/// the traffic a consumer app generates**:
///
///  * **Nominatim** (`nominatim.openstreetmap.org`) — absolute maximum of 1
///    request/second, a valid identifying `User-Agent` is mandatory, results may
///    not be scraped in bulk, and *autocomplete-style keystroke traffic is
///    explicitly forbidden*. That last rule is why address search here goes to
///    Photon instead, and Nominatim is used only for one-off reverse geocodes.
///  * **Photon** (`photon.komoot.io`) — the demo instance. Komoot ask that you
///    self-host rather than point a production app at it. It is built for
///    type-ahead, so it is the correct *shape* of service; it is the *host* that
///    needs replacing.
///  * **OSRM** (`router.project-osrm.org`) — the demo server. The project states
///    plainly that it is for testing and must not be used in production.
///
/// Ignoring this does not fail loudly. It fails as rate-limit errors and IP
/// blocks in whichever city happens to be busiest — i.e. in production, on the
/// users who matter most.
///
/// ### What to do instead
///
/// Pick one and set it in [configure] during app start-up:
///
///  * **Self-host.** Nominatim + Photon + OSRM all run from an India-only OSM
///    extract on a single mid-size VM. Highest effort, zero per-request cost,
///    and no third party sees your users' addresses.
///  * **Paid provider.** Geoapify, LocationIQ, Stadia Maps and MapTiler all
///    expose Nominatim/Photon/OSRM-compatible endpoints, so they are a host +
///    [apiKey] change and nothing more. Far cheaper than Google Maps Platform.
///
/// Either way the code below does not change — which is the whole point of
/// routing every call through this class.
class OsmConfig {
  const OsmConfig._();

  // -------------------------------------------------------------- geocoding

  /// Type-ahead address search (Photon-compatible).
  ///
  /// Photon returns coordinates **inline with every suggestion**, which is a
  /// genuine improvement over what this replaced: Google's autocomplete returned
  /// a `place_id` with no geometry, so resolving a tapped row cost a second
  /// billed Place Details call. Here the tap costs nothing at all.
  static String photonBaseUrl = 'https://photon.komoot.io';

  /// Reverse geocoding — coordinates to a structured address (Nominatim-compatible).
  ///
  /// Deliberately separate from [photonBaseUrl]: Photon's reverse endpoint
  /// returns thinner address detail than Nominatim's, and the one caller here
  /// needs `locality` and `postal_code` specifically.
  ///
  /// Note the app *prefers* the on-device geocoder (`geocoding` package) for
  /// reverse lookups — free, offline-capable, no network. This is the fallback
  /// for when that returns nothing.
  static String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // ---------------------------------------------------------------- routing

  /// Road routing — the polyline, distance and duration for a journey
  /// (OSRM-compatible).
  static String osrmBaseUrl = 'https://router.project-osrm.org';

  // ------------------------------------------------------------------ tiles

  /// Raster tile template for static (non-interactive) map images.
  ///
  /// `tile.openstreetmap.org` has its own tile usage policy — no bulk
  /// downloading, and a valid `User-Agent`. Swap for your provider's template
  /// alongside the services above. Placeholders: `{z}`, `{x}`, `{y}`.
  static String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Attribution string. OSM data is ODbL-licensed and attribution is a
  /// **licence condition, not a courtesy** — every visible map must carry it.
  /// [OsmAttribution] renders this; don't hide it.
  static String attribution = '© OpenStreetMap contributors';

  // ----------------------------------------------------------------- shared

  /// Sent as `?api_key=` / `Authorization` by providers that need one. Null for
  /// the public servers, which take no key.
  static String? apiKey;

  /// Identifies this app to OSM services. Nominatim **rejects requests without
  /// a meaningful one**, and the tile policy requires it too. Must name a real
  /// app and a contactable address.
  static String userAgent = 'BlueEra/14.0.48 (support@bluecs.in)';

  /// Bias search results towards a country. India-only here, matching the
  /// `components=country:in` the Google calls used to send.
  static String countryCode = 'in';

  /// Point every OSM service at different hosts. Call once from `main()`, before
  /// any map or search screen can run.
  ///
  /// ```dart
  /// OsmConfig.configure(
  ///   photonBaseUrl:    'https://photon.yourdomain.in',
  ///   nominatimBaseUrl: 'https://nominatim.yourdomain.in',
  ///   osrmBaseUrl:      'https://osrm.yourdomain.in',
  ///   tileUrlTemplate:  'https://tiles.yourdomain.in/{z}/{x}/{y}.png',
  /// );
  /// ```
  static void configure({
    String? photonBaseUrl,
    String? nominatimBaseUrl,
    String? osrmBaseUrl,
    String? tileUrlTemplate,
    String? attribution,
    String? apiKey,
    String? userAgent,
    String? countryCode,
  }) {
    if (photonBaseUrl != null) OsmConfig.photonBaseUrl = photonBaseUrl;
    if (nominatimBaseUrl != null) OsmConfig.nominatimBaseUrl = nominatimBaseUrl;
    if (osrmBaseUrl != null) OsmConfig.osrmBaseUrl = osrmBaseUrl;
    if (tileUrlTemplate != null) OsmConfig.tileUrlTemplate = tileUrlTemplate;
    if (attribution != null) OsmConfig.attribution = attribution;
    if (apiKey != null) OsmConfig.apiKey = apiKey;
    if (userAgent != null) OsmConfig.userAgent = userAgent;
    if (countryCode != null) OsmConfig.countryCode = countryCode;
  }

  /// True while any endpoint still points at a public community server — i.e.
  /// this build is not fit for production traffic.
  ///
  /// Wired to a start-up assert in debug so the demo hosts cannot reach a
  /// release build unnoticed.
  static bool get isUsingPublicDemoServers =>
      photonBaseUrl.contains('photon.komoot.io') ||
      nominatimBaseUrl.contains('nominatim.openstreetmap.org') ||
      osrmBaseUrl.contains('router.project-osrm.org');
}
