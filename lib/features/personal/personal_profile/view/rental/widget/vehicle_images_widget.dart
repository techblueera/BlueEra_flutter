import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleImagesWidget extends StatelessWidget {
  final VehicleRentalServiceController controller;
  final CommonMultipleImageSectionController multipleImageSectionController;

  const VehicleImagesWidget({
    super.key,
    required this.controller,
    required this.multipleImageSectionController});

  @override
  Widget build(BuildContext context) {
    return Obx(()=> CustomFormCard(
      padding: EdgeInsets.only(
          top: SizeConfig.size16, bottom: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          /// vehicleNumberPlateImages
          _buildAddButton(
              title: AppStrings.uploadVehicleNumberPlateImage,
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.uploadVehicleNumberPlateImage,
                    child: Column(
                      children: [
                        GetBuilder<CommonMultipleImageSectionController>(
                          id: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
                          builder: (ctrl) => CommonMultipleImageUploadSection(
                            title: AppStrings.uploadVehicleNumberPlateImage,
                            minImages: 1,
                            maxImages: 1,
                            images: controller.vehicleNumberPlateImages,
                            onAddImage: () async {
                              multipleImageSectionController.addImages(
                                  label: AppStrings.vehicleNumberPlateImages,
                                  imageList: controller.vehicleNumberPlateImages,
                                  updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
                                  maxUploadImages: 1
                              );
                            },
                            onRemoveImage: (index) {
                              multipleImageSectionController.removeImageAt(
                                imageList: controller.vehicleNumberPlateImages,
                                index: index,
                                updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomBtn(
                          title: controller.isUploadImagesLoading
                              ? null
                              : AppStrings.upload,
                          isLoading: controller.isUploadImagesLoading,
                          onTap: ()=> controller.uploadVehicleImagesApi(
                              images: controller.vehicleNumberPlateImages,
                              sectionId: CommonMultipleImageSectionController.vehicleNumberPlateImageId
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
              status: controller.vehicleImagesUploadStatus[CommonMultipleImageSectionController.vehicleNumberPlateImageId] ?? false
          ),

          /// vehicleRightSideImageId
          _buildAddButton(
              title: AppStrings.uploadVehicleRightSideImages,
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.uploadVehicleRightSideImages,
                    child: Column(
                      children: [
                        GetBuilder<CommonMultipleImageSectionController>(
                          id: CommonMultipleImageSectionController.vehicleRightSideImageId,
                          builder: (ctrl) => CommonMultipleImageUploadSection(
                            title: AppStrings.uploadVehicleRightSideImages,
                            minImages: 2,
                            maxImages: 4,
                            images: controller.vehicleRightSideImages,
                            onAddImage: () async {
                              multipleImageSectionController.addImages(
                                  label: AppStrings.vehicleRightSideImages,
                                  imageList: controller.vehicleRightSideImages,
                                  updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
                                  maxUploadImages: controller.maxVehicleImageUpload
                              );
                            },
                            onRemoveImage: (index) {
                              multipleImageSectionController.removeImageAt(
                                imageList: controller.vehicleRightSideImages,
                                index: index,
                                updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomBtn(
                          title: controller.isUploadImagesLoading
                              ? null
                              : AppStrings.upload,
                          isLoading: controller.isUploadImagesLoading,
                          onTap: ()=> controller.uploadVehicleImagesApi(
                              images: controller.vehicleRightSideImages,
                              sectionId: CommonMultipleImageSectionController.vehicleRightSideImageId
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
              status: controller.vehicleImagesUploadStatus[CommonMultipleImageSectionController.vehicleRightSideImageId] ?? false
          ),

          /// vehicleLeftSideImageId
          _buildAddButton(
              title: AppStrings.uploadVehicleLeftSideImages,
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.uploadVehicleLeftSideImages,
                    child: Column(
                      children: [
                        GetBuilder<CommonMultipleImageSectionController>(
                          id: CommonMultipleImageSectionController.vehicleLeftSideImageId,
                          builder: (ctrl) => CommonMultipleImageUploadSection(
                            title: AppStrings.uploadVehicleNumberPlateImage,
                            minImages: 2,
                            maxImages: 4,
                            images: controller.vehicleLeftSideImages,
                            onAddImage: () {
                              multipleImageSectionController.addImages(
                                  label: AppStrings.vehicleLeftSideImages,
                                  imageList: controller.vehicleLeftSideImages,
                                  updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
                                  maxUploadImages: controller.maxVehicleImageUpload
                              );
                            },
                            onRemoveImage: (index) {
                              multipleImageSectionController.removeImageAt(
                                imageList: controller.vehicleLeftSideImages,
                                index: index,
                                updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomBtn(
                          title: controller.isUploadImagesLoading
                              ? null
                              : AppStrings.upload,
                          isLoading: controller.isUploadImagesLoading,
                          onTap: ()=> controller.uploadVehicleImagesApi(
                              images: controller.vehicleLeftSideImages,
                              sectionId: CommonMultipleImageSectionController.vehicleLeftSideImageId
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
              status: controller.vehicleImagesUploadStatus[CommonMultipleImageSectionController.vehicleLeftSideImageId] ?? false
          ),

          /// vehicleFrontImages
          _buildAddButton(
              title: AppStrings.uploadVehicleFrontImages,
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.uploadVehicleFrontImages,
                    child: Column(
                      children: [
                        GetBuilder<CommonMultipleImageSectionController>(
                          id: CommonMultipleImageSectionController.vehicleFrontImageId,
                          builder: (ctrl) => CommonMultipleImageUploadSection(
                            title: AppStrings.uploadVehicleFrontImages,
                            minImages: 1,
                            maxImages: 2,
                            images: controller.vehicleFrontImages,
                            onAddImage: () async {
                              multipleImageSectionController.addImages(
                                  label: AppStrings.vehicleFrontImages,
                                  imageList: controller.vehicleFrontImages,
                                  updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
                                  maxUploadImages: 1
                              );
                            },
                            onRemoveImage: (index) {
                              multipleImageSectionController.removeImageAt(
                                imageList: controller.vehicleFrontImages,
                                index: index,
                                updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomBtn(
                          title: controller.isUploadImagesLoading
                              ? null
                              : AppStrings.upload,
                          isLoading: controller.isUploadImagesLoading,
                          onTap: ()=> controller.uploadVehicleImagesApi(
                              images: controller.vehicleFrontImages,
                              sectionId: CommonMultipleImageSectionController.vehicleFrontImageId
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
              status: controller.vehicleImagesUploadStatus[CommonMultipleImageSectionController.vehicleFrontImageId] ?? false
          ),

          /// vehicleBackImages
          _buildAddButton(
              title: AppStrings.uploadVehicleBackImages,
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.uploadVehicleBackImages,
                    child: Column(
                      children: [
                        GetBuilder<CommonMultipleImageSectionController>(
                          id: CommonMultipleImageSectionController.vehicleBackImageId,
                          builder: (ctrl) => CommonMultipleImageUploadSection(
                            title: AppStrings.uploadVehicleBackImages,
                            minImages: 1,
                            maxImages: 2,
                            images: controller.vehicleBackImages,
                            onAddImage: () async {
                              multipleImageSectionController.addImages(
                                  label: AppStrings.vehicleBackImages,
                                  imageList: controller.vehicleBackImages,
                                  updateId: CommonMultipleImageSectionController.vehicleBackImageId,
                                  maxUploadImages: 1
                              );
                            },
                            onRemoveImage: (index) {
                              multipleImageSectionController.removeImageAt(
                                imageList: controller.vehicleBackImages,
                                index: index,
                                updateId: CommonMultipleImageSectionController.vehicleBackImageId,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSmall),
                        CustomBtn(
                          title: controller.isUploadImagesLoading
                              ? null
                              : AppStrings.upload,
                          isLoading: controller.isUploadImagesLoading,
                          onTap: ()=> controller.uploadVehicleImagesApi(
                              images: controller.vehicleBackImages,
                              sectionId: CommonMultipleImageSectionController.vehicleBackImageId
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
              status: controller.vehicleImagesUploadStatus[CommonMultipleImageSectionController.vehicleBackImageId] ?? false
          ),
        ],
      ),
    ));
  }

  Widget _buildAddButton({
    required String title,
    required VoidCallback onTap,
    required bool status
  }) {


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

