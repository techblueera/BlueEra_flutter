import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/deliver_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/deliver_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/common/deliver_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleImagesRidingScreen extends StatefulWidget {
  const VehicleImagesRidingScreen({super.key});

  @override
  State<VehicleImagesRidingScreen> createState() => _VehicleImagesRidingScreenState();
}

class _VehicleImagesRidingScreenState extends State<VehicleImagesRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Vehicle Images",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "Step-5/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Column(
          children: [
            /// vehicleNumberPlateImages
            GetBuilder<DeliveryPartnerController>(
              id: DeliveryPartnerController.vehicleNumberPlateImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: 'Upload Vehicle Number Plate Image',
                minImages: 2,
                maxImages: 1,
                images: ctrl.vehicleNumberPlateImages,
                onAddImage: () async {
                  ctrl.addImages(
                      label: 'Vehicle Number Plate Images',
                      imageList: ctrl.vehicleNumberPlateImages,
                      updateId: DeliveryPartnerController.vehicleNumberPlateImageId,
                      maxUploadImages: 1
                  );
                },
                onRemoveImage: (index) {
                  ctrl.removeImageAt(
                    imageList: ctrl.vehicleNumberPlateImages,
                    index: index,
                    updateId: DeliveryPartnerController.vehicleNumberPlateImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleRightSideImageId
            GetBuilder<DeliveryPartnerController>(
              id: DeliveryPartnerController.vehicleRightSideImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: 'Upload Vehicle Right Side Images',
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: ctrl.vehicleRightSideImages,
                onAddImage: () async {
                  ctrl.addImages(
                      label: 'Vehicle Right Side Images',
                      imageList: ctrl.vehicleRightSideImages,
                      updateId: DeliveryPartnerController.vehicleRightSideImageId,
                      maxUploadImages: controller.maxVehicleImageUpload
                  );
                },
                onRemoveImage: (index) {
                  ctrl.removeImageAt(
                    imageList: ctrl.vehicleRightSideImages,
                    index: index,
                    updateId: DeliveryPartnerController.vehicleRightSideImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleLeftSideImageId
            GetBuilder<DeliveryPartnerController>(
              id: DeliveryPartnerController.vehicleLeftSideImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: 'Upload Vehicle Left Side Images',
                minImages: 2,
                maxImages: controller.maxVehicleImageUpload,
                images: ctrl.vehicleLeftSideImages,
                onAddImage: () async {
                  ctrl.addImages(
                      label: 'Upload Vehicle Left Side Images',
                      imageList: ctrl.vehicleLeftSideImages,
                      updateId: DeliveryPartnerController.vehicleLeftSideImageId,
                      maxUploadImages: controller.maxVehicleImageUpload
                  );
                },
                onRemoveImage: (index) {
                  ctrl.removeImageAt(
                    imageList: ctrl.vehicleLeftSideImages,
                    index: index,
                    updateId: DeliveryPartnerController.vehicleLeftSideImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),

            /// vehicleLeftSideImageId
            GetBuilder<DeliveryPartnerController>(
              id: DeliveryPartnerController.vehicleFrBkImageId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: 'Upload Vehicle Front and Back Images',
                minImages: 2,
                maxImages: controller.maxLiveUploadImages,
                images: ctrl.vehicleFrBkImages,
                onAddImage: () async {
                  ctrl.addImages(
                      label: 'Vehicle Front and Back Images',
                      imageList: ctrl.vehicleFrBkImages,
                      updateId: DeliveryPartnerController.vehicleFrBkImageId,
                      maxUploadImages: controller.maxLiveUploadImages
                  );
                },
                onRemoveImage: (index) {
                  ctrl.removeImageAt(
                    imageList: ctrl.vehicleFrBkImages,
                    index: index,
                    updateId: DeliveryPartnerController.vehicleFrBkImageId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingL),

            CustomBtn(
              title: 'Next',
              onTap: ()=> Get.to(()=> VehicleInformationRidingScreen()),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
