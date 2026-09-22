import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/lost_media_recovery.dart';
import 'package:BlueEra/features/common/reelsModule/widget/loading_ui.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BlueEra/core/routes/safe_back.dart';

class CustomVideoPicker {
  static Future<String?> pickVideo() async {
    // The loader is only closed in a `finally`. Previously the close sat on the
    // happy path, so a picker that threw — or an Android activity death that
    // left the pick unanswered — stranded a `barrierDismissible: false` overlay
    // on screen with no way to dismiss it: a hard freeze needing a force-stop.
    Get.dialog(barrierDismissible: false, const LoadingUi());
    try {
      final videoPath = await const SafeImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 10),
      );

      if (videoPath != null) return videoPath.path;
      logs("Video Not Selected !!");
      return null;
    } catch (e) {
      logs("Video Picker Error => $e");
      return null;
    } finally {
      if (Get.isDialogOpen ?? false) safeBack();
    }
  }
}
