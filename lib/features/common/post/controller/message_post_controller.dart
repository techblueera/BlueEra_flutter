import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/post/widget/video_trimmer_screen.dart';
import 'package:BlueEra/features/common/reel/models/generate_presigned_url.dart';
import 'package:BlueEra/features/common/reel/models/video_category_response.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dioObj;
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart' as htp;

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
  final imageTopicsTextEditControllar = TextEditingController().obs;
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
      logs("ERROR 89 ${e.toString()}");
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
      );
      final data = responseModel.response?.data;
      if (responseModel.isSuccess) {
        commonSnackBar(message: data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        addPostMessage.value = ApiResponse.complete(responseModel);
        clearData();

      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }

    } catch (e) {
      logs("ERROR 117 ${e.toString()}");
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
      logs("ERROR 145${e.toString()}");
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
  Rx<MediaType?> selectedType = Rx<MediaType?>(null);

  void removeMedia(int index) {
    imagesList.removeAt(index);
    if (imagesList.isEmpty) selectedType.value = null;
  }

  // 🟢 PICK MEDIA (image or video)
  Future<void> pickMedia() async {
    FileType fileType = FileType.image;
    // FileType fileType = FileType.media;
    // if (selectedType.value == MediaType.image)
    fileType = FileType.image;
    // if (selectedType.value == MediaType.video) fileType = FileType.video;

    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: fileType, compressionQuality: 80);

    if (result == null) return;

    final files = result.paths.map((e) => File(e!)).toList();

    selectedType.value = MediaType.image;

    imagesList.addAll(files);
  }

  Future<void> pickVideoMedia() async {
    selectedType.value = MediaType.video;

    // FilePickerResult? result = await ImagePicker.platform.(
    //     allowMultiple: false,
    //     type: FileType.custom,
    //     allowedExtensions: ['mp4', 'mov', 'avi', 'mkv']
    // );
    final XFile? result = await picker.pickVideo(
      source: ImageSource.gallery, // 🎞️ opens gallery view
    );

    if (result == null) return;

    if (result.path != null) {
      final path = result.path!;

      final trimmedPath = await Get.to(VideoTrimmerPage(videoPath: path));

      if (trimmedPath != null) {
        print("✅ Trimmed Video Path: $trimmedPath");
        // final files = result.paths.map((e) => File(e!)).toList();
        final videoTriFile = File(trimmedPath);

        selectedType.value = MediaType.video;

        imagesList.value = [videoTriFile];
        _generateThumbnail(videoTriFile);

        // Upload / Save / Play trimmed video here
      }
    }
    // <-- Add for video
  }

  /*Future<void> pickVideoMedia() async {

    selectedType.value = MediaType.video;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv']);

    if (result == null) return;

    final files = result.paths.map((e) => File(e!)).toList();


    selectedType.value = MediaType.video;

    imagesList.value = [files.first];
    _generateThumbnail(files.first); // <-- Add for video

  }*/

  RxMap<String, File> videoThumbnails = <String, File>{}.obs;

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
      videoThumbnails[videoFile.path] = File(thumbPath.path);
    }
  }

  Future<void> uploadMessagePost({required PostVia? postVia}) async {
    try {
    dio.FormData formData = dio.FormData();
    if (imagesList.length > 4) {
      commonSnackBar(message: "Max 4 image are allowed");
      return;
    }
    if (selectedType.value == MediaType.video) {
      double progress = 0.0;

      void updateProgress(double value) {
        progress = value.clamp(0.0, 1.0);
        UploadProgressDialog.update(progress);
      }

      // ✅ Show the dialog (GetX version, no context needed)
      UploadProgressDialog.show(initialProgress: progress);
      final videoFile = File(imagesList.firstOrNull?.path ?? "");
      final coverFile = File(videoThumbnails[videoFile.path]?.path ?? "");

      final videoInfo = getFileInfo(videoFile);
      final coverInfo = getFileInfo(coverFile);

      // 1. Init both uploads (20%)
      await Future.wait([
        uploadInit(
          queryParams: {
            ApiKeys.filenameKey: videoInfo['fileName'],
            ApiKeys.contentTypeKey: videoInfo['mimeType']
          },
          isVideoUpload: true,
        ),
        uploadInit(
          queryParams: {
            ApiKeys.filenameKey: coverInfo['fileName'],
            ApiKeys.contentTypeKey: coverInfo['mimeType']
          },
          isVideoUpload: false,
        ),
      ]);
      updateProgress(0.2);

      // 2. Upload files with combined progress (20% → 90%)
      double videoProgress = 0.0;
      double coverProgress = 0.0;

      void updateCombinedProgress() {
        // 20% init + 70% file uploads
        final combined = 0.2 + ((videoProgress + coverProgress) / 2) * 0.7;
        updateProgress(combined);
      }

      if (uploadInitVideoFile?.success ?? false) {
        await Future.wait([
          uploadFileToS3(
            file: videoFile,
            fileType: videoInfo['mimeType']!,
            preSignedUrl: uploadInitVideoFile?.data?.uploadUrl ?? "",
            onProgress: (total) {
              videoProgress = total;
              updateCombinedProgress();
            },
          ),
          uploadFileToS3(
            file: coverFile,
            fileType: coverInfo['mimeType']!,
            preSignedUrl: uploadInitCoverImageFile?.data?.uploadUrl ?? "",
            onProgress: (total) {
              coverProgress = total;
              updateCombinedProgress();
            },
          ),
        ]);
        formData.fields.add(MapEntry(ApiKeys.media_types, "video/mp4"));
        formData.fields.add(MapEntry(ApiKeys.thumbnail,
            uploadInitCoverImageFile?.data?.publicUrl ?? ""));

        formData.fields.add(MapEntry(
            ApiKeys.media, uploadInitVideoFile?.data?.publicUrl ?? ""));
      }
      final size = await getVideoDimensions(videoFile.path);
      print('Width: ${size?.width}, Height: ${size?.height}');
      formData.fields
          .add(MapEntry(ApiKeys.media_width, size?.width.toString() ?? ""));
      formData.fields
          .add(MapEntry(ApiKeys.media_height, size?.height.toString() ?? ""));
      updateProgress(0.9);
    }
    if ((uploadInitVideoFile?.success == false ||
            uploadInitVideoFile?.success == null) &&
        (selectedType.value == MediaType.video)) {
      return;
    }
    final position = await getCurrentLocation();
    final tagUserController = Get.find<TagUserController>();

    String? tagUserIds = tagUserController.selectedUsers
        .map((user) => user.id.toString())
        .join(',');
    if (selectedType.value == MediaType.image) {
      /// Add media files
      for (int i = 0; i < (imagesList.length); i++) {
        final data = imagesList[i];

        File processed = File(data.path);

        String fileName = processed.path.split('/').last;
        formData.files.add(
          MapEntry(
            ApiKeys.media,
            await dio.MultipartFile.fromFile(
              processed.path,
              filename: fileName,
            ),
          ),
        );
        formData.fields.add(MapEntry(ApiKeys.media_types, "image/jpeg"));
      }
      if (imagesList.length == 1) {
        final size =
            await getImageDimensions(File(imagesList.firstOrNull?.path ?? ""));
        print('Width: ${size.width}, Height: ${size.height}');
        formData.fields
            .add(MapEntry(ApiKeys.media_width, size.width.toString()));
        formData.fields
            .add(MapEntry(ApiKeys.media_height, size.height.toString()));
      }
    }

    ///POST VIA TYPE...
    formData.fields.add(MapEntry(ApiKeys.postVia, postVia?.name ?? "profile"));

    ///TITLE...
    if (postTitleController.value.text.isNotEmpty)
      formData.fields
          .add(MapEntry(ApiKeys.title, postTitleController.value.text));

    ///DESCRIPTION...
    if (postText.value.isNotEmpty)
      formData.fields
          .add(MapEntry(ApiKeys.sub_title, postText.value));

    ///NATURE OF POST...
    if (natureOfPostController.value.text.isNotEmpty)
      formData.fields.add(
          MapEntry(ApiKeys.nature_of_post, natureOfPostController.value.text));

    ///REFERENCE LINK...
    if (referenceLinkController.value.text.isNotEmpty)
      formData.fields.add(MapEntry(
        ApiKeys.reference_link,
        referenceLinkController.value.text.isNotEmpty
            ? referenceLinkController.value.text
            : "",
      ));

    /// Add location if available
    if (position?.latitude != null && position?.longitude != null) {
      formData.fields
          .add(MapEntry(ApiKeys.latitude, position?.latitude.toString() ?? ""));
      formData.fields.add(
          MapEntry(ApiKeys.longitude, position?.longitude.toString() ?? ""));
    }

    ///POST TYPE....
    formData.fields.add(MapEntry(ApiKeys.type, AppConstants.MESSAGE_POST));

    ///TAG IDS...
    if (tagUserIds.isNotEmpty)
      formData.fields.add(MapEntry(ApiKeys.tagged_users, tagUserIds));
    await addMsgPostControllerNew(
      bodyReq: formData,
    );
    } catch (e) {
      logs("errorr === $e");

      /// ❌ On error also close dialog
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      UploadProgressDialog.close();
    }
  }

  ApiResponse uploadInitResponse = ApiResponse.initial('Initial');
  ApiResponse uploadFileToS3Response = ApiResponse.initial('Initial');
  GeneratePresignedUrl? uploadInitVideoFile;
  GeneratePresignedUrl? uploadInitCoverImageFile;

  Future<void> uploadInit(
      {required Map<String, dynamic> queryParams,
      required bool isVideoUpload}) async {
    // try {
      ResponseModel? response = await PostRepo().uploadMessagePostVideoRepo(
        queryParams: queryParams,
      );

      if (response?.isSuccess ?? false) {
        uploadInitResponse = ApiResponse.complete(response);
        final uploadInit =
            GeneratePresignedUrl.fromJson(response?.response?.data);
        if (isVideoUpload) {
          uploadInitVideoFile = uploadInit;
        } else {
          uploadInitCoverImageFile = uploadInit;
        }
      } else {
        uploadInitResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    // } catch (e) {
    //   uploadInitResponse = ApiResponse.error('error');
    //   commonSnackBar(message: AppStrings.somethingWentWrong);
    // }
  }

  Future<void> uploadFileToS3({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      ResponseModel? response = await PostRepo().uploadMessagePostVideoRepoToS3(
          onProgress: onProgress,
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  // Dropdown Values
  RxString selectedLanguage = ''.obs;
  RxString selectedEmotion = ''.obs;
  RxString topicDescriptionText = ''.obs;
  Rx<VideoCategoryData?> selectedNatureOfPost = Rx<VideoCategoryData?>(null);

  // Lists
  late final languages = SUPPORTED_LANGUAGES;
  late final emotions = SUPPORTED_EMOTIONS;
  RxList<VideoCategoryData> natureOfPostList =
      <VideoCategoryData>[].obs; // You already have this list
  // var suggestions = <String>[].obs;

  // RxString selectedSuggestion = ''.obs;
  RxBool isGenerated = false.obs; // <--- NEW

  Future<void> generateSocialMediaContent() async {
    try {
      isGenerated.value = true; // <--- Disable button after API call
      suggestions.clear();

      // prepare images multipart
      List<dio.MultipartFile> imageByPart = [];
      // Limit to first 3 images if there are more
      final limitedImages =
          imagesList.length > 3 ? imagesList.take(3).toList() : imagesList;

      for (final imageData in limitedImages) {
        final path = imageData.path;
        final imageInfo = getFileInfo(File(path));
        final isVideo = selectedType.value == MediaType.video;

        ///IF VIDEO IS THERE THEN SEND VIDEO THUMBNAIL INSTEAD OF VIDE FILE FOR GENERATE VIDEO AI DESCRIPTION....
        if (isVideo) {
          final file = imagesList.first;
          final thumb = videoThumbnails[file.path];
          final fileName = thumb?.path.split('/').last;
          final imageInfo = getFileInfo(File(thumb?.path ?? ""));
          final mimeType = imageInfo['mimeType'];

          imageByPart.add(await dio.MultipartFile.fromFile(
            thumb?.path ?? "",
            filename: fileName,
            contentType:
                htp.MediaType.parse(mimeType ?? 'application/octet-stream'),
          ));
        } else {
          final mimeType = imageInfo['mimeType'];
          final fileName = path.split('/').last;
          imageByPart.add(await dio.MultipartFile.fromFile(
            path,
            filename: fileName,
            contentType:
                htp.MediaType.parse(mimeType ?? 'application/octet-stream'),
          ));
        }
      }
      Map<String, dynamic> reqParm = {
        ApiKeys.language: selectedLanguage.value,
        ApiKeys.emotion: selectedEmotion.value,
        ApiKeys.image_topic: imageTopicsTextEditControllar.value.text,
        ApiKeys.images: imageByPart,
      };
      ResponseModel responseModel =
          await PostRepo().aiSocialPostGenerateRepo(queryParam: reqParm);
      if (responseModel.isSuccess) {
        setSuggestions(responseModel.response?.data);
      }
    } catch (e) {
      logs("ERROR 593$e");
    }
  }

  var suggestions = <String>[].obs;
  var selectedSuggestion = "".obs;

  void setSuggestions(dynamic json) {
    final data = json["post_suggestions"] as List<dynamic>;

    suggestions.value = data.map((inner) {
      return (inner as List<dynamic>).join("\n"); // join lines as paragraph
    }).toList();

    selectedSuggestion.value = ""; // reset selection
  }

  // Call this whenever any selection changes
  void onSelectionChanged() {
    isGenerated.value = false; // Re-enable button
  }

  bool get isFormValid =>
      selectedLanguage.value.isNotEmpty &&
      selectedEmotion.value.isNotEmpty &&
      topicDescriptionText.value.isNotEmpty &&
      !isGenerated.value; // <--- disable when generated
}
