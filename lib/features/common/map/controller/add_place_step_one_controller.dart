
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddPlaceStepOneController extends GetxController {
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController placesController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  RxList<String> selectedImages = <String>[].obs;
  RxList<String> selectedCategoryIds = <String>[].obs; // Add this line
  RxBool isConfirmCheck = false.obs;
  RxBool validate = false.obs, isFetchLocationLoading = false.obs;
  RxString lat = "".obs, long = "".obs;

  @override
  void onClose() {
    categoryController.dispose();
    placesController.dispose();
    landmarkController.dispose();
    super.onClose();
  }

  void toggleConfirmCheck() {
    isConfirmCheck.value = !isConfirmCheck.value;
    validateForm();
  }

  Future<void> fetchLocation(BuildContext context) async {
    try {
      isFetchLocationLoading.value = true;
      final locationData = await LocationService.fetchLocation(context);
      if (locationData != null) {
        final position = locationData["position"];

        lat.value = position.latitude.toString();
        long.value = position.longitude.toString();

        final address = locationData["address"];
        landmarkController.text = address;
        validateForm();
      }
      isFetchLocationLoading.value = false;
    } on Exception {
      isFetchLocationLoading.value = false;

      // TODO
    }
  }

  Future<String?> captureImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // if (!isAllowedImageExtension(pickedFile.path)) {
      //   commonSnackBar(message: 'Only JPG, JPEG, and PNG files are allowed.');
      //   return null;
      // }
      return pickedFile.path;
    }
    return null;
  }

  void addImage(String imagePath) {
    selectedImages.add(imagePath);
    validateForm();
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
    validateForm();
  }

  void validateForm() {
    final categoryIsNotEmpty = categoryController.text.isNotEmpty;
    final placesIsNotEmpty = placesController.text.isNotEmpty;
    final landmarkIsNotEmpty = landmarkController.text.isNotEmpty;
    final selectedImagesIsNotEmpty = selectedImages.isNotEmpty;
    final check = isConfirmCheck.value;

    validate.value = categoryIsNotEmpty &&
        placesIsNotEmpty &&
        landmarkIsNotEmpty &&
        selectedImagesIsNotEmpty &&
        check;
  }
}
