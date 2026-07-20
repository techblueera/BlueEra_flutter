import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:get/get.dart';

/// CRUD over pathology tests plus reference data (categories, parameters,
/// specimen / collection / gender / package pickers) used by the test form
/// and listing screens.
class LabTestController extends GetxController {
  final LabTestRepo _repo = LabTestRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxList<TestCategory> categories = <TestCategory>[].obs;
  final RxList<TestParameter> parameters = <TestParameter>[].obs;
  final RxList<PathologyTest> tests = <PathologyTest>[].obs;
  // Kept isolated from [tests] so the Popular Tests carousel on the Lab
  // Tests tab doesn't get overwritten every time a category screen loads.
  final RxList<PathologyTest> popularTests = <PathologyTest>[].obs;
  final RxBool isLoadingPopular = false.obs;
  final RxList<TestCatalogItem> catalogTests = <TestCatalogItem>[].obs;
  final RxString descriptionTest = ''.obs;

  // Catalog pagination state — [fetchCatalog] resets when page == 1 and
  // appends otherwise. [catalogHasMore] flips false when the backend returns
  // a short page (fewer items than [_catalogPageSize]).
  final RxBool isLoadingMoreCatalog = false.obs;
  final RxBool catalogHasMore = true.obs;
  int catalogPage = 1;
  static const int _catalogPageSize = 20;

  // ---- Picker reference data (UI-facing constants) -------------------------

  static const List<String> specimenList = [
    'Blood',
    'Urine',
    'Stool',
    'Sputum',
    'Swab',
    'Tissue',
    'Saliva',
    'Body Fluid',
  ];

  // Values match the backend `specimenCollectionMethod` enum returned by
  // `GET /test-catalog/enums` (`Hospital`, `Home`, `Laboratory`, `Other`,
  // `All`). See `lib/docs/CREATE_PATHOLOGY_TEST_GUIDE.md` §1.2.
  static const List<String> collectionMethods = [
    'Hospital',
    'Home',
    'Laboratory',
    'Other',
    'All',
  ];

  // Matches the backend `gender` enum (`Male`, `Female`, `All`) — see guide
  // §1.2. `All` means "no gender restriction" and is the backend default.
  static const List<String> genderList = ['Male', 'Female', 'All'];

  // The 6 backend `groupCategory` enum values (guide §1.2 + §3). These are
  // the top-level UI tabs and are NOT valid `packageType` values — kept in
  // a separate list so the two dropdowns can never share a source.
  static const List<String> groupCategoryList = [
    'Blood & Routine Tests',
    'Preventive & Wellness Checkups',
    'Women, Pregnancy & Child Health',
    'Diagnostics & Imaging',
    'Organ & System Health',
    'Infection, Cancer & Immunity',
  ];

  // Backend `packageType` enum values (guide §1.2 / §3). Must contain ONLY
  // real package types — never a `groupCategory` value. Sending e.g.
  // `"Blood & Routine Tests"` here is a guaranteed 400.
  static const List<String> packageTypeList = [
    'Basic Blood Test',
    'Basic Health Checkup',
    'Full Body Checkup',
    'Executive Health Package',
    'Diabetes Package',
    'Thyroid Package',
    'Heart Check-up Package',
    'Senior Citizen Package',
    'Men Health Package',
    "Women's Health Package",
    'Fertility & Pregnancy Package',
    'Pediatric Health Package',
    'Pathology',
    'Radiology',
    'Pulmonology Diagnostics',
    'Ophthalmology & ENT',
    'Gastroenterology Package',
    'Neurological Package',
    'Cancer Screening Package',
    'HIV / STI Package',
    'Kidney Disease Package',
    'Liver Disease Package',
    'Bone & Joint Package',
    'Autoimmune Package',
    'Allergy & Immunology Package',
    'Infectious Disease Package',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchParameters();
  }

  // ---- Reads ----------------------------------------------------------------

  // Both fetches use the `/laboratory/{labId}` variant — the unscoped
  // endpoints return every lab's rows, and picking by name grabs a
  // different lab's `_id`, which the backend then rejects on create with
  // "testCategory does not belong to your laboratory".
  // See lib/docs/CREATE_PATHOLOGY_TEST_GUIDE.md §4.

  Future<void> fetchCategories({String? labId}) async {
    final scopedLabId = labId ?? labIDGlobal;
    if (scopedLabId.isEmpty) return;
    try {
      final ResponseModel res =
          await _repo.getTestCategoriesByLab(scopedLabId);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        categories.value = data.map((e) => TestCategory.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchCategories ERROR $e");
    }
  }

  Future<void> fetchParameters({String? labId}) async {
    final scopedLabId = labId ?? labIDGlobal;
    if (scopedLabId.isEmpty) return;
    try {
      final ResponseModel res =
          await _repo.getTestParametersByLab(scopedLabId);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        parameters.value = data.map((e) => TestParameter.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchParameters ERROR $e");
    }
  }

  Future<void> fetchTests(String collection) async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getPathologyTests(collection);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        tests.value = data.map((e) => PathologyTest.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchTests ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// All-categories fetch used by the Lab Tests tab's Popular Tests
  /// carousel. Passes an empty groupCategory so the backend returns the
  /// unfiltered list, then trims to [limit].
  Future<void> fetchPopularTests({int limit = 5}) async {
    try {
      isLoadingPopular.value = true;
      final ResponseModel res = await _repo.getPathologyTests('');
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final all = data.map((e) => PathologyTest.fromJson(e)).toList();
        popularTests.value = all.take(limit).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchPopularTests ERROR $e");
    } finally {
      isLoadingPopular.value = false;
    }
  }

  Future<void> fetchTestsByLab(String labId, String collection) async {
    try {
      isLoading.value = true;
      final ResponseModel res =
          await _repo.getPathologyTestsByLab(labId, collection);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        tests.value = data.map((e) => PathologyTest.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchTestsByLab ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCatalog({
    required String groupCategory,
    int page = 1,
    int limit = _catalogPageSize,
  }) async {
    final isFirstPage = page == 1;
    try {
      if (isFirstPage) {
        isLoading.value = true;
        catalogPage = 1;
        catalogHasMore.value = true;
      } else {
        isLoadingMoreCatalog.value = true;
      }
      final ResponseModel res = await _repo.getTestCatalog(
        groupCategory: groupCategory,
        page: page,
        limit: limit,
      );
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final items = data.map((e) => TestCatalogItem.fromJson(e)).toList();
        if (isFirstPage) {
          catalogTests.value = items;
        } else if (items.isNotEmpty) {
          catalogTests.addAll(items);
        }
        // Backend returns no total; short pages mark the end.
        if (items.length < limit) {
          catalogHasMore.value = false;
        }
        if (items.isNotEmpty) {
          catalogPage = page;
        }
      }
    } catch (e) {
      logs("LabTestController.fetchCatalog ERROR $e");
    } finally {
      isLoading.value = false;
      isLoadingMoreCatalog.value = false;
    }
  }

  /// Loads the next catalog page. No-op when already loading or exhausted.
  Future<void> fetchMoreCatalog({required String groupCategory}) async {
    if (!catalogHasMore.value ||
        isLoading.value ||
        isLoadingMoreCatalog.value) {
      return;
    }
    await fetchCatalog(
      groupCategory: groupCategory,
      page: catalogPage + 1,
    );
  }

  // ---- Writes ---------------------------------------------------------------

  Future<bool> selectCatalog(String id,
      {Map<String, dynamic>? customData}) async {
    try {
      isSaving.value = true;
      final ResponseModel res =
          await _repo.selectCatalogTests([id], overrides: customData);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labSelectedSuccess.tr);
        return true;
      }
      commonSnackBar(
        message:
            res.response?.data['message'] ?? AppStrings.labFailedToSelect.tr,
      );
      return false;
    } catch (e) {
      logs("LabTestController.selectCatalog ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> createTest(PathologyTest test) async {
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.createPathologyTest(test.toJson());
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labTestAddedSuccess.tr);
        await fetchTests(test.collection ?? '');
        return true;
      }
      commonSnackBar(
        message:
            res.response?.data['message'] ?? AppStrings.labFailedToAddTest.tr,
      );
      return false;
    } catch (e) {
      logs("LabTestController.createTest ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateTest(PathologyTest test) async {
    try {
      isSaving.value = true;
      final ResponseModel res =
          await _repo.updatePathologyTest(test.id!, test.toJson());
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labTestUpdatedSuccess.tr);
        await fetchTests(test.collection ?? '');
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ??
            AppStrings.labFailedToUpdateTest.tr,
      );
      return false;
    } catch (e) {
      logs("LabTestController.updateTest ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteTest(String id, String collection) async {
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.deletePathologyTest(id);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labTestDeletedSuccess.tr);
        await fetchTests(collection);
      } else {
        commonSnackBar(
          message: res.response?.data['message'] ??
              AppStrings.labFailedToDeleteTest.tr,
        );
      }
    } catch (e) {
      logs("LabTestController.deleteTest ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isSaving.value = false;
    }
  }
}
