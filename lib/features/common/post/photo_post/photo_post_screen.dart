import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/features/common/reel/controller/song_controller.dart';
import 'package:BlueEra/features/common/reel/models/song_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoPostScreen extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final PostVia? postVia;

  PhotoPostScreen({Key? key, this.post, required this.isEdit, this.postVia})
      : super(key: key);

  @override
  State<PhotoPostScreen> createState() => _PhotoPostScreenState();
}

class _PhotoPostScreenState extends State<PhotoPostScreen> {
  final controller = Get.put(PhotoPostController());
  final tagUserController = Get.put(TagUserController());
  final songController = Get.put(SongController());

  @override
  void initState() {
    controller.isPhotoPostEdit = widget.isEdit;
    logs("controller.isPhotoPostEdit==== ${controller.isPhotoPostEdit}");
    if (widget.isEdit) {
      controller.postData?.value = widget.post ?? Post(id: '');
      controller.selectedPhotos.addAll(widget.post?.media ?? []);
      controller.descriptionTextEdit.text = widget.post?.subTitle ?? "";
      controller.natureOfPostTextEdit.text = widget.post?.natureOfPost ?? "";

      if (widget.post?.song != null) {
        controller.songData.value = SongModel(
            id: widget.post?.song?.id??'',
            name: widget.post?.song?.name??'',
            artist: widget.post?.song?.artist??'',
            coverUrl: widget.post?.song?.coverUrl??''
        );
      }
      controller.selectedSymbol.value = widget.post?.visibilityDuration == 1
          ? SymbolDuration.hours24
          : SymbolDuration.days7;
    }
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<PhotoPostController>();
    Get.delete<TagUserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Photo Post',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.size16,
              left: SizeConfig.size16,
              right: SizeConfig.size16,
              bottom: kToolbarHeight,
            ),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText('Upload Photos',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w500),
                      if(!controller.isPhotoPostEdit)
                        Obx(() =>
                        controller.selectedPhotos.isNotEmpty
                            ? InkWell(
                          onTap: () => controller.updatePhotoAfterEditing(),
                          child: CustomText('Edit',
                              color: AppColors.primaryColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600),
                        )
                            : SizedBox())
                    ],
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _buildPhotoUploadSection(),
                  (!controller.isPhotoPostEdit)
                      ? _buildAddMoreButton()
                      : SizedBox(
                    height: SizeConfig.size15,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  _buildDescriptionSection(),
                  SizedBox(height: SizeConfig.size24),
                  _buildTagPeopleSection(),
                  // SizedBox(height: SizeConfig.size5),
                  // _buildAddSongSection(),
                  // SizedBox(height: SizeConfig.size5),
                  _buildSymbolDurationSection(),
                  SizedBox(height: SizeConfig.size15),
                  _buildNatureOfPostSection(),
                  SizedBox(height: SizeConfig.size32),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Obx(() {
      if (controller.selectedPhotos.isEmpty) {
        return InkWell(
          onTap: controller.addPhotos,
          child: Container(
            width: SizeConfig.screenWidth,
            height: SizeConfig.size50 + 2,
            decoration: BoxDecoration(
              color: AppColors.white, // White background
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
              border: Border.all(width: 1, color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.black_gallery),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    'Upload Photos',
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.large,
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(SizeConfig.size1),
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: controller.selectedPhotos.length,
          itemBuilder: (context, index) {
            if (controller.isPhotoPostEdit) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  controller.selectedPhotos[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(controller.selectedPhotos[index]),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Widget _buildAddMoreButton() {
    return Obx(() {
      if (controller.selectedPhotos.isNotEmpty &&
          controller.selectedPhotos.length < controller.maxPhotos) {
        return TextButton.icon(
          onPressed: controller.addPhotos,
          icon: LocalAssets(
            imagePath: AppIconAssets.addBlueIcon,
            imgColor: AppColors.primaryColor,
          ),
          label: CustomText(
            'Add More',
            color: AppColors.primaryColor,
            fontSize: SizeConfig.large,
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonTextField(
          textEditController: controller.descriptionTextEdit,
          title: 'Description of Message',
          onChange: controller.updateDescription,
          maxLine: 5,
          maxLength: controller.maxCharCount,
          hintText: 'Briefly describe your message...',
          isValidate: false,
        ),
        SizedBox(
          height: SizeConfig.size10,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Obx(() =>
              CustomText(
                '${controller.charCount}/${controller.maxCharCount}',
                color: AppColors.secondaryTextColor,
              )),
        ),
      ],
    );
  }

  Widget _buildTagPeopleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Tag People / Organization button
        GestureDetector(
          onTap: () async {
            await Get.to(() => TagUserScreen());
            // The result will be handled by the TagUserController
          },
          child: Row(
            children: [
              LocalAssets(
                imagePath: AppIconAssets.addBlueIcon,
                imgColor: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                'Add Tag People / Organization',
                color: AppColors.primaryColor,
                fontSize: SizeConfig.large,
              ),
            ],
          ),
        ),

        // Selected users chips
        Obx(() =>
        tagUserController.selectedUsers.isNotEmpty
            ? Padding(
          padding: EdgeInsets.only(top: SizeConfig.size16),
          child: Wrap(
            children: tagUserController.selectedUsers
                .map((user) =>
                UserChip(
                  user: user,
                  onRemove: () =>
                      tagUserController.removeSelectedUser(user),
                ))
                .toList(),
          ),
        )
            : const SizedBox.shrink()),

        SizedBox(height: SizeConfig.size15),
      ],
    );
  }

  Widget _buildAddSongSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (!controller.isPhotoPostEdit)
            ? GestureDetector(
          onTap: () async {
            if (controller.selectedPhotos.isNotEmpty) {
              if (controller.songData.value?.name == null) {
                final result = await Navigator.pushNamed(
                  context,
                  RouteHelper.getAllSongsScreenRoute(),
                  arguments: {
                    ApiKeys.filePath: controller.selectedPhotos,
                  },
                ) as SongModel?;

                if (result != null) {
                  controller.updateSong(result);
                }
              } else {
                commonSnackBar(
                    message: 'You can\'t add more than one song');
              }
            } else {
              commonSnackBar(
                  message: 'Please upload at least one photo to add song');
            }
          },
          child: Row(
            children: [
              LocalAssets(
                imagePath: AppIconAssets.addBlueIcon,
                imgColor: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                'Add Song',
                color: AppColors.primaryColor,
                fontSize: SizeConfig.large,
              ),
            ],
          ),
        )
            : (controller.songData.value?.name != null)
            ? CustomText('Song',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500
        ) : const SizedBox.shrink(),

        // Selected users chips
        Obx(() =>
        (controller.songData.value?.name != null)
            ? Padding(
            padding: EdgeInsets.only(top: SizeConfig.size15),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [controller.songData.value?.name].map((item) {
                return Chip(
                  label: Text(item ?? ''),
                  backgroundColor: AppColors.lightBlue,
                  labelStyle: TextStyle(
                      fontSize: SizeConfig.size14,
                      color: Colors.black87
                  ),
                  deleteIcon: const Icon(Icons.close,
                      size: 20, color: AppColors.mainTextColor),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(8.0)),
                  onDeleted: (!controller.isPhotoPostEdit) ? () {
                    controller.removeSong();
                  } : () {},
                  labelPadding: const EdgeInsets.only(left: 12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ))
            : const SizedBox.shrink()),

        SizedBox(height: SizeConfig.size15),
      ],
    );
  }

  Widget _buildSymbolDurationSection() {
    if (!controller.isPhotoPostEdit)
      return Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            CustomText(
              "How long should we show this symbol?",
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(
                      "1.  ",
                      color: AppColors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.large,
                    ),
                    CustomText(
                      "24 hours",
                      color: AppColors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.large,
                    ),
                  ],
                ),
                Checkbox(
                  value: controller.selectedSymbol.value ==
                      SymbolDuration.hours24,
                  onChanged: (_) =>
                      controller.updateSymbolOfPost(SymbolDuration.hours24),
                  activeColor: AppColors.primaryColor,
                  checkColor: AppColors.white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ],
            ),

            // 2. 7 days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText("2.  ",
                        color: AppColors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.large),
                    CustomText("7 days",
                        color: AppColors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.large),
                  ],
                ),
                Checkbox(
                    value: controller.selectedSymbol.value == SymbolDuration.days7,
                    onChanged: (_) =>  controller.updateSymbolOfPost(SymbolDuration.days7),
                    activeColor: AppColors.primaryColor,
                    checkColor: AppColors.white,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0))),
              ],
            ),

          ],
        );
      });
    else
      return Builder(
        builder: (_) {
          final selected = controller.selectedSymbol.value;
          String label = "";
          if (selected == SymbolDuration.hours24) label = "24 hours";
          if (selected == SymbolDuration.days7) label = "7 days";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "How long should we show this symbol?",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    label,
                    color: AppColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                  Checkbox(
                    value: true,
                    onChanged: null, // disabled
                    activeColor: AppColors.primaryColor,
                    checkColor: AppColors.white,
                  ),
                ],
              ),
            ],
          );
        },
      );

  }

  Widget _buildNatureOfPostSection() {
    return CommonTextField(
      textEditController: controller.natureOfPostTextEdit,
      title: 'Nature of Post (Optional)',
      onChange: controller.updateNatureOfPost,
      hintText: AppConstants.education,
      isValidate: false,
    );
  }

  Widget _buildContinueButton() {
    return PositiveCustomBtn(
        onTap: () {
          if (controller.selectedPhotos.isNotEmpty) {
            if (widget.isEdit) {
              controller.updateDescription(controller.descriptionTextEdit.text);
              controller
                  .updateNatureOfPost(controller.natureOfPostTextEdit.text);
            }
            Get.toNamed(RouteHelper.getPhotoPostPreviewScreenRoute(),
                arguments: {ApiKeys.argPostVia: widget.postVia});
          } else {
            commonSnackBar(message: 'Please upload at least one photo');
          }
        },
        title: "Continue");
  }
}
