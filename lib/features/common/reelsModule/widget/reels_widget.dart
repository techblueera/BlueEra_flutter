// import 'dart:io';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/reelsModule/controller/reels_controller.dart';
// import 'package:BlueEra/features/common/reelsModule/font_style.dart';
// import 'package:BlueEra/features/common/reelsModule/view/video_picker_bottom_sheet_ui.dart';
// import 'package:BlueEra/features/common/reelsModule/widget/comment_bottom_sheet_ui.dart';
// import 'package:BlueEra/features/common/reelsModule/widget/custom_icon_button.dart';
// import 'package:BlueEra/features/common/reelsModule/widget/loading_ui.dart';
// import 'package:BlueEra/widgets/common_delete_conformation_dialog.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:BlueEra/widgets/network_assets.dart';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:readmore/readmore.dart';
// import 'package:video_player/video_player.dart';
//
// class PreviewReelsView extends StatefulWidget {
//   const PreviewReelsView({super.key, required this.index, required this.currentPageIndex});
//
//   final int index;
//   final int currentPageIndex;
//
//   @override
//   State<PreviewReelsView> createState() => _PreviewReelsViewState();
// }
//
// class _PreviewReelsViewState extends State<PreviewReelsView> with SingleTickerProviderStateMixin {
//   final controller = Get.find<ReelsController>();
//
//   ChewieController? chewieController;
//   VideoPlayerController? videoPlayerController;
//
//   RxBool isPlaying = true.obs;
//   RxBool isShowIcon = false.obs;
//
//   RxBool isBuffering = false.obs;
//   RxBool isVideoLoading = true.obs;
//
//   RxBool isShowLikeAnimation = false.obs;
//   RxBool isShowLikeIconAnimation = false.obs;
//   RxBool isShowBookMarkIconAnimation = false.obs;
//
//   RxBool isReelsPage = true.obs; // This is Use to Stop Auto Playing..
//
//   RxBool isLike = false.obs;
//   RxBool isBookMark = false.obs;
//
//   RxMap customChanges = {"like": 0, "comment": 0}.obs;
//
//   AnimationController? _controller;
//   late Animation<double> _animation;
//
//   RxBool isReadMore = false.obs;
//
//   @override
//   void initState() {
//     _controller = AnimationController(
//       duration: const Duration(seconds: 4),
//       vsync: this,
//     )..repeat();
//
//     if (_controller != null) {
//       _animation = Tween(begin: 0.0, end: 1.0).animate(_controller!);
//     }
//     initializeVideoPlayer();
//     customSetting();
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     onDisposeVideoPlayer();
//     logs("Dispose Method Called Success");
//     super.dispose();
//   }
//
//   Future<void> initializeVideoPlayer() async {
//     try {
//       String videoPath = controller.mainReels[widget.index].videoUrl ?? "";
//       videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoPath));
//
//       await videoPlayerController?.initialize();
//
//       if (videoPlayerController != null && (videoPlayerController?.value.isInitialized ?? false)) {
//         chewieController = ChewieController(
//           videoPlayerController: videoPlayerController!,
//           looping: true,
//           allowedScreenSleep: false,
//           allowMuting: false,
//           showControlsOnInitialize: false,
//           showControls: false,
//           maxScale: 1,
//         );
//
//         if (chewieController != null) {
//           isVideoLoading.value = false;
//           (widget.index == widget.currentPageIndex && isReelsPage.value)
//               ? onPlayVideo()
//               : null; // Use => First Time Video Playing...
//         } else {
//           isVideoLoading.value = true;
//         }
//
//         videoPlayerController?.addListener(
//           () {
//             // Use => If Video Buffering then show loading....
//             (videoPlayerController?.value.isBuffering ?? false) ? isBuffering.value = true : isBuffering.value = false;
//
//             if (isReelsPage.value == false) {
//               onStopVideo(); // Use => On Change Routes...
//             }
//           },
//         );
//       }
//     } catch (e) {
//       onDisposeVideoPlayer();
//       logs("Reels Video Initialization Failed !!! ${widget.index} => $e");
//     }
//   }
//
//   void onStopVideo() {
//     isPlaying.value = false;
//     videoPlayerController?.pause();
//   }
//
//   void onPlayVideo() {
//     isPlaying.value = true;
//     videoPlayerController?.play();
//   }
//
//   void onDisposeVideoPlayer() {
//     try {
//       onStopVideo();
//       videoPlayerController?.dispose();
//       chewieController?.dispose();
//       chewieController = null;
//       videoPlayerController = null;
//       isVideoLoading.value = true;
//     } catch (e) {
//       logs(">>>> On Dispose VideoPlayer Error => $e");
//     }
//   }
//
//   void customSetting() {
//     isLike.value = controller.mainReels[widget.index].isLike ?? false;
//     isBookMark.value = controller.mainReels[widget.index].isBookmark ?? false;
//     customChanges["like"] = int.parse(controller.mainReels[widget.index].totalLikes.toString());
//     customChanges["comment"] = int.parse(controller.mainReels[widget.index].totalComments.toString());
//   }
//
//   void onClickVideo() async {
//     if (isVideoLoading.value == false) {
//       videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
//       isShowIcon.value = true;
//       await 2.seconds.delay();
//       isShowIcon.value = false;
//     }
//     if (isReelsPage.value == false) {
//       isReelsPage.value = true; // Use => On Back Reels Page...
//     }
//   }
//
//   void onClickPlayPause() async {
//     videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
//     if (isReelsPage.value == false) {
//       isReelsPage.value = true; // Use => On Back Reels Page...
//     }
//   }
//
//   Future<void> onClickShare() async {
//     // isReelsPage.value = false;
//     //
//     // Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...
//     //
//     // await BranchIoServices.onCreateBranchIoLink(
//     //   id: controller.mainReels[widget.index].id ?? "",
//     //   name: controller.mainReels[widget.index].caption ?? "",
//     //   image: controller.mainReels[widget.index].videoImage ?? "",
//     //   userId: controller.mainReels[widget.index].userId ?? "",
//     //   pageRoutes: "Video",
//     // );
//     //
//     // final link = await BranchIoServices.onGenerateLink();
//     //
//     // Get.back(); // Stop Loading...
//     //
//     // if (link != null) {
//     //   CustomShare.onShareLink(link: link);
//     // }
//     // await ReelsShareApi.callApi(loginUserId: userId, videoId: controller.mainReels[widget.index].id!);
//   }
//
//   Future<void> onClickLike() async {
//     if (isLike.value) {
//       isLike.value = false;
//       customChanges["like"]--;
//     } else {
//       isLike.value = true;
//       customChanges["like"]++;
//     }
//
//     isShowLikeIconAnimation.value = true;
//     await 500.milliseconds.delay();
//     isShowLikeIconAnimation.value = false;
//   }
//
//   ///BOOKMARK...
//   Future<void> onClickBookMark() async {
//     if (isBookMark.value) {
//       isBookMark.value = false;
//     } else {
//       isBookMark.value = true;
//     }
//
//     isShowBookMarkIconAnimation.value = true;
//     await 500.milliseconds.delay();
//     isShowBookMarkIconAnimation.value = false;
//   }
//
//   Future<void> onDoubleClick() async {
//     if (isLike.value) {
//       isLike.value = false;
//       customChanges["like"]--;
//     } else {
//       isLike.value = true;
//       customChanges["like"]++;
//
//       isShowLikeAnimation.value = true;
//       // Vibration.vibrate(duration: 50, amplitude: 128);
//       await 1200.milliseconds.delay();
//       isShowLikeAnimation.value = false;
//     }
//   }
//
//   Future<void> onClickComment() async {
//     isReelsPage.value = false;
//     customChanges["comment"] = await CommentBottomSheetUi().show(
//       context: context,
//       commentType: 2,
//       commentTypeId: controller.mainReels[widget.index].id.toString(),
//       totalComments: customChanges["comment"],
//     );
//   }
//
//   Future<void> _onSelected(BuildContext context, String value) async {
//     if (value == 'delete') {
//       // Show confirmation or perform delete action
//       showDialog(
//         context: context,
//         builder: (context) => ConfirmDeleteDialog(
//           content: "Are you sure you want to delete this reel?",
//           onDelete: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       );
//     } else if (value == 'edit') {
//       onStopVideo();
//
//       ///show edit reel form....
//       // await Get.to(CreateReelScreen(
//       //   videoPath: '',
//       //   videoUploadType: '',
//       //   isEditReel: true,
//       //   reelsData: controller.mainReels[widget.index],
//       // ));
//       onPlayVideo();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.index == widget.currentPageIndex) {
//       // Use => Play Current Video On Scrolling...
//       isReadMore.value = false;
//       (isVideoLoading.value == false && isReelsPage.value) ? onPlayVideo() : null;
//     } else {
//       // Restart Previous Video On Scrolling...
//       isVideoLoading.value == false ? videoPlayerController?.seekTo(Duration.zero) : null;
//       onStopVideo(); // Stop Previous Video On Scrolling...
//     }
//     return Scaffold(
//       body: SafeArea(
//         child: SizedBox(
//           height: Get.height,
//           width: Get.width,
//           child: Stack(
//             children: [
//               GestureDetector(
//                 onTap: onClickVideo,
//                 onDoubleTap: onDoubleClick,
//                 child: Container(
//                   color: AppColors.black,
//                   height: (Get.height),
//                   // height: (Get.height - bottomBarSize),
//                   width: Get.width,
//                   child: Obx(
//                     () => isVideoLoading.value
//                         ? Align(
//                             alignment: Alignment.bottomCenter,
//                             child: LinearProgressIndicator(color: AppColors.primaryColor))
//                         : SizedBox.expand(
//                             child: FittedBox(
//                               fit: BoxFit.cover,
//                               child: SizedBox(
//                                 width: videoPlayerController?.value.size.width ?? 0,
//                                 height: videoPlayerController?.value.size.height ?? 0,
//                                 child: Chewie(controller: chewieController!),
//                               ),
//                             ),
//                           ),
//                   ),
//                 ),
//               ),
//               Obx(
//                 () => isShowIcon.value
//                     ? Align(
//                         alignment: Alignment.center,
//                         child: GestureDetector(
//                           onTap: onClickPlayPause,
//                           child: Container(
//                             height: 70,
//                             width: 70,
//                             padding: EdgeInsets.only(left: isPlaying.value ? 0 : 2),
//                             decoration: BoxDecoration(color: AppColors.black.withOpacity(0.2), shape: BoxShape.circle),
//                             child: Center(
//                               child: isPlaying.value
//                                   ? Icon(Icons.pause_circle)
//                                   : Icon(Icons
//                                       .play_circle) /*Image.asset(
//                                 isPlaying.value ? AppAsset.icPause : AppAsset.icPlay,
//                                 width: 30,
//                                 height: 30,
//                                 color: AppColors.white,
//                               )*/
//                               ,
//                             ),
//                           ),
//                         ),
//                       )
//                     : const Offstage(),
//               ),
//               Positioned(
//                 bottom: 0,
//                 child: Obx(
//                   () => Visibility(
//                     visible: (isVideoLoading == false),
//                     child: Container(
//                       height: Get.height / 4,
//                       width: Get.width,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [AppColors.transparent, AppColors.black.withOpacity(0.7)],
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 0,
//                 child: Container(
//                   padding: Platform.isAndroid ? EdgeInsets.only(top: 30) : EdgeInsets.only(top: 46),
//                   height: Get.height,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.only(top: SizeConfig.size5),
//                         child: CustomIconButton(
//                           circleSize: 40,
//                           iconSize: 20,
//                           icon: AppIconAssets.add,
//                           callback: () {
//                             isReelsPage.value = false;
//
//                             ///IF PROFILE ALREADY CREATED then upload reels or else create channel first...
//
//                             if (has_reel_profile_status == "true") {
//                               VideoPickerBottomSheetUi.show(context: context);
//                             } else if (has_reel_profile_status == "false") {
//                               VideoPickerBottomSheetUi.showProfileChannelDialog(context: context);
//                             } else {
//                               VideoPickerBottomSheetUi.show(context: context);
//                             }
//                             // VideoPickerBottomSheetUi.show(context: context);
//                           },
//                         ),
//                       ),
//                       SizedBox(
//                         width: 5,
//                       ),
//                       if (userId.toString() == controller.mainReels[widget.index].userId.toString())
//                         PopupMenuButton<String>(
//                           onSelected: (value) => _onSelected(context, value),
//                           padding: EdgeInsets.zero,
//                           icon: Icon(
//                             Icons.more_vert,
//                             size: 25,
//                           ),
//                           itemBuilder: (context) => [
//                             PopupMenuItem<String>(
//                               value: 'edit',
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.edit_outlined,
//                                   ),
//                                   SizedBox(width: 8),
//                                   CustomText(
//                                     "Edit",
//                                   )
//                                 ],
//                               ),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'delete',
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.delete_outline, color: AppColors.red00),
//                                   SizedBox(width: 8),
//                                   CustomText(
//                                     "Delete",
//                                     color: AppColors.red00,
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       /*GestureDetector(
//                         onTap: () {
//                           isReelsPage.value = false;
//                           // ReportBottomSheetUi.show(context: context, eventId: controller.mainReels[widget.index].id ?? "", eventType: 1);
//                         },
//                         child: Container(
//                           height: 40,
//                           width: 40,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.more_vert_rounded,
//                             color: AppColors.white,
//                             size: 30,
//                           ),
//                         ),
//                       ),*/
//                       SizedBox(
//                         width: 8,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.only(top: 30, bottom: 100),
//                   height: Get.height,
//                   child: Column(
//                     children: [
//                       const Spacer(),
//                       /*  GestureDetector(
//                         onTap: () {
//                           logs("Video User Id => ${controller.mainReels[widget.index].userId} => ${userId}");
//                           if (controller.mainReels[widget.index].userId != userId) {
//                             isReelsPage.value = false;
//                             SendGiftOnVideoBottomSheetUi.show(
//                               context: context,
//                               videoId: controller.mainReels[widget.index].id ?? "",
//                             );
//                           } else {
//                             Utils.showToast(EnumLocal.txtYouCantSendGiftOwnVideo.name.tr);
//                           }
//                         },
//                         child: SizedBox(
//                           width: 65,
//                           child: Lottie.asset(AppAsset.lottieGift),
//                         ),
//                       ),
//                       10.height,*/
//                       Obx(
//                         () => SizedBox(
//                           height: 40,
//                           child: AnimatedContainer(
//                             duration: Duration(milliseconds: 300),
//                             height: isShowLikeIconAnimation.value ? 15 : 50,
//                             width: isShowLikeIconAnimation.value ? 15 : 50,
//                             alignment: Alignment.center,
//                             child: CustomIconButton(
//                               icon: AppIconAssets.likeIcon,
//                               callback: onClickLike,
//                               iconSize: 34,
//                               iconColor: isLike.value ? AppColors.primaryColor : AppColors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Obx(
//                         () => Text(
//                           CustomFormatNumber.convert(customChanges["like"]),
//                           style: AppFontStyle.styleW700(AppColors.white, 14),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 15,
//                       ),
//                       if (controller.mainReels[widget.index].allow_comments ?? false) ...[
//                         CustomIconButton(
//                             icon: AppIconAssets.commentIcon, circleSize: 40, callback: onClickComment, iconSize: 34),
//                         Obx(
//                           () => Text(
//                             CustomFormatNumber.convert(customChanges["comment"]),
//                             style: AppFontStyle.styleW700(AppColors.white, 14),
//                           ),
//                         ),
//                         SizedBox(
//                           height: 15,
//                         ),
//                       ],
//
//                       ///BOOK MARK REELS...
//                       Obx(
//                         () => SizedBox(
//                           height: 40,
//                           child: AnimatedContainer(
//                             duration: Duration(milliseconds: 300),
//                             height: isShowBookMarkIconAnimation.value ? 15 : 50,
//                             width: isShowBookMarkIconAnimation.value ? 15 : 50,
//                             alignment: Alignment.center,
//                             child: CustomIconButton(
//                               icon: AppIconAssets.savedIcon,
//                               callback: onClickBookMark,
//                               iconSize: 34,
//                               iconColor: isBookMark.value ? AppColors.primaryColor : AppColors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 15,
//                       ),
//                       CustomIconButton(
//                         circleSize: 40,
//                         // circleColor: Colors.pink,
//                         icon: AppIconAssets.shareIcon,
//                         callback: onClickShare,
//                         iconSize: 32,
//                         iconColor: AppColors.white,
//                       ),
//                       Text(
//                         "",
//                         style: AppFontStyle.styleW700(AppColors.white, 14),
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           // logs("Song Id => ${controller.mainReels[widget.index].songId}");
//                           // if (controller.mainReels[widget.index].songId != "" && controller.mainReels[widget.index].songId != null) {
//                           //   isReelsPage.value = false;
//                           //   Get.toNamed(AppRoutes.audioWiseVideosPage, arguments: controller.mainReels[widget.index].songId);
//                           // } else if (controller.mainReels[widget.index].userId != userId) {
//                           //   isReelsPage.value = false;
//                           //   PreviewProfileBottomSheetUi.show(
//                           //     context: context,
//                           //     userId: controller.mainReels[widget.index].userId ?? "",
//                           //   );
//                           // } else {
//                           //   isReelsPage.value = false;
//                           //   final controller = Get.find<BottomBarController>();
//                           //   controller.onChangeBottomBar(4);
//                           // }
//                         },
//                         child: SizedBox(
//                           width: 50,
//                           child: Stack(
//                             alignment: Alignment.center,
//                             clipBehavior: Clip.none,
//                             children: [
//                               // RotationTransition(
//                               //     turns: _animation,
//                               //     child: LocalAssets(
//                               //         imagePath:
//                               //             AppIconAssets.musicOutlinedIcon)),
//                               RotationTransition(
//                                 turns: _animation,
//                                 child: Container(
//                                   width: 30,
//                                   clipBehavior: Clip.antiAlias,
//                                   decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.black28),
//                                   child: Stack(
//                                     alignment: Alignment.center,
//                                     children: [
//                                       LocalAssets(imagePath: AppIconAssets.profilesIcon),
//                                       NetWorkOcToAssets(imgUrl: controller.mainReels[widget.index].userImage),
//                                       Visibility(
//                                         visible: controller.mainReels[widget.index].isProfileImageBanned ?? false,
//                                         child: AspectRatio(
//                                           aspectRatio: 1,
//                                           child: Container(
//                                             clipBehavior: Clip.antiAlias,
//                                             decoration: BoxDecoration(shape: BoxShape.circle),
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 borderRadius: BorderRadius.circular(50),
//                                                 color: AppColors.white.withOpacity(0.3),
//                                               ),
//                                               child: Offstage(),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               // Positioned(
//                               //   right: 4,
//                               //   bottom: -4,
//                               //   child: LocalAssets(
//                               //       imagePath: AppIconAssets.musicOutlinedIcon,
//                               //       width: 20),
//                               // ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 left: 15,
//                 bottom: 20,
//                 child: SizedBox(
//                   height: 400,
//                   width: Get.width / 1.5,
//                   child: Align(
//                     alignment: Alignment.bottomLeft,
//                     child: SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           GestureDetector(
//                             onTap: () {
//                               // if (controller.mainReels[widget.index].userId != userId) {
//                               //   isReelsPage.value = false;
//                               //   PreviewProfileBottomSheetUi.show(
//                               //     context: context,
//                               //     userId: controller.mainReels[widget.index].userId ?? "",
//                               //   );
//                               // } else {
//                               //   isReelsPage.value = false;
//                               //   final controller = Get.find<BottomBarController>();
//                               //   controller.onChangeBottomBar(4);
//                               // }
//                             },
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   height: 46,
//                                   width: 46,
//                                   clipBehavior: Clip.antiAlias,
//                                   decoration: const BoxDecoration(shape: BoxShape.circle),
//                                   child: Stack(
//                                     children: [
//                                       AspectRatio(
//                                           aspectRatio: 1, child: LocalAssets(imagePath: AppIconAssets.profilesIcon)),
//                                       AspectRatio(
//                                           aspectRatio: 1,
//                                           child:
//                                               NetWorkOcToAssets(imgUrl: controller.mainReels[widget.index].userImage)),
//                                       Visibility(
//                                         visible: controller.mainReels[widget.index].isProfileImageBanned ?? false,
//                                         child: AspectRatio(
//                                           aspectRatio: 1,
//                                           child: Container(
//                                             clipBehavior: Clip.antiAlias,
//                                             decoration: BoxDecoration(shape: BoxShape.circle),
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 borderRadius: BorderRadius.circular(50),
//                                                 color: AppColors.white.withOpacity(0.3),
//                                               ),
//                                               child: Offstage(),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 10,
//                                 ),
//                                 Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     SizedBox(
//                                       width: Get.width / 2,
//                                       child: Row(
//                                         mainAxisAlignment: MainAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             maxLines: 1,
//                                             controller.mainReels[widget.index].name ?? "",
//                                             style: AppFontStyle.styleW600(AppColors.white, 16.5),
//                                           ),
//                                           // Visibility(
//                                           //   visible: controller.mainReels[widget.index].isVerified ?? false,
//                                           //   child: Padding(
//                                           //     padding: const EdgeInsets.only(left: 3),
//                                           //     child: LocalAssets(imagePath:AppIconAssets.tick, width: 20),
//                                           //   ),
//                                           // ),
//                                         ],
//                                       ),
//                                     ),
//                                     SizedBox(
//                                       width: Get.width / 2,
//                                       child: Text(
//                                         maxLines: 1,
//                                         controller.mainReels[widget.index].userName ?? "",
//                                         style: AppFontStyle.styleW500(AppColors.white, 13),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Visibility(
//                             visible: controller.mainReels[widget.index].caption?.trim().isNotEmpty ?? false,
//                             child: ReadMoreText(
//                               controller.mainReels[widget.index].caption ?? "",
//                               trimMode: TrimMode.Line,
//                               trimLines: 3,
//                               style: AppFontStyle.styleW500(AppColors.white, 13),
//                               colorClickableText: AppColors.primaryColor,
//                               trimCollapsedText: ' Show more',
//                               trimExpandedText: ' Show less',
//                               moreStyle: AppFontStyle.styleW500(AppColors.primaryColor, 13.5),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
