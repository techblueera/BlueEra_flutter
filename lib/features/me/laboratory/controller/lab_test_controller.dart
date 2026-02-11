import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:get/get.dart';

class LabTestController extends GetxController {
  final LabTestRepo _repo = LabTestRepo();

  var isLoading = false.obs;
  var categories = <TestCategory>[].obs;
  var parameters = <TestParameter>[].obs;
  var tests = <PathologyTest>[].obs;
  var descriptionTest = ''.obs;
  final List<String> specimenList = [
    'Blood',
    'Urine',
    'Stool',
    'Sputum',
    'Swab',
    'Tissue',
    'Saliva',
    'Body Fluid'
  ];
  final List<String> collectionMethods = [
    'Hospital',
    'Home',
    'Laboratory',
    'Other'
  ];
  final List<String> genderList = ['Male', 'Female'];

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchParameters();
  }

  Future<void> fetchCategories() async {
    try {
      ResponseModel res = await _repo.getTestCategories();
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        categories.value = data.map((e) => TestCategory.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> fetchParameters() async {
    try {
      ResponseModel res = await _repo.getTestParameters();
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        parameters.value = data.map((e) => TestParameter.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching parameters: $e");
    }
  }

  Future<void> fetchTests(String collection) async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.getPathologyTests(collection);
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        tests.value = data.map((e) => PathologyTest.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching tests: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTest(PathologyTest test) async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.createPathologyTest(test.toJson());
      if (res.isSuccess) {
        commonSnackBar(message: "Test added successfully");
        fetchTests(test.collection ?? "");
        return true;
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? "Failed to add test");
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "Error adding test: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTest(PathologyTest test) async {
    isLoading.value = true;
    try {
      ResponseModel res =
          await _repo.updatePathologyTest(test.id!, test.toJson());
      if (res.isSuccess) {
        commonSnackBar(message: "Test updated successfully");
        fetchTests(test.collection ?? "");
        return true;
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? "Failed to update test");
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "Error updating test: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTest(String id, String collection) async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.deletePathologyTest(id);
      if (res.isSuccess) {
        commonSnackBar(message: "Test deleted successfully");
        fetchTests(collection);
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? "Failed to delete test");
      }
    } catch (e) {
      commonSnackBar(message: "Error deleting test: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
