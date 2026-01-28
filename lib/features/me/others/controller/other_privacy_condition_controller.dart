
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/otherTNC_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherPrivacyConditionController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var aboutList = <OtherTNCData>[].obs;
  var isLoading = false.obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  var title = "".obs;
  var description = "".obs;

  @override
  void onInit() {
    super.onInit();
    getOtherTNCController();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
  }

  void setFormData(OtherTNCData data) {
    titleController.text = data.title ?? "";
    descriptionController.text = data.description ?? "";
    // Image handling would require checking if we want to show existing image or only new selection
  }

  Future<void> getOtherTNCController() async {
    isLoading.value = true;
    try {
      final response = await _repo.getOtherTNCRepo();
      if (response != null && response.isSuccess) {
        final model = OtherTNCModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          aboutList.assignAll(model.data!);
        }
      } else {
        // Handle error
      }
    } catch (e) {
      print("Error fetching blogs: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createOtherTNCController() async {
    if (titleController.text.isEmpty) {
      commonSnackBar(message: "Please enter title");
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: "Please enter description");
      return;
    }

    isLoading.value = true;
    try {
      final body = {
        "title": titleController.text,
        "description": descriptionController.text
      };

      final response = await _repo.createOtherTNCRepo(body);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: "Created successfully");
        Get.back(); // Close form/screen
        getOtherTNCController(); // Refresh list
      } else {
        commonSnackBar(message: response?.message ?? "Failed to create");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOtherTNCController(String id,
    ) async {
    if (titleController.text.isEmpty) {
      commonSnackBar(message: "Please enter title");
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: "Please enter description");
      return;
    }

    isLoading.value = true;
    try {
      final body = {
        "title": titleController.text,
        "description": descriptionController.text
      };

      final response = await _repo.updateOtherTNCRepo(id, body);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: "Updated successfully");
        Get.back();
        getOtherTNCController();
      } else {
        commonSnackBar(message: response?.message ?? "Failed to update");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOtherTNCController(String id) async {
    isLoading.value = true;
    try {
      final response = await _repo.deleteOtherTNCRepo(id);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: "Deleted successfully");
        getOtherTNCController();
      } else {
        commonSnackBar(message: response?.message ?? "Failed to delete");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
