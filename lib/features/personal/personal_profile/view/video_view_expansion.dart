// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/self_intro_video_upload.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_tile_widget.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
//
// class VideoViewExpansion extends StatefulWidget {
//   final String thumbImage, videoLink;
//   final bool isVisitorProfile;
//
//   const VideoViewExpansion(
//       {super.key,
//       required this.thumbImage,
//       required this.videoLink,
//       this.isVisitorProfile = false, required videoUrl});
//
//   @override
//   State<VideoViewExpansion> createState() => _VideoViewExpansionState();
// }
//
// class _VideoViewExpansionState extends State<VideoViewExpansion> {
//   late VideoPlayerController _controller;
//   bool _isVideoInitialized = false;
//   bool _isThumbnailFailed = false;
//   bool _isVideoFailed = false;
//   bool _isCheckingThumbnail = true;
//   bool _isVideoPlaying = false;
//   bool _isVideoEnded = false;
//   bool isExpand = false;
//   bool isMoreClick = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }
//
//   void _onPlayPausePressed() {
//     if (_isVideoEnded) {
//       _controller.seekTo(Duration.zero); // rewind
//       _controller.play();
//       if (mounted) {
//         setState(() {
//           _isVideoPlaying = true;
//           _isVideoEnded = false;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           if (_controller.value.isPlaying) {
//             _controller.pause();
//             setState(() {
//               _isVideoEnded = true;
//               _isVideoPlaying = false;
//             });
//           } else {
//             setState(() {
//               _isVideoPlaying = true;
//
//               _isVideoEnded = false;
//             });
//             _controller.play();
//           }
//         });
//       }
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isCheckingThumbnail && widget.thumbImage.isNotEmpty) {
//       _checkThumbnail();
//     } else {
//       _initializeVideo();
//     }
//   }
//
//   void _checkThumbnail() {
//     precacheImage(NetworkImage(widget.thumbImage), context).then((_) {
//       if (mounted) {
//         setState(() {
//           _isThumbnailFailed = false;
//           _isCheckingThumbnail = false;
//         });
//       }
//     }).catchError((_) {
//       if (mounted) {
//         setState(() {
//           _isThumbnailFailed = true;
//           _isCheckingThumbnail = false;
//         });
//       }
//       _initializeVideo();
//     });
//   }
//
//   void _initializeVideo() {
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoLink))
//       ..initialize().then((_) {
//         // if (mounted) {
//         //   _playCurrentVideo();
//         // }
//         if (mounted) {
//           setState(() {
//             _isVideoInitialized = true;
//           });
//         }
//       }).catchError((_) {
//         if (mounted) {
//           setState(() {
//             _isVideoFailed = true;
//           });
//         }
//       });
//     _controller.addListener(() {
//       final position = _controller.value.position;
//       final duration = _controller.value.duration;
//
//       // Reset _isVideoEnded if user rewinds or seeks
//       if (_isVideoEnded && position < duration) {
//         if (mounted) {
//           setState(() {
//             _isVideoEnded = false;
//             _isVideoPlaying = true;
//           });
//         }
//       }
//
//       // Detect video end
//       if (position >= duration && !_controller.value.isPlaying) {
//         if (mounted) {
//           setState(() {
//             _isVideoEnded = true;
//             _isVideoPlaying = false;
//           });
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalization = AppLocalizations.of(context);
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
//       padding: (widget.videoLink.isEmpty && widget.isVisitorProfile)
//           ? null
//           : EdgeInsets.symmetric(vertical: SizeConfig.size5),
//       decoration: BoxDecoration(
//         color: AppColors.black28,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: widget.videoLink.isEmpty
//           ? (!widget.isVisitorProfile)
//               ? InkWell(
//                   onTap: () {
//                     Get.to(SelfIntroVideoUpload());
//                   },
//                   child: profileListTile(
//                       iconPath: AppIconAssets.video_outline,
//                       title: appLocalization?.uploadIntroductionVideo),
//                 )
//               : SizedBox()
//           : Theme(
//               data: ThemeData().copyWith(dividerColor: Colors.transparent),
//               child: ExpansionTile(
//                 backgroundColor: Colors.transparent,
//                 collapsedBackgroundColor: Colors.transparent,
//                 iconColor: Colors.white,
//                 // backgroundColor: AppColors.blackColor3,collapsedBackgroundColor: AppColors.blackColor3,
//                 onExpansionChanged: (value) {
//                   isExpand = value;
//                   setState(() {});
//                 },
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     if (widget.videoLink.isNotEmpty)
//                       Icon(
//                         Icons.check_circle,
//                         color: AppColors.primaryColor,
//                       ),
//                     Icon(
//                       !isExpand
//                           ? Icons.keyboard_arrow_down_rounded
//                           : Icons.keyboard_arrow_up,
//                       color: AppColors.primaryColor,
//                     ),
//                   ],
//                 ),
//                 leading: CircleAvatar(
//                   backgroundColor: AppColors.blue3F,
//                   child: SvgPicture.asset(AppIconAssets.video_outline),
//                 ),
//                 title: CustomText(
//                   appLocalization?.uploadIntroductionVideo,
//                 ),
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8.0),
//                     decoration:
//                         BoxDecoration(borderRadius: BorderRadius.circular(20)),
//                     height: SizeConfig.size250,
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         if (!_isThumbnailFailed &&
//                             widget.thumbImage.isNotEmpty &&
//                             _isVideoPlaying == false)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.network(
//                               widget.thumbImage,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) {
//                                 _initializeVideo();
//                                 return SizedBox();
//                               },
//                             ),
//                           )
//                         else if (!_isVideoFailed &&
//                             _isVideoInitialized &&
//                             _isVideoPlaying)
//                           InkWell(
//                             onTap: _onPlayPausePressed,
//                             child: FittedBox(
//                               fit: BoxFit.cover,
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: SizedBox(
//                                   width: SizeConfig.size400,
//                                   height: SizeConfig.size300,
//                                   child: VideoPlayer(_controller),
//                                 ),
//                               ),
//                             ),
//                           )
//                         else if (_isVideoFailed)
//                           Center(
//                             child: CustomText(
//                                 AppLocalizations.of(context)!.failed,
//                                 color: Colors.red,
//                                 fontSize: SizeConfig.large),
//                           )
//                         else
//                           Center(child: CircularProgressIndicator()),
//                         if (!_isVideoPlaying)
//                           Center(
//                             child: Container(
//                               height: SizeConfig.size50,
//                               width: SizeConfig.size50,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: AppColors.primaryColor.withOpacity(.5),
//                               ),
//                               child: GestureDetector(
//                                 onTap: _onPlayPausePressed,
//                                 child: Icon(
//                                   _isVideoPlaying
//                                       ? Icons.pause
//                                       : Icons.play_arrow,
//                                   color: AppColors.white,
//                                   size: 50,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         if (_isVideoPlaying) _buildProgressIndicator(),
//                         if (!_isVideoPlaying)
//                           Positioned(
//                             right: SizeConfig.size10,
//                             top: SizeConfig.size10,
//                             child: PopupMenuButton<String>(
//                               onSelected: _onPopupMenuSelected,
//                               icon: Icon(Icons.more_vert, color: Colors.white),
//                               color: Colors.grey[850],
//                               // da
//                               padding: EdgeInsets.zero,
//                               // rk background to match your design
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               menuPadding: EdgeInsets.zero,
//                               itemBuilder: (BuildContext context) =>
//                                   <PopupMenuEntry<String>>[
//                                 PopupMenuItem<String>(
//                                   value: 'delete',
//                                   child: CustomText(
//                                     appLocalization?.deleteVideo,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             ),
//     );
//   }
//
//   void _onPopupMenuSelected(String value) {
//     if (value == 'delete') {
//
//       commonSnackBar(message: "Video deleted");
//     }
//   }
//
//   Widget _buildProgressIndicator() {
//     return Positioned(
//       bottom: 5,
//       left: 0,
//       right: 0,
//       child: _controller.value.isInitialized
//           ? Padding(
//               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
//               child: VideoProgressIndicator(
//                 _controller,
//                 allowScrubbing: true,
//                 colors: VideoProgressColors(
//                   playedColor: Colors.red,
//                   bufferedColor: Colors.white54,
//                   backgroundColor: Colors.white30,
//                 ),
//               ),
//             )
//           : const SizedBox.shrink(),
//     );
//   }
// }
