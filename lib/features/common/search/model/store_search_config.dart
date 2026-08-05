import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/search/model/search_category.dart';

/// What a store-search screen searches, and what it opens when a result is
/// tapped.
///
/// `StoreSearchScreen` / `StoreSearchController` are vertical-agnostic —
/// everything that makes one of them "grocery search" or "hotel search" lives
/// in here. Adding a vertical is one factory below plus one `onSearchTap` on
/// its listing screen; there is no second screen and no second controller.
///
/// The API side is the guide's one endpoint: `GET search-service/search` with
/// [searchCategory] as `category` and [entityTypes] as `type`
/// (`docs/SEARCH_API_INTEGRATION.md` §1–2). The routing side is
/// `openVisitProfile`, which takes the account/profile hints below and works
/// out the profile screen.
///
/// ## Why every config narrows with `type`
///
/// A vertical's category pairs its **catalogue** with the **businesses** that
/// sell it — `food` returns dishes *and* restaurants, because one query means
/// both. These screens list places you can open a profile for, and a dish has
/// no profile screen to open from here, so each config asks for its category's
/// business/provider type only. The catalogue side is what the per-store
/// screens already do better.
class StoreSearchConfig {
  const StoreSearchConfig({
    required this.searchCategory,
    required this.entityTypes,
    required this.recentSearchesKey,
    required this.hintText,
    this.typeOfBusiness,
    this.categoryOfBusiness,
    this.accountType = AppConstants.business,
    this.profileType,
    this.earnProfileTypes,
    this.tapTarget = StoreSearchTapTarget.visitProfile,
  });

  /// The `category` query param — the vertical the search is fixed to. The
  /// server enforces it, so a grocery search can never surface a video.
  final SearchCategory searchCategory;

  /// The `type` query param — which entity types inside [searchCategory] this
  /// screen wants. Empty = the whole category.
  ///
  /// Must be legal for the category or the API answers `400` (e.g. `product`
  /// is not a `grocery` type) — see the table in the guide.
  final List<String> entityTypes;

  /// SharedPreferences key the recent searches are persisted under. Every
  /// vertical gets its own so a grocery history can't turn up on a hotel
  /// screen.
  final String recentSearchesKey;

  /// Placeholder in the search field.
  final String hintText;

  /// `type_of_business` handed to `openVisitProfile` for a tapped result.
  ///
  /// Safe to force because [entityTypes] pins the vertical server-side — a
  /// `food_business` hit is always a Food business. It means routing no longer
  /// depends on the search payload carrying a category of its own.
  final String? typeOfBusiness;

  /// `category_of_business` used when the result carries none of its own.
  /// Matters for the verticals whose profile screen is chosen by category
  /// (Healthcare → pharmacy / lab / hospital).
  final String? categoryOfBusiness;

  /// `account_type` of what this screen lists. Storefronts are businesses;
  /// home-made / home-service sellers are individuals.
  final String accountType;

  /// Individual verticals: `profile_type` of a tapped result
  /// (`SELF_EMPLOYED`, `PROFESSIONAL`, …). Search payloads never carry one.
  final String? profileType;

  /// Individual verticals: the earn-service profile a tapped result belongs to
  /// (`HOME_MADE_FOOD`, `HOME_MADE_PRODUCTS`). Takes priority over
  /// [profileType] in `openVisitProfile` — the user tapped the *store*, not the
  /// person.
  final List<String>? earnProfileTypes;

  /// What a tapped result opens. Everything here is a profile except rentals,
  /// whose results are listings rather than businesses.
  final StoreSearchTapTarget tapTarget;

  /// The `type` value sent on the wire — comma-separated per the guide, or
  /// null to search the whole category.
  String? get typeParam => entityTypes.isEmpty ? null : entityTypes.join(',');

  /// Placeholder text: the tab the user was on when it is a real one, else the
  /// vertical's own wording. The API has no sub-category filter, so this only
  /// ever personalises the hint — results are the whole vertical either way.
  static String _hint(String fallback, String? categoryLabel) {
    final label = categoryLabel?.trim() ?? '';
    if (label.isEmpty || label.toLowerCase().startsWith('all')) return fallback;
    return 'Search in $label';
  }

  /// Shared shape for the storefront verticals: one category, its own business
  /// entity type, and a forced `type_of_business` for the tap.
  static StoreSearchConfig _business({
    required SearchCategory category,
    required String entityType,
    required String recentKey,
    required String fallbackHint,
    required BusinessType businessType,
    String? categoryLabel,
    String? categoryOfBusiness,
  }) {
    return StoreSearchConfig(
      searchCategory: category,
      entityTypes: [entityType],
      recentSearchesKey: recentKey,
      hintText: _hint(fallbackHint, categoryLabel),
      typeOfBusiness: businessType.name,
      categoryOfBusiness: categoryOfBusiness,
    );
  }

  /// Shared shape for the individual-seller verticals (home-made food /
  /// products, home services): people, not businesses, so the individual side
  /// of `openVisitProfile`.
  static StoreSearchConfig _individual({
    required SearchCategory category,
    required String entityType,
    required String recentKey,
    required String fallbackHint,
    String? categoryLabel,
    String? profileType,
    List<String>? earnProfileTypes,
  }) {
    return StoreSearchConfig(
      searchCategory: category,
      entityTypes: [entityType],
      recentSearchesKey: recentKey,
      hintText: _hint(fallbackHint, categoryLabel),
      accountType: AppConstants.individual,
      profileType: profileType,
      earnProfileTypes: earnProfileTypes,
    );
  }

  // ── Businesses ──────────────────────────────────────────────────────

  factory StoreSearchConfig.grocery({String? categoryLabel}) => _business(
        category: SearchCategory.grocery,
        entityType: 'grocery_shop',
        recentKey: 'grocery_store_recent_searches',
        fallbackHint: 'Search grocery & general stores',
        businessType: BusinessType.Grocery,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.food({String? categoryLabel}) => _business(
        category: SearchCategory.food,
        entityType: 'food_business',
        recentKey: 'food_store_recent_searches',
        fallbackHint: 'Search restaurants & food shops',
        businessType: BusinessType.Food,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.stay({String? categoryLabel}) => _business(
        category: SearchCategory.stay,
        // Businesses only: `hotel` / `home_stay` are the listings, which this
        // screen has no id-only route to.
        entityType: 'hotel_business',
        recentKey: 'stay_recent_searches',
        fallbackHint: 'Search hotels & stays',
        businessType: BusinessType.Motel,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.education({String? categoryLabel}) => _business(
        category: SearchCategory.education,
        entityType: 'education_business',
        recentKey: 'education_recent_searches',
        fallbackHint: 'Search schools & institutes',
        businessType: BusinessType.Siksha,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.finance({String? categoryLabel}) => _business(
        category: SearchCategory.finance,
        entityType: 'finance_business',
        recentKey: 'finance_recent_searches',
        fallbackHint: 'Search banks & finance services',
        businessType: BusinessType.Finance,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.services({String? categoryLabel}) => _business(
        category: SearchCategory.services,
        entityType: 'service_business',
        recentKey: 'services_recent_searches',
        fallbackHint: 'Search service providers',
        businessType: BusinessType.Service,
        categoryLabel: categoryLabel,
      );

  factory StoreSearchConfig.automotive({String? categoryLabel}) => _business(
        category: SearchCategory.automotive,
        entityType: 'automotive_business',
        recentKey: 'automotive_recent_searches',
        fallbackHint: 'Search automotive shops & services',
        businessType: BusinessType.Automotive,
        categoryLabel: categoryLabel,
      );

  /// Retail stores. Not wired to a screen yet — the shopping listing's search
  /// bar already runs its own AI inventory search.
  factory StoreSearchConfig.shopping({String? categoryLabel}) => _business(
        category: SearchCategory.shopping,
        entityType: 'retail_business',
        recentKey: 'shopping_recent_searches',
        fallbackHint: 'Search shops & sellers',
        businessType: BusinessType.Product,
        categoryLabel: categoryLabel,
      );

  /// Healthcare listing (hospitals, clinics, labs).
  ///
  /// `hospital` / `hospital_department` are deliberately left out: they are
  /// records in the hospital service, not businesses, and the visit resolver
  /// opens healthcare screens from a business id. Clinics and labs registered
  /// as businesses — which is how they reach this listing — come back under
  /// `healthcare_business`.
  factory StoreSearchConfig.healthcare({String? categoryLabel}) => _business(
        category: SearchCategory.healthcare,
        entityType: 'healthcare_business',
        recentKey: 'healthcare_recent_searches',
        fallbackHint: 'Search hospitals, clinics & labs',
        businessType: BusinessType.Healthcare,
        categoryLabel: categoryLabel,
        // Healthcare is routed by category, so a result carrying none would
        // otherwise land on the generic business profile.
        categoryOfBusiness: 'HOSPITALS',
      );

  /// Pharmacies — Healthcare again, pinned to the category that opens
  /// `MedicalPharmacyDetailScreen` rather than the hospital screens.
  factory StoreSearchConfig.pharmacy({String? categoryLabel}) => _business(
        category: SearchCategory.healthcare,
        entityType: 'healthcare_business',
        recentKey: 'pharmacy_recent_searches',
        fallbackHint: 'Search pharmacies & medical stores',
        businessType: BusinessType.Healthcare,
        categoryLabel: categoryLabel,
        categoryOfBusiness: 'PHARMACY',
      );

  // ── Listings ────────────────────────────────────────────────────────

  /// Rent & properties. The one vertical whose results are listings rather
  /// than businesses — `rentals` has no business entity type at all — so a tap
  /// fetches the property and opens its detail screen instead of a profile.
  factory StoreSearchConfig.rental({String? categoryLabel}) {
    return StoreSearchConfig(
      searchCategory: SearchCategory.rentals,
      entityTypes: const ['rental'],
      recentSearchesKey: 'rental_recent_searches',
      hintText: _hint('Search property listings', categoryLabel),
      tapTarget: StoreSearchTapTarget.rentalProperty,
    );
  }

  // ── Individuals ─────────────────────────────────────────────────────

  factory StoreSearchConfig.homeMadeFood({String? categoryLabel}) =>
      _individual(
        category: SearchCategory.homemadeFood,
        // The kitchens, not the dishes.
        entityType: 'home_food_center',
        recentKey: 'home_made_food_recent_searches',
        fallbackHint: 'Search home kitchens',
        categoryLabel: categoryLabel,
        earnProfileTypes: const [HOME_MADE_FOOD],
      );

  factory StoreSearchConfig.homeMadeProducts({String? categoryLabel}) =>
      _individual(
        category: SearchCategory.homemadeProducts,
        entityType: 'home_product_seller',
        recentKey: 'home_made_products_recent_searches',
        fallbackHint: 'Search home-made product sellers',
        categoryLabel: categoryLabel,
        earnProfileTypes: const [HOME_MADE_PRODUCTS],
      );

  /// Home services — the same backend scope as "Book Home Services".
  ///
  /// The providers, not their service listings. No earn-profile branch exists
  /// for `HOME_SERVICES` in the visit resolver (its detail screen needs a
  /// fetched service document, not a user id), so these route on the seller's
  /// profile type instead — the self-employed visit screen hydrates itself
  /// from the user id.
  factory StoreSearchConfig.homeServices({String? categoryLabel}) =>
      _individual(
        category: SearchCategory.homeServices,
        entityType: 'home_service_provider',
        recentKey: 'home_services_recent_searches',
        fallbackHint: 'Search home service providers',
        categoryLabel: categoryLabel,
        profileType: SELF_EMPLOYED,
      );

  /// Professional consultants. Not wired to a screen yet — the consultant
  /// entry screen has a location picker, not a name-search bar.
  factory StoreSearchConfig.consultants({String? categoryLabel}) =>
      _individual(
        category: SearchCategory.consultants,
        entityType: 'professional',
        recentKey: 'consultants_recent_searches',
        fallbackHint: 'Search consultants',
        categoryLabel: categoryLabel,
        profileType: PROFESSIONAL,
      );
}

/// What tapping a search result opens.
enum StoreSearchTapTarget {
  /// The owner's profile, via `openVisitProfile` — every storefront and
  /// provider vertical.
  visitProfile,

  /// A property listing's detail screen, fetched by id first.
  rentalProperty,
}
