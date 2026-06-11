import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/wallet_repo.dart';
import 'package:get/get.dart';

/// Drives the "Scan to Pay" QR bottom sheet: fetches the conversation
/// person's UPI details from `wallet-service/wallet/user/{userId}/upi` and
/// exposes them reactively so the sheet can render the right QR.
class UpiPaymentController extends GetxController {
  final WalletRepo _walletRepo = WalletRepo();

  /// True while the UPI details are being fetched.
  final RxBool isLoading = false.obs;

  /// Raw `data` payload returned by the UPI endpoint:
  /// `{ "userId": "...", "upiId": "name@bank" }`.
  final Rxn<dynamic> upiData = Rxn<dynamic>();

  /// The conversation person's UPI id (VPA), e.g. `himanshu@oksbi`. Null until
  /// fetched / when the user has none configured.
  final RxnString upiId = RxnString();

  /// Error message when the fetch fails (null while loading / on success).
  final RxnString errorMessage = RxnString();

  /// Fetches [userId]'s UPI details and logs the full response so we can
  /// decide how to render the QR. Returns the raw [ResponseModel] (or null
  /// when [userId] is empty / the call throws).
  Future<ResponseModel?> fetchUserUpi(String userId) async {
    if (userId.isEmpty) {
      log('🔸 UpiPayment: fetchUserUpi called with empty userId');
      errorMessage.value = 'User not found';
      return null;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await _walletRepo.getUserUpiRepo(userId: userId);

      log('🔹 USER UPI [$userId] '
          'status=${response.statusCode} success=${response.isSuccess}');
      log('🔹 USER UPI RESPONSE => ${response.response?.data}');

      if (response.isSuccess) {
        upiData.value = response.data;
        final id = (response.data is Map) ? response.data['upiId'] : null;
        upiId.value = (id is String && id.isNotEmpty) ? id : null;
        if (upiId.value == null) {
          errorMessage.value = 'No UPI ID found for this user';
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load UPI details';
      }
      return response;
    } catch (e, st) {
      log('🔻 UpiPayment: fetchUserUpi error: $e', stackTrace: st);
      errorMessage.value = 'Something went wrong';
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
