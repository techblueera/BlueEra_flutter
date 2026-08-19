import 'package:flutter/material.dart';

/// The 2026 Discover icon set (`assets/discover/`).
///
/// These replace the older per-category art that Discover's static sections
/// used to pull out of [AppImageAssets] / `OnboardingBusinessAssets` /
/// `OnboardingIndividualAssets`. The old icons stay where they are — onboarding
/// and the me-section screens still use them — this set is Discover's.
///
/// ## They carry their own background
///
/// Every icon here is a 160×160 PNG whose artwork is already sitting on a
/// tinted, rounded-square plate (transparent outside the corner radius). That
/// is the one thing to know before using one: the old icons were bare
/// transparent renders that needed a plate drawn behind them, and Discover's
/// tiles duly drew a pale-blue CIRCLE with 14% padding. Dropping a
/// self-contained tile into that circle leaves a coloured square floating on a
/// blue disc with the disc peeking out at the corners.
///
/// So the tile widgets ([DiscoverIconTile], [DiscoverCircleTile],
/// [_DiscoverFolderPlate]) ask [isSelfContained] and, when it's true, render
/// the icon EDGE-TO-EDGE in a rounded rect with no plate and no padding.
/// Anything else — a legacy bundled asset, or a category image URL off
/// `/category` — keeps the circular plate exactly as before. That check is a
/// path prefix test, which is why every constant here must stay under [_p].
///
/// Categories whose art comes from the API can't be pointed at this set at all;
/// the matching PNGs have to be uploaded backend-side. Which sections those are
/// (and which icon in here belongs to each) is written up in
/// `docs/discover_dynamic_icons.txt`.
class DiscoverIcons {
  const DiscoverIcons._();

  static const String _p = 'assets/discover/';

  /// Bundled art OUTSIDE `assets/discover/` that nevertheless ships with its
  /// own background baked in.
  ///
  /// The "Book your Stay" set is the case this exists for. Nothing in the 2026
  /// zip is a hotel subject, so those five tiles kept their old artwork — but
  /// that artwork is not the bare cut-out the old icons usually were: each is a
  /// 640×400 render on a solid pale tint. Treated as a cut-out it got a plate
  /// drawn behind a background it already had, and the folder showed a small
  /// tinted rectangle floating inside a larger white one.
  ///
  /// An explicit list because the fact is not visible from the path, and the
  /// only alternative — decoding every PNG to sniff its corners — is not
  /// something a build method can do. Delete an entry the day its category
  /// moves to `assets/discover/`.
  static const Set<String> _selfContainedElsewhere = {
    'assets/images/hotel_stay.png',
    'assets/images/economy_stay.png',
    'assets/images/hostels_and_pg.png',
    'assets/images/functions_vacation.png',
  };

  /// True when [path] is one of these self-contained tiles, i.e. the caller
  /// must NOT draw a plate behind it. False for every other asset path and for
  /// network URLs.
  ///
  /// [DiscoverCategoryImages] counts too. Its art is the same kind — a
  /// rounded square with the tint and the border baked in — and it sits in
  /// `assets/discover_images/`, which is NOT a prefix match for
  /// `assets/discover/` (the `_` lands where the `/` is expected). Without this
  /// second prefix every one of those tiles was treated as a bare cut-out:
  /// padded, shrunk to `contain`, and given a plate behind a background it
  /// already had — the same "tinted square floating in a white one" the stay
  /// renders hit above.
  static bool isSelfContained(String? path) =>
      path != null &&
      (path.startsWith(_p) ||
          path.startsWith(_discoverImagesPrefix) ||
          _selfContainedElsewhere.contains(path));

  /// Mirror of `DiscoverCategoryImages._p`. Duplicated rather than imported to
  /// keep this file free of feature dependencies — the two must move together.
  static const String _discoverImagesPrefix = 'assets/discover_images/';

  /// A backend image rather than a bundled asset.
  static bool isNetwork(String? path) =>
      path != null &&
      (path.startsWith('http://') || path.startsWith('https://'));

  /// Whether [path] should be drawn EDGE-TO-EDGE — no plate behind it, no
  /// padding around it.
  ///
  /// Wider than [isSelfContained] by exactly one case: `/category` URLs. Most
  /// of that art now ships with its own tinted rounded square baked in, so a
  /// plate drew a background behind a background — the Grocery and Food
  /// folders showed a coloured square marooned in a white one while every
  /// bundled section beside them filled its tile.
  ///
  /// The `/category` art that is still a bare transparent cut-out is safe here
  /// because the FIT does not change with it: [fitFor] keeps network art on
  /// `contain`, so a square baked source fills a square slot exactly while a
  /// cut-out scales inside it with nothing cropped. That is the same
  /// conclusion the pinned category strip reached for the same mixed source —
  /// see `sticky_category_header_delegate.dart`.
  ///
  /// Use this for the PLATE decision and [fitFor] for the fit; they are
  /// deliberately not the same question.
  static bool fillsTile(String? path) =>
      isSelfContained(path) || isNetwork(path);

  /// How [path] should fill its tile.
  ///
  /// Self-contained art COVERS: its background is the tile, so any gap around
  /// it is a gap in the tile itself. That matters most for the sources that are
  /// not square — the stay renders are 640×400 with the subject centred in a
  /// wide field of flat tint, so `contain` letterboxed them into a small
  /// rectangle while `cover` crops the dead margins and fills the slot.
  ///
  /// Everything else CONTAINS: a bare cut-out has no background to lose, and
  /// cropping one cuts the illustration.
  static BoxFit fitFor(String? path) =>
      isSelfContained(path) ? BoxFit.cover : BoxFit.contain;

  // ── Grocery / kirana ────────────────────────────────────────────────────
  static const String generalStore = '${_p}general_store.png';
  static const String kiranaStore = '${_p}kirana_store.png';
  static const String dairyBakery = '${_p}dairy_bakery.png';

  // ── Restaurant / food service ───────────────────────────────────────────
  static const String multicuisineRestaurant =
      '${_p}multicuisine_restaurant.png';
  static const String pureVegRestaurant = '${_p}pure_veg_restaurant.png';
  static const String nonVegRestaurant = '${_p}non_veg_restaurant.png';
  static const String breakfastFastFood = '${_p}breakfast_fast_food.png';
  static const String coffeeBeverages = '${_p}coffee_beverages.png';
  static const String iceCreamCorner = '${_p}ice_cream_corner.png';
  static const String sweetNamkeen = '${_p}sweet_namkeen.png';

  // ── Home-made food ──────────────────────────────────────────────────────
  static const String tiffin = '${_p}tiffin.png';
  static const String bakery = '${_p}bakery.png';
  static const String sweets = '${_p}sweets.png';
  static const String namkeen = '${_p}namkeen.png';
  static const String pickles = '${_p}pickles.png';

  // ── Home-made products ──────────────────────────────────────────────────
  static const String artCraft = '${_p}art_craft.png';
  static const String giftItems = '${_p}gift_items.png';
  static const String handicrafts = '${_p}handicrafts.png';
  static const String textile = '${_p}textile.png';
  static const String utilityProduct = '${_p}utility_product.png';

  // ── Shopping & sales ────────────────────────────────────────────────────
  static const String electronicsGadgets = '${_p}electronics_gadgets.png';
  static const String mobilesAccessories = '${_p}mobiles_accessories.png';
  static const String fashionJewellery = '${_p}fashion_jewellery.png';
  static const String beautyPersonalCare = '${_p}beauty_personal_care.png';
  static const String booksStationery = '${_p}books_stationery.png';
  static const String kidsProducts = '${_p}kids_products.png';
  static const String homeEssentials = '${_p}home_essentials.png';
  static const String toolsHardware = '${_p}tools_hardware.png';
  static const String sportsHobby = '${_p}sports_hobby.png';

  // ── Transport / ride ────────────────────────────────────────────────────
  static const String twoWheeler = '${_p}two_wheeler.png';
  static const String passenger = '${_p}passenger.png';
  static const String goods = '${_p}goods.png';
  static const String outStation = '${_p}out_station.png';
  static const String logistics = '${_p}logistics.png';

  // ── Automotive ──────────────────────────────────────────────────────────
  static const String vehicleSales = '${_p}vehicle_sales.png';
  static const String vehicleRental = '${_p}vehicle_rental.png';
  static const String vehicleParts = '${_p}vehicle_parts.png';
  static const String vehicleService = '${_p}vehicle_service.png';
  static const String transportLogistic = '${_p}transport_logistic.png';
  static const String serviceCentreUtility = '${_p}service_centre_utility.png';

  // ── Property / rental ───────────────────────────────────────────────────
  static const String housesApartments = '${_p}houses_apartments.png';
  static const String housesApartmentsRent = '${_p}houses_apartments_rent.png';
  static const String newProjectsProperties =
      '${_p}new_projects_properties.png';
  static const String landsPlots = '${_p}lands_plots.png';
  static const String shopsOffices = '${_p}shops_offices.png';
  static const String shopsOfficesSell = '${_p}shops_offices_sell.png';
  static const String realEstateProperty = '${_p}real_estate_property.png';
  static const String propertyBroker = '${_p}property_broker.png';

  // ── Healthcare ──────────────────────────────────────────────────────────
  static const String hospitals = '${_p}hospitals.png';
  static const String doctors = '${_p}doctors.png';
  static const String labs = '${_p}labs.png';
  static const String pharmacy = '${_p}pharmacy.png';
  static const String healthMedical = '${_p}health_medical.png';

  // ── Home services / skilled work ────────────────────────────────────────
  static const String electrician = '${_p}electrician.png';
  static const String plumber = '${_p}plumber.png';
  static const String maid = '${_p}maid.png';
  static const String mechanic = '${_p}mechanic.png';
  static const String cleaner = '${_p}cleaner.png';
  static const String labour = '${_p}labour.png';
  static const String renovator = '${_p}renovator.png';
  static const String homeServicesUtility = '${_p}home_services_utility.png';

  // ── Professionals / consultants ─────────────────────────────────────────
  static const String consultingFirm = '${_p}consulting_firm.png';
  static const String legalGovtConsultant = '${_p}legal_govt_consultant.png';
  static const String financeTaxConsultant = '${_p}finance_tax_consultant.png';
  static const String traineeCareer = '${_p}trainee_career.png';
  static const String techDigital = '${_p}tech_digital.png';
  static const String mediaPublicity = '${_p}media_publicity.png';
  static const String travelHospitality = '${_p}travel_hospitality.png';

  /// Untitled in the delivered set ("Frame 1984081541.png") — a near-duplicate
  /// of [mediaPublicity] with slightly different framing. Kept so the bundle
  /// matches what design shipped; not wired to any tile.
  static const String frameUnlabelled = '${_p}frame_unlabelled.png';

  // ── Financial ───────────────────────────────────────────────────────────
  static const String banking = '${_p}banking.png';
  static const String loan = '${_p}loan.png';
  static const String insurance = '${_p}insurance.png';
  static const String capitalMarket = '${_p}capital_market.png';

  // ── Jobs ────────────────────────────────────────────────────────────────
  static const String jobFullTime = '${_p}job_full_time.png';
  static const String jobPartTime = '${_p}job_part_time.png';
  static const String jobRemote = '${_p}job_remote.png';
  static const String jobOnsite = '${_p}job_onsite.png';

  // ── Education & training ────────────────────────────────────────────────
  static const String schoolEducation = '${_p}school_education.png';
  static const String collegeUniversity = '${_p}college_university.png';
  static const String coachingInstitute = '${_p}coaching_institute.png';
  static const String professionalLearn = '${_p}professional_learn.png';
}
