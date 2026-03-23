
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/post/widget/video_trimmer_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/contactListModel.dart';
import '../model/symbol_details_model.dart';
import '../repo/chat_view_repo.dart';
import '../repo/symbol_repo.dart';

enum PostType { image, video, text, link }

enum PostVisibility { public, private, custom }

class AddChatSymbolController extends GetxController {
  // Post type selection
  final ImagePicker picker = ImagePicker();
  RxList<File> imagesList = <File>[].obs;
  RxList<SymbolDetailsModel> mySymbols = <SymbolDetailsModel>[].obs;
  final SymbolRepo symbolRepo = SymbolRepo();
  Rx<PostType?> selectedPostType = Rx<PostType?>(null);
  RxMap<String, File> videoThumbnails = <String, File>{}.obs;
  RxString selectedBgImage = ''.obs,
      selectedFontFamily = 'OpenSans'.obs,
      uploadMsgPostUrl = "".obs;
  RxDouble selectedFontSize=16.0.obs;
  RxString selectedFontWeight='Medium'.obs;
  final List<String> fontWeightList=[
    "Medium","Bold","Large"
  ];
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
  final List<double> fontSizeList=[
    16.0,18.0,20.0,22.0,24.0,26.0,
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

  // Duration Days
  RxInt selectedDays = 1.obs;
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

  void choosePostType(PostType? type) {
    imagesList.clear();
    linkTextSymbolController.clear();
    selectedPostType.value = type;
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
    bool permissionGranted = false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // For Android 13+ (SDK 33)
      if (androidInfo.version.sdkInt >= 33) {
        // Use photos permission
        var status = await Permission.photos.request();
        permissionGranted = status.isGranted;
      }
      // For Android 11 (SDK 30) and below
      else {
        var status = await Permission.storage.request();
        permissionGranted = status.isGranted;
      }
    } else {
      // iOS logic
      permissionGranted = true;
    }

    if (permissionGranted) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      final files = images.map((e) => File(e.path)).toList();
      choosePostType(PostType.image);
      imagesList.addAll(files);
      logs("imagesList    ${imagesList}");
    } else {
      print("Permission denied");
    }
  }

  Future<void> pickVideoMedia() async {
    final XFile? result = await picker.pickVideo(
      source: ImageSource.gallery, // 🎞️ opens gallery view
    );

    if (result == null) return;

    final path = result.path;

    final trimmedPath = await Get.to(VideoTrimmerPage(videoPath: path));

    if (trimmedPath != null) {
      print("✅ Trimmed Video Path: $trimmedPath");
      // final files = result.paths.map((e) => File(e!)).toList();
      final videoTriFile = File(trimmedPath);
      choosePostType(PostType.video);

      imagesList.value = [videoTriFile];
      _generateThumbnail(videoTriFile);

      // Upload / Save / Play trimmed video here
    }
    // <-- Add for video
  }

  void removeMedia(int index) {
    selectedPostType.value = null;
    imagesList.removeAt(index);
    if (imagesList.isEmpty) selectedPostType.value = null;
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
    return selectedPostType.value == PostType.text ||
        selectedPostType.value == PostType.link;
  }

  bool itMediaPost() {
    return selectedPostType.value == PostType.image ||
        selectedPostType.value == PostType.video;
  }

  Future<bool> createSymbol() async {
    isPosting.value = true;
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
      ApiKeys.type: selectedPostType.value == PostType.image
          ? "photo"
          : selectedPostType.value == PostType.video
              ? "video"
              : selectedPostType.value == PostType.text
                  ? "text"
                  : "embeddedUrl",
      ApiKeys.content: itTextOrLinkPost()
          ? linkTextSymbolController.text
          : MediaUploadRes?.files?.first.publicUrl,
      if(selectedPostType.value == PostType.text||selectedPostType.value == PostType.link)
        ApiKeys.backgroundColor : "#${selectedBgColor.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}",
      if(selectedPostType.value == PostType.text)
        ApiKeys.fontFamily: selectedFontFamily.value,
      if(selectedPostType.value == PostType.text)
        ApiKeys.fontSize: selectedFontSize.value,
      if(selectedPostType.value == PostType.text)
        ApiKeys.fontWeight: "${selectedFontWeight.value}",
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
      isPosting.value = false;
      clearData();
      Get.back();
      return true;
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    }
  }
  Future<void> getSymbolsForPartUser(String userId)async{
    ResponseModel responseModel = await symbolRepo.getAllSymbolsSingleUser(userId);
    if(responseModel.isSuccess){
      mySymbols.value =
      (responseModel.response?.data as List)
          .map((e) => SymbolDetailsModel.fromJson(e))
          .toList();
    }

  }
  Future<List<SymbolDetailsModel>?> deleteSymbol({required SymbolDetailsModel symbolData})async{
    ResponseModel responseModel = await symbolRepo.deleteSymbol(symbolData.id??'');
    if(responseModel.isSuccess){
      mySymbols.remove(symbolData);
      return mySymbols;
    }else{
      return null;
    }

  }
  Future<List<SymbolDetailsModel>?> getSymbolsForOtherUser(String userId)async{
    ResponseModel responseModel = await symbolRepo.getAllSymbolsSingleUser(userId);
    if(responseModel.isSuccess){

      return (responseModel.response?.data as List)
          .map((e) => SymbolDetailsModel.fromJson(e))
          .toList();
    }else{
      return null;
    }

  }
  void clearData(){
   selectedPostType.value=null;
   isPosting.value=false;
   captionController.clear();
   linkTextSymbolController.clear();
   imagesList.clear();
  }
}
