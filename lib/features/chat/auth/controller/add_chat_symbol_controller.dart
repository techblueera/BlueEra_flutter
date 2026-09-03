import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/chat_media_storage_service.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/post/widget/video_trimmer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/contactListModel.dart';
import '../model/symbol_details_model.dart';
import '../model/symbol_interaction_model.dart';
import '../repo/chat_view_repo.dart';
import '../repo/symbol_repo.dart';

enum PostVisibility { public, private, custom }

class AddChatSymbolController extends GetxController {
  // Post type selection
  final ImagePicker picker = ImagePicker();
  RxList<File> imagesList = <File>[].obs;
  RxList<SymbolDetailsModel> mySymbols = <SymbolDetailsModel>[].obs;
  final SymbolRepo symbolRepo = SymbolRepo();
  Rx<SymbolPostType?> selectedSymbolPostType = Rx<SymbolPostType?>(null);
  RxMap<String, File> videoThumbnails = <String, File>{}.obs;


  /// Playback length of the selected video in seconds, or null when it hasn't
  /// been read yet / couldn't be determined. Sent as `media_duration` on
  /// create — the app is the only component that knows it, so omitting it
  /// makes the symbol render as 0:00 everywhere.
  Rxn<double> videoDurationSeconds = Rxn<double>();
  RxString selectedBgImage = ''.obs,
      selectedFontFamily = 'OpenSans'.obs,
      uploadMsgPostUrl = "".obs;
  RxDouble selectedFontSize = 16.0.obs;
  RxString selectedFontWeight = 'Medium'.obs;
  final List<String> fontWeightList = ["Medium", "Bold", "Large"];
  void changeFontFamily(String family) {
    selectedFontFamily.value = family;
  }

  void changeFontSize(double size) {
    selectedFontSize.value = size;
  }

  void changeFontWeight(String weight) {
    selectedFontWeight.value = weight;
  }

  final linkTextSymbolController = TextEditingController();
  final List<Map<String, String>> fontStyles = [
    {'name': 'Style', 'family': 'OpenSans'},
    {'name': 'Style', 'family': 'Arizonia'},
    {'name': 'Style', 'family': 'Artifika'},
    {'name': 'Style', 'family': 'AsapCondensed'},
  ];
  final List<double> fontSizeList = [
    16.0,
    18.0,
    20.0,
    22.0,
    24.0,
    26.0,
  ];
  FontWeight getFontWeight(String selectedFontWeight) {
    switch (selectedFontWeight) {
      // case "Small":
      //   return FontWeight.w200;

      case "Medium":
        return FontWeight.normal;

      case "Bold":
        return FontWeight.bold;

      case "Large":
        return FontWeight.w900;

      // case "Extra Large":
      //   return FontWeight.w900;

      default:
        return FontWeight.normal;
    }
  }

  /// WhatsApp-like background colors
  final List<Color> bgColors = [
    Color(0xFF25D366), // WhatsApp green
    Color(0xFF075E54), // Dark green
    Color(0xFF128C7E),
    Color(0xFF34B7F1), // Blue
    Color(0xFF1DA1F2),
    Color(0xFF9B59B6), // Purple
    Color(0xFFE74C3C), // Red
    Color(0xFFF39C12), // Orange
    Color(0xFF2C3E50), // Dark
    Colors.black,
  ];

  /// Selected background color
  Rx<Color> selectedBgColor = Color(0xFF25D366).obs;

  void changeBgColorRandom() {
    bgColors.shuffle();
    selectedBgColor.value = bgColors.first;
  }

  // For text post

  // Caption
  TextEditingController captionController = TextEditingController();

  // Tag users
  RxList<String?> taggedUsers = <String?>[].obs;
  RxList<String?> exceptContactList = <String?>[].obs;

  // Visibility
  Rx<PostVisibility> visibility = PostVisibility.public.obs;

  // Duration Days — defaults to 3 days; user can change it (1–7).
  RxInt selectedDays = 3.obs;
  RxString VideoUploadProgress = ''.obs;

  // Loading
  RxBool isPosting = false.obs;
  RxList<ExistingNotConnected> onTagSelectedList = <ExistingNotConnected>[].obs;
  RxList<ExistingNotConnected> onExceptContactSelectedList =
      <ExistingNotConnected>[].obs;

  // --- FUNCTIONS ---
  final RxBool showDurationSelector = false.obs;

  void toggleDurationSelector() {
    showDurationSelector.toggle();
  }

  void choosePostType(SymbolPostType? type) {
    imagesList.clear();
    videoDurationSeconds.value = null;
    linkTextSymbolController.clear();
    selectedSymbolPostType.value = type;
  }

  void setVisibility(PostVisibility v) {
    visibility.value = v;
  }

  void setDuration(int days) {
    if (days >= 1 && days <= 7) {
      selectedDays.value = days;
    }
  }

  void toggleTagUser(String user) {
    if (taggedUsers.contains(user)) {
      taggedUsers.remove(user);
    } else {
      taggedUsers.add(user);
    }
  }

  Future<void> pickMedia() async {
    // No storage/photo permission request here: picking runs through the
    // system picker (Android) / PHPicker (iOS), which grant access to the
    // selected items only. The app declares no READ_MEDIA_* permission.
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    final files = images.map((e) => File(e.path)).toList();
    choosePostType(SymbolPostType.image);
    imagesList.addAll(files);
    logs("imagesList    ${imagesList}");
  }

  Future<void> pickVideoMedia() async {
    final XFile? result = await picker.pickVideo(
      source: ImageSource.gallery, // 🎞️ opens gallery view
    );

    if (result == null) return;

    final path = result.path;

    final trimmedPath = await Get.to(() => VideoTrimmerPage(videoPath: path));

    if (trimmedPath != null) {
      print("✅ Trimmed Video Path: $trimmedPath");
      choosePostType(SymbolPostType.video);
      await setVideoFile(File(trimmedPath));
    }
    // <-- Add for video
  }

  /// Makes [videoFile] the selected video and refreshes everything derived
  /// from it. Trimming can happen again from the preview, so the thumbnail and
  /// duration are always re-read from the file that will actually be uploaded.
  Future<void> setVideoFile(File videoFile) async {
    imagesList.value = [videoFile];
    videoDurationSeconds.value = null;
    await Future.wait([
      _generateThumbnail(videoFile),
      _readAndStoreVideoDuration(videoFile),
    ]);
  }

  Future<void> _readAndStoreVideoDuration(File videoFile) async {
    final seconds = await readVideoDurationSeconds(videoFile);
    // Guard against a slow read landing after the user swapped/removed the
    // video — otherwise we'd attach one clip's length to another.
    if (imagesList.isEmpty || imagesList.first.path != videoFile.path) return;
    videoDurationSeconds.value = seconds;
  }

  void removeMedia(int index) {
    imagesList.removeAt(index);
    if (imagesList.isEmpty) videoDurationSeconds.value = null;
  }

  Future<void> _generateThumbnail(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 400,
      quality: 80,
    );

    videoThumbnails[videoFile.path] = File(thumbPath.path);
  }

  Future<GenerateUploadUlrModel?> generateUploadUrl(
      {required Map<String, dynamic> params,
      required List<File> listFile}) async {
    ResponseModel responseModel =
        await ChatViewRepo().generateUploadUrlsApi(params);
    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      final uploadModel = GenerateUploadUlrModel.fromJson(data);
      final files = uploadModel.files;
      if (files?.isEmpty ?? true) return null;

      // Parallel Uploads using Future.wait
      await Future.wait(List.generate(files!.length, (i) {
        final file = listFile[i];
        final url = files[i].uploadUrl ?? '';
        final type = files[i].fileType ?? '';
        return uploadFileToS3(file: file, fileType: type, preSignedUrl: url);
      }));
      return uploadModel;
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return null;
    }
  }

  Future<void> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChatViewRepo().uploadVideoToS3(
          onProgress: (double progress) {
            VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  bool itTextOrLinkPost() {
    return selectedSymbolPostType.value == SymbolPostType.text ||
        selectedSymbolPostType.value == SymbolPostType.link;
  }

  bool itMediaPost() {
    return selectedSymbolPostType.value == SymbolPostType.image ||
        selectedSymbolPostType.value == SymbolPostType.video;
  }

  Future<bool> createSymbol() async {
    /// A guest has no real profile to post the symbol under — validate before
    /// any upload work starts.
    if (isGuestActionBlocked(AppStrings.guestSymbolRestricted.tr)) return false;

    if (itTextOrLinkPost() && linkTextSymbolController.text.trim().isEmpty) {
      commonSnackBar(message: "Please enter some text");
      return false;
    }

    isPosting.value = true;
    try {
      final isVideoPost = selectedSymbolPostType.value == SymbolPostType.video;
      // The pick/trim flow normally reads this already; re-read here as a
      // fallback so a video never posts without its length.
      if (isVideoPost &&
          videoDurationSeconds.value == null &&
          imagesList.isNotEmpty) {
        await _readAndStoreVideoDuration(imagesList.first);
      }

      GenerateUploadUlrModel? MediaUploadRes;
      if (imagesList.isNotEmpty) {
        List<String?> fileNames = [];
        List<String?> fileTypes = [];
        Map<String, String?> fileInfo = getFileInfo(imagesList.first);
        fileNames.add(fileInfo['fileName']);
        fileTypes.add(fileInfo['mimeType']);

        final uploadParams = {
          ApiKeys.fileName: fileNames,
          ApiKeys.fileType: fileTypes,
        };
        MediaUploadRes =
            await generateUploadUrl(params: uploadParams, listFile: imagesList);
      }

      taggedUsers.value = onTagSelectedList.map((e) => e.id).toList();
      exceptContactList.value =
          onExceptContactSelectedList.map((e) => e.id).toList();
      Map<String, dynamic> params = {
        ApiKeys.type: selectedSymbolPostType.value == SymbolPostType.image
            ? "photo"
            : selectedSymbolPostType.value == SymbolPostType.video
                ? "video"
                : selectedSymbolPostType.value == SymbolPostType.text
                    ? "text"
                    : "embeddedUrl",
        ApiKeys.content: itTextOrLinkPost()
            ? linkTextSymbolController.text
            : MediaUploadRes?.files?.first.publicUrl,
        if (selectedSymbolPostType.value == SymbolPostType.text ||
            selectedSymbolPostType.value == SymbolPostType.link)
          ApiKeys.backgroundColor:
              "#${selectedBgColor.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}",
        if (selectedSymbolPostType.value == SymbolPostType.text)
          ApiKeys.fontFamily: selectedFontFamily.value,
        if (selectedSymbolPostType.value == SymbolPostType.text)
          ApiKeys.fontSize: selectedFontSize.value,
        if (selectedSymbolPostType.value == SymbolPostType.text)
          ApiKeys.fontWeight: "${selectedFontWeight.value}",
        // Video length in seconds. Ignored by the server for other types, so
        // it's only sent for video to keep the payload honest.
        if (isVideoPost && videoDurationSeconds.value != null)
          ApiKeys.media_duration: videoDurationSeconds.value,
        ApiKeys.caption: "${captionController.text}",
        ApiKeys.duration_days: selectedDays.value,
        ApiKeys.visibility: visibility.value == PostVisibility.public
            ? "public"
            : visibility.value == PostVisibility.private
                ? "private"
                : "custom ",
        if (visibility.value == PostVisibility.custom)
          ApiKeys.hidden_from: exceptContactList,
        if (taggedUsers.isNotEmpty) ApiKeys.tagged_users: taggedUsers
      };
      ResponseModel responseModel = await symbolRepo.createSymbol(params);

      if (responseModel.isSuccess) {
        Get.find<SymbolFeedController>().fetchSymbolFeed();
        commonSnackBar(message: "Symbol Added Successfully");
        await getSymbolsForPartUser(userId);
        clearData();
        Get.back();
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isPosting.value = false;
    }
  }

  Future<void> getSymbolsForPartUser(String userId) async {
    ResponseModel responseModel =
        await symbolRepo.getAllSymbolsSingleUser(userId);
    if (responseModel.isSuccess) {
      log("sjdckjslclkssdc ${responseModel.response?.data}");
      mySymbols.value = (responseModel.response?.data as List)
          .map((e) => SymbolDetailsModel.fromJson(e))
          .toList();
      _prefetchSymbolMedia(mySymbols);
    }
  }

  /// Fire-and-forget download of photo/video symbols into the local `Symbols/`
  /// folder so they render from disk on the next open.
  void _prefetchSymbolMedia(List<SymbolDetailsModel> symbols) {
    final idUrls = symbols
        .where((s) => (s.type == 'photo' || s.type == 'video'))
        .map((s) => MapEntry(s.id ?? '', s.content ?? ''));
    ChatMediaStorageService.prefetchSymbols(idUrls);
  }

  Future<List<SymbolDetailsModel>?> deleteSymbol(
      {required SymbolDetailsModel symbolData}) async {
    if (isGuestActionBlocked(AppStrings.guestSymbolDeleteRestricted.tr)) {
      return null;
    }

    ResponseModel responseModel =
        await symbolRepo.deleteSymbol(symbolData.id ?? '');
    if (responseModel.isSuccess) {
      mySymbols.remove(symbolData);
      return mySymbols;
    } else {
      return null;
    }
  }

  Future<List<SymbolDetailsModel>?> getSymbolsForOtherUser(
      String userId) async {
    ResponseModel responseModel =
        await symbolRepo.getAllSymbolsSingleUser(userId);
    if (responseModel.isSuccess) {
      final symbols = (responseModel.response?.data as List)
          .map((e) => SymbolDetailsModel.fromJson(e))
          .toList();
      _prefetchSymbolMedia(symbols);
      return symbols;
    } else {
      return null;
    }
  }

  void clearData() {
    selectedSymbolPostType.value = null;
    isPosting.value = false;
    captionController.clear();
    linkTextSymbolController.clear();
    imagesList.clear();
    videoDurationSeconds.value = null;
    selectedDays.value = 3;
  }

  RxList<SymbolLikeEntry> symbolLikes = <SymbolLikeEntry>[].obs;
  RxList<SymbolViewEntry> symbolViews = <SymbolViewEntry>[].obs;
  RxBool isLoadingLikes = false.obs;
  RxBool isLoadingViews = false.obs;

  Future<void> fetchSymbolLikes(String symbolId) async {
    isLoadingLikes.value = true;
    try {
      ResponseModel response = await symbolRepo.getSymbolLikes(symbolId);
      if (response.isSuccess) {
        final data = response.response?.data;
        final list = data is List ? data : (data is Map ? data['data'] ?? [] : []);
        symbolLikes.value = (list as List)
            .map((e) => SymbolLikeEntry.fromJson(e))
            .toList();
      }
    } catch (_) {}
    isLoadingLikes.value = false;
  }

  Future<void> fetchSymbolViews(String symbolId) async {
    isLoadingViews.value = true;
    try {
      ResponseModel response = await symbolRepo.getSymbolViews(symbolId);
      if (response.isSuccess) {
        final data = response.response?.data;
        final list = data is List ? data : (data is Map ? data['data'] ?? [] : []);
        symbolViews.value = (list as List)
            .map((e) => SymbolViewEntry.fromJson(e))
            .toList();
      }
    } catch (_) {}
    isLoadingViews.value = false;
  }

  Future<bool> toggleLikeSymbol(String symbolId, {required bool isLiked}) async {
    /// Returning false makes the caller revert its optimistic heart state.
    if (isGuestActionBlocked(AppStrings.guestLikeRestricted.tr)) return false;

    try {
      ResponseModel response;
      if (isLiked) {
        response = await symbolRepo.unlikeSymbol(symbolId);
      } else {
        response = await symbolRepo.likeSymbol(symbolId);
      }
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  Future<void> markViewed(String symbolId) async {
    /// A guest's view must not be recorded. Silent by design — this fires
    /// automatically as symbols are paged through, not on a user tap.
    if (isGuestUser()) return;

    try {
      await symbolRepo.markSymbolViewed(symbolId);
    } catch (_) {}
  }
}
