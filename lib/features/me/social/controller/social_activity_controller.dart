import 'dart:io';
import 'package:BlueEra/core/api/model/social_activity_res_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SocialActivityController extends GetxController {
  final SocialProfileRepo _repo = SocialProfileRepo();

  // Observables
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isFormValid = false.obs;
  var activityList = <SocialActivityData>[].obs;
  
  // Form Fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController typeController = TextEditingController(); // activityType
  final TextEditingController roleController = TextEditingController();
  final TextEditingController organizerController = TextEditingController(); // organisationName
  final TextEditingController impactController = TextEditingController();
  final TextEditingController venueController = TextEditingController(); // location name
  
  // Date
  var startDay = DateTime.now().day.obs;
  var startMonth = DateTime.now().month.obs;
  var startYear = DateTime.now().year.obs;

  // Location
  var lat = 0.0.obs;
  var lng = 0.0.obs;

  // Image
  var selectedImage = Rxn<File>(null);
  var serverImageUrl = Rx<String?>(null);

  // Edit Mode
  var isEditMode = false.obs;
  var currentActivityId = "".obs;
  var activityTitle = "".obs;
  var activityType = "".obs;
  var activityRole = "".obs;
  var activityOrganizer = "".obs;

  @override
  void onInit() {
    super.onInit();
    getActivities();
    
    // Add listeners for validation
    titleController.addListener(validateForm);
    descriptionController.addListener(validateForm);
    typeController.addListener(validateForm);
    roleController.addListener(validateForm);
    organizerController.addListener(validateForm);
    impactController.addListener(validateForm);
    venueController.addListener(validateForm);
  }

  void validateForm() {
    bool isValid = titleController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        typeController.text.trim().isNotEmpty &&
        roleController.text.trim().isNotEmpty &&
        organizerController.text.trim().isNotEmpty &&
        impactController.text.trim().isNotEmpty &&
        venueController.text.trim().isNotEmpty &&
        (selectedImage.value != null || (serverImageUrl.value != null && serverImageUrl.value!.isNotEmpty));
    
    isFormValid.value = isValid;
  }

  Future<void> getActivities() async {
    isLoading.value = true;
    try {
      final res = await _repo.getSocialActivities();
      if (res.success == true && res.data != null) {
        activityList.assignAll(res.data!);
      }
    } catch (e) {
      print("Error fetching activities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(BuildContext context) async {
     final picker = ImagePicker();
     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
     if (pickedFile != null) {
       selectedImage.value = File(pickedFile.path);
       validateForm();
     }
  }

  Future<void> save() async {
    if (!isFormValid.value) return;

    isSaving.value = true;
    try {
      String? finalImageUrl = serverImageUrl.value;

      if (selectedImage.value != null) {
        UploadResult result = await S3UploadService.uploadFile(selectedImage.value!);
        if (result.isSuccess) {
          finalImageUrl = result.url;
        } else {
          commonSnackBar(message: "Image upload failed: ${result.message}");
          isSaving.value = false;
          return;
        }
      }

      String dateStr = "${startYear.value}-${startMonth.value.toString().padLeft(2, '0')}-${startDay.value.toString().padLeft(2, '0')}";

      final body = {
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "mediaUrl": finalImageUrl,
        "mediaType": "image",
        "activityType": typeController.text.trim(),
        "date": dateStr,
        "location": {
          "name": venueController.text.trim(),
          "type": "Point",
          "coordinates": [lng.value, lat.value] 
        },
        "role": roleController.text.trim(),
        "organisationName": organizerController.text.trim(),
        "impact": impactController.text.trim()
      };

      SocialActivityResModel res;
      if (isEditMode.value) {
        res = await _repo.updateSocialActivity(currentActivityId.value, body);
      } else {
        res = await _repo.createSocialActivity(body);
      }

      if (res.success == true) {
        commonSnackBar(message: isEditMode.value ? "Activity updated successfully" : "Activity created successfully");
        Get.back(); // Go back to list
        getActivities(); // Refresh list
      } else {
        commonSnackBar(message: "Failed to save activity");
      }
    } catch (e) {
      commonSnackBar(message: "Error saving: $e");
    } finally {
      isSaving.value = false;
    }
  }
  
  Future<void> deleteActivity(String id) async {
    try {
      final res = await _repo.deleteSocialActivity(id);
      if (res.success == true) {
         commonSnackBar(message: "Activity deleted successfully");
         getActivities();
      } else {
        commonSnackBar(message: "Failed to delete activity");
      }
    } catch (e) {
      commonSnackBar(message: "Error deleting: $e");
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    typeController.clear();
    roleController.clear();
    organizerController.clear();
    impactController.clear();
    venueController.clear();
    selectedImage.value = null;
    serverImageUrl.value = null;
    isEditMode.value = false;
    currentActivityId.value = "";
    lat.value = 0.0;
    lng.value = 0.0;
    
    // Reset date to today
    var now = DateTime.now();
    startDay.value = now.day;
    startMonth.value = now.month;
    startYear.value = now.year;
    
    validateForm();
  }

  void setEditData(SocialActivityData data) {
    isEditMode.value = true;
    currentActivityId.value = data.sId ?? "";
    titleController.text = data.title ?? "";
    descriptionController.text = data.description ?? "";
    typeController.text = data.activityType ?? "";
    roleController.text = data.role ?? "";
    organizerController.text = data.organisationName ?? "";
    impactController.text = data.impact ?? "";
    venueController.text = data.location?.name ?? "";
    serverImageUrl.value = data.mediaUrl;
    
    if (data.location?.coordinates != null && data.location!.coordinates!.length >= 2) {
      lng.value = data.location!.coordinates![0];
      lat.value = data.location!.coordinates![1];
    }

    if (data.date != null) {
       try {
         DateTime dt = DateTime.parse(data.date!);
         startDay.value = dt.day;
         startMonth.value = dt.month;
         startYear.value = dt.year;
       } catch (e) {
         // ignore parse error
       }
    }
    validateForm();
  }
}
