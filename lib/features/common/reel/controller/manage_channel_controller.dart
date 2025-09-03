import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/create_channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

import '../../../../core/api/model/otp_verify_model.dart';

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

        socialLinks(id: createChannelModel.data.id, reqData: socialLinkReqData);
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
      {required String id, required List<Map<String, String>> reqData}) async {
    if (reqData.isEmpty) {
      Get.back();
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
  Future<void> updateChannel({
    required Map<String, dynamic> reqData,
    List<Map<String, String>>? socialLinkReqData,
  }) async {
    try {
      String? channelId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.channel_Id);
      if (channelId == null || channelId.isEmpty) {
        commonSnackBar(message: "Channel ID not found");
        return;
      }

      ResponseModel response = await ChannelRepo().updateChannel(
        channelId: channelId,
        bodyRequest: reqData,
      );

      if (response.isSuccess) {
        updateChannelResponse = ApiResponse.complete(response);
        commonSnackBar(
            message: response.message ?? "Channel updated successfully");

        await ChannelRepo().getChannelDetails(channelOrUserId: userId);
        await SocialLinks();

        Get.back(result: true);
      } else {
        updateChannelResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      updateChannelResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
