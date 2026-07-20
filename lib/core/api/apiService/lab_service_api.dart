import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `lab-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin LabServiceApi {
  final String labServiceGallery = 'lab-service/gallery';
  final String labServiceContactUs = 'lab-service/contact-us';
  final String labServiceProcessResponse = 'lab-service/ai/process-response';
  final String labFullDetails =
      'lab-service/laboratory-profiles/full-details/$userId';
  final String labFacilities = 'lab-service/facilities';
  final String labHealthCamps = 'lab-service/health-camps';
  final String labHealthCampsFd = 'lab-service/health-camps';
  final String labHealthCampsByLab = 'lab-service/health-camps/laboratory';
  final String labProfiles = 'lab-service/laboratory-profiles';
  final String testCategories = 'lab-service/test-categories';
  final String testParameters = 'lab-service/test-parameters';
  final String testPathology = 'lab-service/pathology-tests';
  // Test catalog (predefined tests)
  final String testCatalog = 'lab-service/test-catalog';
  final String testCatalogSelect = 'lab-service/test-catalog/select';
  final String testLabServiceFullDetails =
      'lab-service/laboratory-profiles/full-details';

  // Packages — "Create Your Own Packages" bundle-of-tests screens.
  // See lib/docs/LABORATORY_INTEGRATION.md §1 and
  // lib/docs/FLUTTER_CATALOGUE_INTEGRATION.md PART 6/7.
  final String labPackages = 'lab-service/packages';
  final String labPackagesMe = 'lab-service/packages/me';
  final String labPackagesByLab = 'lab-service/packages/laboratory';

  // Testimonials — profile-section carousel.
  // See lib/docs/LABORATORY_INTEGRATION.md §2.
  final String labTestimonials = 'lab-service/testimonials';
  final String labTestimonialsByLab = 'lab-service/testimonials/laboratory';

  // Customer → laboratory enquiry — POSTs raise a `healthcare_enquiry`
  // in-chat card via Kafka (`newHealthcareEnquiryReceived`); PUT flips it
  // when the owner accepts/declines. Contract matches the hospital /
  // hotel enquiry card shape — only `category` = "LABORATORY" differs.
  // See lib/docs/LABORATORY_ENQUIRY_INTEGRATION_GUIDE.md.
  final String laboratoryEnquiries = 'lab-service/laboratory-enquiries';
  String laboratoryEnquiryStatus(String enquiryId) =>
      'lab-service/laboratory-enquiries/$enquiryId/status';
  String laboratoryEnquiryById(String enquiryId) =>
      'lab-service/laboratory-enquiries/$enquiryId';

  // Customer → laboratory test booking — the enquiry-first step after
  // acceptance. POSTs create a `healthcare_booking` card
  // (`newHealthcareBookingReceived`); PUT status flips it. Owned by
  // be_laboratory_service. See lib/docs/laboratory-booking-ui-integration.md.
  final String laboratoryBookings = 'lab-service/laboratory-bookings';
  String laboratoryBookingStatus(String bookingId) =>
      'lab-service/laboratory-bookings/$bookingId/status';
  String laboratoryBookingById(String bookingId) =>
      'lab-service/laboratory-bookings/$bookingId';
  // Customer-cancel path (doc §2b): customer can cancel their own
  // booking while it is `pending` OR `accepted`. Distinct from the
  // owner-only status PUT above so the chat card can pick the right
  // transition per role.
  String laboratoryBookingCancel(String bookingId) =>
      'lab-service/laboratory-bookings/$bookingId/cancel';
  // Customer outbox — bookings I sent.
  final String laboratoryBookingsMe = 'lab-service/laboratory-bookings/me';
  // Owner inbox — bookings received on my labs.
  final String laboratoryBookingsOwnerMe =
      'lab-service/laboratory-bookings/owner/me';
}
