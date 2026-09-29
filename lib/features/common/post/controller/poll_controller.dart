import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// State and actions for creating or editing a poll post, shared by
/// PollInputScreen and PollReviewScreen. Registered by PollBinding.
class PollController extends GetxController {
  PollController({required PostRepo repo, Post? editPost, this.postVia})
      : _repo = repo,
        _editPost = editPost;

  final PostRepo _repo;
  final Post? _editPost;
  final PostVia? postVia;

  final questionController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxList<TextEditingController> optionControllers =
      <TextEditingController>[].obs;
  final RxList<String> options = <String>[].obs;
  final RxInt correctAnswerIndex = (-1).obs;
  final RxBool isLoading = false.obs;

  bool get isEdit => _editPost != null;

  bool get canAddOption => !isEdit && optionControllers.length < 4;

  bool get canRemoveOption => !isEdit && optionControllers.length > 2;

  bool get needsCorrectAnswer => !isEdit && correctAnswerIndex.value == -1;

  @override
  void onInit() {
    super.onInit();
    final post = _editPost;
    if (post != null) {
      descriptionController.text = post.subTitle ?? "";
      questionController.text = post.poll?.question ?? "";
      for (final option in post.poll?.options ?? []) {
        optionControllers.add(TextEditingController(text: option.text));
      }
    } else {
      addOption();
      addOption();
    }
  }

  @override
  void onClose() {
    questionController.dispose();
    descriptionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  void addOption() {
    if (optionControllers.length < 4) {
      optionControllers.add(TextEditingController());
    }
  }

  void removeOption(int index) {
    if (optionControllers.length > 2) {
      optionControllers[index].dispose();
      optionControllers.removeAt(index);
    }
  }

  /// Collects the non-empty options and returns the message to show if the
  /// question step is incomplete, or null when the user can move on to review.
  String? validateQuestion() {
    _syncOptions();
    // The options may have changed since the last review, so the answer
    // is picked again there.
    correctAnswerIndex.value = -1;
    if (questionController.text.trim().isEmpty) return AppStrings.fillQuestion;
    if (options.length < 2) return AppStrings.fillTwoOptions;
    return null;
  }

  /// Creates the poll, or updates the description of the one being edited.
  /// Returns true when the post was saved.
  Future<bool> submit() async {
    if (isLoading.value) return false;
    isLoading.value = true;
    try {
      final params = await _buildParams();
      final ResponseModel response = isEdit
          ? await _repo.updatePostRepo(
              postId: _editPost?.id ?? "",
              bodyReq: params,
              isMultiPartPost: true)
          : await _repo.addPostRepo(bodyReq: params, isMultiPartPost: false);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.response?.data?['message'] ??
                AppStrings.somethingWentWrong);
        return false;
      }
      // Same branch handles a create and an edit — only the create is a new
      // post, so the edit is reported separately rather than double-counted.
      // Mirrors photo_post_controller.
      AnalyticsService.I.log(
        isEdit ? 'post_edited' : 'post_created',
        AnalyticsService.params({'post_type': AppConstants.POLL_POST}),
      );
      commonSnackBar(
        message:
            response.response?.data?['message'] ?? "Poll posted successfully",
      );
      return true;
    } catch (e) {
      logs("ERROR ${e.toString()}");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _syncOptions() {
    options.value = optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _buildParams() async {
    final position = await getCurrentLocation();
    final description = descriptionController.text.trim();
    final location = {
      if (position != null) ApiKeys.latitude: position.latitude.toString(),
      if (position != null) ApiKeys.longitude: position.longitude.toString(),
    };

    // Only the description can change on an existing poll.
    if (isEdit) {
      return {
        ApiKeys.type: AppConstants.POLL_POST,
        ApiKeys.sub_title: description,
        ...location,
      };
    }

    _syncOptions();
    final question = questionController.text.trim();
    return {
      ApiKeys.type: AppConstants.POLL_POST,
      ApiKeys.postVia: postVia?.name,
      ApiKeys.poll: {
        ApiKeys.question: question.isNotEmpty ? question : "No Question",
        ApiKeys.options: [
          for (final (index, text) in options.indexed)
            {'text': text, 'isCorrect': index == correctAnswerIndex.value},
        ],
      },
      if (description.isNotEmpty) ApiKeys.sub_title: description,
      ...location,
    };
  }
}
