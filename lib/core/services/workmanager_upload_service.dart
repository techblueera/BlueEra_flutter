import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/video_compreesion_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:flutter/material.dart';

// Task names
const String videoUploadTask = 'videoUploadTask';

// Callback dispatcher that will be called by workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // check if retried before
    // final alreadyRetried =await SharedPreferenceUtils.getAlreadyRetriedSecureValue();

    try {
      switch (taskName) {
        case videoUploadTask:
          return await _handleVideoUpload(inputData!);
        default:
          return Future.value(false);
      }
    } catch (e) {
      print('Error in background task: $e');
      await Workmanager().cancelAll();

      return Future.value(false);
    }
  });
}

// Handle video upload in background
Future<bool> _handleVideoUpload(Map<String, dynamic> inputData) async {
  try {
    final workManagerBaseUrl=await SharedPreferenceUtils.getBaseUrlSecureValue();
    // logs("workManagerBaseUrl===== $workManagerBaseUrl");
    dynamic raw = inputData['requestData'];

    late Map<String, dynamic> requestData;

    if (raw is String) {
      requestData = jsonDecode(raw);
    } else if (raw is Map) {
      requestData = Map<String, dynamic>.from(raw);
    }
    // Extract data from input
    final String videoPath = inputData['videoPath'];
    final String coverPath = inputData['coverPath'];

    // Upload video and cover to S3
    final videoFile = File(videoPath);
    final coverFile = File(coverPath);

    final videoInfo = _getFileInfo(videoFile);
    final coverInfo = _getFileInfo(coverFile);

    // Init video upload
    final videoInitResponse = await ChannelRepo().workmanagerUploadInit(
      url:
          "$workManagerBaseUrl$initUpload",
      queryParams: {
        ApiKeys.fileName: videoInfo['fileName'],
        ApiKeys.fileType: videoInfo['mimeType']
      },
      // isVideoUpload: true,
    );

    // Init cover upload
    final coverInitResponse = await ChannelRepo().workmanagerUploadInit(
      url:
          "$workManagerBaseUrl$initUpload",
      queryParams: {
        ApiKeys.fileName: coverInfo['fileName'],
        ApiKeys.fileType: coverInfo['mimeType']
      },
    );
    if (videoFile.path.isNotEmpty) {
      final compressedFile =
          await VideoCompressionService.compressVideo(videoPath);
      final videoFile =
          compressedFile ?? File(videoPath); // fallback if compression fails
      // Upload files to S3
      await ChannelRepo().uploadVideoToS3(
        file: videoFile,
        fileType: videoInfo['mimeType']!,
        preSignedUrl: videoInitResponse?.response?.data['uploadUrl']!,
        onProgress: (sent) {},
      );
    }
    await ChannelRepo().uploadVideoToS3(
      file: coverFile,
      fileType: coverInfo['mimeType']!,
      preSignedUrl: coverInitResponse?.response?.data['uploadUrl'] ?? '',
      onProgress: (sent) {},
    );

    // Update request data with uploaded file information
    requestData['videoUrl'] =
        videoInitResponse?.response?.data['publicUrl'] ?? '';
    requestData['videoKey'] =
        videoInitResponse?.response?.data['fileKey'] ?? '';
    requestData['coverUrl'] =
        coverInitResponse?.response?.data['publicUrl'] ?? '';
    final response = await ChannelRepo().workManagerUploadVideo(
        bodyRequest: requestData,
        url:
            "${workManagerBaseUrl}video-service/videos/upload");

    return response?.isSuccess ?? false;
  } catch (e) {
    await Workmanager().cancelAll();
    print('Error in _handleVideoUpload: $e');
    return false;
  }
}

// Helper function to get file info
Map<String, String> _getFileInfo(File file) {
  final String fileName = file.path.split('/').last;
  final String extension = fileName.split('.').last.toLowerCase();
  String mimeType;

  if (extension == 'mp4' || extension == 'mov') {
    mimeType = 'video/$extension';
  } else if (extension == 'jpg' || extension == 'jpeg') {
    mimeType = 'image/jpeg';
  } else if (extension == 'png') {
    mimeType = 'image/png';
  } else {
    mimeType = 'application/octet-stream';
  }

  return {
    'fileName': fileName,
    'mimeType': mimeType,
  };
}

class WorkmanagerUploadService {
  // Initialize workmanager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  // Start video upload in background
  static Future<void> startVideoUpload({
    required String videoPath,
    required String coverPath,
    required Map<String, dynamic> requestData,
    required bool isLongVideo,
  }) async {
    try {
      final uniqueName =
          'video_upload_${DateTime.now().millisecondsSinceEpoch}';

      var dataReq = {
        'videoPath': videoPath,
        'coverPath': coverPath,
        'requestData': jsonEncode(requestData),
        'isLongVideo': isLongVideo,
        'taskId': uniqueName,
      };
      // logs("DATA REQ === ${dataReq}");
      await Workmanager().registerOneOffTask(
        uniqueName,
        videoUploadTask,
        inputData: dataReq,
        existingWorkPolicy: ExistingWorkPolicy.append,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(hours: 24),
      );

      // Show notification to user
      commonSnackBar(message: 'Your video will be uploaded in the background. You will be notified when it completes.');
      // Get.snackbar(
      //   'Video Upload',
      //   'Your video will be uploaded in the background. You will be notified when it completes.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.white,
      //   colorText: Colors.black,
      //   duration: const Duration(seconds: 3),
      // );
    } catch (e) {
      print('Error starting background upload: $e');
      commonSnackBar(message: 'Failed to start background upload');
    }
  }
}
