// import 'dart:io';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/video_recorder_screen.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';
//
// class SelfIntroVideoUpload extends StatefulWidget {
//   const SelfIntroVideoUpload({super.key});
//
//   @override
//   State<SelfIntroVideoUpload> createState() => _SelfIntroVideoUploadState();
// }
//
// class _SelfIntroVideoUploadState extends State<SelfIntroVideoUpload> {
//   final ImagePicker _picker = ImagePicker();
//   File? _selectedVideo;
//   File? _selectedImage;
//
//   VideoPlayerController? _videoController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         title: AppLocalizations.of(context)!.postYourVideo,
//         onBackTap: () {
//           Navigator.pop(context);
//
//           // Navigator.pushReplacementNamed(
//           //     context,
//           //     MaterialPageRoute(
//           //         builder: (context) =>  ProfileSetupScreen(
//           //             )));
//         },
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.only(
//                 bottom: SizeConfig.size10,
//                 left: SizeConfig.size20,
//                 right: SizeConfig.size20,
//                 top: SizeConfig.size20),
//             child: GestureDetector(
//               onTap: () => _navigateToVideoRecorder(),
//               child: Container(
//                 height: 200,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: AppColors.black28,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: _selectedVideo != null &&
//                     _videoController != null &&
//                     _videoController!.value.isInitialized
//                     ? ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: AspectRatio(
//                     aspectRatio: _videoController!.value.aspectRatio,
//                     child: VideoPlayer(_videoController!),
//                   ),
//                 )
//                     : Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.image, size: 50, color: Colors.grey),
//                     SizedBox(height: SizeConfig.size10),
//                     Text(
//                         AppLocalizations.of(context)!.uploadYourVideo,
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: SizeConfig.medium)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(
//                 horizontal: SizeConfig.size20, vertical: SizeConfig.size20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Container(
//                   height: SizeConfig.size45,
//                   width: SizeConfig.size45,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.grey),
//                   ),
//                   child: _selectedImage != null
//                       ? ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.file(
//                       _selectedImage!,
//                       fit: BoxFit.cover,
//                     ),
//                   )
//                       : Icon(
//                     Icons.image_outlined,
//                     size: 50,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 SizedBox(
//                   width: SizeConfig.size20,
//                 ),
//                 Expanded(
//                   child: Container(
//                     constraints: BoxConstraints(maxWidth: 200),
//                     height: SizeConfig.size45,
//                     // Ensure same height as the container
//                     child: ElevatedButton(
//                       onPressed: () => _pickMedia(false),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.black28,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(
//                             horizontal: SizeConfig.size20,
//                             vertical: SizeConfig.size10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.cloud_upload_outlined,
//                             size: 20,
//                           ),
//                           SizedBox(width: SizeConfig.size10),
//                           Expanded(
//                             child: CustomText(
//                               AppLocalizations.of(context)!.pickThumbnail,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: SizeConfig.size10),
//           Padding(
//             padding: EdgeInsets.all(SizeConfig.size15),
//             child: PositiveCustomBtn(
//               title: AppLocalizations.of(context)!.save,
//               onTap: () {
//                 Navigator.pop(context);
//
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickMedia(bool isVideo) async {
//     final XFile? pickedFile = isVideo
//         ? await _picker.pickVideo(source: ImageSource.gallery)
//         : await _picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         if (isVideo) {
//           _selectedVideo = File(pickedFile.path);
//           _videoController?.dispose();
//           _videoController = VideoPlayerController.file(_selectedVideo!)
//             ..initialize().then((_) {
//               setState(() {});
//               _videoController!.play();
//             });
//         } else {
//           _selectedImage = File(pickedFile.path);
//         }
//         // _checkFormValid();
//       });
//     }
//   }
//
//   void _navigateToVideoRecorder() async {
//     final String? recordedVideoPath = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => VideoRecorderScreen()),
//     );
//
//     if (recordedVideoPath != null) {
//       try {
//         // Get app's storage directory
//         final directory = await getApplicationDocumentsDirectory();
//         final savedVideoPath =
//             '${directory.path}/recorded_video${DateTime.now().millisecondsSinceEpoch}.mp4';
//
//         // Copy the recorded video to the storage directory
//         final savedVideoFile = File(savedVideoPath);
//         await File(recordedVideoPath).copy(savedVideoPath);
//
//         print("Video saved at: $savedVideoPath");
//
//         setState(() {
//           _selectedVideo = savedVideoFile;
//           _videoController?.dispose();
//           _videoController = VideoPlayerController.file(_selectedVideo!)
//             ..initialize().then((_) {
//               setState(() {});
//               _videoController!.play();
//             });
//         });
//       } catch (e) {
//         print("Error saving video: $e");
//       }
//     }
//   }
// }
