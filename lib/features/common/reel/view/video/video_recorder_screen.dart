import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoReelRecorderScreen extends StatefulWidget {
    final PostVia? postVia;
    const VideoReelRecorderScreen({this.postVia});

    @override
    State<VideoReelRecorderScreen> createState() => _VideoReelRecorderScreenState();
}

class _VideoReelRecorderScreenState extends State<VideoReelRecorderScreen> with SingleTickerProviderStateMixin {
    late CameraController _controller;
    late Future<void> _initializeControllerFuture;

    bool _isRecording = false;
    bool _isPaused = false;
    int _selectedDuration = 5;
    Timer? _timer;
    Duration _duration = Duration.zero;
    XFile? _videoFile;
    bool _isToggling = false;
    bool _hasPermission = false;

    @override
    void initState() {
      super.initState();
      _initializeControllerFuture = _setupCamera();
    }

    Future<void> _setupCamera() async {
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      _hasPermission = cameraStatus.isGranted && micStatus.isGranted;
      if (!_hasPermission) return; // stop here if no permission

      try {
        cameras = await availableCameras();
        if (cameras.isEmpty) throw Exception("No cameras found");

        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );

        await _controller.initialize();
      } catch (e) {
        throw Exception("Camera initialization failed: $e");
      }
    }

    // Future<void> _setupCamera() async {
    //   final cameraStatus = await Permission.camera.request();
    //   final micStatus = await Permission.microphone.request();
    //
    //   if (!cameraStatus.isGranted || !micStatus.isGranted) {
    //     throw Exception("Camera and microphone permissions are required.");
    //   }
    //
    //   try {
    //     cameras = await availableCameras();
    //     if (cameras.isEmpty) throw Exception("No cameras found");
    //
    //     _controller = CameraController(
    //       cameras.first,
    //       ResolutionPreset.medium,
    //       enableAudio: true,
    //     );
    //
    //     await _controller.initialize();
    //   } catch (e) {
    //     throw Exception("Camera initialization failed: $e");
    //   }
    // }

    @override
    void dispose() {
      _controller.dispose();
      _timer?.cancel();
      super.dispose();
    }

    Future<void> _toggleRecording() async {
      if (_isToggling) return;
      _isToggling = true;

      try {
        if (_isRecording) {
          await _stopRecording(autoNavigate: false); // manual pause → show button
        } else {
          await _startRecording();
        }
      } finally {
        _isToggling = false;
      }
    }

    Future<void> _startRecording() async {
      try {
        await _controller.prepareForVideoRecording();
        await _controller.startVideoRecording();

        if (!mounted) return;
        setState(() {
          _isRecording = true;
          _duration = Duration.zero;
          _isPaused = false;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (!mounted) return;
          setState(() => _duration += const Duration(seconds: 1));

          if (_duration.inSeconds >= _selectedDuration) {
            timer.cancel();
            await _stopRecording(autoNavigate: true); // ✅ auto-navigate to preview
          }
        });
      } catch (e) {
        debugPrint("Error starting recording: $e");
      }
    }

    Future<void> _stopRecording({required bool autoNavigate}) async {
      try {
        if (_controller.value.isInitialized && _controller.value.isRecordingVideo) {
          final file = await _controller.stopVideoRecording();
          _timer?.cancel();

          if (!mounted) return;
          setState(() {
            _isRecording = false;
            _isPaused = !autoNavigate;
            _videoFile = file;
          });

          if (autoNavigate) {
            _goToPreview();
          }
        }
      } catch (e) {
        debugPrint("Error stopping recording: $e");
      }
    }

    Future<void> _goToPreview() async {
      if (_videoFile != null) {
        final safePath = await prepareVideoFile(File(_videoFile!.path));
        print("Recording path: $safePath");
        Navigator.pushNamed(
          context,
          RouteHelper.getFullVideoPreviewRoute(),
          arguments: {
            ApiKeys.videoPath: safePath,
            ApiKeys.argPostVia: widget.postVia
          },
        );

        // Navigator.pushNamed(
        //   context,
        //   RouteHelper.getVideoTrimScreenRoute(),
        //   arguments: {
        //     ApiKeys.videoPath: safePath,
        //     ApiKeys.isFrom: RouteConstant.videoRecorderScreen
        //   },
        // );

      }
    }

    Future<String> prepareVideoFile(File file) async {
      final directory = await getTemporaryDirectory();
      final newPath = path.join(directory.path, "${DateTime.now().millisecondsSinceEpoch}.mp4");
      final newFile = await File(file.path).copy(newPath);
      return newFile.path;
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              // If permission denied, show retry option
              final errorMessage = snapshot.error.toString();
              if (errorMessage.contains("permissions")) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Camera & microphone permissions are required.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _initializeControllerFuture = _setupCamera();
                          });
                        },
                        child: const Text("Grant Permission"),
                      )
                    ],
                  ),
                );
              }
              return Center(child: Text('Camera error: $errorMessage'));
            }

            // ✅ If no permission, don't build camera
            if (!_hasPermission || !_controller.value.isInitialized) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Camera not available."),
                    const SizedBox(height: 16),
                    CommonIconContainerButton(
                      width: SizeConfig.size120,
                      icon: Icon(Icons.refresh, color: AppColors.white),
                      onTap: (){
                        setState(() {
                          _initializeControllerFuture = _setupCamera();
                        });
                      },
                      label: 'Try Again',
                      textColor: AppColors.white,
                    ),
                  ],
                ),
              );
            }

            // ✅ Safe: controller is initialized here
            return Stack(
              fit: StackFit.expand,
              children: [
                SizedBox(
                  height: _controller.value.previewSize?.height,
                  width: _controller.value.previewSize?.width,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),

                // Timer Display
                if (_isRecording || _isPaused)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatDuration(_duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Preview Button
                if (_isPaused && _videoFile != null) ...[
                  Align(
                    alignment: Alignment.topCenter,
                    child: InkWell(
                      onTap: _goToPreview,
                      child: Container(
                        margin: const EdgeInsets.only(top: 40.0),
                        padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.size6,
                          horizontal: SizeConfig.size12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill,
                                  color: AppColors.white, size: SizeConfig.size14),
                              SizedBox(width: SizeConfig.size2),
                              CustomText('Preview', color: AppColors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Bottom Controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Duration selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [5, 10, 15, 30].map((sec) {
                            final isSelected = _selectedDuration == sec;
                            return GestureDetector(
                              onTap: () {
                                if (!_isRecording) {
                                  setState(() => _selectedDuration = sec);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.transparent),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black25,
                                      spreadRadius: 0,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text('$sec sec',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Record Button
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          height: 76,
                          width: 76,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? AppColors.red
                                : AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6.0),
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
}
