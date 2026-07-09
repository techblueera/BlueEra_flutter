
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/create_channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

import '../../../personal/auth/controller/view_personal_details_controller.dart';


class ManageChannelController extends GetxController {
  ApiResponse createChannelResponse = ApiResponse.initial('Initial');
  ApiResponse socialLinksResponse = ApiResponse.initial('Initial');
  ApiResponse updateChannelResponse = ApiResponse.initial('Initial');
  RxBool isShowCheck = true.obs;

  ///CREATE CHANNEL...
  Future<void> createChannel(
      {required Map<String, dynamic>? reqData,
      required List<Map<String, String>> socialLinkReqData}) async {
    try {
      ResponseModel response =
          await ChannelRepo().createChannel(bodyRequest: reqData);

      if (response.isSuccess) {
        createChannelResponse = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
        CreateChannelModel createChannelModel = CreateChannelModel.fromJson(response.response?.data);
        channelId = createChannelModel.data.id;
        await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channel_Id,
          channelId,
        );

       await socialLinks(id: createChannelModel.data.id, reqData: socialLinkReqData);
        final viewProfileController = Get.find<ViewPersonalDetailsController>();
        viewProfileController.viewPersonalProfile(forceRefresh: true);
      } else {
        createChannelResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      createChannelResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///CREATE CHANNEL...
  Future<void> socialLinks(
      {required String id, required List<Map<String, String>>? reqData}) async {
    if (reqData == null || reqData.isEmpty) {
      Get.back();
      return;
    }

    try {
      channelId = id;
      ResponseModel response =
          await ChannelRepo().updateSocialLinks(bodyRequest: reqData);

      if (response.isSuccess) {
        socialLinksResponse = ApiResponse.complete(response);
        final viewProfileController = Get.find<ViewPersonalDetailsController>();
        viewProfileController.viewPersonalProfile(forceRefresh: true);
        Get.back();
      } else {
        socialLinksResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      socialLinksResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///UPDATE CHANNEL...
  Future<void> socialLinksUpdate(
      {required String id, required List<Map<String, String>>? reqData}) async {
    if (reqData == null || reqData.isEmpty) {
      Get.back(result: true);
      return;
    }

    try {
      channelId = id;
      ResponseModel response =
          await ChannelRepo().updateSocialLinks(bodyRequest: reqData);

      if (response.isSuccess) {
        socialLinksResponse = ApiResponse.complete(response);
        Get.back();
      } else {
        socialLinksResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      socialLinksResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///UPDATE CHANNEL...

}
