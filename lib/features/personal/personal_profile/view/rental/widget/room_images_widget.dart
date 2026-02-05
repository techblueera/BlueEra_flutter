import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/stay_images_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class roomImagesWidget extends StatelessWidget {
  final StayImagesController controller;
  final CommonMultipleImageSectionController multipleImageSectionController;

  const roomImagesWidget({
    super.key,
    required this.controller,
    required this.multipleImageSectionController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(height: SizeConfig.paddingM),

          // Room Image
          _buildAddButton(
            title: AppStrings.uploadRoomImages,
            onTap: () {
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title: AppStrings.uploadRoomImages,
                  child: Column(
                    children: [
                      GetBuilder<CommonMultipleImageSectionController>(
                        id: CommonMultipleImageSectionController.roomImageId,
                        builder: (ctrl) => CommonMultipleImageUploadSection(
                          title: AppStrings.uploadRoomImages,
                          minImages: controller.maxHomeImageUpload,
                          maxImages: controller.maxHomeImageUpload,
                          images: controller.roomImages,
                          onAddImage: () async {
                            multipleImageSectionController.addImages(
                              label: AppStrings.roomsImagesLabel,
                              imageList: controller.roomImages,
                              updateId: CommonMultipleImageSectionController.roomImageId,
                              maxUploadImages: controller.maxHomeImageUpload,
                            );
                          },
                          onRemoveImage: (index) {
                            multipleImageSectionController.removeImageAt(
                              imageList: controller.roomImages,
                              index: index,
                              updateId: CommonMultipleImageSectionController.roomImageId,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXSmall),
                      CustomBtn(
                        title: controller.isUploadImagesLoading.value
                            ? null
                            : AppStrings.upload,
                        isLoading: controller.isUploadImagesLoading.value,
                        onTap: ()=> controller.uploadRentalImagesApi(
                            images: controller.roomImages,
                            sectionId: CommonMultipleImageSectionController.roomImageId
                        ),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      )
                    ],
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            status: controller.sectionUploadStatus[CommonMultipleImageSectionController.roomImageId] ?? false
          ),

          // kitchenImages
          _buildAddButton(
            title: AppStrings.uploadKitchenImages,
            onTap: () {
              CommonDocumentBottomSheet(
                title: AppStrings.uploadKitchenImages,
                child: Column(
                  children: [
                    GetBuilder<CommonMultipleImageSectionController>(
                      id: CommonMultipleImageSectionController.kitchenImageId,
                      builder: (ctrl) => CommonMultipleImageUploadSection(
                        title: AppStrings.uploadKitchenImages,
                        minImages: 2,
                        maxImages: controller.maxHomeImageUpload,
                        images: controller.kitchenImages,
                        onAddImage: () async {
                          multipleImageSectionController.addImages(
                              label: AppStrings.kitchenImagesLabel,
                              imageList: controller.kitchenImages,
                              updateId: CommonMultipleImageSectionController.kitchenImageId,
                              maxUploadImages: controller.maxHomeImageUpload
                          );
                        },
                        onRemoveImage: (index) {
                          multipleImageSectionController.removeImageAt(
                            imageList: controller.kitchenImages,
                            index: index,
                            updateId: CommonMultipleImageSectionController.kitchenImageId,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: SizeConfig.paddingXSmall),
                    CustomBtn(
                      title: controller.isUploadImagesLoading.value
                          ? null
                          : AppStrings.upload,
                      isLoading: controller.isUploadImagesLoading.value,
                      onTap: ()=> controller.uploadRentalImagesApi(
                          images: controller.kitchenImages,
                          sectionId: CommonMultipleImageSectionController.kitchenImageId
                      ),
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                    )
                  ],
                ),
              );
            },
            status: controller.sectionUploadStatus[CommonMultipleImageSectionController.kitchenImageId] ?? false

          ),
          // SizedBox(height: SizeConfig.paddingM),

          // bathroomImages
          _buildAddButton(
            title: AppStrings.uploadBathroomImages,
            onTap: () {
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title: AppStrings.uploadBathroomImages,
                  child: Column(
                    children: [
                      GetBuilder<CommonMultipleImageSectionController>(
                        id: CommonMultipleImageSectionController.bathroomImageId,
                        builder: (ctrl) => CommonMultipleImageUploadSection(
                          title: AppStrings.uploadBathroomImages,
                          minImages: 2,
                          maxImages: controller.maxHomeImageUpload,
                          images: controller.bathroomImages,
                          onAddImage: () async {
                            multipleImageSectionController.addImages(
                                label: AppStrings.bathroomImagesLabel,
                                imageList: controller.bathroomImages,
                                updateId: CommonMultipleImageSectionController.bathroomImageId,
                                maxUploadImages: controller.maxHomeImageUpload
                            );
                          },
                          onRemoveImage: (index) {
                            multipleImageSectionController.removeImageAt(
                              imageList: controller.bathroomImages,
                              index: index,
                              updateId: CommonMultipleImageSectionController.bathroomImageId,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXSmall),
                      CustomBtn(
                        title: controller.isUploadImagesLoading.value
                            ? null
                            : AppStrings.upload,
                        isLoading: controller.isUploadImagesLoading.value,
                        onTap: ()=> controller.uploadRentalImagesApi(
                            images: controller.bathroomImages,
                            sectionId: CommonMultipleImageSectionController.bathroomImageId
                        ),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      )
                    ],
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            status: controller.sectionUploadStatus[CommonMultipleImageSectionController.bathroomImageId] ?? false
          ),
          // SizedBox(height: SizeConfig.paddingM),

          // roadSideImages
          _buildAddButton(
            title: AppStrings.uploadRoadSideImages,
            onTap: () {
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title: AppStrings.uploadRoadSideImages,
                  child: Column(
                    children: [
                      GetBuilder<CommonMultipleImageSectionController>(
                        id: CommonMultipleImageSectionController.roadSideImageId,
                        builder: (ctrl) => CommonMultipleImageUploadSection(
                          title: AppStrings.uploadRoadSideImages,
                          minImages: 2,
                          maxImages: controller.maxHomeImageUpload,
                          images: controller.roadSideImages,
                          onAddImage: () async {
                            multipleImageSectionController.addImages(
                              label: AppStrings.roadSideImagesLabel,
                              imageList: controller.roadSideImages,
                              updateId: CommonMultipleImageSectionController.roadSideImageId,
                              maxUploadImages: controller.maxHomeImageUpload,
                            );
                          },
                          onRemoveImage: (index) {
                            multipleImageSectionController.removeImageAt(
                              imageList: controller.roadSideImages,
                              index: index,
                              updateId: CommonMultipleImageSectionController.roadSideImageId,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXSmall),
                      CustomBtn(
                        title: controller.isUploadImagesLoading.value
                            ? null
                            : AppStrings.upload,
                        isLoading: controller.isUploadImagesLoading.value,
                        onTap: ()=> controller.uploadRentalImagesApi(
                            images: controller.roadSideImages,
                            sectionId: CommonMultipleImageSectionController.roadSideImageId
                        ),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      )
                    ],
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            status: controller.sectionUploadStatus[CommonMultipleImageSectionController.roadSideImageId] ?? false

          ),
          // SizedBox(height: SizeConfig.paddingM),

          // otherImages
          _buildAddButton(
            title: AppStrings.uploadOtherImages,
            onTap: () {
              /// roomImageId
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title: AppStrings.uploadOtherImages,
                  child: Column(
                    children: [
                      GetBuilder<CommonMultipleImageSectionController>(
                        id: CommonMultipleImageSectionController.otherImageId,
                        builder: (ctrl) => CommonMultipleImageUploadSection(
                          title: AppStrings.uploadOtherImages,
                          maxImages: controller.maxHomeImageUpload,
                          images: controller.otherImages,
                          onAddImage: () async {
                            multipleImageSectionController.addImages(
                                label: AppStrings.otherImagesLabel,
                                imageList: controller.otherImages,
                                updateId: CommonMultipleImageSectionController.otherImageId,
                                maxUploadImages: controller.maxHomeImageUpload
                            );
                          },
                          onRemoveImage: (index) {
                            multipleImageSectionController.removeImageAt(
                              imageList: controller.otherImages,
                              index: index,
                              updateId: CommonMultipleImageSectionController.otherImageId,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXSmall),
                      CustomBtn(
                        title: controller.isUploadImagesLoading.value
                            ? null
                            : AppStrings.upload,
                        isLoading: controller.isUploadImagesLoading.value,
                        onTap: ()=> controller.uploadRentalImagesApi(
                            images: controller.otherImages,
                            sectionId: CommonMultipleImageSectionController.otherImageId
                        ),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                      )
                    ],
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            status: controller.sectionUploadStatus[CommonMultipleImageSectionController.otherImageId] ?? false

          ),
          // SizedBox(height: SizeConfig.paddingM),
        ],
      )
    );
  }

  Widget _buildAddButton({
    required String title,
    required VoidCallback onTap,
    required bool status
  }) {

    // bool isUploadable = status == DocStatus.notUploaded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: status
                ? null
                : onTap,
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (status)
                    ? LocalAssets(
                  imagePath: AppIconAssets.green_tick_icon,
                  height: 20,
                  width: 20,
                ) : Icon(
                  CupertinoIcons.add,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Flexible(
                  child: CustomText(
                    title,
                    color: status
                        ? AppColors.secondaryTextColor
                        : AppColors.primaryColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

  }

}


