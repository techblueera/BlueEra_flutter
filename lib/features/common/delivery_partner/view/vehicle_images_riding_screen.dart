// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
//
// import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
// import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class VehicleImagesRidingScreen extends StatefulWidget {
//   const VehicleImagesRidingScreen({super.key});
//
//   @override
//   State<VehicleImagesRidingScreen> createState() => _VehicleImagesRidingScreenState();
// }
//
// class _VehicleImagesRidingScreenState extends State<VehicleImagesRidingScreen> {
//   final controller = Get.put(DeliveryPartnerController());
//   final multipleImageSectionController = Get.put(CommonMultipleImageSectionController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         title: AppStrings.vehicleImages,
//         // onBackTap: onBackPressed,
//         buildCustomActionWidget: ()=> Padding(
//           padding: const EdgeInsets.only(right: 16),
//           child: Center(
//             child: Text(
//               "${AppStrings.stepLabel.tr}5/6",
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(SizeConfig.size15),
//           child: Obx(()=> AbsorbPointer(
//             absorbing: controller.isRiderVehicleImagesLoading.value,
//             child: Column(
//               children: [
//                 /// vehicleNumberPlateImages
//                 GetBuilder<CommonMultipleImageSectionController>(
//                   id: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
//                   builder: (ctrl) => CommonMultipleImageUploadSection(
//                     title: AppStrings.uploadVehicleNumberPlateImage,
//                     maxImages: 1,
//                     images: controller.vehicleNumberPlateImages,
//                     onAddImage: () async {
//                       multipleImageSectionController.addImages(
//                           label: AppStrings.vehicleNumberPlateImages,
//                           imageList: controller.vehicleNumberPlateImages,
//                           updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
//                           maxUploadImages: 1
//                       );
//                     },
//                     onRemoveImage: (index) {
//                       multipleImageSectionController.removeImageAt(
//                         imageList: controller.vehicleNumberPlateImages,
//                         index: index,
//                         updateId: CommonMultipleImageSectionController.vehicleNumberPlateImageId,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.paddingM),
//
//                 /// vehicleRightSideImageId
//                 GetBuilder<CommonMultipleImageSectionController>(
//                   id: CommonMultipleImageSectionController.vehicleRightSideImageId,
//                   builder: (ctrl) => CommonMultipleImageUploadSection(
//                     title: AppStrings.uploadVehicleRightSideImages,
//                     minImages: 2,
//                     maxImages: controller.maxVehicleImageUpload,
//                     images: controller.vehicleRightSideImages,
//                     onAddImage: () async {
//                       multipleImageSectionController.addImages(
//                           label: AppStrings.vehicleRightSideImages,
//                           imageList: controller.vehicleRightSideImages,
//                           updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
//                           maxUploadImages: controller.maxVehicleImageUpload
//                       );
//                     },
//                     onRemoveImage: (index) {
//                       multipleImageSectionController.removeImageAt(
//                         imageList: controller.vehicleRightSideImages,
//                         index: index,
//                         updateId: CommonMultipleImageSectionController.vehicleRightSideImageId,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.paddingM),
//
//                 /// vehicleLeftSideImageId
//                 GetBuilder<CommonMultipleImageSectionController>(
//                   id: CommonMultipleImageSectionController.vehicleLeftSideImageId,
//                   builder: (ctrl) => CommonMultipleImageUploadSection(
//                     title: AppStrings.uploadVehicleLeftSideImages,
//                     minImages: 2,
//                     maxImages: controller.maxVehicleImageUpload,
//                     images: controller.vehicleLeftSideImages,
//                     onAddImage: () async {
//                       multipleImageSectionController.addImages(
//                           label: AppStrings.vehicleLeftSideImages,
//                           imageList: controller.vehicleLeftSideImages,
//                           updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
//                           maxUploadImages: controller.maxVehicleImageUpload
//                       );
//                     },
//                     onRemoveImage: (index) {
//                       multipleImageSectionController.removeImageAt(
//                         imageList: controller.vehicleLeftSideImages,
//                         index: index,
//                         updateId: CommonMultipleImageSectionController.vehicleLeftSideImageId,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.paddingM),
//
//                 /// vehicleFrontImages
//                 GetBuilder<CommonMultipleImageSectionController>(
//                   id: CommonMultipleImageSectionController.vehicleFrontImageId,
//                   builder: (ctrl) => CommonMultipleImageUploadSection(
//                     title: AppStrings.uploadVehicleFrontImages,
//                     maxImages: 1,
//                     images: controller.vehicleFrontImages,
//                     onAddImage: () async {
//                       multipleImageSectionController.addImages(
//                           label: AppStrings.vehicleFrontImages,
//                           imageList: controller.vehicleFrontImages,
//                           updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
//                           maxUploadImages: 1
//                       );
//                     },
//                     onRemoveImage: (index) {
//                       multipleImageSectionController.removeImageAt(
//                         imageList: controller.vehicleFrontImages,
//                         index: index,
//                         updateId: CommonMultipleImageSectionController.vehicleFrontImageId,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.paddingM),
//
//                 /// vehicleBackImages
//                 GetBuilder<CommonMultipleImageSectionController>(
//                   id: CommonMultipleImageSectionController.vehicleBackImageId,
//                   builder: (ctrl) => CommonMultipleImageUploadSection(
//                     title: AppStrings.uploadVehicleBackImages,
//                     maxImages: 1,
//                     images: controller.vehicleBackImages,
//                     onAddImage: () async {
//                       multipleImageSectionController.addImages(
//                           label: AppStrings.vehicleBackImages,
//                           imageList: controller.vehicleBackImages,
//                           updateId: CommonMultipleImageSectionController.vehicleBackImageId,
//                           maxUploadImages: 1
//                       );
//                     },
//                     onRemoveImage: (index) {
//                       multipleImageSectionController.removeImageAt(
//                         imageList: controller.vehicleBackImages,
//                         index: index,
//                         updateId: CommonMultipleImageSectionController.vehicleBackImageId,
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.paddingL),
//
//                 CustomBtn(
//                   title: controller.isRiderVehicleImagesLoading.value
//                       ? null
//                       : AppStrings.nextButton,
//                   onTap: ()=> controller.ridersOnboardingVehicleImagesApi(),
//                   radius: 10.0,
//                   bgColor: AppColors.primaryColor,
//                   isLoading: controller.isRiderVehicleImagesLoading.value,
//                 ),
//                 SizedBox(height: SizeConfig.paddingM),
//
//               ],
//             ),
//           )),
//         ),
//       ),
//     );
//   }
// }
