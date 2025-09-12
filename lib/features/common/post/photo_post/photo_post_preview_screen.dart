import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/widget/tag_user_screen.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoPostPreviewScreen extends StatelessWidget {
  final PostVia? postVia;

  PhotoPostPreviewScreen({Key? key, this.postVia}) : super(key: key);

  final controller = Get.find<PhotoPostController>();
  final tagUserController = Get.find<TagUserController>();

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
              padding: EdgeInsets.all(
                SizeConfig.size16,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadedPhotosSection(),
                  SizedBox(height: SizeConfig.size16),
                  _buildDescriptionSection(),
                  SizedBox(height: SizeConfig.size16),
                  _buildTagPeopleSection(),
                  // _buildAddSongSection(),
                  // SizedBox(height: SizeConfig.size5),
                  _buildSymbolDurationSection(),
                  SizedBox(height: SizeConfig.size15),
                  _buildNatureOfPostSection(),
                  SizedBox(height: SizeConfig.size32),
                  _buildPreviewButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedPhotosSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText('Upload Photos',
                    fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
                InkWell(
                    onTap: () => Get.back(),
                    child: LocalAssets(imagePath: AppIconAssets.pen_line))
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(SizeConfig.size1),
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
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(controller.selectedPhotos[index]),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            SizedBox(height: SizeConfig.size8),
          ],
        ));
  }

  Widget _buildDescriptionSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText('Description of Message',
                fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
            SizedBox(height: SizeConfig.size10),
            Container(
              width: Get.width,
              padding: EdgeInsets.all(SizeConfig.size14),
              decoration: AppShadows.shadowDecoration,
              child: CustomText(
                controller.description.value.isNotEmpty
                    ? controller.description.value
                    : "N/A",
              ),
            ),
          ],
        ));
  }

  Widget _buildNatureOfPostSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText('Nature of Post',
                fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
            SizedBox(height: SizeConfig.size10),
            Container(
              width: Get.width,
              padding: EdgeInsets.all(SizeConfig.size14),
              decoration: AppShadows.shadowDecoration,
              child: CustomText(
                controller.natureOfPost.value.isNotEmpty
                    ? controller.natureOfPost.value
                    : "N/A",
              ),
            ),
          ],
        ));
  }

  Widget _buildTagPeopleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Tag People / Organization button
        GestureDetector(
          // onTap: () async {
          //   await Get.to(() => TagUserScreen());
          //   // The result will be handled by the TagUserController
          // },
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
        Obx(() => tagUserController.selectedUsers.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: SizeConfig.size16),
                child: Wrap(
                  children: tagUserController.selectedUsers
                      .map((user) => UserChip(
                            user: user,
                            onRemove: () {
                                  // tagUserController.removeSelectedUser(user);
                            },
                          ))
                      .toList(),
                ),
              )
            : Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: CustomText(
              "N/A"
          ),
         ),
        ),

        SizedBox(height: SizeConfig.size15),
      ],
    );
  }

  Widget _buildAddSongSection(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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

        // Selected users chips
        Obx(() => (controller.songData.value?.name != null)
            ? Padding(
            padding: EdgeInsets.only(top: SizeConfig.size15),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [controller.songData.value?.name].map((item) {
                return Chip(
                  label: Text(item??''),
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
                  onDeleted: (){},
                  labelPadding: const EdgeInsets.only(left: 12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ removes min constraints
                );
              }).toList(),
            ))
            : Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
              child: CustomText(
              "N/A"
              ),
            )
         ),

        SizedBox(height: SizeConfig.size15),
      ],
    );
  }

  Widget _buildSymbolDurationSection() {
    final selected = controller.selectedSymbol.value;

    String label = "";
    if (selected == SymbolDuration.hours24) label = "24 hours";
    if (selected == SymbolDuration.days7) label = "7 days";

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(label,
                color: AppColors.black,
                fontWeight: FontWeight.w400,
                fontSize: SizeConfig.large),
            Checkbox(
              value: true,
              onChanged: null,
              activeColor: AppColors.primaryColor,
              checkColor: AppColors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewButton() {
    return PositiveCustomBtn(
        onTap: () {
          Get.toNamed(
              RouteHelper.getPhotoPostReviewScreenRoute(),
              arguments: {ApiKeys.argPostVia: postVia}
          );
        },
        title: "Continue");
  }
}
