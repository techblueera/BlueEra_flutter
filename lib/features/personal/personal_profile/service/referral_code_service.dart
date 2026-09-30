import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';

/// Checks a referral / promo code before it is applied.
class ReferralCodeService {
  ReferralCodeService({UserRepo? repo}) : _repo = repo ?? UserRepo();

  final UserRepo _repo;

  /// Null when the check itself failed (the caller keeps the user where they
  /// are). Otherwise whether the code is valid, with the server's message
  /// when it is not.
  ///
  /// 200 OK does NOT imply the code is valid: the server returns
  /// `{success:true, isValid:false, message:"Referral code is invalid"}` for
  /// unknown codes.
  Future<({bool valid, String? message})?> check(String code) async {
    final res = await _repo.checkReferralRepo(code);
    if (!res.isSuccess) return null;
    final data = res.response?.data;
    final isValid = data is Map && data['isValid'] == true;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : null;
    return (valid: isValid, message: isValid ? null : message);
  }
}
