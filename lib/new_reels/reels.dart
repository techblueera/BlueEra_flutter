// // ignore_for_file: camel_case_types, library_private_types_in_public_api
//
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import 'package:visibility_detector/visibility_detector.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
//
// class Android_VideoPlayerWidget extends StatefulWidget {
//   final  videoUrl;
//   final bool? autoplay;
//   final bool? from;
//
//   const Android_VideoPlayerWidget({
//     super.key,
//     required this.videoUrl,
//     this.autoplay,
//     this.from = false,
//   });
//
//   @override
//   _Android_VideoPlayerMaterialState createState() =>
//       _Android_VideoPlayerMaterialState();
// }
//
// class _Android_VideoPlayerMaterialState extends State<Android_VideoPlayerWidget>
//     with WidgetsBindingObserver {
//   VideoPlayerController? _videoPlayerController;
//   ChewieController? _chewieController;
//   bool _videoInitialized = false;
//   bool _isVisible = false;
//   static const double _visibilityThreshold = 0.8;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializePlayer();
//   }
//
//   Future<void> _initializePlayer() async {
//   try {
//     var fileInfo = await kCacheManager.getFileFromCache(widget.videoUrl);
//
//     if (fileInfo != null) {
//       // Cache la file irundha direct use pannu
//       _videoPlayerController = VideoPlayerController.file(fileInfo.file);
//     } else {
//       // Illa na → seekirama play panna network la irundhu
//       _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
//       // Cache background la start aagattum
//       kCacheManager.downloadFile(widget.videoUrl);
//     }
//
//     await _videoPlayerController!.initialize();
//     await _setVolumeFromPrefs();
//
//     if (mounted) {
//       setState(() {
//         _videoInitialized = true;
//         _initializeChewieController();
//       });
//     }
//   } catch (e) {
//     debugPrint("Error initializing video: $e");
//     if (mounted) {
//       setState(() => _videoInitialized = false);
//     }
//   }
// }
//
//
//   void _initializeChewieController() {
//     if (_videoPlayerController == null) return;
//
//     _chewieController = ChewieController(
//       videoPlayerController: _videoPlayerController!,
//       autoPlay: widget.autoplay ?? false,
//       looping: false,
//       aspectRatio: _videoPlayerController!.value.aspectRatio,
//       allowFullScreen: true,
//       allowMuting: true,
//       showControls: true,
//       showOptions: true,
//       showControlsOnInitialize: true,
//       placeholder: Container(
//         color: Colors.black,
//         child: const Center(child: CircularProgressIndicator()),
//       ),
//       materialProgressColors: ChewieProgressColors(
//         backgroundColor: Colors.white24,
//         bufferedColor: Colors.white54,
//       ),
//       deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
//       deviceOrientationsOnEnterFullScreen: [
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ],
//     );
//
//     // Add listener for volume changes
//     _videoPlayerController!.addListener(_handleVolumeChange);
//   }
//
//   void _handleVolumeChange() {
//     if (!mounted) return;
//
//     final volume = _videoPlayerController!.value.volume;
//     SharedPreferences.getInstance().then((prefs) {
//       prefs.setDouble("volumn", volume);
//     });
//   }
//
//   Future<void> _setVolumeFromPrefs() async {
//     if (!mounted || _videoPlayerController == null) {
//       return;
//     }
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final volume = prefs.getDouble("volumn") ?? 0.0;
//       await _videoPlayerController!.setVolume(volume);
//     } catch (e) {
//       debugPrint('Error setting volume: $e');
//       await _videoPlayerController!.setVolume(0.0);
//     }
//   }
//
//   void _handleVisibilityChange(VisibilityInfo info) {
//     if (!mounted) return;
//
//     final isVisible = info.visibleFraction > _visibilityThreshold;
//     if (_isVisible == isVisible) return;
//
//     _isVisible = isVisible;
//
//     if (isVisible) {
//       if (widget.autoplay ?? false) {
//         _videoPlayerController?.play();
//         _setVolumeFromPrefs();
//       }
//     } else {
//       _videoPlayerController?.pause();
//       _videoPlayerController?.setVolume(0.0);
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!_videoInitialized) return;
//
//     switch (state) {
//       case AppLifecycleState.resumed:
//         if (_isVisible) {
//           _videoPlayerController?.play();
//         }
//         break;
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.paused:
//         _videoPlayerController?.pause();
//         break;
//       case AppLifecycleState.detached:
//       case AppLifecycleState.hidden:
//         break;
//     }
//   }
//
//   @override
//   void dispose() {
//     _videoPlayerController?.removeListener(_handleVolumeChange);
//     _videoPlayerController?.pause();
//     _videoPlayerController?.dispose();
//     _chewieController?.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("VideoUrl: ${widget.videoUrl}");
//     if (!_videoInitialized || _videoPlayerController == null) {
//       return Center(
//         child: SizedBox(
//           height: MediaQuery.of(context).size.width,
//           width: MediaQuery.of(context).size.width / 1.1,
//           child: widget.from == true ? const SizedBox() : const Center(child: CircularProgressIndicator()),
//         ),
//       );
//     }
//
//     return VisibilityDetector(
//       key: Key("${widget.key ?? widget.videoUrl}"),
//       onVisibilityChanged: _handleVisibilityChange,
//       child: AspectRatio(
//         aspectRatio: _videoPlayerController!.value.aspectRatio,
//         child: Chewie(controller: _chewieController!),
//       ),
//     );
//   }
// }
//
// const kReelCacheKey = "reelsCacheKey";
// final kCacheManager = CacheManager(
//   Config(
//     kReelCacheKey,
//     stalePeriod: const Duration(days: 1),
//     maxNrOfCacheObjects: 10,
//     repo: JsonCacheInfoRepository(databaseName: kReelCacheKey),
//     fileService: HttpFileService(),
//   ),
// );
