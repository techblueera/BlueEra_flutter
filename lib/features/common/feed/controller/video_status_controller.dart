import 'dart:async';
import 'package:BlueEra/core/api/model/video_status_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/widget/upload_dialog.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';

class VideoStatusController extends GetxController {
  Rx<VideoStatusModel> videoStatus = VideoStatusModel().obs;
  Timer? countdownTimer;
  RxInt remainingSeconds = 0.obs;

  /// Fetch video upload status
  Future<void> getVideoStatus(BuildContext context, PostCreationMenu param) async {
    try {
      final response = await ChannelRepo().getVideoStatus();

      if (response.isSuccess) {
        final data = VideoStatusModel.fromJson(response.response?.data);
        videoStatus.value = data;

        if (data.canUpload == true) {
          postVia(context, param);

          // commonSnackBar(message: "You can upload a video now!");
        } else {
          _startCountdownDialog(data);
        }
      } else {
        commonSnackBar(message: response.message ?? "Something went wrong");
      }
    } catch (e) {
      commonSnackBar(message: "Error while checking video status");
    }
  }

  /// Open dialog and start countdown
  void _startCountdownDialog(VideoStatusModel data) {
    final totalSeconds =
        (data.remainingTime?.minutes ?? 0) * 60 + (data.remainingTime?.seconds ?? 0);
    remainingSeconds.value = totalSeconds;

    // Start timer
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        Get.back(); // close dialog
      }
    });

    // Show dialog
    Get.dialog(
      UploadRestrictionDialog(
        message: data.message ?? "Please wait before uploading another video.",
        remainingSeconds: remainingSeconds,
        onClose: () {
          countdownTimer?.cancel();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    countdownTimer?.cancel();
    super.onClose();
  }
}
