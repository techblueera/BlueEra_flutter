import 'dart:io';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryPartnerController extends GetxController{
  /// step 1
  final fullNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final emailController = TextEditingController();
  Rx<GenderType?> selectedGender = Rx<GenderType?>(null);
  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;


  /// step 2
  final locationController = TextEditingController();
  final landmarkController = TextEditingController();
  final pinCodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool enabledLiveLocation = false.obs;

  /// step 3
  final aadharController = TextEditingController();
  final panNumberController = TextEditingController();
  int maxLiveUploadImages = 2;
  static const String livePhotoId = 'livePhotoId';
  final RxList<File> livePhoto = <File>[].obs;
  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();

  /// step 4
  final rcController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();
  final Rxn<File> drivingLicenseFrontImage = Rxn<File>();
  final Rxn<File> drivingLicenseBackImage = Rxn<File>();

  /// step 5
  static const String vehicleNumberPlateImageId = 'vehicleNumberPlateImageId';
  static const String vehicleRightSideImageId = 'vehicleRightSideImageId';
  static const String vehicleLeftSideImageId = 'vehicleLeftSideImageId';
  static const String vehicleFrBkImageId = 'vehicleFrBkImageId';
  final RxList<File> vehicleNumberPlateImages = <File>[].obs;
  final RxList<File> vehicleRightSideImages = <File>[].obs;
  final RxList<File> vehicleLeftSideImages = <File>[].obs;
  final RxList<File> vehicleFrBkImages = <File>[].obs;
  int maxVehicleImageUpload = 4;

  /// steps 6
  final vehicleNameController = TextEditingController();
  final vehicleNumnberController = TextEditingController();
  final vehicleModelController = TextEditingController();

  final RxBool isTermsAccepted = false.obs;
  Rx<VehicleRegistrationType?> selectedVehicleRegistrationType = Rx<VehicleRegistrationType?>(null);
  Rx<VehicleType?> selectedVehicleType = Rx<VehicleType?>(null);
  Rx<FuelType?> selectedFuelType = Rx<FuelType?>(null);


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


  /// Pick and add images
  Future<void> addImages({
    required String label,
    required List<File> imageList,
    required String updateId,
    required int maxUploadImages
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

  /// Add single image
   Future<String?> pickImage({
    required BuildContext context,
    String title = "Select Photo",
    bool showError = true,
  }) async {
    try {
      final String? selected = await SelectProfilePictureDialog.showLogoDialog(
        context,
        title,
      );

      if (selected != null && selected.isNotEmpty) {
        return selected;
      } else {
        if (showError) {
          commonSnackBar(message: "Something went wrong, please try again");
        }
        return null;
      }
    } catch (e) {
      if (showError) {
        commonSnackBar(message: "Error selecting image: $e");
      }
      return null;
    }
  }

}