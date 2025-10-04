import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:get/get.dart';

class StatusViewerController extends GetxController {
  var currentIndex = 0.obs;
  var posts = <Post>[].obs;

  void setPosts(List<Post> data) {
    posts.assignAll(data);
  }

  void next() {
    if (currentIndex.value < posts.length - 1) {
      currentIndex.value++;
    } else {
      Get.back(); // close after last
    }
  }

  void previous() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
  }
}

// import 'dart:async';
// import 'package:get/get.dart';
//
// class StatusController extends GetxController {
//   final currentIndex = 0.obs;
//   final progress = 0.0.obs;
//   Timer? _timer;
//
//   final List<String> statuses = [
//     "https://picsum.photos/400/700",
//     "https://placekitten.com/400/700",
//     "https://picsum.photos/id/237/400/700",
//   ];
//
//   void startProgress() {
//     stopProgress();
//     progress.value = 0.0;
//
//     _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
//       if (progress.value < 1.0) {
//         progress.value += 0.01;
//       } else {
//         timer.cancel();
//         nextStatus();
//       }
//     });
//   }
//
//   void nextStatus() {
//     if (currentIndex.value < statuses.length - 1) {
//       currentIndex.value++;
//       startProgress();
//     } else {
//       Get.back(); // Close viewer after last status
//     }
//   }
//
//   void previousStatus() {
//     if (currentIndex.value > 0) {
//       currentIndex.value--;
//       startProgress();
//     }
//   }
//
//   void stopProgress() {
//     _timer?.cancel();
//   }
//
//   @override
//   void onClose() {
//     stopProgress();
//     super.onClose();
//   }
// }
