// import 'dart:io';
//
// import 'package:get/get.dart';
//
// import '../../../../core/api/apiService/response_model.dart';
// import '../../../../core/constants/snackbar_helper.dart';
// import '../../auth/repo/live_video_repo.dart';
//
// class IntroVideoController extends GetxController {
//   final IntroVideoRepo _repo = IntroVideoRepo();
//   Rx<File?> selectedVideo = Rx<File?>(null);
//
//   // RxBool isLoading = false.obs;
//   RxString introVideoUrl = ''.obs;
//
//   Future<void> uploadIntroVideo(File file) async {
//     try {
//       // isLoading.value = true;
//
//       ResponseModel response = await _repo.uploadIntroVideo(file: file);
//
//       if (response.isSuccess) {
//         // await fetchIntroVideo();
//         commonSnackBar(message: response.message ?? 'Uploaded');
//       } else {
//         commonSnackBar(message: response.message ?? 'Upload failed');
//       }
//     } catch (e) {
//       commonSnackBar(message: "Something went wrong.");
//     } finally {
//       // isLoading.value = false;
//     }
//   }
//
//   // Future<void> fetchIntroVideo() async {
//   //   try {
//   //     // isLoading.value = true;
//   //     ResponseModel response = await _repo.fetchIntroVideo();
//   //     if (response.isSuccess && response.data != null) {
//   //       if (response.data is Map && response.data['introVideo'] != null) {
//   //         introVideoUrl.value = response.data['introVideo'];
//   //       }
//   //       else if (response.data is String) {
//   //         introVideoUrl.value = response.data;
//   //       }
//   //       else {
//   //         introVideoUrl.value = '';
//   //         // commonSnackBar(message: 'Intro video not found.');
//   //       }
//   //     } else {
//   //       // commonSnackBar(message: response.message ?? 'Failed to fetch video');
//   //     }
//   //   } catch (e) {
//   //     // commonSnackBar(message: "Something went wrong.");
//   //   } finally {
//   //     // isLoading.value = false;
//   //   }
//   // }
//
// }
