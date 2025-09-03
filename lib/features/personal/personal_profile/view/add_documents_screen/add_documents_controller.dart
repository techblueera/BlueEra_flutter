import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddDocumentsController extends GetxController {
  final TextEditingController documentNameController = TextEditingController();
  RxString documentName = ''.obs;
  RxString selectedFileName = ''.obs;
  RxString selectedFilePath = ''.obs;
  RxBool isFileSelected = false.obs;
  RxBool isLoading = false.obs;

  void setDocumentName(String name) {
    documentName.value = name;
  }

  Future<void> pickDocument() async {
    try {
      isLoading.value = true;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        selectedFileName.value = file.name;
        selectedFilePath.value = file.path ?? '';
        isFileSelected.value = true;

        Get.snackbar(
          'Success',
          'Document selected: ${file.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void addDocument() {
    if (documentName.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a document name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!isFileSelected.value) {
      Get.snackbar(
        'Error',
        'Please select a document to upload',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // TODO: Implement actual document upload to server
    Get.snackbar(
      'Success',
      'Document "${documentName.value}" added successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Reset form
    documentName.value = '';
    selectedFileName.value = '';
    selectedFilePath.value = '';
    isFileSelected.value = false;

    // Navigate back
    Get.back();
  }

  void clearSelection() {
    selectedFileName.value = '';
    selectedFilePath.value = '';
    isFileSelected.value = false;
  }
}
