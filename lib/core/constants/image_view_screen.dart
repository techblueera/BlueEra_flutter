// import 'dart:developer';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
//
// class ImageViewScreen extends StatefulWidget {
//   final List<String> imageUrls;
//   final int initialIndex;
//   final String appBarTitle;
//
//   const ImageViewScreen({
//     super.key,
//     required this.imageUrls,
//     required this.initialIndex,
//     required this.appBarTitle,
//   });
//
//   @override
//   State<ImageViewScreen> createState() => _ImageViewScreenState();
// }
//
// class _ImageViewScreenState extends State<ImageViewScreen> {
//   late PageController _pageController;
//   final TransformationController _transformationController =
//       TransformationController();
//   final double _currentScale = 1.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: widget.initialIndex);
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _transformationController.dispose();
//     super.dispose();
//   }
//
//   // void _handleDoubleTap() {
//   //   setState(() {
//   //     if (_currentScale == 1.0) {
//   //       _currentScale = 3.0; // Zoom in level
//   //       _transformationController.value = Matrix4.identity()..scale(_currentScale);
//   //     } else {
//   //       _currentScale = 1.0; // Reset to default scale
//   //       _transformationController.value = Matrix4.identity();
//   //     }
//   //   });
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: true,
//         backgroundColor: Colors.white.withOpacity(0.1),
//         foregroundColor: Colors.white,
//         title: Text(widget.appBarTitle),
//       ),
//       backgroundColor: Colors.black,
//       body: widget.imageUrls.isEmpty ||
//               (widget.imageUrls.isNotEmpty && widget.imageUrls[0] == 'N/A')
//           ? Center(
//               child: Text(
//               'Not able to download',
//               style: TextStyle(
//                   fontSize: screenWidth(context) * 0.05,
//                   color: AppColors.redDF704D,
//                   fontWeight: FontWeight.w600),
//             ))
//           : PageView.builder(
//               controller: _pageController,
//               itemCount: widget.imageUrls.length,
//               itemBuilder: (context, index) {
//                 final imageUrl = widget.imageUrls[index];
//                 log("Dynamic Value: '$imageUrl'");
//
//                 return Center(
//                   child: imageUrl.endsWith('.jpg') ||
//                           imageUrl.endsWith('.jpeg') ||
//                           imageUrl.endsWith('.png')
//                       ? InteractiveViewer(
//                           panEnabled: true, // Enable panning
//                           transformationController: _transformationController,
//                           // boundaryMargin: const EdgeInsets.all(8),
//                           minScale: 1.0,
//                           maxScale: 5.0,
//                           child: Center(
//                             child: CachedNetworkImage(
//                               imageUrl: imageUrl,
//                               placeholder: (context, url) =>
//                                   const CircularProgressIndicator(),
//                               errorWidget: (context, url, error) =>
//                                   const Icon(Icons.error),
//                             ),
//                           ),
//                         )
//                       : PdfViewer(
//                           fileUrl: imageUrl,
//                           isSender: true,
//                           height: SizeConfig.screenHeight,
//                           width: SizeConfig.screenHeight,
//                           isThumbnail: false,
//                         ),
//                 );
//               },
//             ),
//     );
//   }
// }
