import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_post_screen_new.dart';
import 'package:BlueEra/features/common/post/message_post/edit_photo_feed_widget.dart';
import 'package:BlueEra/features/common/post/message_post/insta_slider_network_widget.dart';
import 'package:BlueEra/features/common/post/message_post/insta_slider_widget.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagePostPreviewScreenNew extends StatefulWidget {
  final PostVia? postVia;
  final Post? post;
  final bool isEdit;

  MessagePostPreviewScreenNew(
      {Key? key, this.postVia, this.post, required this.isEdit})
      : super(key: key);

  @override
  State<MessagePostPreviewScreenNew> createState() =>
      _MessagePostPreviewScreenNewState();
}

class _MessagePostPreviewScreenNewState
    extends State<MessagePostPreviewScreenNew> {
  late MessagePostController msgPostController;
  late TagUserController tagUserController;

  @override
  void initState() {
    if (Get.isRegistered<MessagePostController>()) {
      msgPostController = Get.find<MessagePostController>();
    } else {
      msgPostController = Get.put(MessagePostController());
    }
    msgPostController.taggedSelectedUsersList?.value =
        widget.post?.taggedUsers ?? [];
    msgPostController.isMsgPostEdit = widget.isEdit;

    if (Get.isRegistered<TagUserController>()) {
      tagUserController = Get.find<TagUserController>();
    } else {
      tagUserController = Get.put(TagUserController());
    }
    // TODO: implement initState

    if (widget.isEdit) {
      widget.post?.media?.forEach((action) {
        msgPostController.uploadImageList.add(action);
      });

      msgPostController.postId = widget.post?.id ?? "";
      msgPostController.postText.value = widget.post?.message ?? "";
      msgPostController.postTextDataController.value.text =
          widget.post?.message ?? "";
      msgPostController.descriptionMessage.value.text =
          widget.post?.subTitle ?? "";

      msgPostController.natureOfPostController.value.text =
          widget.post?.natureOfPost ?? "";

      if (widget.post?.referenceLink?.isNotEmpty ?? false) {
        msgPostController.isAddLink.value = true;
        msgPostController.referenceLinkController.value.text =
            widget.post?.referenceLink ?? "";
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (msgPostController.isLoading.value) {
          commonSnackBar(message: AppStrings.pleaseWaitProcessing);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            return CommonBackAppBar(
              title: AppStrings.lekhPreview,
              isLeading: msgPostController.isLoading.value ? false : true,
              onBackTap: () {
                Get.back();
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
                                        Get.back();
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
                                      left: SizeConfig.size50,
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
                                padding: EdgeInsets.only(
                                    left: SizeConfig.size50,
                                    top: msgPostController.postTitleController
                                            .value.text.isEmpty
                                        ? SizeConfig.size10
                                        : 0,
                                    bottom: SizeConfig.size15),
                                child: HighlightText(
                                    text: msgPostController
                                        .descriptionMessage.value.text),
                              ),
                              if (msgPostController.referenceLinkController
                                  .value.text.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                      // top: SizeConfig.size5,
                                      left: SizeConfig.size50,
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

                              if (msgPostController.imagesList.isNotEmpty)
                                // InstaSlider(),
                                LocalMediaGrid(
                                  files: msgPostController.imagesList,
                                  isVideo:
                                      msgPostController.selectedType.value ==
                                          MediaType.video,
                                  videoThumbnails:
                                      msgPostController.videoThumbnails,
                                  onEditTap: (index) =>
                                      Get.off(PhotoListingWidget()),
                                  onTapMedia: (index) => openVideoPreview(
                                      msgPostController.imagesList[index]),
                                ),
                              if (msgPostController.isMsgPostEdit &&
                                  msgPostController.uploadImageList.isNotEmpty)
                                InstaSliderNetwork(
                                  post: widget.post,
                                ),
                              // Selected users chips
                              Obx(
                                () => tagUserController.selectedUsers.isNotEmpty
                                    ? Padding(
                                        padding: EdgeInsets.only(
                                            top: SizeConfig.size16),
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
                                                // Get.back();
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
                                            top: SizeConfig.size15),
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
                              IgnorePointer(
                                ignoring: true,
                                child: msgPostController.isMsgPostEdit
                                    ? Column(
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
                                    : CommonTextField(
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
                                        Get.back();
                                      },
                                      title: AppStrings.back,
                                      textColor: AppColors.primaryColor,
                                      bgColor: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.size16),
                                  Expanded(
                                    child: PositiveCustomBtn(
                                      onTap: () async {
                                        try {
                                          String? tagUserIds = tagUserController
                                              .selectedUsers
                                              .map((user) => user.id.toString())
                                              .join(',');
                                          msgPostController.isLoading.value =
                                              true;

                                          dynamic reqData;

                                          if (msgPostController.isMsgPostEdit) {
                                            reqData = {
                                              ApiKeys.type:
                                                  AppConstants.MESSAGE_POST,
                                              ApiKeys.tagged_users:
                                                  tagUserIds.isNotEmpty
                                                      ? tagUserIds
                                                      : ""
                                            };
                                            await msgPostController
                                                .editMsgPostController(
                                              bodyReq: reqData,
                                            );
                                          } else {
                                            await msgPostController
                                                .uploadMessagePost(
                                                    postVia: widget.postVia);
                                          }

                                          msgPostController.isLoading.value =
                                              false;
                                        } on Exception catch (e) {
                                          logs("ERRO ${e}");
                                          msgPostController.isLoading.value =
                                              false;

                                          // TODO
                                        }
                                      },
                                      title: msgPostController.isMsgPostEdit
                                          ? AppStrings.postUpdate
                                          : AppStrings.postNow,
                                    ),
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
