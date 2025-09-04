import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/photo_post_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/size_config.dart';

class PhotoPostController extends GetxController {
  TextEditingController descriptionTextEdit = TextEditingController();
  TextEditingController natureOfPostTextEdit = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final Rx<PhotoPost> photoPost = PhotoPost(photoUrls: []).obs;
  final RxList<String> selectedPhotos = <String>[].obs;
  final RxList<File> selectedPhotoFiles = <File>[].obs;
  final RxList<String> taggedPeople = <String>[].obs;
  final RxString description = ''.obs;
  final RxString natureOfPost = ''.obs;
  final RxInt charCount = 0.obs;
  final RxBool isLoading = false.obs;
  final int maxCharCount = 140;
  final int maxPhotos = 5; // Updated to 5 as per requirement
  final int minPhotos = 1; // Minimum 1 photo required
  Rx<Post>? postData = Post(id: '').obs;

  // Location variables
  final Rx<double?> latitude = Rx<double?>(null);
  final Rx<double?> longitude = Rx<double?>(null);

  bool isPhotoPostEdit = false;

  void addPhotos() async {
    if (selectedPhotos.length >= maxPhotos) {
      commonSnackBar(
        message: 'You can only upload up to $maxPhotos photos',
      );

      return;
    }

      final List<XFile>? images = await _picker.pickMultiImage();
      if (images == null) return;

      for (final image in images) {
        if (selectedPhotos.length >= maxPhotos) break;

        final compressedFile = await SelectProfilePictureDialog().compressImage(File(image.path));
        if (compressedFile != null) {
          selectedPhotos.add(compressedFile.path);
          selectedPhotoFiles.add(compressedFile);
        }
      }

      updatePhotoPost(); // your existing UI update
  }

  void removePhoto(int index) {
    if (index >= 0 && index < selectedPhotos.length) {
      selectedPhotos.removeAt(index);
      selectedPhotoFiles.removeAt(index);
      updatePhotoPost();
    }
  }

  void updateDescription(String text) {
    description.value = text;
    charCount.value = text.length;
    updatePhotoPost();
  }

  void addTaggedPerson(String name) {
    if (!taggedPeople.contains(name)) {
      taggedPeople.add(name);
      updatePhotoPost();
    }
  }

  void removeTaggedPerson(String name) {
    taggedPeople.remove(name);
    updatePhotoPost();
  }

  void updateNatureOfPost(String nature) {
    natureOfPost.value = nature;
    updatePhotoPost();
  }

  void updateLocation(double lat, double lng) {
    latitude.value = lat;
    longitude.value = lng;
  }

  void updatePhotoPost() {
    photoPost.update((val) {
      val?.photoUrls = selectedPhotos;
      val?.description = description.value;
      val?.taggedPeople = taggedPeople;
      val?.natureOfPost = natureOfPost.value;
    });
  }
  late void Function(double) _updateProgressUI;

  Future submitPost(PostVia? postVia) async {
    if (!isPhotoPostEdit) {
      if (selectedPhotoFiles.isEmpty || selectedPhotoFiles.length < minPhotos) {
        commonSnackBar(message: 'Please upload at least $minPhotos photo');
        return;
      }
    }

    try {
      isLoading.value = true;

      showUploadingProgressDialog(context: Get.context!, progress: 0.01);

      final position = await getCurrentLocation();
      updateLocation(
        position?.latitude ?? 0,
        position?.longitude ?? 0,
      );



      ResponseModel response = isPhotoPostEdit
          ? await PostRepo().updatePostRepo(
        bodyReq: {
          ApiKeys.type: AppConstants.PHOTO_POST,
          ApiKeys.sub_title: description.value,
          ApiKeys.nature_of_post: natureOfPost,
          ApiKeys.tagged_users: Get.find<TagUserController>()
              .selectedUsers
              .map((user) => user.id.toString())
              .join(','),
          ApiKeys.latitude: position?.latitude.toString(),
          ApiKeys.longitude: position?.longitude.toString(),
        },
        isMultiPartPost: true,
        postId: postData?.value.id,
      )
          : await PostRepo().createPost(
        photoPost.value,
        selectedPhotoFiles,
        latitude.value,
        longitude.value,
        postVia,
        (progress) {
          _updateProgressUI(progress);

        },
      );

      Navigator.of(Get.context!, rootNavigator: true).pop();

      if (response.isSuccess) {
        commonSnackBar(
          message: response.response?.data?['message'] ??
              'Your photo post has been created!',
        );
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = true;
        Get.until((route) =>
        route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
        resetForm();
      } else {
        commonSnackBar(
          message: response.response?.data?['message'] ??
              'Failed to create post. Please try again.',
        );
      }
    } catch (e) {
      // Optional error logging
    } finally {
      isLoading.value = false;
    }
  }
  void showUploadingProgressDialog({
    required BuildContext context,
    required double progress,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Uploading...",
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.size10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          content: StatefulBuilder(
            builder: (context, setState) {
              _updateProgressUI = (double newProgress) {
                setState(() {
                  progress = newProgress;
                });
              };

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 8,
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}% completed",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  void resetForm() {
    selectedPhotos.clear();
    selectedPhotoFiles.clear();
    description.value = '';
    taggedPeople.clear();
    natureOfPost.value = '';
    charCount.value = 0;
    latitude.value = null;
    longitude.value = null;
    updatePhotoPost();
  }
}
