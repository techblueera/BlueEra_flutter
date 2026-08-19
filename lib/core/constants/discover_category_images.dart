/// The 2026 Discover category artwork — the illustrated set shipped in
/// `assets/discover_images/`.
///
/// ## Why this is separate from [DiscoverIcons]
///
/// [DiscoverIcons] is one shared pool: `textile` dresses both the Home-Made
/// Product "Textile" tile and the Home-Services "Tailor" tile, `jobOnsite`
/// covers both "Onsite" and "Near By", `landsPlots` covers the Sell and Rent
/// variants. Repointing a constant there to new art would move every tile that
/// borrows it, including ones nobody asked to change.
///
/// These constants are per-tile instead, so each of the six lists below owns
/// its own picture and a future swap touches exactly one row.
///
/// ## Naming
///
/// The filenames are normalised from the delivered folder (spaces, `&` and
/// parentheses out, one prefix per group in). Two of them were also delivered
/// under the wrong name and are renamed here to what they actually depict —
/// see [homeMadeFoodNamkeen] and [homeMadeProductHandicrafts].
class DiscoverCategoryImages {
  const DiscoverCategoryImages._();

  static const String _p = 'assets/discover_images/';

  // ── Book Your Transport → transportItemsCategories ──────────────
  static const String transportTwoWheeler = '${_p}transport_two_wheeler.png';
  static const String transportPassenger = '${_p}transport_passenger.png';
  static const String transportGoods = '${_p}transport_goods.png';
  static const String transportOutStation = '${_p}transport_out_station.png';
  static const String transportRental = '${_p}transport_rental.png';
  static const String transportLogistics = '${_p}transport_logistics.png';

  // ── Home Made Food → discoverHomeMadeFoodCategories ─────────────
  static const String homeMadeFoodTiffin = '${_p}hmf_tiffin.png';
  static const String homeMadeFoodBakery = '${_p}hmf_bakery.png';
  static const String homeMadeFoodSweets = '${_p}hmf_sweets.png';

  /// Delivered as `Sweets-1.png`, next to a `Sweets.png` that is a bowl of
  /// laddus. This one is a bowl of savoury mix, and Namkeen was the only tile
  /// in the set with no file of its own — so the name is the delivery's, not
  /// the picture's. Renamed to what it shows.
  static const String homeMadeFoodNamkeen = '${_p}hmf_namkeen.png';
  static const String homeMadeFoodPickles = '${_p}hmf_pickles.png';

  // ── Home Made Product → discoverHomeMadeProductCategories ───────
  static const String homeMadeProductArtCraft = '${_p}hmp_art_craft.png';
  static const String homeMadeProductGiftItems = '${_p}hmp_gift_items.png';

  /// Delivered as `Gift Items-1.png`, next to a `Gift Items.png` of wrapped
  /// presents. This one is pots, macramé and a painted plate — Handicrafts,
  /// the one tile in the set with no file of its own. Same mislabelling as
  /// [homeMadeFoodNamkeen].
  static const String homeMadeProductHandicrafts = '${_p}hmp_handicrafts.png';
  static const String homeMadeProductTextile = '${_p}hmp_textile.png';
  static const String homeMadeProductUtility = '${_p}hmp_utility_product.png';

  // ── Home Services → discoverHomeServicesCategories ──────────────
  static const String homeServiceTailor = '${_p}hs_tailor.png';
  static const String homeServiceBeautician = '${_p}hs_beautician.png';
  static const String homeServiceInteriorDecor = '${_p}hs_interior_decor.png';
  static const String homeServiceDigitalMarketing =
      '${_p}hs_digital_marketing.png';

  // ── Jobs → jobCategories ────────────────────────────────────────
  static const String jobFullTime = '${_p}job_full_time.png';
  static const String jobPartTime = '${_p}job_part_time.png';
  static const String jobRemote = '${_p}job_remote.png';
  static const String jobOnsite = '${_p}job_onsite.png';

  /// "Near By" finally has art of its own — it used to borrow the Onsite pin.
  static const String jobNearBy = '${_p}job_near_by.png';

  // ── Rent & Properties → propertyDiscoverTiles ───────────────────
  static const String propertyHousesSell = '${_p}prop_houses_sell.png';
  static const String propertyHousesRent = '${_p}prop_houses_rent.png';
  static const String propertyNewProjectsSell =
      '${_p}prop_new_projects_sell.png';
  static const String propertyLandsSell = '${_p}prop_lands_sell.png';
  static const String propertyShopsRent = '${_p}prop_shops_rent.png';
  static const String propertyShopsSell = '${_p}prop_shops_sell.png';
}
