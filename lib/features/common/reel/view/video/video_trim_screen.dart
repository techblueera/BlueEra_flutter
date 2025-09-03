// import 'dart:developer';
// import 'dart:io';
// import 'dart:ui';
//
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/core/routes/route_constant.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_trimmer/video_trimmer.dart';
//
// class VideoTrimScreen extends StatefulWidget {
//   final String videoPath;
//   final VideoType videoType;
//   final String isFrom;
//   const VideoTrimScreen({required this.videoPath, required this.videoType, required this.isFrom});
//
//   @override
//   State<VideoTrimScreen> createState() => _VideoTrimScreenState();
// }
//
// class _VideoTrimScreenState extends State<VideoTrimScreen> with TickerProviderStateMixin {
//   final Trimmer _trimmer = Trimmer();
//   double _start = 0.0;
//   double _end = 0.0;
//   bool _isLoading = false;
//   bool _isVideoLoaded = false;
//   bool _isPlaying = false;
//   Duration _videoDuration = Duration.zero;
//   late AnimationController _playButtonController;
//   late AnimationController _loadingController;
//
//   @override
//   void initState() {
//     super.initState();
//     _playButtonController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _loadingController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat();
//     _loadVideo();
//   }
//
//   @override
//   void dispose() {
//     _trimmer.dispose();
//     _playButtonController.dispose();
//     _loadingController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadVideo() async {
//     try {
//       await _trimmer.loadVideo(videoFile: File(widget.videoPath));
//       _videoDuration = _trimmer.videoPlayerController?.value.duration ?? Duration.zero;
//       log("video duration--> ${_videoDuration.inSeconds}");
//
//       // Set initial values
//       final maxDuration = widget.videoType == VideoType.short
//           ? const Duration(seconds: 30)
//           : _videoDuration;
//
//       _end = (maxDuration.inMilliseconds < _videoDuration.inMilliseconds
//           ? maxDuration.inMilliseconds
//           : _videoDuration.inMilliseconds).toDouble();
//
//
//       setState(() {
//         _isVideoLoaded = true;
//       });
//     } catch (e) {
//       log("Error loading video: $e");
//       commonSnackBar(message: "Failed to load video");
//     }
//   }
//
//   void _togglePlayPause() {
//     setState(() {
//       _isPlaying = !_isPlaying;
//     });
//
//     if (_isPlaying) {
//       _playButtonController.forward();
//       _trimmer.videoPlayerController?.play();
//     } else {
//       _playButtonController.reverse();
//       _trimmer.videoPlayerController?.pause();
//     }
//   }
//
//   void _saveTrimmedVideo() async {
//     final trimmedDuration = Duration(milliseconds: (_end - _start).toInt());
//     log("trimmedDuration--> ${trimmedDuration.inSeconds}");
//
//     if (trimmedDuration > const Duration(seconds: 30)) {
//       commonSnackBar(message: "You can trim up to 30 seconds only.");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     _trimmer.saveTrimmedVideo(
//       startValue: _start,
//       endValue: _end,
//       onSave: (String? outputPath) async {
//         if (mounted) {
//           setState(() => _isLoading = false);
//         }
//
//         if (outputPath != null && context.mounted) {
//           log("Original trimmed path: $outputPath");
//
//           // ✅ Generate a safe file path
//           final Directory appDir = await getApplicationDocumentsDirectory();
//           final String safeFileName =
//               "trimmed_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '_')}.mp4";
//           final String safePath = "${appDir.path}/$safeFileName";
//
//           // ✅ Copy the trimmed file to the safe path
//           final File originalFile = File(outputPath);
//           final File renamedFile = await originalFile.copy(safePath);
//
//           log("✅ Renamed safe path: ${renamedFile.path}");
//
//           Future.delayed(const Duration(milliseconds: 200), () {
//             if (!context.mounted) return;
//
//             if (widget.isFrom == RouteConstant.HomeScreen ||
//                 widget.isFrom == RouteConstant.videoRecorderScreen) {
//               Navigator.pushReplacementNamed(
//                 context,
//                 RouteHelper.getFullVideoPreviewRoute(),
//                 arguments: {
//                   ApiKeys.videoType: widget.videoType,
//                   ApiKeys.videoPath: renamedFile.path,
//                 },
//               );
//             } else {
//               Navigator.pop(context, renamedFile.path);
//             }
//           });
//         }
//         else {
//           commonSnackBar(message: "Failed to trim video");
//         }
//       },
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         isLeading: true,
//         title: "Create Short Video",
//         isSaveButton: true,
//         onSavedTap: _isVideoLoaded && !_isLoading ? _saveTrimmedVideo : null,
//       ),
//       body: _isVideoLoaded
//           ? Stack(
//         children: [
//           Column(
//             children: [
//               // Video Preview Area
//               SizedBox(
//                 height: SizeConfig.screenHeight * 0.7,
//                 child: Container(
//                   width: double.infinity,
//                   color: AppColors.black,
//                   child: Stack(
//                     children: [
//                       VideoViewer(trimmer: _trimmer),
//
//                       // Play/Pause Overlay
//                       Align(
//                         alignment: Alignment.center,
//                         child: GestureDetector(
//                             behavior: HitTestBehavior.translucent,
//                             onTap: _togglePlayPause,
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(25.0),
//                               child: BackdropFilter(
//                                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                                 child: Container(
//                                   height: 60,
//                                   width: 60,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: Colors.white.withValues(alpha: 0.4),
//                                   ),
//                                   child: AnimatedBuilder(
//                                     animation: _playButtonController,
//                                     builder: (BuildContext context, Widget? child) {
//                                       return Icon(
//                                         _isPlaying ? Icons.pause : Icons.play_arrow,
//                                         size: 36,
//                                         color: Colors.white,
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ),
//                             )
//
//                         ),
//                       ),
//
//                       // Duration Info Overlay
//                       Positioned(
//                         top: 20,
//                         right: 20,
//                         child: Container(
//                           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withValues(alpha: 0.7),
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Text(
//                             formatDuration(_videoDuration),
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: SizeConfig.size20,
//                   vertical: SizeConfig.size20,
//                 ),
//                 child: TrimViewer(
//                   trimmer: _trimmer,
//                   viewerHeight: 50,
//                   durationTextStyle: TextStyle(color: AppColors.black),
//                   viewerWidth: MediaQuery.of(context).size.width,
//                   maxVideoLength: const Duration(seconds: 30),
//                   onChangeStart: (value) => _start = value,
//                   onChangeEnd: (value) => _end = value,
//                   onChangePlaybackState: (isPlaying) {
//                     // setState(() => _isPlaying = isPlaying);
//                   },
//                   editorProperties: TrimEditorProperties(
//                     borderPaintColor: AppColors.primaryColor,
//                     scrubberPaintColor: AppColors.primaryColor,
//                     circlePaintColor: Colors.white,
//                   ),
//                 ),
//               ),
//
//             ],
//           ),
//
//           // Loading Overlay
//           if (_isLoading)
//             Container(
//               color: Colors.black.withValues(alpha: 0.8),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     RotationTransition(
//                       turns: _loadingController,
//                       child: Container(
//                         width: 60,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               AppColors.primaryColor,
//                               AppColors.primaryColor.withValues(alpha: 0.3),
//                             ],
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.cut,
//                           color: Colors.white,
//                           size: 30,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       "Trimming video...",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       )
//           : Container(
//         color: Colors.black,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 color: AppColors.primaryColor,
//               ),
//               SizedBox(height: 20),
//               Text(
//                 "Loading video...",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }