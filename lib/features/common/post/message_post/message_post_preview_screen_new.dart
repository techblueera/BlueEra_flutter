import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_post_screen_new.dart';
import 'package:BlueEra/features/common/post/message_post/edit_photo_feed_widget.dart';
import 'package:BlueEra/features/common/post/message_post/insta_slider_network_widget.dart';
import 'package:BlueEra/features/common/post/message_post/insta_slider_widget.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/features/common/post/widget/return_to_feed.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:BlueEra/core/routes/safe_back.dart';

/// Previews a new message post, or edits an existing one. Uses the
/// MessagePostController of the route that started the flow (the create
/// screen, or this screen's own route when the feed opens it for an edit).
class MessagePostPreviewScreenNew extends StatefulWidget {
  const MessagePostPreviewScreenNew({Key? key}) : super(key: key);

  @override
  State<MessagePostPreviewScreenNew> createState() =>
      _MessagePostPreviewScreenNewState();
}

class _MessagePostPreviewScreenNewState
    extends State<MessagePostPreviewScreenNew> {
  final msgPostController = Get.find<MessagePostController>();
  final tagUserController = Get.find<TagUserController>();
  late String originalCaption;
  late bool hasChanges;

  // Video validation state — for new video posts we must confirm the trimmed
  // file can actually be opened by the platform player before allowing the
  // user to submit. Protects against ExoPlayer "Source error" crashes that
  // otherwise would only surface during upload/playback.
  bool _isVideoValidating = false;
  bool _isVideoReady = true;
  String? _videoError;
  Worker? _videoWorker;

  @override
  void initState() {
    // Store original caption for change detection
    originalCaption = msgPostController.editPost?.subTitle ?? "";
    hasChanges = false;
    super.initState();

    // Validate the trimmed/picked video once on entry, and again whenever the
    // user re-trims (imagesList mutates). Skipped in edit mode because the
    // existing post's media is a remote URL, not a local file.
    if (!msgPostController.isMsgPostEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateCurrentVideoIfNeeded();
      });
      _videoWorker = ever<List<File>>(msgPostController.imagesList, (_) {
        _validateCurrentVideoIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _videoWorker?.dispose();
    super.dispose();
  }

  Future<void> _validateCurrentVideoIfNeeded() async {
    if (!mounted) return;

    // Non-video posts are always considered ready.
    if (msgPostController.selectedType.value != MediaType.video) {
      setState(() {
        _isVideoValidating = false;
        _isVideoReady = true;
        _videoError = null;
      });
      return;
    }

    final file = msgPostController.imagesList.firstOrNull;
    if (file == null || !file.existsSync()) {
      setState(() {
        _isVideoValidating = false;
        _isVideoReady = false;
        _videoError =
            'Video file is missing. Please pick or re-trim the video.';
      });
      return;
    }

    setState(() {
      _isVideoValidating = true;
      _isVideoReady = false;
      _videoError = null;
    });

    final duration = await msgPostController.validateVideoFile(file);
    if (!mounted) return;
    if (duration != null) {
      setState(() {
        _isVideoValidating = false;
        _isVideoReady = true;
        _videoError = null;
      });
    } else {
      final msg =
          'Unable to play the trimmed video. Please re-trim or choose another video.';
      setState(() {
        _isVideoValidating = false;
        _isVideoReady = false;
        _videoError = msg;
      });
      commonSnackBar(message: msg, snackBackgroundColor: AppColors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (msgPostController.isLoading.value) {
          commonSnackBar(message: AppStrings.pleaseWaitProcessing);
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            return CommonBackAppBar(
              title: AppStrings.lekhPreview,
              isLeading: msgPostController.isLoading.value ? false : true,
              onBackTap: () {
                safeBack();
              },
            );
          }),
        ),
        body: SafeArea(
          child: Obx(() {
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size50),
                    child: Column(
                      children: [
                        Container(
                          width: Get.width,
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size15,
                              vertical: SizeConfig.size15),
                          margin: EdgeInsets.all(SizeConfig.size16),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ChannelProfileHeader(
                                      imageUrl: userProfileGlobal,
                                      title: isIndividualUser()
                                          ? userNameGlobal
                                          : isBusinessUser()
                                              ? businessOwnerNameGlobal
                                              : "",
                                      userName: isIndividualUser()
                                          ? userNameAtGlobal
                                          : businessOwnerNameGlobal,
                                      subtitle: isIndividualUser()
                                          ? userProfessionGlobal
                                          : businessNameGlobal,
                                    ),
                                  ),
                                  if (!msgPostController.isMsgPostEdit)
                                    GestureDetector(
                                      onTap: () {
                                        safeBack();
                                      },
                                      child: LocalAssets(
                                          imagePath:
                                              AppIconAssets.round_black_edit),
                                    ),
                                ],
                              ),
                              if (msgPostController
                                  .postTitleController.value.text.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.size15,
                                      right: SizeConfig.size15,
                                      top: SizeConfig.size5,
                                      bottom: SizeConfig.size5),
                                  child: CustomText(
                                    msgPostController
                                        .postTitleController.value.text,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.large,
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.size15,
                                    vertical: msgPostController
                                            .postTitleController
                                            .value
                                            .text
                                            .isEmpty
                                        ? SizeConfig.size10
                                        : 0),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      bottom: SizeConfig.size15),
                                  child: msgPostController.isMsgPostEdit
                                      ? CommonTextField(
                                          title: AppStrings.description,
                                          hintText:
                                              "Enter description (minimum 30 characters)",
                                          maxLength: 2000,
                                          isValidate: false,
                                          readOnly: false,
                                          maxLine: 3,
                                          textEditController: msgPostController
                                              .descriptionMessage.value,
                                          onChange: (value) {
                                            setState(() {
                                              hasChanges =
                                                  value != originalCaption;
                                            });
                                          },
                                        )
                                      : HighlightText(
                                          text: msgPostController
                                              .descriptionMessage.value.text),
                                ),
                              ),
                              if (msgPostController.referenceLinkController
                                  .value.text.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.size15,
                                      right: SizeConfig.size15,
                                      bottom: SizeConfig.size15),
                                  child: InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                          msgPostController
                                              .referenceLinkController
                                              .value
                                              .text);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                    child: CustomText(
                                      msgPostController
                                          .referenceLinkController.value.text,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),

                              if (msgPostController.imagesList.isNotEmpty &&
                                  !msgPostController.isMsgPostEdit)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size15),
                                  child: LocalMediaGrid(
                                    files: msgPostController.imagesList,
                                    isVideo:
                                        msgPostController.selectedType.value ==
                                            MediaType.video,
                                    videoThumbnails:
                                        msgPostController.videoThumbnails,
                                    onEditTap: (index) =>
                                        Get.off(() => PhotoListingWidget()),
                                    onTapMedia: (index) => openVideoPreview(
                                        msgPostController.imagesList[index]),
                                  ),
                                ),
                              if (msgPostController.isMsgPostEdit &&
                                  msgPostController.uploadImageList.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size15),
                                  child: InstaSliderNetwork(
                                    post: msgPostController.editPost,
                                  ),
                                ),
                              // Video validation status
                              if (!msgPostController.isMsgPostEdit &&
                                  msgPostController.selectedType.value ==
                                      MediaType.video &&
                                  (_isVideoValidating || _videoError != null))
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.size15,
                                      right: SizeConfig.size15,
                                      top: SizeConfig.size10),
                                  child: _isVideoValidating
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: SizeConfig.size16,
                                              height: SizeConfig.size16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            SizedBox(width: SizeConfig.size10),
                                            Expanded(
                                              child: CustomText(
                                                "Validating video, please wait...",
                                                color: AppColors.black,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: AppColors.red,
                                                size: SizeConfig.size20),
                                            SizedBox(width: SizeConfig.size10),
                                            Expanded(
                                              child: CustomText(
                                                _videoError ?? "",
                                                color: AppColors.red,
                                              ),
                                            ),
                                            SizedBox(width: SizeConfig.size10),
                                            GestureDetector(
                                              onTap:
                                                  _validateCurrentVideoIfNeeded,
                                              child: CustomText(
                                                "Retry",
                                                color: AppColors.primaryColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              // Selected users chips
                              Obx(
                                () => tagUserController.selectedUsers.isNotEmpty
                                    ? Padding(
                                        padding: EdgeInsets.only(
                                            top: SizeConfig.size16,
                                            left: SizeConfig.size15,
                                            right: SizeConfig.size15),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                children: tagUserController
                                                    .selectedUsers
                                                    .map((user) => UserChip(
                                                          user: user,
                                                          onRemove: () =>
                                                              tagUserController
                                                                  .removeSelectedUser(
                                                                      user),
                                                        ))
                                                    .toList(),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await Get.to(
                                                    () => TagUserScreen());
                                              },
                                              child: LocalAssets(
                                                  imagePath: AppIconAssets
                                                      .round_black_edit),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.only(
                                            top: SizeConfig.size15,
                                            left: SizeConfig.size15,
                                            right: SizeConfig.size15),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await Get.to(() => TagUserScreen());
                                          },
                                          child: AddLinkRow(
                                            title: AppStrings
                                                .addTagPeopleOrganization,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size15,
                              vertical: SizeConfig.size15),
                          margin: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size16),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              msgPostController.isMsgPostEdit
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          AppStrings.natureOfPost,
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.black,
                                        ),
                                        SizedBox(
                                          height: SizeConfig.size10,
                                        ),
                                        CustomText(msgPostController
                                                .natureOfPostController
                                                .value
                                                .text
                                                .isNotEmpty
                                            ? msgPostController
                                                .natureOfPostController
                                                .value
                                                .text
                                            : AppStrings.notAvailable.tr),
                                      ],
                                    )
                                  : IgnorePointer(
                                      ignoring: msgPostController
                                          .natureOfPostController
                                          .value
                                          .text
                                          .isNotEmpty,
                                      child: CommonTextField(
                                        title: AppStrings.natureOfPost,
                                        hintText: AppStrings.egFlower,
                                        maxLength: 50,
                                        isValidate: false,
                                        readOnly:
                                            msgPostController.isMsgPostEdit,
                                        textEditController: msgPostController
                                            .natureOfPostController.value,
                                      ),
                                    ),
                              SizedBox(height: SizeConfig.size30),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: PositiveCustomBtn(
                                      onTap: () {
                                        safeBack();
                                      },
                                      title: AppStrings.back,
                                      textColor: AppColors.primaryColor,
                                      bgColor: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.size16),
                                  Expanded(
                                    child: Builder(builder: (_) {
                                      // Block submit if a new video post is
                                      // still validating or failed validation
                                      // — prevents uploading a file the
                                      // platform player can't even open.
                                      final bool isNewVideoPost =
                                          !msgPostController.isMsgPostEdit &&
                                              msgPostController
                                                      .selectedType.value ==
                                                  MediaType.video;
                                      final bool videoBlocksSubmit =
                                          isNewVideoPost &&
                                              (_isVideoValidating ||
                                                  !_isVideoReady ||
                                                  _videoError != null);
                                      bool isUpdateEnabled =
                                          (msgPostController.isMsgPostEdit
                                                  ? hasChanges
                                                  : true) &&
                                              !videoBlocksSubmit;

                                      return PositiveCustomBtn(
                                        onTap: isUpdateEnabled
                                            ? () async {
                                                final error = msgPostController
                                                    .validateDescription();
                                                if (error != null) {
                                                  commonSnackBar(
                                                      message: error,
                                                      snackBackgroundColor:
                                                          AppColors.red);
                                                  return;
                                                }
                                                if (await msgPostController
                                                    .submit()) {
                                                  returnToFeedAfterPosting();
                                                }
                                              }
                                            : null,
                                        title: msgPostController.isMsgPostEdit
                                            ? AppStrings.postUpdate
                                            : AppStrings.postNow,
                                        bgColor: isUpdateEnabled
                                            ? AppColors.primaryColor
                                            : AppColors.primaryColor
                                                .withValues(alpha: 0.5),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (msgPostController.isLoading.value) CircularIndicator(),
              ],
            );
          }),
        ),
      ),
    );
  }
}
