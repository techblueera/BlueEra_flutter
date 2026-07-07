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
  // See lib/docs/LABORATORY_INTEGRATION.md §1.
  final String labPackages = 'lab-service/packages';
  final String labPackagesByLab = 'lab-service/packages/laboratory';

  // Testimonials — profile-section carousel.
  // See lib/docs/LABORATORY_INTEGRATION.md §2.
  final String labTestimonials = 'lab-service/testimonials';
  final String labTestimonialsByLab = 'lab-service/testimonials/laboratory';
}
