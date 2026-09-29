import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_package_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// A customer viewing a lab's profile: the lab's tests and packages.
///
/// Kept apart from the owner's shared [LabTestController] and
/// [LabPackageController] so browsing someone else's lab doesn't overwrite the
/// owner's own lists. Registered per lab (tagged with [businessId]) by
/// VisitedLabBinding on the lab detail route.
class VisitedLabController extends GetxController {
  VisitedLabController({
    required this.businessId,
    required ViewBusinessDetailsController businessDetails,
    LabTestRepo? testRepo,
    LabPackageRepo? packageRepo,
    LabFullDetailsRepo? fullDetailsRepo,
  })  : _businessDetails = businessDetails,
        _testRepo = testRepo ?? LabTestRepo(),
        _packageRepo = packageRepo ?? LabPackageRepo(),
        _fullDetailsRepo = fullDetailsRepo ?? LabFullDetailsRepo();

  final String businessId;
  final ViewBusinessDetailsController _businessDetails;
  final LabTestRepo _testRepo;
  final LabPackageRepo _packageRepo;
  final LabFullDetailsRepo _fullDetailsRepo;

  final tests = <PathologyTest>[].obs;
  final packages = <LabPackage>[].obs;
  final isLoading = true.obs;

  /// The lab's `LaboratoryProfile._id`, which the tests and packages
  /// endpoints key on (not the business id this screen was opened with).
  String? laboratoryId;

  @override
  void onInit() {
    super.onInit();
    refreshLab();
  }

  /// Reloads the visited business profile (its `user_id` is the key the
  /// lab's full-details endpoint expects), then the lab's tests and packages.
  Future<void> refreshLab() async {
    if (businessId.isNotEmpty) {
      await _businessDetails.viewBusinessProfileById(businessId);
    }
    await _loadTestsAndPackages();
  }

  Future<void> _loadTestsAndPackages() async {
    try {
      final labId = await _resolveLaboratoryId();
      if (labId == null || labId.isEmpty) return;
      laboratoryId = labId;

      // Tests and packages both key on the same LaboratoryProfile._id, so
      // fetch them concurrently.
      final results = await Future.wait([
        _testRepo.getPathologyTestsByLab(labId, ''),
        _packageRepo.getPackagesByLab(labId),
      ]);
      final testsRes = results[0];
      if (testsRes.isSuccess) {
        final List data = testsRes.getExtraData('data') ?? [];
        tests.assignAll(data.map((e) => PathologyTest.fromJson(e)));
      }
      final packagesRes = results[1];
      if (packagesRes.isSuccess) {
        final List data = packagesRes.getExtraData('data') ?? [];
        packages.assignAll(
            data.whereType<Map<String, dynamic>>().map(LabPackage.fromJson));
      }
    } catch (e) {
      debugPrint('VisitedLabController fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _resolveLaboratoryId() async {
    final userId = _businessDetails.visitedBusinessProfileDetails?.data?.userId;
    if (userId == null || userId.isEmpty) return null;
    try {
      final res = await _fullDetailsRepo.getFullDetailsByUserId(userId);
      if (!res.isSuccess) return null;
      final data = res.response?.data?['data'];
      if (data is Map) {
        final profile = data['profile'];
        if (profile is Map) return profile['_id']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('VisitedLabController resolve labId error: $e');
      return null;
    }
  }
}
