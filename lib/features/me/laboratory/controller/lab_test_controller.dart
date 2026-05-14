import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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
  final RxList<TestCatalogItem> catalogTests = <TestCatalogItem>[].obs;
  final RxString descriptionTest = ''.obs;

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

  static const List<String> collectionMethods = [
    'Hospital',
    'Home',
    'Laboratory',
    'Other',
  ];

  static const List<String> genderList = ['Male', 'Female'];

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

  Future<void> fetchCategories() async {
    try {
      final ResponseModel res = await _repo.getTestCategories();
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        categories.value = data.map((e) => TestCategory.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchCategories ERROR $e");
    }
  }

  Future<void> fetchParameters() async {
    try {
      final ResponseModel res = await _repo.getTestParameters();
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        parameters.value =
            data.map((e) => TestParameter.fromJson(e)).toList();
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
    int limit = 20,
  }) async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getTestCatalog(
        groupCategory: groupCategory,
        page: page,
        limit: limit,
      );
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        catalogTests.value =
            data.map((e) => TestCatalogItem.fromJson(e)).toList();
      }
    } catch (e) {
      logs("LabTestController.fetchCatalog ERROR $e");
    } finally {
      isLoading.value = false;
    }
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
