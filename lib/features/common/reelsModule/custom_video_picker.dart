import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/reelsModule/widget/loading_ui.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CustomVideoPicker {
  static Future<String?> pickVideo() async {
    try {
      Get.dialog(barrierDismissible: false, const LoadingUi());
      final videoPath = await ImagePicker().pickVideo(source: ImageSource.gallery,maxDuration: Duration(seconds: 10));
      Get.back();

      if (videoPath != null) {
        return videoPath.path;
      } else {
        logs("Video Not Selected !!");
        return null;
      }
    } catch (e) {
      logs("Video Picker Error => $e");
      return null;
    }
  }
}
