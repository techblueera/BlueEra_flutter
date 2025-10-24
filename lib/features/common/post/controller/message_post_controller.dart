
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/photo_post_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:croppy/croppy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dioObj;
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MessagePostController extends GetxController {
  /// ADD MSG POST
  Rx<ApiResponse> addPostMessage = ApiResponse.initial('Initial').obs;

  RxBool isLoading = false.obs;

  RxString postText = ''.obs;
  RxString messageText = ''.obs;
  RxString messageTitle = ''.obs;
  RxBool isAddLink = false.obs;
  RxBool isAddTitle = true.obs;
  RxList<User>? taggedSelectedUsersList = <User>[].obs;
  // RxList<File> selectedFiles = <File>[].obs;

  final postTitleController = TextEditingController().obs;
  final postTextDataController = TextEditingController().obs;
  final descriptionMessage = TextEditingController().obs;
  final natureOfPostController = TextEditingController().obs;
  final referenceLinkController = TextEditingController().obs;
  bool isMsgPostEdit = false;
  String? postId;

  ///ADD MESSAGE POST...
  Future<void> editMsgPostController({
    required Map<String, dynamic>? bodyReq,
  }) async {
    try {
      ResponseModel responseModel = isMsgPostEdit
          ? await PostRepo().updatePostRepo(
              postId: postId,
              bodyReq: bodyReq,
              isMultiPartPost: true,
            )
          : await PostRepo().addPostRepo(
              bodyReq: bodyReq,
              isMultiPartPost: true,
            );
      final data = responseModel.response?.data;
      clearData();
      if (responseModel.isSuccess) {
        isMsgPostEdit = false;
        commonSnackBar(message: data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        addPostMessage.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      addPostMessage.value = ApiResponse.error('error');
    }
  }

  ///ADD MESSAGE POST...
  Future<void> addMsgPostControllerNew({
    required dioObj.FormData bodyReq,
  }) async {
    try {
      ResponseModel responseModel = await PostRepo().addPostNewRepo(
        formData: bodyReq,
        isMultiPartPost: true,
      );
      final data = responseModel.response?.data;
      clearData();
      if (responseModel.isSuccess) {
        commonSnackBar(message: data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        addPostMessage.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      addPostMessage.value = ApiResponse.error('error');
    }
  }

  ///RePost  MESSAGE POST...
  Future<void> rePostMsgPostControllerNew({
    required dioObj.FormData bodyReq,
  }) async {
    try {
      ResponseModel responseModel = await PostRepo().addPostNewRepo(
        formData: bodyReq,
        isMultiPartPost: true,
      );
      final data = responseModel.response?.data;
      clearRepostData();
      if (responseModel.isSuccess) {
        commonSnackBar(message: data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        addPostMessage.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      addPostMessage.value = ApiResponse.error('error');
    }
  }

  clearData() {
    postTextDataController.value.clear();
    descriptionMessage.value.clear();
    referenceLinkController.value.clear();
    messageText.value = "";
    postText.value = "";
    isAddLink.value = false;
    Get.find<TagUserController>().clearAllSelections();
    Get.find<TagUserController>().selectedUsers.clear();
  }

  clearRepostData() {
    descriptionMessage.value.clear();
    messageText.value = "";
    postText.value = "";
  }



  void removePhoto(int index) {
    if (index >= 0 && index < imagesList.length) {
      imagesList.removeAt(index);
    }
  }

  final Rx<PhotoPost> photoPost = PhotoPost(photoUrls: []).obs;

  ///new code
  final ImagePicker picker = ImagePicker();

  // Store up to 5 images
  // RxList<MessagePostImageModel> imagesList = <MessagePostImageModel>[].obs;
  RxList<String> uploadImageList = <String>[].obs;
  RxList<File> imagesList = <File>[].obs;
  Rx<MediaType>? selectedType;

  void removeMedia(int index) {
      imagesList.removeAt(index);
      if (imagesList.isEmpty) selectedType = null;
  }
  // 🟢 PICK MEDIA (image or video)
  Future<void> pickMedia() async {
    FileType fileType = FileType.media;
    if (selectedType?.value == MediaType.image) fileType = FileType.image;
    // if (_selectedType == MediaType.video) fileType = FileType.video;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: selectedType?.value == MediaType.image,
      type: fileType,
    );

    if (result == null) return;

    final files = result.paths.map((e) => File(e!)).toList();
    final firstExt = files.first.path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(firstExt);

    // setState(() {
    if (selectedType?.value == null) {
      selectedType?.value = isVideo ? MediaType.video : MediaType.image;
    }

    if (selectedType?.value == MediaType.video) {
      imagesList.value = [files.first];
      _generateThumbnail(files.first); // <-- Add for video
    } else {
      imagesList.addAll(files);
    }
    // });
  }
   RxMap videoThumbnails = {}.obs; // videoPath -> thumbnail file

  Future<void> _generateThumbnail(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 400,
      quality: 80,
    );

    if (thumbPath != null) {
        videoThumbnails[videoFile.path] = File(thumbPath);
    }
  }

  // Aspect ratio (default Square 1:1)

  // Future<void> pickImageFrom(BuildContext context) async {
  //   if (imagesList.length >= 4) {
  //     commonSnackBar(message: "Limit Reached You can select max 4 images");
  //     return;
  //   }
  //   // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   final croppedPath = await SelectProfilePictureDialog.pickFromGallery(
  //     context,
  //     cropAspectRatio:  CropAspectRatio(width:300, height: 300),
  //   );
  //   // XFile image=XFile(pickedFile?.path??"");
  //   if (croppedPath?.isNotEmpty??false) {
  //     imagesList.add(MessagePostImageModel(
  //         id: 0, imageFile: XFile(croppedPath??""), imgCropMode: AppConstants.Landscape));
  //   }
  // }

}

class MessagePostImageModel {
  final int? id;
  final XFile? imageFile;
  final String? imgWidth;
  final String? imgHeight;
  final String? imgCropMode;

  MessagePostImageModel({
    required this.id,
    required this.imageFile,
    this.imgWidth,
    this.imgHeight,
    this.imgCropMode,
  });
}
