import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/detail_item.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AddFlatRentalServiceController extends GetxController {
  final currentStep = 0.obs;

  final formKeyStep1 = GlobalKey<FormState>();

  // Example form data
  final propertyName = TextEditingController();
  final landmark = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  final landlineNumber = TextEditingController();
  final landlineCode = TextEditingController();
  final mobile = TextEditingController();
  final charge = TextEditingController();
  final highlights = TextEditingController();

  ContactType? selectedType = ContactType.Mobile;
  final selectedChargesTypes = Rxn<ChargesTypes>();

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;

  final RxList<String> arrHighlights = <String>[].obs;
  RxList<DetailItem> arrMoreDetails = <DetailItem>[].obs;

  int maxUploadImages = 4;
  final RxList<File> roadSideImage = <File>[].obs;
  final RxList<File> roomImages = <File>[].obs;
  final RxList<File> kitchenImage = <File>[].obs;
  final RxList<File> bathroomImage = <File>[].obs;
  final RxList<File> otherImage = <File>[].obs;

  @override
  void onInit() {
    super.onInit();

    ever(currentStep, (step) {
      print('Current Step Changed: $step');
      // You can trigger animations, validations, or scroll resets here.
    });

  }

  void nextStep() {
    if (formKeyStep1.currentState?.validate() ?? false) {
      bool isFormValid = false;

      // Validate contact type
      if (selectedType == ContactType.Mobile) {
        isFormValid = mobile.text.trim().isNotEmpty;
        if (!isFormValid) {
          commonSnackBar(message: 'Please enter your mobile number.');
          return;
        }
      }
      else if (selectedType == ContactType.Landline) {
        isFormValid = landlineCode.text.trim().isNotEmpty &&
            landlineNumber.text.trim().isNotEmpty;
        if (!isFormValid) {
          commonSnackBar(message: 'Please enter your landline code and number.');
          return;
        }
      }
      else {
        commonSnackBar(message: 'Please select contact type.');
        return;
      }

      // Validate charges type
      if (selectedChargesTypes.value == null) {
        commonSnackBar(message: 'Please choose charges type.');
        return;
      }

      // Move to next step
      if (currentStep.value < 1) {
        currentStep.value++;
      }
    } else {
      commonSnackBar(message: 'Please fill all required fields correctly.');
    }
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void onBackPressed(){
    if(currentStep.value > 0){
      previousStep();
    }else{
      Get.back();
    }
  }

  void addHighlights() {
    if(arrHighlights.length == 10){
      commonSnackBar(message: 'You can\'t add more than 10 highlights');
      return;
    }

    final text = highlights.text.trim();
    if (text.isNotEmpty) {
      arrHighlights.add(text);
      highlights.clear();
    }
  }

  void removeHighlights(String tag) {
    arrHighlights.remove(tag);
  }

  void addDetail(DetailItem detail) {
    arrMoreDetails.add(detail);
  }

  void removeDetail(int index) {
    arrMoreDetails.removeAt(index);
  }

  /// Pick images
  Future<List<String>?> pickImages(String title) async {
    final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
      Get.context!,
      title,
    );
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    return null;
  }

  // IDs for GetBuilder updates
  static const String roadSideId = 'roadSide';
  static const String roomId = 'room';
  static const String kitchenId = 'kitchen';
  static const String bathroomId = 'bathroom';
  static const String otherId = 'other';

  /// Pick and add images
  Future<void> addImages({
    required String label,
    required List<File> imageList,
    required String updateId,
  }) async {
    final selectedImages = await pickImages(label);
    if (selectedImages == null || selectedImages.isEmpty) return;

    final newFiles = selectedImages.map((e) => File(e)).toList();
    final remaining = maxUploadImages - imageList.length;
    if (remaining <= 0) {
      commonSnackBar(message: 'You can only upload $maxUploadImages images');
      return;
    }

    imageList.addAll(newFiles.take(remaining));
    update([updateId]);
  }

  /// Remove image
  void removeImageAt({
    required List<File> imageList,
    required int index,
    required String updateId,
  }) {
    if (index >= 0 && index < imageList.length) {
      imageList.removeAt(index);
      update([updateId]);
    }
  }

  // final propertyName = TextEditingController();
  // final landmark = TextEditingController();
  // final location = TextEditingController();
  // final description = TextEditingController();
  // final landlineNumber = TextEditingController();
  // final landlineCode = TextEditingController();
  // final mobile = TextEditingController();
  // final charge = TextEditingController();
  // final highlights = TextEditingController();
  //
  // void validateStep1Form() {
  //     bool commonValid = propertyName.text.trim().isNotEmpty &&
  //         fullBusinessAddressTextController.text.trim().isNotEmpty &&
  //         nameTextController.text.trim().isNotEmpty &&
  //         yourRoleController.text.trim().isNotEmpty &&
  //         viewBusinessDetailsController.businessDescription.value
  //             .trim()
  //             .isNotEmpty &&
  //         picCodeController.text.trim().isNotEmpty &&
  //         emailTextController.text.trim().isNotEmpty;
  //
  //     // Type-specific validation
  //     if (selectedType == ContactType.Mobile) {
  //       isFormValid = commonValid && mobileController.text.trim().isNotEmpty;
  //     } else if (selectedType == ContactType.Landline) {
  //       isFormValid = commonValid &&
  //           landlineCodeController.text.trim().isNotEmpty &&
  //           landlineNumberController.text.trim().isNotEmpty;
  //     } else {
  //       isFormValid = false;
  //     }
  // }

  bool validateBeforePost() {
    final errors = <String>[];

    if (roadSideImage.length < 2) {
      errors.add('Please upload at least 2 road side images');
    }
    if (roomImages.length < 4) {
      errors.add('Please upload at least 4 room images');
    }
    if (kitchenImage.length < 2) {
      errors.add('Please upload at least 2 kitchen images');
    }
    if (bathroomImage.length < 2) {
      errors.add('Please upload at least 2 bathroom images');
    }

    if (errors.isNotEmpty) {
      // Show first missing requirement as a toast/snackbar
      commonSnackBar(message: errors.first);
      return false;
    }

    // call api
    return true;
  }


  void submitForm() {
    if(!validateBeforePost()) return;

    print('Submitting form...');
  }
}
