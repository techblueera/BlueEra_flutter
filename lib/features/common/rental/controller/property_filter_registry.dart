import 'package:BlueEra/features/common/rental/controller/property_controller.dart';

/// Stable identifiers for every chip-style filter the rental discover
/// screen knows about. Common free-text/range filters (city, price)
/// are special-cased in [PropertyDiscoverController] — they don't fit
/// the "single value from a fixed option list" shape this registry
/// models.
///
/// Add a new entry here + one row in [propertyFilterRegistry] below and
/// the bottom sheet, applied-chip strip, active-count badge, and
/// removeFilter all pick it up automatically.
enum FilterId {
  // ── Common across all property types ──
  listedBy,
  minRating,
  // ── HouseAndApartment ──
  houseApartmentType,
  bhk,
  bathrooms,
  // ── Shared (HA / Lands / NewProjects) ──
  facing,
  // ── Shared (HA / Shops / PG) ──
  carParking,
  // ── Shared (HA Rent / Shops / PG) ──
  furnishing,
  // ── HA Sell only ──
  availabilityStatus,
  // ── HA Rent / PG ──
  bachelorsAllowed,
  // ── Shops / NewProjects ──
  projectStatus,
  // ── Shops only ──
  washrooms,
  // ── PG only ──
  pgSubType,
  pgRoomType,
  attachedBathroom,
  mealsIncluded,
  // ── NewProjects only ──
  typeOfProperty,
  noOfTowers,
  noOfFloors,
}

/// Property-type keys used by the API. Mirrors
/// [PropertyController._propertyTypeKey].
class PropertyTypeKey {
  static const houseAndApartment = 'HouseAndApartment';
  static const shopAndOffices = 'ShopAndOffices';
  static const landAndPlots = 'LandAndPlots';
  static const newProjects = 'NewProjectsAndProperties';
  static const pgAndGuestHouse = 'PGAndGuestHouse';
}

/// Listing-type values used by the API.
class ListingType {
  static const sell = 'Sell';
  static const rent = 'Rent';
}

/// Describes one chip-style filter — its label, the API key it maps to,
/// the option set the user picks from, and which
/// (property-type, listing-type) combinations it should appear under.
class FilterDef {
  final FilterId id;
  final String label;
  final String apiKey;
  final List<String> options;

  /// Map from property-type key → set of listing-types this filter is
  /// relevant under. `null` value means "any listing type". A
  /// property-type missing from the map means the filter isn't shown
  /// there at all.
  final Map<String, Set<String>?> appliesTo;

  const FilterDef({
    required this.id,
    required this.label,
    required this.apiKey,
    required this.options,
    required this.appliesTo,
  });

  bool showsFor(String propertyType, String listingType) {
    if (!appliesTo.containsKey(propertyType)) return false;
    final allowed = appliesTo[propertyType];
    return allowed == null || allowed.contains(listingType);
  }
}

// Convenience: filter visible under every property + listing type combo.
const Map<String, Set<String>?> _allTypesAny = {
  PropertyTypeKey.houseAndApartment: null,
  PropertyTypeKey.shopAndOffices: null,
  PropertyTypeKey.landAndPlots: null,
  PropertyTypeKey.newProjects: null,
  PropertyTypeKey.pgAndGuestHouse: null,
};

/// Single source of truth for every chip-style filter. Order here is
/// the order they appear in the bottom sheet.
final List<FilterDef> propertyFilterRegistry = const [
  // ── Common ────────────────────────────────────────────────────
  FilterDef(
    id: FilterId.listedBy,
    label: 'Listed By',
    apiKey: 'listedBy',
    options: PropertyController.listedByOptions,
    appliesTo: _allTypesAny,
  ),
  FilterDef(
    id: FilterId.minRating,
    label: 'Min Rating',
    apiKey: 'minRating',
    options: ['3+', '4+', '4.5+'],
    appliesTo: _allTypesAny,
  ),

  // ── HouseAndApartment only ───────────────────────────────────
  FilterDef(
    id: FilterId.houseApartmentType,
    label: 'House Type',
    apiKey: 'houseApartmentType',
    options: PropertyController.haTypeOptions,
    appliesTo: {PropertyTypeKey.houseAndApartment: null},
  ),
  FilterDef(
    id: FilterId.bhk,
    label: 'BHK',
    apiKey: 'bhk',
    options: PropertyController.bhkOptions,
    appliesTo: {PropertyTypeKey.houseAndApartment: null},
  ),
  FilterDef(
    id: FilterId.bathrooms,
    label: 'Bathrooms',
    apiKey: 'bathrooms',
    options: PropertyController.bathroomOptions,
    appliesTo: {PropertyTypeKey.houseAndApartment: null},
  ),

  // ── Facing — HA / Lands / NewProjects ────────────────────────
  FilterDef(
    id: FilterId.facing,
    label: 'Facing',
    apiKey: 'facing',
    options: PropertyController.facingOptions,
    appliesTo: {
      PropertyTypeKey.houseAndApartment: null,
      PropertyTypeKey.landAndPlots: null,
      PropertyTypeKey.newProjects: null,
    },
  ),

  // ── Car Parking — HA / Shops / PG ────────────────────────────
  FilterDef(
    id: FilterId.carParking,
    label: 'Car Parking',
    apiKey: 'carParking',
    options: PropertyController.parkingOptions,
    appliesTo: {
      PropertyTypeKey.houseAndApartment: null,
      PropertyTypeKey.shopAndOffices: null,
      PropertyTypeKey.pgAndGuestHouse: null,
    },
  ),

  // ── Furnishing — HA(Rent), Shops, PG ─────────────────────────
  FilterDef(
    id: FilterId.furnishing,
    label: 'Furnishing',
    apiKey: 'furnishing',
    options: PropertyController.furnishingOptions,
    appliesTo: {
      PropertyTypeKey.houseAndApartment: {ListingType.rent},
      PropertyTypeKey.shopAndOffices: null,
      PropertyTypeKey.pgAndGuestHouse: null,
    },
  ),

  // ── HA Sell only ─────────────────────────────────────────────
  FilterDef(
    id: FilterId.availabilityStatus,
    label: 'Availability',
    apiKey: 'availabilityStatus',
    options: PropertyController.availabilityOptions,
    appliesTo: {
      PropertyTypeKey.houseAndApartment: {ListingType.sell},
    },
  ),

  // ── Bachelors — HA(Rent) / PG ────────────────────────────────
  FilterDef(
    id: FilterId.bachelorsAllowed,
    label: 'Bachelors',
    apiKey: 'bachelorsAllowed',
    options: PropertyController.bachelorOptions,
    appliesTo: {
      PropertyTypeKey.houseAndApartment: {ListingType.rent},
      PropertyTypeKey.pgAndGuestHouse: null,
    },
  ),

  // ── Project Status — Shops / NewProjects ─────────────────────
  FilterDef(
    id: FilterId.projectStatus,
    label: 'Project Status',
    apiKey: 'projectStatus',
    options: PropertyController.soProjectStatusOptions,
    appliesTo: {
      PropertyTypeKey.shopAndOffices: null,
      PropertyTypeKey.newProjects: null,
    },
  ),

  // ── Shops only ───────────────────────────────────────────────
  FilterDef(
    id: FilterId.washrooms,
    label: 'Washrooms',
    apiKey: 'washrooms',
    options: PropertyController.washroomOptions,
    appliesTo: {PropertyTypeKey.shopAndOffices: null},
  ),

  // ── PG only ──────────────────────────────────────────────────
  FilterDef(
    id: FilterId.pgSubType,
    label: 'PG Type',
    apiKey: 'subType',
    options: PropertyController.pgSubtypeOptions,
    appliesTo: {PropertyTypeKey.pgAndGuestHouse: null},
  ),
  FilterDef(
    id: FilterId.pgRoomType,
    label: 'Room Type',
    apiKey: 'roomType',
    options: PropertyController.pgRoomTypeOptions,
    appliesTo: {PropertyTypeKey.pgAndGuestHouse: null},
  ),
  FilterDef(
    id: FilterId.attachedBathroom,
    label: 'Attached Bathroom',
    apiKey: 'attachedBathroom',
    options: PropertyController.attachedBathroomOptions,
    appliesTo: {PropertyTypeKey.pgAndGuestHouse: null},
  ),
  FilterDef(
    id: FilterId.mealsIncluded,
    label: 'Meals',
    apiKey: 'mealsIncluded',
    options: PropertyController.mealsOptions,
    appliesTo: {PropertyTypeKey.pgAndGuestHouse: null},
  ),

  // ── NewProjects only ─────────────────────────────────────────
  FilterDef(
    id: FilterId.typeOfProperty,
    label: 'Property Type',
    apiKey: 'typeOfProperty',
    options: PropertyController.npPropertyTypeOptions,
    appliesTo: {PropertyTypeKey.newProjects: null},
  ),
  FilterDef(
    id: FilterId.noOfTowers,
    label: 'Towers',
    apiKey: 'noOfTowers',
    options: PropertyController.towersOptions,
    appliesTo: {PropertyTypeKey.newProjects: null},
  ),
  FilterDef(
    id: FilterId.noOfFloors,
    label: 'Floors',
    apiKey: 'noOfFloors',
    options: PropertyController.floorsOptions,
    appliesTo: {PropertyTypeKey.newProjects: null},
  ),
];

FilterDef? filterDefById(FilterId id) {
  for (final d in propertyFilterRegistry) {
    if (d.id == id) return d;
  }
  return null;
}

/// Friendly label for the applied-filter chip in the discover strip.
/// Falls back to the raw value when no custom format applies.
String chipLabelFor(FilterId id, String value) {
  switch (id) {
    case FilterId.bhk:
      return '$value BHK';
    case FilterId.bathrooms:
      return '$value Bath';
    case FilterId.carParking:
      return '$value Parking';
    case FilterId.washrooms:
      return value == '1' ? '1 Washroom' : '$value Washrooms';
    case FilterId.noOfTowers:
      return '$value Towers';
    case FilterId.noOfFloors:
      return '$value Floors';
    case FilterId.minRating:
      return '$value ★';
    case FilterId.mealsIncluded:
      return value == 'Yes Included' ? 'Meals Included' : 'No Meals';
    case FilterId.attachedBathroom:
      return value == 'Yes Attached' ? 'Attached Bath' : 'No Attached Bath';
    case FilterId.bachelorsAllowed:
      return value == 'Yes Allowed' ? 'Bachelors Allowed' : 'No Bachelors';
    case FilterId.listedBy:
    case FilterId.houseApartmentType:
    case FilterId.facing:
    case FilterId.furnishing:
    case FilterId.availabilityStatus:
    case FilterId.projectStatus:
    case FilterId.pgSubType:
    case FilterId.pgRoomType:
    case FilterId.typeOfProperty:
      return value;
  }
}
