import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:get/get.dart';

import '../repo/booking_repo.dart';

/// A customer sending an enquiry to a channel about one of its videos.
/// Registered by SendEnquiryBinding on the enquiry screen's route.
class SendEnquiryController extends GetxController {
  SendEnquiryController(
      {required BookingRepo repo,
      required this.channelId,
      required this.videoId})
      : _repo = repo;

  final BookingRepo _repo;
  final String channelId;
  final String videoId;

  final isSending = false.obs;

  /// Sends the enquiry. Returns true when it was sent.
  Future<bool> send(
      {required String name,
      required String email,
      required String mobile,
      required String message}) async {
    if (isSending.value) return false;
    isSending.value = true;
    try {
      final response = await _repo.postEnquiry(bodyRequest: {
        ApiKeys.serviceProvider_channelId: channelId,
        ApiKeys.message: message,
        ApiKeys.videoId: videoId,
        ApiKeys.user_email: email,
        ApiKeys.user_phone: mobile,
        ApiKeys.user_name: name,
      });
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isSending.value = false;
    }
  }
}
