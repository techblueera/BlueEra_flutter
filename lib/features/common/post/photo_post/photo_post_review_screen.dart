import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoPostReviewScreen extends StatelessWidget {
  final PostVia? postVia;

  PhotoPostReviewScreen({Key? key, this.postVia}) : super(key: key);

  final controller = Get.find<PhotoPostController>();
  final tagUserController = Get.find<TagUserController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Photo Post',
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      _buildUploadedPhotosSection(),
                      SizedBox(height: SizeConfig.size16),
                      _buildDescriptionSection(),
                      SizedBox(height: SizeConfig.size16),
                      _buildTagPeopleSection(),

                      // _buildAddSongSection(),
                      // SizedBox(height: SizeConfig.size5),
                      // _buildSymbolDurationSection(),
                      // SizedBox(height: SizeConfig.size15),

                      _buildNatureOfPostSection(),
                      SizedBox(height: SizeConfig.size32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            )),
    );
  }

  Widget _buildUploadedPhotosSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText('Upload Photos',
                fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
            SizedBox(height: SizeConfig.size8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
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

  Widget _buildTagPeopleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Tag People / Organization button
        CustomText('Tag People / Organization',
            fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
        // Selected users chips
        Obx(() => tagUserController.selectedUsers.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: SizeConfig.size16),
                child: Wrap(
                  children: tagUserController.selectedUsers
                      .map((user) => UserChip(
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
        // Add Tag People / Organization button
        GestureDetector(
          onTap: ()  {
            Navigator.pushNamed(
              Get.context!,
              RouteHelper.getGetAllSongsScreenRoute(),
              arguments: {
                ApiKeys.videoPath: 'widget.videoPath',
              },
            ) as Map<String, dynamic>?;

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
        ),

        // Selected users chips
        Obx(() => tagUserController.selectedUsers.isNotEmpty
            ? Padding(
          padding: EdgeInsets.only(top: SizeConfig.size16),
          child: Wrap(
            children: tagUserController.selectedUsers
                .map((user) => UserChip(
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

  Widget _buildSymbolDurationSection() {
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

          // 1. 24 hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomText("1.  ",color: AppColors.black, fontWeight: FontWeight.w400,fontSize: SizeConfig.large),
                  CustomText("24 hours",
                      color: AppColors.black, fontWeight: FontWeight.w400,fontSize: SizeConfig.large
                  ),
                ],
              ),
              Checkbox(
                  value: controller.selected.value == SymbolDuration.hours24,
                  onChanged: (_) => controller.select(SymbolDuration.hours24),
                  activeColor: AppColors.primaryColor,
                  checkColor: AppColors.white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.0))
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 2. 7 days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomText("2.  ", color: AppColors.black, fontWeight: FontWeight.w400,fontSize: SizeConfig.large),
                  CustomText("7 days",
                      color: AppColors.black, fontWeight: FontWeight.w400,fontSize: SizeConfig.large
                  ),
                ],
              ),
              Checkbox(
                  value: controller.selected.value == SymbolDuration.days7,
                  onChanged: (_) => controller.select(SymbolDuration.days7),
                  activeColor: AppColors.primaryColor,
                  checkColor: AppColors.white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.0))
              ),
            ],
          ),
        ],
      );
    });
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
            child: PositiveCustomBtn(
          onTap: () {
            Get.back();
          },
          title: "Cancel",
          bgColor: AppColors.white,
          textColor: AppColors.primaryColor,
        )),
        SizedBox(width: SizeConfig.size16),
        Expanded(
          child: PositiveCustomBtn(
              onTap: () async {
                await controller.submitPost(postVia);
              },
              title: 'Post Now'),
        ),
      ],
    );
  }
}
