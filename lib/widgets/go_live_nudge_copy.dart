import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/navigation/me_section_kind.dart';

/// Picks the body copy for the shared "You're offline" nudge
/// ([showGoLiveNudgeSheet]) from the account's own line of business.
///
/// Now that go-live reaches every Me screen, one sentence can't carry it. A
/// restaurant that isn't live is missing ORDERS; a clinic is missing
/// APPOINTMENTS; a showroom is missing ENQUIRIES; a plumber is missing WORK.
/// "Customers can't find your shop" is wrong-ish for all four, and being told
/// the wrong thing about your own business is what makes a nudge easy to
/// dismiss without reading.
///
/// Only the BODY varies. Title ("You're offline") and CTA ("Turn on Go Live")
/// stay shared — see [showGoLiveNudgeSheet], which is deliberately one shape
/// everywhere.
///
/// These return translation KEYS, not sentences; callers apply `.tr`.
///
/// Business copy comes off [MeSectionKind], the same classifier the Me-tab
/// router switches on to choose the screen — not a second reading of the
/// type/category globals. That is the whole reason the enum exists: the sheet
/// and the screen behind it now can't describe different businesses.
/// Body key for a BUSINESS account, from the SAME [MeSectionKind] the Me-tab
/// router uses to pick the screen — so what the sheet says and what the
/// merchant is looking at can't disagree.
///
/// Exhaustive on purpose: a new section added to the router has to be given
/// wording here before this compiles.
String goLiveNudgeBodyForBusiness() {
  switch (resolveMeSectionKind()) {
    case MeSectionKind.food:
      return AppStrings.goLiveNudgeBodyFood;
    case MeSectionKind.grocery:
      return AppStrings.goLiveNudgeBodyGrocery;
    case MeSectionKind.pharmacy:
      return AppStrings.goLiveNudgeBodyPharmacy;
    // Doctors, hospitals and labs sell TIME, not stock: what they lose while
    // offline is appointments.
    case MeSectionKind.doctor:
    case MeSectionKind.hospital:
    case MeSectionKind.laboratory:
      return AppStrings.goLiveNudgeBodyAppointments;
    case MeSectionKind.hotel:
      return AppStrings.goLiveNudgeBodyHotel;
    case MeSectionKind.school:
      return AppStrings.goLiveNudgeBodySchool;
    // All three are a catalogue of goods, whoever made them.
    case MeSectionKind.product:
    case MeSectionKind.manufacturerProduct:
    case MeSectionKind.automotiveParts:
      return AppStrings.goLiveNudgeBodyProduct;
    case MeSectionKind.vehicleSales:
      return AppStrings.goLiveNudgeBodyVehicle;
    // A workshop and a service business take the same thing: requests.
    case MeSectionKind.automotiveService:
    case MeSectionKind.service:
      return AppStrings.goLiveNudgeBodyService;
    case MeSectionKind.unknown:
      return AppStrings.goLiveNudgeBusinessBody;
  }
}

/// Body key for an INDIVIDUAL account, from `userProfileTypeGlobal` /
/// `userProfessionGlobal`.
///
/// Riders never get here — `RiderServiceScreen` runs its own sheet with
/// ride-request wording — but [isGigWorkerAccount] covers them anyway, so a
/// rider who somehow reaches this reads about work requests rather than a
/// shopfront.
String goLiveNudgeBodyForIndividual() {
  // Checked FIRST, because it is the only branch that also matches on
  // profession: a gig worker whose profile type hasn't hydrated yet (cold
  // start, re-login) is still identifiable as one.
  if (isGigWorkerAccount()) return AppStrings.goLiveNudgeBodyGigWork;

  switch (userProfileTypeGlobal) {
    // Grouped: both sell hands-on work by the job. SKILL_WORKER has no Me
    // screen of its own yet (the router drops it on the unknown-profile
    // fallback), but if it ever reaches this sheet, "request your services" is
    // the right sentence for it.
    case SELF_EMPLOYED:
    case SKILL_WORKER:
      return AppStrings.goLiveNudgeBodySelfEmployed;
    case PROFESSIONAL:
      return AppStrings.goLiveNudgeBodyProfessional;
  }
  return AppStrings.goLiveNudgeIndividualBody;
}
