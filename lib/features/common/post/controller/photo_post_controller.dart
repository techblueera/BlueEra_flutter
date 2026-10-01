import 'package:BlueEra/core/services/lost_media_recovery.dart';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/photo_post_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/models/song_model.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BlueEra/core/constants/debug_log.dart';

enum SymbolDuration { hours24, days7 }

/// State and actions for creating or editing a photo (symbol) post, shared by
/// the photo post screens. Registered by PhotoPostBinding.
class PhotoPostController extends GetxController {
  PhotoPostController(
      {required PostRepo repo,
      required TagUserController tagUsers,
      this.editPost,
      this.postVia})
      : _repo = repo,
        _tagUsers = tagUsers;

  final PostRepo _repo;
  final TagUserController _tagUsers;
  final Post? editPost;
  final PostVia? postVia;

  bool get isPhotoPostEdit => editPost != null;

  TextEditingController descriptionTextEdit = TextEditingController();
  TextEditingController natureOfPostTextEdit = TextEditingController();

  final SafeImagePicker _picker = SafeImagePicker();
  final Rx<PhotoPost> photoPost = PhotoPost(photoUrls: []).obs;
  RxList<String> selectedPhotos = <String>[].obs;
  RxList<File> selectedPhotoFiles = <File>[].obs;
  final RxList<String> taggedPeople = <String>[].obs;
  final RxString description = ''.obs;
  final RxString natureOfPost = ''.obs;
  final RxInt charCount = 0.obs;
  final RxBool isLoading = false.obs;
  final int maxCharCount = 140;
  final int maxPhotos = 5; // Updated to 5 as per requirement
  final int minPhotos = 1; // Minimum 1 photo required

  Rx<SymbolDuration> selectedSymbol = SymbolDuration.hours24.obs;
  Rx<SongModel?> songData = Rx<SongModel?>(null);

  @override
  void onInit() {
    super.onInit();
    final post = editPost;
    if (post == null) return;
    selectedPhotos.addAll(post.media ?? []);
    descriptionTextEdit.text = post.subTitle ?? "";
    natureOfPostTextEdit.text = post.natureOfPost ?? "";
    final song = post.song;
    if (song != null) {
      songData.value = SongModel(
          id: song.id,
          name: song.name,
          artist: song.artist,
          coverUrl: song.coverUrl);
    }
    selectedSymbol.value = post.visibilityDuration == 1
        ? SymbolDuration.hours24
        : SymbolDuration.days7;
  }

  @override
  void onClose() {
    descriptionTextEdit.dispose();
    natureOfPostTextEdit.dispose();
    super.onClose();
  }

  /// Picks and compresses more photos. Returns true when any were added, so
  /// the view can open the photo editor on them.
  Future<bool> addPhotos() async {
    // if (selectedPhotos.length >= maxPhotos) {
    //   commonSnackBar(
    //     message: 'You can only upload up to $maxPhotos photos',
    //   );
    //
    //   return;
    // }

    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isEmpty) return false;

    int totalImage = selectedPhotos.length + images.length;
    log('total images--> $totalImage');
    if (totalImage > maxPhotos) {
      commonSnackBar(
        message: 'You can only upload up to $maxPhotos photos',
      );

      return false;
    }

    for (final image in images) {
      if (totalImage > maxPhotos) break;

      final originalSize = await File(image.path).length();

      final compressedFile =
          await PhotoPickerService.compressImage(File(image.path));

      if (compressedFile != null) {
        final newSize = await compressedFile.length();

        // 📊 Calculate reduction
        final reductionBytes = originalSize - newSize;
        final reductionPercent =
            (reductionBytes / originalSize * 100).toStringAsFixed(2);

        debugLog(
          "✅ Image compressed successfully: "
          "${_formatBytes(originalSize)} → ${_formatBytes(newSize)} "
          "(${reductionPercent}% reduced)",
        );

        originalPhotos.add(compressedFile.path);
        selectedPhotos.add(compressedFile.path);
        selectedPhotoFiles.add(compressedFile);

        log('selected Photos -- ${selectedPhotos.length}');
      }
    }

    return true;
  }

  /// Helper to format bytes into KB/MB
  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (bytes.bitLength / 10).floor(); // log2(1024) ~ 10
    final size = bytes / (1 << (i * 10));
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
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

  void updateSong(SongModel song) {
    songData.value = song;
    updatePhotoPost();
  }

  removeSong() {
    songData.value = null;
    updatePhotoPost();
  }

  void updateSymbolOfPost(SymbolDuration symbol) {
    selectedSymbol.value = symbol;
    updatePhotoPost();
  }

  void updatePhotoPost() {
    photoPost.update((val) {
      val?.photoUrls = selectedPhotos;
      val?.description = description.value;
      val?.taggedPeople = taggedPeople;
      val?.natureOfPost = natureOfPost.value;
      val?.song = songData.value;
      val?.symbol = selectedSymbol.value;
    });
  }

  /// Creates the post, or updates the one being edited. Returns true when it
  /// was saved; the caller decides where to go next.
  Future<bool> submitPost() async {
    if (!isPhotoPostEdit &&
        (selectedPhotoFiles.isEmpty || selectedPhotoFiles.length < minPhotos)) {
      commonSnackBar(message: 'Please upload at least $minPhotos photo');
      return false;
    }

    final taggedUserIds =
        _tagUsers.selectedUsers.map((user) => user.id.toString()).join(',');
    try {
      isLoading.value = true;
      UploadProgressDialog.show(initialProgress: 0.01);

      final position = await getCurrentLocation();

      final ResponseModel response = isPhotoPostEdit
          ? await _repo.updatePostRepo(
              bodyReq: {
                ApiKeys.type: AppConstants.PHOTO_POST,
                ApiKeys.sub_title: description.value,
                ApiKeys.nature_of_post: natureOfPost.value,
                ApiKeys.tagged_users: taggedUserIds,
                ApiKeys.latitude: position?.latitude.toString(),
                ApiKeys.longitude: position?.longitude.toString(),
              },
              isMultiPartPost: true,
              postId: editPost?.id,
            )
          : await _repo.createPost(
              photoPost.value,
              selectedPhotoFiles,
              position?.latitude ?? 0,
              position?.longitude ?? 0,
              postVia,
              UploadProgressDialog.update,
              natureOfPost.value,
              songData.value,
              (selectedSymbol.value == SymbolDuration.hours24) ? "1" : "7",
              taggedUserIds,
            );
      UploadProgressDialog.close();

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.response?.data?['message'] ??
              'Failed to create post. Please try again.',
        );
        return false;
      }
      // Same branch handles a create and an edit — only the create is a new
      // post, so the edit is reported separately rather than double-counted.
      AnalyticsService.I.log(
        isPhotoPostEdit ? 'post_edited' : 'post_created',
        AnalyticsService.params({
          'post_type': AppConstants.PHOTO_POST,
          'nature_of_post': natureOfPost.value,
        }),
      );
      commonSnackBar(
        message: response.response?.data?['message'] ??
            'Your Symbol Post has been created!',
      );
      return true;
    } catch (e) {
      UploadProgressDialog.close();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  List<String> originalPhotos = [];

  /// Takes the photo editor's result. Null means the editor was dismissed
  /// without one (e.g. the system back gesture), so the photos stay as they
  /// were.
  void applyEditedPhotos(List<String>? editedPhotos) {
    if (editedPhotos == null) return;
    selectedPhotos.value = List<String>.from(editedPhotos);
    selectedPhotoFiles.value = editedPhotos.map((p) => File(p)).toList();
    updatePhotoPost();
  }
}
