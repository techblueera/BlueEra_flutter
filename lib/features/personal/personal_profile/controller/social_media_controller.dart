// import 'dart:developer';
//
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:get/get.dart';
//
// import '../../../../core/api/apiService/api_keys.dart';
// import '../../../../core/api/apiService/response_model.dart';
// import '../../auth/repo/social_links_repo.dart';
//
// class SocialLinksController extends GetxController {
//   final SocialLinksRepo _repo = SocialLinksRepo();
//
//   // RxBool isLoading = false.obs;
//   RxString youtube = ''.obs;
//   RxString twitter = ''.obs;
//   RxString linkedin = ''.obs;
//   RxString instagram = ''.obs;
//   RxString website = ''.obs;
//
//
//   Future<void> fetchLinks_() async {
//     try {
//       ResponseModel response = await _repo.getSocialMediaLinks();
//
//       if (response.isSuccess && response.data != null) {
//         youtube.value = response.data['data']['social_links']['youtube'] ?? '';
//         twitter.value = response.data['data']['social_links']['twitter'] ?? '';
//         linkedin.value = response.data['data']['social_links']['linkedin'] ?? '';
//         instagram.value = response.data['data']['social_links']['instagram'] ?? '';
//         website.value = response.data['data']['social_links']['website'] ?? '';
//       }
//     } catch (e) {
//       print('Error: $e');
//     } finally {
//     }
//   }
//
//   Future<void> updateLinks() async {
//     try {
//       Map<String, dynamic> payload = {
//         ApiKeys.youtube: youtube.value,
//         ApiKeys.twitter: twitter.value,
//         ApiKeys.linkedin: linkedin.value,
//         ApiKeys.instagram: instagram.value,
//         ApiKeys.website: website.value,
//       };
//
//       ResponseModel response = await _repo.updateSocialMediaLinks(params: payload);
//
//       if (response.isSuccess) {
//         commonSnackBar(message: response.data?['message']);
//
//       } else {
//         commonSnackBar(message: response.message);
//
//       }
//     } catch (e) {
//       log('Error: $e');
//     } finally {
//       // isLoading.value = false;
//     }
//   }
// }
