// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/reel/view/channel/manage_channel_screen.dart';
// import 'package:BlueEra/features/common/reelsModule/controller/preview_created_reels_controller.dart';
// import 'package:BlueEra/features/common/reelsModule/custom_thumbnail.dart';
// import 'package:BlueEra/features/common/reelsModule/custom_video_picker.dart';
// import 'package:BlueEra/features/common/reelsModule/custom_video_time.dart';
// import 'package:BlueEra/features/common/reelsModule/widget/loading_ui.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class VideoPickerBottomSheetUi {
//   ///CREATE PROFILE O CHANNEL OR SKIP...
//   static showProfileChannelDialog({required BuildContext context}) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.black28,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             CustomText("Create Your Channel", fontWeight: FontWeight.bold, fontSize: SizeConfig.large),
//             IconButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 icon: Icon(Icons.close))
//           ],
//         ),
//         content: CustomText(
//           "You're earning from reels—awesome! To manage your content and grow your audience, you need to create your own channel. Start now and take full control of your earnings and visibility.",
//         ),
//         actionsPadding: EdgeInsets.only(right: SizeConfig.paddingM, bottom: SizeConfig.paddingS),
//         actions: [
//           Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size10,
//             ),
//             child: PositiveCustomBtn(
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   navigatePushTo(context, ManageChannelScreen());
//                 },
//                 title: "Create Channel"),
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size20),
//             child: PositiveCustomBtn(
//               onTap: () {
//                 Navigator.of(context).pop();
//                 VideoPickerBottomSheetUi.show(context: context);
//               },
//               title: "Not Now",
//               bgColor: Colors.transparent,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   static Future<void> show({required BuildContext context}) async {
//     await showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Container(
//           // height: 200,
//           width: Get.width,
//           clipBehavior: Clip.antiAlias,
//           decoration: BoxDecoration(color: AppColors.black28, borderRadius: BorderRadius.circular(20)),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 height: SizeConfig.size20,
//               ),
//               Container(
//                 // height: 65,
//                 color: AppColors.black28,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     const Spacer(),
//                     CustomText(
//                       "Choose Video",
//                       fontWeight: FontWeight.bold,
//                       fontSize: SizeConfig.large,
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       onTap: () => Get.back(),
//                       child: Container(
//                         height: 30,
//                         width: 30,
//                         margin: const EdgeInsets.only(right: 20),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.transparent,
//                           // border: Border.all(color: AppColors.black),
//                         ),
//                         child: Center(
//                           child: LocalAssets(
//                             imagePath: AppIconAssets.close_white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(
//                 height: SizeConfig.size10,
//               ),
//               GestureDetector(
//                 onTap: () async {
//                   uploadVideo(isVideoUploadType: AppConstants.short, context);
//                 },
//                 child: Container(
//                   color: AppColors.transparent,
//                   alignment: Alignment.center,
//                   padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       LocalAssets(imagePath: AppIconAssets.gallery_sky, width: 26),
//                       SizedBox(
//                         width: SizeConfig.paddingXS,
//                       ),
//                       Flexible(
//                         child: CustomText(
//                           "Short Video Upload (up to 60 sec)",
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 height: SizeConfig.size10,
//               ),
//               Padding(
//                   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
//                   child: Divider(
//                     color: Colors.white,
//                   )),
//               SizedBox(
//                 height: SizeConfig.size10,
//               ),
//               GestureDetector(
//                   onTap: () async {
//                     uploadVideo(context, isVideoUploadType: AppConstants.long);
//                   },
//                   child: Container(
//                     color: AppColors.transparent,
//                     alignment: Alignment.center,
//                     padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         LocalAssets(imagePath: AppIconAssets.gallery_sky, width: 26),
//                         SizedBox(
//                           width: SizeConfig.paddingXS,
//                         ),
//                         Flexible(
//                           child: CustomText(
//                             "Long Video Upload (up to 5 min)",
//                           ),
//                         ),
//                       ],
//                     ),
//                   )),
//               SizedBox(
//                 height: SizeConfig.size30,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   static uploadVideo(BuildContext context, {String? isVideoUploadType}) async {
//     Get.back(); // Close Bottom Sheet...
//
//     // if (InternetConnection.isConnect.value) {
//     Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...
//
//     final videoPath = await CustomVideoPicker.pickVideo(); // Pick Video...
//
//     if (videoPath != null) {
//       final videoTime = await CustomVideoTime.onGet(videoPath);
//       final String? videoImage = await CustomThumbnail.onGet(videoPath); //
//       Get.back(); // Stop Loading...
// // Pick Video Time...
// //       if ((videoTime ?? 0) < videoDuration) {
//       logs("Picked Video Time => ${videoTime}");
//
//       if (videoTime != null) {
//         // Pick Video Image...
//
//         Get.back(); // Stop Loading...
//         if (videoImage != null) {
//           // Get.to(VideoTrimScreen(
//           //   videoPath: videoPath,
//           //   videoType: isVideoUploadType,
//           //   videoThumbnail: videoImage,
//           // ));
//
//           // Get.to(
//           //     PreviewCreatedReelsView(
//           //       videoType: isVideoUploadType,
//           //     ),
//           //     arguments: {
//           //       "video": videoPath,
//           //       "image": videoImage,
//           //       "time": videoTime,
//           //       "songId": "",
//           //     },
//           //     binding: PreviewCreatedReelsBinding());
//         } else {
//           logs("Get Video Image Failed !!");
//           Get.back(); // Stop Loading...
//         }
//       } else {
//         logs("Get Video Time Failed !!");
//         Get.back(); // Stop Loading...
//       }
//       /*} else {
//         Get.to(VideoTrimScreen(videoPath: videoPath,videoType: isVideoUploadType,videoThumbnail:videoImage??"" ,));
//         // Get.back();
//
//         // commonSnackBar(
//         //     message: "Please select video duration max $videoDuration sec.");
//         return;
//       }*/
//     } else {
//       logs("Video Not Selected !!");
//       Get.back(); // Stop Loading...
//     }
//   }
// }
//
// class PreviewCreatedReelsBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<PreviewCreatedReelsController>(() => PreviewCreatedReelsController());
//   }
// }
