import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// Which Me-section module a BUSINESS account belongs to.
///
/// One name per destination in `_buildBusinessScreen`
/// (bottom_navigation_bar_screen.dart), which is the point: the classification
/// used to live inside that method as a nest of type/category string tests,
/// so anything else that needed to know what kind of shop this is — the
/// go-live nudge copy, to begin with — had to re-derive it and drift from it.
/// Now the router switches on this and so does everyone else.
///
/// Values map 1:1 onto screens, NOT onto `BusinessType`. Several types land on
/// the same module (a pharmacy and a healthcare manufacturer both sell
/// medicines; grocery and grocery-manufacturing share a store screen), and one
/// type can split several ways (Automotive → showroom / workshop / parts), so
/// a per-type enum would not be able to say what a merchant actually sees.
///
/// Deliberately business-only. Individual accounts route off a single global
/// (`userProfileTypeGlobal`) in a plain switch — there is no tangle there worth
/// extracting.
enum MeSectionKind {
  /// Restaurants and cloud kitchens → `FoodMainScreen`.
  food,

  /// Grocery stores, and grocery MANUFACTURING → `GroceryScreen`.
  grocery,

  /// Pharmacies, and healthcare MANUFACTURING → `MedicalScreen`.
  pharmacy,

  /// Standalone doctors and clinics — independent practitioners with their own
  /// listing and appointment inbox → `DoctorMain`.
  doctor,

  /// Hospitals and alternative health → `HospitalMain`.
  hospital,

  /// Diagnostic labs → `LaboratoryMain`.
  laboratory,

  /// Hotels (`BusinessType.Motel`) → `HotelMain`.
  hotel,

  /// Schools and coaching (`BusinessType.Siksha`) → `SchoolMain`.
  school,

  /// General goods sellers → `ProductScreen`.
  product,

  /// Manufacturers of general goods → `ManufacturerProductScreen`. Kept apart
  /// from [product] because it is a genuinely different screen, even though
  /// the two read alike.
  manufacturerProduct,

  /// Auto-parts sellers, and automotive MANUFACTURING → `AutomotivePartsScreen`.
  automotiveParts,

  /// Vehicle showrooms → `VehicleScreenV3`.
  vehicleSales,

  /// Vehicle service, support, transport & logistics → `AutomotiveServiceMain`.
  automotiveService,

  /// Everything that sells time rather than stock and has no module of its
  /// own — Service, Finance, and any healthcare category that isn't one of the
  /// four above → `OthersMain`.
  service,

  /// Unrecognised: an automotive category outside the three known groups, a
  /// `BusinessType` the API adds later, `BusinessType.Both`, or an account
  /// whose type hasn't hydrated yet → `_UnknownBusinessFallback`.
  unknown,
}

/// Classifies the account from its business type and category.
///
/// Defaults to the logged-in user's own globals, which is what both callers
/// want; the parameters exist so the mapping can be exercised directly with a
/// type/category pair.
///
/// Both inputs are uppercased AND trimmed. The category tests were a mix of
/// trimmed and untrimmed before this was extracted, which meant a category
/// arriving as `"PHARMACY "` matched the doctor test but fell straight past
/// the `== "PHARMACY"` one and landed on the generic services screen.
MeSectionKind resolveMeSectionKind({
  String? businessType,
  String? businessCategory,
}) {
  final String type = (businessType ?? businessTypeGlobal).toUpperCase().trim();
  final String category =
      (businessCategory ?? businessCategoryGlobal).toUpperCase().trim();

  if (type == BusinessType.Food.name.toUpperCase()) return MeSectionKind.food;
  if (type == BusinessType.Grocery.name.toUpperCase()) {
    return MeSectionKind.grocery;
  }
  if (type == BusinessType.Siksha.name.toUpperCase()) {
    return MeSectionKind.school;
  }
  if (type == BusinessType.Motel.name.toUpperCase()) return MeSectionKind.hotel;
  if (type == BusinessType.Product.name.toUpperCase()) {
    return MeSectionKind.product;
  }
  if (type == BusinessType.Service.name.toUpperCase() ||
      type == BusinessType.Finance.name.toUpperCase()) {
    return MeSectionKind.service;
  }

  if (type == BusinessType.Healthcare.name.toUpperCase()) {
    // DOCTORS / CLINICS are STANDALONE DOCTORS — independent practitioners
    // with their own listing, professional profile and appointment inbox
    // (hospital-service/doctors*). Checked first, and by TOKEN rather than
    // exact value, because the category arrives in several shapes ("DOCTORS",
    // "Doctors", "Clinic Doctors", "CLINICS").
    if (category.contains(BusinessCategoryTokens.doctorToken) ||
        category.contains(BusinessCategoryTokens.clinicToken)) {
      return MeSectionKind.doctor;
    }
    if (category == BusinessCategoryTokens.hospitals ||
        category == BusinessCategoryTokens.alternativeHealth) {
      return MeSectionKind.hospital;
    }
    if (category == BusinessCategoryTokens.diagnostic) {
      return MeSectionKind.laboratory;
    }
    if (category == BusinessCategoryTokens.pharmacy) {
      return MeSectionKind.pharmacy;
    }
    // Everything else under Healthcare keeps the generic services screen.
    return MeSectionKind.service;
  }

  if (type == BusinessType.Manufacturing.name.toUpperCase()) {
    // Manufacturing splits by WHAT IS MADE. The onboarding API serves four
    // categories under it — grocery & stationary, product, healthcare and
    // automotive — and each one's goods already have a catalogue screen, so
    // the merchant lands on the one built for their own stock instead of every
    // manufacturer sharing the generic product screen.
    //
    // Matched on a token rather than an exact string because
    // `businessCategoryGlobal` carries the display name ("Manufacturing
    // Healthcare") on some paths and the tag id ("MANUFACTURING_HEALTHCARE")
    // on others. Each token appears in exactly one manufacturing category, so
    // either shape lands.
    if (category.contains(BusinessCategoryTokens.groceryToken)) {
      return MeSectionKind.grocery;
    }
    if (category.contains(BusinessCategoryTokens.healthcareToken)) {
      return MeSectionKind.pharmacy;
    }
    if (category.contains(BusinessCategoryTokens.automotiveToken)) {
      return MeSectionKind.automotiveParts;
    }
    // MANUFACTURING_PRODUCT — and deliberately also anything added
    // server-side later, which then gets the general goods catalogue (where
    // every manufacturer landed until the split) rather than the unknown
    // fallback.
    return MeSectionKind.manufacturerProduct;
  }

  if (type == BusinessType.Automotive.name.toUpperCase()) {
    // Order matters: a category can satisfy more than one test (e.g.
    // VEHICLE_SALES), and first match wins — the same precedence the router's
    // else-if chain had.
    if (BusinessCategoryTokens.automotiveVehicleSales.contains(category)) {
      return MeSectionKind.vehicleSales;
    }
    if (BusinessCategoryTokens.automotiveServiceAndSupport
        .contains(category)) {
      return MeSectionKind.automotiveService;
    }
    // "AUTO PARTS" (with its space, as the API returns it).
    if (category.contains(BusinessCategoryTokens.autoPartsToken)) {
      return MeSectionKind.automotiveParts;
    }
    return MeSectionKind.unknown;
  }

  return MeSectionKind.unknown;
}
