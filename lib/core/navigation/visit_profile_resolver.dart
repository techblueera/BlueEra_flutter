import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/manufacturer_visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single entry point for opening **someone else's** profile (the visited /
/// customer-facing side), mirroring how `resolveBusinessScreen()` /
/// `resolveIndividualScreen()` pick the *own* "me" screen.
///
/// IMPORTANT: unlike the "me" resolver, this must **never** read the
/// `businessTypeGlobal` / `userProfileTypeGlobal` globals — those describe the
/// logged-in user. The visited profile's own type/category/ids are passed in.
///
/// Mapping (business → its dedicated visit screen):
///   Food          → [VisitFoodStoreDetailsScreen]
///   Grocery       → [VisitGroceryStoreScreen]
///   Product       → [VisitProductStoreDetailsScreen]
///   Manufacturing → [ManufacturerVisitProductStoreDetailsScreen]
///   Automotive (Sales/Parts sectors) → [AutomotiveVisitProductStoreDetailsScreen]
///
/// No dedicated visit screen yet → generic [VisitBusinessProfileNew]:
///   Healthcare (Hospital / Lab / Pharmacy / Clinic / …), Motel/Hotel, Siksha,
///   Finance, Service, Automotive (Service / Transport / Rental / Support).
///
/// Individual accounts (any profession — Self-employed / Gig / Social /
/// Professional) → [NewVisitProfileScreen]. There are no per-profession visit
/// screens, so they all share that one.
class VisitProfileResolver {
  const VisitProfileResolver._();

  /// Builds the right visit screen for the given profile metadata.
  ///
  /// [accountType] decides individual vs business (compared against
  /// [AppConstants.individual] / [AppConstants.business], case-insensitive).
  /// [businessType] / [businessCategory] come from the visited business profile
  /// (`typeOfBusiness` / `categoryOfBusiness`). [businessId] is the business
  /// `_id`; [userId] is the owner/author id (falls back to [businessId] when a
  /// screen needs a user id but only the business id is known).
  static Widget resolveScreen({
    String? accountType,
    String? businessType,
    String? businessCategory,
    required String businessId,
    String? userId,
    String screenFrom = AppConstants.feedScreen,
  }) {
    final acc = (accountType ?? '').toUpperCase();
    final uid = (userId != null && userId.isNotEmpty) ? userId : businessId;

    // Individual profiles → single shared visit screen.
    if (acc == AppConstants.individual.toUpperCase()) {
      return NewVisitProfileScreen(
        authorId: uid,
        screenFromName: screenFrom,
      );
    }

    final type = (businessType ?? '').toUpperCase();
    final cat = (businessCategory ?? '').toUpperCase();

    if (type == BusinessType.Food.name.toUpperCase()) {
      return VisitFoodStoreDetailsScreen(visitBusinessId: businessId);
    }
    if (type == BusinessType.Grocery.name.toUpperCase()) {
      return VisitGroceryStoreScreen(visitBusinessId: businessId, userId: uid);
    }
    if (type == BusinessType.Product.name.toUpperCase()) {
      return VisitProductStoreDetailsScreen(visitUserId: uid);
    }
    if (type == BusinessType.Manufacturing.name.toUpperCase()) {
      return ManufacturerVisitProductStoreDetailsScreen(
          visitBusinessId: businessId);
    }
    if (type == BusinessType.Automotive.name.toUpperCase()) {
      // Only the Sales / Parts sectors have a product-style visit screen;
      // Service / Transport / Rental / Support fall back to the generic one
      // (matches `_isSpecificProductAutomotive` in the own-profile resolver).
      final isAutoProduct = [AppConstants.SALES_SECTOR, AppConstants.PARTS_SECTOR]
          .any((s) => s.toUpperCase() == cat);
      if (isAutoProduct) {
        return AutomotiveVisitProductStoreDetailsScreen(visitUserId: uid);
      }
      return _genericBusiness(businessId, screenFrom);
    }

    // Healthcare, Motel/Hotel, Siksha, Finance, Service, and anything else have
    // no dedicated visit screen yet → generic business profile.
    return _genericBusiness(businessId, screenFrom);
  }

  /// Convenience wrapper when you already have the fetched business profile.
  /// (BusinessProfileDetails is a business-only model, so this assumes a
  /// business account.)
  static Widget resolveBusinessProfile(
    BusinessProfileDetails? profile, {
    String screenFrom = AppConstants.feedScreen,
  }) {
    return resolveScreen(
      accountType: AppConstants.business,
      businessType: profile?.typeOfBusiness,
      businessCategory: profile?.categoryOfBusiness,
      businessId: profile?.id ?? '',
      userId: profile?.userId,
      screenFrom: screenFrom,
    );
  }

  /// Pushes the resolved visit screen via GetX. Returns the navigation future.
  static Future<T?>? open<T>({
    String? accountType,
    String? businessType,
    String? businessCategory,
    required String businessId,
    String? userId,
    String screenFrom = AppConstants.feedScreen,
  }) {
    return Get.to<T>(() => resolveScreen(
          accountType: accountType,
          businessType: businessType,
          businessCategory: businessCategory,
          businessId: businessId,
          userId: userId,
          screenFrom: screenFrom,
        ));
  }

  static Widget _genericBusiness(String businessId, String screenFrom) =>
      VisitBusinessProfileNew(businessId: businessId, screenName: screenFrom);

  // ── Individual "discover-style" rich profiles ───────────────────────────
  // Unlike [resolveScreen] (id-only), these take a fully-fetched Discover
  // model, so they're typed entry points. Use them when you already hold the
  // listing data (Discover lists, map sheet, etc.); use [resolveScreen] /
  // NewVisitProfileScreen when all you have is an author id.

  /// Self-employed / skill-work provider profile. The screen now derives the
  /// price + timing display from [service] itself, so we just hand it over.
  static Widget selfEmployed(ServiceData service, {bool isSelfPreview = false}) =>
      SelfEmployeeViewDiscoverScreen(
        service: service,
        isSelfPreview: isSelfPreview,
      );

  /// Professional / consultant profile.
  static Widget professional(ProfessionalConsData data) =>
      DiscoverProfessionalsViewScreen(professionalConsData: data);

  /// Visit-side mirror of `resolveIndividualScreen()`: picks the screen by
  /// the visited individual's [profileType] (`SELF_EMPLOYED` / `GIG_WORKER` /
  /// `SOCIAL_PROFILE` / `PROFESSIONAL`).
  ///
  /// Self-employed & professional have rich Discover screens. Pass the matching
  /// model ([service] / [professionalData]) when you already hold it (Discover
  /// lists); otherwise the screen fetches it by [authorId] on open (it shows a
  /// loader while fetching). Gig / Social have no dedicated visit screen, so
  /// they use the id-based [NewVisitProfileScreen].
  static Widget resolveIndividualScreen({
    required String profileType,
    required String authorId,
    ServiceData? service,
    ProfessionalConsData? professionalData,
    String screenFrom = AppConstants.feedScreen,
  }) {
    switch (profileType.toUpperCase()) {
      case SELF_EMPLOYED:
        return SelfEmployeeViewDiscoverScreen(
            service: service, userId: authorId);
      case PROFESSIONAL:
        return DiscoverProfessionalsViewScreen(
            professionalConsData: professionalData, userId: authorId);
      case GIG_WORKER:
      case SOCIAL_PROFILE:
      default:
        return NewVisitProfileScreen(
            authorId: authorId, screenFromName: screenFrom);
    }
  }

  static Future<T?>? openSelfEmployed<T>(
    ServiceData service, {
    bool isSelfPreview = false,
  }) =>
      Get.to<T>(() => selfEmployed(service, isSelfPreview: isSelfPreview));

  static Future<T?>? openProfessional<T>(ProfessionalConsData data) =>
      Get.to<T>(() => professional(data));

  static Future<T?>? openIndividual<T>({
    required String profileType,
    required String authorId,
    ServiceData? service,
    ProfessionalConsData? professionalData,
    String screenFrom = AppConstants.feedScreen,
  }) =>
      Get.to<T>(() => resolveIndividualScreen(
            profileType: profileType,
            authorId: authorId,
            service: service,
            professionalData: professionalData,
            screenFrom: screenFrom,
          ));
}
