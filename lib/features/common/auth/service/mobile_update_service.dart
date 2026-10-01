import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';

/// Changing the account's mobile number: request an OTP for the new number,
/// then verify it.
///
/// Each step tells the user how it went and returns true on success; moving
/// between the entry and OTP stages is up to the caller.
class MobileUpdateService {
  MobileUpdateService({AuthRepo? repo}) : _repo = repo ?? AuthRepo();

  final AuthRepo _repo;

  /// Sends an OTP to the new number in [params].
  Future<bool> requestOtp(Map<String, dynamic> params) async {
    try {
      final response =
          await _repo.requestMobileUpdateOtpRepo(bodyRequest: params);
      commonSnackBar(
          message: response.message ??
              (response.isSuccess
                  ? AppStrings.success
                  : AppStrings.somethingWentWrong));
      return response.isSuccess;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  /// Verifies the OTP in [params], which switches the account to the new
  /// number.
  Future<bool> verifyOtp(Map<String, dynamic> params) async {
    try {
      final response =
          await _repo.verifyMobileUpdateOtpRepo(bodyRequest: params);
      final ok = response.statusCode == 200;
      commonSnackBar(
          message: response.message ??
              (ok ? AppStrings.success : AppStrings.somethingWentWrong));
      return ok;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }
}
