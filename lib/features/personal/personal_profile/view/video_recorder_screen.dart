// import 'dart:async';
// import 'dart:io';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class VideoRecorderScreen extends StatefulWidget {
//   const VideoRecorderScreen({super.key});
//
//   @override
//   _VideoRecorderScreenState createState() => _VideoRecorderScreenState();
// }
//
// class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isRecording = false;
//   bool _isAudioEnabled = true;
//   bool _isFlashOn = false;
//   File? _selectedVideo;
//   int _recordDuration = 0;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     if (_cameras != null && _cameras!.isNotEmpty) {
//       _cameraController = CameraController(_cameras![0], ResolutionPreset.high,
//           enableAudio: _isAudioEnabled);
//       await _cameraController!.initialize();
//       setState(() {});
//     }
//   }
//
//   void _toggleRecording() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }
//     if (_isRecording) {
//       XFile videoFile = await _cameraController!.stopVideoRecording();
//       _selectedVideo = File(videoFile.path);
//       _timer?.cancel();
//     } else {
//       await _cameraController!.startVideoRecording();
//       _recordDuration = 0;
//       _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//         setState(() {
//           _recordDuration++;
//         });
//       });
//     }
//     setState(() {
//       _isRecording = !_isRecording;
//     });
//   }
//
//   void _toggleFlash() {
//     if (_cameraController == null) return;
//     _isFlashOn = !_isFlashOn;
//     _cameraController!
//         .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
//     setState(() {});
//   }
//
//   void _toggleAudio() {
//     _isAudioEnabled = !_isAudioEnabled;
//     _initializeCamera(); // Reinitialize camera with updated audio setting
//   }
//
//   Future<void> _pickVideoFromGallery() async {
//     final pickedFile =
//         await ImagePicker().pickVideo(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedVideo = File(pickedFile.path);
//       });
//     }
//   }
//
//   String _formatDuration(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final secs = (seconds % 60).toString().padLeft(2, '0');
//     return "$minutes:$secs";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             _cameraController != null && _cameraController!.value.isInitialized
//                 ? Positioned.fill(
//                     child: CameraPreview(_cameraController!),
//                   )
//                 : Center(child: CircularProgressIndicator()),
//             Positioned(
//               top: SizeConfig.size20,
//               left:SizeConfig.size10,
//               child: Container(
//                 padding: EdgeInsets.all(SizeConfig.paddingXSmall),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: AppColors.black28,
//                 ),
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Icon(Icons.close, color: Colors.white),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: SizeConfig.size20,
//               right:SizeConfig.size10,
//               child: Container(
//                 padding: EdgeInsets.all(SizeConfig.paddingXSmall),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: AppColors.black28,
//                 ),
//                 child: GestureDetector(
//                   onTap: _toggleFlash,
//                   child: Icon(
//                     _isFlashOn ? Icons.flash_on : Icons.flash_off,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         margin: EdgeInsets.all(SizeConfig.paddingXSL),
//                         padding: EdgeInsets.all(SizeConfig.paddingXSmall),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.black28,
//                         ),
//                         child: GestureDetector(
//                           onTap: _toggleAudio,
//                           child: Icon(
//                             _isAudioEnabled
//                                 ? Icons.volume_up_outlined
//                                 : Icons.volume_off_outlined,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       if (_selectedVideo != null)
//                         Container(
//                           margin: EdgeInsets.all(SizeConfig.paddingXSL),
//                           padding: EdgeInsets.all(SizeConfig.paddingXSmall),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: AppColors.black28,
//                           ),
//                           child: GestureDetector(
//                             onTap: () {
//                               Navigator.pop(context, _selectedVideo!.path);
//                             },
//                             child: Icon(
//                               Icons.check,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   Container(
//                     padding:
//                         EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size10),
//                     decoration: BoxDecoration(
//                         color: AppColors.black28,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(20),
//                           topRight: Radius.circular(20),
//                         )),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(SizeConfig.paddingXSmall),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: AppColors.black28,
//                           ),
//                           child: GestureDetector(
//                             onTap: _pickVideoFromGallery,
//                             child:
//                                 Icon(Icons.photo_outlined, color: Colors.white),
//                           ),
//                         ),
//                         Column(
//                           children: [
//                             GestureDetector(
//                               onTap: _toggleRecording,
//                               child: Container(
//                                 width: SizeConfig.size55,
//                                 height: SizeConfig.size55,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   border:
//                                       Border.all(color: Colors.red, width: 3),
//                                 ),
//                                 child: Center(
//                                   child: Icon(
//                                     _isRecording ? Icons.stop : Icons.circle,
//                                     color: Colors.red,
//                                     size: SizeConfig.size40,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.only(top: 5),
//                               child: CustomText(
//                                 _isRecording
//                                     ? _formatDuration(_recordDuration)
//                                     : "00:00",
//                               ),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           padding: EdgeInsets.all(5),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: AppColors.black28,
//                           ),
//                           child: GestureDetector(
//                             onTap: _initializeCamera,
//                             child: Icon(Icons.refresh, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }
// }
