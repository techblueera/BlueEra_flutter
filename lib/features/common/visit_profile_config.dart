import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/others_service_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/hmp_store_details_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_detail_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/manufacturer_visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:get/get.dart';

/// ONE entry point for opening **someone else's** profile — the visited /
/// customer-facing side — from anywhere in the app (Discover rails, nearby
/// stores, chat, search, feed, share preview, deep links…).
///
/// Call [openVisitProfile] with whatever the listing/profile payload gave you
/// and it works out the screen. Nothing else in this file is public.
///
/// ## Why a function and not a `Widget resolve(...)`
///
/// Some visit screens can't be built from an id alone — they read their state
/// from a controller that must be seeded/fetched *before* the push (School,
/// Hospital, Finance) or need a fully fetched model (Hotel). So the routing
/// and the navigation have to live together.
///
/// ## Routing table
///
/// **INDIVIDUAL** — keyed on `profileType`, then the earn-service profile:
///
/// | profileType / earn type          | screen                              |
/// |----------------------------------|-------------------------------------|
/// | `SELF_EMPLOYED`                  | [SelfEmployeeViewDiscoverScreen]    |
/// | `PROFESSIONAL`                   | [DiscoverProfessionalsViewScreen]   |
/// | `GIG_WORKER`, `SOCIAL_PROFILE`   | [NewVisitProfileScreen]             |
/// | earn `HOME_MADE_FOOD`            | [HmfStoreDetailsDiscoverScreen]     |
/// | earn `HOME_MADE_PRODUCTS`        | [HmpStoreDetailsDiscoverScreenV2]   |
///
/// **BUSINESS** — keyed on `type_of_business`, then `category_of_business`:
///
/// | type_of_business | category_of_business        | screen                                       |
/// |------------------|-----------------------------|----------------------------------------------|
/// | `Food`           | any                         | [VisitFoodStoreDetailsScreen]                |
/// | `Grocery`        | any                         | [VisitGroceryStoreScreen]                    |
/// | `Product`        | any                         | [VisitProductStoreDetailsScreen]             |
/// | `Manufacturing`  | any                         | [ManufacturerVisitProductStoreDetailsScreen] |
/// | `Healthcare`     | `PHARMACY`                  | [MedicalPharmacyDetailScreen]                |
/// | `Healthcare`     | `DIAGNOSTIC`                | [LabDetailScreen]                            |
/// | `Healthcare`     | `HOSPITALS` / `CLINICS` / `DOCTORS` / `ALTERNATIVE_HEALTH` | [DiscoverHospitalHomeScreen] |
/// | `Siksha`         | any                         | [DiscoverSchoolHomeScreen]                   |
/// | `Motel`          | any                         | [HotelDiscoverHomeScreen] (pre-fetched)      |
/// | `Finance`        | any                         | [FinanceDetailScreen]                        |
/// | `Service`        | any                         | [OthersServiceDetailScreen]                  |
/// | `Automotive`     | `AUTO_PARTS`                | [AutomotiveVisitProductStoreDetailsScreen]   |
///
/// Anything not in the table (including Automotive `VEHICLE_SALES` /
/// `VEHICLE_SERVICE` / `TRANSPORT_LOGISTICS_PARKING` / `VEHICLE_SUPPORT`,
/// which have no seller-scoped customer screen yet) falls through to the
/// generic [VisitBusinessProfileNew], so no tap ever dead-ends.
///
/// IMPORTANT: never read `businessTypeGlobal` / `userProfileTypeGlobal` here —
/// those describe the **logged-in** user. Everything routed on must be passed
/// in from the visited profile.
Future<void> openVisitProfile({
  /// `INDIVIDUAL` / `BUSINESS` — the visited profile's `account_type`.
  required String? accountType,

  /// Individual only: `SELF_EMPLOYED` / `GIG_WORKER` / `SOCIAL_PROFILE` /
  /// `PROFESSIONAL` (the profile's `profile_type`).
  String? profileType,

  /// Individual only: the profession tag (`CONTENT_CREATOR`, `ARTIST`,
  /// `JOURNALIST`, …).
  ///
  /// Kept in the signature because callers have it and it's what the *own*
  /// profile resolver branches on — but there is currently no per-profession
  /// **visit** screen (a visited content creator and a visited journalist both
  /// open [NewVisitProfileScreen]), so it doesn't change the target today.
  String? profession,

  /// Individual only: entries from `earnProfileTypes` — `HOME_MADE_FOOD`,
  /// `HOME_MADE_PRODUCTS`, `HOME_SERVICES`. When the caller came from a
  /// home-made rail this takes priority over [profileType], because the user
  /// tapped the *store*, not the person.
  List<String>? earnProfileTypes,

  /// Business only: `type_of_business` (`Food`, `Grocery`, `Product`,
  /// `Healthcare`, `Siksha`, `Motel`, `Finance`, `Service`, `Automotive`,
  /// `Manufacturing`).
  String? typeOfBusiness,

  /// Business only: `category_of_business` (`GENERAL_STORE`, `DIAGNOSTIC`,
  /// `PHARMACY`, `HOSPITALS`, `AUTO_PARTS`, …).
  String? categoryOfBusiness,

  /// The business profile `_id`. Required for business profiles; falls back to
  /// [userId] when a caller only holds the owner id.
  String? businessId,

  /// The owner/author user `_id`. Required for individual profiles; falls back
  /// to [businessId].
  String? userId,

  /// Passed through to the generic profile screens for their back/analytics
  /// behaviour.
  String screenFrom = AppConstants.feedScreen,
}) async {
  final String bid = _pick(businessId, userId);
  final String uid = _pick(userId, businessId);

  if (bid.isEmpty && uid.isEmpty) {
    logs('openVisitProfile: no businessId/userId — nothing to open');
    return;
  }

  final String account = _norm(accountType);
  final String type = _norm(typeOfBusiness);
  final String category = _norm(categoryOfBusiness);

  logs('openVisitProfile: account=$account type=$type category=$category '
      'profileType=${_norm(profileType)} bid=$bid uid=$uid');

  // BUSINESS is decided by `account_type`, but a payload that carries a
  // `type_of_business` is a business profile regardless of what (or whether)
  // `account_type` says — several list endpoints omit it.
  final bool isBusiness =
      account == _normConst(AppConstants.business) || type.isNotEmpty;

  if (isBusiness) {
    await _openBusiness(
      type: type,
      category: category,
      businessId: bid,
      userId: uid,
      screenFrom: screenFrom,
    );
    return;
  }

  _openIndividual(
    profileType: _norm(profileType),
    earnProfileTypes: earnProfileTypes,
    userId: uid,
    screenFrom: screenFrom,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual
// ─────────────────────────────────────────────────────────────────────────────

void _openIndividual({
  required String profileType,
  required List<String>? earnProfileTypes,
  required String userId,
  required String screenFrom,
}) {
  // Home-made stores win over the person's own profile type: the tap came from
  // a store rail, so the user wants the storefront.
  final earn = (earnProfileTypes ?? const <String>[]).map(_norm).toSet();
  if (earn.contains(_normConst(HOME_MADE_FOOD))) {
    Get.to(() => HmfStoreDetailsDiscoverScreen(userId: userId));
    return;
  }
  if (earn.contains(_normConst(HOME_MADE_PRODUCTS))) {
    Get.to(() => HmpStoreDetailsDiscoverScreenV2(userId: userId));
    return;
  }
  // HOME_SERVICES deliberately has no branch: its detail screen
  // (HomeServiceDiscoverDetailsScreenV2) needs a fully fetched GetServiceModel
  // and can't be opened from a user id, so it falls through to the profile.

  switch (profileType) {
    case SELF_EMPLOYED:
      Get.to(() => SelfEmployeeViewDiscoverScreen(userId: userId));
      return;
    case PROFESSIONAL:
      Get.to(() => DiscoverProfessionalsViewScreen(userId: userId));
      return;
    case GIG_WORKER:
    case SOCIAL_PROFILE:
    default:
      // Gig workers and social profiles (incl. content creators / artists /
      // journalists) share the one generic visit profile.
      Get.to(() => NewVisitProfileScreen(
            authorId: userId,
            screenFromName: screenFrom,
          ));
      return;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Business
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _openBusiness({
  required String type,
  required String category,
  required String businessId,
  required String userId,
  required String screenFrom,
}) async {
  // Every dedicated visit screen below does `Get.find<ViewBusinessDetailsController>()`
  // in its initState/field initialisers, so register it once up front — this is
  // what lets a cold-start entry (deep link, notification) work.
  getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  if (type == _enum(BusinessType.Food)) {
    Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: businessId));
    return;
  }

  if (type == _enum(BusinessType.Grocery)) {
    Get.to(() => VisitGroceryStoreScreen(
          visitBusinessId: businessId,
          userId: userId,
        ));
    return;
  }

  if (type == _enum(BusinessType.Product)) {
    Get.to(() => VisitProductStoreDetailsScreen(visitUserId: userId));
    return;
  }

  if (type == _enum(BusinessType.Manufacturing)) {
    Get.to(() =>
        ManufacturerVisitProductStoreDetailsScreen(visitBusinessId: businessId));
    return;
  }

  if (type == _enum(BusinessType.Healthcare)) {
    _openHealthcare(
      category: category,
      businessId: businessId,
      screenFrom: screenFrom,
    );
    return;
  }

  if (type == _enum(BusinessType.Siksha)) {
    _openSchool(businessId);
    return;
  }

  if (type == _enum(BusinessType.Motel)) {
    // The hotel screen needs a fully fetched HotelServiceData, so this shows
    // its own blocking loader and snackbars on failure.
    await deepLinkNetworkResources.navigateToHotelDetail(businessId);
    return;
  }

  if (type == _enum(BusinessType.Finance)) {
    _openFinance(businessId);
    return;
  }

  if (type == _enum(BusinessType.Service)) {
    Get.to(() => OthersServiceDetailScreen(visitUserId: userId));
    return;
  }

  if (type == _enum(BusinessType.Automotive)) {
    // Only the parts catalog has a customer-facing store screen. Vehicle sales,
    // service, transport and support have no seller-scoped visit screen yet, so
    // they get the generic business profile.
    // Normalised, so the API's "AUTO PARTS" and "AUTO_PARTS" both land here.
    if (category.contains('AUTO_PARTS')) {
      Get.to(() => AutomotiveVisitProductStoreDetailsScreen(visitUserId: userId));
      return;
    }
    _openGenericBusiness(businessId, screenFrom);
    return;
  }

  _openGenericBusiness(businessId, screenFrom);
}

/// Healthcare splits purely on `category_of_business` — the same split the
/// own-profile ("Me" tab) resolver makes.
void _openHealthcare({
  required String category,
  required String businessId,
  required String screenFrom,
}) {
  if (category == 'PHARMACY') {
    // Self-hydrates (profile + inventory) from the business id.
    Get.to(() => MedicalPharmacyDetailScreen(businessId: businessId));
    return;
  }

  if (category == 'DIAGNOSTIC') {
    // Resolves LaboratoryProfile._id from the business id itself, then loads
    // the tests.
    Get.to(() => LabDetailScreen(businessId: businessId));
    return;
  }

  const hospitalCategories = {
    'HOSPITALS',
    'CLINICS',
    'DOCTORS',
    'ALTERNATIVE_HEALTH',
  };
  if (hospitalCategories.contains(category)) {
    // DiscoverHospitalHomeScreen reads from HospitalServiceAiController. Seed
    // the model with just the id — its initState fetches the full profile and
    // merges the hospital sections.
    final hospitalController = getOrPut(() => HospitalServiceAiController());
    hospitalController.hospitalDataResModel?.value = HospitalFullDetailsResModel(
      success: true,
      data: HospitalFullData(id: businessId),
    );
    Get.to(() => const DiscoverHospitalHomeScreen());
    return;
  }

  _openGenericBusiness(businessId, screenFrom);
}

/// DiscoverSchoolHomeScreen reads from SchoolAboutUsController. Reset it first
/// so a previously-viewed school doesn't flash, then push and fetch. The id is
/// passed as BOTH `schoolID` and `ownerID` — the controller tries the school-id
/// lookup and transparently falls back to the owner-id one, so it resolves
/// whichever kind of id the caller happened to hold.
void _openSchool(String id) {
  final schoolAboutUsController = getOrPut(() => SchoolAboutUsController());
  schoolAboutUsController.schoolDetailsData?.value = SchoolDetailsData();
  Get.to(() => DiscoverSchoolHomeScreen());
  schoolAboutUsController.getSchoolByIdController(schoolID: id, ownerID: id);
}

/// FinanceDetailScreen reads from FinanceDiscoverController. Clear the previous
/// selection and kick the fetch off up front so the screen shows its own loader
/// instead of a half-empty header; leaving `selectedDetail` null also stops its
/// initState firing a second fetch.
void _openFinance(String id) {
  final controller = getOrPut(() => FinanceDiscoverController());
  controller.selectedDetail.value = null;
  controller.fetchDetail(id);
  Get.to(() => const FinanceDetailScreen());
}

void _openGenericBusiness(String businessId, String screenFrom) {
  Get.to(() => VisitBusinessProfileNew(
        businessId: businessId,
        screenName: screenFrom,
      ));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// First non-blank of the two, else `''`.
String _pick(String? a, String? b) {
  final first = (a ?? '').trim();
  if (first.isNotEmpty) return first;
  return (b ?? '').trim();
}

/// Uppercases and collapses whitespace to underscores so the API's two spellings
/// of the same key match — `"Vehicle Sales"`, `"VEHICLE_SALES"` and
/// `"vehicle sales"` all normalise to `VEHICLE_SALES`.
String _norm(String? value) => (value ?? '')
    .trim()
    .toUpperCase()
    .replaceAll(RegExp(r'[\s-]+'), '_');

String _normConst(String value) => _norm(value);

String _enum(BusinessType type) => _norm(type.name);