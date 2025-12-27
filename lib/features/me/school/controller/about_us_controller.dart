import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AboutUsController extends GetxController {
  final Rxn<File> historyImageFile = Rxn<File>();
  RxString historyText = ''.obs;
  final Rxn<File> directorMessageImageFile = Rxn<File>();
  RxString directorMessageText = ''.obs;
  RxString departmentDescriptionText = ''.obs;



  ///DEPARTMENT SCREEN LOGIC
  var selectedImages = <File>[].obs;
  final ImagePicker _picker = ImagePicker();

  // Pick images from gallery or camera
  Future<void> pickImages(ImageSource source) async {
    if (selectedImages.length >= 5) {
      Get.snackbar("Limit Reached", "You can only add up to 5 images.");
      return;
    }

    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      // Only add images up to the limit of 5
      for (var file in pickedFiles) {
        if (selectedImages.length < 5) {
          selectedImages.add(File(file.path));
        }
      }
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedImages.add(File(pickedFile.path));
      }
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  int maxDepartmentImageUpload = 5;
  final RxList<File> addMoreImages = <File>[].obs;
// Validation Variables
  final isFormValid = false.obs;

  // This function checks all conditions
  void validateForm({
    required String deptName,
    required String hodName,
    required String staffNames,
    required String description,
    required List images,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = deptName.isNotEmpty &&
        hodName.isNotEmpty &&
        staffNames.isNotEmpty &&
        description.isNotEmpty &&
        images.isNotEmpty;
  }

  // This function checks all conditions
  void courseValidateForm({
    required String deptName,
    required String hodName,
    required String staffNames,
    required String description,
    required List images,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = deptName.isNotEmpty &&
        hodName.isNotEmpty &&
        staffNames.isNotEmpty &&
        description.isNotEmpty &&
        images.isNotEmpty;
  }
  ///ADD COURSE...
// Radio button state
  var feeType = 'Yearly'.obs; // Default selection

  // Fee amount
  var feeAmount = ''.obs;

  void setFeeType(String? value) {
    if (value != null) feeType.value = value;
  }
}
